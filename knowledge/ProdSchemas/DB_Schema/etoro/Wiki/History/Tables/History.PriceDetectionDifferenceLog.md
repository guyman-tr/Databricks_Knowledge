# History.PriceDetectionDifferenceLog

> High-frequency log of price anomaly detection events, recording each instance where the active price feed diverges from secondary feeds beyond a configured threshold - capturing instrument, provider, price, and severity.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | NotificationLogID (INT IDENTITY, clustered PK) |
| **Partition** | No (ON [HISTORY] filegroup) |
| **Indexes** | 1 (1 clustered PK) |

---

## 1. Business Meaning

`History.PriceDetectionDifferenceLog` is the technical event store for the price anomaly detection system. The trading platform continuously compares the active price feed (the feed currently used for executions) against secondary/backup feeds. When the active feed's price diverges from secondary feeds by more than a configured threshold, a price anomaly event is logged here with the instrument ID, active provider ID, the active provider's price at that moment, the severity classification, and the timestamp.

This table exists to give operations teams a queryable, time-series record of price feed quality issues. With 1.6 million rows (and actively growing - new rows added every few seconds for instrument 100024 in the live environment), it is a high-frequency monitoring log. Operations can identify which instruments experience frequent price discrepancies, which providers are most often the outlier, and how severity patterns change over time.

Each row is paired 1:1 with `History.PriceDetectionNotificationLog` via `NotificationLogID` - the same IDENTITY value is inserted into both tables for each event. The DifferenceLog holds the technical data (prices, providers, instruments), while the NotificationLog holds the human-readable alert content (email subject/body). Both are written together by the price detection service, which is an external application (no SSDT procedures reference these tables - the writer is outside the SSDT project).

---

## 2. Business Logic

### 2.1 Price Feed Anomaly Classification

**What**: Each price detection event is classified by severity based on the magnitude of the price discrepancy between the active feed and secondary feeds.

**Columns/Parameters Involved**: `NotificationSeverityTypeID`, `ActiveProviderPrice`, `InstrumentID`

**Rules**:
- NotificationSeverityTypeID is a FK to Dictionary.DowntimeSeverity: 1=Critical, 2=High, 3=Medium, 4=Low
- The SUBJECT text in the paired NotificationLog describes the DIRECTION of the anomaly ("Low Price Problem Alert" or "High Price Problem Alert") - meaning the active feed's price is either too low or too high vs secondary feeds
- SeverityTypeID=1 (Critical): ~712K rows (44%) - most common; corresponds to "Low Price Problem Alert" in notifications
- SeverityTypeID=2 (High): ~509K rows (31%)
- SeverityTypeID=3 (Medium): ~400K rows (25%) - corresponds to "High Price Problem Alert" in notifications
- SeverityTypeID=4 (Low): ~9K rows (<1%) - rarest anomaly severity

**Diagram**:
```
Price Detection Service (external application)
    |
    +-> Compares ActiveProvider price vs SecondaryFeed prices
    |
    +-> If divergence detected:
        |
        +-> Determine SeverityType (1=Critical, 2=High, 3=Medium, 4=Low)
        +-> INSERT History.PriceDetectionDifferenceLog  <- THIS TABLE (technical data)
        +-> INSERT History.PriceDetectionNotificationLog (alert subject/body)
        +-> [optionally] Send email/alert to operations
```

### 2.2 1:1 Link with NotificationLog

**What**: Every row in this table has a corresponding row in History.PriceDetectionNotificationLog sharing the same NotificationLogID.

**Columns/Parameters Involved**: `NotificationLogID`

**Rules**:
- NotificationLogID is IDENTITY(1,1) in THIS table - it generates the shared ID
- The same NotificationLogID is inserted into PriceDetectionNotificationLog as a non-identity PK
- To get the full picture of any event: JOIN these two tables on NotificationLogID
- Both tables are inserted in the same transaction by the price detection service

---

## 3. Data Overview

1,631,056 rows. Actively written - new rows appear every few seconds in live environment.

| NotificationLogID | NotificationSeverityTypeID | InstrumentID | ActiveProviderID | ActiveProviderPrice | Occurred |
|---|---|---|---|---|---|
| 1639034 | 1 (Critical) | 100024 | 21 | 518.65 | 2026-03-21 09:46:50 |
| 1639033 | 1 (Critical) | 100024 | 21 | 518.65 | 2026-03-21 09:46:28 |
| 1639032 | 3 (Medium) | 100024 | 21 | 518.65 | 2026-03-21 09:46:18 |
| 1639031 | 2 (High) | 100024 | 21 | 518.64 | 2026-03-21 09:46:14 |
| 1639030 | 1 (Critical) | 100024 | 21 | 518.65 | 2026-03-21 09:46:10 |

