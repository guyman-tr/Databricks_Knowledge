# AffiliateCommission.UpsertAppsflyerReportStatus

> Inserts or updates Appsflyer report status tracking records using a MERGE operation, maintaining the date range and last record date for each application.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | MERGE on AppsflyerReportStatus by AppID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure maintains the synchronization state of Appsflyer report data imports. Appsflyer is a mobile attribution and marketing analytics platform, and the affiliate commission system periodically pulls reports from it for each registered application. This procedure tracks the date ranges covered by each import and the timestamp of the last record received.

When a report is pulled for an application, this procedure is called with the AppID and the date range of the report. If the AppID already exists in the tracking table, the date range and last record date are updated. If it is a new AppID, a new tracking record is inserted. This upsert behavior is implemented using the SQL MERGE statement.

Maintaining accurate report status is essential for ensuring complete data coverage. The commission engine needs to know what time periods have been imported from Appsflyer to avoid gaps in attribution data that could lead to missed or incorrect commissions.

---

## 2. Business Logic

### 2.1 MERGE Upsert Pattern

**What**: Uses a MERGE statement to insert a new AppsflyerReportStatus record if the AppID does not exist, or update the existing record if it does.

**Columns/Parameters Involved**: @AppID, @FromDate, @ToDate, @LastRecordDate

**Rules**:
- Match key: TARGET.AppID = SOURCE.AppID
- WHEN MATCHED: Updates FromDate, ToDate, and LastRecordDate with the new values
- WHEN NOT MATCHED BY TARGET: Inserts a new record with AppID, FromDate, ToDate, LastRecordDate
- This ensures exactly one record per AppID at all times

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AppID | VARCHAR(1000) | No | - | CODE-BACKED | Appsflyer application identifier |
| 2 | @FromDate | DATETIME | No | - | CODE-BACKED | Start date of the report period |
| 3 | @ToDate | DATETIME | No | - | CODE-BACKED | End date of the report period |
| 4 | @LastRecordDate | DATETIME | No | - | CODE-BACKED | Timestamp of the most recent record in the report |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AppID | AffiliateCommission.AppsflyerReportStatus | MERGE target | Inserts or updates report status by AppID |

### 5.2 Referenced By (other objects point to this)

Called by the Appsflyer data import service after each report pull to record the synchronization state.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpsertAppsflyerReportStatus
  --> AffiliateCommission.AppsflyerReportStatus (MERGE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.AppsflyerReportStatus | Table | MERGE target - inserts or updates report status records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Appsflyer import service | Application | Calls this SP after each report pull |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Upsert a report status for an application
```sql
EXEC AffiliateCommission.UpsertAppsflyerReportStatus
    @AppID = 'com.example.tradingapp',
    @FromDate = '2026-04-01',
    @ToDate = '2026-04-12',
    @LastRecordDate = '2026-04-12 08:30:00';
```

### 8.2 Check current report status for all applications
```sql
SELECT AppID, FromDate, ToDate, LastRecordDate
FROM AffiliateCommission.AppsflyerReportStatus WITH (NOLOCK);
```

### 8.3 Find applications with stale report data
```sql
SELECT AppID, FromDate, ToDate, LastRecordDate
FROM AffiliateCommission.AppsflyerReportStatus WITH (NOLOCK)
WHERE LastRecordDate < DATEADD(DAY, -7, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpsertAppsflyerReportStatus | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpsertAppsflyerReportStatus.sql*
