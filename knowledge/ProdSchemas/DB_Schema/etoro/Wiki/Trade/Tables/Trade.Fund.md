# Trade.Fund

> Master table for CopyFunds/SmartPortfolios defining each fund's account, owner, visibility, minimum investment, rebalance interval, and strategy type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | FundID (INT, CLUSTERED PK) |
| **Partition** | MAIN filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Trade.Fund is the master definition table for eToro's CopyFunds (later rebranded as SmartPortfolios) - thematic portfolios that investors can copy with a single minimum investment amount. Each row represents one fund: a named investment strategy that rebalances on a schedule and aggregates positions across multiple instruments or traders. The fund type (TopTraders, Partners, or Market) determines how the allocation is sourced: copying Popular Investors, following an external partner, or tracking a thematic index.

This table exists because the fund management system needs a single source of truth for fund metadata: which customer account holds the fund (FundAccountID), who manages it (FundOwnerID), whether it is publicly discoverable (IsPublic), the minimum investment (MinCopyAmount), how often it rebalances (RefreshIntervalMonths), and whether it holds crypto (HasCrypto). Without it, Trade.FundInterval and Trade.FundIntervalAllocation would have no parent, and procedures like Trade.GetFundInfo and Trade.Job_GenerateFundAllocation could not resolve fund configuration.

Data flows through this object as follows: Trade.Job_GenerateFundAllocation creates new rows when BackOffice.Customer has AccountTypeID=9 (fund) but no Trade.Fund exists for that owner - it INSERTs with UserName as FundName, CID as FundAccountID and FundOwnerID, IsPublic=1, MinCopyAmount=5000, RefreshIntervalMonths=1, FundType=3 (Market). Trade.GetFundMetaData, Trade.GetFundInfo, and Trade.GetFundCidsBulk read fund metadata for API and bulk operations. Trade.FundInterval stores time intervals per fund; Trade.DeleteFundAllocationBacktestData and Trade.FundBacktestDataDelete clean up backtest data by FundID. Legacy note: prior to FB 45530 (2017), "is user a fund?" was checked via Trade.Fund; it is now resolved via BackOffice.Customer (AccountTypeID=9).

---

## 2. Business Logic

### 2.1 Fund Account vs Owner

**What**: Distinction between the fund's trading account and the entity that owns/manages the fund.

**Columns/Parameters Involved**: `FundAccountID`, `FundOwnerID`

**Rules**:
- FundAccountID and FundOwnerID both reference Customer.CustomerStatic.CID. In current data (Job_GenerateFundAllocation) they are set to the same CID when a fund is auto-created. The design allows for future separation (e.g., a fund managed by one entity but held in a different account).
- FundAccountID is the account that holds the fund's positions and is used for fee exclusion (Trade.ExcludeFeeByFundID conceptually excludes fund CIDs from fee processing).
- Confluence (DCS-627): "To check if a CID is a fund: Check if the CID is in the column FundAccountID in Trade.Fund table."

### 2.2 Fund Type and Rebalance Schedule

**What**: Fund strategy category drives allocation logic; RefreshIntervalMonths drives interval creation.

**Columns/Parameters Involved**: `FundType`, `RefreshIntervalMonths`, `MinCopyAmount`

**Rules**:
- FundType: 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). NULL allowed - older funds may not have been classified.
- RefreshIntervalMonths: Used by Job_GenerateFundAllocation to create Trade.FundInterval rows. Each interval spans this many months. Example: 1 = monthly, 2 = bimonthly.
- MinCopyAmount: Minimum investment in account currency for copying into this fund. Enforced by application layer.

**Diagram**:
```
Trade.Fund
    |
    +-> FundType (Dictionary.FundType): 1=TopTraders, 2=Partners, 3=Market
    |
    +-> RefreshIntervalMonths -> Trade.FundInterval.PlannedEnd = add months to PlannedStart
```

---

## 3. Data Overview

