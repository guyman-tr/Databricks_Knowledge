# eMoney_dbo.eMoney_Daily_Shortfall_CID_Level

**Schema**: eMoney_dbo  
**Type**: Table  
**Generated**: 2026-04-21  
**Batch**: 15  
**Wiki Quality**: 8.8/10  

---

## 1. Overview

Daily snapshot of eToro Money account-level **overdraft positions** (shortfalls). Each row represents one CID/AccountId combination where the computed balance was negative on a given date. Only accounts with at least one eToro deposit (`EtoroDeposits > 0`) are included — pure provisioned or unactivated accounts are excluded.

The table is populated by `SP_eMoney_Daily_Shortfall_CID_Level` via a DELETE+INSERT pattern: all rows for the target date are deleted, then all qualifying accounts for that date are re-inserted. The `Shortfall` column is a computed sum of all balance components; the SP's outer filter retains only rows where that sum is negative.

**Primary use case**: Regulatory monitoring and operational oversight of overdrawn eToro Money accounts — identifying clients who are in a negative balance position on any given day.

---

## 2. Table Metadata

| Property | Value |
|----------|-------|
| Full name | `eMoney_dbo.eMoney_Daily_Shortfall_CID_Level` |
| Distribution | HASH(CID) |
| Index | HEAP |
| Row count (approx.) | 1,359,644 (2024-01-01 to 2026-04-12) |
| Date range | 2024-01-01 → 2026-04-12 (latest observed) |
| Load pattern | Daily DELETE+INSERT by DateID |
| Writer SP | `eMoney_dbo.SP_eMoney_Daily_Shortfall_CID_Level` |
| SP parameter | `@date DATE` |
| Grain | One row per CID + AccountId + DateID |
| UC target | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_shortfall_cid_level` |

---

## 3. Column Dictionary

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | CID | INT | NOT NULL | T2 | Customer ID — eToro platform customer identifier. HASH distribution key. |
| 2 | AccountId | INT | NOT NULL | T2 | Tribe (eToro Money) account identifier. |
| 3 | DateID | INT | NOT NULL | T2 | Date dimension surrogate key. Renamed from `eMoneyClientBalance.BalanceDateID`. |
| 4 | Date | DATE | NOT NULL | T2 | Calendar date of the shortfall snapshot. Renamed from `eMoneyClientBalance.BalanceDate`. |
| 5 | Shortfall | DECIMAL | NOT NULL | T2 | Computed overdraft amount (always negative). Formula: `BankPayIns + BankPayOuts + Card_POS + Card_ATM + BalanceAdjustments + ChargeBackAdjustments + ATMFee + FxFee + OtherFee + OpeningBalance`. Only rows where this sum < 0 are inserted. |
| 6 | UpdateDate | DATETIME | NULL | T2 | Timestamp of the INSERT, populated via `GETDATE()`. |
| 7 | BankPayIns | DECIMAL | NULL | T2 | Bank payment inflows (positive values) for the account on this date. Direct from eMoneyClientBalance. |
| 8 | BankPayOuts | DECIMAL | NULL | T2 | Bank payment outflows (negative values) for the account on this date. Direct from eMoneyClientBalance. |
| 9 | Card_POS | DECIMAL | NULL | T2 | Point-of-sale card transactions for the account on this date. Direct from eMoneyClientBalance. |
| 10 | Card_ATM | DECIMAL | NULL | T2 | ATM card cash withdrawals for the account on this date. Direct from eMoneyClientBalance. |
| 11 | BalanceAdjustments | DECIMAL | NULL | T2 | Manual or system balance adjustments on this date. Direct from eMoneyClientBalance. |
| 12 | ChargeBackAdjustments | DECIMAL | NULL | T2 | Chargeback adjustments applied to the account on this date. Direct from eMoneyClientBalance. |
| 13 | ATMFee | DECIMAL | NULL | T2 | ATM fee charges for this account on this date. Direct from eMoneyClientBalance. |
| 14 | FxFee | DECIMAL | NULL | T2 | FX conversion fee charges for this account on this date. Direct from eMoneyClientBalance. |
| 15 | OtherFee | DECIMAL | NULL | T2 | Miscellaneous fee charges for this account on this date. Direct from eMoneyClientBalance. |
| 16 | OpeningBalance | DECIMAL | NULL | T2 | Balance carried forward from the prior day. Direct from eMoneyClientBalance. |
| 17 | Entity | VARCHAR | NULL | T2 | Regulatory entity code for the account (e.g., 826=eToro Money UK, 978=eToro Money Malta, 36=eToro Money AUS). Direct from eMoneyClientBalance. |
| 18 | CurrencyIson | INT | NULL | T2 | ISO 4217 numeric currency code for the account's operating currency. Direct from eMoneyClientBalance. |

**Tier summary**: 0 Tier 1 | 18 Tier 2 | 0 Tier 3 | 0 Tier 4

---

## 4. Business Logic

### Shortfall Computation

The SP computes `Shortfall` as an additive sum of all transaction categories in `eMoneyClientBalance`. The formula captures the net daily position:

```
Shortfall = BankPayIns
          + BankPayOuts          -- typically negative
          + Card_POS             -- typically negative (spending)
          + Card_ATM             -- typically negative
          + BalanceAdjustments
          + ChargeBackAdjustments
          + ATMFee               -- typically negative
          + FxFee                -- typically negative
          + OtherFee             -- typically negative
          + OpeningBalance
