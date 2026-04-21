# eMoney_dbo.eMoney_Snapshot_Settled_Balance

> Daily snapshot of cumulative settled balance and transaction type breakdown for all eTM accounts — one row per account per currency as of yesterday (GETDATE()-1). 1,287,999 rows across 4 currencies (EUR 64.7%, GBP 33.7%, AUD 1.6%, DKK <0.1%) for DateID=20260411. MI/MO amounts are partitioned by transaction type (IBAN In, IBAN Out, Card, Direct Debit, Other) with USD approximations. Refreshed daily via TRUNCATE + INSERT by SP_eMoney_Snapshot_Settled_Balance.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | eMoney_dbo.eMoney_Dim_Account (account grain) + eMoney_dbo.eMoney_Dim_Transaction (settled TXs, TxStatusID=2) + eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static (currency labels) + DWH_dbo.Fact_CurrencyPriceWithSplit (USD FX rates). Written by SP_eMoney_Snapshot_Settled_Balance. |
| **Refresh** | Daily TRUNCATE + INSERT (full rebuild for GETDATE()-1 only). |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |
| **PII** | None |

---

## 1. Business Meaning

`eMoney_Snapshot_Settled_Balance` is the daily account balance snapshot for all eToro Money accounts. **Grain**: one row per (DateID, AccountID, CurrencyBalanceISOCode) — one row per account per currency balance as of the most recent completed day (GETDATE()-1). As of 2026-04-11, the table holds 1,287,999 rows covering 1,287,453 distinct accounts across 4 currencies: EUR (832,610 rows), GBP (434,329), AUD (20,629), DKK (431).

**What the table captures**: the cumulative settled balance for each account as of yesterday, broken down by transaction type category. `HolderBalance` is the all-time net settled balance (TotalMI + TotalMO); the table retains only the current day's snapshot (TRUNCATE before INSERT), so no historical balance time series is maintained here. For historical balance history, refer to `eMoney_Calculated_Balance` (stale as of 2025-06-09) or `eMoneyClientBalance`.

**Balance structure**: TotalMI (gross money-in) and TotalMO (gross money-out) are the top-level flows. Each is further decomposed by payment channel: IBAN-In (bank→eTM), IBAN-Out (eTM→bank), Card transactions, Direct Debit, and Other. Most accounts (99.7%) have IBAN-type activity; only 0.19% have card transaction flows. 56.9% of accounts have zero HolderBalance, consistent with inactive or fully-withdrawn accounts.

**USD approximation**: USDApproxBalance, USDApproxTotalMI, and USDApproxTotalMO provide USD-equivalent values using the previous day's FX rate from `Fact_CurrencyPriceWithSplit` via `eMoney_Currency_Instrument_Mapping_Static`. These columns are NULL for DKK accounts (ISO 208) because no USD instrument mapping exists in the static table for DKK.

**Balance sign convention**: TotalMI is positive (money credited to account); TotalMO is negative (money debited from account). HolderBalance can be negative (overdraft-like states from reversals or timing differences) — minimum observed is -597,856.82.

---

## 2. Business Logic

### 2.1 Daily Single-Day Snapshot Pattern

**What**: The table holds exactly one snapshot date — GETDATE()-1 from the last SP run. No historical time series.

**Columns Involved**: `DateID`, `USDApproxDate`, `UpdateDate`

**Rules**:
- SP executes TRUNCATE before INSERT — no accumulation over time; every SP run replaces the entire table
- `DateID` is YYYYMMDD of the balance date (GETDATE()-1); equals USDApproxDate (both reference yesterday)
- If the SP does not run on a given day, the table retains the prior run's data (stale DateID)
- For cumulative historical balance, use `eMoneyClientBalance` (Tribe snapshot-based) or `eMoney_Calculated_Balance` (stale 2025-06-09)

### 2.2 Transaction Type Decomposition

**What**: TotalMI and TotalMO are each decomposed into five channel categories.

**Columns Involved**: `TotalMI`, `TotalMO`, `CardTxMI`, `CardTxMO`, `IBANInMI`, `IBANInMO`, `IBANOutMI`, `IBANOutMO`, `DirectDebitMI`, `DirectDebitMO`, `OtherMI`, `OtherMO`

