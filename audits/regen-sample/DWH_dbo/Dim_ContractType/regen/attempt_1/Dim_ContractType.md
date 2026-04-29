# DWH_dbo.Dim_ContractType

> 9-row static dimension table enumerating affiliate contract types (CPR, CPA, Rev, Hyb, eCost, ZeroCost, CPL, Other, N/A). Loaded via one-time migration; no writer SP. Referenced by Dim_Affiliate and resolved in SP_Marketing_Cube. Daily Override export to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant) — loaded via DWH_Migration, no active writer SP |
| **Refresh** | Static (no writer SP); Generic Pipeline daily Override export to UC |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ContractTypeID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, parquet, daily) |

---

## 1. Business Meaning

Dim_ContractType is a static 9-row lookup table that defines the contract type codes used in the affiliate marketing domain. Each row maps a `ContractTypeID` integer to a short abbreviation (`Name`): 0=N/A, 1=CPR, 2=CPA, 3=Rev, 4=Hyb, 5=Other, 6=eCost, 7=ZeroCost, 8=CPL.

The table has no dedicated ETL stored procedure — it was loaded via a one-time migration from `DWH_Migration.Dim_ContractType`. The `InsertDate` and `UpdateDate` columns are entirely NULL across all rows, confirming that no ongoing ETL process maintains this table.

`SP_Dim_Affiliate` computes a `ContractType` integer for each affiliate using a CASE expression over `ContractName` patterns, producing values that correspond to the IDs in this dimension. `SP_Marketing_Cube` then JOINs `Dim_ContractType` to `Dim_Affiliate` on `ContractType = ContractTypeID` to resolve the human-readable contract type name for marketing analytics cubes.

---

## 2. Business Logic

### 2.1 Contract Type Enumeration

**What**: Maps integer IDs to affiliate contract type abbreviations.
**Columns Involved**: ContractTypeID, Name
**Rules**:
- 0 = N/A (default/fallback when no contract pattern matches)
- 1 = CPR (Cost Per Revenue)
- 2 = CPA (Cost Per Acquisition)
- 3 = Rev (Revenue share)
- 4 = Hyb (Hybrid model)
- 5 = Other (unclassified)
- 6 = eCost (electronic cost)
- 7 = ZeroCost (zero-cost arrangement)
- 8 = CPL (Cost Per Lead)

### 2.2 Contract Type Assignment Logic (SP_Dim_Affiliate)

**What**: SP_Dim_Affiliate assigns ContractType to affiliates via CASE on ContractName.
**Columns Involved**: ContractType (in Dim_Affiliate), ContractName
**Rules**:
- ContractName LIKE '%mati%' AND '%' → 3 (Rev)
- ContractName LIKE '%cpl%' → 8 (CPL)
- ContractName LIKE '%cpr%' → 8 (CPR — note: shares ID 8 with CPL in CASE order)
- Channel = 'Affiliate' AND ContractName LIKE '%0 commission%' → 7 (ZeroCost)
- ELSE → 0 (N/A)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution means this table is copied to every compute node — JOINs to it never require data movement. CLUSTERED INDEX on ContractTypeID enables fast point lookups. With only 9 rows, full table scans are negligible.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What contract types exist? | `SELECT * FROM DWH_dbo.Dim_ContractType ORDER BY ContractTypeID` |
| Resolve affiliate contract type name | `JOIN DWH_dbo.Dim_ContractType DCT ON DA.ContractType = DCT.ContractTypeID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Affiliate | `Dim_Affiliate.ContractType = Dim_ContractType.ContractTypeID` | Resolve contract type name for affiliate records |

### 3.4 Gotchas

- **ContractTypeID 0 = N/A**: Default fallback in SP_Dim_Affiliate when no ContractName pattern matches. Filter or handle explicitly in aggregations.
- **InsertDate / UpdateDate are entirely NULL**: These metadata columns were never populated, likely because the table was loaded as a one-time migration with no ongoing ETL.
- **CPR and CPL share ID 8 in SP_Dim_Affiliate CASE logic**: The CASE expression evaluates `%cpl%` before `%cpr%`, so a ContractName matching both would be assigned CPL (8). However, the dimension table lists CPR at ID 1 and CPL at ID 8, suggesting the SP logic may have a latent mapping inconsistency.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Grounded in DDL + live data, no upstream wiki |
| Tier 4 | Inferred from name only (banned in this pipeline) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ContractTypeID | int | YES | Primary key identifying the affiliate contract type. Integer enum: 0=N/A, 1=CPR, 2=CPA, 3=Rev, 4=Hyb, 5=Other, 6=eCost, 7=ZeroCost, 8=CPL. Referenced by Dim_Affiliate.ContractType. (Tier 3 — DDL + live data, no upstream wiki) |
| 2 | Name | varchar(20) | YES | Short abbreviation for the contract type. 9 distinct values: N/A, CPR, CPA, Rev, Hyb, Other, eCost, ZeroCost, CPL. Resolved in SP_Marketing_Cube via JOIN to Dim_Affiliate. (Tier 3 — DDL + live data, no upstream wiki) |
| 3 | InsertDate | datetime | YES | Row insertion timestamp. Currently NULL across all 9 rows — never populated by migration or ETL. (Tier 3 — DDL + live data, no upstream wiki) |
| 4 | UpdateDate | datetime | YES | Row last-update timestamp. Currently NULL across all 9 rows — never populated by migration or ETL. (Tier 3 — DDL + live data, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| ContractTypeID | Unknown (migration) | ContractTypeID | Passthrough |
| Name | Unknown (migration) | Name | Passthrough |
| InsertDate | Unknown (migration) | InsertDate | Passthrough |
| UpdateDate | Unknown (migration) | UpdateDate | Passthrough |

### 5.2 ETL Pipeline

```
Unknown production source (static reference data)
  |-- One-time migration ---|
  v
DWH_Migration.Dim_ContractType (staging, ROUND_ROBIN)
  |-- Migration copy ---|
  v
DWH_dbo.Dim_ContractType (9 rows, REPLICATE)
  |-- Generic Pipeline (Override, daily, parquet) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None — this is a root lookup table.

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ContractTypeID | DWH_dbo.Dim_Affiliate | Dim_Affiliate.ContractType → Dim_ContractType.ContractTypeID |
| Name | BI_DB_dbo.SP_Marketing_Cube | Resolves ContractType name via JOIN for marketing cube |

---

## 7. Sample Queries

### 7.1 List All Contract Types

```sql
SELECT ContractTypeID, Name
FROM DWH_dbo.Dim_ContractType
ORDER BY ContractTypeID;
```

### 7.2 Count Affiliates by Contract Type

```sql
SELECT DCT.Name AS ContractType, COUNT(*) AS AffiliateCount
FROM DWH_dbo.Dim_Affiliate DA
JOIN DWH_dbo.Dim_ContractType DCT
  ON DA.ContractType = DCT.ContractTypeID
GROUP BY DCT.Name
ORDER BY AffiliateCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this static lookup table.

---

*Generated: 2026-04-28 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 0 T2, 4 T3, 0 T4, 0 T5 | Elements: 4/4, Logic: 6/10, Lineage: 5/10*
*Object: DWH_dbo.Dim_ContractType | Type: Table | Production Source: Unknown (dormant — migration load)*
