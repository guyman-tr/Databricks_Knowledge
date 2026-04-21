# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform

> 68M-row DDR MIMO fact for the Trading Platform — transaction-level deposits and withdrawals with multi-currency support, funding type, FTD/global-FTD flags, IBAN/recurring/C2F markers, and deduplication logic, feeding the DDR Money-In/Money-Out framework.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — DDR MIMO Trading Platform) |
| **Production Source** | Derived from `Fact_CustomerAction`, `Fact_BillingDeposit`, `Fact_BillingWithdraw`, `Dim_Currency`, `Dim_Customer`, `BI_DB_DepositWithdrawFee` via `SP_DDR_Fact_MIMO_Trading_Platform` |
| **Refresh** | Daily — `DELETE WHERE DateID = @dateID` + `INSERT` per business date |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_MIMO_Trading_Platform` stores **transaction-level Money-In / Money-Out** activity for eToro's **Trading Platform (TP)**. Each row represents a single deposit or withdrawal, identified by `DepositID` or `WithdrawPaymentID`, with both USD and original-currency amounts.

The table was created in July 2024 by Guy Manova for the DDR framework. It differs from the Options and eMoney MIMO tables by supporting **multi-currency** transactions, multiple **funding types**, and additional classification flags (`IsIBANTrade`, `IsCryptoToFiat`, `IsRecurring`, `IsIBANQuickTransfer`).

Key design decisions documented in the SP changelog:
- **ActionTypeID 44/45 included** (May 2025) — IBAN sweep deposits/withdrawals, fixing a design flaw that excluded them
- **IsIBANQuickTransfer** (MoveMoneyReasonID = 6) — identifies internal transfers that can create FTDs despite being FundingTypeID 33
- **Post-insert FTD recovery** — UPDATE sets IsFTD=1 for deposits matching `Dim_Customer.FTDTransactionID` where the FTD arrived late
- **Deduplication** via ROW_NUMBER — production bugs causing duplicate rows in source tables are cleaned up

**ETL**: `SP_DDR_Fact_MIMO_Trading_Platform` runs daily (Priority 60, SB_Daily). It deletes and reinserts rows for a single `@dateID`.

Data spans from 2007-08-27 to present with ~68M rows across ~5.9M distinct CIDs.

---

## 2. Business Logic

### 2.1 Deposit Logic

**What**: Captures all TP deposits from `Fact_CustomerAction` where ActionTypeID IN (7, 44).

**Columns Involved**: `AmountUSD`, `AmountOrigCurrency`, `FundingTypeID`, `CurrencyID`, `Currency`, `IsFTD`, `IsRecurring`, `IsIBANTrade`

**Rules**:
- ActionTypeID 7 = standard deposit; ActionTypeID 44 = IBAN sweep deposit
- `AmountUSD` = `Fact_CustomerAction.Amount` (always in USD)
- `AmountOrigCurrency` = `Fact_BillingDeposit.Amount` (original currency)
- `IsFTD` = 1 when `Dim_Customer.FTDTransactionID = DepositID` (for FTDPlatformID=1)
- `IsIBANTrade` = 1 when ActionTypeID = 44

### 2.2 Withdraw Logic

**What**: Captures all TP withdrawals from `Fact_CustomerAction` where ActionTypeID IN (8, 45).

**Columns Involved**: `AmountUSD`, `AmountOrigCurrency`, `FundingTypeID`, `CurrencyID`, `IsRedeem`, `IsIBANTrade`

**Rules**:
- ActionTypeID 8 = standard withdraw; ActionTypeID 45 = IBAN sweep withdraw
- `AmountOrigCurrency` = COALESCE(`BI_DB_DepositWithdrawFee.Amount`, ROUND(`Amount_WithdrawToFunding / ExchangeRate`))
- `IsFTD` = always 0 for withdrawals
- `IsRedeem` = from `Fact_CustomerAction.IsRedeem`
- `IsIBANTrade` = 1 when ActionTypeID = 45

### 2.3 Deduplication

**What**: Production bugs can cause duplicate rows. ROW_NUMBER partitioned by MIMOAction + TransactionID keeps only the first.

### 2.4 FTD Recovery Update

**What**: Post-insert UPDATE recovers FTDs not showing properly from Dim_Customer.

**Rules**:
- Matches deposits to `Dim_Customer.FTDTransactionID` where `FTDPlatformID = 1`
- Only updates rows with `IsFTD = 0` and `DateID >= 20250901`
- Required because Dim_Customer FTD data may arrive later than the transaction date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) with CLUSTERED COLUMNSTORE. Always filter on `DateID` for performance. Adding `MIMOAction` further narrows to deposits or withdrawals.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| TP deposits for a date | `WHERE DateID = @dateID AND MIMOAction = 'Deposit'` |
| FTD count by month | `WHERE IsFTD = 1 GROUP BY DateID / 100` |
| IBAN vs non-IBAN deposits | `GROUP BY IsIBANTrade` |
| Deposit volume by funding type | `JOIN Dim_FundingType ON FundingTypeID` |
| Recurring deposit analysis | `WHERE IsRecurring = 1 AND MIMOAction = 'Deposit'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID | Customer attributes |
| DWH_dbo.Dim_Date | DateID | Calendar dimension |
| DWH_dbo.Dim_FundingType | FundingTypeID | Funding type description |
| DWH_dbo.Dim_Currency | CurrencyID | Currency details |
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | — | Consolidated MIMO across all platforms |

