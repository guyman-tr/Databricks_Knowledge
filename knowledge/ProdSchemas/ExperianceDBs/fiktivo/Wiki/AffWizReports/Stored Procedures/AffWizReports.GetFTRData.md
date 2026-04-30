# AffWizReports.GetFTRData

> Builds the dynamic SQL SELECT DISTINCT clause for individual First Time Run (status=3) records from etoro_Install, contributing rows to allDataUnion.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended SELECT DISTINCT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFTRData builds the raw First Time Run event query fragment. FTR events (status=3 in etoro_Install) represent the first time a customer actually launches the app after installation. This SP extracts dimensional rows with NULL placeholders for most dimensions (CountryID, ProviderID, DownloadID, PlayerLevelID, LabelID, FunnelID, CustomerID are all NULL since FTR events lack this metadata).

The inner subquery deduplicates on (date, status, ip, rid) and filters to status=3. Date range uses BETWEEN.

---

## 2. Business Logic

### 2.1 FTR Dimensional Extraction

**What**: Extracts FTR events as dimensional rows with limited metadata.

**Rules**:
- status=3 filter for First Time Run events
- Most dimensional columns return NULL (FTR events carry minimal data)
- Only AffiliateID (rid), SerialID, Date, and BannerID are available

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
| 4 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, includes date. When 0, NULL. |
| 5 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, includes YEAR/MONTH. When 0, NULLs. |
| 6 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, includes serial as SerialID. When 0, NULL. |
| 7 | @ShowCountryName | bit | NO | - | CODE-BACKED | Not used. Returns NULL always. |
| 8 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | Not used. Interface compatibility. |
| 9 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, includes BannerID. |
| 10 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends SELECT DISTINCT clause. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | fiktivo.etoro_Install | Table read | Install events filtered to status=3 (FTR) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Contributes FTR rows to allDataUnion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetFTRData (procedure)
+-- fiktivo.etoro_Install (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Install | Table | Install events (status=3) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for FTR dimensional rows |

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
SELECT TOP 50 date, ip, rid AS AffiliateID, serial, banner FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE status = 3 AND date >= '2026-03-01' ORDER BY date DESC
```

### 8.2 Build FTR data SQL fragment

```sql
DECLARE @sql VARCHAR(MAX) = ' UNION ALL '
EXEC AffWizReports.GetFTRData @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @ShowDate = 1, @ShowMonth = 0, @ShowSerialID = 0,
    @ShowCountryName = 0, @ShowMarketingRegion = 0, @ShowBanner = 0, @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.3 Compare Install vs FTR counts

```sql
SELECT status, COUNT(DISTINCT CONCAT(ip, CAST(date AS DATE), rid)) AS UniqueEvents
FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE date >= '2026-03-01' AND date < '2026-04-01' AND status IN (1, 3)
GROUP BY status
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 7/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetFTRData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetFTRData.sql*
