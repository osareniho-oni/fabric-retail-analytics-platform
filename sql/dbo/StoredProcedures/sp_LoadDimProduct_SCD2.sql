-- Load Product Dimension (SCD Type 2)

CREATE   PROCEDURE dbo.sp_LoadDimProduct_SCD2
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
        'lh_silver.dbo.stg_products + stg_departments';
    DECLARE @TargetEntity VARCHAR(255) = 'dim.Product';
    DECLARE @ErrorMessage VARCHAR(4000);

    IF OBJECT_ID('dim.Product', 'U') IS NOT NULL
    BEGIN
        BEGIN TRY
            IF OBJECT_ID('tempdb..#SourceProduct') IS NOT NULL
                DROP TABLE #SourceProduct;

            SELECT @RowsRead = COUNT(*)
            FROM lh_silver.dbo.stg_products;

            SELECT
                p.product_id AS ProductID,
                p.product_name AS ProductName,
                p.product_number AS ProductNumber,
                d.department_name AS Department,
                COALESCE(p.unit_price, CAST(0.00 AS DECIMAL(10,2))) AS UnitPrice
            INTO #SourceProduct
            FROM lh_silver.dbo.stg_products p
            INNER JOIN lh_silver.dbo.stg_departments d
                ON p.department_id = d.department_id;

            UPDATE tgt
            SET
                tgt.ValidTo = @ExecutionTimestamp,
                tgt.IsCurrent = 0
            FROM dim.Product tgt
            INNER JOIN #SourceProduct src
                ON tgt.ProductID = src.ProductID
            WHERE tgt.IsCurrent = 1
              AND
              (
                   ISNULL(tgt.ProductName, '') <> ISNULL(src.ProductName, '')
                OR ISNULL(tgt.ProductNumber, '') <> ISNULL(src.ProductNumber, '')
                OR ISNULL(tgt.Department, '') <> ISNULL(src.Department, '')
                OR ISNULL(tgt.UnitPrice, 0.00) <> ISNULL(src.UnitPrice, 0.00)
              );

            SET @RowsExpired = @@ROWCOUNT;

            INSERT INTO dim.Product
            (
                ProductID,
                ProductName,
                ProductNumber,
                Department,
                UnitPrice,
                ValidFrom,
                ValidTo,
                IsCurrent,
                IsRebranded
            )
            SELECT
                src.ProductID,
                src.ProductName,
                src.ProductNumber,
                src.Department,
                src.UnitPrice,
                @ExecutionTimestamp,
                NULL,
                1,
                CASE 
                    WHEN ISNULL(tgt.ProductName, '') <> ISNULL(src.ProductName, '')
                        THEN 1
                        ELSE 0
                END
            FROM #SourceProduct src
            LEFT JOIN dim.Product tgt
                ON src.ProductID = tgt.ProductID
               AND tgt.IsCurrent = 1
            WHERE tgt.ProductID IS NULL
               OR
               (
                    ISNULL(tgt.ProductName, '') <> ISNULL(src.ProductName, '')
                 OR ISNULL(tgt.ProductNumber, '') <> ISNULL(src.ProductNumber, '')
                 OR ISNULL(tgt.Department, '') <> ISNULL(src.Department, '')
                 OR ISNULL(tgt.UnitPrice, 0.00) <> ISNULL(src.UnitPrice, 0.00)
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
            
            -- Refresh Basket Table (Second Sink)
            TRUNCATE TABLE dim.Product_Basket;

            INSERT INTO dim.Product_Basket
            (
                ProductName,
                ProductNumber,
                Department
            )
            SELECT
                ProductName,
                ProductNumber,
                Department
            FROM dim.Product;

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
            'Target table dim.Product does not exist.';

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