# AffiliateCommission.GetRegistrationTriggeredEvents

> Claims and returns triggered registration events for commission re-evaluation, using an UPDATE-OUTPUT locking pattern to prevent concurrent processing.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns claimed RegistrationEvent rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetRegistrationTriggeredEvents is the queue consumer for the registration commission pipeline. When a registration event needs re-evaluation (e.g., attribution change, organic-to-paid re-attribution), this procedure claims the triggered events and returns them for the commission engine to reprocess.

This procedure follows the same UPDATE-OUTPUT pattern as GetClosedPositionTriggeredEvents and GetCreditTriggeredEvents. It sets DateModified on RegistrationEvent rows to claim them, then outputs the event data. Events that were claimed but not processed within the lock deferral window become re-eligible.

Unlike the credit and closed position variants, the registration version does not use dbo.InlineMax for LastCheckDate - it returns the stored LastCheckDate directly from the event row. The NonOrganicUpdated filter (present in the other variants) is commented out, meaning ALL non-expired registration events within the source partition are eligible.

---

## 2. Business Logic

### 2.1 Registration Event Claim Pattern

**What**: Atomically claims registration events and returns their data for re-processing.

**Columns/Parameters Involved**: `DateModified`, `@ExpirationInDays`, `@LockDeferredInMinutes`, `@Source`

**Rules**:
- UPDATE sets DateModified = GETUTCDATE() to claim the row
- OUTPUT returns the claimed event data
- Expiration: DATEADD(DAY, @ExpirationInDays, RegistrationDate) >= GETUTCDATE() (event must not have expired)
- Lock deferral: DATEADD(minute, @LockDeferredInMinutes, DateModified) < GETUTCDATE() (must not be recently claimed)
- Source partition: [Source] = @Source
- No NOLOCK hint - intentional for locking correctness
- Unlike other triggered event SPs, the NonOrganicUpdated filter is commented out - all events are eligible

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExpirationInDays | int (IN) | NO | - | CODE-BACKED | How far back to look for registration events. Events with RegistrationDate + this value < now are expired. |
| 2 | @Source | nvarchar(50) (IN) | NO | - | CODE-BACKED | Processing source partition for concurrent consumer isolation. |
| 3 | @LockDeferredInMinutes | int (IN) | YES | 1 | CODE-BACKED | Minimum age of DateModified before re-claim. Default 1 minute. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | ID | bigint | - | - | CODE-BACKED | RegistrationEvent primary key. |
| 5 | RegistrationID | bigint | - | - | CODE-BACKED | The registration record that triggered the event. FK to Registration. |
| 6 | RegistrationDate | datetime | - | - | CODE-BACKED | When the customer registered. Used for expiration calculation. |
| 7 | CountryID | int | - | - | CODE-BACKED | Customer's country for country-specific rates. |
| 8 | ProviderID | bigint | - | - | CODE-BACKED | Current provider in the chain. |
| 9 | RealProviderID | bigint | - | - | CODE-BACKED | Actual executing provider. |
| 10 | OriginalProviderID | bigint | - | - | CODE-BACKED | Original broker/provider entity. |
| 11 | CID | bigint | - | - | CODE-BACKED | Customer ID. |
| 12 | AffiliateID | int | - | - | CODE-BACKED | Attributed affiliate. |
| 13 | LastCheckDate | datetime | - | - | CODE-BACKED | When this event was last checked/evaluated. Stored directly (not computed like credit/position variants). |
| 14 | Source | nvarchar(50) | - | - | CODE-BACKED | Event source identifier. |
| 15 | GCID | bigint | - | - | CODE-BACKED | Global Customer ID. Added PART-3405. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.RegistrationEvent | READ+WRITE (UPDATE OUTPUT) | Claims events by setting DateModified; outputs event data |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the registration commission re-evaluation service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetRegistrationTriggeredEvents (procedure)
+-- AffiliateCommission.RegistrationEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationEvent | Table | UPDATE + OUTPUT for event claiming |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Registration commission service) | External | Consumes triggered events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get triggered registration events
```sql
EXEC [AffiliateCommission].[GetRegistrationTriggeredEvents]
    @ExpirationInDays = 30,
    @Source = 'Main',
    @LockDeferredInMinutes = 1
```

### 8.2 Check pending registration events
```sql
SELECT ID, RegistrationID, CID, AffiliateID, RegistrationDate, DateModified, [Source]
FROM [AffiliateCommission].[RegistrationEvent] WITH (NOLOCK)
WHERE DATEADD(DAY, 30, RegistrationDate) >= GETUTCDATE()
ORDER BY DateModified ASC
```

### 8.3 Count registration events by source
```sql
SELECT [Source], COUNT(*) AS EventCount
FROM [AffiliateCommission].[RegistrationEvent] WITH (NOLOCK)
WHERE DATEADD(DAY, 30, RegistrationDate) >= GETUTCDATE()
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-3405: Added GCID to output (2025-02-23)
- PART-2448: CPA New Compensation Design (2023-12-17)
- PART-2889: Fix RegistrationCommission AffiliateID (2023-03-28)
- PART-1195: New SP for Registration Commission (2022-02-22)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetRegistrationTriggeredEvents | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetRegistrationTriggeredEvents.sql*
