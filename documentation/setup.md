# Configuration and offline examples

[Portfolio overview](../README.md) | [Architecture diagram](../architecture/overview.mmd) | [Validation](validation.md)

## Repository use

The repository provides sanitized implementation examples, diagrams, screenshots, and fictional checks. Live connection handles, workspace/item IDs, and storage endpoints are replaced with placeholders. Environment configuration and a complete deployment package are required before cloud execution.

## Environment prerequisites

| Dependency | Configuration needed |
|---|---|
| Fabric workspace and capacity | Permissions to create/run lakehouses, Warehouse, jobs, notebooks, dataflow, model, and reports |
| SQL Server / FileServer | Source access and Fabric connections; gateway connectivity where required for on-premises sources |
| Lakehouses and Warehouse | Correct item bindings and SQL endpoint access; code uses lh_bronze, lh_silver, and dw_gold names |
| Pipeline targets | Deployed Copy Jobs, notebooks, dataflow, procedures, connections, and workspace/item IDs |
| Semantic model/report | Demo or approved storage bindings, table access, model relationships, and report connection |

Actual gateway/security configuration and capacity costs are outside the retained examples. No infrastructure-as-code or automated deployment is supplied.

## Included artifact scope

- **Semantic model:** native descriptor, compatibility/model files, all 27 referenced tables/helpers, shared expression, and relationships.
- **Pipelines/Copy Jobs:** content definitions with their activity graph and mappings; notebook exports retain readable source and dependency comments.
- **Warehouse:** schema/table definitions and eight selected loading/audit procedures. Other Gold-invoked procedures and a complete migration are not included.
- **Report excerpts:** two page configurations ([revenue/profitability](../powerbi/report-excerpts/revenue-profitability-page.json) and [marginal analysis](../powerbi/report-excerpts/marginal-cost-revenue-page.json)) and a model reference. Complete visuals/theme packaging is not included; screenshots demonstrate rendered design.

The code is intended for inspection and adaptation, not direct import. No original source data or credentials are included.

## Run the offline examples

Python 3.9+ and its standard library are sufficient:

```text
python documentation/validation/run_examples.py
```

The fixtures in [data/sample-data](../data/sample-data/fixtures.json) exercise individual calculations and counterexamples. The runner uses in-memory SQLite and writes no files. See [validation](validation.md) for results and pending Fabric checks.