**Rules**:
- **Additive relationship**: TotalMI = CardTxMI + IBANInMI + IBANOutMI + DirectDebitMI + OtherMI (summing non-NULL category values)
- **Additive relationship**: TotalMO = CardTxMO + IBANInMO + IBANOutMO + DirectDebitMO + OtherMO
- Category columns are NULL (not zero) when the account has no transactions in that category; do not use `IS NULL` as "no activity" interchangeably with `= 0`
- **IBANIn** = bank-to-eTM transfers (SEPA received); **IBANOut** = eTM-to-bank transfers (SEPA sent); reversal flows appear as positive values in the MO column's MI counterpart (e.g., an IBANOut reversal returned to the account appears as IBANOutMI)
- **Card** = debit card purchases (CardTxMO) and any card MI credits (rare); **DirectDebit** = automated debits (UK direct debit)
- **Other** = residual TxTypeIDs not covered by the above channels

### 2.3 USD Approximation Logic

**What**: Three USD-equivalent summary columns using the previous day's FX rate.

**Columns Involved**: `USDApproxDate`, `USDApproxBalance`, `USDApproxTotalMI`, `USDApproxTotalMO`

**Rules**:
- FX rate source: `DWH_dbo.Fact_CurrencyPriceWithSplit` joined via `eMoney_Currency_Instrument_Mapping_Static` (by instrument code for the currency)
- Only EUR, GBP, and AUD have USD instrument mappings — DKK (208) rows have NULL USD columns
- USD approximations are indicative only (spot rate for one day); for precise FX conversion, use dedicated FX fact tables
- USDApproxDate = USDApproxDate column = DateID in date form (GETDATE()-1)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distributes rows by customer — customer-level aggregations are efficient. HEAP is optimal for this fully-replaced daily table. Note: the table has a small duplicate-row issue (1,287,999 rows vs 1,287,455 distinct AccountIDs) — approximately 544 AccountIDs have 2+ rows. Always aggregate (SUM, not SELECT *) when computing totals at the account level.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Accounts with positive balance | `WHERE HolderBalance > 0` (554,733 rows as of 2026-04-11) |
| Currency breakdown of balances | `GROUP BY CurrencyBalanceISOCode, HolderBalanceCurrency` |
| Total eTM wallet balance in GBP | `WHERE CurrencyBalanceISOCode = 826 GROUP BY CurrencyBalanceISOCode SUM(HolderBalance)` |
| Approximate total AUM in USD | `SUM(USDApproxBalance)` WHERE USDApproxBalance IS NOT NULL |
| Card-active account balances | `WHERE CardTxMO IS NOT NULL` (2,423 accounts with card spending) |
| Zero-balance accounts | `WHERE HolderBalance = 0` (733,266 rows — 56.9%) |
| Date of snapshot | `SELECT DISTINCT DateID` — always one value (GETDATE()-1 at last run) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Account | ON ssb.AccountID = mda.AccountID | Full account attributes (IsValidETM, AccountProgram, etc.) |
| eMoney_dbo.eMoney_Panel_FirstDates | ON ssb.CID = fd.CID | FMI/FMO milestone cross-reference |
| DWH_dbo.Dim_Customer | ON ssb.CID = dc.RealCID | Current customer trading profile |

### 3.4 Gotchas

