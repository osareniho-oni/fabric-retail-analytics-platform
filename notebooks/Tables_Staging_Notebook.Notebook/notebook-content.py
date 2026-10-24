# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "c41c82a8-aedb-58f1-bcd7-2e777120012b",
# META       "default_lakehouse_name": "lh_bronze",
# META       "default_lakehouse_workspace_id": "9a956fbf-7953-54e6-8798-f4f4de1ae6f8",
# META       "known_lakehouses": [
# META         {
# META           "id": "c41c82a8-aedb-58f1-bcd7-2e777120012b"
# META         }
# META       ]
# META     },
# META     "warehouse": {
# META       "default_warehouse": "89cb5681-4ea4-563a-8ed0-5d0367cf3729",
# META       "known_warehouses": [
# META         {
# META           "id": "89cb5681-4ea4-563a-8ed0-5d0367cf3729",
# META           "type": "Lakewarehouse"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

import json
audit_logs = []

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging: Cities

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_cities AS
    WITH ranked_cities AS (
        SELECT 
            CityID AS city_id, 
            CityName AS city_name, 
            StateID AS state_id,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Using our technical timestamp since there is no source date
            ROW_NUMBER() OVER (
                PARTITION BY CityID 
                ORDER BY ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.City
    )
    SELECT 
        city_id, 
        city_name, 
        state_id,
        ingested_at_mt AS ingested_at
    FROM ranked_cities
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.City").count()
rows_written = spark.table("lh_silver.dbo.stg_cities").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.City",
    "TargetEntity": "lh_silver.dbo.stg_cities",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging: Customers

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_customers AS
    WITH ranked_customers AS (
        SELECT
            CustomerID AS customer_id,
            FirstName AS first_name,
            LastName AS last_name,
            CustomerAddress AS customer_address,
            CityID AS city_id,
            CAST(CreatedDate AS TIMESTAMP) AS created_at,
            CAST(ModifiedDate AS TIMESTAMP) AS updated_at,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Prioritize the source modification date, then ingestion time
            ROW_NUMBER() OVER (
                PARTITION BY CustomerID 
                ORDER BY ModifiedDate DESC, ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.Customer
    )
    SELECT
        customer_id,
        first_name,
        last_name,
        customer_address,
        city_id,
        created_at,
        updated_at,
        ingested_at_mt AS ingested_at
    FROM ranked_customers
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.Customer").count()
rows_written = spark.table("lh_silver.dbo.stg_customers").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.Customer",
    "TargetEntity": "lh_silver.dbo.stg_customers",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging: Departments

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_departments AS
    WITH ranked_departments AS (
        SELECT
            DepartmentID AS department_id,
            Department AS department_name,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Using our technical timestamp since there is no source date
            ROW_NUMBER() OVER (
                PARTITION BY DepartmentID 
                ORDER BY ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.Department
    )
    SELECT
        department_id,
        department_name,
        ingested_at_mt AS ingested_at
    FROM ranked_departments
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.Department").count()
rows_written = spark.table("lh_silver.dbo.stg_departments").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.Department",
    "TargetEntity": "lh_silver.dbo.stg_departments",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging Employees

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_employees AS
    WITH ranked_employees AS (
        SELECT
            EmployeeID AS employee_id,
            EmployeeNo AS employee_number,
            FirstName AS first_name,
            LastName AS last_name,
            CAST(DoB AS DATE) AS date_of_birth,
            MaritalStatus AS marital_status_id,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Using our technical timestamp since there is no source date.
            -- This ensures the latest state from each batch is safely prepared for SCD Type 2 down the line.
            ROW_NUMBER() OVER (
                PARTITION BY EmployeeID 
                ORDER BY ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.Employee
    )
    SELECT
        employee_id,
        employee_number,
        first_name,
        last_name,
        date_of_birth,
        marital_status_id,
        ingested_at_mt AS ingested_at
    FROM ranked_employees
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.Employee").count()
rows_written = spark.table("lh_silver.dbo.stg_employees").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.Employee",
    "TargetEntity": "lh_silver.dbo.stg_employees",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging Marital_Status_types

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_marital_status_types AS
    WITH ranked_marital_statuses AS (
        SELECT
            MaritalStatusID AS marital_status_id,
            MaritalStatus AS marital_status,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Using our technical timestamp since there is no source date
            ROW_NUMBER() OVER (
                PARTITION BY MaritalStatusID 
                ORDER BY ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.MaritalStatus
    )
    SELECT
        marital_status_id,
        marital_status,
        ingested_at_mt AS ingested_at
    FROM ranked_marital_statuses
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.MaritalStatus").count()
rows_written = spark.table("lh_silver.dbo.stg_marital_status_types").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.MaritalStatus",
    "TargetEntity": "lh_silver.dbo.stg_marital_status_types",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging POSChannels

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_pos_channels AS
    WITH ranked_pos_channels AS (
        SELECT 
            ChannelID AS channel_id,
            ChannelNo AS channel_number,
            DeviceModel AS device_model,
            SerialNo AS serial_number,
            CAST(InstallationDate AS TIMESTAMP) AS installed_at,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Prioritize the asset installation date to order history, 
            -- falling back on our technical ingestion timestamp for identical records.
            ROW_NUMBER() OVER (
                PARTITION BY ChannelID 
                ORDER BY InstallationDate DESC, ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.POSChannel
    )
    SELECT 
        channel_id,
        channel_number,
        device_model,
        serial_number,
        installed_at,
        ingested_at_mt AS ingested_at
    FROM ranked_pos_channels
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.POSChannel").count()
rows_written = spark.table("lh_silver.dbo.stg_pos_channels").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.POSChannel",
    "TargetEntity": "lh_silver.dbo.stg_pos_channels",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging Products

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_products AS
    WITH ranked_products AS (
        SELECT
            ProductID AS product_id,
            DepartmentID AS department_id,
            Product AS product_name,
            ProductNumber AS product_number,
            CAST(UnitPrice AS DECIMAL(18, 2)) AS unit_price,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Using our technical timestamp since there is no source date.
            -- This ensures that rebranded product names bubble up cleanly to the top.
            ROW_NUMBER() OVER (
                PARTITION BY ProductID 
                ORDER BY ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.Product
    )
    SELECT
        product_id,
        department_id,
        product_name,
        product_number,
        unit_price,
        ingested_at_mt AS ingested_at
    FROM ranked_products
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.Product").count()
rows_written = spark.table("lh_silver.dbo.stg_products").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.Product",
    "TargetEntity": "lh_silver.dbo.stg_products",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging Promotions

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_promotions AS
    WITH ranked_promotions AS (
        SELECT
            PromotionID AS promotion_id,
            PromotionTypeID AS promotion_type_id,
            CAST(StartDate AS DATE) AS start_date,
            CAST(Enddate AS DATE) AS end_date,
            CAST(DiscountPercent AS DECIMAL(5, 2)) AS discount_percent,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Using our technical timestamp since there is no row-level modification date
            ROW_NUMBER() OVER (
                PARTITION BY PromotionID 
                ORDER BY ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.Promotion
    )
    SELECT
        promotion_id,
        promotion_type_id,
        start_date,
        end_date,
        discount_percent,
        ingested_at_mt AS ingested_at
    FROM ranked_promotions
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.Promotion").count()
rows_written = spark.table("lh_silver.dbo.stg_promotions").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.Promotion",
    "TargetEntity": "lh_silver.dbo.stg_promotions",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging Promotion_types

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_promotion_types AS
    WITH ranked_promotion_types AS (
        SELECT
            PromotionTypeID AS promotion_type_id,
            Promotion AS promotion_name,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Using our technical timestamp since there is no source date
            ROW_NUMBER() OVER (
                PARTITION BY PromotionTypeID 
                ORDER BY ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.PromotionType
    )
    SELECT
        promotion_type_id,
        promotion_name,
        ingested_at_mt AS ingested_at
    FROM ranked_promotion_types
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.PromotionType").count()
rows_written = spark.table("lh_silver.dbo.stg_promotion_types").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.PromotionType",
    "TargetEntity": "lh_silver.dbo.stg_promotion_types",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})    

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging Purchase_transactions

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_purchase_transactions AS
    WITH processed_purchases AS (
        SELECT
            TransactionID AS transaction_id,
            TransactionNo AS transaction_number,
            CAST(TransDate AS DATE) AS transaction_date,
            CAST(OrderDate AS DATE) AS order_date,
            CAST(DeliveryDate AS DATE) AS delivery_date,
            CAST(ShipDate AS DATE) AS ship_date,
            VendorID AS vendor_id,
            EmployeeID AS employee_id,
            ProductID AS product_id,
            StoreID AS store_id,
            CAST(Quantity AS INT) AS quantity,
            CAST(TaxAmount AS DECIMAL(18, 2)) AS tax_amount,
            CAST(LineAmount AS DECIMAL(18, 2)) AS line_amount,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt
        FROM lh_bronze.dbo.PurchaseTransaction
    )
    SELECT
        transaction_id,
        transaction_number,
        transaction_date,
        order_date,
        delivery_date,
        ship_date,
        vendor_id,
        employee_id,
        product_id,
        store_id,
        quantity,
        tax_amount,
        line_amount,
        ingested_at_mt AS ingested_at
    FROM processed_purchases
    -- Filter to only keep records where the transaction happened prior to current date
    WHERE transaction_date < TO_DATE(FROM_UTC_TIMESTAMP(CURRENT_TIMESTAMP(), 'America/Edmonton'));
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.PurchaseTransaction").count()
rows_written = spark.table("lh_silver.dbo.stg_purchase_transactions").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.PurchaseTransaction",
    "TargetEntity": "lh_silver.dbo.stg_purchase_transactions",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging sales_transactions

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_sales_transactions AS
    WITH processed_sales AS (
        SELECT
            TransactionID AS transaction_id,
            TransactionNo AS transaction_number,
            CAST(TransDate AS DATE) AS transaction_date,
            HOUR(CAST(TransDate AS TIMESTAMP)) AS transaction_hour,
            CAST(OrderDate AS DATE) AS order_date,
            HOUR(CAST(OrderDate AS TIMESTAMP)) AS order_hour,
            CAST(DeliveryDate AS DATE) AS delivery_date,
            ChannelID AS channel_id,
            CustomerID AS customer_id,
            EmployeeID AS employee_id,
            ProductID AS product_id,
            StoreID AS store_id,
            PromotionID AS promotion_id,
            CAST(Quantity AS INT) AS quantity,
            CAST(TaxAmount AS DECIMAL(18, 2)) AS tax_amount,
            CAST(LineAmount AS DECIMAL(18, 2)) AS line_amount,
            CAST(LineDiscountAmount AS DECIMAL(18, 2)) AS line_discount_amount,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt
        FROM lh_bronze.dbo.SalesTransaction
    )
    SELECT
        transaction_id,
        transaction_number,
        transaction_date,
        transaction_hour,
        order_date,
        order_hour,
        delivery_date,
        channel_id,
        customer_id,
        employee_id,
        product_id,
        store_id,
        promotion_id,
        quantity,
        tax_amount,
        line_amount,
        line_discount_amount,
        ingested_at_mt AS ingested_at
    FROM processed_sales
    -- Filter to only keep records where the transaction happened prior to current date
    WHERE transaction_date < TO_DATE(FROM_UTC_TIMESTAMP(CURRENT_TIMESTAMP(), 'America/Edmonton'))
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.SalesTransaction").count()
rows_written = spark.table("lh_silver.dbo.stg_sales_transactions").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.SalesTransaction",
    "TargetEntity": "lh_silver.dbo.stg_sales_transactions",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging States

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_states AS
    WITH ranked_states AS (
        SELECT
            StateID AS state_id,
            State AS state_name,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Using our technical timestamp since there is no source date
            ROW_NUMBER() OVER (
                PARTITION BY StateID 
                ORDER BY ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.State
    )
    SELECT
        state_id,
        state_name,
        ingested_at_mt AS ingested_at
    FROM ranked_states
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.State").count()
rows_written = spark.table("lh_silver.dbo.stg_states").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.State",
    "TargetEntity": "lh_silver.dbo.stg_states",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# staging Stores

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_stores AS
    WITH ranked_stores AS (
        SELECT
            StoreID AS store_id,
            StateID AS state_id,
            StoreName AS store_name,
            streetAddress AS street_address,
            CityID AS city_id,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Using our technical timestamp since there is no source date
            ROW_NUMBER() OVER (
                PARTITION BY StoreID 
                ORDER BY ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.Store
    )
    SELECT
        store_id,
        state_id,
        store_name,
        street_address,
        city_id,
        ingested_at_mt AS ingested_at
    FROM ranked_stores
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.Store").count()
rows_written = spark.table("lh_silver.dbo.stg_stores").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.Store",
    "TargetEntity": "lh_silver.dbo.stg_stores",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging Vendors

spark.sql("""
    CREATE OR REPLACE TABLE lh_silver.dbo.stg_vendors AS
    WITH ranked_vendors AS (
        SELECT
            VendorID AS vendor_id,
            VendorNo AS vendor_number,
            LastName AS last_name,
            FirstName AS first_name,
            RegistrationNo AS registration_number,
            VendorAddress AS vendor_address,
            CityID AS city_id,
            CAST(CreatedDate AS TIMESTAMP) AS created_at,
            CAST(ModifiedDate AS TIMESTAMP) AS updated_at,
            -- Override UTC timestamp with local Mountain Time
            from_utc_timestamp(CAST(ingested_at AS TIMESTAMP), 'America/Edmonton') AS ingested_at_mt,
            
            -- Deduplicate: Prioritize the source modification date, then ingestion time
            ROW_NUMBER() OVER (
                PARTITION BY VendorID 
                ORDER BY ModifiedDate DESC, ingested_at DESC
            ) AS row_num
        FROM lh_bronze.dbo.Vendor
    )
    SELECT
        vendor_id,
        vendor_number,
        last_name,
        first_name,
        registration_number,
        vendor_address,
        city_id,
        created_at,
        updated_at,
        ingested_at_mt AS ingested_at
    FROM ranked_vendors
    WHERE row_num = 1;
""")

# Capture Metrics
rows_read = spark.table("lh_bronze.dbo.Vendor").count()
rows_written = spark.table("lh_silver.dbo.stg_vendors").count()

# Append to audit list
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "lh_bronze.dbo.Vendor",
    "TargetEntity": "lh_silver.dbo.stg_vendors",
    "RowsRead": rows_read,
    "RowsWritten": rows_written,
    "Status": "Succeeded"
})

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Exit the notebook and send all collected logs to the pipeline
mssparkutils.notebook.exit(json.dumps(audit_logs))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
