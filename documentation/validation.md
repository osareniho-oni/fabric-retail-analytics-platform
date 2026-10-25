# Validation and technical limitations

[Overview](../README.md) | [Requirements](business-requirements.md) | [Offline examples](validation/run_examples.py) | [Financial checks](financial-reconciliation.md)

## Evidence available

My [Fabric master-run capture](../screenshots/execution/master-pipeline-success.png) shows successful Bronze, Silver, and Gold invocations. [Entity logs](../screenshots/execution/pipeline-execution-log.png) show recorded source/target counts and status; [watermarks](../screenshots/validation/fact-load-watermarks.png) show completed business-date control state. These are evidence of project execution and monitoring. Correctness still requires reconciled source-to-report checks.

[Model layouts](data-model.md) and [report captures](dashboard-design.md) show structure and design. Exact correspondence between the repository snapshot and the deployed version has not been established. No new Fabric workload was run during portfolio preparation.

## Executed offline examples

```text
python documentation/validation/run_examples.py
```

All five groups passed locally using standard-library Python and an in-memory SQLite database. The runner writes no files. These are independent fixture calculations/reference contracts, not execution of the exported Spark, T-SQL, or DAX.

| Check | Expected and actual local result | Interpretation |
|---|---|---|
| Sales/order arithmetic | Gross 50, discount 2, net 48; 2 orders, 4 units; value/order 24, units/order 2, lines/order 1.5 | Fixture expectations match the reference calculations. |
| Intended daily HR retention | First ordinal retains 2 absence hours; last ordinal retains misconduct decision 2 across shuffled examples | Demonstrates the intended business rule, not the original notebook's distributed ordering behavior. |
| Duplicate/rerun contract | Repeat insert retains 3 rows and amount 50; duplicate source IDs rejected | SQLite/Python reference only; Warehouse key stability and transactions remain to be tested. |
| Late-delivery grain | Line/order arithmetic gives 1; distinct-order arithmetic gives 0.5 | Reproduces the existing numerator/denominator mismatch. |
| Historical/late-arrival cases | Event-time key 11 differs from current key 12; old-dated event falls outside next watermark window | Reproduces limitations; no history or late-arrival mechanism is added. |

## Confirmed source issues

These conclusions follow from the retained definitions. They identify affected code paths, not a claim that every dashboard result is wrong.

| Issue | Evidence and scope |
|---|---|
| Basket key mismatch | [Basket measures](<../powerbi/Retail Analytics Model.SemanticModel/definition/tables/_Measures.tmdl>) reference Product_Basket.ProductKey, absent from both its Warehouse and model definitions. Affects those key-based measures. |
| Product classification | [Product loader](../sql/dbo/StoredProcedures/sp_LoadDimProduct_SCD2.sql) expires the current version before comparing against a current-row join for IsRebranded; new rows also compare against a missing prior row. Classification needs correction/validation. |
| Lookup-key replacement | [Promotion loader](../sql/dbo/StoredProcedures/sp_LoadDimPromotion.sql) deletes/reinserts identity-key rows. Repeated loads can break existing fact references; stable-key rerun behavior needs testing. |
| Empty calendar initialization | Gold's [Script1](<../pipelines/Gold(Modeling)_Pipeline.DataPipeline/pipeline-content.json>) compares MAX(Year) with the current year; an empty dim.Date produces NULL and skips the load. This is a first-load edge case. |
| Late-delivery grain | Existing DAX counts late purchase rows but divides by distinct purchase orders. Multi-line orders can inflate the rate. |
| POS semantic paths | [Relationships](<../powerbi/Retail Analytics Model.SemanticModel/definition/relationships.tmdl>) contain no date/channel paths for POSDeviceChange. Those slicer paths are not established by this export. |

## Design limitations

- **Historical attribution:** Sales/Purchase/Overtime loaders join current dimension versions. Existing facts retain keys, but backfills can receive current attributes; load timestamps are not source-effective dates.
- **Late arrivals and corrections:** completed-date windows and insert-only facts do not provide automatic replay/restatement.
- **HR ordering:** zipWithIndex supplies an execution index rather than a persisted source sequence across ingestion runs.
- **Recovery/concurrency:** the selected procedures do not define a single transaction across related changes; overlap and partial-failure recovery need explicit tests.
- **Interpretation:** promotional ratios and before/after cohorts are descriptive. Absence-rate denominator and financial-cost assumptions need agreed definitions.

## Review concerns requiring execution or additional context

| Concern | Next check |
|---|---|
| COGS, financial totals, and date roles | Execute the proposed [read-only financial queries](financial-reconciliation.md); reconcile full-precision product/period totals and inventory/unit assumptions. |
| Marginal prior-period selection | Compare numeric chronological periods against the OFFSET expressions and current visual/filter context. Chronological axis labels alone do not resolve this. |
| Device-change detection | Inspect the deployed fact loader and compare known installation/replacement events. Its full loader is outside the selected SQL subset. |
| Audit/failure propagation | Induce an approved failure case and verify parent status, correlated logs, and unchanged control state. Current images show success paths. |
| Grain and referential integrity | Check unique business keys, exactly one dimension match, orphan keys, and stable references on rerun; reconcile fact totals to retained/rejected source rows. |

Distance-based vendor analysis and customer-retention/frequency metrics are [future improvements](business-requirements.md). Screenshots of SCD fields or relationships do not by themselves establish historical attribution, key integrity, or DAX correctness.
