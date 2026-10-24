-- Load Promotion Dimension

CREATE   PROCEDURE dbo.sp_LoadDimPromotion
    @MasterRunId VARCHAR(100),
    @ChildRunId  VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowsRead INT = 0;
    DECLARE @RowsWritten INT = 0;
    DECLARE @SourceEntity VARCHAR(255) = 'lh_silver.dbo.stg_promotions + lh_silver.dbo.stg_promotion_types';
    DECLARE @TargetEntity VARCHAR(255) = 'dim.Promotion';
    DECLARE @ErrorMessage VARCHAR(4000);

    IF OBJECT_ID('dim.Promotion', 'U') IS NOT NULL
    BEGIN
        BEGIN TRY
            -- Counts promotion source rows; the lookup join does not change this count.
            SELECT @RowsRead = COUNT(*)
            FROM lh_silver.dbo.stg_promotions;

            DELETE FROM dim.Promotion;

            INSERT INTO dim.Promotion
            (
                PromotionID,
                PromotionName,
                StartDate,
                EndDate,
                DiscountPercent
            )
            SELECT
                p.promotion_id,
                COALESCE(pt.promotion_name, 'Unknown'),
                p.start_date,
                p.end_date,
                COALESCE(p.discount_percent, CAST(0.00 AS DECIMAL(5,2)))
            FROM lh_silver.dbo.stg_promotions p
            INNER JOIN lh_silver.dbo.stg_promotion_types pt
                ON p.promotion_type_id = pt.promotion_type_id;

            SET @RowsWritten = @@ROWCOUNT;

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
            'Target table dim.Promotion does not exist.';

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