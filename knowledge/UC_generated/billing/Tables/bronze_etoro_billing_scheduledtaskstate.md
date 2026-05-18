---
object_fqn: main.billing.bronze_etoro_billing_scheduledtaskstate
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_scheduledtaskstate
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-18T10:58:38Z'
upstreams:
- etoro.Billing.ScheduledTaskState
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md
  source_database: etoro
  source_schema: Billing
  source_table: ScheduledTaskState
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/ScheduledTaskState
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_scheduledtaskstate

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.ScheduledTaskState`). 5 of 5 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_scheduledtaskstate` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Apr 20 17:18:39 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.ScheduledTaskState` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md`.

- Lake path: `Bronze/etoro/Billing/ScheduledTaskState`
- Copy strategy: `Append`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.ScheduledTaskState`
- 5 of 5 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | INT | YES | The deposit being processed. Part of the composite PK. Implicit FK to Billing.Deposit(DepositID). `GetScheduledTask*` procedures JOIN `Billing.Deposit D ON STS.DepositID = D.DepositID` to get deposit data for processing (Tier 1 — inherited from etoro.Billing.ScheduledTaskState). |
| 1 | TaskID | INT | YES | The task type. Part of the composite PK. References Billing.ScheduledTaskConfig(TaskID). Values 1-8. Each TaskID represents a different downstream system: 1=AppsFlyer, 2=RabbitMQ FTD, 3=RabbitMQ FTD remote, 5=Monitor, 7=Deposit processing, 8=Mixpanel (inferred from procedure names) (Tier 1 — inherited from etoro.Billing.ScheduledTaskState). |
| 2 | TaskState | INT | YES | Execution state. Default=0. 0=Pending (waiting to be fetched), 1=Done/Processed (primary completion), 2=Second-phase done (TaskID=3 only), 3=In-Progress (transient, set during batch fetch), 4=Final done (TaskID=1/AppsFlyer only) (Tier 1 — inherited from etoro.Billing.ScheduledTaskState). |
| 3 | ReasonID | INT | YES | Outcome reason code. Set by `UpdateScheduledTaskState`. NULL for pending and in-progress rows. Non-null values indicate specific processing outcomes (success codes, failure reasons). Exact values require application code review (Tier 1 — inherited from etoro.Billing.ScheduledTaskState). |
| 4 | Created | TIMESTAMP | YES | UTC timestamp of the last state change. Defaults to getutcdate() on INSERT. Updated by scheduler procedures (using GetDate() - local time inconsistency). For pending rows reflects deposit creation time. For in-progress/done reflects when the state was last changed (Tier 1 — inherited from etoro.Billing.ScheduledTaskState). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.ScheduledTaskState` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.ScheduledTaskState
        │
        ▼
main.billing.bronze_etoro_billing_scheduledtaskstate   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| DepositID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ScheduledTaskState) |
| TaskID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ScheduledTaskState) |
| TaskState | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ScheduledTaskState) |
| ReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ScheduledTaskState) |
| Created | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.ScheduledTaskState) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
