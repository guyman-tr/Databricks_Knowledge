# eMoney_dbo.eMoney_Panel_FirstDates

> Per-account first-date milestone panel for eToro Money — one row per eMoney account (GCID_Unique_Count=1), capturing the account's first settled money-in (FMI) and money-out (FMO) events, IBAN/card date ranges, card activation timestamp, and the first 5 transactions by category (general, IBAN, Card). The primary source for FMI/FMO signals consumed by `eMoney_Reports_AcquisitionFunnel`. Refreshed daily by `SP_eMoney_Panel_FirstDates`.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Sources** | eMoney_Dim_Account (grain), eMoney_Dim_Transaction (all event data) |
| **Refresh** | Daily — DELETE + INSERT full refresh via SP_eMoney_Panel_FirstDates (Steps 1–8) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override strategy, daily) |

---

## 1. Business Meaning

`eMoney_Panel_FirstDates` is the central milestone-tracking panel for eToro Money accounts. Each row represents one eMoney account and records when (and how) that account first moved money in and out, the date ranges of IBAN and card activity, the card activation timestamp, and the first 5 transactions across three category cuts (all types, IBAN only, card only).

As of 2026-04-12 the table has **2,031,884 rows** (2,031,882 distinct CIDs — 2 accounts share a CID, likely a data anomaly). The earliest FMI_Date is 2020-11-10, corresponding to the UK launch. Key adoption rates:

| Milestone | Count | % of accounts |
|-----------|-------|---------------|
| Has FMI (ever funded) | 1,286,611 | 63.3% |
| Has FMO (ever sent) | 1,242,239 | 61.1% |
| Card activated | 26,832 | 1.3% |
| Card first tx | 25,135 | 1.2% |
| ≥1 settled action | 1,287,451 | 63.4% |
| ≥5 settled actions | 687,082 | 33.8% |

The table is the authoritative source for FMI/FMO signals in the eMoney acquisition funnel (`SP_eMoney_Reports_Daily` JOINs here to derive `IsFMI` and `IsFMO` flags).

**Grain filter**: Only accounts where `GCID_Unique_Count=1` in `eMoney_Dim_Account` are included — multi-account GCIDs are excluded to prevent double-counting. This filter was added 2026-01-12 by Shachar Rubin.

---

## 2. Business Logic

### 2.1 First Money-In (FMI)

