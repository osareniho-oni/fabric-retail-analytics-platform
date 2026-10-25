# Financial calculation bases and reconciliation

[Dashboard design](dashboard-design.md) | [DAX source](<../powerbi/Retail Analytics Model.SemanticModel/definition/tables/_Measures.tmdl>) | [Read-only DAX checks](validation/financial-reconciliation.dax) | [Read-only Warehouse checks](validation/financial-reconciliation.sql)

The supplied 2019 profitability view displays approximately Net Revenue $381.23M, Gross Profit $374.86M, Gross Profit Margin 98.33%, and Production Cost $5.56B. These are displayed report values, **not validated financial outcomes**. The bridge displays about $6.36M COGS. The retained DAX supplies the following calculation bases.

## Different calculation bases

| Measure | Inspected formula/base | Consequence |
|---|---|---|
| Net Revenue | Sales line amounts minus sales line discounts | Sales-side revenue under model filters. Verify that line amount is gross before separately subtracting discount. |
| Production Cost | Purchase line amounts plus purchase tax | Purchasing spend under purchase-side date/model filters; not established manufacturing cost or cost of inventory sold. |
| Average Unit Cost | Production Cost divided by purchased quantity | A purchase-average proxy, sensitive to product mix, units, tax, and chosen dates. |
| COGS | For one selected year, iterates Sales rows and multiplies sales quantity by Average Unit Cost, clears Date filters, and restricts Purchase OrderDateKey to that year | Uses sold quantities and a different purchase date basis than default transaction-date filtering. It is not the Production Cost total. |
| Gross Profit / Margin | Net Revenue minus COGS; then divide by Net Revenue | High margin is arithmetically compatible with low computed COGS even when purchasing spend is large. That does not validate the costing model. |
| Marginal measures | Change in revenue / change in sold quantity versus change in purchase spend / change in purchased quantity across selected periods | Denominators and populations differ; the spread is not automatically incremental profit on matched inventory units. |

Rounded revenue minus profit implies about $6.37M COGS, close to the displayed bridge's $6.36M after rounding. Profit divided by revenue is about 98.33%. This arithmetic explains the cards' relationship; it does not reconcile $5.56B purchasing spend to sold inventory or certify any result.

With the inspected single-direction dimension-to-fact relationships, context transition on a Sales row does not automatically turn that row's product into a filter on Purchase. The COGS total can therefore use an external-context purchase average rather than each sold product's own average. Compare total COGS with a sum evaluated by stable ProductID before concluding; this is a source-based concern awaiting DAX execution.

Other unresolved questions: shared versus mismatched date roles, opening/closing inventory, returns and adjustments, unit/currency consistency, tax capitalization, product mixes, unmatched keys, duplicate IDs, historical versions, filter/calculation-group selections, and additive behavior across products and periods. The marginal chart's axis is visibly chronological, but that alone does not verify OFFSET's prior-period selection in the source expressions that order Month Name.

## Precise checks to perform in the existing project

The linked SQL and DAX queries are **read-only checks that have not been executed**. Confirm the deployed object names and page context before comparing results.

1. Record the page's 2019 filter, Top N value, other slicers, visual filters, calculation-group selections, and exact card measures. Export underlying approved totals privately with full precision; do not reconcile rounded cards alone.
2. Run the DAX base query with calculation-group filters cleared. Compare revenue, purchase spend/units, annual purchase-order-date spend, COGS, implied COGS, and profit/margin. Differences from the screenshot can indicate context/version differences, not necessarily a failed calculation.
3. Compare total COGS with SUMX over stable ProductID. Inspect product-level quantities and purchase costs. Check whether the total recomputes one global average instead of summing product-specific sold costs.
4. Run the Warehouse query separately aggregating Sales and Purchase before joining. Compare sales transaction year, purchase transaction year, and purchase order year. Never join raw sales and purchase lines directly by ProductID; that multiplies rows.
5. For a small approved product/time subset, hand-calculate sales net amount, purchase spend and units, a clearly specified unit-cost basis, sold cost, and margin. Explain inventory/timing differences before interpreting high margins as performance.
6. For marginal metrics, compare January/February/March and December/January explicitly: previous selected period, numeric chronological period, delta revenue/spend, delta quantities, zero/missing denominators, and total-row behavior. Confirm unit comparability before interpreting the spread.

Reconciliation remains open. The report images demonstrate visual design; financial performance interpretation depends on resolving these cost, quantity, and date bases.
