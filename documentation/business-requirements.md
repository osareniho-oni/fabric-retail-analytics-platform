# Business problem and requirements

[Overview](../README.md) | [Architecture](../architecture/README.md) | [Traceability](requirements-traceability.md)

## Context and intended decisions

Retail transactions, supplier deliveries, and workforce files answer related questions but arrive in different structures. The supplied training case called for an integrated analytical view of product movement, purchasing, point-of-sale changes, employee events, and financial trends.

Intended users are operations, procurement, workforce, and finance analysts, inferred from the case. There is no claim that these were actual project stakeholders or that the solution changed business outcomes.

## Supplied needs versus implementation decisions

The analytical needs came from a closed training programme. The original document is not included. The [traceability matrix](requirements-traceability.md) is a neutral summary linked to source evidence, not a reproduction of that document.

The author independently chose and implemented Fabric pipelines, Copy Jobs, Bronze/Silver lakehouses, Spark staging, a Gold Warehouse, stored-procedure loading, a Direct Lake semantic model, and Power BI reporting. The programme's original technology stack does not imply that this implementation includes SQL Server Analysis Services cubes, Tableau, or the programme's on-premises integration/reporting components.

## Scope and success criteria

Implemented definitions cover ingestion, cleansing, selected dimension history, incremental fact loading, audit records, measures, and eleven report-page topics. Distance-based nearest-vendor selection is missing. Several historical and KPI requirements are partial or unverified.

Proposed reviewer acceptance criteria are: trace a requirement through source fields and transformations to a fact/measure/page; reconcile selected totals; retain valid keys on rerun; and inspect run/error evidence. These are proposed checks, not stakeholder-approved criteria or completed acceptance tests. See [validation status](validation.md).

The author describes an on-premises SQL source, separate transaction/reference/file ingestion strategies, two staging notebooks, procedure-based Gold loading, and cross-layer monitoring. [Engineering details](data-engineering.md) separates that context from inspected settings and supplied execution captures.
