# Dimensional model and loading examples

[Overview](../README.md) | [Engineering](data-engineering.md) | [Semantic model/KPIs](dashboard-design.md)

**Source scope:** selected Warehouse table and loader definitions preserve existing implementation behavior. They illustrate the design and are not a complete deployment package.

## Selected star relationships

[View the selected star-schema diagram](../architecture/data-model.md) and its [editable Mermaid source](../architecture/data-model.mmd).

This simplified diagram shows selected relationships present in the semantic definitions. Arrows indicate dimension-to-fact context, not a complete cardinality or deployment diagram. [Relationship source](<../powerbi/Retail Analytics Model.SemanticModel/definition/relationships.tmdl>) includes inactive date/hour roles. The original POSDeviceChange fact lacks corresponding semantic date/channel relationships; this diagram does not imply otherwise.

## Facts and intended grains

Grains are inferred from source definitions/loaders and need data-level uniqueness validation.

| Fact definition | Intended grain/context |
|---|---|
| [Sales](../sql/fact/Tables/Sales.sql) | Source transaction ID with product-line attributes; order number groups lines. |
| [Purchase](../sql/fact/Tables/Purchase.sql) | Source purchase transaction ID; vendor, product, store, and multiple date roles. |
| [Overtime](../sql/fact/Tables/Overtime.sql) | Employee overtime event. |
| [Absence](../sql/fact/Tables/Absence.sql) | Retained employee-day record, aggregated by dimensional context. |
| [Misconduct](../sql/fact/Tables/Misconduct.sql) | Retained employee-day incident, aggregated by category/decision context. |
| [POSDeviceChange](../sql/fact/Tables/POSDeviceChange.sql) | Derived channel/device change event; original detection and filtering need review. |

Shared dimensions are Product, Store, Employee, Date, and Time where applicable. Other definitions include Vendor, Customer, Promotion, POSChannel, absence/misconduct categories and decisions, and Product_Basket. All 13 dimension definitions are retained under `sql/dim/Tables/`. Calendar keys are date-derived; do not claim every dimension uses a surrogate key.

## History and attribute replacement

- [Product SCD2 loader](../sql/dbo/StoredProcedures/sp_LoadDimProduct_SCD2.sql), [Vendor SCD2 loader](../sql/dbo/StoredProcedures/sp_LoadDimVendor_SCD2.sql), and [Employee SCD2 loader](../sql/dbo/StoredProcedures/sp_LoadDimEmployee_SCD2.sql) expire changed versions and insert current rows with ValidFrom/ValidTo/IsCurrent. SCD2 means retaining successive attribute versions.
- [Promotion loader](../sql/dbo/StoredProcedures/sp_LoadDimPromotion.sql) demonstrates full replacement of lookup attributes: Type 1-style replacement rather than retained history. It is **not** a key-preserving Type 1 upsert; deleting/reinserting identity rows can orphan existing fact references.
- [Sales](../sql/dbo/StoredProcedures/sp_LoadFactSales.sql), [Purchase](../sql/dbo/StoredProcedures/sp_LoadFactPurchase.sql), and [Overtime](../sql/dbo/StoredProcedures/sp_LoadFactOvertime.sql) illustrate dimension resolution and watermark-based loading.

## Historical attribution limitations

These fact loaders join current dimension versions, not event-date validity intervals. Existing facts retain stored keys, but initial historical loads/backfills can assign today's product, vendor, or employee attributes to older events. Validity timestamps represent observation/load time, not necessarily the business effective date.

Consequently, rebranding, vendor-change, and employee-status comparisons can depend on load timing and cohorts rather than clean before/after history. The original product rename flag also compares after expiration, and basket measures reference a key missing from the original helper schema. These issues are documented, not silently corrected. None of the comparisons demonstrates causation.

## Observed deployed object inventories

The supplied [dimensions](../screenshots/models/warehouse-dimensions.png), [facts](../screenshots/models/warehouse-facts.png), and [procedures](../screenshots/models/warehouse-stored-procedures.png) captures show object inventories. They do not establish model relationships, correct keys, or exact source-version correspondence.

## Semantic-model subject-area layouts

The repository contains one `Retail Analytics Model.SemanticModel` definition referencing Sales, Purchase, Absence, Misconduct, and Overtime, with their relationships in one shared file. The five supplied captures are documented as **subject-area layouts of that shared model**, not five separate semantic models or proof of separate secured perspectives. Runtime model identity and exact source/capture correspondence remain unverified.

