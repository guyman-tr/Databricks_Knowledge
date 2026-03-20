# DWH_dbo.Dim_Product

> Client application and platform dimension mapping eToro product names (app identifiers) to their platform and sub-platform categories.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown - frozen legacy migration (no active ETL) |
| **Refresh** | None - static frozen data since 2018 |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ProductID ASC) |
| | |
| **UC Target** | bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product |
| **UC Format** | Delta |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Product is a static lookup table that classifies eToro client applications into a three-level hierarchy: Platform (Mobile/Web), SubPlatform (Android/iOS/Browsers), and Product (individual app names). It enumerates the named client applications (OpenBook, Trader, Wallet, eToroX, Delta, reToro, RegistrationAPI, Other) across mobile and web delivery channels. ProductID 99 serves as the universal null-sentinel row for fact table JOINs.

No production source has been identified. All 27 rows have InsertDate = 2018-09-02, indicating a one-time legacy migration from the on-premises DWH. A single UpdateDate of 2020-07-28 suggests a minor post-migration correction. No Generic Pipeline export feeds into this table - it is the DWH itself that exports to Gold via the Generic Pipeline (uc_table: bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product).

This table has no active ETL stored procedure. It is a frozen lookup dictionary. Analysts should treat it as a stable but potentially incomplete mapping - newer product names introduced after 2020 are likely not represented.

---

## 2. Business Logic

### 2.1 Three-Level Product Hierarchy

**What**: eToro client applications are organized into a three-level hierarchy for platform-level reporting.

**Columns Involved**: `Platform`, `SubPlatform`, `Product`

**Rules**:
- Level 1 (Platform): empty string (no platform), Mobile, Web
- Level 2 (SubPlatform): empty string (no platform), Android, iOS, Browsers
- Level 3 (Product): individual app names (see full value map in Section 4)
- The combination of Platform + SubPlatform + Product uniquely identifies each app variant

**Diagram**:
```
Platform
 +-- (empty)  -> SubPlatform: (empty) -> Product: No Platform [ID=99, sentinel]
 +-- Mobile   -> Android     -> OpenBook, Other, RegistrationAPI, reToro, reToroAndroid, Trader, Wallet, eToroX, Delta
 |            -> iOS         -> OpenBook, Other, RegistrationAPI, reToro, reToroiOS, Trader, Wallet, eToroX, Delta
 +-- Web      -> Browsers    -> OpenBook, Other, RegistrationAPI, reToro, Trader, Wallet, eToroX, Delta
```

### 2.2 Null Sentinel Pattern

**What**: ProductID=99 ("No Platform") is the universal null sentinel for fact table JOINs.

**Columns Involved**: `ProductID`, `Product`, `Platform`, `SubPlatform`

