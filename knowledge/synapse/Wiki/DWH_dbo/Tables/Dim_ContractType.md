# DWH_dbo.Dim_ContractType

> Affiliate commission model lookup - 9 frozen rows mapping ContractTypeID to deal-structure abbreviations (CPR, CPA, Rev, Hyb, etc.) used in affiliate partner agreements.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Legacy DWH SQL Server (DWH-internal; no etoro.Dictionary equivalent) |
| **Refresh** | None (frozen migration; all InsertDate/UpdateDate NULL) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ContractTypeID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

DWH_dbo.Dim_ContractType is a reference table defining affiliate commission model types for eToro's affiliate marketing program. Each row represents a distinct compensation structure used in partner agreements:

- **CPR** (Cost Per Registration): flat fee per new user registration
- **CPA** (Cost Per Acquisition): flat fee per qualifying deposit
- **Rev** (Revenue Share): percentage of ongoing trading revenue
- **Hyb** (Hybrid): combination model (e.g., CPA + Rev share)
- **eCost**: electronic/digital cost model
- **ZeroCost**: no-commission arrangement
- **CPL** (Cost Per Lead): fee per lead submitted

The table is a DWH-internal lookup with no direct equivalent in the production etoro database (etoro.Dictionary has no ContractType table). It was migrated from the legacy DWH SQL Server as a one-time load and has never been updated since - all InsertDate and UpdateDate values are NULL.

Note: SP_Dim_Affiliate populates Dim_Affiliate.ContractType via an inline CASE expression on ContractName text patterns (LIKE '%cpr%', LIKE '%0 commission%', etc.) - it does NOT perform a runtime lookup JOIN to this table. Dim_ContractType serves as a decode reference for analysts, not as an ETL dependency.

---

## 2. Business Logic

### 2.1 Commission Model Decode

**What**: Maps a ContractTypeID integer to the affiliate compensation structure name.

**Columns Involved**: `ContractTypeID`, `Name`

**Rules**:
- ID=0 (N/A): fallback / unknown or unclassified contract
- ID=1 (CPR): Cost Per Registration - flat fee per registration event
- ID=2 (CPA): Cost Per Acquisition - flat fee per first qualifying deposit
- ID=3 (Rev): Revenue Share - ongoing percentage of trading revenue
- ID=4 (Hyb): Hybrid - mixed model combining multiple commission types
- ID=5 (Other): catch-all for non-standard agreements
- ID=6 (eCost): electronic/digital channel cost model
- ID=7 (ZeroCost): zero-commission arrangement
- ID=8 (CPL): Cost Per Lead - fee per qualified lead

**Diagram**:
```
ContractTypeID -> Name
  0 -> N/A       (unknown/fallback)
  1 -> CPR       (Cost Per Registration)
  2 -> CPA       (Cost Per Acquisition)
  3 -> Rev       (Revenue Share)
  4 -> Hyb       (Hybrid)
  5 -> Other     (catch-all)
  6 -> eCost     (electronic/digital cost)
  7 -> ZeroCost  (no commission)
  8 -> CPL       (Cost Per Lead)
```

**Note**: SP_Dim_Affiliate derives ContractType integer values via CASE on ContractName text (not by joining this table). The CASE produces values 0-8 that align with this lookup but the derivation is independent of Dim_ContractType at ETL time.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `ContractTypeID ASC`. At 9 rows, REPLICATE gives each compute node a local copy for zero-movement JOINs on ContractTypeID.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Delta (MANAGED), no partitioning. Full scan is optimal at 9 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode affiliate contract model | JOIN DWH_dbo.Dim_ContractType ON ContractTypeID for Name |
| All contract types available | SELECT * FROM Dim_ContractType ORDER BY ContractTypeID |
| Affiliates by commission model | JOIN Dim_Affiliate a ON a.ContractType = ct.ContractTypeID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Affiliate | ON a.ContractType = ct.ContractTypeID | Decode commission model for affiliate dimension |

### 3.4 Gotchas

