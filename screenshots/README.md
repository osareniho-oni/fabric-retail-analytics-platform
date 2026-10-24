# Reviewed screenshots and follow-up captures

[Overview](../README.md) | [Evidence boundaries](../documentation/validation.md) | [Financial review](../documentation/financial-reconciliation.md)

All 18 supplied images were inspected (13 initial captures and five semantic-model layouts). Originals are preserved outside the publication folder; these are local publication candidates with final data/rights approval pending. They show the existing project. Exact correspondence with the staged source snapshot is unverified. Data shown has **not** been established as synthetic.

## Available reviewed crops

| Image | Caption: what it demonstrates | Alteration and material limitation |
|---|---|---|
| [bronze-ingestion](pipelines/bronze-ingestion.png) | Three Copy Job branches and output/audit processing. | Canvas crop; configuration evidence, not repeat-copy or reconciliation proof. |
| [silver-staging](pipelines/silver-staging.png) | Separate table/file notebook branches and success/failure audit paths. | Canvas crop; does not establish deterministic HR ordering or failed-master behavior. |
| [gold-modeling](pipelines/gold-modeling.png) | Dimension/calendar prerequisites before the fact chain. | Canvas crop; does not validate loader results or source/version correspondence. |
| [master-pipeline-success](execution/master-pipeline-success.png) | Succeeded master with successful Bronze, Silver, and Gold invocations. | Crop plus run-ID black mask; dates/statuses intact; exact staged-version match unverified. |
| [pipeline-execution-log](execution/pipeline-execution-log.png) | Visible Gold/Silver entity-level source/target/count/status/time records. | Crop excludes identifier columns; counts/statuses retained; partial preview, not a reconciliation or all-layer audit. |
| [bronze-tables-and-files](storage/bronze-tables-and-files.png) | Bronze SQL table inventory and six CSV Files items. | Chrome/workspace breadcrumb cropped; no source record contents shown. |
| [silver-staging-tables](storage/silver-staging-tables.png) | Silver staging table inventory. | Table-list crop; no contents or quality checks established. |
| [warehouse-dimensions](models/warehouse-dimensions.png) | Warehouse dimension object inventory. | Object-list crop; not an inspected relationship diagram. |
| [warehouse-facts](models/warehouse-facts.png) | Six Warehouse fact objects. | Object-list crop; does not prove grain, key integrity, or correct totals. |
| [warehouse-stored-procedures](models/warehouse-stored-procedures.png) | Warehouse loading and audit procedure inventory. | Object-list crop; no procedure execution/correctness certified. |
| [fact-load-watermarks](validation/fact-load-watermarks.png) | Six fact control records with completed business dates and update timestamps. | Crop plus run-ID values masked; recorded control state only, not a passed reconciliation test. |
| [revenue-profitability](dashboards/revenue-profitability.png) | Revenue/profitability page layout, cards, ranking charts, bridge, and period matrix. | Report canvas crop; financial bases unresolved: report-design evidence, not validated outcomes. |
| [marginal-cost-revenue](dashboards/marginal-cost-revenue.png) | Marginal analysis cards, trend, breakdown, and product table. | Report canvas crop; period selection, quantity bases, and narrative claims unverified. |
| [sales-relationships](models/sales-relationships.png) | Sales subject-area layout in one shared model: Product, Store, Employee, Date, Time, Customer, Promotion, and POSChannel context. | External black border cropped; exact columns/active roles verified in model definitions; small labels need a larger capture. |
| [purchase-relationships](models/purchase-relationships.png) | Purchase layout with shared dimensions, Vendor, and multiple Date roles. | Border cropped; transaction date active, other date roles inactive in source; higher resolution recommended. |
| [absence-relationships](models/absence-relationships.png) | Absence layout with Date, Employee, Store, and AbsentCategory. | Border cropped; source declares four active paths; visible cardinalities do not validate underlying key data. |
| [misconduct-relationships](models/misconduct-relationships.png) | Misconduct layout with shared Date/Employee/Store and category/decision lookups. | Border cropped; source declares five active paths; higher resolution and expanded field cards recommended. |
| [overtime-relationships](models/overtime-relationships.png) | Overtime layout with Employee and start/end Date/Time roles. | Border cropped; start roles active and end roles inactive in source; no DAX correctness or historical-attribution proof. |

Only cropping and opaque identifier masks were used. No status, label, figure, chart, or result was reconstructed or changed. Publication copies were not resized; image metadata was cleared. Browser URLs/tabs, account chrome, taskbars, trial banners, and blank space were removed. No organization-name reference or personal records were observed in retained crops. Visible product labels, totals, row counts, and dates still require final approval.

## Where these are used

The root README embeds the successful master run as primary execution evidence and the Sales subject-area relationship view. Qualified financial images remain in dashboard documentation; detailed log evidence remains linked through supporting reviews. This index captions every included image. Architecture/engineering pages link pipeline/storage views; model documentation links object inventories; dashboard documentation links both report pages; validation links log/control-state captures.

## Specific next captures and checks

| Suggested destination | What to capture | Evidence purpose and linked location |
|---|---|---|
| `dashboards/daily-sales.png` | Daily Sales Movement with approved data and documented date/product/store/promotion filters | Better lead analytical page after revenue, discounts, units, and orders reconcile; root README and dashboard documentation |
| Existing five `models/*-relationships.png` filenames | Higher-resolution views with expanded table cards and larger field labels | Subject-area layouts are now supplied; improve field readability and confirm deployed-model identity for the data-model documentation |
| `validation/selected-reconciliation.png` | One approved full-precision expected/actual source-to-report check | Numerical correctness for the stated version/filter context; validation documentation |
| `pipelines/transaction-copy-settings.png` | Safe incremental Copy Job configuration and key settings | Distinguish source checkpoint/incremental behavior from Gold fact watermarks; engineering documentation |
| `pipelines/hr-file-copy-settings.png` | Safe file replacement configuration or approved repeat-copy observation | Verify author-described file replacement semantics; engineering documentation |
| Existing pipeline image filenames | Recapture at larger canvas zoom if labels are too small | Improve legibility without sharpening/reconstructing source text |

Before capture or approval, inspect organization references, IDs, connection/host names, URLs, account information, people, addresses, incidents, serials, commercial values, filters/tooltips/hidden panes, and error/export details. Use metadata-only captures if data cannot be approved. Record safe capture/version/run context and masking. Never label original-project screenshots as validation of changed code. Add new image links only after the files exist and are reviewed.

## Semantic-model layout evidence

These five views belong to the single shared-model representation in the repository, not five separate semantic models. [Model documentation](../documentation/data-model.md) lists all 33 exact paths and distinguishes explicit inactive flags from default cardinality/filter behavior. Date/Employee are shared across all five facts; other shared dimensions vary by area. Sales, Purchase, and Misconduct most need higher-resolution field detail. Absence/Overtime are usable for an overview at native size, with enlarged recaptures recommended for complete key labels. Source cards already hide/truncate some fields. No model content or labels were altered, and the images do not validate DAX or historical attribution.
