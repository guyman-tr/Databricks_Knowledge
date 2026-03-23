# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms

> Unified daily Money-In/Money-Out transaction fact across all platforms (Trading Platform, eMoney, Options, MoneyFarm) — records every deposit and withdrawal with platform-specific and global first-time-deposit flags, feeding the DDR customer status aggregation.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — daily transactions) |
| **Production Source** | DWH-computed: UNION of TP MIMO + eMoney MIMO + Options + MoneyFarm |
| **Refresh** | Daily — DELETE for @dateID + INSERT (SP_DDR_Fact_Fact_MIMO_AllPlatforms @date) |
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

`BI_DB_DDR_Fact_MIMO_AllPlatforms` is the consolidated Money-In/Money-Out fact table that unifies deposit and withdrawal transactions from all eToro platforms into a single daily view per customer. "MIMO" = Money In, Money Out.

The table combines four platform sources:
- **Trading Platform (TP)**: Main eToro trading platform deposits/withdrawals
- **eMoney**: eToro's electronic money platform (IBAN-based transactions)
- **Options**: Options platform MIMO (best effort — data may not be reliably ready daily)
- **MoneyFarm**: MoneyFarm FTD-only data

Each transaction includes two FTD (First Time Deposit) indicators:
- **IsPlatformFTD**: Whether this is the first deposit on this specific platform
- **IsGlobalFTD**: Whether this is the customer's first deposit across ALL platforms (resolved via `Function_MIMO_First_Deposit_All_Platforms`)

Created: 2024-07-02 by Guy Manova. Heavily evolved through 2025 with additions for C2F, recurring, IBAN quick transfers, Options, MoneyFarm, and crypto-to-fiat indicators.

---

## 2. Business Logic

### 2.1 Platform Union

**What**: Combines MIMO transactions from 4 platforms into a single table.

**Rules**:
- TP and eMoney are the primary sources (reliable daily)
- Options is "best effort, no dependencies" — data may be delayed
- MoneyFarm is FTD-only data
- Each row gets a `MIMOPlatform` tag identifying its source

### 2.2 Global FTD Resolution

**What**: Determines if a deposit is the customer's first across all platforms.

**Columns Involved**: `IsGlobalFTD`, `IsPlatformFTD`

**Rules**:
- `IsGlobalFTD` is resolved via `Function_MIMO_First_Deposit_All_Platforms(0)`
- `IsPlatformFTD` indicates first deposit on the specific platform
- Post-load UPDATE recovers FTDs from `Dim_Customer` for cases where FTD data arrived after initial run

### 2.3 Crypto-to-Fiat

**What**: Identifies crypto-to-USD conversions on the trading platform.

**Columns Involved**: `IsCryptoToFiat`

**Rules**:
- `FundingTypeID = 27` on TP indicates crypto-to-USD conversion
- Applied to the whole population daily to avoid chasing history

### 2.4 IBAN Quick Transfer

**What**: Identifies eMoney internal transfers.

**Columns Involved**: `IsIBANQuickTransfer`

**Rules**:
- `MoneyMoveReason = 6` in eMoney — new feature called "Internal Transfer" in eMoney
- Named `IsIBANQuickTransfer` because "internal transfer" means something different on TP

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH(RealCID)**: Co-located with other DDR customer-level tables for efficient JOINs.

**CLUSTERED COLUMNSTORE INDEX**: Good for analytical scans over date ranges.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID | Customer details |
| DWH_dbo.Dim_Currency | ON CurrencyID | Currency name |
| DWH_dbo.Dim_Date | ON DateID | Calendar attributes |
| BI_DB_DDR_Customer_Daily_Status | ON RealCID, DateID | Daily panel enrichment |

### 3.3 Gotchas

