# eMoney_dbo.FiatAccount

> ~2.06M-row eMoney fiat-account dimension. One row per fiat account opened on the eToro Money (eMoney) platform — keyed by an internal numeric `Id`, joined to customers via `Gcid`, and tagged with the program/sub-program enrolment and the account creation timestamp. Effectively the customer↔eMoney-program link that Payments and MIMO joins use to identify which eMoney program (Money, Money Crypto, etc.) a customer is enrolled in.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | eMoney platform — fiat account creation events |
| **Refresh** | Continuous (event-driven) — `SynapseUpdateDate` indicates the most recent ETL touch (4 AM cycle observed) |
| **Row Count** | ~2,060,000 |
| **Grain** | One row per eMoney fiat account |
| | |
| **Synapse Distribution** | (typically HASH on Gcid for customer-side joins) |
| **Synapse Index** | CLUSTERED on Id |
| | |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount` |
| **UC Format** | delta |
| **UC Partitioned By** | partition_date |
| **UC Table Type** | Gold export (generic pipeline) |

---

## 1. Business Meaning

`eMoney_dbo.FiatAccount` is the canonical link between an eToro customer (`Gcid`) and the eMoney fiat-account program they're enrolled in. eMoney is eToro's licensed e-money business (e.g. eToro Money in the UK), separate from the trading platform. When a customer opens an eMoney account, a row is written here with:

- a numeric `Id` — local to the eMoney system
- the customer's `Gcid` — joins to `Dim_Customer`
- an `AccountGuid` — the Guid identifier exposed to client systems and the eMoney APIs
- `AccountProgramId` and `SubProgramId` — the enrollment program (e.g. "eToro Money", "eToro Money Crypto", staking variants, etc.)
- `Created` — the timestamp the account was opened on the eMoney side

The `etr_y` / `etr_ym` / `etr_ymd` columns are partition-friendly date strings populated downstream of the eMoney ingestion. `partition_date` is the UC-side partition key (one folder per day).

Use this table to:
- Tell whether a `Gcid` has any eMoney account (existence join)
- Slice users by `(AccountProgramId, SubProgramId)` enrollment
- Date-bound user growth in eMoney programs (count of `Created` per day)

Bridges to broader Payments work-flows are documented in the `payments/emoney-accounts-and-cards` and `bridges/tribe-emoney-audit` skills.

---

## 2. Query Advisory

### 2.1 Common Patterns

| Question | Approach |
|----------|----------|
| Does CID X have an eMoney account? | `EXISTS (SELECT 1 FROM FiatAccount WHERE Gcid = ...)` |
| Top program enrollments | `GROUP BY AccountProgramId, SubProgramId ORDER BY COUNT(*) DESC` |
| Daily new account opens | `GROUP BY CAST(Created AS DATE)` |
| Latest snapshot per Gcid | `ROW_NUMBER() OVER (PARTITION BY Gcid ORDER BY Created DESC)` |

### 2.2 Distribution (UC sample 2026-05-07)

| AccountProgramId | SubProgramId | Rows | Notes |
|------------------|--------------|------|-------|
| 2 | 6 | 1,163,060 | Largest cohort |
| 2 | 4 | 455,835 | |
| 2 | 9 | 191,874 | |
| 2 | 8 | 130,998 | |
| 1 | 2 | 52,368 | Different program family |
| 2 | 13 | 41,169 | |
| 2 | 7 | 14,131 | |
| 1 | 1 | 7,856 | |
| ... | ... | <2k | Long tail of niche programs |

### 2.3 Gotchas

- **Multiple accounts per customer**: a single `Gcid` can have multiple `Id` rows (different programs / re-opens). Use `MAX(Created)` or `ROW_NUMBER()` if you need a single "latest" account per customer.
- **`Created` is the eMoney-side timestamp**, not the eToro-side registration. For platform registration date, join to `DWH_dbo.Dim_Customer.Reg_Date`.
- **`etr_y/_ym/_ymd` may be empty strings** in some rows (observed in 2026-05-06 sample) — derive from `Created` instead when blank.
- **`partition_date`** is the UC partition column — push predicates here for fast scans.
- **Program/SubProgram catalog**: the (program, sub-program) integer pairs are not currently enriched with a separate dim — refer to eMoney engineering for the mapping or join via `eMoney_dbo.AccountProgram` / similar dim if available.

---

## 3. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 1 | DDL + UC sample |
| ** | Tier 2 | UC distribution audit (2026-05-07) |
| * | Tier 3 | Inferred from name/eMoney conventions [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | eMoney-internal numeric primary key. One row per fiat account. Append-only on creation. (Tier 1 — DDL) |
| 2 | Gcid | bigint | YES | Global Customer ID — eToro-platform-side. Joins to `DWH_dbo.Dim_Customer.GCID` and `BI_DB_dbo.BI_DB_DDR_CID_Level.CID`. The single most common join key out of this table. (Tier 1 — DDL + sample) |
| 3 | AccountGuid | varchar(max) | YES | UUID-style account identifier exposed to eMoney APIs and client systems. Primary handle for cross-reference into eMoney transaction streams (Tribe audit, eMoney IBAN tables). (Tier 1 — UC sample) |
| 4 | Created | datetime2(7) | YES | Timestamp when the eMoney fiat account was opened. Source-of-truth for "eMoney opened" events. (Tier 1 — UC sample, 2026-05-06 latest) |
| 5 | AccountProgramId | int | YES | Top-level enrollment program identifier. Two main families observed (1 and 2); 2 is dominant (>2M of ~2.06M rows). The (AccountProgramId, SubProgramId) pair encodes the specific eMoney offering. (Tier 2 — UC distribution audit) |
| 6 | SubProgramId | int | YES | Sub-program / variant identifier within the parent AccountProgram. Distinct values 1-16 observed. (Tier 2 — UC distribution audit) |
| 7 | etr_y | varchar(max) | YES | Year string derived from `Created` (e.g. `'2026'`). Often empty in some rows — when blank, derive from `YEAR(Created)`. (Tier 3 — inferred) |
| 8 | etr_ym | varchar(max) | YES | Year-month string `'YYYY-MM'`. Same caveat as etr_y. (Tier 3 — inferred) |
| 9 | etr_ymd | varchar(max) | YES | Year-month-day string `'YYYY-MM-DD'`. Same caveat. (Tier 3 — inferred) |
| 10 | SynapseUpdateDate | datetime | YES | Timestamp of the most recent Synapse-side ETL touch on this row. Useful for change-data capture (see `WHERE SynapseUpdateDate >= ...` for incremental). (Tier 1 — UC sample) |
| 11 | partition_date | date | YES | UC-side partition column — one partition per business day of ingestion. Push predicates on this for fast scans (e.g. `WHERE partition_date = CURRENT_DATE - 1`). (Tier 1 — DDL + UC partition spec) |

---

## 4. Lineage

```
eMoney platform → eMoney_dbo.FiatAccount (Synapse) → Generic Pipeline (gold export)
                                                   ↓
                  main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount
                  (partitioned by partition_date)
