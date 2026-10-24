# Selected star relationships

[Architecture](README.md) | [Model documentation](../documentation/data-model.md) | [Editable Mermaid source](data-model.mmd)

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

This is a selected source-defined model view, not an inspected deployed-model screenshot. See the model documentation for omitted relationships, date roles, and historical attribution limits.
