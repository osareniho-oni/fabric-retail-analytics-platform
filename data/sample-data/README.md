# Fictional examples for individual checks

[Validation](../../documentation/validation.md) | [Example runner](../../documentation/validation/run_examples.py) | [Sales/purchase fixture](fixtures.json)

Every record was independently generated for this portfolio. Names, addresses, identifiers, products, and incidents are fictional; no supplied organization records were copied or transformed.

## Contents

- fixtures.json: three sales lines across two orders, three purchase lines across two orders, and stated expectations. Unused source schemas/reference rows are omitted.
- absent_category.csv, misconduct_category.csv, misconduct_decision.csv: small fictional lookup examples.
- absent_data.csv and misconduct_trans.csv: two competing employee-day entries with explicit source_record_ordinal for a deterministic reference calculation.
- overtime_data.csv: two versions of an employee/start-time event for deduplication discussion.

The rows were generated programmatically with explicit small keys, dates, and values. HR physical row order is deliberately reversed. The example ordinal expresses intended source sequence; the existing notebook does not consume that contract. These CSVs are not validated upload-ready inputs for the original pipeline.

## Expected arithmetic and limits

Sales gross=50, discounts=2, net=48, orders=2, units=4, value/order=24, units/order=2, and lines/order=1.5. Purchase spending=150. One distinct late purchase order contains two late lines, exposing the existing late-rate grain mismatch: 1 from line/order counting versus 0.5 from order/order counting. The reference daily HR rule retains two absence hours and misconduct decision 2.

These examples support individual offline checks, not an end-to-end Fabric run, representative workload, or business outcome. Historical and late-arrival examples demonstrate limitations; they do not implement detection, replay, or event-time attribution. Screenshot data is separate and has not been established as synthetic.
