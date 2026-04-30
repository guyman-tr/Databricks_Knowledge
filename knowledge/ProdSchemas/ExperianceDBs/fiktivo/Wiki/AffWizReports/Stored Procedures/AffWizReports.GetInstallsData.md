# AffWizReports.GetInstallsData

> Builds the dynamic SQL SELECT DISTINCT clause for individual install records (status=1) from etoro_Install, contributing rows to allDataUnion.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended SELECT DISTINCT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetInstallsData builds the raw install event query fragment for the AffWiz report. It extracts SELECT DISTINCT rows from `fiktivo.etoro_Install` filtered to status=1 (successful installs), with deduplication via inner subquery on (date, status, ip, rid).

Most dimensional columns return NULL since install events carry limited metadata. Only AffiliateID (rid), SerialID, Date, and BannerID are available. Date range uses BETWEEN.

---

## 2. Business Logic

### 2.1 Install Dimensional Extraction

**What**: Extracts install events as dimensional rows with limited metadata.

**Rules**:
- status=1 filter for successful installs
- CountryID, ProviderID, DownloadID, PlayerLevelID, LabelID, FunnelID, CustomerID all return NULL

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
| 5 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, includes YEAR/MONTH. |
| 6 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, includes serial as SerialID. |
| 7 | @ShowCountryName | bit | NO | - | CODE-BACKED | Not used. Returns NULL. |
| 8 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | Not used. Interface compatibility. |
| 9 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, includes BannerID. |
| 10 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends SELECT DISTINCT clause. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | fiktivo.etoro_Install | Table read | Install events (status=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Contributes install rows to allDataUnion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetInstallsData (procedure)
+-- fiktivo.etoro_Install (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Install | Table | Install events (status=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for install dimensional rows |

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
SELECT TOP 50 date, ip, rid AS AffiliateID, serial, banner FROM fiktivo.etoro_Install WITH (NOLOCK) WHERE status = 1 AND date >= '2026-03-01' ORDER BY date DESC
```

### 8.2 Build installs data SQL fragment

```sql
DECLARE @sql VARCHAR(MAX) = ' UNION ALL '
EXEC AffWizReports.GetInstallsData @fromDate = '2026-03-01', @toDate = '2026-03-31', @BannerId = NULL,
    @ShowDate = 1, @ShowMonth = 0, @ShowSerialID = 0, @ShowCountryName = 0, @ShowMarketingRegion = 0, @ShowBanner = 0, @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.3 Count installs vs FTR

```sql
SELECT status, COUNT(*) FROM fiktivo.etoro_Install WITH (NOLOCK) WHERE date >= '2026-03-01' AND date < '2026-04-01' AND status IN (1,3) GROUP BY status
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 7/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetInstallsData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetInstallsData.sql*