- **Not an ETL dependency**: SP_Dim_Affiliate derives ContractType values via CASE expressions from ContractName text patterns. This table is NOT joined at ETL time - it is a decode reference for analysts only.
- **All timestamps NULL**: InsertDate and UpdateDate are NULL for all 9 rows. Do not use these columns to determine row age or ETL timing.
- **Frozen table**: No automated pipeline updates this table. If new commission models are introduced, they will not appear here without a manual DBA insert.
- **Type mismatch with Dim_Affiliate**: Dim_Affiliate.ContractType is tinyint; Dim_ContractType.ContractTypeID is int. CAST if needed for JOINs.
- **N/A (ID=0)**: Use as fallback when ContractType cannot be determined from ContractName text matching in SP_Dim_Affiliate.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Description |
|-------|------|-----|-------------|
| **5 stars** | Tier 5 | `(Tier 5 - domain expert)` | Domain expert confirmed |
| **4 stars** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Upstream production wiki verbatim |
| **3 stars** | Tier 2 | `(Tier 2 - ...)` | Synapse SP code or migration DDL |
| **2 stars** | Tier 3 | `(Tier 3 - ...)` | Live data sampling or DDL structure |
| **1 star** | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ContractTypeID | int | YES | Affiliate commission model identifier. Values: 0=N/A (unknown/fallback), 1=CPR (Cost Per Registration), 2=CPA (Cost Per Acquisition), 3=Rev (Revenue Share), 4=Hyb (Hybrid), 5=Other, 6=eCost, 7=ZeroCost, 8=CPL (Cost Per Lead). SP_Dim_Affiliate derives these values via CASE on ContractName text. (Tier 2 - DWH_Migration.Dim_ContractType DDL) |
| 2 | Name | varchar(20) | YES | Abbreviated commission model name: N/A, CPR, CPA, Rev, Hyb, Other, eCost, ZeroCost, CPL. Short abbreviations used as display labels in affiliate reporting. No description column exists - analyst reference only. (Tier 3 - live data sampling, SELECT * FROM Dim_ContractType) |
| 3 | InsertDate | datetime | YES | Migration load timestamp. All 9 rows are NULL - this column was populated as varchar(50) in the DWH_Migration staging DDL but the values were not carried over (or were NULL in the legacy DWH SQL Server source). Not useful for row age determination. (Tier 2 - DWH_Migration.Dim_ContractType DDL + Tier 3 live data) |
| 4 | UpdateDate | datetime | YES | Last update timestamp. All 9 rows are NULL - same as InsertDate, no values were populated during migration. Table is effectively static since initial load. (Tier 2 - DWH_Migration.Dim_ContractType DDL + Tier 3 live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| ContractTypeID | Legacy DWH SQL Server (DWH-internal) | ContractTypeID | passthrough |
| Name | Legacy DWH SQL Server (DWH-internal) | Name | passthrough |
| InsertDate | DWH Migration ETL | InsertDate | cast (varchar50 -> datetime; all NULL in DWH) |
| UpdateDate | DWH Migration ETL | UpdateDate | cast (varchar50 -> datetime; all NULL in DWH) |

Note: No production equivalent exists in etoro.Dictionary. Dim_ContractType is DWH-internal, originating from the legacy DWH SQL Server affiliate commission model classification.

### 5.2 ETL Pipeline

```
Legacy DWH SQL Server (affiliate commission model types)
  -> DWH_Migration.Dim_ContractType (NoDbObjectsScripts, 2024-09-16)
       -> DWH_dbo.Dim_ContractType (9 rows, frozen, no active ETL)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Legacy DWH SQL Server | Historical DWH-internal affiliate dimension |
| Migration | DWH_Migration.Dim_ContractType | One-time migration staging DDL |
| Target | DWH_dbo.Dim_ContractType | Current Synapse dimension (9 rows, frozen) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (none) | - | Leaf dimension - no foreign keys |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Affiliate | ContractType (tinyint) | Affiliate dimension stores derived commission model ID (populated via CASE in SP_Dim_Affiliate, not via FK join) |

---

## 7. Sample Queries

### 7.1 Full commission model reference list
```sql
SELECT ContractTypeID, Name
FROM [DWH_dbo].[Dim_ContractType]
ORDER BY ContractTypeID;
```

### 7.2 Decode affiliate commission model
```sql
SELECT
    a.AffiliateID,
    a.AffiliateName,
    ct.Name AS CommissionModel
FROM [DWH_dbo].[Dim_Affiliate] a
LEFT JOIN [DWH_dbo].[Dim_ContractType] ct ON a.ContractType = ct.ContractTypeID
ORDER BY a.AffiliateID;
```

### 7.3 Affiliates grouped by commission model
```sql
SELECT
    ct.Name AS CommissionModel,
    COUNT(*) AS AffiliateCount
FROM [DWH_dbo].[Dim_Affiliate] a
LEFT JOIN [DWH_dbo].[Dim_ContractType] ct ON a.ContractType = ct.ContractTypeID
GROUP BY ct.Name
ORDER BY AffiliateCount DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Affiliates - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11497250033/Affiliates+-+System+Document) | Confluence | CPA vs FTD, eligibility, commission types in affiliate flows |
| [Affiliate commission services (RevShare)](https://etoro-jira.atlassian.net/wiki/spaces/CI/pages/11257972276/Affiliate+commission+services+RevShare) | Confluence | RevShare / affiliate-commission service context |
| [Affiliate - Data migration](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11643322541/Affiliate+-Data+migration) | Confluence | CPA, RevShare, and commission migration scope |
| [Affiliate Program - eToro Partners](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137312260/Affiliate+Program+-+eToro+Partners) | Confluence | Partner commission plans and CPA negotiation context |

---

*Generated: 2026-03-18 | Quality: 6.8/10 (★★★☆☆) | Phases: 13/14*
*Tiers: 0 T1, 2 T2, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 7/10, Logic: 5/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_ContractType | Type: Table | Production Source: Legacy DWH SQL Server (DWH-internal, no etoro.Dictionary equivalent)*
