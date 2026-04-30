# History.AddPriceDetectionDifferenceLog

> Writer procedure that logs a price feed anomaly detection event into the technical event store, inserting one row into History.PriceDetectionDifferenceLog and returning the generated IDENTITY log ID.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns @@identity (the new NotificationLogID from the INSERT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.AddPriceDetectionDifferenceLog` is the write gateway for the technical side of price anomaly events. The price detection service (an external application outside the SSDT project) continuously compares the active price feed against secondary/backup feeds. When the active feed diverges beyond a configured threshold, the service calls this procedure to log the technical event: which instrument, which provider was active, what price it reported, how severe the discrepancy was, and when it occurred.

This procedure exists as a thin, safe INSERT wrapper around `History.PriceDetectionDifferenceLog`. It provides error isolation via BEGIN TRY/CATCH - if the INSERT fails for any reason (disk pressure, lock timeout), the service receives RETURN -1 rather than an exception propagating. On success it returns the new IDENTITY value (`@@identity`), which the calling service then passes to `History.AddPriceDetectionNotificationLog` as the shared `NotificationLogID` linking the two sibling log tables.

The price detection event pair is always written atomically by the external service: first this procedure (which generates the IDENTITY), then `AddPriceDetectionNotificationLog` (which receives that IDENTITY as `@ID`). This sequencing is enforced by the calling application, not by database constraints.

---

## 2. Business Logic

### 2.1 Identity-First Write Pattern

**What**: This procedure generates the shared log ID used to link all three price detection log tables.

**Columns/Parameters Involved**: `@NotificationSeverityTypeID`, return value

**Rules**:
- This procedure INSERT generates the IDENTITY(1,1) for `History.PriceDetectionDifferenceLog`
- `@@identity` is returned to the caller, who must pass it as `@ID` to `History.AddPriceDetectionNotificationLog`
- Without this ID, the two log tables cannot be JOINed - the calling service is responsible for the link
- RETURN(-1) on any error; the caller must treat -1 as failure and abort the paired insert

**Diagram**:
```
External Price Detection Service
    |
    +-> EXEC History.AddPriceDetectionDifferenceLog(...)
    |       -> INSERT History.PriceDetectionDifferenceLog
    |       -> RETURN @@identity  (e.g., 1639035)
    |
    +-> IF returned_id > 0:
    |       -> EXEC History.AddPriceDetectionNotificationLog(@ID=1639035, ...)
    |
    +-> IF returned_id = -1:
            -> Log error; skip NotificationLog insert
```

### 2.2 Error Isolation

**What**: The TRY/CATCH wrapper ensures INSERT failures return a sentinel value rather than propagating exceptions.

**Columns/Parameters Involved**: all parameters (passed to INSERT)

**Rules**:
- RETURN(@@identity): successful INSERT; value is the new NotificationLogID (always > 0)
- RETURN(-1): INSERT failed; no row was written; the paired NotificationLog should NOT be inserted
- The external service is responsible for treating -1 as a failure signal

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NotificationSeverityTypeID | int | NO | - | CODE-BACKED | Severity classification of the price anomaly. Maps to History.PriceDetectionDifferenceLog.NotificationSeverityTypeID. FK to Dictionary.DowntimeSeverity: 1=Critical, 2=High, 3=Medium, 4=Low. The price detection service calculates severity from the magnitude of the feed divergence. |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Trading instrument whose active price feed was anomalous. Maps to History.PriceDetectionDifferenceLog.InstrumentID. Implicit FK to Trade.Instrument. From live data, instrument 100024 dominates (active continuous monitoring). |
| 3 | @ActiveProviderID | int | NO | - | CODE-BACKED | ID of the price provider currently used for trade executions whose price deviated from secondary feeds. Maps to History.PriceDetectionDifferenceLog.ActiveProviderID. Implicit FK to provider lookup. |
| 4 | @ActiveProviderPrice | float | NO | - | CODE-BACKED | The price reported by the active provider at the moment of anomaly detection. This is the "outlier" price. The secondary provider prices (which disagreed with this value) are stored per-provider in History.PriceDetectionProviderDifferenceLog. |
| 5 | @Occurred | datetime | NO | - | CODE-BACKED | Timestamp when the price anomaly was detected by the external price detection service. Passed in by the caller (not DB-generated). Stored as local server time (not UTC). Matches the "Time of check" in the paired NotificationLog body. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @NotificationSeverityTypeID | History.PriceDetectionDifferenceLog | Write target | Inserts the anomaly event technical record |
| @InstrumentID | Trade.Instrument | Implicit | Identifies the instrument with the anomalous feed |
| @ActiveProviderID | Provider lookup | Implicit | Identifies the active feed provider that deviated |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External price detection service | (application call) | Application | Called by the external monitoring service whenever a price feed divergence is detected. Not referenced by any SSDT stored procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AddPriceDetectionDifferenceLog (procedure)
└── History.PriceDetectionDifferenceLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PriceDetectionDifferenceLog | Table | INSERT target - one row written per procedure call |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External price detection service | Application | Calls this procedure whenever price feed anomaly detected; uses the returned IDENTITY as the shared log ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. All constraint enforcement is in the target table (History.PriceDetectionDifferenceLog).

---

## 8. Sample Queries

### 8.1 Find recent price anomaly events written by this procedure

```sql
SELECT TOP 10
    NotificationLogID,
    NotificationSeverityTypeID,
    InstrumentID,
    ActiveProviderID,
    ActiveProviderPrice,
    Occurred
FROM History.PriceDetectionDifferenceLog WITH (NOLOCK)
ORDER BY NotificationLogID DESC
```

### 8.2 Join the two sibling log tables to see full event context

```sql
SELECT TOP 20
    d.NotificationLogID,
    d.NotificationSeverityTypeID,
    d.InstrumentID,
    d.ActiveProviderID,
    d.ActiveProviderPrice,
    n.Subject,
    d.Occurred
FROM History.PriceDetectionDifferenceLog d WITH (NOLOCK)
JOIN History.PriceDetectionNotificationLog n WITH (NOLOCK)
    ON n.NotificationLogID = d.NotificationLogID
ORDER BY d.NotificationLogID DESC
```

### 8.3 Check anomaly frequency by instrument and severity

```sql
SELECT
    d.InstrumentID,
    d.NotificationSeverityTypeID,
    COUNT(*) AS EventCount,
    MIN(d.Occurred) AS FirstSeen,
    MAX(d.Occurred) AS LastSeen
FROM History.PriceDetectionDifferenceLog d WITH (NOLOCK)
GROUP BY d.InstrumentID, d.NotificationSeverityTypeID
ORDER BY EventCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.AddPriceDetectionDifferenceLog | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.AddPriceDetectionDifferenceLog.sql*