*Instrument 100024 with ProviderID=21 is generating multiple anomaly events per minute. The same instrument/provider appears repeatedly with varying severity levels, indicating ongoing feed quality monitoring.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationLogID | int IDENTITY(1,1) | NO | auto | VERIFIED | Auto-incrementing PK (NOT FOR REPLICATION). This IDENTITY value is the shared key between this table and History.PriceDetectionNotificationLog - the same ID is inserted into both tables for each price anomaly event. Provides the 1:1 link. |
| 2 | NotificationSeverityTypeID | int | NO | - | VERIFIED | Severity of the price discrepancy. FK to Dictionary.DowntimeSeverity: 1=Critical, 2=High, 3=Medium, 4=Low. Distribution in live data: 44% Critical, 31% High, 25% Medium, <1% Low. Note: the alert SUBJECT in NotificationLog describes the direction (Low/High price) - severity here indicates the magnitude of discrepancy. |
| 3 | InstrumentID | int | NO | - | VERIFIED | Financial instrument for which the price anomaly was detected. The active feed's price for this instrument diverged from secondary feeds. Implicit FK to instrument lookup. |
| 4 | ActiveProviderID | int | NO | - | VERIFIED | ID of the active price feed provider whose price is the outlier. This is the provider currently supplying execution prices for the instrument. Implicit FK to provider lookup. The notification body identifies the provider with descriptive name (e.g., "ProviderARS#21: ZBFX Price1(69)"). |
| 5 | ActiveProviderPrice | float | NO | - | VERIFIED | The price reported by the active provider at the time the anomaly was detected. This is the price that differs from secondary feeds. Stored as float (not dtPrice) - this is a raw feed price used for detection comparison, not for execution. |
| 6 | Occurred | datetime | NO | getdate() | VERIFIED | Local server timestamp when the anomaly was logged. DEFAULT getdate() (not UTC). Corresponds to the "Time of check" reported in the notification body. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NotificationSeverityTypeID | Dictionary.DowntimeSeverity | FK (FK_HistoryDifferenceLog_DictionaryDowntimeSeverity) | Severity classification of the price anomaly |
| InstrumentID | Instrument lookup | Implicit | Instrument with the price feed discrepancy |
| ActiveProviderID | Provider lookup | Implicit | The feed provider whose price was anomalous |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PriceDetectionNotificationLog | NotificationLogID | 1:1 companion | Shares this table's IDENTITY as its own PK - provides alert subject/body |
| History.PriceDetectionProviderDifferenceLog | (via NotificationLogID) | Dependent | Batch #11 object #11 - extends this log with per-provider comparison details |
| Price detection service (external) | INSERT | WRITER | External application writes rows - not represented in SSDT |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PriceDetectionDifferenceLog (table)
(leaf - no code-level dependencies)
```

FK dependency: Dictionary.DowntimeSeverity (enforced by FK_HistoryDifferenceLog_DictionaryDowntimeSeverity).

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.DowntimeSeverity | Table | FK target for NotificationSeverityTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PriceDetectionNotificationLog | Table | Uses NotificationLogID from this table as its PK (1:1 relationship) |
| History.PriceDetectionProviderDifferenceLog | Table | Extends this table with per-provider feed details (Batch 11, #11) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_History_PriceDetectionDifferenceLog | CLUSTERED PK | NotificationLogID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_HistoryDifferenceLog_DictionaryDowntimeSeverity | FK | NotificationSeverityTypeID -> Dictionary.DowntimeSeverity(DowntimeSeverityID) |
| DF__History__PriceDetectionDifferenceLog__Occurred | DEFAULT | `getdate()` on Occurred |

---

## 8. Sample Queries

### 8.1 Recent price anomalies for a specific instrument

```sql
SELECT
    ddl.NotificationLogID,
    ds.Name AS Severity,
    ddl.ActiveProviderID,
    ddl.ActiveProviderPrice,
    ddl.Occurred,
    dnl.Subject
FROM History.PriceDetectionDifferenceLog ddl WITH (NOLOCK)
JOIN Dictionary.DowntimeSeverity ds WITH (NOLOCK) ON ds.DowntimeSeverityID = ddl.NotificationSeverityTypeID
LEFT JOIN History.PriceDetectionNotificationLog dnl WITH (NOLOCK) ON dnl.NotificationLogID = ddl.NotificationLogID
WHERE ddl.InstrumentID = @InstrumentID
ORDER BY ddl.Occurred DESC
```

### 8.2 Anomaly count by instrument and severity (last 24 hours)

```sql
SELECT
    ddl.InstrumentID,
    ds.Name AS Severity,
    COUNT(*) AS EventCount
FROM History.PriceDetectionDifferenceLog ddl WITH (NOLOCK)
JOIN Dictionary.DowntimeSeverity ds WITH (NOLOCK) ON ds.DowntimeSeverityID = ddl.NotificationSeverityTypeID
WHERE ddl.Occurred >= DATEADD(HOUR, -24, GETDATE())
GROUP BY ddl.InstrumentID, ds.Name
ORDER BY EventCount DESC
```

### 8.3 Most problematic providers by critical event count

```sql
SELECT
    ddl.ActiveProviderID,
    COUNT(*) AS CriticalEventCount,
    MAX(ddl.Occurred) AS MostRecent
FROM History.PriceDetectionDifferenceLog ddl WITH (NOLOCK)
WHERE ddl.NotificationSeverityTypeID = 1  -- Critical only
  AND ddl.Occurred >= DATEADD(DAY, -7, GETDATE())
GROUP BY ddl.ActiveProviderID
ORDER BY CriticalEventCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PriceDetectionDifferenceLog | Type: Table | Source: etoro/etoro/History/Tables/History.PriceDetectionDifferenceLog.sql*