```

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Description |
|---------|----------------|-------------|
| Gcid | `DWH_dbo.Dim_Customer.GCID` | Customer identity bridge |

### 5.2 Referenced By

Joined into MIMO panels, eMoney IBAN/card tables, Tribe audit views, and Payments super-domain skills (see `payments/emoney-accounts-and-cards`, `bridges/tribe-emoney-audit`).

---

## 6. Sample Queries

### 6.1 Latest-account-per-customer

```sql
SELECT Gcid, AccountGuid, AccountProgramId, SubProgramId, Created
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY Gcid ORDER BY Created DESC) rn
  FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount
) WHERE rn = 1
```

### 6.2 Daily new-account opens

```sql
SELECT CAST(Created AS DATE) AS open_day, COUNT(*) AS new_accounts
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_fiataccount
WHERE Created >= CURRENT_DATE - INTERVAL 30 DAYS
GROUP BY CAST(Created AS DATE)
ORDER BY open_day DESC
```

---

*Generated: 2026-05-07 | Wave 2 systematic NO_WIKI fill-in*
*Source: DDL + UC sample 2026-05-06/07 + UC distribution audit + payments/emoney-accounts-and-cards skill*
*Object: eMoney_dbo.FiatAccount | Type: Table | Production: eMoney platform*
