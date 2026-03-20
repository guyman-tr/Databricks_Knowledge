# DWH_dbo.CustomerStatic

> Abandoned stub table intended to capture a summary of customer registration events; currently contains 0 rows and has no active ETL writer. Deployed but never populated.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Customer.CustomerStatic (partial column subset) |
| **Refresh** | None — no active ETL (stub/abandoned) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

DWH_dbo.CustomerStatic appears to have been designed as a compact customer registration summary table capturing key attributes at the time of a customer's first or primary action event. Its 10-column structure (CID, Registered, IsReal, ActionTypeID, PlatformTypeID, Amount, DateID, TimeID, StatusID, PlatformID) combines identity fields from the production Customer.CustomerStatic with action-event fields (ActionTypeID, Amount, PlatformTypeID) suggesting an intended role as a pre-aggregated "first customer action" fact - similar in concept to Fact_FirstCustomerAction.

The production source table is etoro.Customer.CustomerStatic on etoroDB-REAL, which is exported daily to the data lake at Bronze/etoro/Customer/CustomerStatic/ and staged into DWH_staging.etoro_Customer_CustomerStatic (85 columns, full customer profile). The DWH table contains only 10 of those 85+ columns, and adds several columns (ActionTypeID, PlatformTypeID, Amount, DateID, TimeID) not present in the production source, suggesting it was intended to JOIN registration data with a first-action event.

This table has 0 rows and no ETL stored procedure writes to it. The staging data from etoro_Customer_CustomerStatic is consumed by SP_Dim_Customer_DL_To_Synapse (to populate Ext_Dim_CustomerStatic with CID/ApexID pairs) and SP_Fact_CustomerAction_DL_To_Synapse (to populate Ext_FCA_Customer and other staging tables), but neither SP targets DWH_dbo.CustomerStatic. This table is effectively abandoned. Use Dim_Customer or Fact_CustomerAction (ActionTypeID=41) for customer registration analysis.

---

## 2. Business Logic

### 2.1 Intended Registration Event Summary (Abandoned)

**What**: Based on the column structure, this table was designed to hold one row per customer capturing their registration event as a combined customer-profile + action record.

**Columns Involved**: `CID`, `Registered`, `IsReal`, `ActionTypeID`, `PlatformTypeID`, `Amount`, `DateID`, `TimeID`, `StatusID`, `PlatformID`

**Rules**:
- DateID would be YYYYMMDD integer derived from Registered (matching the DWH pattern seen in Fact_CustomerAction)
- TimeID would be the hour portion of Registered (matching the DATEPART(HOUR, Registered) pattern in SP_Fact_CustomerAction_DL_To_Synapse line 331)
- ActionTypeID=41 (Customer Registration) would be the expected value for a registration event (from Dim_ActionType)
- This structure mirrors how SP_Fact_CustomerAction_DL_To_Synapse computes DateID and TimeID from the CustomerStatic.Registered column, confirming the design intent