- **TRUNCATE daily — no history**: This table always holds one day only. Do not attempt to query historical balance by DateID — only one value exists.
- **Duplicate rows**: ~544 AccountIDs have 2+ identical rows. Always use SUM/AVG rather than assuming one row per account; or add DISTINCT when counting accounts.
- **NULL ≠ zero in category columns**: CardTxMI=NULL means no card MI transactions, not zero card balance. Use `COALESCE(CardTxMI, 0)` in SUM calculations.
- **DKK has no USD approximation**: All 431 DKK rows have NULL USDApprox* columns. Filter these out before computing USD-based totals.
- **Negative HolderBalance is valid**: Observed range -597,856 to +999,629. Negative balances indicate accounts where reversals or timing effects result in a net debit position.
- **HolderBalance relationship**: HolderBalance = TotalMI + TotalMO (TotalMO is negative). Do not sum these columns independently.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB or etoro DB_Schema) |
| Tier 2 | Derived from ETL SP code or DWH computation logic |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Glossary-sourced |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | YYYYMMDD integer representing the settled balance snapshot date (GETDATE()-1 at SP run time, e.g., 20260411). The entire table always contains only one DateID. (Tier 2 — SP_eMoney_Snapshot_Settled_Balance) |
| 2 | AccountID | int | YES | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. DWH note: renamed from `Id` in dbo.FiatAccount. (Tier 1 — dbo.FiatAccount) |
| 3 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |
| 4 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | CurrencyBalanceISOCode | int | YES | ISO 4217 numeric currency code for this account's balance (978=EUR, 826=GBP, 36=AUD, 208=DKK). One row per account per currency. Distribution: EUR=64.7%, GBP=33.7%, AUD=1.6%, DKK<0.1%. (Tier 2 — SP_eMoney_Snapshot_Settled_Balance) |
| 6 | HolderBalanceCurrency | varchar(50) | YES | Text currency label for HolderBalanceCurrency (e.g., 'EUR', 'GBP', 'AUD'). Derived from eMoney_Currency_Instrument_Mapping_Static by CurrencyBalanceISOCode. NULL for DKK (208) — no mapping in static table. (Tier 2 — eMoney_Currency_Instrument_Mapping_Static) |
| 7 | HolderBalance | numeric(38,2) | YES | Cumulative net settled balance for this account as of DateID. Computed as SUM(HolderAmount) for all settled transactions (TxStatusID=2) through the snapshot date. HolderBalance = TotalMI + TotalMO. Range: -597,856.82 to +999,628.82. 733,266 rows = 0.00 (56.9%). (Tier 2 — eMoney_Dim_Transaction) |
| 8 | CountTxsHolderBalance | int | YES | Total count of settled transactions (TxStatusID=2) for this account contributing to HolderBalance. Includes all transaction types. (Tier 2 — eMoney_Dim_Transaction) |
| 9 | TotalMI | numeric(38,2) | YES | Gross cumulative money-in (positive HolderAmount) settled transactions. TotalMI = CardTxMI + IBANInMI + IBANOutMI + DirectDebitMI + OtherMI (non-NULL category components). All 1,287,999 rows have TotalMI populated. (Tier 2 — eMoney_Dim_Transaction) |
| 10 | CountTxsMI | int | YES | Count of money-in transactions contributing to TotalMI. (Tier 2 — eMoney_Dim_Transaction) |
| 11 | TotalMO | numeric(38,2) | YES | Gross cumulative money-out (negative HolderAmount) settled transactions. TotalMO = CardTxMO + IBANInMO + IBANOutMO + DirectDebitMO + OtherMO (non-NULL components, all negative). (Tier 2 — eMoney_Dim_Transaction) |
| 12 | CountTxsMO | int | YES | Count of money-out transactions contributing to TotalMO. (Tier 2 — eMoney_Dim_Transaction) |
| 13 | CardTxMI | numeric(38,2) | YES | Cumulative money-in from debit card transactions (card credits, cashback, card reversals). NULL if account has no card MI activity (99.81% of rows). 2,423 rows non-NULL. (Tier 2 — eMoney_Dim_Transaction) |
| 14 | CardTxMO | numeric(38,2) | YES | Cumulative money-out from debit card transactions (card purchases and payments, negative). NULL if account has no card MO activity. (Tier 2 — eMoney_Dim_Transaction) |
| 15 | IBANInMI | numeric(38,2) | YES | Cumulative money-in from inbound IBAN transfers (bank→eTM, SEPA received). The dominant MI channel; 1,287,158 rows non-NULL (99.9%). (Tier 2 — eMoney_Dim_Transaction) |
| 16 | IBANInMO | numeric(38,2) | YES | Cumulative money-out from inbound IBAN transfer reversals (SEPA received payment returned to sender, negative, rare). NULL if no inbound reversals. (Tier 2 — eMoney_Dim_Transaction) |
| 17 | IBANOutMI | numeric(38,2) | YES | Cumulative money-in from outbound IBAN transfer reversals (eTM→bank transfers returned to account). NULL if no outbound reversals. (Tier 2 — eMoney_Dim_Transaction) |
| 18 | IBANOutMO | numeric(38,2) | YES | Cumulative money-out from outbound IBAN transfers (eTM→bank, SEPA sent, negative). NULL if account has never sent a bank transfer. (Tier 2 — eMoney_Dim_Transaction) |
| 19 | DirectDebitMI | numeric(38,2) | YES | Cumulative money-in from direct debit refunds or reversals (positive). NULL if no direct debit MI activity. (Tier 2 — eMoney_Dim_Transaction) |
| 20 | DirectDebitMO | numeric(38,2) | YES | Cumulative money-out from direct debit deductions (automated UK bank debits, negative). NULL if account has no direct debit activity (593 rows non-NULL). (Tier 2 — eMoney_Dim_Transaction) |
| 21 | OtherMI | numeric(38,2) | YES | Cumulative money-in from transaction types not covered by Card, IBAN In, IBAN Out, or Direct Debit categories. NULL if no uncategorised MI activity (11,580 rows non-NULL). (Tier 2 — eMoney_Dim_Transaction) |
| 22 | OtherMO | numeric(38,2) | YES | Cumulative money-out from uncategorised transaction types. NULL if no uncategorised MO activity. (Tier 2 — eMoney_Dim_Transaction) |
| 23 | USDApproxDate | date | YES | Reference date for the USD FX rate used in USDApprox* columns. Set to GETDATE()-1 (same business date as DateID). (Tier 2 — SP_eMoney_Snapshot_Settled_Balance) |
| 24 | USDApproxBalance | numeric(38,2) | YES | HolderBalance converted to USD using the FX rate for USDApproxDate from Fact_CurrencyPriceWithSplit. Indicative approximation only. NULL for DKK (208) — no USD instrument mapping. (Tier 2 — Fact_CurrencyPriceWithSplit) |
| 25 | USDApproxTotalMI | numeric(38,2) | YES | TotalMI converted to USD. NULL for DKK. Indicative; uses single-day spot rate. (Tier 2 — Fact_CurrencyPriceWithSplit) |
| 26 | USDApproxTotalMO | numeric(38,2) | YES | TotalMO converted to USD (negative value). NULL for DKK. Indicative; uses single-day spot rate. (Tier 2 — Fact_CurrencyPriceWithSplit) |
| 27 | UpdateDate | datetime | YES | Timestamp when this record was written by the SP. Set to GETDATE() at TRUNCATE+INSERT time. Reflects the SP run time, not the business event. (Tier 2 — SP_eMoney_Snapshot_Settled_Balance) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AccountID | FiatDwhDB.dbo.FiatAccount | Id | Renamed; via eMoney_Dim_Account |
| GCID | FiatDwhDB.dbo.FiatAccount | Gcid | Via eMoney_Dim_Account |
| CID | etoro.Customer.CustomerStatic | CID | Via eMoney_Dim_Account |
| HolderBalance | eMoney_dbo.eMoney_Dim_Transaction | HolderAmount | SUM(TxStatusID=2) |
| TotalMI | eMoney_dbo.eMoney_Dim_Transaction | HolderAmount | SUM WHERE > 0 |
| TotalMO | eMoney_dbo.eMoney_Dim_Transaction | HolderAmount | SUM WHERE < 0 |
| CardTx* / IBANIn* / IBANOut* / DirectDebit* / Other* | eMoney_dbo.eMoney_Dim_Transaction | HolderAmount | SUM by TxTypeID category |
| USDApprox* | DWH_dbo.Fact_CurrencyPriceWithSplit | — | FX rate × balance/MI/MO |
| HolderBalanceCurrency | eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static | — | Currency text by ISO code |

