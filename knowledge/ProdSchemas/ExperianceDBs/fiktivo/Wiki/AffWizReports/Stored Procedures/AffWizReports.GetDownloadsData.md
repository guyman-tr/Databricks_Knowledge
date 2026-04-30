# AffWizReports.GetDownloadsData

> Builds the dynamic SQL SELECT DISTINCT clause for individual download records, contributing rows to the report's allDataUnion dataset.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended SELECT DISTINCT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetDownloadsData builds the raw download event query fragment for the AffWiz report. It produces SELECT DISTINCT rows for each download event from `fiktivo.etoro_Download`, contributing to the orchestrator's allDataUnion.

Download events represent app installations (status=1) tracked by the affiliate system. Each record links a download to an affiliate (rid) with optional sub-affiliate (serial) and banner tracking. This SP extracts dimensional rows (AffiliateID, Date, SerialID, BannerID) with NULL placeholders for dimensions not available in download data (CountryID, ProviderID, DownloadID, PlayerLevelID, LabelID, FunnelID, CustomerID).

The inner subquery deduplicates on (date, status, ip, rid) to avoid counting the same physical download multiple times.

---

## 2. Business Logic

### 2.1 Download Deduplication

**What**: Deduplicates download records by unique IP/date/affiliate combination.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`

**Rules**:
- Inner SELECT DISTINCT removes duplicate downloads from same IP on same day for same affiliate
- Only status=1 records (successful downloads) are included
- Many dimensional columns return NULL since download events carry limited metadata

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | datetime | NO | - | CODE-BACKED | Start of reporting period. Filters etoro_Download.date. |
| 2 | @toDate | datetime | NO | - | CODE-BACKED | End of reporting period. Filters etoro_Download.date. |
| 3 | @BannerId | int | NO | - | CODE-BACKED | Banner filter when @ShowBanner=1 and not NULL. |
| 4 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, includes date. When 0, returns NULL AS Date. |
| 5 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, includes YEAR and MONTH. When 0, returns NULLs. |
| 6 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, includes serial as SerialID. When 0, returns NULL. |
| 7 | @ShowCountryName | bit | NO | - | CODE-BACKED | Not used (downloads lack country data). Present for interface compatibility. |
| 8 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | Not used. Present for interface compatibility. |
| 9 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, includes banner AS BannerID. When 0, returns NULL. |
| 10 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends SELECT DISTINCT clause for download dimensional data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | fiktivo.etoro_Download | Table read | Source of download events |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Contributes download rows to allDataUnion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetDownloadsData (procedure)
+-- fiktivo.etoro_Download (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Download | Table | Source of download event records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for download dimensional rows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View raw download events

```sql
SELECT TOP 50 date, status, ip, rid AS AffiliateID, serial, banner
FROM fiktivo.etoro_Download WITH (NOLOCK)
WHERE status = 1 AND date >= '2026-03-01'
ORDER BY date DESC
```

### 8.2 Build download data SQL fragment

```sql
DECLARE @sql VARCHAR(MAX) = ' UNION ALL '
EXEC AffWizReports.GetDownloadsData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @ShowDate = 1, @ShowMonth = 0,
    @ShowSerialID = 0, @ShowCountryName = 0,
    @ShowMarketingRegion = 0, @ShowBanner = 0,
    @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.3 Count distinct download dimensions

```sql
SELECT COUNT(*) AS DistinctDownloads
FROM (
    SELECT DISTINCT CAST(date AS DATE) AS d, ip, rid
    FROM fiktivo.etoro_Download WITH (NOLOCK)
    WHERE status = 1 AND date >= '2026-03-01' AND date < '2026-04-01'
) x
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetDownloadsData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetDownloadsData.sql*