```

The outer query (`WHERE Shortfall < 0`) retains only rows where the net sum is negative. Accounts that end the day with a zero or positive balance are excluded.

### Two-Stage Filter

The SP applies filters in two stages:

**Stage 1 (inner query — on eMoneyClientBalance):**
- `BalanceDateID = @DateID` — single-date snapshot only
- `EtoroDeposits > 0` — excludes accounts that have never received an eToro deposit; pure provisioned accounts are not meaningful for shortfall monitoring

**Stage 2 (outer query):**
- `WHERE Shortfall < 0` — only overdrawn accounts are inserted into the shortfall table

### Load Pattern

DELETE+INSERT by DateID: the SP deletes all existing rows where `DateID = @DateID` before inserting the fresh snapshot. This ensures idempotent daily reruns without duplication.

### Distribution Key

HASH(CID) — queries joining to customer-level tables (e.g., Dim_Customer) will benefit from this distribution. Range scans by date require a broadcast join or full scan.

---

## 5. Data Quality Notes

| Observation | Detail |
|-------------|--------|
| Shortfall range | -1,032,951.14 to -0.01 (always negative by construction) |
| No duplicate guard beyond delete | The SP relies on DateID DELETE+INSERT; re-running for an already-loaded date is safe |
| EtoroDeposits filter | Accounts with zero lifetime eToro deposits are excluded; this is intentional to focus on active account holders |
| UpdateDate nullable | Unlike the successor MIMO tables, UpdateDate is NULL-able here — no constraint |
| No Tier 1 columns | eMoneyClientBalance is an internal DWH staging table with no DB_Schema upstream wiki; all columns are Tier 2 |
| Entity-level spread | Latest date (2026-04-12) shows 3 active entities: AUS (36/AUD, 39 accounts), Malta (978/EUR, 399 accounts), UK (826/GBP, 339 accounts) |

---

## 6. Sample Data

**Latest observed date: 2026-04-12 — by Entity**

| Entity (CurrencyIson) | Overdrawn Accounts | Total Shortfall |
|----------------------|-------------------|----------------|
| 36 (AUD — eToro Money AUS) | 39 | ~A$53K |
| 978 (EUR — eToro Money Malta) | 399 | ~€177K |
| 826 (GBP — eToro Money UK) | 339 | ~£230K |

**Shortfall distribution (all dates):**

| Metric | Value |
|--------|-------|
| Min Shortfall | -1,032,951.14 |
| Max Shortfall | -0.01 |
| Total rows | 1,359,644 |
| Date range | 2024-01-01 to 2026-04-12 |

---

## 7. Relationships

| Related Object | Type | Join Key | Notes |
|---------------|------|----------|-------|
| `eMoney_dbo.eMoneyClientBalance` | Source table | CID + BalanceDateID | Sole data source; not stored in this table |
| `eMoney_dbo.eMoney_Aggregated_Tribe_Balance` | Sibling table | Entity + DateID | Aggregated balance by entity/currency — counterpart for aggregate-level shortfall context |
| `DWH_dbo.Dim_Customer` | Lookup | CID | Not used in this SP but natural join key for customer enrichment |

---

## 8. SP and Change History

| Date | Change | Author |
|------|--------|--------|
| ~2024-01-01 (earliest data) | Table populated; SP_eMoney_Daily_Shortfall_CID_Level in production | Unknown |
| 2026-04-21 | First-time wiki documentation | Auto-generated (Batch 15) |

**SP execution model**: `SP_eMoney_Daily_Shortfall_CID_Level` accepts a single `@date DATE` parameter. It converts this to `@DateID` internally and runs the DELETE+INSERT for that date. The SP is not included in `SP_eMoney_Execute_Group_One` (all EXECs in that orchestrator are commented out post-Synapse migration); it is called standalone or via external orchestration.

---

*Source: DDL from DataPlatform repo + SP_eMoney_Daily_Shortfall_CID_Level.sql + live MCP query (2026-04-21)*
