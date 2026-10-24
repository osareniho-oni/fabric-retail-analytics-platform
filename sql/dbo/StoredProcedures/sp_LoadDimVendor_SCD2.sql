-- Load Vendor Dimension (SCD Type 2)

CREATE   PROCEDURE dbo.sp_LoadDimVendor_SCD2
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
        'lh_silver.dbo.stg_vendors + stg_cities + stg_states';
    DECLARE @TargetEntity VARCHAR(255) = 'dim.Vendor';
    DECLARE @ErrorMessage VARCHAR(4000);

    IF OBJECT_ID('dim.Vendor', 'U') IS NOT NULL
    BEGIN
        BEGIN TRY
            IF OBJECT_ID('tempdb..#SourceVendor') IS NOT NULL
                DROP TABLE #SourceVendor;

            SELECT @RowsRead = COUNT(*)
            FROM lh_silver.dbo.stg_vendors;

            SELECT
                v.vendor_id AS VendorID,
                v.vendor_number AS VendorNumber,
                CONCAT(
                    UPPER(COALESCE(v.last_name, '')),
                    ' ',
                    COALESCE(v.first_name, '')
                ) AS VendorName,
                v.registration_number AS RegistrationNumber,
                v.vendor_address AS VendorAddress,
                c.city_name AS City,
                st.state_name AS [State]
            INTO #SourceVendor
            FROM lh_silver.dbo.stg_vendors v
            INNER JOIN lh_silver.dbo.stg_cities c
                ON v.city_id = c.city_id
            INNER JOIN lh_silver.dbo.stg_states st
                ON c.state_id = st.state_id;

            UPDATE tgt
            SET
                tgt.ValidTo = @ExecutionTimestamp,
                tgt.IsCurrent = 0
            FROM dim.Vendor tgt
            INNER JOIN #SourceVendor src
                ON tgt.VendorID = src.VendorID
            WHERE tgt.IsCurrent = 1
              AND
              (
                   ISNULL(tgt.VendorName, '') <> ISNULL(src.VendorName, '')
                OR ISNULL(tgt.VendorNumber, '') <> ISNULL(src.VendorNumber, '')
                OR ISNULL(tgt.RegistrationNumber, '') <> ISNULL(src.RegistrationNumber, '')
                OR ISNULL(tgt.VendorAddress, '') <> ISNULL(src.VendorAddress, '')
                OR ISNULL(tgt.City, '') <> ISNULL(src.City, '')
                OR ISNULL(tgt.State, '') <> ISNULL(src.State, '')
              );

            SET @RowsExpired = @@ROWCOUNT;

            INSERT INTO dim.Vendor
            (
                VendorID,
                VendorNumber,
                VendorName,
                RegistrationNumber,
                VendorAddress,
                City,
                [State],
                ValidFrom,
                ValidTo,
                IsCurrent
            )
            SELECT
                src.VendorID,
                src.VendorNumber,
                src.VendorName,
                src.RegistrationNumber,
                src.VendorAddress,
                src.City,
                src.State,
                @ExecutionTimestamp,
                NULL,
                1
            FROM #SourceVendor src
            LEFT JOIN dim.Vendor tgt
                ON src.VendorID = tgt.VendorID
               AND tgt.IsCurrent = 1
            WHERE tgt.VendorID IS NULL
               OR
               (
                    ISNULL(tgt.VendorName, '') <> ISNULL(src.VendorName, '')
                 OR ISNULL(tgt.VendorNumber, '') <> ISNULL(src.VendorNumber, '')
                 OR ISNULL(tgt.RegistrationNumber, '') <> ISNULL(src.RegistrationNumber, '')
                 OR ISNULL(tgt.VendorAddress, '') <> ISNULL(src.VendorAddress, '')
                 OR ISNULL(tgt.City, '') <> ISNULL(src.City, '')
                 OR ISNULL(tgt.State, '') <> ISNULL(src.State, '')
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
            'Target table dim.Vendor does not exist.';

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