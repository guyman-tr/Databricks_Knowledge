# AffWizReports.GetInstallsAggregatedData

> Aggregates app install counts (status=1) by affiliate from the etoro_Install table for the AffWiz report.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for install data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetInstallsAggregatedData computes install counts per affiliate. Installs (status=1 in etoro_Install) represent successful app installations, one step deeper than downloads in the acquisition funnel. The procedure deduplicates by (date, status, ip, rid) before counting.

Results are inserted into `#InstallsAggregatedData`. Like the Downloads/FTR SPs, this has fewer dimensional parameters (no ProviderID, DownloadID, PlayerLevel, CustomerID, Label, Funnel).

---

## 2. Business Logic

### 2.1 Install Count Deduplication

**What**: Counts unique installs by deduplicating on IP/date/affiliate.

**Rules**:
- Inner SELECT DISTINCT on (date, status, ip, rid) + optional serial/banner
- Outer COUNT(*) per affiliate grouping
- status=1 filter for successful installs
- Date range uses BETWEEN

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | datetime | NO | - | CODE-BACKED | Start of reporting period. |
| 2 | @toDate | datetime | NO | - | CODE-BACKED | End of reporting period. |
| 3 | @BannerId | int | NO | - | CODE-BACKED | Banner filter. |
| 4 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, groups by date. |
| 5 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, groups by YEAR/MONTH. |
| 6 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, groups by serial. |
| 7 | @ShowCountryName | bit | NO | - | CODE-BACKED | Not used. Interface compatibility. |
| 8 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | Not used. Interface compatibility. |
| 9 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, groups by banner. |
| 10 | @Debug | bit | YES | 0 | CODE-BACKED | Debug mode flag. |
| 11 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #InstallsAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | fiktivo.etoro_Install | Table read | Install events filtered to status=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #InstallsAggregatedData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetInstallsAggregatedData (procedure)
+-- fiktivo.etoro_Install (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Install | Table | Install events (status=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for install count metrics |

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

### 8.2 Count installs by affiliate

```sql
SELECT rid AS AffiliateID, COUNT(DISTINCT CONCAT(ip, CAST(date AS DATE))) AS Installs
FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE status = 1 AND date >= '2026-03-01' AND date < '2026-04-01'
GROUP BY rid ORDER BY Installs DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetInstallsAggregatedData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @ShowDate = 0, @ShowMonth = 1,
    @ShowSerialID = 0, @ShowCountryName = 0,
    @ShowMarketingRegion = 0, @ShowBanner = 0,
    @Debug = 1, @strSQL = @sql OUTPUT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetInstallsAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetInstallsAggregatedData.sql*
