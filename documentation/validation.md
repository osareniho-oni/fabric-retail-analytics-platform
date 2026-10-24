# Validation evidence and limitations

[Overview](../README.md) | [Requirements](requirements-traceability.md) | [Local examples](validation/run_examples.py) | [Financial reconciliation](financial-reconciliation.md)

## What the evidence establishes

- **Observed execution:** the [master capture](../screenshots/execution/master-pipeline-success.png) shows successful Bronze, Silver, and Gold invocations. The [entity log](../screenshots/execution/pipeline-execution-log.png) shows recorded counts/statuses; the [watermark view](../screenshots/validation/fact-load-watermarks.png) shows control state. Neither is a source-to-target reconciliation.
- **Source evidence:** retained definitions illustrate ingestion, transformations, dimensions/facts, measures, and report configuration. The five [subject-area layouts](data-model.md) are consistent with one shared model. Exact source-to-deployed-version correspondence remains unconfirmed.
- **Local examples:** independent Python/SQLite calculations check fictional expectations and reproduce limitations. They do not execute the exported Spark, T-SQL, DAX, or pipelines.
- **Still pending:** full-precision data/model/report reconciliations, failed-run handling, concurrency/recovery, key integrity across reruns, and financial interpretation. Financial screenshots demonstrate report design, not validated outcomes.

## Reproducible offline checks

From the repository root, run:

```text
python documentation/validation/run_examples.py
```

The runner uses standard-library Python and an in-memory SQLite database, performs no network requests, and writes no files. All five groups passed locally during portfolio preparation. Passing a counterexample means a limitation was reproduced, not fixed.

| Check and relevant implementation | Environment | Expected result | Actual result / limits |
|---|---|---|---|
| Sales/order arithmetic; Net Sales and store basket measures | Independent Python fixture | Gross 50, discount 2, net 48, orders 2, units 4, value/order 24, units/order 2, lines/order 1.5 | Matched. Model filters, live source semantics, and DAX were not executed. |
| First/last daily HR intent; file notebook | Independent Python fixture | Explicit-ordinal first absence=2 hours; last misconduct decision=2 under shuffled inputs | Matched. Original notebook does not implement this ordinal contract; distributed input order remains a concern. |
| Duplicate IDs and repeat inserts; Sales loader's intended contract | Independent SQLite/Python reference | Repeat insert retains 3 rows and amount 50; duplicate source IDs rejected | Matched in reference example only. Does not validate Warehouse transactions or lookup-key stability. |
| Late-delivery line/order grain; existing DAX | Independent Python counterexample | Existing row-count/order-count arithmetic=1 versus distinct-order expectation=0.5 | Difference reproduced. No DAX or measure correction. |
| Current-version attribution and completed-date watermarks | Independent Python counterexamples | Old event falls outside next load window; event-time key 11 differs from current key 12 | Reproduced. No late-arrival detector/replay or historical-attribution fix is implemented by this test. |

## Existing Fabric checks still needed

| Check | Expected evidence | Current status |
|---|---|---|
| Referential integrity and grains | Unique business keys, exactly one required dimension match per source row, reconciled fact totals | Loader checks exist; no inspected full data-level reconciliation. |
| Duplicate prevention and reruns | Duplicate source IDs fail; fact totals and referenced dimension keys remain stable | Not established by a successful master run. Original lookup delete/reinsert can regenerate surrogate keys. |
| Audit/failure behavior | Correlated run IDs/counts and failed master status when required work fails | Successful execution and recorded log rows observed; failure/recovery case pending. |
| Regression | Agreed full-precision baseline under recorded version/filter context | Pending; images alone do not certify KPI values. |
| Financial cost bases | Reconciled quantities, date roles, product costing, tax and inventory assumptions | [Read-only SQL/DAX proposals](financial-reconciliation.md) remain unexecuted. |

## Material limitations retained

HR ordering, empty-target calendar initialization, product rename classification, missing basket key, regenerated lookup keys, POS change detection/model paths, and selected KPI definitions need review. Current-dimension joins can misattribute historical events; completed-date watermarks can omit late arrivals/corrections. Atomic recovery and overlapping-run safety are not established. Nearest-vendor distance analysis is missing. Visible SCD fields and relationship diagrams do not prove correct historical attribution or DAX results.

Use the existing project to collect approved, version-labelled reconciliations and larger relationship captures. No new deployment is required just to explain the evidence already available.