### 5.2 ETL Pipeline

```
eMoney_dbo.eMoney_Dim_Account (AccountID, GCID, CID, CurrencyBalanceISOCode)
  + eMoney_dbo.eMoney_Dim_Transaction (settled TXs, TxStatusID=2 — all MI/MO by category)
  |-- SP Step 1: #accountbalance (GROUP BY AccountID/GCID/CID: balance + MI/MO decomposition) ---|
  v
eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static (currency code → text label)
  + DWH_dbo.Fact_CurrencyPriceWithSplit (USD FX rate for GETDATE()-1)
  |-- SP Step 2: #final (adds CurrencyBalanceISOCode, HolderBalanceCurrency, USD approx) ---|
  v
SP_eMoney_Snapshot_Settled_Balance: TRUNCATE + INSERT
  v
eMoney_dbo.eMoney_Snapshot_Settled_Balance (1,287,999 rows, DateID=20260411, HASH(CID), HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountID | eMoney_dbo.eMoney_Dim_Account | Account grain key |
| CID / GCID | DWH_dbo.Dim_Customer | Current trading profile |
| Settled transactions | eMoney_dbo.eMoney_Dim_Transaction | Source of all balance and flow aggregations |
| USD FX rate | DWH_dbo.Fact_CurrencyPriceWithSplit | USD approximation FX rate |
| Currency label | eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static | ISO code → text currency mapping |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance | UC Gold export (Generic Pipeline, delta) |

---

## 7. Sample Queries

```sql
-- Current eTM wallet AUM (assets under management) by currency
SELECT
    HolderBalanceCurrency,
    COUNT(*) AS accounts,
    SUM(HolderBalance) AS total_balance,
    SUM(USDApproxBalance) AS total_usd_approx,
    AVG(HolderBalance) AS avg_balance
