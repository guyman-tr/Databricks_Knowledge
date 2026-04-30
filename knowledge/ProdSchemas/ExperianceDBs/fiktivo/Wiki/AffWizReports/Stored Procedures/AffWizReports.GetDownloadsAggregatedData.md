# AffWizReports.GetDownloadsAggregatedData

> Aggregates app download counts by affiliate from the etoro_Download table, inserting into a temp table and building join clauses for the AffWiz report.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for download data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetDownloadsAggregatedData computes download counts per affiliate for the Affiliate Wizard report. Downloads represent successful app installations (status=1) from the `fiktivo.etoro_Download` table, counted as distinct events per IP/date/affiliate combination.

This procedure exists to measure how many app downloads each affiliate has driven. Downloads are an early-funnel metric - preceding registrations, leads, and deposits in the customer acquisition journey.

The procedure first de-duplicates download records using SELECT DISTINCT on date, status, IP, and affiliate ID, then counts the distinct downloads per affiliate. Results are inserted into `#DownloadsAggregatedData` and a JOIN clause is appended to @strSQL. This SP has fewer dimensional parameters than most (no ProviderID, DownloadID, PlayerLevel, CustomerID, or LabelID) because download events carry less attribution metadata than post-registration events.

---

## 2. Business Logic

### 2.1 Download Deduplication and Counting

**What**: Counts unique downloads by deduplicating on IP address within date/affiliate.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@ShowDate`, `@ShowMonth`, `@ShowSerialID`, `@ShowBanner`

**Rules**:
- Inner subquery applies SELECT DISTINCT on (date, status, ip, rid) to deduplicate same-device downloads
- Only status=1 records are counted (successful downloads)
- Outer query COUNTs the deduplicated rows per affiliate
- Fewer grouping dimensions than other aggregation SPs (no Player Level, Label, Funnel, CustomerID)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | datetime | NO | - | CODE-BACKED | Start of reporting period. Filters etoro_Download.date. |
| 2 | @toDate | datetime | NO | - | CODE-BACKED | End of reporting period. Filters etoro_Download.date. |
| 3 | @BannerId | int | NO | - | CODE-BACKED | Banner filter when @ShowBanner=1 and value is not NULL. |
| 4 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, groups by download date (daily granularity). |
| 5 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, groups by YEAR and MONTH. |
| 6 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, groups by serial (SubAffiliateID) with binary collation. |
| 7 | @ShowCountryName | bit | NO | - | CODE-BACKED | Not used in grouping (downloads lack country data). Present for interface compatibility. |
| 8 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | Not used in grouping. Present for interface compatibility. |
| 9 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, groups by banner ID from the download record. |
| 10 | @Debug | bit | YES | 0 | CODE-BACKED | When 1, prints SQL and copies results to ##DownloadsAggregatedData. |
| 11 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN clause for #DownloadsAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | fiktivo.etoro_Download | Table read | Source of app download events with status, IP, affiliate ID (rid), serial, and banner |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #DownloadsAggregatedData for download count metrics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetDownloadsAggregatedData (procedure)
+-- fiktivo.etoro_Download (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Download | Table | Source of download events filtered by status=1 and date range |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for download count metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View download data

```sql
SELECT TOP 50 date, status, ip, rid AS AffiliateID, serial, banner AS BannerID
FROM fiktivo.etoro_Download WITH (NOLOCK)
WHERE status = 1 AND date >= '2026-03-01'
ORDER BY date DESC
```

### 8.2 Count downloads by affiliate

```sql
SELECT rid AS AffiliateID, COUNT(DISTINCT CONCAT(ip, CAST(date AS DATE))) AS Downloads
FROM fiktivo.etoro_Download WITH (NOLOCK)
WHERE status = 1 AND date >= '2026-03-01' AND date < '2026-04-01'
GROUP BY rid
ORDER BY Downloads DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetDownloadsAggregatedData
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
*Object: AffWizReports.GetDownloadsAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetDownloadsAggregatedData.sql*
