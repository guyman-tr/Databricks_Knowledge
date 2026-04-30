# AffiliateCommission.GetAppsflyerReportStatus

> Simple lookup procedure that retrieves the last-fetched time window for an AppsFlyer mobile attribution report, enabling incremental data pulls.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns FromDate, ToDate, LastRecordDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAppsflyerReportStatus retrieves the date range watermark for a specific mobile app's AppsFlyer attribution report. The AppsFlyer integration pulls mobile install attribution data (which affiliates drove which app installations) in incremental batches. This procedure returns the time window of the last successful pull so the next fetch can start where it left off.

This procedure exists as the read counterpart to UpsertAppsflyerReportStatus (which writes/updates the watermarks). Together they implement a cursor pattern for incremental data synchronization with the AppsFlyer external API.

Data comes from the AppsflyerReportStatus table, which currently has only 2 rows (one per tracked mobile app - typically Android and iOS).

---

## 2. Business Logic

### 2.1 Watermark Retrieval

**What**: Returns the time window boundaries for the last successful AppsFlyer report fetch.

**Columns/Parameters Involved**: `@AppID`, `FromDate`, `ToDate`, `LastRecordDate`

**Rules**:
- Looks up AppsflyerReportStatus by AppID (the mobile app identifier in AppsFlyer)
- FromDate = start of the last successfully fetched period
- ToDate = end of the last successfully fetched period
- LastRecordDate = timestamp of the most recent record within that period
- The caller uses ToDate as the starting point for the next incremental fetch
- Returns empty result set if AppID not found (new app, not yet tracked)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AppID | varchar(1000) (IN) | NO | - | CODE-BACKED | The AppsFlyer application identifier (e.g., mobile app bundle ID). Matched against AppsflyerReportStatus.AppID. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | FromDate | datetime | - | - | CODE-BACKED | Start of the last successfully fetched report period. The next fetch should overlap slightly for safety. |
| 3 | ToDate | datetime | - | - | CODE-BACKED | End of the last successfully fetched report period. The next fetch starts from this date. |
| 4 | LastRecordDate | datetime | - | - | CODE-BACKED | Timestamp of the most recent attribution record received in the last fetch. May differ from ToDate if the last batch had records only up to a certain point. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AppID | AffiliateCommission.AppsflyerReportStatus | READ (SELECT) | Retrieves watermark dates by AppID |

### 5.2 Referenced By (other objects point to this)

No callers found in the AffiliateCommission schema. Called by the AppsFlyer data synchronization service to determine the next fetch window.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetAppsflyerReportStatus (procedure)
+-- AffiliateCommission.AppsflyerReportStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.AppsflyerReportStatus | Table | SELECT by AppID; returns FromDate, ToDate, LastRecordDate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (AppsFlyer sync service) | External | Reads watermark before incremental data fetch |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get report status for a specific app
```sql
EXEC [AffiliateCommission].[GetAppsflyerReportStatus] @AppID = 'com.etoro.openbook'
```

### 8.2 View all app watermarks
```sql
SELECT AppID, FromDate, ToDate, LastRecordDate
FROM [AffiliateCommission].[AppsflyerReportStatus] WITH (NOLOCK)
ORDER BY ToDate DESC
```

### 8.3 Find apps with stale data (not updated in 7+ days)
```sql
SELECT AppID, FromDate, ToDate, LastRecordDate,
       DATEDIFF(DAY, ToDate, GETUTCDATE()) AS DaysSinceLastFetch
FROM [AffiliateCommission].[AppsflyerReportStatus] WITH (NOLOCK)
WHERE DATEDIFF(DAY, ToDate, GETUTCDATE()) > 7
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetAppsflyerReportStatus | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetAppsflyerReportStatus.sql*
