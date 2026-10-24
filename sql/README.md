# Warehouse definitions and selected loaders

[Data model](../documentation/data-model.md) | [Diagram](../architecture/data-model.md) | [Validation](../documentation/validation.md)

`dim/Tables/` contains 13 dimensions; `fact/Tables/` contains six facts. `dbo/Tables/` contains calendar staging, watermark control, and audit tables. `dbo/StoredProcedures/` contains eight selected loading/audit examples.

Start with [Sales loading](dbo/StoredProcedures/sp_LoadFactSales.sql), [Product history](dbo/StoredProcedures/sp_LoadDimProduct_SCD2.sql), [Promotion replacement](dbo/StoredProcedures/sp_LoadDimPromotion.sql), and [audit writing](dbo/StoredProcedures/sp_WritePipelineAudit.sql).

These preserve existing behavior. Current-dimension attribution, late arrivals, lookup-key replacement, and basket/rebranding concerns remain documented. No SQL project, complete setup, or complete procedure set is supplied. No SQL workload or build was run during reorganization.
