# DWH_dbo.Dim_Platform

> Lookup table defining the 4 client access platform types (Undefined, Web, IOS, Android) used to tag customer actions and sessions with their originating device platform.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Platform |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PlatformID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_Platform is a 4-row dictionary defining the device and application platforms from which customers access the eToro trading application. Every user session, trade, and interaction is tagged with a platform identifier to enable per-platform analytics, feature flagging, and UX customization. Platform determines which features are available (some are web-only or mobile-only), which UI is rendered, and which API endpoints are called.

The data originates from `etoro.Dictionary.Platform` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/Platform/` in the data lake. In production, the PK column is named `Id`; the DWH ETL renames it to `PlatformID`.

Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from `DWH_staging.etoro_Dictionary_Platform`. Refreshes daily. As of 2026-03-19, UpdateDate is 2026-03-11 -- 8 days stale due to known schema-wide ETL disruption.

**Note**: No DWH SPs other than SP_Dictionaries_DL_To_Synapse were found referencing this table in the SSDT repo. This dimension may be lightly used or orphaned within the current DWH batch of documented tables -- confirm consumer SPs when Dim_Customer and Fact tables are available for cross-reference.

---

## 2. Business Logic

### 2.1 Multi-Platform Access Classification

**What**: Classifies each user session or action by the device/app platform from which it originated.

**Columns Involved**: `PlatformID`, `Platform`

**Rules**:
- **ID=0 (Undefined)** -- Platform not detected or not applicable. Used for server-side operations, API calls without user-agent context, or legacy records before platform tracking was added.
- **ID=1 (Web)** -- Browser-based access. Full feature set, desktop-optimized trading interface.
- **ID=2 (IOS)** -- Apple iOS native app. Mobile-optimized trading, push notifications, Face ID authentication.
- **ID=3 (Android)** -- Google Android native app. Mobile-optimized trading, push notifications, biometric authentication.
- Feature flags can be platform-specific (e.g., a feature rolled out to iOS before Android).

**Diagram**:
```
Platform Types
  0 = Undefined (server-side / platform detection failed)
  1 = Web       (browser -- desktop or mobile browser)
  2 = IOS       (Apple native app -- iPhone/iPad)
  3 = Android   (Google native app)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `PlatformID`. With only 4 rows, REPLICATE is optimal -- every compute node holds a full copy, making JOIN operations zero-shuffle-cost. Always join on `PlatformID`.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platform`. With 4 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What does a PlatformID mean? | JOIN Dim_Platform ON PlatformID for the label |
| Platform split of customer actions | GROUP BY PlatformID with this dim for labels |
| Mobile vs Web breakdown | Group IDs 2+3 as "Mobile", ID 1 as "Web", ID 0 as "Undefined" |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer (when available) | ON dc.PlatformID = dp.PlatformID | Resolve platform label per customer (confirm column name in Dim_Customer) |
| Fact tables referencing PlatformID | ON ft.PlatformID = dp.PlatformID | Resolve platform label in fact-level analytics |

### 3.4 Gotchas

- **Column rename**: Production table has `Id` (not `PlatformID`). The DWH ETL renames it during load (`SELECT [Id] AS PlatformID`). Do not query production using `PlatformID` -- it won't exist.
- **ID=0 exists**: The table has an ID=0 row (Undefined). Standard INNER JOIN is safe but may exclude undefined records from counts.
- **Potentially orphaned**: Only SP_Dictionaries_DL_To_Synapse was found referencing this table in the current SSDT scan. Verify active consumer SPs when Fact tables are documented.
- **Note: Distinct from Dim_PlatformType**: Dim_PlatformType (13 rows, batch 5) is a legacy migration table covering historical platform categories. Dim_Platform (4 rows) is the actively ETL'd production dictionary. They serve different purposes.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.Platform) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PlatformID | int | YES | DWH platform identifier. 0=Undefined, 1=Web, 2=IOS, 3=Android. Renamed from `Id` in the production source (etoro.Dictionary.Platform) by the DWH ETL. Referenced by session and action tracking tables to indicate the originating device platform. DWH note: column renamed from production `Id` to `PlatformID` during TRUNCATE+INSERT load. (Tier 1 - upstream wiki, Dictionary.Platform) |
| 2 | Platform | nvarchar(20) | YES | Platform name label: "Undefined", "Web", "IOS", "Android". Used in reporting dashboards and per-platform analytics. Passthrough from production -- same column name. (Tier 1 - upstream wiki, Dictionary.Platform) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PlatformID | etoro.Dictionary.Platform | Id | rename (Id -> PlatformID) |
| Platform | etoro.Dictionary.Platform | Platform | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on each reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.Platform.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.Platform
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/Platform/
  -> DWH_staging.etoro_Dictionary_Platform
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT; Id -> PlatformID rename)
  -> DWH_dbo.Dim_Platform
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Platform | Production platform dictionary (etoroDB-REAL) -- PK column is `Id` |
| Lake | Bronze/etoro/Dictionary/Platform/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_Platform | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; renames `Id` to `PlatformID` and overrides UpdateDate to GETDATE() |
| Target | DWH_dbo.Dim_Platform | 4-row enum lookup, REPLICATE distributed |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo (pending tables) | PlatformID | Platform label resolution in customer and fact tables -- confirm when Dim_Customer and Fact tables are documented |

---

## 7. Sample Queries

### 7.1 List all platform types

```sql
SELECT PlatformID,
       Platform
FROM   [DWH_dbo].[Dim_Platform]
ORDER BY PlatformID;
```

### 7.2 Mobile vs Web breakdown (analytical grouping)

```sql
SELECT  CASE dp.PlatformID
            WHEN 1 THEN 'Web'
            WHEN 2 THEN 'Mobile (iOS)'
            WHEN 3 THEN 'Mobile (Android)'
            ELSE 'Undefined'
        END            AS PlatformGroup,
        dp.Platform,
        dp.PlatformID
FROM    [DWH_dbo].[Dim_Platform] dp
ORDER BY dp.PlatformID;
```

### 7.3 Resolve PlatformID in a fact table (template)

```sql
-- Replace FactTable and PlatformID_col with the actual table and column name
SELECT  ft.*,
        dp.Platform
FROM    [DWH_dbo].[SomeFactTable] ft
LEFT JOIN [DWH_dbo].[Dim_Platform] dp
        ON ft.PlatformID = dp.PlatformID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.6/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Platform | Type: Table | Production Source: etoro.Dictionary.Platform*
