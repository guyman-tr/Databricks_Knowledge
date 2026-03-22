# DWH_dbo.Dim_Fund

> eToro Smart Portfolio (Fund) dimension - maps Fund IDs to fund metadata including name, account, owner, public visibility, minimum copy amount, refresh schedule, and fund type.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.Fund |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (FundID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fund` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Fund` is a dimension table of eToro Smart Portfolios (internally called Funds). Each row represents one managed investment fund, identified by a `FundID`, with its associated account (`FundAccountID`), owner (`FundOwnerID`), public visibility flag (`IsPublic`), minimum copy investment amount (`MinCopyAmount`), quarterly/annual refresh schedule (`RefreshIntervalMonths`), and fund category (`FundType`).

As of 2026-03-11, the table contains **877 funds**, nearly all of which are public (876 of 877). The vast majority are categorized as FundType=3 (Market), with smaller counts of FundType=1 (TopTraders, 38 funds) and FundType=2 (Partners, 44 funds).

`FundType` values are decoded by `DWH_dbo.Dim_FundType`:
- 1 = TopTraders (curated expert trader portfolios)
- 2 = Partners (partner/affiliate-managed portfolios)
- 3 = Market (market/thematic portfolios - the dominant type)

The data originates from `etoro.Trade.Fund` on the etoroDB-REAL production server via `DWH_staging.etoro_Trade_Fund`. The staging table includes 3 additional columns (`CreateDate`, `LastUpdateDate`, `HasCrypto`) that the ETL intentionally drops.

---

## 2. Business Logic

### 2.1 Fund Type Classification

**What**: Funds are classified into three types based on their portfolio curation model.

**Columns Involved**: `FundType`

**Rules**:
- FundType = 1 (TopTraders): Portfolios curated from eToro's top-performing copy traders
- FundType = 2 (Partners): Portfolios managed by eToro partner organizations or affiliates
- FundType = 3 (Market): Thematic or sector-based market portfolios (e.g., "BigTech", "AllStocks", "GoldenEnergy")

**Distribution** (as of 2026-03-11):
```
FundType 1 (TopTraders): 38 funds  (4.3%)
FundType 2 (Partners):   44 funds  (5.0%)
FundType 3 (Market):    795 funds  (90.6%)
```

### 2.2 Minimum Copy Amount

**What**: `MinCopyAmount` defines the minimum investment required to copy a fund. Values observed are 500.0000 and 5000.0000 (USD equivalent).

**Columns Involved**: `MinCopyAmount`

**Rules**:
- money data type - represents a USD-denominated threshold
- Range observed: $500 to $5,000

### 2.3 Refresh Schedule

**What**: `RefreshIntervalMonths` defines how often the fund portfolio is rebalanced/refreshed.

**Columns Involved**: `RefreshIntervalMonths`

**Rules**:
- Range observed: 1 to 12 months
- Common values likely 3 (quarterly) and 12 (annual) based on data pattern (all sample rows = 3)

### 2.4 Dropped Staging Columns

**What**: Three staging columns are intentionally excluded from the DWH dimension.

**Rules**:
- `CreateDate` (datetime2): Fund creation timestamp - excluded from DWH Dim_Fund
- `LastUpdateDate` (datetime2): Last source update timestamp - excluded (UpdateDate is ETL load time)
- `HasCrypto` (bit): Whether the fund contains crypto assets - excluded from DWH

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (appropriate for 877-row dimension). CLUSTERED INDEX on FundID enables efficient point lookups. Joins from large fact tables incur no data movement.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 877 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FundID to fund name | `LEFT JOIN DWH_dbo.Dim_Fund ON FundID` |
| Get fund with its type name | `JOIN Dim_Fund f JOIN Dim_FundType ft ON f.FundType = ft.FundTypeID` |
| Find market/thematic funds | `WHERE FundType = 3` |
| Find all public funds | `WHERE IsPublic = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_FundType | ON FundType = FundTypeID | Decode fund category to name |
| (No active fact FK consumers) | FundID | FundID not used as FK in current DWH SSDT repo |

### 3.4 Gotchas

- **FundAccountID = FundOwnerID**: In sample data, FundAccountID and FundOwnerID hold identical values. This may mean the fund account IS the owner account (a single eToro account both owns and trades the fund). Verify before using one vs the other.
- **Dropped staging columns**: `CreateDate`, `LastUpdateDate`, and `HasCrypto` from the source are not available in DWH. Query staging table directly if these are needed.
- **FundType is nullable**: Despite the fund type being important for analysis, `FundType` is defined as NULL in the DDL. In practice, all 877 rows have a value - but NULL-safe joins are advisable.
- **UpdateDate is NOT NULL**: Unusual; set to GETDATE() each SP run (ETL timestamp, not the source LastUpdateDate).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|------------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundID | int | NO | Primary key. Surrogate identifier for the fund. Referenced by Trade.FundInterval, Trade.FundIntervalAllocation, and fee/backtest procedures. (Tier 1 — Trade.Fund) |
| 2 | FundName | nvarchar(255) | NO | Display name of the fund. Set from Customer.CustomerStatic.UserName when Job_GenerateFundAllocation creates a fund. Shown in fund details and API responses. (Tier 1 — Trade.Fund) |
| 3 | FundAccountID | int | NO | FK to Customer.CustomerStatic.CID. The customer account that holds the fund's positions. Used to check 'is CID a fund?' (Confluence DCS-627). Join key for GetFundMetaData, GetFundCidsBulk. (Tier 1 — Trade.Fund) |
| 4 | FundOwnerID | int | NO | FK to Customer.CustomerStatic.CID. The entity that owns/manages the fund. Job_GenerateFundAllocation looks up FundID by FundOwnerID; when null, creates new fund. Typically equals FundAccountID at creation. (Tier 1 — Trade.Fund) |
| 5 | IsPublic | bit | NO | 1 = fund is publicly discoverable; 0 = private. Returned by GetFundMetaData. Controls visibility in fund listing and copy flows. (Tier 1 — Trade.Fund) |
| 6 | MinCopyAmount | money | NO | Minimum investment amount (in account currency) required to copy into this fund. Job_GenerateFundAllocation uses 5000 for new funds; sample data shows 100-5000. Enforced by application. (Tier 1 — Trade.Fund) |
| 7 | RefreshIntervalMonths | int | NO | Rebalance interval in months. Job_GenerateFundAllocation uses this to compute Trade.FundInterval.PlannedEnd: adds this many months to PlannedStart. Sample: 1=monthly, 2=bimonthly, 3=quarterly. (Tier 1 — Trade.Fund) |
| 8 | FundType | int | YES | FK to Dictionary.FundType.FundTypeID. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). NULL for older funds. See Dictionary.FundType. (Tier 1 — Trade.Fund) |
| 9 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT the source LastUpdateDate. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FundID | etoro.Trade.Fund | FundID | passthrough |
| FundName | etoro.Trade.Fund | FundName | passthrough |
| FundAccountID | etoro.Trade.Fund | FundAccountID | passthrough |
| FundOwnerID | etoro.Trade.Fund | FundOwnerID | passthrough |
| IsPublic | etoro.Trade.Fund | IsPublic | passthrough |
| MinCopyAmount | etoro.Trade.Fund | MinCopyAmount | passthrough (decimal(38,18) -> money) |
| RefreshIntervalMonths | etoro.Trade.Fund | RefreshIntervalMonths | passthrough |
| FundType | etoro.Trade.Fund | FundType | passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| (dropped) | etoro.Trade.Fund | CreateDate | not loaded |
| (dropped) | etoro.Trade.Fund | LastUpdateDate | not loaded |
| (dropped) | etoro.Trade.Fund | HasCrypto | not loaded |

### 5.2 ETL Pipeline

```
etoro.Trade.Fund -> Generic Pipeline -> DWH_staging.etoro_Trade_Fund -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) -> DWH_dbo.Dim_Fund
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Trade.Fund | Fund entity table on etoroDB-REAL |
| Lake | Bronze/etoro/Trade/Fund/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Trade_Fund | Raw import (11 cols, ROUND_ROBIN, HEAP) |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT (~line 646). Drops CreateDate, LastUpdateDate, HasCrypto. Adds UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_Fund | 877-row REPLICATE/CLUSTERED fund dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| FundType | DWH_dbo.Dim_FundType | FK to fund type dimension (1=TopTraders, 2=Partners, 3=Market) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (None active) | FundID | No active FK references in current DWH SSDT repo |

---

## 7. Sample Queries

### 7.1 All funds with type name

```sql
SELECT f.FundID, f.FundName, ft.FundTypeName, f.IsPublic, f.MinCopyAmount
FROM DWH_dbo.Dim_Fund f
LEFT JOIN DWH_dbo.Dim_FundType ft ON f.FundType = ft.FundTypeID
ORDER BY f.FundType, f.FundName
```

### 7.2 Fund type distribution

```sql
SELECT ft.FundTypeName, COUNT(*) AS FundCount
FROM DWH_dbo.Dim_Fund f
JOIN DWH_dbo.Dim_FundType ft ON f.FundType = ft.FundTypeID
GROUP BY ft.FundTypeName
ORDER BY FundCount DESC
```

### 7.3 Funds by minimum copy amount threshold

```sql
SELECT MinCopyAmount, COUNT(*) AS FundCount
FROM DWH_dbo.Dim_Fund
GROUP BY MinCopyAmount
ORDER BY MinCopyAmount
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 8 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 7/10, Relationships: 6/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Fund | Type: Table | Production Source: etoro.Trade.Fund*
