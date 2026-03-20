# DWH_dbo.Dim_AffiliateCostType

> Lookup dimension classifying the types of affiliate marketing costs tracked in the eToro affiliate program (e.g., CPA, Sales, Bonus, Lead).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Legacy DWH SQL Server (via DWH_Migration — frozen one-time migration) |
| **Refresh** | None — frozen data, no active ETL |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (AffiliateCostTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype` |
| **UC Format** | Parquet (Override/full load, daily) |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_AffiliateCostType` is a reference dimension enumerating the cost categories used to classify affiliate marketing expenditures. Each row represents a distinct type of cost that the eToro affiliate program may incur when acquiring customers through affiliate channels (e.g., a CPA payment triggered by a first deposit, a Lead fee for a registration, or a Bonus for a qualified trade).

This table was migrated from the legacy on-premises DWH SQL Server into Synapse in September 2024 via a one-time DWH_Migration load script (`2024_09_16_17_31_03_DWH_Migration.Dim_AffiliateCostType.sql`). A JUNK_ variant of the migration staging table also exists, confirming the standard two-pass migration pattern used during the Synapse migration project.

No active ETL SP populates this table. The 11 rows (including the standard ID=0 N/A placeholder) represent the full set of cost types as they existed in the legacy DWH at migration time. As of 2026-03-19, this table has zero references from any stored procedure, view, or downstream object in the Dataplatform SSDT repo — it appears to be a reference table that has not yet been wired into any Synapse analytics or ETL workflows. The table is exported daily to the Gold layer UC table (`dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype`) via the Generic Pipeline.

---

## 2. Business Logic

### 2.1 Affiliate Cost Type Enumeration

**What**: Classification of the types of costs eToro incurs through its affiliate marketing program.

**Columns Involved**: `AffiliateCostTypeID`, `Name`

**Rules**:
- ID=0 is the standard DWH N/A placeholder row used to satisfy FK JOINs for fact rows with no applicable cost type.
- IDs 1-10 represent distinct affiliate cost categories. Note: "Copys" (ID=9) appears to be a typo for "Copy" (as in copy-trade commissions).
- InsertDate and UpdateDate are always NULL — these were not populated during the DWH_Migration one-time load and there is no active ETL to set them.

**Value Map**:
```
AffiliateCostTypeID | Name
 0 | N/A            (placeholder)
 1 | First Position
 2 | Sales
 3 | Bonus
 4 | Chargeback
 5 | CPA
 6 | Lead
 7 | Registration
 8 | Clicks
 9 | Copys          (likely typo for "Copy")
10 | eCost
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `AffiliateCostTypeID`. REPLICATE is appropriate — the table has only 11 rows and is a pure reference dimension. Every compute node gets a full copy, eliminating shuffle costs on any JOIN to this table. The clustered index on the integer PK enables fast point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is exported to `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype` as Parquet (full Override load, daily frequency). No partitioning is expected for an 11-row reference table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What does this AffiliateCostTypeID mean? | `SELECT Name FROM DWH_dbo.Dim_AffiliateCostType WHERE AffiliateCostTypeID = @id` |
| List all affiliate cost types | `SELECT * FROM DWH_dbo.Dim_AffiliateCostType WHERE AffiliateCostTypeID > 0 ORDER BY AffiliateCostTypeID` |

### 3.3 Common JOINs

No consuming SPs or views currently JOIN to this table. If a fact table with an `AffiliateCostTypeID` column is introduced, the standard JOIN pattern would be:

```sql
JOIN DWH_dbo.Dim_AffiliateCostType act ON f.AffiliateCostTypeID = act.AffiliateCostTypeID
```

### 3.4 Gotchas

- **Frozen data**: InsertDate and UpdateDate are NULL for all 11 rows — do not rely on them for freshness checks.
- **No active consumers**: As of 2026-03-19, no SP, view, or downstream table references this dimension. It is a candidate for cleanup review or future integration.
- **"Copys" typo**: ID=9 is named "Copys" which likely means "Copy" (copy-trade commissions). Confirm with the affiliate team before relying on this label in reports.
- **Small table**: 11 rows total. Use `SELECT *` without concern.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★★ | Tier 2b | DWH_Migration DDL — structural fact from migration source |
| ★★ | Tier 3 | Live data / sampling — observed from actual Synapse table rows |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateCostTypeID | smallint | NO | Primary key identifying the affiliate cost type. Values 0-10; ID=0 is the standard N/A placeholder row for fact JOINs. (Tier 3 — live data, DWH_dbo.Dim_AffiliateCostType) |
| 2 | Name | varchar(50) | NO | Human-readable label for the affiliate cost category. See value map in Section 2.1 for all 10 active categories plus the N/A placeholder. Note: ID=9 "Copys" is likely a typo for "Copy" (copy-trade commissions). (Tier 3 — live data, DWH_dbo.Dim_AffiliateCostType) |
| 3 | InsertDate | datetime | YES | Migration artifact — always NULL. In a live ETL table this would record the row creation timestamp; this table has no active ETL and was never populated during the DWH_Migration one-time load. (Tier 2b — DWH_Migration DDL) |
| 4 | UpdateDate | datetime | YES | Migration artifact — always NULL. In a live ETL table this would record the last ETL refresh timestamp. No active ETL writes to this table. (Tier 2b — DWH_Migration DDL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| AffiliateCostTypeID | DWH_Migration.Dim_AffiliateCostType | AffiliateCostTypeID (varchar(10)) | Cast to smallint |
| Name | DWH_Migration.Dim_AffiliateCostType | Name (varchar(50)) | Passthrough |
| InsertDate | DWH_Migration.Dim_AffiliateCostType | InsertDate (varchar(50)) | Cast to datetime — always NULL |
| UpdateDate | DWH_Migration.Dim_AffiliateCostType | UpdateDate (varchar(50)) | Cast to datetime — always NULL |

No upstream production wiki. Source: legacy on-premises DWH SQL Server (migrated September 2024, no etoro DB equivalent found).

### 5.2 ETL Pipeline

```
Legacy DWH SQL Server -> one-time DWH_Migration load -> DWH_dbo.Dim_AffiliateCostType
(no active ETL refresh)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Legacy DWH SQL Server | Affiliate cost type reference table — no active production equivalent found |
| Migration | DWH_Migration.Dim_AffiliateCostType | Staging table created 2024-09-16, full table migrated |
| ETL | None | No active ETL SP. Table is frozen at migration snapshot. |
| Target | DWH_dbo.Dim_AffiliateCostType | 11 rows, REPLICATE distributed |
| Export | Generic Pipeline | DWH -> Gold/sql_dp_prod_we/DWH_dbo/Dim_AffiliateCostType/ -> UC dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype (daily) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| — | — | No foreign key relationships. This is a leaf reference dimension. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | No consuming SPs, views, or downstream tables reference this table as of 2026-03-19. |

---

## 7. Sample Queries

### 7.1 View all affiliate cost types

```sql
SELECT AffiliateCostTypeID, Name
FROM DWH_dbo.Dim_AffiliateCostType
WHERE AffiliateCostTypeID > 0
ORDER BY AffiliateCostTypeID
```

### 7.2 Resolve an affiliate cost type ID to its label

```sql
SELECT act.Name AS CostTypeName
FROM DWH_dbo.Dim_AffiliateCostType act
WHERE act.AffiliateCostTypeID = 5  -- CPA
```

### 7.3 Confirm table freshness (migration artifact check)

```sql
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN InsertDate IS NULL THEN 1 ELSE 0 END) AS NullInsertDate,
    SUM(CASE WHEN UpdateDate IS NULL THEN 1 ELSE 0 END) AS NullUpdateDate
FROM DWH_dbo.Dim_AffiliateCostType
-- Expected: 11 total, 11 null InsertDate, 11 null UpdateDate (frozen migration)
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Affiliate -Data migration](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11643322541) | Confluence | Commission type mapping: Registration Commission, CPA commission (Type 1), ChargeBack Commission (Type 4&5), RevShare/Sales/Close Position. Confirms the value map in Section 2.1. |
| [Affiliates - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11497250033) | Confluence | Commission system reads messages from queue, validates and calculates commission according to type, updates FiktivoCommission table. Confirms commission types correspond to AffWizz (fiktivo) system. |
| [ISA CPA for affiliate](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13848641537) | Confluence | CPA (Cost Per Acquisition) can have different commission plans per deposit source (e.g., Money Farm deposits). |

---

*Generated: 2026-03-19 | Quality: 7.0/10 (★★★★☆) | Phases: 13/14*
*Tiers: 0 T1, 0 T2, 2 T2b, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 7/10*
*Object: DWH_dbo.Dim_AffiliateCostType | Type: Table | Production Source: Legacy DWH SQL Server (DWH_Migration)*
