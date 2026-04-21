# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform

> 99K-row DDR MIMO fact for the Options (Apex) platform — transaction-level deposits and withdrawals from US options accounts, with first-time-deposit and global-FTD flags, feeding the DDR Money-In/Money-Out framework.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — DDR MIMO Options) |
| **Production Source** | `Function_MIMO_Options_Platform` → `External_Sodreconciliation_apex_EXT869_CashActivity`, `Dim_Customer`, `Fact_SnapshotCustomer` via `SP_DDR_Fact_MIMO_Options_Platform` |
| **Refresh** | Daily — TRUNCATE + full reload from function |
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

`BI_DB_DDR_Fact_MIMO_Options_Platform` stores transaction-level **Money-In / Money-Out** activity for eToro's **Options (Apex/Gatsby)** platform. Each row represents a single deposit or withdrawal on a US options account, identified by the Apex transaction ID (`TransactionID`), with the amount always in USD.

The data originates from Apex's cash activity feed (`External_Sodreconciliation_apex_EXT869_CashActivity`), mapped to eToro customer IDs via `External_USABroker_Apex_Options` → `Dim_Customer`. The table is part of the DDR MIMO family alongside `BI_DB_DDR_Fact_MIMO_AllPlatforms` (consolidated) and platform-specific tables for Trading Platform and eMoney.

**ETL**: `SP_DDR_Fact_MIMO_Options_Platform` runs daily (Priority 0, SB_Daily). It TRUNCATEs the table and reloads the full history from `Function_MIMO_Options_Platform(20000101, today, 0)`. No date-scoped incremental load — full rebuild every day.

Data spans from 2022-10-31 to present with ~99K rows across ~13K distinct customers.

---

## 2. Business Logic

### 2.1 MIMO Action Classification

**What**: Cash movements classified as Deposit or Withdraw.

**Columns Involved**: `MIMOAction`, `AmountUSD`

**Rules** (from Function_MIMO_Options_Platform):
- PayTypeCode 'C' → 'Deposit'
- PayTypeCode 'D' → 'Withdraw'
- Amount = ABS(original amount); always positive
- Filters: OfficeCode IN ('4GS', '5GU'), excludes house accounts (4GS43999, 4GS00100-104)
- Only ACH/WRD entries OR TerminalID='OMJNL' (internal journal transfers)

### 2.2 First-Time Deposit Flags

**What**: Marks the first deposit on the Options platform and the first deposit across all eToro platforms.

**Columns Involved**: `IsFTD`, `IsGlobalFTD`

**Rules**:
- `IsFTD`: 1 if this transaction is the first deposit on Options for this customer (from CTE FinalFTD logic in function)
- `IsGlobalFTD`: 1 if this is the customer's first deposit across ALL platforms (cross-references Dim_Customer first-deposit data for platform 2)

### 2.3 Hardcoded Options Constants

**What**: Options platform uses only USD and has no funding type concept.

**Columns Involved**: `OrigIdentifier`, `FundingTypeID`, `CurrencyID`, `Currency`, `AmountOrigCurrency`

**Rules**:
- `OrigIdentifier` = 'ApexTxID' (constant)
- `FundingTypeID` = 0 (no funding type for Options)
- `CurrencyID` = 1, `Currency` = 'USD' (Options is USD-only)
- `AmountOrigCurrency` = `AmountUSD` (same value)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) with CLUSTERED COLUMNSTORE. Small table (~99K rows) — full scans are fast. Always filter on `DateID` for period queries and `MIMOAction` for deposit/withdraw splits.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Options deposits for a date | `WHERE DateID = @dateID AND MIMOAction = 'Deposit'` |
| Options FTD count by month | `WHERE IsFTD = 1 GROUP BY DateID / 100` |
| Total Options MIMO volume | `SELECT SUM(AmountUSD) WHERE DateID BETWEEN @start AND @end` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID | Customer attributes |
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | — | Consolidated MIMO across all platforms |
| DWH_dbo.Dim_Date | DateID | Calendar dimension |

### 3.4 Gotchas

