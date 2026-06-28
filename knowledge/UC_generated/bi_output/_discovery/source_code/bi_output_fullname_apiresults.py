# ==========================================================================
# Source: system.access.table_lineage → Workspace API export
# Object:  main.bi_output.bi_output_fullname_apiresults
# Writer:  /Workspace/Shared/BI/BI CY/Ad hoc and Projects/Teams/FCMU/AI Fake Name Processing
# Language: PYTHON
# Captured: 2026-06-19T14:27:06Z
# Source URL: databricks://workspace/Workspace/Shared/BI/BI CY/Ad hoc and Projects/Teams/FCMU/AI Fake Name Processing
# ==========================================================================

# >>>>> writer #1 role=primary job=384802822442789 task=AI_Fake_Name_Processing
# Databricks notebook source
# =========================================
# Full Name QC (daily): yesterday-only + skip existing CIDs
# Merged: your previous debug/sample/main-run + new delta/merge logic
# =========================================

# -------- CONFIG --------
SOURCE_TABLE = "main.pii_data.bronze_etoro_customer_customer"
TARGET_TABLE = "main.bi_output.bi_output_fullname_apiresults"
DB_FOR_TARGET = "main.bi_output"

# Timezone behavior for "yesterday"
USE_LOCAL_TZ = True                # True -> use Europe/Dublin local yesterday; False -> use simple date(to_timestamp)
LOCAL_TZ = "Europe/Dublin"

# Safety caps / batching
BATCH_SIZE = 100                   # names per OpenAI call
MAX_NAMES_PER_RUN = 5000           # cap for a single run to control costs
DO_DEBUG_SAMPLES = True            # show schema + sample counts
DO_SAMPLE_TEST = True              # run a 20-name test before the main run

# OpenAI model
%pip install openai
from openai import OpenAI
OPENAI_MODEL = "gpt-4o"

# =========================================
# Imports
# =========================================
import os, json, time
import pandas as pd

from pyspark.sql import functions as F
from pyspark.sql.functions import (
    col, trim, length, concat_ws, initcap, to_date, current_date, date_sub
)

# ---- OpenAI client ----
# Preferred: set OPENAI_API_KEY in cluster env vars or via secrets
# Example secrets:
# api_key = dbutils.secrets.get(scope="openai", key="OPENAI_API_KEY")
# from openai import OpenAI
# client = OpenAI(api_key=api_key)



# ---- OpenAI client (prefer env var) ----
# Set this once per cluster/session (or configure via Secrets)
os.environ["OPENAI_API_KEY"] = "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"  # <-- better: set in cluster env/secret scope
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))  # will raise if not set



def validate_names_with_ai(names_list, retries=2):
    """Calls OpenAI once for a batch of names. Returns list of {name, classification, reason} dicts."""
    prompt = f"""
    You are an expert fraud detection analyst. Analyze these names and classify each as:
    - 'Likely Real': Standard, common, or plausible human names
    - 'Suspicious': Unusual but possibly real
    - 'Likely Fake': Gibberish, keyboard spam, placeholder text

    You must ONLY use one of these three categories for each name—do not use any other phrase, synonym, or category.
    Names to analyze: {', '.join([f'"{name}"' for name in names_list])}

    Return JSON object with 'results' array containing objects with 'name', 'classification', 'reason'.
    """
    for attempt in range(retries + 1):
        try:
            r = client.chat.completions.create(
                model=OPENAI_MODEL,
                messages=[{"role": "user", "content": prompt}],
                response_format={"type": "json_object"}
            )
            return json.loads(r.choices[0].message.content).get("results", [])
        except Exception as e:
            print(f"OpenAI error ({attempt+1}/{retries+1}): {e}")
            if attempt < retries:
                time.sleep(1.5*(attempt+1))
    return []


# =========================================
# 1) LOAD + DEBUG (optional)
# =========================================
df = spark.table(SOURCE_TABLE).select("CID", "FirstName", "LastName", "Registered")

if DO_DEBUG_SAMPLES:
    print("Schema:")
    df.printSchema()
    total = df.count()
    null_fn = df.filter(col("FirstName").isNull()).count()
    null_ln = df.filter(col("LastName").isNull()).count()
    blank_fn = df.filter((col("FirstName").isNotNull()) & (length(trim(col("FirstName"))) == 0)).count()
    blank_ln = df.filter((col("LastName").isNotNull()) & (length(trim(col("LastName"))) == 0)).count()
    print(f"Total: {total}, NULL FirstName: {null_fn}, NULL LastName: {null_ln}, "
          f"blank FirstName: {blank_fn}, blank LastName: {blank_ln}")


# =========================================
# 2) YESTERDAY FILTER
#    - If Registered is UTC and you care about Dublin-local date, use from_utc_timestamp
# =========================================
from pyspark.sql.functions import to_date, current_date, date_sub

# Last 15 days window (excluding today)
start_date = date_sub(current_date(), 3)  # 3 days ago
end_date   = current_date()                # today (exclusive)

if USE_LOCAL_TZ:
    reg_date = to_date(F.from_utc_timestamp(col("Registered"), LOCAL_TZ))
else:
    reg_date = to_date(col("Registered"))

last15_df = df.filter((reg_date >= start_date) & (reg_date < end_date))