**What**: Date, time, and source classification of the first settled inbound transaction.
**Columns Involved**: FMI_Date, FMI_Time, FMI_Source, Seniority_FMI
**Rules**:
- Settled IN tx = TxTypeID IN (5, 7), TxStatusID=2, HolderAmount≠0
- SP Step 1 (#fmi): `ROW_NUMBER() OVER (PARTITION BY AccountID ORDER BY TxStatusModificationTime ASC)` — row 1 = first ever
- FMI_Source CASE: TxTypeID=7 → `'External'` (PaymentReceived); TxTypeID=5 → `'TP'` (TransferReceived)
- Seniority_FMI = `DATEDIFF(MONTH, FMI_Date, @Date)` — months from first funding to the refresh run date
- As of 2026-04-12: FMI_Source TP=672,868 (52.3%), External=613,743 (47.7%)

### 2.2 First Money-Out (FMO)

**What**: Date, time, destination, and method-of-payment of the first settled outbound transaction.
**Columns Involved**: FMO_Date, FMO_Time, FMO_Target, FMO_MOP, Seniority_FMO
**Rules**:
- Settled OUT tx = TxTypeID IN (1,2,3,4,6,8,13), TxStatusID=2, HolderAmount≠0
- SP Step 2 (#fmo): `ROW_NUMBER() OVER (PARTITION BY AccountID ORDER BY TxStatusModificationTime ASC)` — row 1 = first ever
- FMO_Target CASE: TxTypeID=6 → `'TP'` (Transfer); others → `'External'`
- FMO_MOP CASE: TxTypeID IN (1,2,3,4) → `'Card'`; TxTypeID IN (6,8) → `'IBAN'`; TxTypeID=13 → `'DirectDebit'`
- Seniority_FMO = `DATEDIFF(MONTH, FMO_Date, @Date)`
- As of 2026-04-12: FMO_Target TP=700,796 (56.4%), External=541,443 (43.6%); FMO_MOP IBAN=1,235,319 (99.4%), Card=6,908 (0.6%), DirectDebit=12 (<0.01%)

### 2.3 Transaction Date Ranges

**What**: MIN/MAX settled tx dates by payment rail.
**Columns Involved**: LastSettledTXDate, FirstIBANSettledTXDate, LastIBANSettledTXDate, FirstCardSettledTXDate, LastCardSettledTXDate, Seniority_LastTXDate
**Rules**:
- SP Step 3 (#transactions): aggregates over all settled tx (TxStatusID=2, HolderAmount≠0) per AccountID
- LastSettledTXDate = MAX(TxStatusModificationDate) across all settled tx
- IBAN range: TxTypeID IN (5,6,7,8) → MIN/MAX
- Card range: TxTypeID IN (1,2,3,4) → MIN/MAX
- Seniority_LastTXDate = `DATEDIFF(MONTH, LastSettledTXDate, @Date)` — months since last activity

### 2.4 Card Activation

**What**: Timestamp when the physical/virtual card was activated.
**Columns Involved**: CardActivationTime
**Rules**:
- Source: eMoney_Dim_Account.CardStatusTime
- Logic: `CASE WHEN CardStatusID=1 THEN CardStatusTime ELSE NULL END`
- CardStatusID=1 indicates an activated card state; all other states (not issued, blocked, etc.) yield NULL

### 2.5 First 5 Actions — General

**What**: Date, type name, and USD-approximate amount of the first through fifth settled transactions of any type.
**Columns Involved**: 1stActionDate/Type/USDApproxAmount … 5thActionDate/Type/USDApproxAmount
**Rules**:
- SP Step 4 (#firstactions_general): all settled tx (TxStatusID=2, HolderAmount≠0), ranked by TxStatusModificationTime ASC per account
- `ROW_NUMBER() OVER (PARTITION BY AccountID ORDER BY TxStatusModificationTime ASC)` → RowNumASC 1–5
- For each N: `MAX(CASE WHEN RowNumASC=N THEN col END)` across the partition → one scalar per account
- USDApproxAmount = money type (ROUND(HolderAmount × mid-rate, 2)); NULL for DKK accounts

### 2.6 First 5 Actions — IBAN

**What**: First through fifth IBAN-rail transactions.
**Columns Involved**: IBAN1stActionDate … IBAN5thActionUSDApproxAmount
**Rules**:
- SP Step 5 (#firstactions_iban): same pattern as general, filtered to TxTypeID IN (5,6,7,8)
- NULL for all IBAN columns if account has no IBAN activity

### 2.7 First 5 Actions — Card

**What**: First through fifth card-rail transactions.
**Columns Involved**: Card1stActionDate … Card5thActionUSDApproxAmount
**Rules**:
- SP Step 6 (#firstactions_card): same pattern as general, filtered to TxTypeID IN (1,2,3,4)
- NULL for all Card columns for the 98.7% of accounts with no card activation

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution is optimal for GROUP BY CID or JOINs to other CID-keyed tables (Dim_Customer, eMoney_Reports_AcquisitionFunnel). HEAP is appropriate — the table is written as a full daily refresh with no incremental key.

**UC format is parquet** (not delta). The Gold target `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` does not support MERGE/UPDATE operations from Databricks; always read it as a full snapshot.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly FMI cohort | `GROUP BY DATE_TRUNC('month', FMI_Date)` |
| FMI→FMO conversion lag | `DATEDIFF(DAY, FMI_Date, FMO_Date)` — filter `FMO_Date IS NOT NULL` |
| Card adoption among funded | `WHERE FMI_Date IS NOT NULL AND CardActivationTime IS NOT NULL` |
| IBAN vs card first-action mix | `COUNT(IBAN1stActionDate) vs COUNT(Card1stActionDate)` |
| Active accounts (last 3 months) | `WHERE Seniority_LastTXDate <= 3` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Reports_AcquisitionFunnel | `CID` | Enrich funnel customer grain with FMI/FMO dates |
| eMoney_Dim_Account | `AccountID` | Add account metadata (currency, country) |
| DWH_dbo.Dim_Customer | `CID` | Add trading-side customer attributes |

### 3.4 Gotchas

- **36.7% of rows have NULL FMI_Date**: Accounts in eMoney_Dim_Account that have never funded. All downstream FMI columns (Seniority_FMI, FMI_Time, FMI_Source) are NULL for these rows.
- **GCID_Unique_Count=1 grain filter**: Accounts where one GCID maps to multiple eMoney accounts are excluded entirely. If a customer reports a missing row, check `eMoney_Dim_Account.GCID_Unique_Count`.
- **Seniority columns reflect the SP run date, not today**: They are computed at INSERT time using `@Date = CONVERT(DATE, GETDATE())`. Values grow stale by 1 for each day since the last SP run. For real-time seniority, compute `DATEDIFF(MONTH, FMI_Date, GETDATE())` directly.
- **Action columns are wide-pivoted NULLs**: An account with only 2 settled actions will have NULL for 3rd/4th/5thActionDate. Do not interpret NULL as "no data after row 2" — it means the account has fewer than N actions.
- **FMO_MOP is dominated by IBAN (99.4%)**: Card and DirectDebit FMOs are rare; card usage almost always starts as card-first-action rather than first-ever-out.
- **2 duplicate CID rows**: Two accounts share a CID (data anomaly). JOINs to Dim_Customer on CID may produce unexpected duplicates for those accounts.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki — description copied exactly |
| Tier 2 | Derived or computed by ETL SP — passthrough transformation, aggregate, or CASE |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountID | int | YES | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. (Tier 1 — dbo.FiatAccount) |
| 2 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |
| 3 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | FMI_Date | date | YES | Date of the account's first settled money-in transaction (TxTypeID IN [5,7], TxStatusID=2, HolderAmount≠0). Derived from TxStatusModificationDate of ROW_NUMBER=1 (ASC by TxStatusModificationTime). NULL for 36.7% of accounts that have never funded. Earliest value: 2020-11-10 (UK launch). (Tier 2 — eMoney_Dim_Transaction) |
| 5 | Seniority_FMI | int | YES | Months elapsed between FMI_Date and the SP run date. DATEDIFF(MONTH, FMI_Date, @Date). NULL when FMI_Date is NULL. Computed at INSERT time — recalculate DATEDIFF directly for real-time values. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 6 | FMI_Time | datetime | YES | Full timestamp of the first settled money-in transaction. Derived from TxStatusModificationTime of ROW_NUMBER=1 (ASC). NULL when FMI_Date is NULL. (Tier 2 — eMoney_Dim_Transaction) |
| 7 | FMI_Source | varchar(50) | YES | Origin classification of the first money-in: `'TP'` (TxTypeID=5, TransferReceived — internal eToro transfer) or `'External'` (TxTypeID=7, PaymentReceived — bank/external). As of 2026-04-12: TP=672,868 (52.3%), External=613,743 (47.7%). NULL when FMI_Date is NULL. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 8 | FMO_Date | date | YES | Date of the account's first settled money-out transaction (TxTypeID IN [1,2,3,4,6,8,13], TxStatusID=2, HolderAmount≠0). Derived from TxStatusModificationDate of ROW_NUMBER=1 (ASC by TxStatusModificationTime). NULL for 38.9% of accounts that have never sent. (Tier 2 — eMoney_Dim_Transaction) |
| 9 | Seniority_FMO | int | YES | Months elapsed between FMO_Date and the SP run date. DATEDIFF(MONTH, FMO_Date, @Date). NULL when FMO_Date is NULL. Computed at INSERT time. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 10 | FMO_Time | datetime | YES | Full timestamp of the first settled money-out transaction. Derived from TxStatusModificationTime of ROW_NUMBER=1 (ASC). NULL when FMO_Date is NULL. (Tier 2 — eMoney_Dim_Transaction) |
| 11 | FMO_Target | varchar(50) | YES | Destination classification of the first money-out: `'TP'` (TxTypeID=6 — internal Transfer to eToro user) or `'External'` (all other OUT types — bank, card, DD). As of 2026-04-12: TP=700,796 (56.4%), External=541,443 (43.6%). NULL when FMO_Date is NULL. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 12 | FMO_MOP | varchar(50) | YES | Method of payment for the first money-out: `'Card'` (TxTypeID IN [1,2,3,4]), `'IBAN'` (TxTypeID IN [6,8]), `'DirectDebit'` (TxTypeID=13). As of 2026-04-12: IBAN=1,235,319 (99.4% of FMO accounts), Card=6,908 (0.6%), DirectDebit=12 (<0.01%). NULL when FMO_Date is NULL. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 13 | LastSettledTXDate | date | YES | Date of the account's most recent settled transaction across all types (TxStatusID=2, HolderAmount≠0). MAX(TxStatusModificationDate). Used as a recency signal; compare to GETDATE() for churn analysis. NULL if no settled transactions. (Tier 2 — eMoney_Dim_Transaction) |
| 14 | Seniority_LastTXDate | int | YES | Months elapsed between LastSettledTXDate and the SP run date. DATEDIFF(MONTH, LastSettledTXDate, @Date). Accounts with Seniority_LastTXDate ≤ 3 are typically considered active. Computed at INSERT time. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 15 | FirstIBANSettledTXDate | date | YES | Date of the account's first settled IBAN-rail transaction (TxTypeID IN [5,6,7,8]). MIN(TxStatusModificationDate) for IBAN types. NULL if no IBAN activity. (Tier 2 — eMoney_Dim_Transaction) |
| 16 | LastIBANSettledTXDate | date | YES | Date of the account's most recent settled IBAN-rail transaction (TxTypeID IN [5,6,7,8]). MAX(TxStatusModificationDate) for IBAN types. NULL if no IBAN activity. (Tier 2 — eMoney_Dim_Transaction) |
| 17 | CardActivationTime | datetime | YES | Timestamp when the card reached activated status. CASE WHEN CardStatusID=1 THEN CardStatusTime ELSE NULL END, sourced from eMoney_Dim_Account. NULL for 98.7% of accounts with no activated card. (Tier 2 — eMoney_Dim_Account) |
| 18 | FirstCardSettledTXDate | date | YES | Date of the account's first settled card-rail transaction (TxTypeID IN [1,2,3,4]). MIN(TxStatusModificationDate) for card types. NULL if no card activity. (Tier 2 — eMoney_Dim_Transaction) |
| 19 | LastCardSettledTXDate | date | YES | Date of the account's most recent settled card-rail transaction (TxTypeID IN [1,2,3,4]). MAX(TxStatusModificationDate) for card types. NULL if no card activity. (Tier 2 — eMoney_Dim_Transaction) |
| 20 | 1stActionDate | date | YES | Date of the account's 1st settled transaction (all types, ranked ASC by TxStatusModificationTime). MAX(CASE WHEN RowNumASC=1 THEN TxStatusModificationDate END). NULL if no settled tx. (Tier 2 — eMoney_Dim_Transaction) |
| 21 | 1stActionType | varchar(50) | YES | TxType name of the 1st settled transaction. MAX(CASE WHEN RowNumASC=1 THEN TxType END). Values: CardPayment, Transfer, PaymentReceived, etc. NULL if no settled tx. (Tier 2 — eMoney_Dim_Transaction) |
| 22 | 1stActionUSDApproxAmount | money | YES | Approximate USD value of the 1st settled transaction. MAX(CASE WHEN RowNumASC=1 THEN USDAmountApprox END). ROUND(HolderAmount × mid-rate, 2). NULL for DKK and if no settled tx. (Tier 2 — eMoney_Dim_Transaction) |
| 23 | 2ndActionDate | date | YES | Date of the account's 2nd settled transaction (all types, ranked ASC). NULL if fewer than 2 settled tx. Same derivation as 1stActionDate with RowNumASC=2. (Tier 2 — eMoney_Dim_Transaction) |
| 24 | 2ndActionType | varchar(50) | YES | TxType name of the 2nd settled transaction. NULL if fewer than 2. (Tier 2 — eMoney_Dim_Transaction) |
| 25 | 2ndActionUSDApproxAmount | money | YES | USD approximate amount of the 2nd settled transaction. NULL if fewer than 2. (Tier 2 — eMoney_Dim_Transaction) |
| 26 | 3rdActionDate | date | YES | Date of the 3rd settled transaction (all types, ranked ASC). NULL if fewer than 3. (Tier 2 — eMoney_Dim_Transaction) |
| 27 | 3rdActionType | varchar(50) | YES | TxType name of the 3rd settled transaction. NULL if fewer than 3. (Tier 2 — eMoney_Dim_Transaction) |
| 28 | 3rdActionUSDApproxAmount | money | YES | USD approximate amount of the 3rd settled transaction. NULL if fewer than 3. (Tier 2 — eMoney_Dim_Transaction) |
| 29 | 4thActionDate | date | YES | Date of the 4th settled transaction (all types, ranked ASC). NULL if fewer than 4. (Tier 2 — eMoney_Dim_Transaction) |
| 30 | 4thActionType | varchar(50) | YES | TxType name of the 4th settled transaction. NULL if fewer than 4. (Tier 2 — eMoney_Dim_Transaction) |
| 31 | 4thActionUSDApproxAmount | money | YES | USD approximate amount of the 4th settled transaction. NULL if fewer than 4. (Tier 2 — eMoney_Dim_Transaction) |
| 32 | 5thActionDate | date | YES | Date of the 5th settled transaction (all types, ranked ASC). NULL if fewer than 5. (Tier 2 — eMoney_Dim_Transaction) |
| 33 | 5thActionType | varchar(50) | YES | TxType name of the 5th settled transaction. NULL if fewer than 5. (Tier 2 — eMoney_Dim_Transaction) |
| 34 | 5thActionUSDApproxAmount | money | YES | USD approximate amount of the 5th settled transaction. NULL if fewer than 5. (Tier 2 — eMoney_Dim_Transaction) |
| 35 | IBAN1stActionDate | date | YES | Date of the account's 1st settled IBAN-rail transaction (TxTypeID IN [5,6,7,8]), ranked ASC. NULL if no IBAN activity. (Tier 2 — eMoney_Dim_Transaction) |
| 36 | IBAN1stActionType | varchar(50) | YES | TxType name of the 1st settled IBAN transaction. Values: Transfer, TransferReceived, PaymentReceived, Payment. NULL if no IBAN activity. (Tier 2 — eMoney_Dim_Transaction) |
| 37 | IBAN1stActionUSDApproxAmount | money | YES | USD approximate amount of the 1st settled IBAN transaction. NULL for DKK and no IBAN activity. (Tier 2 — eMoney_Dim_Transaction) |
| 38 | IBAN2ndActionDate | date | YES | Date of the 2nd settled IBAN transaction. NULL if fewer than 2 IBAN tx. Same derivation as IBAN1st with RowNumASC=2. (Tier 2 — eMoney_Dim_Transaction) |
| 39 | IBAN2ndActionType | varchar(50) | YES | TxType of the 2nd settled IBAN transaction. NULL if fewer than 2 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 40 | IBAN2ndActionUSDApproxAmount | money | YES | USD amount of the 2nd settled IBAN transaction. NULL if fewer than 2 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 41 | IBAN3rdActionDate | date | YES | Date of the 3rd settled IBAN transaction. NULL if fewer than 3 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 42 | IBAN3rdActionType | varchar(50) | YES | TxType of the 3rd settled IBAN transaction. NULL if fewer than 3 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 43 | IBAN3rdActionUSDApproxAmount | money | YES | USD amount of the 3rd settled IBAN transaction. NULL if fewer than 3 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 44 | IBAN4thActionDate | date | YES | Date of the 4th settled IBAN transaction. NULL if fewer than 4 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 45 | IBAN4thActionType | varchar(50) | YES | TxType of the 4th settled IBAN transaction. NULL if fewer than 4 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 46 | IBAN4thActionUSDApproxAmount | money | YES | USD amount of the 4th settled IBAN transaction. NULL if fewer than 4 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 47 | IBAN5thActionDate | date | YES | Date of the 5th settled IBAN transaction. NULL if fewer than 5 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 48 | IBAN5thActionType | varchar(50) | YES | TxType of the 5th settled IBAN transaction. NULL if fewer than 5 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 49 | IBAN5thActionUSDApproxAmount | money | YES | USD amount of the 5th settled IBAN transaction. NULL if fewer than 5 IBAN tx. (Tier 2 — eMoney_Dim_Transaction) |
| 50 | Card1stActionDate | date | YES | Date of the account's 1st settled card-rail transaction (TxTypeID IN [1,2,3,4]), ranked ASC. NULL for 98.7% of accounts with no card activity. (Tier 2 — eMoney_Dim_Transaction) |
| 51 | Card1stActionType | varchar(50) | YES | TxType name of the 1st settled card transaction. Values: CardPayment, ContactlessPayment, CardCashWithdrawal, CardRefund. NULL if no card activity. (Tier 2 — eMoney_Dim_Transaction) |
| 52 | Card1stActionUSDApproxAmount | money | YES | USD approximate amount of the 1st settled card transaction. NULL if no card activity. (Tier 2 — eMoney_Dim_Transaction) |
| 53 | Card2ndActionDate | date | YES | Date of the 2nd settled card transaction. NULL if fewer than 2 card tx. Same derivation as Card1st with RowNumASC=2. (Tier 2 — eMoney_Dim_Transaction) |
| 54 | Card2ndActionType | varchar(50) | YES | TxType of the 2nd settled card transaction. NULL if fewer than 2 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 55 | Card2ndActionUSDApproxAmount | money | YES | USD amount of the 2nd settled card transaction. NULL if fewer than 2 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 56 | Card3rdActionDate | date | YES | Date of the 3rd settled card transaction. NULL if fewer than 3 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 57 | Card3rdActionType | varchar(50) | YES | TxType of the 3rd settled card transaction. NULL if fewer than 3 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 58 | Card3rdActionUSDApproxAmount | money | YES | USD amount of the 3rd settled card transaction. NULL if fewer than 3 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 59 | Card4thActionDate | date | YES | Date of the 4th settled card transaction. NULL if fewer than 4 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 60 | Card4thActionType | varchar(50) | YES | TxType of the 4th settled card transaction. NULL if fewer than 4 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 61 | Card4thActionUSDApproxAmount | money | YES | USD amount of the 4th settled card transaction. NULL if fewer than 4 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 62 | Card5thActionDate | date | YES | Date of the 5th settled card transaction. NULL if fewer than 5 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 63 | Card5thActionType | varchar(50) | YES | TxType of the 5th settled card transaction. NULL if fewer than 5 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 64 | Card5thActionUSDApproxAmount | money | YES | USD amount of the 5th settled card transaction. NULL if fewer than 5 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 65 | UpdateDate | datetime | YES | Timestamp of the most recent SP refresh. Set to GETDATE() at INSERT time; all rows share the same value per daily run. Last observed: 2026-04-12. (Tier 2 — SP_eMoney_Panel_FirstDates) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AccountID | eMoney_Dim_Account | AccountID | Passthrough (grain key) |
| GCID | eMoney_Dim_Account | GCID | Passthrough |
| CID | eMoney_Dim_Account | CID | Passthrough |
| FMI_Date | eMoney_Dim_Transaction | TxStatusModificationDate | MIN by ROW_NUMBER ASC (TxTypeID IN [5,7]) |
| FMI_Time | eMoney_Dim_Transaction | TxStatusModificationTime | First settled IN tx |
| FMI_Source | SP_eMoney_Panel_FirstDates | TxTypeID | CASE: 7→External, 5→TP |
| Seniority_FMI | SP_eMoney_Panel_FirstDates | — | DATEDIFF(MONTH, FMI_Date, @Date) |
| FMO_Date | eMoney_Dim_Transaction | TxStatusModificationDate | MIN by ROW_NUMBER ASC (TxTypeID IN [1-4,6,8,13]) |
| FMO_Time | eMoney_Dim_Transaction | TxStatusModificationTime | First settled OUT tx |
| FMO_Target | SP_eMoney_Panel_FirstDates | TxTypeID | CASE: 6→TP, others→External |
| FMO_MOP | SP_eMoney_Panel_FirstDates | TxTypeID | CASE: 1-4→Card, 6/8→IBAN, 13→DirectDebit |
| Seniority_FMO | SP_eMoney_Panel_FirstDates | — | DATEDIFF(MONTH, FMO_Date, @Date) |
| LastSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MAX (all settled) |
| Seniority_LastTXDate | SP_eMoney_Panel_FirstDates | — | DATEDIFF(MONTH, LastSettledTXDate, @Date) |
| FirstIBANSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MIN WHERE TxTypeID IN (5,6,7,8) |
| LastIBANSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MAX WHERE TxTypeID IN (5,6,7,8) |
| CardActivationTime | eMoney_Dim_Account | CardStatusTime | CASE WHEN CardStatusID=1 |
| FirstCardSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MIN WHERE TxTypeID IN (1,2,3,4) |
| LastCardSettledTXDate | eMoney_Dim_Transaction | TxStatusModificationDate | MAX WHERE TxTypeID IN (1,2,3,4) |
| NthActionDate (1–5) | eMoney_Dim_Transaction | TxStatusModificationDate | MAX(CASE WHEN RowNumASC=N) |
| NthActionType (1–5) | eMoney_Dim_Transaction | TxType | MAX(CASE WHEN RowNumASC=N) |
| NthActionUSDApproxAmount (1–5) | eMoney_Dim_Transaction | USDAmountApprox | MAX(CASE WHEN RowNumASC=N) |
| IBANNthAction* (1–5, 3 cols each) | eMoney_Dim_Transaction | Same as above | Filtered TxTypeID IN (5,6,7,8) |
| CardNthAction* (1–5, 3 cols each) | eMoney_Dim_Transaction | Same as above | Filtered TxTypeID IN (1,2,3,4) |
| UpdateDate | SP_eMoney_Panel_FirstDates | — | GETDATE() at INSERT |

### 5.2 ETL Pipeline

```
eMoney_Dim_Account (WHERE GCID_Unique_Count=1 — grain definition)
  + eMoney_Dim_Transaction (WHERE TxStatusID=2, HolderAmount≠0)
    → Step 1: #fmi — ROW_NUMBER ASC on IN tx (TxTypeID IN [5,7])
    → Step 2: #fmo — ROW_NUMBER ASC on OUT tx (TxTypeID IN [1-4,6,8,13])
    → Step 3: #transactions — MIN/MAX dates by rail (IBAN, Card, All)
    → Step 4: #firstactions_general — top-5 settled tx (all types)
    → Step 5: #firstactions_iban — top-5 IBAN tx (TxTypeID IN [5,6,7,8])
    → Step 6: #firstactions_card — top-5 Card tx (TxTypeID IN [1,2,3,4])
    → Step 7: #final — JOIN all temp tables to eMoney_Dim_Account
    |-- SP_eMoney_Panel_FirstDates Step 8 (DELETE + INSERT, daily) ---|
    v
eMoney_dbo.eMoney_Panel_FirstDates (2,031,884 rows, HASH(CID) HEAP)
    |-- Generic Pipeline (Override, parquet, daily) ---|
    v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountID, GCID, CID, CardActivationTime | eMoney_Dim_Account | Grain source — one row per account (GCID_Unique_Count=1 filter); CardStatusTime/CardStatusID for card activation |
| FMI_Date, FMO_Date, all Action columns | eMoney_Dim_Transaction | All transaction event data — dates, types, amounts, status |

### 6.2 Referenced By

| Object | Schema | Usage |
|--------|--------|-------|
| SP_eMoney_Reports_Daily | eMoney_dbo | JOINs to Panel_FirstDates to derive IsFMI (FMI_Date IS NOT NULL), IsFMO (FMO_Date IS NOT NULL), IsCardFirstTx (FirstCardSettledTXDate IS NOT NULL) signals for eMoney_Reports_AcquisitionFunnel |
| eMoney_Reports_AcquisitionFunnel | eMoney_dbo | Downstream consumer of FMI/FMO/card signals via SP_eMoney_Reports_Daily |

---

## 7. Sample Queries

### Monthly FMI cohort size (last 24 months)

```sql
SELECT DATETRUNC(MONTH, FMI_Date) AS cohort_month,
       COUNT(*)                    AS funded_accounts
FROM [eMoney_dbo].[eMoney_Panel_FirstDates]
WHERE FMI_Date >= DATEADD(MONTH, -24, GETDATE())
GROUP BY DATETRUNC(MONTH, FMI_Date)
ORDER BY cohort_month;
```

### FMI-to-FMO conversion lag distribution

```sql
SELECT DATEDIFF(DAY, FMI_Date, FMO_Date) AS days_to_first_out,
       COUNT(*)                           AS accounts
FROM [eMoney_dbo].[eMoney_Panel_FirstDates]
WHERE FMI_Date IS NOT NULL
  AND FMO_Date IS NOT NULL
GROUP BY DATEDIFF(DAY, FMI_Date, FMO_Date)
ORDER BY days_to_first_out;
```

### Card adoption funnel

```sql
SELECT COUNT(*)                                          AS total_accounts,
       COUNT(FMI_Date)                                   AS funded,
       COUNT(CardActivationTime)                         AS card_activated,
       COUNT(Card1stActionDate)                          AS card_first_tx
FROM [eMoney_dbo].[eMoney_Panel_FirstDates];
```

### First-action type mix (what do accounts do first?)

```sql
SELECT [1stActionType],
       COUNT(*) AS accounts
FROM [eMoney_dbo].[eMoney_Panel_FirstDates]
WHERE [1stActionType] IS NOT NULL
GROUP BY [1stActionType]
ORDER BY accounts DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 13/14*
*Tiers: 3 T1, 62 T2, 0 T3, 0 T4, 0 T5 | Elements: 65/65, Logic: 9/10, Completeness: 9/10*
*Object: eMoney_dbo.eMoney_Panel_FirstDates | Type: Table | Production Sources: eMoney_Dim_Account, eMoney_Dim_Transaction*