- **TRUNCATE + full reload**: Table is fully rebuilt daily. Do not assume incremental appends.
- **All amounts are USD**: `AmountOrigCurrency` = `AmountUSD` always. No currency conversion needed.
- **FundingTypeID is always 0**: Not meaningful for this platform — Options has no funding type concept.
- **IsInternalTransfer**: 1 when TerminalID = 'OMJNL' (journal entry). These are internal transfers, not customer-initiated deposits.
- **House account exclusions hardcoded**: Accounts 4GS43999, 4GS00100-104 are excluded in the function.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP/function code | (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Business date as YYYYMMDD integer. CONVERT(nvarchar(8), ProcessDate, 112) from Apex cash activity. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 2 | Date | date | YES | Calendar date. CONVERT(date, ProcessDate) from Apex cash activity. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 3 | RealCID | int | YES | Real customer ID. Mapped via Options GCID → External_USABroker_Apex_Options → Dim_Customer.RealCID. HASH distribution key. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 4 | MIMOAction | varchar(20) | YES | Transaction direction. CASE WHEN PayTypeCode='C' THEN 'Deposit' WHEN 'D' THEN 'Withdraw' END. From Function_MIMO_Options_Platform. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 5 | OrigIdentifier | varchar(20) | YES | Transaction source identifier. Hardcoded 'ApexTxID' for all Options transactions. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 6 | TransactionID | varchar(50) | YES | Apex transaction ID (ACATSControlNumber from External_Sodreconciliation_apex_EXT869_CashActivity). (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 7 | AmountUSD | decimal(16,6) | YES | Transaction amount in USD. ABS(Amount) from Apex cash activity. Filtered by OfficeCode IN ('4GS','5GU'), excl house accounts, EnteredBy IN ('ACH','WRD') OR TerminalID='OMJNL'. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 8 | AmountOrigCurrency | decimal(16,6) | YES | Transaction amount in original currency. Always equals AmountUSD — Options platform is USD-only. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 9 | FundingTypeID | int | YES | Funding type identifier. Hardcoded 0 — Options platform has no funding type concept. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 10 | CurrencyID | int | YES | Currency identifier. Hardcoded 1 (USD). Options platform uses USD only. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 11 | Currency | varchar(20) | YES | Currency code. Hardcoded 'USD'. Options platform uses USD only. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 12 | IsFTD | int | YES | First-time deposit on Options platform. 1 if this is the customer's first Options deposit (FinalFTD CTE match in function). (Tier 1 — Function_MIMO_First_Deposit_All_Platforms) |
| 13 | IsGlobalFTD | int | YES | Global first-time deposit across all eToro platforms. 1 if this is the customer's first deposit on ANY platform, cross-referencing Dim_Customer first-deposit data for platform 2. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 14 | IsInternalTransfer | int | YES | Internal transfer flag. CASE WHEN TerminalID='OMJNL' THEN 1 ELSE 0. Journal entries, not customer-initiated. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 15 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() at insert time. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateID, Date | External_Sodreconciliation_apex_EXT869_CashActivity | ProcessDate | CONVERT |
| RealCID | Dim_Customer | RealCID | Via Options GCID mapping |
| MIMOAction | External_Sodreconciliation_apex_EXT869_CashActivity | PayTypeCode | CASE mapping |
| AmountUSD | External_Sodreconciliation_apex_EXT869_CashActivity | Amount | ABS with filters |
| TransactionID | External_Sodreconciliation_apex_EXT869_CashActivity | ACATSControlNumber | passthrough |
| IsFTD, IsGlobalFTD | Function FTD logic | Multiple | CTE computation |

### 5.2 ETL Pipeline

```
External_Sodreconciliation_apex_EXT869_CashActivity (Apex cash feed)
  +
External_USABroker_Apex_Options (GCID → Options account mapping)
  +
DWH_dbo.Dim_Customer (RealCID, FTD dates)
  +
DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer)
  |
  └─ Function_MIMO_Options_Platform(20000101, today, 0)
       |
       └─ SP_DDR_Fact_MIMO_Options_Platform [Priority 0, SB_Daily]
            |-- TRUNCATE TABLE
            |-- INSERT full history
            v
       BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform (99K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| DateID | DWH_dbo.Dim_Date | Calendar dimension |
| FundingTypeID | DWH_dbo.Dim_FundingType | Always 0 for Options |
| CurrencyID | DWH_dbo.Dim_Currency | Always 1 (USD) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | — | Consolidated MIMO view includes Options |
| BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms | — | AllPlatforms SP reads from this table |

---

## 7. Sample Queries

### 7.1 Options deposit volume by month

```sql
SELECT DateID / 100 AS YearMonth,
       COUNT(*) AS Transactions,
       SUM(AmountUSD) AS TotalDeposits
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform
WHERE MIMOAction = 'Deposit'
GROUP BY DateID / 100
ORDER BY YearMonth
```

### 7.2 First-time depositors on Options platform

```sql
SELECT DateID, RealCID, AmountUSD
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform
WHERE IsFTD = 1
ORDER BY DateID DESC
```

### 7.3 Internal transfers vs customer deposits

```sql
SELECT MIMOAction,
       IsInternalTransfer,
       COUNT(*) AS Cnt,
       SUM(AmountUSD) AS TotalAmount
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform
WHERE DateID BETWEEN 20260101 AND 20260309
GROUP BY MIMOAction, IsInternalTransfer
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.0/10 (★★★★☆) | Phases: 11/14*
*Tiers: 1 T1, 14 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform | Type: Table | Production Source: SP_DDR_Fact_MIMO_Options_Platform*