The images visibly mark dimensions with `1`, facts with `*`, and show single-arrow filter paths. The source declares exact `fromColumn` (fact) and `toColumn` (dimension) endpoints and explicitly marks inactive paths with `isActive: false`. It does not serialize cardinality or cross-filter overrides. The tables below use the default many-to-one, single-direction interpretation: dimension (`1`) filters fact (`*`), not the reverse. This is consistent with the visible markers and [Microsoft's TMDL relationship guidance](https://github.com/microsoft/skills-for-fabric/blob/main/skills/semantic-model-authoring/references/tmdl-guidelines.md). Omitted properties are not misrepresented here as explicit settings or a runtime verification.

Solid paths are active; dotted paths are inactive. Active paths filter by default; inactive paths require explicit activation in a calculation to apply that role. Selected DAX includes USERELATIONSHIP for Purchase delivery and ship dates; do not assume every inactive date/hour role has a dedicated measure.

**Shared dimensions:** Date and Employee relate to all five facts. Store is shared by Sales, Purchase, Absence, and Misconduct; Product by Sales and Purchase; Time by Sales and Overtime. Vendor is Purchase-specific in these views. Customer, Promotion, and POSChannel provide Sales context; category/decision lookups specialize HR analysis. No direct fact-to-fact relationship is declared in these 33 paths.

Exact columns and active flags below were read from the [relationship definitions](<../powerbi/Retail Analytics Model.SemanticModel/definition/relationships.tmdl>), not inferred from table placement or tiny labels. Every row has fact `*` to dimension `1` cardinality, with single-direction dimension-to-fact filtering under the default interpretation. Active/inactive roles differ as listed.

### Sales

![Sales subject-area layout of the shared semantic model](../screenshots/models/sales-relationships.png)

Sales shares Product, Store, Employee, Date, and Time with other areas and adds Customer, Promotion, and POSChannel. Transaction date/hour are the default roles; order/delivery dates and order hour are inactive.

| Fact column | Dimension column | Status |
|---|---|---|
| `Sales.ChannelKey` | `POSChannel.ChannelKey` | Active |
| `Sales.CustomerKey` | `Customer.CustomerKey` | Active |
| `Sales.DeliveryDateKey` | `Date.DateKey` | Inactive |
| `Sales.EmployeeKey` | `Employee.EmployeeKey` | Active |
| `Sales.PromotionKey` | `Promotion.PromotionKey` | Active |
| `Sales.TransactionHourKey` | `Time.TimeKey` | Active |
| `Sales.StoreKey` | `Store.StoreKey` | Active |
| `Sales.OrderDateKey` | `Date.DateKey` | Inactive |
| `Sales.TransactionDateKey` | `Date.DateKey` | Active |
| `Sales.OrderHourKey` | `Time.TimeKey` | Inactive |
| `Sales.ProductKey` | `Product.ProductKey` | Active |

### Purchase

![Purchase subject-area layout of the shared semantic model](../screenshots/models/purchase-relationships.png)

Purchase shares Product, Store, Employee, and Date and adds Vendor. Transaction date is active; order, delivery, and ship dates are alternative inactive roles.

| Fact column | Dimension column | Status |
|---|---|---|
| `Purchase.DeliveryDateKey` | `Date.DateKey` | Inactive |
| `Purchase.OrderDateKey` | `Date.DateKey` | Inactive |
| `Purchase.ShipDateKey` | `Date.DateKey` | Inactive |
| `Purchase.TransactionDateKey` | `Date.DateKey` | Active |
| `Purchase.EmployeeKey` | `Employee.EmployeeKey` | Active |
| `Purchase.StoreKey` | `Store.StoreKey` | Active |
| `Purchase.VendorKey` | `Vendor.VendorKey` | Active |
| `Purchase.ProductKey` | `Product.ProductKey` | Active |

### Absence

![Absence subject-area layout of the shared semantic model](../screenshots/models/absence-relationships.png)

Absence relates to Date, Employee, Store, and AbsentCategory. All four declared paths are active; no separate inactive date/time role is defined for this fact.

| Fact column | Dimension column | Status |
|---|---|---|
| `Absence.AbsenceCategoryKey` | `AbsentCategory.CategoryKey` | Active |
| `Absence.DateKey` | `Date.DateKey` | Active |
| `Absence.EmployeeKey` | `Employee.EmployeeKey` | Active |
| `Absence.StoreKey` | `Store.StoreKey` | Active |

### Misconduct

![Misconduct subject-area layout of the shared semantic model](../screenshots/models/misconduct-relationships.png)

Misconduct relates to Date, Employee, Store, MisconductCategory, and MisconductDecision. All five paths are active; the decision/category keys are distinct business contexts.

| Fact column | Dimension column | Status |
|---|---|---|
| `Misconduct.DecisionKey` | `MisconductDecision.DecisionKey` | Active |
| `Misconduct.EmployeeKey` | `Employee.EmployeeKey` | Active |
| `Misconduct.MisconductCategoryKey` | `MisconductCategory.CategoryKey` | Active |
| `Misconduct.StoreKey` | `Store.StoreKey` | Active |
| `Misconduct.DateKey` | `Date.DateKey` | Active |

### Overtime

![Overtime subject-area layout of the shared semantic model](../screenshots/models/overtime-relationships.png)

Overtime shares Employee, Date, and Time. Start date/hour are active, while end date/hour are inactive alternatives. There is no Store relationship for Overtime in this source.

| Fact column | Dimension column | Status |
|---|---|---|
| `Overtime.EmployeeKey` | `Employee.EmployeeKey` | Active |
| `Overtime.StartDateKey` | `Date.DateKey` | Active |
| `Overtime.EndDateKey` | `Date.DateKey` | Inactive |
| `Overtime.StartHourKey` | `Time.TimeKey` | Active |
| `Overtime.EndHourKey` | `Time.TimeKey` | Inactive |

### Readability and evidence limits

External black borders were cropped; model content was not changed, resized, or reconstructed. Native publication sizes are Sales 709 x 602, Purchase 593 x 563, Absence 930 x 584, Misconduct 731 x 582, and Overtime 930 x 612 pixels. Layout/cardinality structure is visible. Sales, Purchase, and Misconduct especially need higher-resolution captures for comfortable field-label reading; Absence and Overtime are more readable at native size but should be enlarged for publication-quality field detail. Several source cards already truncate/scroll their field lists; cropping cannot recover hidden fields. Recapture with larger canvas zoom and expanded cards if all key fields must be visible.

Visible IsCurrent/ValidFrom/ValidTo fields demonstrate that attributes exist, not correct SCD history or fact attribution. The current-row loader limitations described above remain. These screenshots do not execute or validate DAX, key uniqueness, referential integrity, totals, or financial outcomes.
