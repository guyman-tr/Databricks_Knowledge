# AffiliateCommission.ReadRegistrationUnhandledMessages

> Claims and returns stale registration queue messages that haven't been processed within 10 minutes, implementing a dead-letter recovery pattern for the registration commission pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns claimed ID + DateCreated + RegistrationMessage from queue |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ReadRegistrationUnhandledMessages is the dead-letter recovery consumer for the registration message queue. The AffiliateTraderRegistrationQueue table acts as a message queue for registration events flowing from the platform to the commission system. When messages sit for more than 10 minutes without processing, this procedure claims and returns them for retry.

This procedure follows the same pattern as ReadCreditUnhandledMessages but operates on the registration queue. It ensures no registration events are permanently lost when the primary consumer encounters failures or crashes. The 10-minute stale threshold matches the credit queue variant.

Unlike the credit variant, this procedure also returns the row ID alongside the message payload, which may be used for deduplication or tracking in the retry pipeline.

---

## 2. Business Logic

### 2.1 Stale Message Recovery

**What**: Claims registration queue messages that haven't been processed within 10 minutes.

**Columns/Parameters Involved**: `DateModified`

**Rules**:
- UPDATE sets DateModified = GETUTCDATE() to claim stale messages
- OUTPUT returns ID, DateCreated, and RegistrationMessage for reprocessing
- Stale threshold: DATEADD(minute, 10, DateModified) < GETUTCDATE()
- No batch limit - claims all stale messages
- RegistrationMessage contains the full registration event payload for resubmission

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | - | - | CODE-BACKED | Queue row identifier. Used for tracking and deduplication in retry processing. |
| 2 | DateCreated | datetime | - | - | CODE-BACKED | When the registration message was originally enqueued. |
| 3 | RegistrationMessage | nvarchar(max) | - | - | CODE-BACKED | Full registration event payload for reprocessing. Contains all data needed to resubmit the event to the registration commission pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.AffiliateTraderRegistrationQueue | READ+WRITE (UPDATE OUTPUT) | Claims stale messages by setting DateModified; outputs message data |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by a scheduled job or health-check service to recover stuck messages.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ReadRegistrationUnhandledMessages (procedure)
+-- AffiliateCommission.AffiliateTraderRegistrationQueue (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.AffiliateTraderRegistrationQueue | Table | UPDATE + OUTPUT for stale message recovery |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Registration recovery job) | External | Reprocesses stuck registration messages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Read unhandled registration messages
```sql
EXEC [AffiliateCommission].[ReadRegistrationUnhandledMessages]
```

### 8.2 Check for stale messages in the registration queue
```sql
SELECT COUNT(*) AS StaleCount
FROM [AffiliateCommission].[AffiliateTraderRegistrationQueue] WITH (NOLOCK)
WHERE DATEADD(MINUTE, 10, DateModified) < GETUTCDATE()
```

### 8.3 View registration queue health
```sql
SELECT
    COUNT(*) AS TotalMessages,
    SUM(CASE WHEN DATEADD(MINUTE, 10, DateModified) < GETUTCDATE() THEN 1 ELSE 0 END) AS StaleMessages,
    MIN(DateCreated) AS OldestMessage,
    MAX(DateCreated) AS NewestMessage
FROM [AffiliateCommission].[AffiliateTraderRegistrationQueue] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ReadRegistrationUnhandledMessages | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.ReadRegistrationUnhandledMessages.sql*
