---
object_fqn: main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 29
row_count: null
generated_at: '2026-05-19T12:13:00Z'
upstreams:
- RecurringInvestment.History.RecurringInvestmentPlans
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md
  source_database: RecurringInvestment
  source_schema: History
  source_table: RecurringInvestmentPlans
  source_repo: ExperianceDBs
  datalake_path: Bronze/RecurringInvestment/History/RecurringInvestmentPlans
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 26
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_recurringinvestment_history_recurringinvestmentplans

> Bronze ingest in `main.bi_db` (1:1 passthrough of `RecurringInvestment.History.RecurringInvestmentPlans`). 26 of 29 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 29 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Nov 18 17:16:08 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `RecurringInvestment.History.RecurringInvestmentPlans` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md`.

- Lake path: `Bronze/RecurringInvestment/History/RecurringInvestmentPlans`
- Copy strategy: `Append`
- Source database: `RecurringInvestment` (`ExperianceDBs`)
- Source schema/table: `History.RecurringInvestmentPlans`
- 26 of 29 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Same as parent table RecurringInvestment.Plans.ID. Unique identifier for the recurring investment plan. Not an identity column in the history table (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 1 | GCID | LONG | YES | Same as parent table RecurringInvestment.Plans.GCID. Global Customer ID of the user who owns this plan (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 2 | CID | LONG | YES | Same as parent table RecurringInvestment.Plans.CID. Customer ID - alternate user identifier (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 3 | InstrumentID | INT | YES | Same as parent table RecurringInvestment.Plans.InstrumentID. ID of the instrument for Instrument-type plans (PlanType=1). NULL for Copy-type plans (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 4 | RecurringDepositID | INT | YES | Same as parent table RecurringInvestment.Plans.RecurringDepositID. ID of the linked Recurring Deposit Plan from MIMO/Money Group (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 5 | Amount | DECIMAL | YES | Same as parent table RecurringInvestment.Plans.Amount. Investment amount per cycle in the plan's CurrencyID at the time this row version was current (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 6 | CurrencyID | INT | YES | Same as parent table RecurringInvestment.Plans.CurrencyID. Currency of the plan's Amount (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 7 | PlanStatusID | INT | YES | Same as parent table RecurringInvestment.Plans.PlanStatusID. Lifecycle state: 0=Initializing, 1=Active, 2=Cancelled (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 8 | DepositPlanStatusID | INT | YES | Same as parent table RecurringInvestment.Plans.DepositPlanStatusID. DEPRECATED. Status of the linked recurring deposit plan (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 9 | StatusReasonID | INT | YES | Same as parent table RecurringInvestment.Plans.StatusReasonID. Reason for the plan status at this point in time. Maps to Dictionary.PlanEventCode (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 10 | CreationDate | TIMESTAMP | YES | Same as parent table RecurringInvestment.Plans.CreationDate. When the plan was originally created (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 11 | EndDate | TIMESTAMP | YES | Same as parent table RecurringInvestment.Plans.EndDate. When the plan was cancelled. NULL while active (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 12 | DepositStartDate | TIMESTAMP | YES | Same as parent table RecurringInvestment.Plans.DepositStartDate. When the plan's first deposit occurred or was scheduled (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 13 | FrequencyID | INT | YES | Same as parent table RecurringInvestment.Plans.FrequencyID. Execution cadence: 3=Monthly (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 14 | RepeatsOn | INT | YES | Same as parent table RecurringInvestment.Plans.RepeatsOn. Day of the month when the plan executes (1-28) (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 15 | FundingID | INT | YES | Same as parent table RecurringInvestment.Plans.FundingID. ID of the plan's payment method (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 16 | Trace | STRING | YES | Same as parent table RecurringInvestment.Plans.Trace, but stored as nvarchar(733) NOT computed (unlike the parent's computed column). Contains JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName captured at the time the row was current (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 17 | ValidFrom | TIMESTAMP | YES | Period start - the point in time when this row version became the "current" version in the parent table (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 18 | ValidTo | TIMESTAMP | YES | Period end - the point in time when this row version was superseded by an update or deleted from the parent table (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 19 | etr_y | STRING | YES | Source: RecurringInvestment.History.RecurringInvestmentPlans.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 20 | etr_ym | STRING | YES | Source: RecurringInvestment.History.RecurringInvestmentPlans.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 21 | etr_ymd | STRING | YES | Source: RecurringInvestment.History.RecurringInvestmentPlans.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 22 | PlanType | INT | YES | Same as parent table RecurringInvestment.Plans.PlanType. Plan classification: 1=Instrument, 2=Copy (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 23 | CopyParentCID | LONG | YES | Same as parent table RecurringInvestment.Plans.CopyParentCID. CID of the trader being copied. NULL for Instrument-type plans (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 24 | CopyParentGCID | LONG | YES | Same as parent table RecurringInvestment.Plans.CopyParentGCID. GCID of the trader being copied. NULL for Instrument-type plans (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 25 | CopyType | INT | YES | Same as parent table RecurringInvestment.Plans.CopyType. Copy relationship type: 0=None, 1=PI, 4=SmartPortfolio (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 26 | HasBackupPayment | BOOLEAN | YES | Same as parent table RecurringInvestment.Plans.HasBackupPayment. Whether the plan has a fallback payment method (Tier 2 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 27 | MopType | INT | YES | Same as parent table RecurringInvestment.Plans.MopType. Method of Payment type for deposits (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |
| 28 | AmountUsd | DECIMAL | YES | Same as parent table RecurringInvestment.Plans.AmountUsd. Investment amount per cycle in USD (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RecurringInvestment.History.RecurringInvestmentPlans` | Primary | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` |

### 4.2 Pipeline ASCII Diagram

```
RecurringInvestment.History.RecurringInvestmentPlans
        │
        ▼
main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans   ←── this object
        │
        ▼
main.bi_output.bi_output_v_recurring_investment
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
| ID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| GCID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| CID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| RecurringDepositID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| Amount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| PlanStatusID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| DepositPlanStatusID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| StatusReasonID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| CreationDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| EndDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| DepositStartDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| FrequencyID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| RepeatsOn | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| FundingID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| Trace | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| ValidTo | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| etr_y | would inherit from `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| PlanType | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| CopyParentCID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| CopyParentGCID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| CopyType | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| HasBackupPayment | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| MopType | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |
| AmountUsd | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringInvestment.History.RecurringInvestmentPlans) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 26 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 29/29 | Source: bronze_tier1_inheritance*
