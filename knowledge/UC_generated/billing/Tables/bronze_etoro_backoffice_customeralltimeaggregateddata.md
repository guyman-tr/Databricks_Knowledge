---
object_fqn: main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 27
row_count: null
generated_at: '2026-05-18T10:58:22Z'
upstreams:
- etoro.BackOffice.CustomerAllTimeAggregatedData
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md
  source_database: etoro
  source_schema: BackOffice
  source_table: CustomerAllTimeAggregatedData
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/CustomerAllTimeAggregatedData
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 27
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_customeralltimeaggregateddata

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.BackOffice.CustomerAllTimeAggregatedData`). 27 of 27 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 27 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Dec 05 13:45:10 UTC 2022 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.CustomerAllTimeAggregatedData` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md`.

- Lake path: `Bronze/etoro/BackOffice/CustomerAllTimeAggregatedData`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.CustomerAllTimeAggregatedData`
- 27 of 27 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Customer ID - the row key. From _1 table in Branch 1, from MIMO table in Branch 2 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 1 | TotalProfit | DECIMAL | YES | Lifetime realized profit from all closed trading positions. Zero for MIMO-only customers. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 2 | TotalDeposit | DECIMAL | YES | Lifetime total deposits from the MIMO pipeline. For standard-only customers (no MIMO record) this is 0. Sourced from CustomerMIMOAllTimeAggregatedData (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 3 | TotalBonus | DECIMAL | YES | Lifetime total bonus credits from MIMO pipeline. Sourced from CustomerMIMOAllTimeAggregatedData (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 4 | TotalInvestment | DECIMAL | YES | Total funds locked into open trading positions. Zero for MIMO-only customers. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 5 | TotalCommission | DECIMAL | YES | Total commission charges paid. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 6 | TotalVolume | DECIMAL | YES | Total trading volume (sum of position sizes) in USD. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 7 | TotalLot | DECIMAL | YES | Total lot volume traded. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 8 | TotalChampWin | DECIMAL | YES | Total championship winnings. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 9 | TotalCashout | DECIMAL | YES | Lifetime approved cashouts (withdrawals) from MIMO pipeline. Sourced from CustomerMIMOAllTimeAggregatedData (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 10 | TotalCashoutRequest | DECIMAL | YES | Total value of cashout requests (including pending). From CustomerMIMOAllTimeAggregatedData (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 11 | TotalReverseCashout | DECIMAL | YES | Total reversed cashout amounts. From CustomerMIMOAllTimeAggregatedData (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 12 | TotalCompensation | DECIMAL | YES | Total compensation credits from MIMO pipeline. From CustomerMIMOAllTimeAggregatedData (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 13 | TotalGameCount | LONG | YES | Total number of games/contests participated in. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 14 | TotalPositionCount | LONG | YES | Total number of trading positions opened lifetime. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 15 | TotalLoginCount | LONG | YES | Total number of platform logins. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 16 | TotalLoggedTime | LONG | YES | Total time spent logged in (seconds or minutes). From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 17 | TotalEndOfWeekFee | DECIMAL | YES | Total end-of-week inactivity fees charged. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 18 | LastUpdate | TIMESTAMP | YES | Most recent update timestamp from either pipeline. `CASE WHEN A.LastUpdate > ISNULL(M.LastUpdate,'01-01-2000') THEN A.LastUpdate ELSE M.LastUpdate END` (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 19 | FirstTimeCashierLoginDate | TIMESTAMP | YES | Date customer first accessed the cashier/deposit flow. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 20 | FirstTimeDepositAttemptDate | TIMESTAMP | YES | Date of customer's first deposit attempt via MIMO pipeline. From CustomerMIMOAllTimeAggregatedData (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 21 | FirstTimeDepositSuccessDate | TIMESTAMP | YES | Date of customer's first successful deposit via MIMO pipeline. From CustomerMIMOAllTimeAggregatedData (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 22 | LastOccurredTriggerToSF | TIMESTAMP | YES | Most recent SalesForce sync trigger timestamp. Takes the later of A and M values (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 23 | LastLoggedInOn | TIMESTAMP | YES | Most recent login timestamp. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 24 | LastClientIp | STRING | YES | IP address from most recent login. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 25 | RealizedEquityLastChange | TIMESTAMP | YES | Timestamp of last change to LastRealizedEquity. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |
| 26 | LastRealizedEquity | DECIMAL | YES | Most recent snapshot of customer's realized equity balance. 0 for MIMO-only customers. From CustomerAllTimeAggregatedData_1 (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.CustomerAllTimeAggregatedData` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.CustomerAllTimeAggregatedData
        │
        ▼
main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata   ←── this object
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
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalProfit | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalDeposit | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalBonus | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalInvestment | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalCommission | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalVolume | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalLot | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalChampWin | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalCashout | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalCashoutRequest | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalReverseCashout | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalCompensation | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalGameCount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalPositionCount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalLoginCount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalLoggedTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| TotalEndOfWeekFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| LastUpdate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| FirstTimeCashierLoginDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| FirstTimeDepositAttemptDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| FirstTimeDepositSuccessDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| LastOccurredTriggerToSF | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| LastLoggedInOn | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| LastClientIp | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| RealizedEquityLastChange | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |
| LastRealizedEquity | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerAllTimeAggregatedData) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 27 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 27/27 | Source: bronze_tier1_inheritance*
