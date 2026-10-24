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

# imports
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DateType, TimestampType
from pyspark.sql import window as W, functions as F

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
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

# spark configuration
spark.conf.set("spark.sql.legacy.timeParserPolicy", "CORRECTED")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Staging: absent_category

# Define Table Schema
absent_category_schema = StructType([
    StructField("category_id", IntegerType(),True),
    StructField("category_name", StringType(), True),
    StructField("ingested_at", TimestampType(), True)
])

# Read data
raw_absent_category_df = spark.read \
    .schema(absent_category_schema) \
    .option("header","True") \
    .csv("Files/absent_category.csv") 

# Overwrite/Add local Mountain Time timestamp
staged_absent_category_df = raw_absent_category_df.withColumn(
    "ingested_at", 
    F.from_utc_timestamp(F.col("ingested_at"), "America/Edmonton")
)

# deduplicate data
# 1. define the window
absent_category_window = W.Window.partitionBy("category_id") \
                      .orderBy(F.col("ingested_at").desc())

# 2. filter for first row in each partition
dedup_absent_category_df = (
    staged_absent_category_df.withColumn("row_num", F.row_number().over(absent_category_window))
    .filter(F.col("row_num") == 1)
    .drop("row_num")
)

# Save to a staging Lakehouse (lh_silver)
dedup_absent_category_df.write \
  .format("delta") \
  .mode("overwrite") \
  .saveAsTable("lh_silver.dbo.stg_absent_categories")
 
# display(dedup_absent_category_df)

rows_read = raw_absent_category_df.count()
rows_written = dedup_absent_category_df.count()

# Create audit payload
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "Files/absent_category.csv",
    "TargetEntity": "lh_silver.dbo.stg_absent_categories",
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

# Staging: absent_data

# Define Table Schema
absent_data_schema = StructType([
    StructField("emp_id", IntegerType(), True),
    StructField("store_id", IntegerType(), True),
    StructField("absent_date", StringType(), True),
    StructField("absent_hour", IntegerType(), True),
    StructField("category_id", IntegerType(), True ),
    StructField("ingested_at", TimestampType(), True)
])

# Read data
raw_absent_data_df = spark.read \
    .schema(absent_data_schema) \
    .option("header","True") \
    .csv("Files/absent_data.csv") 

# Overwrite/Add local Mountain Time timestamp
staged_absent_data_df = raw_absent_data_df.withColumn(
    "ingested_at", 
    F.from_utc_timestamp(F.col("ingested_at"), "America/Edmonton")
)

# deduplicate data to remove duplicates ("The first entry of the absence data for a day is the right record to be retained")
# Add an exact sequential row index based on raw file order
# zipWithIndex guarantees row 0, 1, 2... in exact original order
rdd_with_idx = staged_absent_data_df.rdd.zipWithIndex().map(lambda r: (*r[0], r[1]))
indexed_schema = staged_absent_data_df.schema.add("file_row_idx", "long")
ordered_df = spark.createDataFrame(rdd_with_idx, schema=indexed_schema)

# 3. Transform dates & apply daily deduplication window
parsed_deduped_df = (
    ordered_df
    .withColumn(
        "absent_date",
        F.coalesce(
            F.to_date(F.col("absent_date"), "MM/dd/yyyy"),
            F.to_date(F.col("absent_date"), "M/d/yyyy"),
            F.to_date(F.col("absent_date"), "yyyy-MM-dd")
        )
    )
    .filter(F.col("absent_date") <= F.date_sub(F.to_date(F.from_utc_timestamp(F.current_timestamp(), "America/Edmonton")), 1))
    .withColumn(
        "row_num",
        F.row_number().over(
            W.Window.partitionBy("emp_id", "absent_date").orderBy(F.col("file_row_idx").asc())
        )
    )
    .filter(F.col("row_num") == 1)
    .drop("row_num", "file_row_idx")
)

# Save to a staging Lakehouse (lh_silver)
parsed_deduped_df.write \
  .format("delta") \
  .mode("overwrite") \
  .saveAsTable("lh_silver.dbo.stg_absent_data")
 
 
# display(deduped_absence_df)

rows_read = raw_absent_data_df.count()
rows_written = parsed_deduped_df.count()

# print(rows_read)
# print(rows_written)

# Create audit payload
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "Files/absent_data.csv",
    "TargetEntity": "lh_silver.dbo.stg_absent_data",
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

# Staging: misconduct_category

