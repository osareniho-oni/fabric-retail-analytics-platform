-- Load Fact Purchase

CREATE   PROCEDURE dbo.sp_LoadFactPurchase
    @MasterRunId varchar(100),
    @ChildRunId  varchar(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExecutionTimestamp DATETIME2 = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Mountain Standard Time' AS DATETIME2);
    DECLARE @SourceEntity varchar(255) = 'lh_silver.dbo.stg_purchase_transactions';
    DECLARE @TargetEntity varchar(255) = 'fact.Purchase';

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
        IF OBJECT_ID('fact.Purchase', 'U') IS NULL
        BEGIN
            THROW 50001, 'Target table fact.Purchase does not exist.', 1;
        END;

        ----------------------------------------------------------------
        -- 2. Retrieve existing watermark
        ----------------------------------------------------------------
        SELECT @LastCompletedBusinessDate = LastCompletedBusinessDate
        FROM dbo.FactLoadControl
        WHERE TargetEntity = @TargetEntity;

        IF @LastCompletedBusinessDate IS NULL
        BEGIN
            THROW 50002, 'No watermark row found for fact.Purchase in dbo.FactLoadControl.', 1;
        END;

        ----------------------------------------------------------------
        -- 3. Determine load date window
        ----------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM fact.Purchase)
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
        IF OBJECT_ID('tempdb..#PurchaseBase') IS NOT NULL DROP TABLE #PurchaseBase;

        SELECT
            src.transaction_id,
            src.transaction_number,
            src.transaction_date,
            src.order_date,
            src.delivery_date,
            src.ship_date,
            src.vendor_id,
            src.employee_id,
            src.product_id,
            src.store_id,
            ISNULL(src.quantity, 0) AS quantity,
            ISNULL(src.tax_amount, 0.00) AS tax_amount,
            ISNULL(src.line_amount, 0.00) AS line_amount
        INTO #PurchaseBase
        FROM lh_silver.dbo.stg_purchase_transactions src
        WHERE src.transaction_date >= @LoadStart
            AND src.transaction_date <= @LoadEnd;

        SELECT @RowsRead = COUNT(*) FROM #PurchaseBase;

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
        IF EXISTS (SELECT 1 FROM #PurchaseBase WHERE transaction_id IS NULL)
        BEGIN
            THROW 50003, 'Purchase source contains NULL transaction_id values.', 1;
        END;

        IF EXISTS (
            SELECT transaction_id 
            FROM #PurchaseBase 
            GROUP BY transaction_id 
            HAVING COUNT(*) > 1
        )
        BEGIN
            THROW 50004, 'Purchase source contains duplicate transaction_id values.', 1;
        END;

        ----------------------------------------------------------------
        -- 7. Strict INNER JOIN to Gold Dimensions
        ----------------------------------------------------------------
        IF OBJECT_ID('tempdb..#PurchaseSrc') IS NOT NULL DROP TABLE #PurchaseSrc;

        SELECT
            src.transaction_id,
            src.transaction_number,
            d1.DateKey     AS TransactionDateKey,
            d2.DateKey     AS OrderDateKey,
            d3.DateKey     AS DeliveryDateKey,
            d4.DateKey     AS ShipDateKey,
            v.VendorKey,
            em.EmployeeKey,
            pr.ProductKey,
            st.StoreKey,
            src.quantity   AS Quantity,
            src.tax_amount AS TaxAmount,
            src.line_amount AS LineAmount
        INTO #PurchaseSrc
        FROM #PurchaseBase src
        INNER JOIN dim.[Date] d1     ON src.transaction_date = d1.FullDate
        INNER JOIN dim.[Date] d2     ON src.order_date = d2.FullDate
        INNER JOIN dim.[Date] d3     ON src.delivery_date = d3.FullDate
        INNER JOIN dim.[Date] d4     ON src.ship_date = d4.FullDate
        INNER JOIN dim.Vendor v      ON src.vendor_id = v.VendorID AND v.IsCurrent = 1
        INNER JOIN dim.Employee em   ON src.employee_id = em.EmployeeID AND em.IsCurrent = 1
        INNER JOIN dim.Product pr    ON src.product_id = pr.ProductID AND pr.IsCurrent = 1
        INNER JOIN dim.Store st      ON src.store_id = st.StoreID AND st.IsCurrent = 1;

        SELECT @RowsStaged = COUNT(*) FROM #PurchaseSrc;

        ----------------------------------------------------------------
        -- 8. Enforce Referential Integrity Failure Rule
        ----------------------------------------------------------------
        IF @RowsStaged <> @RowsRead
        BEGIN
            DECLARE @Diff int = @RowsRead - @RowsStaged;
            DECLARE @Err varchar(255) = CONCAT('Referential Integrity Error: ', @Diff, ' Purchase record(s) failed to match a required dimension key.');
            THROW 50005, @Err, 1;
        END;

        ----------------------------------------------------------------
        -- 9. Insert Facts & Advance Watermark
        ----------------------------------------------------------------
        INSERT INTO fact.Purchase
        (
            TransactionID,
            TransactionNumber,
            TransactionDateKey,
            OrderDateKey,
            DeliveryDateKey,
            ShipDateKey,
            VendorKey,
            EmployeeKey,
            ProductKey,
            StoreKey,
            Quantity,
            TaxAmount,
            LineAmount
        )
        SELECT
            src.transaction_id,
            src.transaction_number,
            src.TransactionDateKey,
            src.OrderDateKey,
            src.DeliveryDateKey,
            src.ShipDateKey,
            src.VendorKey,
            src.EmployeeKey,
            src.ProductKey,
            src.StoreKey,
            src.Quantity,
            src.TaxAmount,
            src.LineAmount
        FROM #PurchaseSrc src
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM fact.Purchase tgt
            WHERE tgt.TransactionID = src.transaction_id
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