# Setup and reproduction boundaries

[Overview](../README.md) | [Architecture](../architecture/README.md) | [Validation](validation.md)

## Review the portfolio

No deployment is required. Start with the root README, then inspect the business trace, diagrams, source examples, and evidence. The selected implementation preserves existing behavior with confidentiality substitutions.

This is **not an import-ready deployment**. Workspace/item IDs, connection handles, and storage endpoints are placeholders. Original credentials, source data, full provisioning/setup, and a complete set of pipeline dependencies are not supplied. Do not execute these examples against an existing environment as though the bindings were valid.

## Offline examples

Python 3.9+ is sufficient, with no third-party packages or network access:

```text
python documentation/validation/run_examples.py
```

The runner checks fictional arithmetic, a reference rerun/duplicate contract, and known-limitation examples. It writes no output files. It does not execute Spark, T-SQL, DAX, or Fabric. [Sample data](../data/sample-data/README.md) supports individual examples, not a validated full pipeline run.

## Retained native structure and illustrative excerpts

- The semantic-model folder retains its descriptor, compatibility/model definitions, all referenced tables/helpers, relationship definitions, and shared storage expression. The expression is sanitized; structure is useful for technical review, not proof of deployability.
- Pipeline/Copy Job folders retain their content definitions. Notebook folders retain readable Fabric source with kernel/dependency comments. Their original environment handles are substituted; external services and some invoked objects are absent.
- SQL preserves canonical table/schema definitions and eight selected procedures. dbo.Date is calendar staging, FactLoadControl is load state, and PipelineExecutionLog supports auditing. Other procedures invoked by Gold are deliberately omitted from this selected example set; this is not a complete migration or setup package.
- Report files under [report-excerpts](../powerbi/report-excerpts/README.md) are explicitly illustrative page settings and a model reference. No visual definitions, theme/resource package, report entry configuration, or complete report is implied.

No .platform files, schedules, SQL project descriptor, original data, or notebook output containers are included. None is required to read the selected excerpts. Missing workspace-integration metadata is not silently presented as a working native deployment.

Live operation depends on suitable Fabric capacity, permissions, SQL Server/FileServer connections, any required gateway, and deployed items. These configurations and costs have not been reproduced; infrastructure-as-code and CI/CD are not claimed. Existing screenshots support execution and design with the limits in [validation](validation.md).
