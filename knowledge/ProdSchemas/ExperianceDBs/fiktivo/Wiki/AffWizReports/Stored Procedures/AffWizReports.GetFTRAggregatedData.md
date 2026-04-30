# AffWizReports.GetFTRAggregatedData

> Aggregates First Time Run (FTR) install counts by affiliate from the etoro_Install table (status=3), inserting into a temp table for the AffWiz report.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for FTR data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFTRAggregatedData computes First Time Run (FTR) counts per affiliate. FTR represents the first time a customer actually launches the app after downloading and installing it (status=3 in etoro_Install, as opposed to status=1 for installs).

FTR is a deeper funnel metric than downloads or installs - it confirms the customer opened the app. This SP has fewer dimensional parameters (no ProviderID, DownloadID, PlayerLevel, CustomerID, Label, Funnel) because FTR events carry minimal metadata.

Results are inserted into `#FTRAggregatedData`.

---

## 2. Business Logic

### 2.1 FTR Count via Deduplication

**What**: Counts first-time app runs by deduplicating on IP/date/affiliate.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`

**Rules**:
- Inner subquery: SELECT DISTINCT on (date, status, ip, rid) from etoro_Install WHERE status=3
- Outer query: COUNT(*) per affiliate grouping
- status=3 = First Time Run (vs status=1 = Install)
- Date range uses BETWEEN (not the >= / < +1 pattern used by most other SPs)

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
| 6 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, groups by serial (SubAffiliateID). |
| 7 | @ShowCountryName | bit | NO | - | CODE-BACKED | Not used. Interface compatibility. |
| 8 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | Not used. Interface compatibility. |
| 9 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, groups by banner. |
| 10 | @Debug | bit | YES | 0 | CODE-BACKED | Debug mode flag. |
| 11 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #FTRAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | fiktivo.etoro_Install | Table read | Install events filtered to status=3 (First Time Run) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #FTRAggregatedData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetFTRAggregatedData (procedure)
+-- fiktivo.etoro_Install (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Install | Table | Install events filtered to status=3 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for FTR count metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View FTR events

```sql
SELECT TOP 50 date, status, ip, rid AS AffiliateID, serial, banner
FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE status = 3 AND date >= '2026-03-01'
ORDER BY date DESC
```

### 8.2 Count FTR by affiliate

```sql
SELECT rid AS AffiliateID, COUNT(DISTINCT CONCAT(ip, CAST(date AS DATE))) AS FTRCount
FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE status = 3 AND date >= '2026-03-01' AND date < '2026-04-01'
GROUP BY rid ORDER BY FTRCount DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetFTRAggregatedData
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
*Object: AffWizReports.GetFTRAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetFTRAggregatedData.sql*
