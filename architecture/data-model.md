# Selected star relationships

[Portfolio overview](../README.md) | [Model documentation](../documentation/data-model.md) | [Editable Mermaid source](data-model.mmd)

```mermaid
flowchart LR
    Product[Product] --> Sales[Sales fact]
    Store[Store] --> Sales
    Employee[Employee] --> Sales
    Date[Date] --> Sales
    Time[Time] --> Sales
    Customer[Customer] --> Sales
    Promotion[Promotion] --> Sales
    Channel[POSChannel] --> Sales
    Product --> Purchase[Purchase fact]
    Store --> Purchase
    Employee --> Purchase
    Date --> Purchase
    Vendor[Vendor] --> Purchase
```

Selected Sales/Purchase star relationships. The [model documentation](../documentation/data-model.md) covers all five subject areas, date roles, and historical attribution.