FROM eMoney_dbo.eMoney_Snapshot_Settled_Balance
WHERE HolderBalance > 0
GROUP BY HolderBalanceCurrency
ORDER BY total_balance DESC;
```

```sql
-- Transaction type breakdown: what proportion of eTM volume is card vs. IBAN?
SELECT
    COUNT(CASE WHEN CardTxMI IS NOT NULL THEN 1 END) AS card_active_accounts,
    COUNT(CASE WHEN IBANInMI IS NOT NULL THEN 1 END) AS iban_in_active_accounts,
    COUNT(CASE WHEN IBANOutMO IS NOT NULL THEN 1 END) AS iban_out_active_accounts,
    COUNT(CASE WHEN DirectDebitMO IS NOT NULL THEN 1 END) AS direct_debit_active_accounts,
    SUM(COALESCE(CardTxMO, 0)) AS total_card_spend,
    SUM(COALESCE(IBANInMI, 0)) AS total_iban_received,
    SUM(COALESCE(IBANOutMO, 0)) AS total_iban_sent
FROM eMoney_dbo.eMoney_Snapshot_Settled_Balance;
```

```sql
-- Accounts with card activity: balance and card spending profile
SELECT
    CID, GCID, HolderBalanceCurrency, HolderBalance,
    CardTxMI, CardTxMO, IBANInMI, IBANOutMO,
    USDApproxBalance
FROM eMoney_dbo.eMoney_Snapshot_Settled_Balance
WHERE CardTxMO IS NOT NULL
ORDER BY ABS(CAST(CardTxMO AS FLOAT)) DESC;
```

---

## 8. Sources

No Atlassian documentation found for this object.

---

*Generated: 2026-04-21 | Quality: 8.9/10 | Phases: 13/14*
*Tiers: 3 T1, 24 T2, 0 T3, 0 T4, 0 T5 | Elements: 27/27*

> **Phase Gate Check**: T1 columns (AccountID, GCID, CID) verified against eMoney_Dim_Account.md (#2 AccountID, #3 GCID), eMoney_Account_Mappings.md (#13 AccountID, #14 GCID), eMoney_Card_Instance_Summary.md (#1 CID). MI/MO category decomposition additive relationship verified against sample data (TotalMI = sum of CardTxMI + IBANInMI + IBANOutMI + DirectDebitMI + OtherMI confirmed on live rows). All 27 elements documented.

> **T1 Copy Verification**: AccountID — "Auto-incrementing surrogate primary key..." matches eMoney_Dim_Account #2, eMoney_Panel_FirstDates #1. GCID — "Global Customer ID..." matches eMoney_Account_Mappings #14, eMoney_Dim_Account #3. CID — "Customer ID - platform-internal primary key..." matches eMoney_Card_Instance_Summary #1.
