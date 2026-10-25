# Business requirements and implementation traceability

[Portfolio overview](../README.md) | [Architecture diagram](../architecture/overview.mmd) | [KPI glossary](dashboard-design.md) | [Validation](validation.md)

## Business context

Retail operations combine sales transactions, supplier deliveries, product changes, and workforce events. The project brings these sources into a common analytical platform for operations, procurement, workforce, and finance questions: product movement, promotion mix, co-purchases, delivery duration, time-of-day demand, and employee trends.

## My contribution

I designed and built the Microsoft Fabric solution using a SQL Server operational source. My implementation covers Fabric pipelines and Copy Jobs, lakehouse ingestion and staging, Spark transformations, dimensional Warehouse loading, semantic modelling, DAX, and Power BI report design.

I translated the project's analytical objectives into cleansing and retention rules, fact grains, dimension history, KPI definitions, report layouts, and validation questions. The trace below connects those business-analysis decisions to the implemented data and analytics components, including known gaps.

## Requirements-to-implementation trace

The IDs organize the project's analytical needs. **Implemented** means a supporting code path exists; **Partial** identifies a scope or logic gap; **Future improvement** identifies work not implemented. Execution evidence and correctness checks are recorded separately in [validation](validation.md).

Common evidence: [table transformations](../notebooks/Tables_Staging_Notebook.Notebook/notebook-content.py), [HR transformations](../notebooks/Files_Staging_Notebook.Notebook/notebook-content.py), [DAX measures](<../powerbi/Retail Analytics Model.SemanticModel/definition/tables/_Measures.tmdl>), and [relationships](<../powerbi/Retail Analytics Model.SemanticModel/definition/relationships.tmdl>). Named measures are in the linked measure file; report topics are described in [dashboard design](dashboard-design.md).

| ID / analytical need | Transformation, tables, measures, and report page | Coverage and evidence boundary |
|---|---|---|
| R01 Daily product movement and promotion comparison | SQL sales staging -> fact.Sales and Product/Promotion/Date; Net Sales, Total Units Sold, Promo Sales Share %; Daily Sales Movement | Implemented; descriptive comparisons only. Promo Lift is a ratio of sales totals, not causal lift. |
| R02 Products bought together | Sales staging and Product_Basket projection -> fact.Sales, dim.Product, dim.Product_Basket; Co-Purchased Orders, Attachment Rate %; Market Basket | Partial; original measures reference a ProductKey missing from helper table/model. Other basket formulas also exist; validate the actual page's selected measures. |
| R03 Device replacement frequency | POS channel staging/history -> fact.POSDeviceChange, dim.POSChannel; POS Replacement Count/Frequency; POS Replacements | Partial; device-change history needs runtime review, and the exported semantic model lacks date/channel relationships for this fact. |
| R04 Most ordered products per vendor/store | Purchase staging -> fact.Purchase, Product/Vendor/Store; Total Purchase Quantity, Vendor Product Rank; Vendor & Supply Chain | Implemented; grain, ranking context, ties, and Top N behavior unverified. |
| R05 Delivery comparison around vendor changes | Vendor SCD2 plus Purchase loader -> dim.Vendor/fact.Purchase; Pre-/Post-Change Avg Delivery Days; Vendor & Supply Chain | Partial; current/expired cohorts and current-row fact joins do not guarantee event-time attribution. Descriptive only. |
| R06 Sales around product renaming/rebranding | Product SCD2 plus Sales loader; Rebrand Sales Lift %, Product Rebranding calculation group; Rebranding Impact | Partial; flag logic, current-only group filters, and historical attribution need review. A rename is not proof of a marketing event or causal effect. |
| R07 Overtime across employee status changes | HR event parsing/deduplication plus employee SCD2 -> Overtime/Employee; Total Overtime Hours and status-filtered measures; Employee Overtime | Partial; source-effective status history is not established. Do not infer personal-status changes cause overtime differences. |
| R08 Total versus rebranded-product sales | Product and Sales -> Total Brand Sales, Rebranded Product Sales, Rebrand Sales Contribution %; Rebranding Impact | Partial; totals require trustworthy classification and reconciliation. |
| R09 Vendor delivery duration | Purchase date fields -> Purchase/Vendor/Date; Avg Vendor Delivery Days, Vendor Delivery Efficiency Rank, Late Delivery Rate %; Vendor & Supply Chain | Implemented duration definitions; average is line-weighted and original late-rate numerator counts lines while denominator counts orders. Coded 14-day threshold is not confirmed as agreed business policy. |
| R10 Product demand by time of day | Sales timestamp/hour extraction -> Sales/Time/Product; Product Rank by Time Period, Time Period Units Share %; Time-of-Day Demand | Implemented; validate time zones, period boundaries, and ranking filters. |
| R11 Misconduct patterns | Last employee-day HR entry -> Misconduct/Employee/Store/Category/Decision; Total Misconduct Incidents, Employees with Misconduct; Employee Misconduct | Implemented definitions; deterministic source ordering and totals unverified.  |
| R12 Absence trends for workforce planning | First employee-day HR entry -> Absence/Employee/Store/Category/Date; Total Absent Hours, Total Absence Incidents, Absence Rate %; Employee Absenteeism | Partial; trends defined, but fixed 160-hour baseline and version-based person counts limit the rate.  |
| R13a Marginal revenue and purchasing cost | Sales/Purchase and date context -> Marginal Revenue, Marginal Production Cost; Marginal Cost & Revenue Analysis | Partial; purchase-cost interpretation and prior-period selection need reconciliation. |
| R13b Year/quarter/month financial comparisons | Sales/Purchase/Date; Time Intelligence calculation group; Revenue & Profitability Performance | Implemented calculation definitions; accounting meaning, filter contexts, COGS, and values unverified. |
| R13c Nearest vendor by product/delivery context | Vendor/store addresses exist; no distance/routing transformation, measure, or matching page found | Future improvement: geographic/road distance and eligible vendor selection are not implemented. |

## Acceptance focus and future improvements

Useful acceptance checks trace a source field through transformation, dimensional keys, measure, and visual; reconcile full-precision totals; and verify duplicate, missing-key, and rerun behavior. These are proposed acceptance checks, with current results in the validation document.

Optional extensions include nearest-vendor distance analysis, customer-retention cohorts, and customer order frequency over a defined period. Historical effective-date attribution and late-arrival/correction handling are engineering improvements discussed with the current limitations. Separate Analysis Services cubes and Tableau outputs are outside this Fabric implementation.