# Define Table Schema
misconduct_category_schema = StructType([
    StructField("misconduct_id", IntegerType(),True),
    StructField("misconduct_name", StringType(), True),
    StructField("ingested_at", TimestampType(), True)
])

# Read data
raw_misconduct_category_df = spark.read \
    .schema(misconduct_category_schema) \
    .option("header","True") \
    .csv("Files/misconduct_category.csv") 

# Overwrite/Add local Mountain Time timestamp
staged_misconduct_category_df = raw_misconduct_category_df.withColumn(
    "ingested_at", 
    F.from_utc_timestamp(F.col("ingested_at"), "America/Edmonton")
)

# deduplicate data
# 1. define the window
misconduct_category_window = W.Window.partitionBy("misconduct_id") \
                      .orderBy(F.col("ingested_at").desc())

# 2. filter for first row in each partition
deduped_misconduct_category_df = (
    staged_misconduct_category_df.withColumn("row_num", F.row_number().over(misconduct_category_window))
    .filter(F.col("row_num") == 1)
    .drop("row_num")
)

# Save to a staging Lakehouse (lh_silver)
deduped_misconduct_category_df.write \
  .format("delta") \
  .mode("overwrite") \
  .saveAsTable("lh_silver.dbo.stg_misconduct_categories")

 
# display(deduped_misconduct_category_df)

rows_read = raw_misconduct_category_df.count()
rows_written = deduped_misconduct_category_df.count()

# Create audit payload
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "Files/misconduct_category.csv",
    "TargetEntity": "lh_silver.dbo.stg_misconduct_categories",
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

# Staging: misconduct_decision

# Define Table Schema
misconduct_decision_schema = StructType([
    StructField("decision_id", IntegerType(),True),
    StructField("decision_name", StringType(), True),
    StructField("ingested_at", TimestampType(), True) 
])

# Read data
raw_misconduct_decision_df = spark.read \
    .schema(misconduct_decision_schema) \
    .option("header","True") \
    .csv("Files/misconduct_decision.csv") 

# Overwrite/Add local Mountain Time timestamp
staged_misconduct_decision_df = raw_misconduct_decision_df.withColumn(
    "ingested_at", 
    F.from_utc_timestamp(F.col("ingested_at"), "America/Edmonton")
)

# deduplicate data
# 1. define the window
misconduct_decision_window = W.Window.partitionBy("decision_id") \
                      .orderBy(F.col("ingested_at").desc())

# 2. filter for first row in each partition
deduped_misconduct_decision_df = (
    staged_misconduct_decision_df.withColumn("row_num", F.row_number().over(misconduct_decision_window))
    .filter(F.col("row_num") == 1)
    .drop("row_num")
)

# Save to a staging Lakehouse (lh_silver)
deduped_misconduct_decision_df.write \
  .format("delta") \
  .mode("overwrite") \
  .saveAsTable("lh_silver.dbo.stg_misconduct_decisions")

 
# display(deduped_misconduct_decision_df)

rows_read = raw_misconduct_decision_df.count()
rows_written = deduped_misconduct_decision_df.count()

# Create audit payload
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "Files/misconduct_decision.csv",
    "TargetEntity": "lh_silver.dbo.stg_misconduct_decisions",
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

# Staging: misconduct_transactions

# Define Table Schema
misconduct_trans_schema = StructType([
    StructField("emp_id", IntegerType(), True),
    StructField("store_id", IntegerType(), True),
    StructField("misconduct_date", StringType(), True),
    StructField("misconduct_id", IntegerType(), True),
    StructField("decision_id", IntegerType(), True ),
    StructField("ingested_at", TimestampType(), True)
])

# Read data
raw_misconduct_trans_df = spark.read \
    .schema(misconduct_trans_schema) \
    .option("header","True") \
    .csv("Files/misconduct_trans.csv") 

# Overwrite/Add local Mountain Time timestamp
staged_misconduct_trans_df = raw_misconduct_trans_df.withColumn(
    "ingested_at", 
    F.from_utc_timestamp(F.col("ingested_at"), "America/Edmonton")
)

# deduplicate data to remove duplicates ("The last entry of the employee misconduct data for a day is the right record to be retained")
# Add an exact sequential row index based on raw file order
# zipWithIndex guarantees row 0, 1, 2... in exact original order
rdd_with_idx = staged_misconduct_trans_df.rdd.zipWithIndex().map(lambda r: (*r[0], r[1]))
indexed_schema = staged_misconduct_trans_df.schema.add("file_row_idx", "long")
ordered_df = spark.createDataFrame(rdd_with_idx, schema=indexed_schema)

