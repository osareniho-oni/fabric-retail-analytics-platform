# Data engineering

[Portfolio overview](../README.md) | [Architecture diagram](../architecture/overview.mmd) | [Data model](data-model.md) | [Validation](validation.md)

## Ingestion choices

| Source | Inspected configuration | Landing area |
|---|---|---|
| [Sales and purchase transactions](../pipelines/Ingest_Transaction_Tables.CopyJob/copyjob-content.json) | CDC job mode, SnapshotPlusIncremental reads, TransactionID change settings, initial Truncate behavior, and Append destinations | Bronze Tables |
| [Reference tables](../pipelines/Ingest_Reference_Tables.CopyJob/copyjob-content.json) | Batch ingestion with Overwrite destinations | Bronze Tables |
| [Six HR CSVs](../pipelines/Ingest_HR_CSV_Files.CopyJob/copyjob-content.json) | Batch FileServer copies with named files, FlattenHierarchy, and ingestion timestamps | Bronze Files |

Transaction settings support snapshot-plus-incremental ingestion; they do not expose a persisted source checkpoint or establish source-side log-based SQL CDC. This is distinct from Gold's explicit LastCompletedBusinessDate control.

The implementation narrative describes refreshed/replaced HR files. The export records batch file copies without an explicit overwrite flag; repeat-copy semantics remain a configuration check. Reference table replacement is explicit in the Overwrite setting.

## Transformation paths

- [Table notebook](../notebooks/Tables_Staging_Notebook.Notebook/notebook-content.py): Spark SQL renaming, type conversion, selected reference ranking, date/hour extraction, and Silver table replacement.
- [HR notebook](../notebooks/Files_Staging_Notebook.Notebook/notebook-content.py): explicit schemas, date parsing, prior-day filtering, first daily absence / last daily misconduct retention, overtime deduplication, Delta writes, and audit payloads.
- [Calendar query](../pipelines/dataflows/Date_Dataflow.Dataflow/mashup.pq): dates from 2014 through the current year with reporting attributes.

Both transformation paths converge into Silver. HR first/last selection relies on inferred distributed input order; a stable source sequence is an improvement identified in [validation](validation.md).

## Warehouse loading

The [Sales loader](../sql/dbo/StoredProcedures/sp_LoadFactSales.sql) calculates a business-date window from FactLoadControl, rejects null/duplicate source IDs, resolves dimension keys, checks joined counts, inserts absent transaction IDs, advances the watermark, and records status. [Purchase](../sql/dbo/StoredProcedures/sp_LoadFactPurchase.sql) and [Overtime](../sql/dbo/StoredProcedures/sp_LoadFactOvertime.sql) illustrate related patterns.

Incremental date windows avoid reloading completed periods. Their tradeoff is that old-dated late arrivals and corrections need a replay/restatement policy; current code does not provide one.

## Dependencies and monitoring

[Master](../pipelines/Master_ETL_Pipeline.DataPipeline/pipeline-content.json), [Bronze](<../pipelines/Bronze(Ingestion)_Pipeline.DataPipeline/pipeline-content.json>), [Silver](<../pipelines/Silver(Staging)_Pipeline.DataPipeline/pipeline-content.json>), and [Gold](<../pipelines/Gold(Modeling)_Pipeline.DataPipeline/pipeline-content.json>) definitions show completion dependencies, parallel staging, dimension-before-fact sequencing, and logging branches.

Copy Job outputs, notebook row-count payloads, and [procedure audit calls](../sql/dbo/StoredProcedures/sp_WritePipelineAudit.sql) feed PipelineExecutionLog. The [master-run capture](../screenshots/execution/master-pipeline-success.png) and [log preview](../screenshots/execution/pipeline-execution-log.png) provide execution context. Failure propagation, overlapping runs, and partial-write recovery remain acceptance checks.