print("Yesterday (server thought) =", spark.sql("select date_sub(current_date(),1) as d").collect()[0]["d"])
print("Rows after yesterday filter:", last15_df.count())


# =========================================
# 3) CLEAN NAMES (both present + non-blank) and build full_name
# =========================================
clean_df = (
    last15_df
    .filter(col("FirstName").isNotNull() & col("LastName").isNotNull())
    .filter((length(trim(col("FirstName"))) > 0) & (length(trim(col("LastName"))) > 0))
    .withColumn("full_name", concat_ws(" ", initcap(trim(col("FirstName"))), initcap(trim(col("LastName")))))
    .select("CID", "FirstName", "LastName", "full_name")
    .dropDuplicates(["CID"])  # safety
)

print("Clean rows with both names:", clean_df.count())
clean_df.show(10, truncate=False)


# =========================================
# 4) SKIP CIDs ALREADY IN TARGET
# =========================================
if spark.catalog.tableExists(TARGET_TABLE):
    existing_cids = spark.table(TARGET_TABLE).select("CID").distinct()
    new_df = clean_df.join(existing_cids, on="CID", how="left_anti")
else:
    new_df = clean_df

candidates = new_df.count()
print("New CIDs to evaluate today:", candidates)

if candidates == 0:
    print("No new CIDs to process today. Exiting early.")
    dbutils.notebook.exit("OK: nothing to do")


# =========================================
# 5) DEBUG SAMPLE TEST (optional, runs before main)
# =========================================
if DO_SAMPLE_TEST:
    sample_pd = new_df.limit(20).toPandas()
    sample_names = sample_pd["full_name"].tolist()
    print("Testing on 20 names:", sample_names)
    test_results = validate_names_with_ai(sample_names)
    test_results_df = pd.DataFrame(test_results)
    if not test_results_df.empty and "name" in test_results_df.columns:
        test_merged = sample_pd.merge(test_results_df, how="left", left_on="full_name", right_on="name")
        print("Sample test output:\n", test_merged[["CID", "FirstName", "LastName", "classification", "reason"]].head())
    else:
        print("Warning: Sample test returned empty/invalid structure; continuing anyway.")


# =========================================
# 6) MAIN RUN (batched)
# =========================================
# Cap volume to control costs; adjust MAX_NAMES_PER_RUN as needed for your daily throughput
names_list = [r["full_name"] for r in new_df.select("full_name").limit(MAX_NAMES_PER_RUN).collect()]
print(f"Evaluating {len(names_list)} names (capped by MAX_NAMES_PER_RUN={MAX_NAMES_PER_RUN}).")

results = []
for i in range(0, len(names_list), BATCH_SIZE):
    batch = names_list[i:i+BATCH_SIZE]
    print(f"Batch {i//BATCH_SIZE + 1} / {(len(names_list)-1)//BATCH_SIZE + 1} ...")
    out = validate_names_with_ai(batch)
    if isinstance(out, list) and out:
        results.extend(out)
    else:
        print(f"Warning: empty or invalid results for batch {i//BATCH_SIZE + 1}")

if not results:
    print("No results returned from OpenAI; nothing to insert.")
    dbutils.notebook.exit("OK: no results")


# Join results back to the CIDs (for the same limited set we processed)
processed_pd = new_df.limit(MAX_NAMES_PER_RUN).toPandas()
results_pd = pd.DataFrame(results)
final_pd = (
    processed_pd
      .merge(results_pd, how="left", left_on="full_name", right_on="name")
      [["CID", "classification", "reason"]]
)

# Optional audit column for traceability
final_pd["run_date"] = pd.to_datetime("today").date()

from pyspark.sql import functions as F

final_sdf = spark.createDataFrame(final_pd)[["CID", "classification", "reason", "run_date"]]

# Add partition columns based on run_date
final_sdf = (
    final_sdf
    .withColumn("etr_y",   F.year("run_date").cast("int"))
    .withColumn("etr_ym",  F.date_format("run_date", "yyyyMM").cast("int"))
    .withColumn("etr_ymd", F.date_format("run_date", "yyyyMMdd").cast("int"))
)

# =========================================
# 7) WRITE (MERGE insert-only)
# =========================================

spark.sql(f"CREATE DATABASE IF NOT EXISTS {DB_FOR_TARGET}")

from delta.tables import DeltaTable

if spark.catalog.tableExists(TARGET_TABLE):
    tgt = DeltaTable.forName(spark, TARGET_TABLE)
    (tgt.alias("t")
        .merge(final_sdf.alias("s"), "t.CID = s.CID")
        .whenNotMatchedInsert(values={
      "CID":            "s.CID",
    "classification": "s.classification",
    "reason":         "s.reason",
    "run_date":       "s.run_date",
    "etr_y":          "s.etr_y",
    "etr_ym":         "s.etr_ym",
    "etr_ymd":        "s.etr_ymd"
        })
        .execute())
else:
    (final_sdf
        .write
        .format("delta")
        .mode("overwrite")
        .saveAsTable(TARGET_TABLE))

print("Upsert complete.")
spark.sql(f"SELECT * FROM {TARGET_TABLE} ORDER BY run_date DESC, CID LIMIT 20").show(truncate=False)