### 3.4 Gotchas

- **AmountOrigCurrency can be negative** for withdrawals (preserves the original sign) while `AmountUSD` is always positive.
- **IsFTD may be updated post-insert**: The SP runs an UPDATE after INSERT to recover late-arriving FTDs. Queries during ETL may see IsFTD=0 temporarily.
- **IsCryptoToFiat always 0**: C2F is tracked separately; this column is a placeholder.
- **Deduplication**: The SP deduplicates using ROW_NUMBER, so the target table should not contain duplicates. However, source duplicates in `Fact_CustomerAction` were documented as a known issue.
- **IsInternalTransfer = 1 when FundingTypeID = 33**: These are IBAN-to-TP internal movements. Can create FTDs despite being "internal" (MoveMoneyReasonID = 6).
- **ActionTypeID 44/45 added May 2025**: Pre-May 2025 data does not include IBAN sweep deposits/withdrawals.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Business date as YYYYMMDD integer. CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). Delete/replace key. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 2 | Date | date | YES | Calendar date — equals parameter `@date`. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 3 | RealCID | int | YES | Real customer ID from Fact_CustomerAction.RealCID. HASH distribution key. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 4 | MIMOAction | varchar(20) | YES | Transaction direction. 'Deposit' for ActionTypeID 7/44, 'Withdraw' for 8/45. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 5 | OrigIdentifier | varchar(20) | YES | Source ID column name. 'DepositID' for deposits, 'WithdrawPaymentID' for withdrawals. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 6 | TransactionID | int | YES | Source transaction ID (DepositID or WithdrawPaymentID from Fact_CustomerAction). (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 7 | AmountUSD | decimal(16,6) | YES | Transaction amount in USD. From Fact_CustomerAction.Amount. Always positive. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 8 | AmountOrigCurrency | decimal(16,6) | YES | Transaction amount in original currency. Deposits: Fact_BillingDeposit.Amount. Withdrawals: COALESCE(BI_DB_DepositWithdrawFee.Amount, ROUND(Amount_WithdrawToFunding/ExchangeRate)). Can be negative for withdrawals. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 9 | FundingTypeID | int | YES | Funding type ID. From Fact_BillingDeposit.FundingTypeID (deposits) or Fact_BillingWithdraw.FundingTypeID_Funding (withdrawals). 33 = internal IBAN transfer. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 10 | CurrencyID | int | YES | Currency ID from Fact_BillingDeposit.CurrencyID (deposits) or Fact_BillingWithdraw.ProcessCurrencyID (withdrawals). (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 11 | Currency | varchar(20) | YES | Currency abbreviation from Dim_Currency.Abbreviation (e.g., USD, EUR, GBP). (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 12 | IsFTD | int | YES | First-time deposit on Trading Platform. 1 when Dim_Customer.FTDTransactionID = DepositID (FTDPlatformID=1). Post-insert UPDATE recovers late-arriving FTDs for DateID ≥ 20250901. (Tier 1 — Function_MIMO_First_Deposit_All_Platforms) |
| 13 | IsInternalTransfer | int | YES | Internal IBAN-to-TP transfer flag. CASE WHEN FundingTypeID = 33 THEN 1 ELSE 0. These can create FTDs via MoveMoneyReasonID=6. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 14 | IsRedeem | int | YES | Billing redeem flag. From Fact_CustomerAction.IsRedeem for withdrawals; always 0 for deposits. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 15 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() at insert time. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 16 | IsIBANTrade | int | YES | IBAN sweep transaction flag. 1 when ActionTypeID IN (44, 45). Added May 2025. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 17 | IsCryptoToFiat | int | YES | Crypto-to-fiat flag. Always 0 — C2F tracked separately. Placeholder column. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 18 | IsRecurring | int | YES | Recurring deposit flag. ISNULL(Fact_BillingDeposit.IsRecurring, 0) for deposits; 0 for withdrawals. Added May 2025. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 19 | IsIBANQuickTransfer | int | YES | Quick transfer from IBAN flag. CASE WHEN MoveMoneyReasonID = 6 THEN 1 ELSE 0. Internal transfers that can trigger FTDs. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column Group | Production Source | Key Columns | Transform |
|---------------------|-------------------|-------------|-----------|
| Transaction core (cols 1-8) | Fact_CustomerAction + Fact_BillingDeposit/Withdraw | DepositID, WithdrawPaymentID, Amount | passthrough + currency lookup |
| Classification flags (cols 9-14, 16-19) | Fact_CustomerAction + Fact_BillingDeposit + Dim_Customer | FundingTypeID, ActionTypeID, MoveMoneyReasonID, FTDTransactionID | CASE logic |
| ETL metadata (cols 15) | SP | GETDATE() | ETL-computed |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID 7,8,44,45 for @dateID)
  +
DWH_dbo.Fact_BillingDeposit (deposit details)
DWH_dbo.Fact_BillingWithdraw (withdraw details)
  +
DWH_dbo.Dim_Currency (abbreviation)
DWH_dbo.Dim_Customer (FTD match for platform 1)
BI_DB_dbo.BI_DB_DepositWithdrawFee (alternative withdraw amount)
  |
  └─ #depositsTP + #cashoutTP
       └─ UNION ALL → #mimoTP (dedup via ROW_NUMBER)
            |
            └─ SP_DDR_Fact_MIMO_Trading_Platform(@date) [Priority 60, SB_Daily]
                 |-- DELETE WHERE DateID = @dateID
                 |-- INSERT from #mimoTP
                 |-- UPDATE IsFTD recovery from Dim_Customer (≥20250901)
                 v
            BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform (68M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| DateID | DWH_dbo.Dim_Date | Calendar dimension |
| FundingTypeID | DWH_dbo.Dim_FundingType | Funding type lookup |
| CurrencyID | DWH_dbo.Dim_Currency | Currency details |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | — | Consolidated MIMO view includes TP |
| BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms | — | AllPlatforms SP reads from this table |

---

## 7. Sample Queries

### 7.1 TP deposit volume by funding type for a date

```sql
SELECT ft.FundingType, COUNT(*) AS Cnt, SUM(t.AmountUSD) AS TotalUSD
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform t
JOIN DWH_dbo.Dim_FundingType ft ON t.FundingTypeID = ft.FundingTypeID
WHERE t.DateID = 20260310 AND t.MIMOAction = 'Deposit'
GROUP BY ft.FundingType
ORDER BY TotalUSD DESC
```

### 7.2 FTD trend including IBAN sweeps

```sql
SELECT DateID / 100 AS YearMonth,
       COUNT(*) AS FTD_Count,
       SUM(AmountUSD) AS FTD_Volume
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform
WHERE IsFTD = 1
GROUP BY DateID / 100
ORDER BY YearMonth
```

### 7.3 IBAN quick transfers that triggered FTDs

```sql
SELECT DateID, RealCID, AmountUSD, Currency
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform
WHERE IsIBANQuickTransfer = 1 AND IsFTD = 1
ORDER BY DateID DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. The DDR framework is documented via SP headers and changelog entries by Guy Manova.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 12/14*
*Tiers: 1 T1, 18 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform | Type: Table | Production Source: SP_DDR_Fact_MIMO_Trading_Platform*