# 3. Transform dates & apply daily deduplication window
parsed_deduped_df = (
    ordered_df
    .withColumn(
        "misconduct_date",
        F.coalesce(
            F.to_date(F.col("misconduct_date"), "MM/dd/yyyy"),
            F.to_date(F.col("misconduct_date"), "M/d/yyyy"),
            F.to_date(F.col("misconduct_date"), "yyyy-MM-dd")
        )
    )
    .filter(F.col("misconduct_date") <= F.date_sub(F.to_date(F.from_utc_timestamp(F.current_timestamp(), "America/Edmonton")), 1))
    .withColumn(
        "row_num",
        F.row_number().over(
            W.Window.partitionBy("emp_id", "misconduct_date").orderBy(F.col("file_row_idx").desc())
        )
    )
    .filter(F.col("row_num") == 1)
    .drop("row_num", "file_row_idx")
)

# Save to a staging Lakehouse (lh_silver)
parsed_deduped_df.write \
  .format("delta") \
  .mode("overwrite") \
  .saveAsTable("lh_silver.dbo.stg_misconduct_transactions")

# display(deduped_misconduct_df)

rows_read = raw_misconduct_trans_df.count()
rows_written = parsed_deduped_df.count()

# print(rows_read)
# print(rows_written)

# # Create audit payload
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "Files/misconduct_trans.csv",
    "TargetEntity": "lh_silver.dbo.stg_misconduct_transactions",
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

# Staging: overtime_data

# Define Table Schema
overtime_data_schema = StructType([
    StructField("overtime_id", IntegerType(), True),
    StructField("employee_number", StringType(), True),
    StructField("first_name", StringType(), True),
    StructField("last_name", StringType(), True),
    StructField("overtime_start_ts", StringType(), True),
    StructField("overtime_end_ts", StringType(), True ),
    StructField("ingested_at", TimestampType(), True)
])

# Read data
raw_overtime_df = spark.read \
    .schema(overtime_data_schema) \
    .option("header","True") \
    .csv("Files/overtime_data.csv") 

# Overwrite/Add local Mountain Time timestamp
staged_overtime_df = raw_overtime_df.withColumn(
    "ingested_at", 
    F.from_utc_timestamp(F.col("ingested_at"), "America/Edmonton")
)

# Transform and parse dates safely
parsed_overtime_df = (
    staged_overtime_df
    # 1. Parse the Start Timestamp
    .withColumn(
        "overtime_start_ts",
        F.coalesce(
            F.to_timestamp(F.col("overtime_start_ts"), "yyyy-MM-dd HH:mm:ss"),
            F.to_timestamp(F.col("overtime_start_ts"), "MM/dd/yyyy HH:mm:ss")
        )
    )
    # 2. Parse the End Timestamp
    .withColumn(
        "overtime_end_ts",
        F.coalesce(
            F.to_timestamp(F.col("overtime_end_ts"), "yyyy-MM-dd HH:mm:ss"),
            F.to_timestamp(F.col("overtime_end_ts"), "MM/dd/yyyy HH:mm:ss")
        )
    )   
    # 3. Filter to only keep dates less than or equal to yesterday
    # Convert timestamp to date using F.to_date() so the comparison works perfectly
    .filter(F.to_date(F.col("overtime_start_ts")) <= F.date_sub(F.to_date(F.from_utc_timestamp(F.current_timestamp(), "America/Edmonton")), 1))
)

# 2. Deduplicate using the Business Grain
# This ensures an employee cannot have two records starting at the exact same second.

overtime_window = W.Window.partitionBy("employee_number", "overtime_start_ts").orderBy(F.col("overtime_id").desc())

deduped_overtime_df = (
    parsed_overtime_df
    .withColumn("row_num", F.row_number().over(overtime_window))
    .filter(F.col("row_num") == 1)
    .drop("row_num")
)

# Save to a staging Lakehouse (lh_silver)
deduped_overtime_df.write \
  .format("delta") \
  .mode("overwrite") \
  .saveAsTable("lh_silver.dbo.stg_overtime_data")


# 3. Verify results
# display(deduped_overtime_df)

rows_read = raw_overtime_df.count()
rows_written = deduped_overtime_df.count()

# print(rows_read)
# print(rows_written)

# Create audit payload
audit_logs.append({
    "Layer": "Silver",
    "SourceEntity": "Files/overtime_data.csv",
    "TargetEntity": "lh_silver.dbo.stg_overtime_data",
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
