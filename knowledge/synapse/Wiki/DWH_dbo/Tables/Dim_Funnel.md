# DWH_dbo.Dim_Funnel

> Acquisition funnel dimension - maps funnel IDs to the channel or product surface through which eToro customers registered, with platform classification. Used in customer, deposit, and action analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Funnel |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Funnel` is an acquisition channel dimension mapping 129 funnel IDs (range -9 to 130) to the registration surface or product entry point through which an eToro customer first arrived. Funnels represent web pages, mobile apps, partner sites, and internal tools.

**FunnelID=-9 (AutomationTest)** and **FunnelID=0 (Unknown)** are special sentinel values. SP_Dim_Customer uses `ISNULL(FunnelID, 0)` coercing NULLs to 0 (Unknown).

`PlatformID` classifies the broad channel:
- 0 = Unspecified/internal (AutomationTest, Unknown, Sit&Play, Mobile generic, BackOffice, etc.)
- 1 = Web (eToro Client, Web Trader, Web Registration, Open Book, Cashier, eToro Website, etc.)
- 2 = iOS (iOS eToro Trader)
- 3 = Android (Android eToro Trader, Android Trade Alerts)

The dimension is actively consumed by `Dim_Customer` (registration funnel for each customer), `Fact_BillingDeposit` (funnel at deposit time), and `Fact_CustomerAction`.

---

## 2. Business Logic

### 2.1 Funnel Channel Classification

**What**: Funnels represent the specific registration or entry channel for a customer. PlatformID provides a coarser platform grouping.

**Columns Involved**: `FunnelID`, `Name`, `PlatformID`

**Rules**:
- Web funnels (PlatformID=1): "eToro Client", "Web Trader", "Web Registration", "Open Book", "Cashier", "eToro Website", "Landing Page", "eToroUSA Website", "eToroPartners Website"
- iOS funnels (PlatformID=2): "iOS eToro Trader"
- Android funnels (PlatformID=3): "Android eToro Trader", "Android Trade Alerts"
- Unspecified/internal (PlatformID=0): "AutomationTest" (FunnelID=-9), "Unknown" (FunnelID=0), "Mobile" (generic), "BackOffice", "Copy.me", "Sit & Play"

**Key funnels observed**:
```
-9  | AutomationTest          | 0 (internal test)
0   | Unknown                 | 0 (null sentinel)
1   | eToro Client            | 1 (web)
2   | Web Trader              | 1 (web)
3   | Web Registration        | 1 (web)
6   | Mobile                  | 0 (generic mobile)
15  | Android eToro Trader    | 3 (Android)
17  | iOS eToro Trader        | 2 (iOS)
18  | eToroUSA Website        | 1 (web, US market)
19  | eToroPartners Website   | 1 (web, partners)
```

### 2.2 Null-Sentinel Pattern

**What**: FunnelID=0 (Unknown) serves as a null-safe join target.

**Columns Involved**: `FunnelID`

**Rules**:
- SP_Dim_Customer uses `ISNULL(FunnelID, 0) AS FunnelID` to coerce NULLs to 0 before load
- SP_Dim_Customer change detection: `OR ISNULL(dc.FunnelID,0) <> ISNULL(a.FunnelID,0)`
- Fact tables with FunnelID=0 represent customers/transactions where the registration channel is unknown

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (129 rows - appropriate). HEAP index - full scans on all lookups, negligible impact at 129 rows. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 129 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FunnelID to funnel name | `LEFT JOIN DWH_dbo.Dim_Funnel ON FunnelID` |
| Group by platform (Web/iOS/Android) | `GROUP BY PlatformID` with CASE decode |
| Exclude automation/unknown funnels | `WHERE FunnelID > 0` |
| Count customers by acquisition funnel | `JOIN Dim_Customer ON FunnelID GROUP BY Name` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON FunnelID | Customer acquisition channel |
| DWH_dbo.Fact_BillingDeposit | ON FunnelID | Funnel context for deposits |
| DWH_dbo.Fact_CustomerAction | ON FunnelID | Funnel context for customer actions |

### 3.4 Gotchas

- **HEAP index**: Unlike most Dim_ tables with CLUSTERED INDEX, Dim_Funnel uses HEAP. Point-lookups are full scans but negligible at 129 rows.
- **FunnelID=-9 is negative**: AutomationTest has FunnelID=-9. Filters like `WHERE FunnelID > 0` correctly exclude both AutomationTest and Unknown.
- **PlatformID is unresolved**: There is no `Dim_Platform` table in DWH_dbo. PlatformID values (0-3) must be decoded manually or via Dim_PlatformType (if applicable).
- **Name not renamed**: Unlike most Dim_ tables where Name becomes XxxName (e.g., FunnelName), this column stays as `Name`.
- **StatusID hardcoded**: All rows have StatusID=1. No deactivation mechanism visible.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FunnelID | int | NO | Primary key identifying the acquisition funnel. Ranges from -9 (AutomationTest) through 130+. Stored on Customer.CustomerStatic via FK and on Customer.RegistrationRequest at registration time. Also stored on Billing.Deposit for first-deposit attribution. (Tier 1 — Dictionary.Funnel) |
| 2 | Name | varchar(50) | YES | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. (Tier 1 — Dictionary.Funnel) |
| 3 | PlatformID | int | YES | Platform category for this funnel. 0=Unknown/Cross-platform, 1=Web, 2=iOS, 3=Android. Defaults to 0 for server-side or platform-agnostic funnels. Links to Dictionary.Platform for platform name resolution. (Tier 1 — Dictionary.Funnel) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate per run). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | StatusID | int | YES | Hardcoded to 1 for all rows. Likely means active. No Dim_Status table in DWH to decode. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FunnelID | etoro.Dictionary.Funnel | FunnelID | passthrough |
| Name | etoro.Dictionary.Funnel | Name | passthrough |
| PlatformID | etoro.Dictionary.Funnel | PlatformID | passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |
| StatusID | - | - | ETL-computed: hardcoded 1 |

### 5.2 ETL Pipeline

```
etoro.Dictionary.Funnel -> Generic Pipeline -> DWH_staging.etoro_Dictionary_Funnel -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 698) -> DWH_dbo.Dim_Funnel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Funnel | Funnel dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/Funnel/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_Funnel | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds UpdateDate/InsertDate=GETDATE(), StatusID=1. |
| Target | DWH_dbo.Dim_Funnel | 129-row REPLICATE/HEAP funnel dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | FunnelID | Customer acquisition funnel (registration channel) |
| DWH_dbo.Fact_BillingDeposit | FunnelID | Funnel context at deposit time |
| DWH_dbo.Fact_CustomerAction | FunnelID | Funnel context for customer financial actions |

---

## 7. Sample Queries

### 7.1 All active funnels by platform

```sql
SELECT FunnelID, Name,
    CASE PlatformID
        WHEN 0 THEN 'Unspecified/Internal'
        WHEN 1 THEN 'Web'
        WHEN 2 THEN 'iOS'
        WHEN 3 THEN 'Android'
        ELSE 'Unknown'
    END AS PlatformName
FROM DWH_dbo.Dim_Funnel
WHERE FunnelID > 0
ORDER BY PlatformID, FunnelID
```

### 7.2 Customer count by acquisition platform

```sql
SELECT
    CASE f.PlatformID
        WHEN 1 THEN 'Web'
        WHEN 2 THEN 'iOS'
        WHEN 3 THEN 'Android'
        ELSE 'Other'
    END AS Platform,
    COUNT(*) AS CustomerCount
FROM DWH_dbo.Dim_Customer dc
LEFT JOIN DWH_dbo.Dim_Funnel f ON dc.FunnelID = f.FunnelID
WHERE dc.FunnelID > 0
GROUP BY f.PlatformID
ORDER BY CustomerCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 3 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/8, Logic: 8/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Funnel | Type: Table | Production Source: etoro.Dictionary.Funnel*
