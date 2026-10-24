-- PROPOSED READ-ONLY CHECK. Not executed. Uses inspected Warehouse names.
-- Full precision, no raw fact-to-fact join; stable business ProductID groups SCD versions.
WITH SalesByProduct AS (
    SELECT p.ProductID, COUNT_BIG(*) AS SalesRows,
           SUM(CAST(s.Quantity AS decimal(28,4))) AS SoldUnits,
           SUM(CAST(s.LineAmount AS decimal(28,4)) - CAST(s.Linediscountamount AS decimal(28,4))) AS NetRevenue
    FROM fact.Sales s
    LEFT JOIN dim.Product p ON p.ProductKey = s.ProductKey
    WHERE s.TransactionDateKey BETWEEN 20190101 AND 20191231
    GROUP BY p.ProductID
), PurchaseByProduct AS (
    SELECT p.ProductID, COUNT_BIG(*) AS PurchaseRows,
           SUM(CASE WHEN x.TransactionDateKey BETWEEN 20190101 AND 20191231
                    THEN CAST(x.LineAmount AS decimal(28,4)) + CAST(x.TaxAmount AS decimal(28,4)) ELSE 0 END) AS SpendTransactionYear,
           SUM(CASE WHEN x.OrderDateKey BETWEEN 20190101 AND 20191231
                    THEN CAST(x.LineAmount AS decimal(28,4)) + CAST(x.TaxAmount AS decimal(28,4)) ELSE 0 END) AS SpendOrderYear,
           SUM(CASE WHEN x.OrderDateKey BETWEEN 20190101 AND 20191231
                    THEN CAST(x.Quantity AS decimal(28,4)) ELSE 0 END) AS UnitsOrderYear
    FROM fact.Purchase x
    LEFT JOIN dim.Product p ON p.ProductKey = x.ProductKey
    WHERE x.TransactionDateKey BETWEEN 20190101 AND 20191231
       OR x.OrderDateKey BETWEEN 20190101 AND 20191231
    GROUP BY p.ProductID
)
SELECT COALESCE(s.ProductID,x.ProductID) AS ProductID,
       s.SalesRows, s.SoldUnits, s.NetRevenue,
       x.PurchaseRows, x.SpendTransactionYear, x.SpendOrderYear, x.UnitsOrderYear,
       x.SpendOrderYear / NULLIF(x.UnitsOrderYear,0) AS PurchaseAverageProxy,
       s.SoldUnits * (x.SpendOrderYear / NULLIF(x.UnitsOrderYear,0)) AS SoldCostProxy
FROM SalesByProduct s
FULL OUTER JOIN PurchaseByProduct x ON x.ProductID=s.ProductID
ORDER BY COALESCE(s.ProductID,x.ProductID);
-- NULL ProductID groups indicate unresolved keys: investigate before totaling.
-- SoldCostProxy is an explicit comparison basis, not a validated accounting valuation.
