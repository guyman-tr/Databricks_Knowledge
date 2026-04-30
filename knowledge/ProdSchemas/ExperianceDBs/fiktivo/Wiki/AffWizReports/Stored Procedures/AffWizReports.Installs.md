# AffWizReports.Installs

> Legacy install data extraction procedure that builds a SELECT DISTINCT clause for install events (status=1) from etoro_Install with a simpler parameter set than GetInstallsData.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended SELECT DISTINCT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffWizReports.Installs is a legacy install data extraction procedure that predates the standardized GetInstallsData SP. It builds a SELECT DISTINCT clause for install events from `fiktivo.etoro_Install` where status=1, but with a simpler parameter set that includes @ShowCategory (commented out in newer SPs).

This procedure exists as an older version of the install data extraction logic. Unlike GetInstallsData which follows the standardized parameter pattern used across all AffWizReports SPs, this SP has a more limited interface without @ShowCountryName or @ShowMarketingRegion as separate parameters. It is likely maintained for backward compatibility.

The inner subquery deduplicates on (date, status, ip, rid) and uses direct string concatenation for date parameters (not CONVERT/DATEADD pattern), which is less safe than the approach in newer SPs.

---

## 2. Business Logic

### 2.1 Legacy Install Extraction

**What**: Extracts install events with a simplified parameter interface.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@BannerId`

**Rules**:
- Filters fiktivo.etoro_Install to status=1 (successful installs)
- Deduplicates via inner SELECT DISTINCT on (date, status, ip, rid)
- Outputs AffiliateID (rid) as the primary dimension
- Optional SerialID and BannerID grouping
- Date filtering uses direct string concatenation (legacy pattern)
- No CountryID, ProviderID, DownloadID, PlayerLevel, CustomerID, Label, or Funnel dimensions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | datetime | NO | - | CODE-BACKED | Start of reporting period. Used in direct string concatenation. |
| 2 | @toDate | datetime | NO | - | CODE-BACKED | End of reporting period. Used in direct string concatenation. |
| 3 | @BannerId | int | NO | - | CODE-BACKED | Banner filter when @ShowBanner=1 and not NULL. |
| 4 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, includes date in output. |
| 5 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, includes YEAR/MONTH. |
| 6 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, includes serial as SerialID with binary collation. |
| 7 | @ShowCountryName | bit | NO | - | CODE-BACKED | Not used in body. Present for interface compatibility. |
| 8 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | Not used in body. Present for interface compatibility. |
| 9 | @ShowCategory | bit | NO | - | CODE-BACKED | Legacy parameter. When 1 (or @ShowBanner=1), includes BannerID. |
| 10 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, includes BannerID. Combined with @ShowCategory check. |
| 11 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends SELECT DISTINCT clause. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | fiktivo.etoro_Install | Table read | Install events filtered to status=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Legacy install data for allDataUnion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.Installs (procedure)
+-- fiktivo.etoro_Install (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Install | Table | Install events (status=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Legacy install data extraction |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View install events

```sql
SELECT TOP 50 date, ip, rid AS AffiliateID, serial, banner FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE status = 1 AND date >= '2026-03-01' ORDER BY date DESC
```

### 8.2 Execute the legacy installs SP

```sql
DECLARE @sql VARCHAR(MAX) = ' UNION ALL '
EXEC AffWizReports.Installs @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @ShowDate = 1, @ShowMonth = 0, @ShowSerialID = 0,
    @ShowCountryName = 0, @ShowMarketingRegion = 0, @ShowCategory = 0, @ShowBanner = 0,
    @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.3 Compare legacy vs modern install SP output

```sql
-- Both should produce equivalent results for the same parameters
DECLARE @sqlLegacy VARCHAR(MAX) = '', @sqlModern VARCHAR(MAX) = ''
EXEC AffWizReports.Installs @fromDate='2026-03-01', @toDate='2026-03-31', @BannerId=NULL,
    @ShowDate=1, @ShowMonth=0, @ShowSerialID=0, @ShowCountryName=0, @ShowMarketingRegion=0,
    @ShowCategory=0, @ShowBanner=0, @strSQL=@sqlLegacy OUTPUT
EXEC AffWizReports.GetInstallsData @fromDate='2026-03-01', @toDate='2026-03-31', @BannerId=NULL,
    @ShowDate=1, @ShowMonth=0, @ShowSerialID=0, @ShowCountryName=0, @ShowMarketingRegion=0,
    @ShowBanner=0, @strSQL=@sqlModern OUTPUT
PRINT 'Legacy: ' + @sqlLegacy
PRINT 'Modern: ' + @sqlModern
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 7/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.Installs | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.Installs.sql*