| FundID | FundName | FundAccountID | FundType | HasCrypto | Meaning |
|---|---|---|---|---|---|
| 1 | BitcoinWorldWide | 341479 | NULL | 1 | Early fund (FundType NULL) with crypto. MinCopyAmount 1000, monthly refresh. Demonstrates legacy rows before FundType was mandatory. |
| 2 | Automation107 | 3739187 | 1 | 1 | TopTraders fund (copy-based). Bimonthly refresh, MinCopyAmount 100. Automation/test fund. |
| 3 | CopyTradingElno25062 | 6620828 | 3 | 1 | Market (thematic index) fund. Bimonthly refresh. Copy-prefix suggests copy-trading origin. |
| 12 | Automation118 | 3739195 | 2 | 1 | Partners fund (external strategist). Different strategy from Automation107. |
| 15 | CopyMyPort93 | 24487959 | 3 | 0 | Market fund with HasCrypto=0. Only fund in sample excluding crypto from its mandate. |

**Selection criteria for the 5 rows:**
- Rows show all three FundType values (1, 2, 3) plus NULL
- HasCrypto true and false represented
- Mix of test/automation names and production-style names

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate identifier for the fund. Referenced by Trade.FundInterval, Trade.FundIntervalAllocation, and fee/backtest procedures. |
| 2 | FundName | nvarchar(255) | NO | - | CODE-BACKED | Display name of the fund. Set from Customer.CustomerStatic.UserName when Job_GenerateFundAllocation creates a fund. Shown in fund details and API responses. |
| 3 | FundAccountID | int | NO | - | CODE-BACKED | FK to Customer.CustomerStatic.CID. The customer account that holds the fund's positions. Used to check "is CID a fund?" (Confluence DCS-627). Join key for GetFundMetaData, GetFundCidsBulk. |
| 4 | FundOwnerID | int | NO | - | CODE-BACKED | FK to Customer.CustomerStatic.CID. The entity that owns/manages the fund. Job_GenerateFundAllocation looks up FundID by FundOwnerID; when null, creates new fund. Typically equals FundAccountID at creation. |
| 5 | IsPublic | bit | NO | - | CODE-BACKED | 1 = fund is publicly discoverable; 0 = private. Returned by GetFundMetaData. Controls visibility in fund listing and copy flows. |
| 6 | MinCopyAmount | money | NO | - | CODE-BACKED | Minimum investment amount (in account currency) required to copy into this fund. Job_GenerateFundAllocation uses 5000 for new funds; sample data shows 100-5000. Enforced by application. |
| 7 | RefreshIntervalMonths | int | NO | - | CODE-BACKED | Rebalance interval in months. Job_GenerateFundAllocation uses this to compute Trade.FundInterval.PlannedEnd: adds this many months to PlannedStart. Sample: 1=monthly, 2=bimonthly, 3=quarterly. |
| 8 | CreateDate | datetime | NO | getdate() | CODE-BACKED | When the fund row was created. Set by default. |
| 9 | LastUpdateDate | datetime | NO | - | CODE-BACKED | Last modification timestamp. Updated by application or procedures when fund config changes. |
| 10 | FundType | int | YES | - | VERIFIED | FK to Dictionary.FundType.FundTypeID. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). NULL for older funds. See Dictionary.FundType. |
| 11 | HasCrypto | bit | NO | 1 | CODE-BACKED | 1 = fund may hold crypto instruments; 0 = fund excludes crypto. Default 1. Returned by GetFundMetaData. Used for instrument filtering and risk rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundAccountID | Customer.CustomerStatic | FK | The customer account holding the fund |
| FundOwnerID | Customer.CustomerStatic | FK | The entity owning/managing the fund |
| FundType | Dictionary.FundType | FK | Strategy category: TopTraders, Partners, or Market |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FundInterval | FundID | FK | Each fund has time intervals for allocation periods |
| Trade.FundIntervalAllocation | (via FundInterval) | Implicit | Allocations belong to intervals belonging to funds |
| Trade.GetFundMetaData | - | Read | Returns fund metadata by FundAccountID |
| Trade.GetFundInfo | - | Read | Returns fund metadata + intervals + allocations |
| Trade.GetFundCidsBulk | - | Read | Resolves FundAccountID, FundID for batch of CIDs |
| Trade.Job_GenerateFundAllocation | - | Writer | Creates funds and intervals for BackOffice fund owners |
| Trade.DeleteFundAllocationBacktestData | - | Read | Joins via FundID for cleanup |
| Trade.FundBacktestDataDelete | FundID param | Read | Deletes backtest data by FundID |
| Trade.GetMirrorHierarchyExcludeOpenedPositions | FundID | JOIN | Flags IsFundCopy when fund exists |
| Trade.GetMirrorHierarchyIncludeOpenedPositions | FundID | JOIN | Same as above |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Fund (table)
```
Tables have no code-level dependencies. FK targets (Customer.CustomerStatic, Dictionary.FundType) are structural dependencies only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target for FundAccountID, FundOwnerID |
| Dictionary.FundType | Table | FK target for FundType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FundInterval | Table | FK from FundID |
| Trade.GetFundMetaData | Procedure | Reads by FundAccountID |
| Trade.GetFundInfo | Procedure | Reads and JOINs to FundInterval |
| Trade.GetFundCidsBulk | Procedure | Reads FundAccountID, FundID |
| Trade.Job_GenerateFundAllocation | Procedure | Reads by FundOwnerID; INSERTs new rows |
| Trade.DeleteFundAllocationBacktestData | Procedure | JOINs for cleanup |
| Trade.FundBacktestDataDelete | Procedure | Uses FundID parameter |
| Trade.GetMirrorHierarchyExcludeOpenedPositions | Procedure | LEFT JOIN for IsFundCopy |
| Trade.GetMirrorHierarchyIncludeOpenedPositions | Procedure | LEFT JOIN for IsFundCopy |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeFund | CLUSTERED PK | FundID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeFund | PRIMARY KEY | Unique FundID |
| DF_TradeFund_CreateDate | DEFAULT | CreateDate = getdate() |
| df_HasCrypto | DEFAULT | HasCrypto = 1 |
| FK_TF_FundAccountID | FOREIGN KEY | FundAccountID -> Customer.CustomerStatic.CID |
| FK_TF_FundOwnerID | FOREIGN KEY | FundOwnerID -> Customer.CustomerStatic.CID |
| FK_TradFundFundType_DictionaryFundType | FOREIGN KEY | FundType -> Dictionary.FundType.FundTypeID |

---

## 8. Sample Queries

### 8.1 Get fund metadata by account
```sql
SELECT  FundName,
        FundAccountID,
        IsPublic,
        HasCrypto,
        MinCopyAmount,
        RefreshIntervalMonths
FROM    Trade.Fund WITH (NOLOCK)
WHERE   FundAccountID = 341479;
```

### 8.2 List all funds with fund type description
```sql
SELECT  f.FundID,
        f.FundName,
        f.FundAccountID,
        ft.Description AS FundTypeName,
        f.MinCopyAmount,
        f.RefreshIntervalMonths,
        f.HasCrypto
FROM    Trade.Fund f WITH (NOLOCK)
LEFT JOIN Dictionary.FundType ft WITH (NOLOCK) ON f.FundType = ft.FundTypeID
ORDER BY f.FundID;
```

### 8.3 Check if a CID is a fund account
```sql
SELECT  CASE WHEN EXISTS (
            SELECT 1 FROM Trade.Fund WITH (NOLOCK) WHERE FundAccountID = @CID
        ) THEN 1 ELSE 0 END AS IsFund;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [DCS-627: Spike Findings - Include Backtested Results in Smart Portfolios Returns](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13583450136) | Confluence | To check if a CID is a fund: Check if the CID is in FundAccountID in Trade.Fund. Fund.MonthlyGain contains monthly backtest data for Smart Portfolios. IsFund function in FundIdsProvider (user-stats-api) as reference. |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Fund | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Fund.sql*
