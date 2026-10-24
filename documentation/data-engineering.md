# Data engineering examples

[Overview](../README.md) | [Model/loaders](data-model.md) | [Validation](validation.md)

**Version status:** every artifact here is a sanitized copy of the existing implementation. No proposed behavioral corrections were applied. Invalid environment bindings are deliberate confidentiality placeholders. These are code-review examples, not a complete runnable package.

## Ingestion and orchestration

| Evidence | Purpose | Limitation |
|---|---|---|
| [Master pipeline](../pipelines/Master_ETL_Pipeline.DataPipeline/pipeline-content.json) | Invokes Bronze, Silver, then Gold with completion dependencies. | Supplied master image shows three successful invocations; exact source version remains unverified. |
| [Bronze pipeline](<../pipelines/Bronze(Ingestion)_Pipeline.DataPipeline/pipeline-content.json>) | Invokes reference, transaction, and HR Copy Jobs; processes outputs for auditing. | External connections and Copy Job output behavior need Fabric evidence. |
| [Reference Copy Job](../pipelines/Ingest_Reference_Tables.CopyJob/copyjob-content.json) | Batch overwrite of SQL Server reference tables. | Source availability and full-copy consistency unverified. |
| [Transaction Copy Job](../pipelines/Ingest_Transaction_Tables.CopyJob/copyjob-content.json) | CDC-mode/snapshot-plus-incremental configuration with transaction-ID settings and append targets. | Does not prove source-side CDC or complete update/delete propagation. |
| [HR Copy Job](../pipelines/Ingest_HR_CSV_Files.CopyJob/copyjob-content.json) | Six FileServer CSV inputs to Bronze files, with ingestion timestamps. | Source schema/order and connector execution unverified. |
| [Silver pipeline](<../pipelines/Silver(Staging)_Pipeline.DataPipeline/pipeline-content.json>) | Table/file notebooks and success/failure audit branches. | Logging branches alone do not prove correct parent failure status. |
| [Gold pipeline](<../pipelines/Gold(Modeling)_Pipeline.DataPipeline/pipeline-content.json>) | Dimension-before-fact loading and calendar preparation. | Original calendar initialization and POS sequencing concerns are retained. |

## Transformation and business rules

- [Table notebook](../notebooks/Tables_Staging_Notebook.Notebook/notebook-content.py): Spark SQL renaming, type conversions, reference ranking, date/hour extraction, and Silver table replacement. Sales/Purchase staging does not silently resolve conflicting transaction IDs; fact loaders contain fail-fast checks.
- [File notebook](../notebooks/Files_Staging_Notebook.Notebook/notebook-content.py): explicit schemas, date parsing, prior-day filtering, first daily absence and last daily misconduct retention, overtime event deduplication, Delta writes, and JSON audit payloads.
- [Calendar Power Query](../pipelines/dataflows/Date_Dataflow.Dataflow/mashup.pq): generated date attributes and Warehouse staging binding.

The original HR notebook infers row order through distributed zipWithIndex. That does not establish a deterministic source-sequence contract. This limitation remains in the retained source and has not been resolved by the offline reference examples.

## Incremental loading and observability

The [Sales loader](../sql/dbo/StoredProcedures/sp_LoadFactSales.sql) uses completed business dates, checks null/duplicate transaction IDs, resolves dimensions, compares source/join counts, prevents existing-ID inserts, and audits success/failure. The [audit procedure](../sql/dbo/StoredProcedures/sp_WritePipelineAudit.sql) stores correlated run IDs and counts.

These controls demonstrate implementation intent. They do not establish late-arrival support, atomic recovery, concurrency safety, monitoring alerts, or numerical reconciliation. Late-arriving old-dated events can fall outside subsequent watermark windows. See the [validation ledger](validation.md).

## Supplied visual evidence

Reviewed crops show [Bronze](../screenshots/pipelines/bronze-ingestion.png), [Silver](../screenshots/pipelines/silver-staging.png), [Gold](../screenshots/pipelines/gold-modeling.png), [Bronze Tables/Files](../screenshots/storage/bronze-tables-and-files.png), and [Silver staging tables](../screenshots/storage/silver-staging-tables.png). These support configured paths/inventories; the ingestion distinctions below explains source incrementality versus explicit Gold fact watermarks and the limits of file replacement evidence.

## Ingestion distinctions and external configuration

Transaction Copy Job settings specify CDC mode, SnapshotPlusIncremental, TransactionID change settings, an initial Truncate behavior, and append destinations. They do not expose a persisted source watermark or prove source-side log-based SQL CDC. This is distinct from Gold FactLoadControl's explicit LastCompletedBusinessDate watermark.

Reference destinations use batch Overwrite. HR destinations are named CSV files copied from FileServer into Bronze Files with FlattenHierarchy. File replacement is author-described; exported settings alone do not establish repeat-copy overwrite behavior. Do not describe CSV handling as SQL table truncation.

The author identifies on-premises SQL Server as the source. Connection types are visible, but gateway installation/configuration, credentials, permissions, and runtime checkpoints were not inspected. Matching downloaded notebook sources corroborated the retained text; no embedded notebook outputs are published.
