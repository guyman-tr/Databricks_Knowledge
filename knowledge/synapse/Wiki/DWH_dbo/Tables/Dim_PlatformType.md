# DWH_dbo.Dim_PlatformType

> Static 13-row legacy dimension mapping eToro trading platform access types (Web/Mobile/BackOffice x OpenBook/Trader/SocialAlerts) to their capability flags; migrated from the legacy DWH SQL Server, no active ETL refresh.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Legacy DWH SQL Server (DWH_Migration, one-time migration) |
| **Refresh** | None - static frozen migration table |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ProductID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_platformtype` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_PlatformType` defines the 13 access context types for the eToro trading platform - the combination of product mode (OpenBook/Trader/SocialAlerts/BackOffice/CRM) and access channel (Web Desktop, Web Mobile, Android, iOS, BackOffice) that identifies how a user was interacting with eToro when an action occurred. Each row specifies which capabilities are available for that access context via binary flags.

This table was migrated from the legacy on-premises DWH SQL Server as a one-time data migration (`DWH_Migration.Dim_PlatformType` via NoDbObjectsScripts). All `InsertDate` and `UpdateDate` values are NULL, confirming no active ETL. There is no corresponding production source table in the etoro application database.

**In modern ETL, `Dim_PlatformType` is effectively deprecated.** `SP_Fact_CustomerAction` hardcodes `PlatformTypeID = 0` (No Platform) for the majority of action types - the platform detection logic (which would map user agents to platform IDs 1-9) was commented out. The table remains for historical analytics on older Fact_CustomerAction data where PlatformTypeID was properly populated.

---

## 2. Business Logic

### 2.1 Platform Access Context Matrix

**What**: Each row defines a unique combination of Product (trading mode) + Platform (channel) + SubPlatform (specific variant). The binary flags tell BI analysts what was possible for users on that access context.

**Columns Involved**: `Product`, `Platform`, `SubPlatform`, `CanManualTrade`, `CanOpenMirror`, `CanCopyTrade`, `CanDeposit`, `CanCashout`

**Rules**:
- OpenBook (social feed) cannot manual trade, can copy/follow; Trader (trading terminal) can manual trade
- Desktop Web is the most capable (CanDeposit + CanCashout); Mobile lacks Cashout in most cases
- BackOffice/CRM contexts: all capabilities False (admin access, no trading)
- ProductID 0 and 99 = "No Platform" placeholders (different IDs but same meaning)
- ProductID 4,5,7: InDevelopment = True (feature not yet live)

