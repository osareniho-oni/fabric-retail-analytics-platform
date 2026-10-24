-- Load Employee Dimension (SCD Type 2)

CREATE   PROCEDURE dbo.sp_LoadDimEmployee_SCD2
    @MasterRunId VARCHAR(100),
    @ChildRunId  VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExecutionTimestamp DATETIME2 = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Mountain Standard Time' AS DATETIME2);
    DECLARE @RowsRead INT = 0;
    DECLARE @RowsExpired INT = 0;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsWritten INT = 0;
    DECLARE @SourceEntity VARCHAR(255) =
        'lh_silver.dbo.stg_employees + stg_marital_status_types';
    DECLARE @TargetEntity VARCHAR(255) = 'dim.Employee';
    DECLARE @ErrorMessage VARCHAR(4000);

    IF OBJECT_ID('dim.Employee', 'U') IS NOT NULL
    BEGIN
        BEGIN TRY
            IF OBJECT_ID('tempdb..#SourceEmployee') IS NOT NULL
                DROP TABLE #SourceEmployee;

            SELECT @RowsRead = COUNT(*)
            FROM lh_silver.dbo.stg_employees;

            SELECT
                e.employee_id AS EmployeeID,
                e.employee_number AS EmployeeNumber,
                CONCAT(UPPER(e.last_name), ' ', e.first_name) AS EmployeeName,
                e.date_of_birth AS DateOfBirth,
                m.marital_status AS MaritalStatus
            INTO #SourceEmployee
            FROM lh_silver.dbo.stg_employees e
            INNER JOIN lh_silver.dbo.stg_marital_status_types m
                ON e.marital_status_id = m.marital_status_id;

            -- Expire the current version when tracked attributes change.
            UPDATE tgt
            SET
                tgt.ValidTo = @ExecutionTimestamp,
                tgt.IsCurrent = 0
            FROM dim.Employee tgt
            INNER JOIN #SourceEmployee src
                ON tgt.EmployeeID = src.EmployeeID
            WHERE tgt.IsCurrent = 1
              AND
              (
                   ISNULL(tgt.EmployeeNumber, '') <> ISNULL(src.EmployeeNumber, '')
                OR ISNULL(tgt.EmployeeName, '') <> ISNULL(src.EmployeeName, '')
                OR ISNULL(CONVERT(VARCHAR(10), tgt.DateOfBirth, 23), '')
                   <> ISNULL(CONVERT(VARCHAR(10), src.DateOfBirth, 23), '')
                OR ISNULL(tgt.MaritalStatus, '') <> ISNULL(src.MaritalStatus, '')
              );

            SET @RowsExpired = @@ROWCOUNT;

            -- Insert new employees and a new current version for changed employees.
            INSERT INTO dim.Employee
            (
                EmployeeID,
                EmployeeNumber,
                EmployeeName,
                DateOfBirth,
                MaritalStatus,
                ValidFrom,
                ValidTo,
                IsCurrent
            )
            SELECT
                src.EmployeeID,
                src.EmployeeNumber,
                src.EmployeeName,
                src.DateOfBirth,
                src.MaritalStatus,
                @ExecutionTimestamp,
                NULL,
                1
            FROM #SourceEmployee src
            LEFT JOIN dim.Employee tgt
                ON src.EmployeeID = tgt.EmployeeID
               AND tgt.IsCurrent = 1
            WHERE tgt.EmployeeID IS NULL
               OR
               (
                    ISNULL(tgt.EmployeeNumber, '') <> ISNULL(src.EmployeeNumber, '')
                 OR ISNULL(tgt.EmployeeName, '') <> ISNULL(src.EmployeeName, '')
                 OR ISNULL(CONVERT(VARCHAR(10), tgt.DateOfBirth, 23), '')
                    <> ISNULL(CONVERT(VARCHAR(10), src.DateOfBirth, 23), '')
                 OR ISNULL(tgt.MaritalStatus, '') <> ISNULL(src.MaritalStatus, '')
               );

            SET @RowsInserted = @@ROWCOUNT;
            SET @RowsWritten = @RowsExpired + @RowsInserted;

            EXEC dbo.sp_WritePipelineAudit
                @MasterRunId  = @MasterRunId,
                @ChildRunId   = @ChildRunId,
                @Layer        = 'Gold',
                @SourceEntity = @SourceEntity,
                @TargetEntity = @TargetEntity,
                @RowsRead     = @RowsRead,
                @RowsWritten  = @RowsWritten,
                @Status       = 'Succeeded';
        END TRY
        BEGIN CATCH
            SET @ErrorMessage = ERROR_MESSAGE();

            EXEC dbo.sp_WritePipelineAudit
                @MasterRunId  = @MasterRunId,
                @ChildRunId   = @ChildRunId,
                @Layer        = 'Gold',
                @SourceEntity = @SourceEntity,
                @TargetEntity = @TargetEntity,
                @RowsRead     = NULL,
                @RowsWritten  = NULL,
                @Status       = 'Failed',
                @ErrorMessage = @ErrorMessage;

            THROW;
        END CATCH
    END
    ELSE
    BEGIN
        DECLARE @Err VARCHAR(255) =
            'Target table dim.Employee does not exist.';

        EXEC dbo.sp_WritePipelineAudit
            @MasterRunId  = @MasterRunId,
            @ChildRunId   = @ChildRunId,
            @Layer        = 'Gold',
            @SourceEntity = @SourceEntity,
            @TargetEntity = @TargetEntity,
            @RowsRead     = NULL,
            @RowsWritten  = NULL,
            @Status       = 'Failed',
            @ErrorMessage = @Err;

        ;THROW 50000, @Err, 1;
    END
END;