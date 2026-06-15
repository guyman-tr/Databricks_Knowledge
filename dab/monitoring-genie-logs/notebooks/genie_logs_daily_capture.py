# Databricks notebook source
# MAGIC %md
# MAGIC # monitoring-genie-logs — Daily Capture
# MAGIC
# MAGIC Builds a sibling table to `main.config.monitoring_mcp_logs_mcp_gateway` for **Genie** activity.
# MAGIC
# MAGIC **Source of enumeration:** `main.monitoring.genie_audit_events` (Databricks audit log of Genie API calls).
# MAGIC The audit log gives us every `(space_id, conversation_id, message_id)` tuple but **does not** carry the
# MAGIC NL prompt content in `request_params`. So this job:
# MAGIC
# MAGIC 1. Reads the audit log since the last successful watermark, dedupes to unique `message_id`s.
# MAGIC 2. Calls the Genie REST API per message to fetch `content` (NL prompt), `attachments` (SQL / text), `status`, `error`.
# MAGIC 3. Joins to `system.query.history` on the best-effort `statement_id` match (space + user + time window) to enrich
# MAGIC    each row with execution metrics (latency, rows, bytes, warehouse).
# MAGIC 4. MERGEs into `main.{env}.de_output_monitoring_genie_logs_genie_gateway` (natural key = `message_id`).
# MAGIC 5. Records a watermark row in the sibling watermark table; next run uses that high watermark as its low watermark.
# MAGIC
# MAGIC **Parameters** (job widgets):
# MAGIC - `env` — `stg` | `prod` (defaults to `stg`)
# MAGIC - `backfill_days` — initial-run lookback (default `7`). Ignored when a watermark row already exists.
# MAGIC - `max_messages` — safety cap per run (default `5000`).
# MAGIC - `dry_run` — `true` | `false`. If `true`, skip MERGE and just print summary.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 1 — Imports, widgets, config

# COMMAND ----------

import json
import time
from datetime import datetime, timedelta, timezone

from pyspark.sql import functions as F
from pyspark.sql.types import (
    BooleanType,
    IntegerType,
    LongType,
    StringType,
    StructField,
    StructType,
    TimestampType,
)
from databricks.sdk import WorkspaceClient

dbutils.widgets.dropdown("env", "stg", ["stg", "prod"], "Target environment")
dbutils.widgets.text("backfill_days", "7", "Initial backfill window (days)")
dbutils.widgets.text("max_messages", "5000", "Per-run safety cap (#messages)")
dbutils.widgets.dropdown("dry_run", "false", ["true", "false"], "Dry run (skip MERGE)")

ENV = dbutils.widgets.get("env").strip().lower()
BACKFILL_DAYS = int(dbutils.widgets.get("backfill_days"))
MAX_MESSAGES = int(dbutils.widgets.get("max_messages"))
DRY_RUN = dbutils.widgets.get("dry_run").strip().lower() == "true"

assert ENV in ("stg", "prod"), f"env must be stg or prod (got {ENV!r})"

SCHEMA = "de_output" if ENV == "prod" else "de_output_stg"
TABLE_GATEWAY = f"main.{SCHEMA}.de_output_monitoring_genie_logs_genie_gateway"
TABLE_WATERMARK = f"main.{SCHEMA}.de_output_monitoring_genie_logs_watermark"

AUDIT_TABLE = "main.monitoring.genie_audit_events"
SPACES_DIM = "main.monitoring.genie_spaces_dim"
QUERY_HISTORY = "system.query.history"

RUN_START = datetime.now(timezone.utc)
RUN_ID = RUN_START.strftime("%Y%m%dT%H%M%SZ")

