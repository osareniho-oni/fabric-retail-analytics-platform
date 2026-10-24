-- Load Overtime Fact

CREATE   PROCEDURE dbo.sp_LoadFactOvertime
    @MasterRunId varchar(100),
    @ChildRunId  varchar(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExecutionTimestamp DATETIME2 = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Mountain Standard Time' AS DATETIME2);
    DECLARE @SourceEntity varchar(255) = 'lh_silver.dbo.stg_overtime_data';
    DECLARE @TargetEntity varchar(255) = 'fact.Overtime';

    DECLARE @InitialLoadDate date = '1900-01-01';
    DECLARE @LastCompletedBusinessDate date;
    DECLARE @LoadStart date;
    DECLARE @LoadEnd date = DATEADD(DAY, -1, CAST(@ExecutionTimestamp AS DATE));

    DECLARE @RowsRead int = 0;
    DECLARE @RowsWritten int = 0;
    DECLARE @RowsStaged int = 0;
    DECLARE @ErrorMessage varchar(4000);

    BEGIN TRY

        ----------------------------------------------------------------
        -- 1. Validate target table exists
        ----------------------------------------------------------------
        IF OBJECT_ID('fact.Overtime', 'U') IS NULL
        BEGIN
            THROW 50001, 'Target table fact.Overtime does not exist.', 1;
        END;

        ----------------------------------------------------------------
        -- 2. Retrieve existing watermark
        ----------------------------------------------------------------
        SELECT @LastCompletedBusinessDate = LastCompletedBusinessDate
        FROM dbo.FactLoadControl
        WHERE TargetEntity = @TargetEntity;

        IF @LastCompletedBusinessDate IS NULL
        BEGIN
            THROW 50002, 'No watermark row found for fact.Overtime in dbo.FactLoadControl.', 1;
        END;

        ----------------------------------------------------------------
        -- 3. Determine load date window
        ----------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM fact.Overtime)
            SET @LoadStart = @InitialLoadDate;
        ELSE
            SET @LoadStart = DATEADD(DAY, 1, @LastCompletedBusinessDate);

        ----------------------------------------------------------------
        -- 4. Short-circuit if pipeline is already up to date
        ----------------------------------------------------------------
        IF @LoadStart > @LoadEnd
        BEGIN
            EXEC dbo.sp_WritePipelineAudit
                @MasterRunId  = @MasterRunId,
                @ChildRunId   = @ChildRunId,
                @Layer        = 'Gold',
                @SourceEntity = @SourceEntity,
                @TargetEntity = @TargetEntity,
                @RowsRead     = 0,
                @RowsWritten  = 0,
                @Status       = 'Succeeded',
                @ErrorMessage = NULL;

            RETURN;
        END;

        ----------------------------------------------------------------
        -- 5. Stage raw delta source records for the date window
        ----------------------------------------------------------------
        IF OBJECT_ID('tempdb..#OvertimeBase') IS NOT NULL DROP TABLE #OvertimeBase;

        SELECT
            src.overtime_id,
            src.overtime_start_ts,
            src.overtime_end_ts,
            src.employee_number
        INTO #OvertimeBase
        FROM lh_silver.dbo.stg_overtime_data src
        WHERE CAST(src.overtime_start_ts AS date) >= @LoadStart
          AND CAST(src.overtime_start_ts AS date) <= @LoadEnd;

        SELECT @RowsRead = COUNT(*) FROM #OvertimeBase;

        -- If zero transactions occurred in this window, advance watermark and exit
        IF @RowsRead = 0
        BEGIN
            UPDATE dbo.FactLoadControl
            SET LastCompletedBusinessDate = @LoadEnd,
                LastSuccessfulRunId = @MasterRunId,
                UpdatedAt = @ExecutionTimestamp
            WHERE TargetEntity = @TargetEntity;

            EXEC dbo.sp_WritePipelineAudit
                @MasterRunId  = @MasterRunId,
                @ChildRunId   = @ChildRunId,
                @Layer        = 'Gold',
                @SourceEntity = @SourceEntity,
                @TargetEntity = @TargetEntity,
                @RowsRead     = 0,
                @RowsWritten  = 0,
                @Status       = 'Succeeded',
                @ErrorMessage = NULL;

            RETURN;
        END;

        ----------------------------------------------------------------
        -- 6. Grain & Key Integrity Checks
        ----------------------------------------------------------------
        -- Verify core required fields are non-null
        IF EXISTS (
            SELECT 1 
            FROM #OvertimeBase 
            WHERE overtime_id IS NULL 
               OR overtime_start_ts IS NULL 
               OR overtime_end_ts IS NULL 
               OR employee_number IS NULL
        )
        BEGIN
            THROW 50003, 'Overtime source contains NULL core key/timestamp values.', 1;
        END;

        ----------------------------------------------------------------
        -- 7. Strict INNER JOIN to Gold Dimensions
        ----------------------------------------------------------------
        IF OBJECT_ID('tempdb..#OvertimeSrc') IS NOT NULL DROP TABLE #OvertimeSrc;

        SELECT
            src.overtime_id                                                                 AS OvertimeID,
            d1.DateKey                                                                     AS StartDateKey,
            t1.TimeKey                                                                     AS StartHourKey,
            d2.DateKey                                                                     AS EndDateKey,
            t2.TimeKey                                                                     AS EndHourKey,
            em.EmployeeKey                                                                 AS EmployeeKey,
            ROUND(DATEDIFF(MINUTE, src.overtime_start_ts, src.overtime_end_ts) / 60.0, 2) AS OvertimeHours
        INTO #OvertimeSrc
        FROM #OvertimeBase src
        INNER JOIN dim.[Date] d1 
            ON CAST(src.overtime_start_ts AS date) = d1.FullDate
        INNER JOIN dim.[Date] d2 
            ON CAST(src.overtime_end_ts AS date) = d2.FullDate
        INNER JOIN dim.[Time] t1 
            ON DATEPART(HOUR, src.overtime_start_ts) = t1.TimeHour
        INNER JOIN dim.[Time] t2 
            ON DATEPART(HOUR, src.overtime_end_ts) = t2.TimeHour
        INNER JOIN dim.Employee em 
            ON src.employee_number = em.EmployeeNumber 
           AND em.IsCurrent = 1;

        SELECT @RowsStaged = COUNT(*) FROM #OvertimeSrc;

        ----------------------------------------------------------------
        -- 8. Enforce Referential Integrity Failure Rule
        ----------------------------------------------------------------
        IF @RowsStaged <> @RowsRead
        BEGIN
            DECLARE @Diff int = @RowsRead - @RowsStaged;
            DECLARE @Err varchar(255) = CONCAT('Referential Integrity Error: ', @Diff, ' Overtime record(s) failed to match a required dimension key.');
            THROW 50005, @Err, 1;
        END;

        ----------------------------------------------------------------
        -- 9. Insert Facts & Advance Watermark
        ----------------------------------------------------------------
        INSERT INTO fact.Overtime
        (
            OvertimeID,
            StartDateKey,
            StartHourKey,
            EndDateKey,
            EndHourKey,
            EmployeeKey,
            OvertimeHours
        )
        SELECT
            src.OvertimeID,
            src.StartDateKey,
            src.StartHourKey,
            src.EndDateKey,
            src.EndHourKey,
            src.EmployeeKey,
            src.OvertimeHours
        FROM #OvertimeSrc src
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM fact.Overtime tgt
            WHERE tgt.OvertimeID = src.OvertimeID
        );

        SET @RowsWritten = @@ROWCOUNT;

        -- Advance watermark in control table
        UPDATE dbo.FactLoadControl
        SET
            LastCompletedBusinessDate = @LoadEnd,
            LastSuccessfulRunId = @MasterRunId,
            UpdatedAt = @ExecutionTimestamp
        WHERE TargetEntity = @TargetEntity;

        ----------------------------------------------------------------
        -- 10. Log Success Audit
        ----------------------------------------------------------------
        EXEC dbo.sp_WritePipelineAudit
            @MasterRunId  = @MasterRunId,
            @ChildRunId   = @ChildRunId,
            @Layer        = 'Gold',
            @SourceEntity = @SourceEntity,
            @TargetEntity = @TargetEntity,
            @RowsRead     = @RowsRead,
            @RowsWritten  = @RowsWritten,
            @Status       = 'Succeeded',
            @ErrorMessage = NULL;

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();

        EXEC dbo.sp_WritePipelineAudit
            @MasterRunId  = @MasterRunId,
            @ChildRunId   = @ChildRunId,
            @Layer        = 'Gold',
            @SourceEntity = @SourceEntity,
            @TargetEntity = @TargetEntity,
            @RowsRead     = @RowsRead,
            @RowsWritten  = 0,
            @Status       = 'Failed',
            @ErrorMessage = @ErrorMessage;

        THROW;
    END CATCH;
END;