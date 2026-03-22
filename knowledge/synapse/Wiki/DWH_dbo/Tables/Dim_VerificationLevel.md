# DWH_dbo.Dim_VerificationLevel

> Lookup dimension defining the four progressive KYC identity verification tiers (Level 0–3) that gate platform capabilities — from unverified registration through full KYC with complete trading and withdrawal access. Also includes a DWH-internal ID=-1 sentinel row. Sourced daily from etoro.Dictionary.VerificationLevel via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.VerificationLevel |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT + sentinel row) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED (ID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Dim_VerificationLevel` defines the progressive identity verification tiers that eToro customers pass through as they complete KYC (Know Your Customer) requirements. Each level represents a milestone unlocking additional platform capabilities. Level 0 is the starting state (unverified); Level 3 is full KYC with unrestricted access.

Without this table, the DWH cannot segment customers by identity verification status. Regulatory requirements (MiFID II, ASIC, CySEC) mandate that large withdrawals, leveraged trading, and real stock purchases require minimum verification thresholds. This dimension provides the classification system for those segments in DWH analytics.

Source: `etoro.Dictionary.VerificationLevel` on etoroDB-REAL. Loaded by SP_Dictionaries_DL_To_Synapse with TRUNCATE + INSERT. Two DWH-specific additions beyond the source data:
1. `DWHVerificationLevelID` — populated as a copy of `ID` (passthrough alias used in DWH ETL)
2. `StatusID` — hardcoded to 1 for all rows (ETL active-row convention)
3. An ID=-1 sentinel row is inserted after the main load for NULL-safe JOINs in fact tables

---

## 2. Business Logic

### 2.1 Progressive Verification Tiers

**What**: Four levels from unverified to fully KYC-verified, each unlocking more platform features.

**Columns Involved**: `ID`, `Name`

**Rules**:
- Level 0 — baseline state after registration; severe restrictions on trading and withdrawals
- Level 1 — basic verification complete (e.g., email confirmed, basic questionnaire); limited trading allowed
- Level 2 — intermediate verification (POI document submitted or under review); moderate trading access
- Level 3 — full KYC (POI + POA confirmed); complete platform access: unlimited withdrawals, all instruments, leveraged trading, real stocks

**Diagram**:
```
Registration → Level 0 (Unverified)
                    |
              Email/basic verified
                    v
              Level 1 (Basic)
                    |
              POI submitted
                    v
              Level 2 (Intermediate)
                    |
              POI + POA confirmed
                    v
              Level 3 (Full KYC)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE is optimal for this 6-row table (5 source rows + 1 sentinel). Zero data movement on JOINs. Clustered index on `ID` for point lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer count by verification tier | JOIN Dim_Customer ON VerificationLevelID = ID |
| Fully KYC customers | Filter ID = 3 |
| Unverified customer share | Filter ID = 0 |

### 3.3 Gotchas

- **DWHVerificationLevelID is a duplicate of ID**: This column has the same value as `ID` for every row. It is a DWH ETL convention artifact, not a separate key
- **StatusID is always 1**: Hardcoded by ETL, carries no business meaning
- **ID=-1 sentinel**: Added by SP_Dictionaries_DL_To_Synapse for NULL-safe JOINs in fact tables. Not a real verification level

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — upstream wiki, Dictionary.VerificationLevel) |
| Tier 2 — SP ETL code | (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NOT NULL | Verification tier identifier. Clustered index key. 0=Unverified (registration default, severe restrictions), 1=Basic (limited trading), 2=Intermediate (POI submitted, moderate access), 3=Full KYC (all features unlocked). -1=DWH sentinel (NULL-safe JOIN placeholder). Stored in customer dimension tables as VerificationLevelID and checked by 60+ procedures to gate trading, withdrawals, and compliance operations. (Tier 1 — upstream wiki, Dictionary.VerificationLevel) |
| 2 | Name | varchar(50) | YES | Display label for the tier. "Level 0" through "Level 3". Used in BackOffice UI, compliance reports, and customer analytics. Nullable by DDL but all production rows are populated. (Tier 1 — upstream wiki, Dictionary.VerificationLevel) |
| 3 | DWHVerificationLevelID | int | YES | DWH ETL alias for the ID column. Populated as `[ID] AS [DWHVerificationLevelID]` in SP_Dictionaries_DL_To_Synapse — always equals ID. Used internally by DWH ETL procedures that reference this column name; carries the same value as ID. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | ETL active-row indicator. Hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not from the production source; carries no business meaning. DWH-wide ETL convention. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily reload. Not a production change timestamp — use for ETL freshness monitoring only. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL load timestamp for row insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | etoro.Dictionary.VerificationLevel | ID | Passthrough |
| Name | etoro.Dictionary.VerificationLevel | Name | Passthrough |
| DWHVerificationLevelID | etoro.Dictionary.VerificationLevel | ID | Alias copy of ID |
| StatusID | — | — | ETL-computed: hardcoded to 1 |
| UpdateDate | — | — | ETL-computed: GETDATE() at load time |
| InsertDate | — | — | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.VerificationLevel (etoroDB-REAL, 4 rows: 0-3)
  |
  v [Generic Pipeline — daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/VerificationLevel/
  |
  v [staging]
DWH_staging.etoro_Dictionary_VerificationLevel
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT + ID=-1 sentinel]
DWH_dbo.Dim_VerificationLevel (5 rows: -1, 0, 1, 2, 3)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.VerificationLevel | 4-row KYC tier table (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/VerificationLevel/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_VerificationLevel | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; DWHVerificationLevelID=ID; StatusID=1; UpdateDate/InsertDate=GETDATE(); ID=-1 sentinel added |
| Target | DWH_dbo.Dim_VerificationLevel | 5 rows (-1,0,1,2,3) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ID | etoro.Dictionary.VerificationLevel | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | VerificationLevelID | Customer KYC tier (primary consumer in DWH) |

---

## 7. Sample Queries

### 7.1 List all verification tiers

```sql
SELECT ID, Name, DWHVerificationLevelID
FROM [DWH_dbo].[Dim_VerificationLevel]
WHERE ID >= 0
ORDER BY ID
-- Returns: 0=Level 0, 1=Level 1, 2=Level 2, 3=Level 3
```

### 7.2 Customer distribution by verification level

```sql
SELECT
    vl.Name AS VerificationLevel,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_VerificationLevel] vl
    ON dc.VerificationLevelID = vl.ID
WHERE vl.ID >= 0
GROUP BY vl.Name
ORDER BY vl.ID
```

### 7.3 ETL freshness check

```sql
SELECT ID, Name, UpdateDate
FROM [DWH_dbo].[Dim_VerificationLevel]
ORDER BY ID
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — simple-dict fast-path.)

---

*Generated: 2026-03-19 | Quality: 8.5/10 | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4-Inferred | Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 8.0/10*
*Object: DWH_dbo.Dim_VerificationLevel | Type: Table | Production Source: etoro.Dictionary.VerificationLevel*