**Diagram**:
```
etoro.Customer.CustomerStatic
       |
       v (never implemented)
DWH_staging.etoro_Customer_CustomerStatic
       |
       v (no SP implemented)
DWH_dbo.CustomerStatic (0 rows)
       |
       x  NO ACTIVE ETL
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on CID ASC. ROUND_ROBIN indicates this table was not designed for JOIN-heavy workloads - it was likely intended as a staging or summary layer that gets queried directly. The table is empty; do not use it for any analytical purpose.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table has no UC representation (it is empty and abandoned). If ever populated in the future, expect daily partitioning by DateID given its column structure.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer registration events | Use Fact_CustomerAction WHERE ActionTypeID = 41 instead |
| Customer static attributes | Use Dim_Customer for dimensional lookups |
| First customer action per user | Use Fact_FirstCustomerAction |

### 3.3 Common JOINs

This table has no rows and no known active usage. No JOIN patterns documented.

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_ActionType | ON cs.ActionTypeID = dat.ActionTypeID | Resolve action type name (intended) |
| DWH_dbo.Dim_Platform | ON cs.PlatformID = dp.PlatformID | Resolve platform name (intended) |

### 3.4 Gotchas

- **Table has 0 rows** - do not use for analysis. Querying this table will always return empty results.
- **No active ETL** - there is no stored procedure that INSERT INTO DWH_dbo.CustomerStatic. The existence of DWH_staging.etoro_Customer_CustomerStatic is misleading; that staging table feeds other tables (Ext_Dim_CustomerStatic, Ext_FCA_Customer), NOT this table.
- **Use Fact_CustomerAction instead** - ActionTypeID=41 (Customer Registration) in Fact_CustomerAction is the correct table for registration event analysis.
- **ROUND_ROBIN distribution** means any future use with JOIN on CID would produce data movement in Synapse.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Customer.CustomerStatic) |
| 3 stars | Tier 2 - ETL SP code | (Tier 2 - ETL SP code) |
| 2 stars | Tier 3b - DDL structure | (Tier 3b - DDL structure) |
| 1 star | Tier 4-Inferred | [UNVERIFIED] (Tier 4 - inferred) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 - upstream wiki, Customer.CustomerStatic) |
| 2 | Registered | datetime | NO | Account registration date. Default=getdate() at production. Indexed via Idx_Customer_Customer_Registered with INCLUDE on key contact fields in production. In this DWH table, serves as the base for DateID and TimeID derivation. (Tier 1 - upstream wiki, Customer.CustomerStatic) |
| 3 | IsReal | tinyint | YES | Whether this is a real-money account (1) or demo (0). In production this is a bit column; in DWH stored as tinyint. All non-demo customers have IsReal=1. (Tier 1 - upstream wiki, Customer.CustomerStatic) |
| 4 | ActionTypeID | int | NOT NULL | Financial action type associated with this customer's registration event. Expected value: 41 (Customer Registration, from Dim_ActionType). NOT present in production Customer.CustomerStatic - this field was intended to link registration to the first action event. (Tier 3b - DDL structure) |
| 5 | PlatformTypeID | int | NOT NULL | Platform type identifier for the customer's registration platform. Likely references Dim_PlatformType or a similar dimension. NOT present in production Customer.CustomerStatic - DWH-specific field. (Tier 3b - DDL structure) |
| 6 | Amount | int | NOT NULL | [UNVERIFIED] Numeric amount associated with the registration event. Possibly an initial deposit amount or balance amount. NOT present in production Customer.CustomerStatic. Units and scale unknown since the table has 0 rows. (Tier 4 - inferred) |
| 7 | DateID | int | YES | Integer date key in YYYYMMDD format derived from the Registered datetime column. Matches the ETL pattern used in SP_Fact_CustomerAction_DL_To_Synapse (CONVERT(INT, CONVERT(VARCHAR, [Registered], 112))). (Tier 2 - ETL SP code, SP_Fact_CustomerAction_DL_To_Synapse) |
| 8 | TimeID | int | YES | Integer time key representing the hour of registration. Derived from DATEPART(HOUR, Registered) per the pattern in SP_Fact_CustomerAction_DL_To_Synapse line 331. Range: 0-23. (Tier 2 - ETL SP code, SP_Fact_CustomerAction_DL_To_Synapse) |
| 9 | StatusID | int | NOT NULL | [UNVERIFIED] Status identifier for this customer. Likely maps to account or player status. NOT present in production Customer.CustomerStatic with this name (production has AccountStatusID and PlayerStatusID separately). Intended FK target unclear. (Tier 3b - DDL structure) |
| 10 | PlatformID | int | NOT NULL | Platform identifier. In production Customer.CustomerStatic this is a nullable int with 4 known values: 0=Undefined, 1=Web, 2=IOS, 3=Android (confirmed from Dim_Platform lookup). (Tier 1 - upstream wiki, Customer.CustomerStatic) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | etoro.Customer.CustomerStatic | CID | Passthrough |
| Registered | etoro.Customer.CustomerStatic | Registered | Passthrough |
| IsReal | etoro.Customer.CustomerStatic | IsReal | Cast bit -> tinyint |
| ActionTypeID | Unknown | - | Not in production source - DWH-specific (intended join) |
| PlatformTypeID | Unknown | - | Not in production source - DWH-specific |
| Amount | Unknown | - | Not in production source - DWH-specific |
| DateID | etoro.Customer.CustomerStatic | Registered | CONVERT(INT, CONVERT(VARCHAR, Registered, 112)) |
| TimeID | etoro.Customer.CustomerStatic | Registered | DATEPART(HOUR, Registered) |
| StatusID | Unknown | - | Not in production source - DWH-specific |
| PlatformID | etoro.Customer.CustomerStatic | PlatformID | Passthrough (intended) |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic -> Generic Pipeline (daily, Override) -> Bronze/etoro/Customer/CustomerStatic/ -> DWH_staging.etoro_Customer_CustomerStatic -> ??? (no SP implemented) -> DWH_dbo.CustomerStatic (EMPTY)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Customer.CustomerStatic | 18.7M row customer master record (etoroDB-REAL) |
| Lake | Bronze/etoro/Customer/CustomerStatic/ | Daily full refresh (Override strategy, 1440 min) |
| Staging | DWH_staging.etoro_Customer_CustomerStatic | 85-column staging table with full customer profile |
| ETL | None implemented | No SP writes to DWH_dbo.CustomerStatic |
| Target | DWH_dbo.CustomerStatic | 0 rows - never populated |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (intended FK) |
| ActionTypeID | DWH_dbo.Dim_ActionType | Financial action type lookup (intended FK) |
| PlatformID | DWH_dbo.Dim_Platform | Platform lookup: 0=Undefined, 1=Web, 2=IOS, 3=Android (intended FK) |
| DateID | DWH_dbo.Dim_Date | Date dimension key YYYYMMDD (intended FK) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| None found | - | No SPs, views, or other tables reference DWH_dbo.CustomerStatic |

---

## 7. Sample Queries

### 7.1 Verify table is empty

```sql
SELECT COUNT(*) AS RowCount
FROM [DWH_dbo].[CustomerStatic]
-- Expected: 0 rows
```

### 7.2 Customer registration events (USE THIS INSTEAD)

```sql
-- Preferred alternative: Fact_CustomerAction for registration events
SELECT
    fca.CID,
    fca.DateID,
    fca.ActionTypeID,
    dat.Name AS ActionTypeName,
    fca.PlatformID