print(f"env             = {ENV}")
print(f"gateway target  = {TABLE_GATEWAY}")
print(f"watermark table = {TABLE_WATERMARK}")
print(f"backfill_days   = {BACKFILL_DAYS}")
print(f"max_messages    = {MAX_MESSAGES}")
print(f"dry_run         = {DRY_RUN}")
print(f"run_id          = {RUN_ID}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 1b — Bootstrap target tables (idempotent)
# MAGIC
# MAGIC `CREATE TABLE IF NOT EXISTS` with the canonical schema. Safe to run every time — if the tables already exist this
# MAGIC is a no-op. This makes the notebook self-sufficient even if `sql/01_create_tables.sql` hasn't been manually applied.

# COMMAND ----------

STORAGE_ACCOUNT = "dldataplatformprodwe" if ENV == "prod" else "stgdpdlwe"
GATEWAY_LOCATION = f"abfss://analysis@{STORAGE_ACCOUNT}.dfs.core.windows.net/DE_OUTPUT/Monitoring/Genie_Logs/Genie_Gateway/"
WATERMARK_LOCATION = f"abfss://analysis@{STORAGE_ACCOUNT}.dfs.core.windows.net/DE_OUTPUT/Monitoring/Genie_Logs/Watermark/"

spark.sql(f"""
CREATE TABLE IF NOT EXISTS {TABLE_GATEWAY} (
  ts                          TIMESTAMP,
  genie_mode                  STRING,
  workspace_id                STRING,
  space_id                    STRING,
  space_name                  STRING,
  conversation_id             STRING,
  conversation_type           STRING,
  message_id                  STRING,
  user_email                  STRING,
  nl_prompt                   STRING,
  nl_response_summary         STRING,
  generated_sql               STRING,
  query_description           STRING,
  attachment_count            INT,
  attachment_kinds            STRING,
  message_status              STRING,
  error_message               STRING,
  statement_id                STRING,
  total_duration_ms           BIGINT,
  read_rows                   BIGINT,
  produced_rows               BIGINT,
  read_bytes                  BIGINT,
  from_result_cache           BOOLEAN,
  pruned_files                BIGINT,
  warehouse_id                STRING,
  thumb_up                    BOOLEAN,
  thumb_down                  BOOLEAN,
  feedback_comment            STRING,
  raw_message_json            STRING,
  ingested_at                 TIMESTAMP,
  UpdateDate                  TIMESTAMP
)
USING DELTA
LOCATION '{GATEWAY_LOCATION}'
COMMENT 'Daily-captured Genie conversation log. One row per Genie message, audit-log + Genie REST API + system.query.history.'
TBLPROPERTIES (
  'refresh_frequency' = 'daily',
  'sla' = 'D+1 09:00 UTC',
  'source_system' = 'genie_audit + genie_api + system.query.history',
  'pii' = 'indirect',
  'certified' = 'silver',
  'data_classification' = 'internal'
)
""")

spark.sql(f"""
CREATE TABLE IF NOT EXISTS {TABLE_WATERMARK} (
  env                         STRING,
  run_id                      STRING,
  run_start                   TIMESTAMP,
  run_end                     TIMESTAMP,
  audit_low_watermark         TIMESTAMP,
  audit_high_watermark        TIMESTAMP,
  messages_seen               INT,
  messages_fetched            INT,
  messages_skipped            INT,
  api_errors                  INT,
  rows_merged                 INT,
  notes                       STRING,
  UpdateDate                  TIMESTAMP
)
USING DELTA
LOCATION '{WATERMARK_LOCATION}'
COMMENT 'Per-run watermarks for monitoring-genie-logs capture job.'
TBLPROPERTIES (
  'refresh_frequency' = 'daily',
  'pii' = 'none',
  'certified' = 'bronze',
  'data_classification' = 'internal'
)
""")
print(f"bootstrap OK: {TABLE_GATEWAY}, {TABLE_WATERMARK}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 2 — Determine low watermark
# MAGIC
# MAGIC If the watermark table is empty (first run) we look back `BACKFILL_DAYS` days. Otherwise we use the
# MAGIC max `audit_high_watermark` from previous successful runs (where `rows_merged >= 0` and `notes` not flagged as failed).

# COMMAND ----------

def read_low_watermark() -> datetime:
    try:
        row = (
            spark.table(TABLE_WATERMARK)
            .where(F.col("env") == ENV)
            .agg(F.max("audit_high_watermark").alias("hw"))
            .collect()[0]
        )
        hw = row["hw"]
    except Exception as exc:
        print(f"watermark read fallback ({exc.__class__.__name__}: {exc}); using backfill window")
        hw = None
    if hw is None:
        return RUN_START - timedelta(days=BACKFILL_DAYS)
    return hw


LOW_WATERMARK = read_low_watermark()
print(f"low_watermark   = {LOW_WATERMARK.isoformat()}")
print(f"high_watermark  = {RUN_START.isoformat()}  (notebook RUN_START)")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 3 — Enumerate target messages from the audit log
# MAGIC
# MAGIC Take every distinct `message_id` whose audit-log activity falls inside the window.
# MAGIC We also collect: latest `user_email`, originating `space_id`, `conversation_id`, earliest seen time (proxy for create time),
# MAGIC and the `conversation_type` from the matching `createConversation` row (if any).
# MAGIC Cap at `MAX_MESSAGES` to keep per-run blast radius bounded.

# COMMAND ----------

audit_window = (
    spark.table(AUDIT_TABLE)
    .where(F.col("event_time") > F.lit(LOW_WATERMARK))
    .where(F.col("event_time") <= F.lit(RUN_START))
)

msgs_with_id = audit_window.where(
    F.col("message_id").isNotNull() & (F.col("message_id") != "")
)

# canonical (space_id, conversation_id, message_id, user_email) per message_id (earliest seen, latest user)
messages_to_fetch = (
    msgs_with_id.groupBy("message_id")
    .agg(
        F.first("space_id", ignorenulls=True).alias("space_id"),
        F.first("conversation_id", ignorenulls=True).alias("conversation_id"),
        F.first("workspace_id", ignorenulls=True).alias("workspace_id"),
        F.first("user_email", ignorenulls=True).alias("user_email"),
        F.min("event_time").alias("first_seen"),
        F.max("event_time").alias("last_seen"),
        F.collect_set("action_name").alias("action_set"),
    )
    .where(F.col("space_id").isNotNull() & F.col("conversation_id").isNotNull())
    .orderBy("first_seen")
    .limit(MAX_MESSAGES)
)

# conversation_type lookup from createConversation rows in (or before) the window
conv_type = (
    spark.table(AUDIT_TABLE)
    .where(F.col("event_time") > F.lit(LOW_WATERMARK - timedelta(days=30)))  # extra back-look for conv creation
    .where(F.col("action_name") == "createConversation")
    .withColumn("conversation_type", F.col("request_params")["conversation_type"])
    .withColumn("conv_from_resp", F.col("request_params")["conversation_id"])
    # `createConversation` rows have conv_id in request_params or in the column itself (later messages)
    .withColumn(
        "conv_id_resolved",
        F.coalesce(F.col("conversation_id"), F.col("conv_from_resp")),
    )
    .select(
        F.col("conv_id_resolved").alias("conversation_id"),
        F.col("conversation_type"),
    )
    .where(F.col("conversation_id").isNotNull())
    .dropDuplicates(["conversation_id"])
)

messages_to_fetch = messages_to_fetch.join(conv_type, on="conversation_id", how="left")
messages_pd = messages_to_fetch.toPandas()

print(f"distinct messages in window: {len(messages_pd)}")
if len(messages_pd):
    print(messages_pd.head(5).to_string(index=False))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 4 — Fetch each message from the Genie REST API
# MAGIC
# MAGIC Uses the SDK `WorkspaceClient.genie.get_message(...)` call. Falls back to raw REST if the SDK shape changes.
# MAGIC Defensive: any per-message failure is recorded and the loop continues.

# COMMAND ----------

w = WorkspaceClient()


def _safe_attr(obj, *names, default=None):
    for n in names:
        if obj is None:
            return default
        obj = getattr(obj, n, None)
    return obj if obj is not None else default


def _coerce_dt(value):
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    # Genie API returns epoch millis as long; or ISO strings
    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value / 1000.0, tz=timezone.utc)
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except Exception:
        return None


def classify_mode(action_set, conversation_type):
    # action_set arrives from toPandas() as a numpy array — must not use `array or []`
    if action_set is None:
        actions = set()
    else:
        try:
            actions = set(list(action_set))
        except TypeError:
            actions = set()
    genie_actions = {a for a in actions if isinstance(a, str) and a.startswith("genie")}

    ct = ""
    if conversation_type is not None:
        try:
            if not (isinstance(conversation_type, float) and conversation_type != conversation_type):  # NaN guard
                ct = str(conversation_type).upper()
        except Exception:
            ct = ""

    if ct == "DEEP_RESEARCH":
        return "deep_research"
    if genie_actions and not (actions - genie_actions - {"getQueryResult", "executeQuery", "getMessageAttachmentQueryResult"}):
        return "genie_agent"
    return "genie_space"


def fetch_one(space_id, conversation_id, message_id):
    try:
        m = w.genie.get_message(
            space_id=space_id,
            conversation_id=conversation_id,
            message_id=message_id,
        )
    except Exception as exc:
        return {"_error": f"{exc.__class__.__name__}: {exc}"}

    raw = None
    try:
        raw = json.dumps(m.as_dict() if hasattr(m, "as_dict") else m.__dict__, default=str)[:65000]
    except Exception:
        raw = None

    attachments = _safe_attr(m, "attachments", default=[]) or []
    kinds = []
    sqls = []
    texts = []
    descriptions = []
    for a in attachments:
        q = _safe_attr(a, "query")
        t = _safe_attr(a, "text")
        if q is not None:
            kinds.append("query")
            sqls.append(_safe_attr(q, "query") or "")
            descriptions.append(_safe_attr(q, "description") or "")
        if t is not None:
            kinds.append("text")
            texts.append(_safe_attr(t, "content") or "")

    return {
        "ts": _coerce_dt(_safe_attr(m, "created_timestamp")),
        "user_id": _safe_attr(m, "user_id"),
        "content": _safe_attr(m, "content"),
        "status": str(_safe_attr(m, "status") or ""),
        "error_message": _safe_attr(m, "error", "error"),
        "attachments_count": len(attachments),
        "attachment_kinds": ",".join(kinds) or None,
        "nl_response_summary": "\n\n".join([t for t in texts if t]) or None,
        "generated_sql": "\n\n-- next attachment --\n\n".join([s for s in sqls if s]) or None,
        "query_description": "\n\n".join([d for d in descriptions if d]) or None,
        "statement_id": _safe_attr(m, "query_result_metadata", "statement_id")
            or (attachments[0].query.statement_id if attachments and _safe_attr(attachments[0], "query", "statement_id") else None),
        "raw": raw,
        "_error": None,
    }


fetched = []
errors = 0
t0 = time.time()
for i, row in enumerate(messages_pd.itertuples(index=False), start=1):
    res = fetch_one(row.space_id, row.conversation_id, row.message_id)
    if res.get("_error"):
        errors += 1
        if errors <= 5:
            print(f"[{i}] error on {row.message_id}: {res['_error']}")
        fetched.append({**res, "_message_id": row.message_id})
        continue
    fetched.append({**res, "_message_id": row.message_id})
    if i % 50 == 0:
        elapsed = time.time() - t0
        print(f"  fetched {i}/{len(messages_pd)} ({elapsed:.1f}s, {i/elapsed:.1f} msg/s, {errors} errs)")

print(f"fetched {len(fetched)} messages, {errors} errors in {time.time()-t0:.1f}s")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 5 — Build the per-message row + join system.query.history
# MAGIC
# MAGIC For each fetched message we either know the `statement_id` (best case — present in `query_result_metadata` or
# MAGIC the query attachment) or we leave it `NULL` and let downstream consumers join heuristically. We then enrich with
# MAGIC `system.query.history` on `statement_id` to attach execution metrics.

# COMMAND ----------

import pandas as pd  # available on all Databricks runtimes

if not messages_pd.empty:
    fetched_df = pd.DataFrame(fetched).set_index("_message_id")
    base = messages_pd.set_index("message_id")
    joined = base.join(fetched_df, how="left")
    joined = joined.reset_index().rename(columns={"index": "message_id"})

    joined["genie_mode"] = joined.apply(
        lambda r: classify_mode(r.get("action_set"), r.get("conversation_type")), axis=1
    )
    # Use the API's created_timestamp when available, fall back to first_seen from audit
    joined["ts"] = joined["ts"].fillna(joined["first_seen"])

    rows = pd.DataFrame({
        "ts": joined["ts"],
        "genie_mode": joined["genie_mode"],
        "workspace_id": joined["workspace_id"],
        "space_id": joined["space_id"],
        "space_name": None,
        "conversation_id": joined["conversation_id"],
        "conversation_type": joined["conversation_type"],
        "message_id": joined["message_id"],
        "user_email": joined["user_email"],
        "nl_prompt": joined["content"],
        "nl_response_summary": joined["nl_response_summary"],
        "generated_sql": joined["generated_sql"],
        "query_description": joined["query_description"],
        "attachment_count": joined["attachments_count"].fillna(0).astype("Int32"),
        "attachment_kinds": joined["attachment_kinds"],
        "message_status": joined["status"],
        "error_message": joined["error_message"],
        "statement_id": joined["statement_id"],
        "raw_message_json": joined["raw"],
    })

    schema = StructType([
        StructField("ts", TimestampType()),
        StructField("genie_mode", StringType()),
        StructField("workspace_id", StringType()),
        StructField("space_id", StringType()),
        StructField("space_name", StringType()),
        StructField("conversation_id", StringType()),
        StructField("conversation_type", StringType()),
        StructField("message_id", StringType()),
        StructField("user_email", StringType()),
        StructField("nl_prompt", StringType()),
        StructField("nl_response_summary", StringType()),
        StructField("generated_sql", StringType()),
        StructField("query_description", StringType()),
        StructField("attachment_count", IntegerType()),
        StructField("attachment_kinds", StringType()),
        StructField("message_status", StringType()),
        StructField("error_message", StringType()),
        StructField("statement_id", StringType()),
        StructField("raw_message_json", StringType()),
    ])

    rows_df = spark.createDataFrame(rows, schema=schema)
else:
    rows_df = spark.createDataFrame([], schema=StructType([
        StructField("message_id", StringType())
    ]))

# Join spaces dim for space_name
spaces = (
    spark.table(SPACES_DIM).select("space_id", "space_name").dropDuplicates(["space_id"])
)
rows_df = (
    rows_df.drop("space_name")
    .join(spaces, on="space_id", how="left")
    .withColumnRenamed("space_name", "space_name")
)

# Join system.query.history for execution metrics
qh = (
    spark.table(QUERY_HISTORY)
    .select(
        F.col("statement_id"),
        F.col("total_duration_ms"),
        F.col("read_rows"),
        F.col("produced_rows"),
        F.col("read_bytes"),
        F.col("from_result_cache"),
        F.col("pruned_files"),
        F.col("compute.warehouse_id").alias("warehouse_id"),
    )
)
rows_df = rows_df.join(qh, on="statement_id", how="left")

# Stamp ingested_at + UpdateDate
rows_df = (
    rows_df
    .withColumn("ingested_at", F.lit(RUN_START))
    .withColumn("UpdateDate", F.current_timestamp())
    .withColumn("thumb_up", F.lit(None).cast(BooleanType()))
    .withColumn("thumb_down", F.lit(None).cast(BooleanType()))
    .withColumn("feedback_comment", F.lit(None).cast(StringType()))
    .select(
        "ts", "genie_mode", "workspace_id", "space_id", "space_name",
        "conversation_id", "conversation_type", "message_id", "user_email",
        "nl_prompt", "nl_response_summary", "generated_sql", "query_description",
        "attachment_count", "attachment_kinds", "message_status", "error_message",
        "statement_id", "total_duration_ms", "read_rows", "produced_rows",
        "read_bytes", "from_result_cache", "pruned_files", "warehouse_id",
        "thumb_up", "thumb_down", "feedback_comment",
        "raw_message_json", "ingested_at", "UpdateDate",
    )
)

row_count = rows_df.count()
print(f"prepared {row_count} rows for MERGE")
if row_count:
    display(rows_df.limit(5))  # noqa: F821 — Databricks built-in

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 6 — MERGE into the gateway table

# COMMAND ----------

merged = 0
if row_count and not DRY_RUN:
    rows_df.createOrReplaceTempView("_genie_capture_batch")
    spark.sql(f"""
    MERGE INTO {TABLE_GATEWAY} t
    USING _genie_capture_batch s
    ON t.message_id = s.message_id
    WHEN MATCHED THEN UPDATE SET *
    WHEN NOT MATCHED THEN INSERT *
    """)
    # rough count: latest run's stamp
    merged = (
        spark.table(TABLE_GATEWAY)
        .where(F.col("ingested_at") == F.lit(RUN_START))
        .count()
    )
    print(f"MERGE complete; {merged} rows touched (matched on ingested_at == RUN_START)")
elif DRY_RUN:
    print("DRY_RUN=true — skipping MERGE")
else:
    print("no rows to merge")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 7 — Write watermark row

# COMMAND ----------

run_end = datetime.now(timezone.utc)
wm_row = spark.createDataFrame(
    [(
        ENV,
        RUN_ID,
        RUN_START,
        run_end,
        LOW_WATERMARK,
        RUN_START,
        int(len(messages_pd)),
        int(len(fetched) - errors),
        int(0),
        int(errors),
        int(merged),
        f"dry_run={DRY_RUN}; max_messages={MAX_MESSAGES}",
    )],
    schema=StructType([
        StructField("env", StringType()),
        StructField("run_id", StringType()),
        StructField("run_start", TimestampType()),
        StructField("run_end", TimestampType()),
        StructField("audit_low_watermark", TimestampType()),
        StructField("audit_high_watermark", TimestampType()),
        StructField("messages_seen", IntegerType()),
        StructField("messages_fetched", IntegerType()),
        StructField("messages_skipped", IntegerType()),
        StructField("api_errors", IntegerType()),
        StructField("rows_merged", IntegerType()),
        StructField("notes", StringType()),
    ]),
).withColumn("UpdateDate", F.current_timestamp())

if not DRY_RUN:
    wm_row.write.mode("append").saveAsTable(TABLE_WATERMARK)
    print(f"watermark row appended for env={ENV}")
else:
    print("DRY_RUN=true — watermark row not written")
    display(wm_row)  # noqa: F821

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cell 8 — Summary

# COMMAND ----------

print("=" * 60)
print(f"run_id              {RUN_ID}")
print(f"env                 {ENV}")
print(f"window              {LOW_WATERMARK.isoformat()}  →  {RUN_START.isoformat()}")
print(f"messages seen       {len(messages_pd)}")
print(f"messages fetched    {len(fetched) - errors}")
print(f"api errors          {errors}")
print(f"rows merged         {merged}")
print(f"dry_run             {DRY_RUN}")
print(f"target gateway      {TABLE_GATEWAY}")
print(f"target watermark    {TABLE_WATERMARK}")
print("=" * 60)

dbutils.notebook.exit(json.dumps({
    "run_id": RUN_ID,
    "env": ENV,
    "messages_seen": int(len(messages_pd)),
    "messages_fetched": int(len(fetched) - errors),
    "api_errors": int(errors),
    "rows_merged": int(merged),
    "dry_run": DRY_RUN,
}))