- **Options data is unreliable**: Options platform MIMO is "best effort" — may not be present for every day.
- **Multiple rows per CID per day**: A customer can have multiple deposits/withdrawals on the same day across platforms.
- **Null merge keys replaced**: As of 2025-12-07, NULLs in merge key columns are replaced with sentinel values for lake compatibility.
- **IsGlobalFTD vs IsPlatformFTD**: These can differ — a customer's first eMoney deposit may not be their global FTD.
- **SP name has double "Fact"**: The writer SP is `SP_DDR_Fact_Fact_MIMO_AllPlatforms` (intentional naming).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| ★ | Tier 4 — Inferred | (Tier 4 — [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NULL | Transaction date as YYYYMMDD integer. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 2 | Date | date | NULL | Transaction date. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 3 | RealCID | int | NULL | Real customer ID. Distribution key. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 4 | MIMOAction | varchar(100) | NULL | Transaction type: Deposit or Withdraw. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 5 | OrigIdentifier | varchar(100) | NULL | Original transaction identifier from the source platform. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 6 | TransactionID | int | NULL | Transaction ID from the source system. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 7 | AmountUSD | decimal(16,6) | NULL | Transaction amount in USD. Positive for deposits, negative for withdrawals. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 8 | AmountOrigCurrency | decimal(16,6) | NULL | Transaction amount in the original currency. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 9 | FundingTypeID | int | NULL | Funding/payment method type. 27 = crypto-to-fiat on TP, 33 = eMoney deposit. (Tier 4 — [UNVERIFIED]) |
| 10 | CurrencyID | int | NULL | Currency dimension key. FK to Dim_Currency. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 11 | Currency | varchar(20) | NULL | Currency abbreviation (USD, EUR, GBP, etc.). (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 12 | IsPlatformFTD | int | NULL | 1 = first time deposit on this specific platform. 0 = not FTD on this platform. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 13 | IsInternalTransfer | int | NULL | 1 = internal transfer between platforms/accounts. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 14 | IsRedeem | int | NULL | 1 = redeem transaction (CopyFund/SmartPortfolio redemption). (Tier 4 — [UNVERIFIED]) |
| 15 | IsTradeFromIBAN | int | NULL | 1 = trade opened from IBAN balance. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 16 | MIMOPlatform | varchar(20) | NULL | Source platform identifier: TP, eMoney, Options, MoneyFarm. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 17 | IsGlobalFTD | int | NULL | 1 = first time deposit across ALL platforms. Resolved via Function_MIMO_First_Deposit_All_Platforms. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 18 | UpdateDate | datetime | NULL | ETL load timestamp — GETDATE(). (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 19 | IsCryptoToFiat | int | NULL | 1 = crypto-to-fiat conversion (FundingTypeID 27 on TP, TxType 14 on eMoney). Added 2025-03-17. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 20 | IsRecurring | int | NULL | 1 = recurring transaction. Added 2025-05-06. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 21 | IsIBANQuickTransfer | int | NULL | 1 = eMoney internal transfer (MoneyMoveReason = 6). Added 2025-06-16. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |

---

## 5. Lineage

### 5.1 Pipeline

```
TP MIMO + eMoney MIMO + Options + MoneyFarm
    │
    └─ SP_DDR_Fact_Fact_MIMO_AllPlatforms(@date)
        ├─ #ibans (FTD customers from Dim_Customer)
        ├─ #globalFTDs (Function_MIMO_First_Deposit_All_Platforms)
        ├─ UNION of all platform MIMO
        ├─ JOIN to #globalFTDs for IsGlobalFTD
        ├─ DELETE/INSERT
        └─ UPDATE: FTD recovery from Dim_Customer
```

---

## 6. Relationships

### 6.1 References To

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Customer | RealCID | Customer details, FTD recovery |
| DWH_dbo.Dim_Currency | CurrencyID | Currency name |

### 6.2 Referenced By

| Source Object | Usage |
|--------------|-------|
| SP_DDR_Customer_Daily_Status | Daily customer status aggregation |
| SP_MarketingCloudDaily | Marketing cloud daily feed |
| SP_RevenueForum | Revenue forum reporting |

---

## 7. Sample Queries

### 7.1 Daily MIMO by platform

```sql
SELECT  MIMOPlatform, MIMOAction,
        COUNT(*) AS TxCount,
        SUM(AmountUSD) AS TotalUSD
FROM    [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_AllPlatforms]
WHERE   DateID = 20260320
GROUP BY MIMOPlatform, MIMOAction
ORDER BY MIMOPlatform, MIMOAction;
```

### 7.2 Global FTDs by platform

```sql
SELECT  MIMOPlatform,
        COUNT(*) AS FTDCount,
        SUM(AmountUSD) AS FTDAmountUSD
FROM    [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_AllPlatforms]
WHERE   DateID = 20260320
  AND   IsGlobalFTD = 1
GROUP BY MIMOPlatform;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found specific to this table.

---

*Generated: 2026-03-22 | Quality: 8.0/10 (★★★★☆) | Phases: 12/14 (P2,P3 skipped — Synapse MCP unavailable)*
*Tiers: 0 T1, 18 T2, 0 T3, 3 T4 [UNVERIFIED] (FundingTypeID values, IsRedeem, MIMOAction domain), 0 T5 | Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | Type: Table | Source: DWH-computed (TP + eMoney + Options + MoneyFarm union)*