FROM [DWH_dbo].[Fact_CustomerAction] fca
JOIN [DWH_dbo].[Dim_ActionType] dat ON fca.ActionTypeID = dat.ActionTypeID
WHERE fca.ActionTypeID = 41  -- Customer Registration
ORDER BY fca.DateID DESC
```

### 7.3 Table structure inspection

```sql
-- Inspect DDL structure (table has 0 rows, no data to query)
SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable,
    c.max_length
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
JOIN sys.objects o ON c.object_id = o.object_id
WHERE o.name = 'CustomerStatic'
  AND SCHEMA_NAME(o.schema_id) = 'DWH_dbo'
ORDER BY c.column_id
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key knowledge extracted |
|--------|------|-------------------------|
| [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151/DWH+Process+Data+Sources) | Confluence | Official inventory of DWH pipeline inputs — lists `etoro.Customer.CustomerStatic` on AZR-W-DBLS-4 as a partitioned Customer schema source feeding the DWH process (confirms CustomerStatic is in the enterprise data-source catalog alongside other etoro OLTP tables). |
| [DWH User Guide](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11604167900/DWH+User+Guide) | Confluence | Describes Synapse DWH flow: lake → staging → final DWH tables — general context for where a Synapse-resident `CustomerStatic` would sit if it were ever populated. |

---

*Generated: 2026-03-19 | Quality: 6.8/10 (3½ stars) | Phases: 9/14 (P3/P6/P9/P9B skipped — empty table; P10 Atlassian refresh)*
*Tiers: 4 T1, 2 T2, 3 T3b, 0 T4-Atlassian, 1 T4-Inferred, 0 T5 | Elements: 7.5/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 8.0/10*
*Object: DWH_dbo.CustomerStatic | Type: Table | Production Source: etoro.Customer.CustomerStatic (partial)*
