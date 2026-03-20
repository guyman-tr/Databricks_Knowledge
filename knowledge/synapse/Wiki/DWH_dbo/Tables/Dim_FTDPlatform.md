# DWH_dbo.Dim_FTDPlatform

> Static lookup table mapping FTD platform type IDs (1-4) to the trading platform on which a customer made their First Time Deposit (TradingPlatform, Options, eMoney, MoneyFarm).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | MoneyBusDB.Dictionary.AccountTypes |
| **Refresh** | None (static - no active ETL, 4 rows manually loaded) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_FTDPlatform` is a 4-row reference table that classifies customers by the eToro sub-platform through which they made their **First Time Deposit (FTD)**. Each row maps a numeric platform ID to a human-readable platform name, enabling BI analysts to segment and report on acquisition by platform type.

The data originates from `MoneyBusDB.Dictionary.AccountTypes` on the `moneybus` production server. `MoneyBusDB` is the transaction ledger for eToro's eMoney and subsidiary platforms. The Generic Pipeline exports this table daily to `Bronze/MoneyBusDB/Dictionary/AccountTypes/`, where it is read by `BI_DB_dbo.External_MoneyBusDB_Dictionary_AccountTypes`. A companion BI_DB view (`BI_DB_dbo.V_Dim_FTDPlatform`) implements the same mapping via a CASE expression over that external table.

`DWH_dbo.Dim_FTDPlatform` itself has **no active ETL SP** writing to it. The 4 rows were loaded manually (one-time) and exactly match the CASE expression in `BI_DB_dbo.V_Dim_FTDPlatform`. The table is static and frozen. If `MoneyBusDB.Dictionary.AccountTypes` adds new account types in production, `Dim_FTDPlatform` will NOT auto-update - it requires a manual INSERT.

---

## 2. Business Logic

### 2.1 FTD Platform Classification

**What**: The 4 platform IDs represent distinct eToro sub-products, each with its own deposit mechanism and customer journey.

**Columns Involved**: `FTDPlatformID`, `FTDPlatformName`

**Rules**:
- `FTDPlatformID = 1` (TradingPlatform) - the main eToro CFD/stock trading platform, the primary acquisition channel
- `FTDPlatformID = 2` (Options) - eToro's options trading product
- `FTDPlatformID = 3` (eMoney) - eToro's eMoney wallet / payment product (EU regulated)
- `FTDPlatformID = 4` (MoneyFarm) - MoneyFarm investment/ISA product (UK subsidiary)
- Values 5+ are handled as 'NA' in `BI_DB_dbo.V_Dim_FTDPlatform` CASE expression but do NOT exist in this DWH table

**Diagram**:
```
Dim_Customer.FTDPlatformID -----> Dim_FTDPlatform.FTDPlatformID
                                           |
                              +------------+------------+--------+
                              |            |            |        |
                         1=TradingPlatform  2=Options  3=eMoney  4=MoneyFarm
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE with HEAP. With only 4 rows, all nodes hold an in-memory copy. No distribution-key filtering needed - any JOIN condition is optimal. HEAP is correct for a 4-row table; no clustered index overhead.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this will likely be a small managed Delta table with no partitioning. No partition pruning needed for a 4-row table. Broadcast join is implicit for this size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Segment customers by FTD platform | `LEFT JOIN DWH_dbo.Dim_FTDPlatform df ON dc.FTDPlatformID = df.FTDPlatformID` on Dim_Customer |
| Count first-time depositors by platform | `GROUP BY df.FTDPlatformName` after LEFT JOIN |
| Filter eMoney-only customers | `WHERE dc.FTDPlatformID = 3` (no join needed if name not required) |
| Report on MoneyFarm FTDs | `WHERE df.FTDPlatformName = 'MoneyFarm'` or `WHERE dc.FTDPlatformID = 4` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON dc.FTDPlatformID = df.FTDPlatformID` | Resolve FTD platform name for customer segmentation |

### 3.4 Gotchas

- **No active ETL** - this table is static. Production `MoneyBusDB.Dictionary.AccountTypes` changes will NOT propagate automatically to DWH.
- **No ID=0 placeholder** - unlike most DWH dimension tables, there is no FTDPlatformID=0 row. Dim_Customer rows with NULL FTDPlatformID (customers who never deposited) must use LEFT JOIN to avoid row loss.
- **BI_DB uses its own mapping** - `BI_DB_dbo.V_Dim_FTDPlatform` applies the same names via a CASE expression over the external table. If the two diverge due to a DWH update, analysts may see inconsistency between DWH and BI_DB reports.
- **AccountTypeId is the source field name** - in `CustomerFinanceDB.Customer.*` tables, this dimension is called `AccountTypeId`. It was renamed to `FTDPlatformID` in DWH.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★★ | Tier 2 | Synapse code (ETL SP / DDL) |
| ★★★ | Tier 3 | Live data sampling + DDL structure |
| ★ | Tier 4-Inferred | Column name inference - `[UNVERIFIED]` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FTDPlatformID | int | NO | Primary key. Numeric identifier for the eToro sub-platform on which a customer made their First Time Deposit. Values: 1=TradingPlatform, 2=Options, 3=eMoney, 4=MoneyFarm. Sourced from `MoneyBusDB.Dictionary.AccountTypes` as the account type identifier. In `CustomerFinanceDB`, this field is named `AccountTypeId`. (Tier 3 — live data sampling, MoneyBusDB.Dictionary.AccountTypes) |
| 2 | FTDPlatformName | varchar(50) | NO | Human-readable name of the FTD platform. Values observed: 'TradingPlatform', 'Options', 'eMoney', 'MoneyFarm'. Matches the CASE expression in `BI_DB_dbo.V_Dim_FTDPlatform`. Used by BI_DB SPs as the display/label value for FTD platform segmentation. (Tier 3 — live data sampling, MoneyBusDB.Dictionary.AccountTypes) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FTDPlatformID | MoneyBusDB.Dictionary.AccountTypes | FTDPlatformID | None (passthrough) |
| FTDPlatformName | MoneyBusDB.Dictionary.AccountTypes | Name | None (passthrough) |

No upstream wiki found for MoneyBusDB.Dictionary.AccountTypes.

### 5.2 ETL Pipeline

```
MoneyBusDB.Dictionary.AccountTypes -> Generic Pipeline (daily, Override)
  -> Bronze/MoneyBusDB/Dictionary/AccountTypes/
  -> BI_DB_dbo.External_MoneyBusDB_Dictionary_AccountTypes
  -> [BI_DB_dbo.V_Dim_FTDPlatform applies CASE rename]
  -> DWH_dbo.Dim_FTDPlatform (ONE-TIME MANUAL LOAD - no active ETL SP)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | MoneyBusDB.Dictionary.AccountTypes | Account type dictionary on moneybus production server |