**Rules**:
- ProductID=99, Product="No Platform", Platform="", SubPlatform=""
- Fact tables coerce NULL ProductID to 99 via ISNULL(ProductID, 99) before JOINing
- This row exists to preserve referential integrity when no product context is available

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `ProductID ASC`. As a 27-row static dictionary, REPLICATE is optimal - the entire table is copied to every distribution node, enabling zero-shuffle JOINs. Always JOIN on `ProductID` directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product` is a Delta table. With only 27 rows, no partitioning is needed - read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve ProductID to app name in a fact table | `LEFT JOIN DWH_dbo.Dim_Product dp ON ISNULL(fact.ProductID, 99) = dp.ProductID` |
| All mobile products | `WHERE Platform = 'Mobile'` |
| Android-specific products | `WHERE Platform = 'Mobile' AND SubPlatform = 'Android'` |
| Web products only | `WHERE Platform = 'Web'` |
| Filter out the sentinel row | `WHERE ProductID <> 99` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact tables with ProductID | `ON ISNULL(fact.ProductID, 99) = dp.ProductID` | Resolve product name and platform |

### 3.4 Gotchas

- **Frozen since 2018**: Newer eToro products (post-2020) are unlikely to appear. If a ProductID in a fact table doesn't join, it's a newer app not in this table.
- **Delta/eToroX presence**: ProductIDs 124/125/126 (Delta) and 121/122/123 (eToroX) have the highest IDs, suggesting they were added in a 2020 update - these are the most recent entries.
- **Platform is an empty string, not NULL**: For the sentinel row (ID=99), both Platform and SubPlatform are empty strings, not NULLs.
- **No consumers found in SSDT**: No stored procedure in the DWH SSDT repo JOINs to Dim_Product. This table may be used primarily by reporting layers outside the DWH (BI_DB, Databricks).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP/DDL)` |
| ★★☆☆☆ | Tier 3 - Live data / DDL structure | `(Tier 3 - live data)` / `(Tier 3b - DDL)` |
| ★☆☆☆☆ | Tier 4 - Inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 - inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProductID | int | NO | Primary key. Client application identifier. Sentinel: 99 = No Platform (null substitute for fact table JOINs). Known IDs: 99=No Platform, 101-126=named apps across platforms. (Tier 3b - DDL) |
| 2 | Product | varchar(50) | NO | Client application display name. Values: No Platform, OpenBook, Other, RegistrationAPI, reToro, reToroAndroid, reToroiOS, Trader, Wallet, eToroX, Delta. "Other" is a catch-all for unclassified sessions. (Tier 3 - live data) |
| 3 | Platform | varchar(50) | NO | Top-level delivery platform. Values: empty string (No Platform sentinel), Mobile, Web. (Tier 3 - live data) |
| 4 | SubPlatform | varchar(50) | NO | Operating system or browser category. Values: empty string (No Platform sentinel), Android, iOS, Browsers. (Tier 3 - live data) |
| 5 | InsertDate | datetime | YES | ETL or migration timestamp when the row was inserted. All rows = 2018-09-02 (one-time migration). (Tier 3b - DDL) |
| 6 | UpdateDate | datetime | YES | Last modification timestamp. Max value 2020-07-28 (Delta/eToroX rows added). Static for all other rows. (Tier 3 - live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ProductID | Unknown - legacy DWH migration | ProductID | Passthrough (migration) |
| Product | Unknown - legacy DWH migration | Product / Name | Passthrough (migration) |
| Platform | Unknown - legacy DWH migration | Platform | Passthrough (migration) |
| SubPlatform | Unknown - legacy DWH migration | SubPlatform | Passthrough (migration) |
| InsertDate | ETL metadata | - | GETDATE() at migration time |
| UpdateDate | ETL metadata | - | GETDATE() at migration time |

### 5.2 ETL Pipeline

```
Unknown production source -> one-time migration (2018) -> DWH_dbo.Dim_Product
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Unknown legacy DWH | Original on-premises SQL Server DWH source |
| ETL | None (frozen) | No active ETL SP exists in SSDT |
| Target | DWH_dbo.Dim_Product | 27-row static lookup, frozen since 2018 |
| Export | Generic Pipeline | DWH exports to bi_db.gold_sql_dp_prod_we_dwh_dbo_dim_product |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - no foreign key columns referencing other DWH tables.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Unknown fact tables (outside SSDT scope) | ProductID | Potentially referenced by reporting layers. No FK consumers found in DWH SSDT repo. |

---

## 7. Sample Queries

### 7.1 List all products by platform
```sql
SELECT Platform, SubPlatform, ProductID, Product
FROM [DWH_dbo].[Dim_Product]
WHERE ProductID <> 99
ORDER BY Platform, SubPlatform, Product
```

### 7.2 Resolve product names in a fact table
```sql
SELECT
    fca.CID,
    fca.ActionDate,
    ISNULL(dp.Platform, 'Unknown') AS Platform,
    ISNULL(dp.SubPlatform, 'Unknown') AS SubPlatform,
    ISNULL(dp.Product, 'Unknown') AS Product
FROM [DWH_dbo].[Fact_CustomerAction] fca
LEFT JOIN [DWH_dbo].[Dim_Product] dp
    ON ISNULL(fca.ProductID, 99) = dp.ProductID
WHERE fca.ActionDateID = 20260101
```

### 7.3 Count of mobile vs web products
```sql
SELECT
    Platform,
    SubPlatform,
    COUNT(*) AS product_count,
    STRING_AGG(Product, ', ') AS products
FROM [DWH_dbo].[Dim_Product]
WHERE ProductID <> 99
GROUP BY Platform, SubPlatform
ORDER BY Platform, SubPlatform
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862/BI+Dictionary) | Confluence | Positions DWH tables as the foundation layer for detailed eToro reporting; SCD-style dimensions noted as the pattern for customer/product-style attributes. |
| [Data Products \| Architecture](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11839046073/Data+Products+Architecture) | Confluence | Describes “Top instruments” and daily traded-instrument calculations in Databricks—adjacent business context for product/platform and instrument analytics. |
| [DWH User Guide](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11604167900/DWH+User+Guide) | Confluence | Documents DWH lake paths and snapshot layout for trading datasets—useful background for where app/product identifiers may appear in downstream exports. |

---

*Generated: 2026-03-19 | Quality: 7.1/10 (★★★☆☆) | Phases: 9/14*
*Tiers: 0 T1, 0 T2, 4 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/10, Logic: 7/10, Relationships: 2/10, Sources: 7/10*
*Object: DWH_dbo.Dim_Product | Type: Table | Production Source: Unknown - legacy migration*