**Diagram**:
```
ProductID -> Product   x Platform  x SubPlatform
    0     -> No Platform (placeholder)
    1     -> OpenBook    x Web      x DesktopWeb   (social, can deposit/cashout)
    2     -> Trader      x Web      x DesktopWeb   (full trading terminal)
    3     -> OpenBook    x Web      x MobileWeb    (social, can deposit, no cashout)
    4     -> Trader      x Web      x MobileWeb    [InDevelopment]
    5     -> OpenBook    x Mobile   x Android      [InDevelopment]
    6     -> Trader      x Mobile   x Android      (manual trade + copy trade)
    7     -> OpenBook    x Mobile   x iOS          [InDevelopment]
    8     -> Trader      x Mobile   x iOS          (manual trade + copy trade)
    9     -> SocialAlerts x Mobile  x Android      (copy trade only)
   10     -> BackOffice  x BackOffice x BackOffice (admin, no trading)
   11     -> CRM         x BackOffice x BackOffice (CRM, no trading)
   99     -> No Platform (second placeholder, same as 0)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE with CLUSTERED INDEX on ProductID. With 13 rows, any JOIN is optimal - the table is broadcast to all nodes. No performance concern.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this will be a tiny static Delta table. No partitioning needed. Broadcast join is automatic for 13-row tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode PlatformTypeID in fact data | `LEFT JOIN Dim_PlatformType pt ON fca.PlatformTypeID = pt.ProductID` |
| Find all actions on mobile platforms | `WHERE pt.Platform = 'Mobile'` after JOIN |
| Historical platform breakdown of actions | JOIN to Fact_CustomerAction on PlatformTypeID (note: most modern rows = 0) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_CustomerAction | `ON Fact_CustomerAction.PlatformTypeID = Dim_PlatformType.ProductID` | Decode platform context for customer actions (note: mostly 0 in modern data) |

### 3.4 Gotchas

- **Modern ETL hardcodes PlatformTypeID = 0** - `SP_Fact_CustomerAction` uses `0 AS PlatformTypeID` for most action types. Only historical data (pre-deprecation) has meaningful platform type values (1-11).
- **Duplicate "No Platform" rows** - ProductID 0 and 99 both represent "No Platform" with identical flag values. This appears to be a migration artifact from the legacy system.
- **All InsertDate/UpdateDate = NULL** - confirms static migration. Do not use these columns for freshness checks.
- **No active JOINs in SSDT** - no stored procedures or views in the SSDT repo JOIN to this table. It was historically a JOIN target but is now only referenced conceptually via the PlatformTypeID column in Fact_CustomerAction.
- **PlatformTypeID embedded in HistoryID** - `SP_Fact_CustomerAction` encodes PlatformTypeID into the HistoryID surrogate key (`right('00' + cast(PlatformTypeID AS VARCHAR(2)), 2)` at position 3-4). Since this is always 0, HistoryIDs are not distinguished by platform.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★ | Tier 2 | Synapse code (DDL + SP usage patterns) |
| ★★ | Tier 3 | Live data sampling |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProductID | smallint | NO | Primary key. Numeric identifier for the platform access context. Range: 0-11 and 99. 0 and 99 are "No Platform" placeholders. Maps to PlatformTypeID in Fact_CustomerAction. In modern ETL, almost all Fact_CustomerAction rows have PlatformTypeID = 0. (Tier 3 — live data sampling, DWH_Migration) |
| 2 | Product | varchar(50) | NO | Trading product / UI mode. Values observed: 'No Platform' (0,99), 'OpenBook' (1,3,5,7 - social feed), 'Trader' (2,4,6,8 - trading terminal), 'SocialAlerts' (9 - alerts app), 'BackOffice' (10 - admin), 'CRM' (11 - CRM system). (Tier 3 — live data sampling, DWH_Migration) |
| 3 | Platform | varchar(50) | NO | Access channel. Values: empty (0,99), 'Web' (1-4), 'Mobile' (5-9), 'BackOffice' (10-11). (Tier 3 — live data sampling, DWH_Migration) |
| 4 | SubPlatform | varchar(50) | NO | Specific access channel variant. Values: empty (0,99), 'DesktopWeb' (1,2), 'MobileWeb' (3,4), 'Android' (5,6,9), 'iOS' (7,8), 'BackOffice' (10,11). (Tier 3 — live data sampling, DWH_Migration) |
| 5 | CanManualTrade | bit | NO | Whether this platform context allows manual position opening/closing. True only for Trader variants: IDs 2 (Web Desktop), 6 (Android), 8 (iOS). OpenBook, SocialAlerts, BackOffice, CRM cannot manually trade. (Tier 3 — live data sampling, DWH_Migration) |
| 6 | CanOpenMirror | bit | NO | Whether this platform context allows opening a copy-trade mirror (following another trader). True for OpenBook variants: IDs 1 (DesktopWeb), 3 (MobileWeb), 5 (Android InDev), 7 (iOS InDev). (Tier 3 — live data sampling, DWH_Migration) |
| 7 | CanCopyTrade | bit | NO | Whether this platform context allows copy-trading (following/mirroring). True for: Trader Web Desktop (2), Trader Android (6), Trader iOS (8), SocialAlerts Android (9). (Tier 3 — live data sampling, DWH_Migration) |
| 8 | CanDeposit | bit | NO | Whether this platform context allows making a deposit. True for Web variants (1=OpenBook DesktopWeb, 2=Trader DesktopWeb, 3=OpenBook MobileWeb, 4=Trader MobileWeb InDev). Mobile apps do not support in-app deposits via this dimension. (Tier 3 — live data sampling, DWH_Migration) |
| 9 | CanCashout | bit | NO | Whether this platform context allows cashout/withdrawal. True only for ID 1 (OpenBook Web Desktop). False for all mobile and all BackOffice contexts. (Tier 3 — live data sampling, DWH_Migration) |
| 10 | InDevelopment | bit | NO | Whether this platform context was marked as in-development (not yet live). True for IDs 4 (Trader MobileWeb), 5 (OpenBook Android), 7 (OpenBook iOS). These features were either cancelled or released under different IDs. (Tier 3 — live data sampling, DWH_Migration) |
| 11 | InsertDate | datetime | YES | Intended ETL load timestamp. All values are NULL - confirms one-time migration load with no tracking. Do not use for freshness analysis. (Tier 2 — DDL structure, DWH_Migration) |
| 12 | UpdateDate | datetime | YES | Intended ETL update timestamp. All values are NULL - confirms no ETL has run since migration. (Tier 2 — DDL structure, DWH_Migration) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All columns | Legacy DWH SQL Server | All columns | One-time migration (varchar->bit conversion for flags) |

No upstream wiki available for legacy DWH SQL Server source.

### 5.2 ETL Pipeline

```
Legacy DWH SQL Server (on-premises)
  -> DWH_Migration.Dim_PlatformType  [Synapse migration staging table]
  -> DWH_dbo.Dim_PlatformType  [ONE-TIME MANUAL MIGRATION - no active ETL SP]
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Legacy DWH SQL Server | On-premises SQL Server DWH (pre-Synapse) |
| Migration | DWH_Migration.Dim_PlatformType | Staging DDL in NoDbObjectsScripts (varchar columns for BCP load) |
| Target | DWH_dbo.Dim_PlatformType | Static frozen 13-row dimension, no refresh |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ProductID | Legacy DWH SQL Server | Source of all 13 platform type definitions |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_CustomerAction | PlatformTypeID | FK-style reference (no enforced constraint). Note: mostly hardcoded to 0 in modern ETL. |
| DWH_dbo.SP_Fact_CustomerAction | PlatformTypeID | Used in HistoryID surrogate key construction (hardcoded 0 in all active code paths) |