| Lake | Bronze/MoneyBusDB/Dictionary/AccountTypes/ | Daily full-load export via Generic Pipeline |
| External | BI_DB_dbo.External_MoneyBusDB_Dictionary_AccountTypes | Synapse external table reading from lake path |
| View | BI_DB_dbo.V_Dim_FTDPlatform | CASE expression mapping IDs 1-4 to platform names |
| Target | DWH_dbo.Dim_FTDPlatform | Static 4-row lookup. No active ETL. One-time manual load. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| FTDPlatformID | MoneyBusDB.Dictionary.AccountTypes | Production source for the 4 platform type definitions |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | FTDPlatformID | JOIN to resolve the platform name for a customer's first deposit |
| BI_DB_dbo.SP_DDR_Customer_Daily_Status | FTDPlatformID | LEFT JOIN to include FTDPlatformName in daily DDR reporting |
| BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms | FTDPlatformID | JOIN for MIMO (Money In / Money Out) platform segmentation |
| BI_DB_dbo.Function_Population_First_Time_Funded | FTDPlatformID | JOIN for FTF population reporting |

---

## 7. Sample Queries

### 7.1 List all FTD platform types
```sql
SELECT FTDPlatformID, FTDPlatformName
FROM [DWH_dbo].[Dim_FTDPlatform]
ORDER BY FTDPlatformID;
```

### 7.2 Count first-time depositors by FTD platform
```sql
SELECT df.FTDPlatformName, COUNT(*) AS FTDCustomers
FROM [DWH_dbo].[Dim_Customer] dc
LEFT JOIN [DWH_dbo].[Dim_FTDPlatform] df
    ON dc.FTDPlatformID = df.FTDPlatformID
WHERE dc.IsDepositor = 1
GROUP BY df.FTDPlatformName
ORDER BY FTDCustomers DESC;
```

### 7.3 FTD breakdown including customers with no FTD platform (NULL)
```sql
SELECT
    COALESCE(df.FTDPlatformName, 'No FTD') AS Platform,
    COUNT(*) AS Customers,
    SUM(dc.FirstDepositAmount) AS TotalFTDAmount
FROM [DWH_dbo].[Dim_Customer] dc
LEFT JOIN [DWH_dbo].[Dim_FTDPlatform] df
    ON dc.FTDPlatformID = df.FTDPlatformID
GROUP BY COALESCE(df.FTDPlatformName, 'No FTD')
ORDER BY Customers DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.9/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 0 T2, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10*
*Object: DWH_dbo.Dim_FTDPlatform | Type: Table | Production Source: MoneyBusDB.Dictionary.AccountTypes*
