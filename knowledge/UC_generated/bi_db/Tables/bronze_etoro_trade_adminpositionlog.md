---
object_fqn: main.bi_db.bronze_etoro_trade_adminpositionlog
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_trade_adminpositionlog
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 27
row_count: null
generated_at: '2026-05-19T12:12:49Z'
upstreams:
- etoro.Trade.AdminPositionLog
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md
  source_database: etoro
  source_schema: Trade
  source_table: AdminPositionLog
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Trade/AdminPositionLog
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 27
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_trade_adminpositionlog

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Trade.AdminPositionLog`). 27 of 27 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_trade_adminpositionlog` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 27 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Oct 10 11:13:57 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Trade.AdminPositionLog` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md`.

- Lake path: `Bronze/etoro/Trade/AdminPositionLog`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Trade.AdminPositionLog`
- 27 of 27 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AdminPositionID | LONG | YES | Auto-generated surrogate key. IDENTITY seed 3747184 indicates this table was re-seeded after data migration from AdminPositionLogOLD (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 1 | AdminPositionRequestID | STRING | YES | Correlation GUID grouping multiple admin position entries from the same batch request. Used for deduplication (CID + RequestID prevents duplicate execution) and for lookups via `GetAdminPositionLogByRequestID` (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 2 | CID | INT | YES | Customer identifier for the account receiving the admin position. Implicit FK to Customer.CustomerStatic. Indexed for lookup performance (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 3 | InstrumentID | INT | YES | Financial instrument for the position. Implicit FK to Trade.Instrument (Tier 2 — inherited from etoro.Trade.AdminPositionLog). |
| 4 | OpenActionType | INT | YES | Why this admin position was created. Maps to Dictionary.OpenPositionActionType: 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 4=Stock Dividend, 5=Corporate Action, 6=Technical Issue, 7=Operational position adjustment, 8=Add Funds, 9=Reinvestment, 10=Admin, 11=Stacking, 12=Promotion, 13=ACATS_IN, 14=ReedemForNFT, 15=Technical, 16=Alignment, 17=Recurring Investment. Most common: 11 (Stacking) (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 5 | AdminPositionEventID | STRING | YES | Event correlation ID for the position creation event in the distributed system. Indexed for event-based lookups (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 6 | AmountInUnits | DECIMAL | YES | Number of units/shares for the position. NULL when amount is specified in monetary terms instead (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 7 | Amount | DECIMAL | YES | Monetary amount for the position. NULL when amount is specified in units instead. Mutually exclusive with AmountInUnits for most action types (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 8 | HedgeServerID | INT | YES | Hedge server assigned to execute this position. Implicit FK to Trade.HedgeServer. NULL for positions that don't require hedging (Tier 2 — inherited from etoro.Trade.AdminPositionLog). |
| 9 | RequestOccurred | TIMESTAMP | YES | UTC timestamp when the admin position request was created. Indexed for time-range queries and monitoring (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 10 | UserName | STRING | YES | Username of the operator who initiated the request. For automated processes, often contains the CID as a string (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 11 | ExecutionOccurred | TIMESTAMP | YES | UTC timestamp when the position was actually executed (filled). NULL for pending or rejected requests. Indexed for execution monitoring (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 12 | PositionID | LONG | YES | The resulting position ID in Trade.PositionTbl after successful execution. NULL until State=3 (Filled). Indexed for reverse lookups from position to admin request (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 13 | State | INT | YES | Current lifecycle state: 1=Pending (created), 2=Placed (sent to execution), 3=Filled (succeeded), 4=Rejected (failed). Source: Dictionary.AdminPositionState. Most rows are State 4 (Rejected, 63%) or State 3 (Filled, 35%) (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 14 | FailReason | STRING | YES | Human-readable error description when State=4 (Rejected). Set by `SetAdminPositionFailInfo`. NULL for non-failed requests (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 15 | ErrorCode | INT | YES | Numeric error code when State=4 (Rejected). Set by `SetAdminPositionState` or `SetAdminPositionFailInfo`. NULL for non-failed requests (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 16 | Cusip | STRING | YES | CUSIP identifier for US securities. Used for ACATS transfers and US regulatory reporting (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 17 | ApexID | STRING | YES | Apex Clearing account/transaction identifier for US brokerage integration (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 18 | Rate | DECIMAL | YES | Execution rate/price for the position. NULL until execution occurs (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 19 | RateTime | TIMESTAMP | YES | Timestamp of the rate used for execution. May differ from ExecutionOccurred if rate was captured earlier (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 20 | CheckBalance | BOOLEAN | YES | Whether to validate the customer has sufficient balance before opening the position. 0=Skip balance check (common for compensations), 1=Enforce balance check (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 21 | IsComputeForHedge | BOOLEAN | YES | Whether this position should be included in hedge exposure calculations. 0=Exclude from hedging, 1=Include in hedging (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 22 | IsFunded | BOOLEAN | YES | Whether this is a funded (real asset) position vs a CFD. 1=Funded/real, 0=CFD (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 23 | CompensationReasonID | INT | YES | Reason code for the compensation or admin action. Sourced from Dictionary.CorporateAction.CompensationReasonID in airdrop flows. Most common: 91 (91% of rows) (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 24 | ValidatePositionWorth | BOOLEAN | YES | Whether to validate minimum position value before opening. 0=Skip validation, 1=Enforce minimum worth check (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 25 | CompensationCreditID | LONG | YES | Credit entry ID linking this admin position to a compensation credit record. Added after AdminPositionLogOLD was archived (not present in OLD table) (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |
| 26 | OrderID | LONG | YES | Associated order ID in Trade.Orders for this admin position. Added after AdminPositionLogOLD was archived. Indexed for order-based lookups (Tier 1 — inherited from etoro.Trade.AdminPositionLog). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Trade.AdminPositionLog` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Trade.AdminPositionLog
        │
        ▼
main.bi_db.bronze_etoro_trade_adminpositionlog   ←── this object
        │
        ▼
main.etoro_kpi_prep.v_fact_customeraction_w_metrics
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
| AdminPositionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| AdminPositionRequestID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| OpenActionType | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| AdminPositionEventID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| AmountInUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| Amount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| HedgeServerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| RequestOccurred | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| UserName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| ExecutionOccurred | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| PositionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| State | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| FailReason | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| ErrorCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| Cusip | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| ApexID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| Rate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| RateTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| CheckBalance | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| IsComputeForHedge | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| IsFunded | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| CompensationReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| ValidatePositionWorth | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| CompensationCreditID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |
| OrderID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.AdminPositionLog) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 27 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 27/27 | Source: bronze_tier1_inheritance*
