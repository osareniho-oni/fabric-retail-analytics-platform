# Pipelines, ingestion, and calendar dataflow

[Architecture](../architecture/README.md) | [Engineering explanation](../documentation/data-engineering.md)

- [Master](Master_ETL_Pipeline.DataPipeline/pipeline-content.json): Bronze then Silver then Gold.
- [Bronze](<Bronze(Ingestion)_Pipeline.DataPipeline/pipeline-content.json>): ingestion jobs and audit handling.
- [Silver](<Silver(Staging)_Pipeline.DataPipeline/pipeline-content.json>): staging and logging branches.
- [Gold](<Gold(Modeling)_Pipeline.DataPipeline/pipeline-content.json>): dimension/calendar prerequisites and facts.
- [Reference](Ingest_Reference_Tables.CopyJob/copyjob-content.json), [transaction](Ingest_Transaction_Tables.CopyJob/copyjob-content.json), and [HR](Ingest_HR_CSV_Files.CopyJob/copyjob-content.json) ingestion: mappings, sources, and destinations.
- [Calendar Power Query](dataflows/Date_Dataflow.Dataflow/mashup.pq): date generation and staging.

All retain existing behavior with confidentiality substitutions. No schedule or working connection is included. Reference intent is preserved; this subset is not deployment-ready. The inspected [master capture](../screenshots/execution/master-pipeline-success.png) supports one successful original-project run. It does not prove exact source correspondence. [Engineering details](../documentation/data-engineering.md) distinguishes Copy Job incremental configuration, reference overwrite, author-described file replacement, and Gold watermarks.