---

## 7. Sample Queries

### 7.1 Display all platform access contexts with capabilities
```sql
SELECT ProductID, Product, Platform, SubPlatform,
    CanManualTrade, CanOpenMirror, CanCopyTrade, CanDeposit, CanCashout, InDevelopment
FROM [DWH_dbo].[Dim_PlatformType]
WHERE ProductID NOT IN (0, 99)  -- exclude placeholders
ORDER BY ProductID;
```

### 7.2 Fact_CustomerAction breakdown by platform (historical data only)
```sql
SELECT pt.Product, pt.Platform, pt.SubPlatform, COUNT(*) AS ActionCount
FROM [DWH_dbo].[Fact_CustomerAction] fca
LEFT JOIN [DWH_dbo].[Dim_PlatformType] pt
    ON fca.PlatformTypeID = pt.ProductID
WHERE fca.PlatformTypeID != 0  -- exclude modern rows where platform was not detected
GROUP BY pt.Product, pt.Platform, pt.SubPlatform
ORDER BY ActionCount DESC;
```

### 7.3 Find platform types that allow both manual trading and copy trading
```sql
SELECT ProductID, Product, Platform, SubPlatform
FROM [DWH_dbo].[Dim_PlatformType]
WHERE CanManualTrade = 1 AND CanCopyTrade = 1;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.8/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 2 T2, 10 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10*
*Object: DWH_dbo.Dim_PlatformType | Type: Table | Production Source: Legacy DWH SQL Server (DWH_Migration)*
