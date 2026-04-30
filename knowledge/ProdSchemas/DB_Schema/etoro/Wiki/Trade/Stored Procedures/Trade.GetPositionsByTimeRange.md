# Trade.GetPositionsByTimeRange

> Returns newly opened or recently closed positions within a date range for hedge server notification processing - two modes controlled by @NotificationType.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate/@EndDate + @NotificationType - time window and notification mode |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPositionsByTimeRange` returns position events in a time range for hedge notification processing. Two modes: (1) @NotificationType=1 returns positions opened in the window (from Trade.PositionTbl); (2) @NotificationType=2 returns positions closed or partially closed in the window (from History.PositionSlim).

**WHY:** Hedge servers need to know about position events (opens and closes) to update their hedge positions. Rather than polling all positions, they query for events in a recent time window. This SP provides the minimal position event data needed: PositionID, InstrumentID, HedgeServerID, and timestamps.

**HOW:** Simple branching IF: mode 1 queries Trade.PositionTbl WHERE Occurred BETWEEN dates (all positions, no status filter); mode 2 queries History.PositionSlim WHERE CloseOccurred BETWEEN dates (includes partial closes). Both use NOLOCK.

**Note:** Mode 1 does NOT filter by StatusID - it returns positions regardless of whether they are still open or have since closed. This gives the hedge server all positions that were OPENED in the window.

---

## 2. Business Logic

### 2.1 Mode 1 - Open Notifications (@NotificationType=1)

**What:** Positions that were opened in the time range.

**Rules:**
- `FROM Trade.PositionTbl WHERE Occurred BETWEEN @StartDate AND @EndDate`
- No StatusID filter - includes positions that opened and may have since closed
- Returns: PositionID, InstrumentID, HedgeServerID, Occurred AS OpenOccurred

### 2.2 Mode 2 - Close/Partial Close Notifications (@NotificationType=2)

**What:** Positions that were closed or partially closed in the time range.

**Rules:**
- `FROM History.PositionSlim WHERE CloseOccurred BETWEEN @StartDate AND @EndDate`
- Includes partial closes (OriginalPositionID set for partial close child records)
- Returns: PositionID, InstrumentID, HedgeServerID, OriginalPositionID, OpenOccurred, CloseOccurred

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the notification window. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the notification window. |
| 3 | @NotificationType | TINYINT | NO | - | CODE-BACKED | 1=Open notifications (Trade.PositionTbl); 2=Close/Partial Close (History.PositionSlim). |

**Output - Mode 1 (@NotificationType=1):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | Position opened in the window. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being traded. |
| 6 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server responsible for this position. |
| 7 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | When the position was opened (Occurred alias). |

**Output - Mode 2 (@NotificationType=2):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 8 | PositionID | BIGINT | NO | - | CODE-BACKED | Position closed in the window. |
| 9 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument. |
| 10 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server for this position. |
| 11 | OriginalPositionID | BIGINT | YES | - | CODE-BACKED | For partial closes: the original position ID before the partial close split. NULL for full closes. |
| 12 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | When the position was originally opened. |
| 13 | CloseOccurred | DATETIME | YES | - | CODE-BACKED | When the position was closed (trigger for mode 2 filter). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate/@EndDate | Trade.PositionTbl | Lookup | Opened positions (mode 1) |
| @StartDate/@EndDate | History.PositionSlim | Lookup | Closed/partial-close positions (mode 2) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by hedge server notification polling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsByTimeRange (procedure)
|- Trade.PositionTbl (table) - mode 1: opened positions
|- History.PositionSlim (table) - mode 2: closed positions
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by hedge server notification polling |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @NotificationType = 1 vs 2 | Branch | Different tables and columns per mode |
| No StatusID filter (mode 1) | Design | Returns all opened positions, not just still-open |
| BETWEEN @StartDate AND @EndDate | Range | Inclusive on both ends |
| WITH (NOLOCK) | Performance | Dirty read acceptable for notification polling |

---

## 8. Sample Queries

### 8.1 Open notifications for last 5 minutes

```sql
EXEC Trade.GetPositionsByTimeRange
    @StartDate = DATEADD(MINUTE, -5, GETUTCDATE()),
    @EndDate = GETUTCDATE(),
    @NotificationType = 1
```

### 8.2 Close notifications for last 5 minutes

```sql
EXEC Trade.GetPositionsByTimeRange
    @StartDate = DATEADD(MINUTE, -5, GETUTCDATE()),
    @EndDate = GETUTCDATE(),
    @NotificationType = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 7.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsByTimeRange | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsByTimeRange.sql*
