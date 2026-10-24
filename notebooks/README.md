# Transformation notebooks

[Engineering explanation](../documentation/data-engineering.md) | [Validation](../documentation/validation.md)

- [Table staging](Tables_Staging_Notebook.Notebook/notebook-content.py): Spark SQL conformance, ranking, timestamps, and Silver writes.
- [File staging](Files_Staging_Notebook.Notebook/notebook-content.py): HR schemas, date parsing, daily retention rules, overtime deduplication, and audit payloads.

These are sanitized copies of the existing implementation with no behavioral corrections. Environment metadata is substituted. Original HR ordering limitations are retained; no explicit stable-source ordinal contract is implemented. No notebook was executed during this reorganization.

The .py source is the single canonical publication format. Matching downloaded .ipynb copies and their embedded runtime outputs are not included. Kernel/dependency comments are retained for Fabric source context, with environment handles substituted.
