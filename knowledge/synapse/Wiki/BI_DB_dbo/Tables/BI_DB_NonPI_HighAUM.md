# BI_DB_dbo.BI_DB_NonPI_HighAUM

> 72-row tiny reference table identifying non-Popular Investor CopyTrader parents with AUM > $15,000 who have active copiers. Daily TRUNCATE+INSERT full refresh via `SP_NonPI_HighAUM`. Flags high-leverage crypto positions for risk monitoring. Source: `general.etoroGeneral_History_GuruCopiers` + DWH dimensions.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `SP_NonPI_HighAUM` (no parameters) sourcing from `general.etoroGeneral_History_GuruCopiers` |
| **Refresh** | Daily -- TRUNCATE + INSERT (full rebuild) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CI(ParentCID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |

---

## 1. Business Meaning

`BI_DB_NonPI_HighAUM` is a 72-row risk monitoring table that identifies non-Popular Investor CopyTrader parents with significant Assets Under Management (> $15,000) who have at least one active copier. Each row represents one qualifying parent account, enriched with copier count, player status, account manager, region, and a count of high-leverage crypto positions.

The table is rebuilt daily by `SP_NonPI_HighAUM` (no parameters). The SP pulls yesterday's copy relationships from `general.etoroGeneral_History_GuruCopiers` (Timestamp = yesterday), filters to non-PI parents (GuruStatusID IN (0,1) or NULL), excludes blocked/invalid accounts, calculates AUM as SUM(Cash + Investment + PnL), and keeps only parents with AUM > $15,000. It then enriches each parent with customer attributes from DWH dimensions and counts high-leverage crypto positions (InstrumentTypeID=10, Leverage>1) from `Dim_Position`.

**Changed by**: Ofir Chloe Gal (2023-01-16, external table migration), Adi Ferber (2024-01-21, TRUNCATE pattern).

---

## 2. Business Logic

### 2.1 Non-PI Parent Identification

**What**: Filters CopyTrader parents to only those who are NOT Popular Investors.

**Columns Involved**: `ParentCID`

**Rules**:
- Source: `general.etoroGeneral_History_GuruCopiers` with Timestamp = yesterday
- GuruStatusID IN (0, 1) or NULL -- excludes active Popular Investors
- PlayerLevelID <> 4 -- excludes PI player level
- AccountTypeID != 9 -- excludes specific account type
- Not present in `External_etoro_Customer_BlockedCustomerOperations` with OperationTypeID = 2 (copy-blocked customers excluded)

### 2.2 AUM Calculation and Threshold

**What**: Computes Assets Under Management and filters to high-value parents.

**Columns Involved**: `AUM`

**Rules**:
- AUM = SUM(ISNULL(Cash, 0) + ISNULL(Investment, 0) + ISNULL(PnL, 0)) from GuruCopiers
- Only parents with AUM > $15,000 are included
- Aggregated per ParentCID

### 2.3 High-Leverage Crypto Flag

**What**: Counts open crypto positions with leverage greater than 1 for risk monitoring.

**Columns Involved**: `HighLevCrypto`

**Rules**:
- Source: `DWH_dbo.Dim_Position` with CloseDateID = 0 (open positions only)
- Filtered to InstrumentTypeID = 10 (crypto) via `DWH_dbo.Dim_Instrument`
- Leverage > 1
- COUNT per ParentCID; 0 means no high-leverage crypto exposure

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a clustered index on ParentCID ASC. With only 72 rows, full table scans are instantaneous. The CI on ParentCID supports point lookups by customer.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Parents with high-leverage crypto | `WHERE HighLevCrypto > 0` |
| Top AUM non-PI parents | `ORDER BY AUM DESC` |
| Parents by region | `GROUP BY Region` |
| Specific parent lookup | `WHERE ParentCID = @cid` (uses CI) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON ParentCID = RealCID | Additional customer attributes not in the flat table |
| DWH_dbo.Dim_Position | ON ParentCID = CID AND CloseDateID = 0 | Open position details for the parent |

### 3.4 Gotchas

- **Tiny table**: Only 72 rows. If the count grows significantly, the AUM > $15,000 threshold or PI filter may have changed.
- **Yesterday's snapshot only**: Data reflects copy relationships as of yesterday (Timestamp = yesterday in GuruCopiers). Not a historical table -- TRUNCATE+INSERT daily.
- **BI_DB_NonPI_HighAUM column**: Column #9 is named identically to the table -- an ETL artifact. It is simply GETDATE() at insert time.
- **NULL AM**: Account manager (AM) is NULL when no manager is assigned to the parent customer.
- **HighLevCrypto = 0**: Means the parent has no open crypto positions with Leverage > 1 -- not that they have no crypto at all.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 -- Synapse SP code | `(Tier 2 -- source)` |
| ★☆☆☆☆ | Tier 5 -- ETL metadata only | `(Tier 5 -- source)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ParentCID | bigint | YES | The CopyTrader parent customer ID from etoroGeneral_History_GuruCopiers. Clustered index column. Only non-PI parents (GuruStatusID IN (0,1) or NULL) with AUM > $15,000 and active copiers. (Tier 2 -- SP_NonPI_HighAUM, etoroGeneral_History_GuruCopiers.ParentCID) |
| 2 | UserName | varchar(20) | YES | Parent customer login username from Dim_Customer. (Tier 2 -- SP_NonPI_HighAUM, Dim_Customer.UserName) |
| 3 | AUM | money | YES | Assets Under Management: SUM(ISNULL(Cash,0) + ISNULL(Investment,0) + ISNULL(PnL,0)) from GuruCopiers. Only rows with AUM > $15,000 included. (Tier 2 -- SP_NonPI_HighAUM, etoroGeneral_History_GuruCopiers) |
| 4 | copiers | int | YES | Number of active copiers: COUNT(CID) from GuruCopiers per ParentCID. (Tier 2 -- SP_NonPI_HighAUM, etoroGeneral_History_GuruCopiers.CID) |
| 5 | PlayerStatus | varchar(50) | NO | Player status name from Dim_PlayerStatus. Values: Normal, etc. (Tier 2 -- SP_NonPI_HighAUM, Dim_PlayerStatus.Name) |
| 6 | AM | varchar(101) | YES | Account manager full name: Dim_Manager.FirstName + ' ' + LastName. NULL if no AM assigned. (Tier 2 -- SP_NonPI_HighAUM, Dim_Manager.FirstName + LastName) |
| 7 | Region | varchar(50) | NO | Marketing region from Dim_Country via Dim_Customer.CountryID. (Tier 2 -- SP_NonPI_HighAUM, Dim_Country.Region) |
| 8 | HighLevCrypto | int | YES | Count of open crypto positions (InstrumentTypeID=10) with Leverage > 1 for this parent. 0 = no high-leverage crypto exposure. (Tier 2 -- SP_NonPI_HighAUM, Dim_Position + Dim_Instrument) |
| 9 | BI_DB_NonPI_HighAUM | datetime | YES | ETL timestamp (GETDATE()). Column named same as table -- artifact. (Tier 5 -- SP_NonPI_HighAUM, GETDATE()) |
| 10 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at INSERT time. (Tier 5 -- SP_NonPI_HighAUM, GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ParentCID | etoroGeneral_History_GuruCopiers | ParentCID | passthrough |
| UserName | Dim_Customer | UserName | join-enriched |
| AUM | etoroGeneral_History_GuruCopiers | Cash + Investment + PnL | SUM(ISNULL aggregation) |
| copiers | etoroGeneral_History_GuruCopiers | CID | COUNT aggregate |
| PlayerStatus | Dim_PlayerStatus | Name | join-enriched |
| AM | Dim_Manager | FirstName + LastName | concat |
| Region | Dim_Country | Region | join-enriched |
| HighLevCrypto | Dim_Position + Dim_Instrument | InstrumentTypeID, Leverage | COUNT with filter |
| BI_DB_NonPI_HighAUM | -- | -- | ETL-computed (GETDATE()) |
| UpdateDate | -- | -- | ETL-computed (GETDATE()) |

### 5.2 ETL Pipeline

```
general.etoroGeneral_History_GuruCopiers (Timestamp = yesterday)
    |
    +-- JOIN DWH_dbo.Dim_Customer (parent attributes)
    +-- JOIN DWH_dbo.Dim_Manager (AM name)
    +-- JOIN DWH_dbo.Dim_PlayerStatus (player status)
    +-- JOIN DWH_dbo.Dim_Country (region)
    +-- LEFT JOIN External_etoro_Customer_BlockedCustomerOperations (exclude OperationTypeID=2)
    +-- LEFT JOIN DWH_dbo.Dim_Position + Dim_Instrument (crypto leverage count)
    |
    └─ SP_NonPI_HighAUM (no parameters)
        ├─ Filter: GuruStatusID IN (0,1)/NULL, PlayerLevelID<>4, AUM>15000
        ├─ TRUNCATE TABLE BI_DB_dbo.BI_DB_NonPI_HighAUM
        └─ INSERT → BI_DB_dbo.BI_DB_NonPI_HighAUM (72 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ParentCID | general.etoroGeneral_History_GuruCopiers | Copy relationship source -- parent customer IDs |
| ParentCID | DWH_dbo.Dim_Customer | Customer attributes (UserName, CountryID) |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Player status name resolution |
| AM | DWH_dbo.Dim_Manager | Account manager name resolution |
| Region | DWH_dbo.Dim_Country | Region via Dim_Customer.CountryID |
| HighLevCrypto | DWH_dbo.Dim_Position | Open crypto positions (CloseDateID=0) |
| HighLevCrypto | DWH_dbo.Dim_Instrument | Crypto filter (InstrumentTypeID=10, Leverage>1) |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in the SSDT repo. Used for risk monitoring dashboards tracking non-PI high-AUM CopyTrader parents.

---

## 7. Sample Queries

### 7.1 Parents with high-leverage crypto exposure

```sql
SELECT
    ParentCID,
    UserName,
    AUM,
    copiers,
    HighLevCrypto,
    Region
FROM [BI_DB_dbo].[BI_DB_NonPI_HighAUM]
WHERE HighLevCrypto > 0
ORDER BY HighLevCrypto DESC;
```

### 7.2 Top AUM parents by region

```sql
SELECT
    Region,
    COUNT(*) AS ParentCount,
    SUM(AUM) AS TotalAUM,
    AVG(AUM) AS AvgAUM,
    SUM(copiers) AS TotalCopiers
FROM [BI_DB_dbo].[BI_DB_NonPI_HighAUM]
GROUP BY Region
ORDER BY TotalAUM DESC;
```

### 7.3 Unmanaged high-AUM parents (no AM assigned)

```sql
SELECT
    ParentCID,
    UserName,
    AUM,
    copiers,
    PlayerStatus
FROM [BI_DB_dbo].[BI_DB_NonPI_HighAUM]
WHERE AM IS NULL
ORDER BY AUM DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4, 2 T5 | Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_NonPI_HighAUM | Type: Table | Production Source: general.etoroGeneral_History_GuruCopiers*
