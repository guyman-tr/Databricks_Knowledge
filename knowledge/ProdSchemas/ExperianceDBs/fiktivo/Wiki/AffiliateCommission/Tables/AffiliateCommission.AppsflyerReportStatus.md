# AffiliateCommission.AppsflyerReportStatus

> Tracks the last-fetched time window for AppsFlyer attribution reports per mobile app, enabling incremental data pulls without re-processing historical records.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint, IDENTITY) |
| **Partition** | No |
| **Indexes** | 2 active (CDX on ID, NC on AppID with INCLUDE) |

---

## 1. Business Meaning

AppsflyerReportStatus is a watermark/cursor table that tracks the progress of data synchronization with AppsFlyer, a mobile attribution and marketing analytics platform. Each row represents one mobile application (identified by AppID) and records the time window of the last successfully fetched report from AppsFlyer's API.

This table exists to support incremental data pulls. When the affiliate commission system queries AppsFlyer for attribution data (which affiliates drove which mobile app installations), it needs to know where the last pull left off. Without this table, the system would either re-fetch all historical data on every run (expensive and slow) or risk missing records during gaps.

The table is maintained by UpsertAppsflyerReportStatus (MERGE pattern - inserts new apps or updates existing ones) and queried by GetAppsflyerReportStatus to determine the next fetch window. Currently contains only 2 rows - one per tracked mobile app (Android and iOS). Data dates from March 2023, suggesting the AppsFlyer integration may be dormant in this environment.

---

## 2. Business Logic

### 2.1 Incremental Fetch Window

**What**: Each app tracks a sliding time window (FromDate to ToDate) representing the last successfully fetched report period.

**Columns/Parameters Involved**: `AppID`, `FromDate`, `ToDate`, `LastRecordDate`

**Rules**:
- GetAppsflyerReportStatus reads the current window for a given AppID
- The consuming service uses ToDate as the starting point for the next fetch
- After a successful fetch, UpsertAppsflyerReportStatus advances the window
- LastRecordDate tracks the timestamp of the most recent record within the fetched data (may differ from ToDate)

**Diagram**:
```
Time -->
|----[FromDate]=========[ToDate]-----|
                                     |----[NextFromDate]=====[NextToDate]---|
                                     ^
                                LastRecordDate marks last actual data point
```

---

## 3. Data Overview

| ID | AppID | FromDate | ToDate | LastRecordDate | Meaning |
|---|---|---|---|---|---|
| 1 | id674984916 | 2023-03-27 07:40 | 2023-03-28 13:40 | 2023-03-28 13:40 | iOS app (Apple App Store ID). 30-hour fetch window. LastRecordDate equals ToDate - data was complete up to window end. |
| 2 | com.etoro.openbook | 2023-03-27 01:40 | 2023-03-28 07:40 | 2023-03-28 07:41 | Android app (Google Play package). 30-hour fetch window. LastRecordDate slightly after ToDate - possibly includes a record at the boundary. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. Not used in business logic - AppID is the natural key used by the MERGE pattern in UpsertAppsflyerReportStatus. |
| 2 | AppID | varchar(1000) | NO | - | CODE-BACKED | AppsFlyer application identifier. For iOS apps this is the Apple App Store numeric ID (e.g., "id674984916"). For Android apps this is the Google Play package name (e.g., "com.etoro.openbook"). Used as the MERGE match key. Indexed for lookup performance. |
| 3 | FromDate | datetime | NO | - | CODE-BACKED | Start of the last successfully fetched report time window. Represents the earliest timestamp in the most recent data pull from AppsFlyer. Updated by UpsertAppsflyerReportStatus after each successful fetch. |
| 4 | ToDate | datetime | NO | - | CODE-BACKED | End of the last successfully fetched report time window. The next incremental pull should start from this point. Updated by UpsertAppsflyerReportStatus after each successful fetch. |
| 5 | LastRecordDate | datetime | NO | - | CODE-BACKED | Timestamp of the most recent actual data record within the fetched window. May differ slightly from ToDate if the last record falls before or at the window boundary. Provides a secondary checkpoint for data completeness verification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. AppID is an external identifier from AppsFlyer, not a FK.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.UpsertAppsflyerReportStatus | MERGE | Writer/Modifier | Upserts the fetch window after each successful data pull |
| AffiliateCommission.GetAppsflyerReportStatus | SELECT | Reader | Reads current window for a given AppID to determine next fetch start |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.UpsertAppsflyerReportStatus | Stored Procedure | Writer - MERGE upsert of fetch window |
| AffiliateCommission.GetAppsflyerReportStatus | Stored Procedure | Reader - retrieves current window by AppID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CDX_AffiliateCommissionAppsflyerReportStatus_ID | CLUSTERED | ID ASC | - | - | Active |
| IDX_AffiliateCommissionAppsflyerReportStatus_AppID | NONCLUSTERED | AppID ASC | FromDate, ToDate | - | Active |

### 7.2 Constraints

None beyond NOT NULL column constraints. No explicit PK constraint defined (relies on clustered index). Data compression: PAGE on both the table and clustered index.

---

## 8. Sample Queries

### 8.1 Get current fetch window for an app
```sql
SELECT AppID, FromDate, ToDate, LastRecordDate
FROM AffiliateCommission.AppsflyerReportStatus WITH (NOLOCK)
WHERE AppID = 'com.etoro.openbook';
```

### 8.2 Check all tracked apps and their last sync times
```sql
SELECT AppID,
       FromDate,
       ToDate,
       LastRecordDate,
       DATEDIFF(day, ToDate, GETUTCDATE()) AS DaysSinceLastSync
FROM AffiliateCommission.AppsflyerReportStatus WITH (NOLOCK)
ORDER BY ToDate DESC;
```

### 8.3 Identify apps with stale sync windows
```sql
SELECT AppID, ToDate,
       DATEDIFF(hour, ToDate, GETUTCDATE()) AS HoursBehind
FROM AffiliateCommission.AppsflyerReportStatus WITH (NOLOCK)
WHERE DATEDIFF(hour, ToDate, GETUTCDATE()) > 48
ORDER BY ToDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.AppsflyerReportStatus | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.AppsflyerReportStatus.sql*
