# AffiliateCommission.GetClosedPositionTriggeredEvents

> Claims and returns closed position events that have been triggered for commission re-evaluation, using an UPDATE-OUTPUT locking pattern to prevent concurrent processing.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns claimed ClosedPositionEvent rows with LastCheckDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetClosedPositionTriggeredEvents is a queue-consumer procedure in the closed position commission pipeline. When a closed position's attribution data changes (e.g., the customer is re-attributed to a different affiliate, or non-organic affiliate data is updated), a ClosedPositionEvent record is marked as triggered. This procedure claims those triggered events by setting their DateModified timestamp and returns them for the commission engine to re-evaluate.

This procedure exists because commission calculations may need to be re-run when attribution changes after the initial commission was computed. The UPDATE-OUTPUT pattern acts as a distributed lock: by updating DateModified, the procedure claims ownership of the rows, preventing other concurrent instances from picking up the same events.

The procedure filters for events that (1) haven't expired (within @ExpirationInDays), (2) haven't been recently claimed (DateModified older than @LockDeferredInMinutes), (3) match the processing source, and (4) have at least one trigger flag set (NonOrganicUpdated or ReAttributeUpdated).

---

## 2. Business Logic

### 2.1 Event Claim Pattern (UPDATE-OUTPUT Lock)

**What**: Atomically claims triggered events and returns their data in a single operation.

**Columns/Parameters Involved**: `DateModified`, `@ExpirationInDays`, `@LockDeferredInMinutes`, `@Source`

**Rules**:
- UPDATE sets DateModified = GETUTCDATE() to claim the row
- OUTPUT returns the claimed row's full event data
- Events must be within the expiration window (Occurred >= today - @ExpirationInDays)
- Events must not have been claimed recently (DateModified < now - @LockDeferredInMinutes)
- Events must match the @Source partition (allows multiple processing instances per source)
- Events must have at least one trigger: NonOrganicUpdated IS NOT NULL OR ReAttributeUpdated IS NOT NULL
- No NOLOCK hint on ClosedPositionEvent - intentional for correct locking behavior

### 2.2 LastCheckDate Calculation

**What**: Computes the most recent change timestamp across two trigger columns.

**Columns/Parameters Involved**: `NonOrganicUpdated`, `ReAttributeUpdated`, `LastCheckDate`

**Rules**:
- Uses dbo.InlineMax(NonOrganicUpdated, ReAttributeUpdated, NULL, NULL, NULL, NULL) to find the later of the two trigger timestamps
- This LastCheckDate tells the commission engine which changes to consider since the last evaluation
- If both triggers are set, the more recent one determines the check boundary

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExpirationInDays | int (IN) | NO | - | CODE-BACKED | How far back to look for triggered events. Events older than this are considered expired and ignored. |
| 2 | @Source | nvarchar(50) (IN) | NO | - | CODE-BACKED | Processing source partition. Allows multiple independent consumers to process different event sources without contention. |
| 3 | @LockDeferredInMinutes | int (IN) | YES | 1 | CODE-BACKED | Minimum age of DateModified before an event can be re-claimed. Prevents immediate re-processing of recently claimed events. Default 1 minute. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | ID | bigint | - | - | CODE-BACKED | ClosedPositionEvent primary key. |
| 5 | ClosedPositionID | bigint | - | - | CODE-BACKED | The closed position that triggered the event. FK to ClosedPosition. |
| 6 | Occurred | datetime | - | - | CODE-BACKED | When the triggering change occurred. |
| 7 | CID | bigint | - | - | CODE-BACKED | Customer ID associated with the position. |
| 8 | Amount | money | - | - | CODE-BACKED | Position trade amount (from the event snapshot). |
| 9 | HedgeCommission | money | - | - | CODE-BACKED | Hedge commission deducted from the position. |
| 10 | NetProfit | money | - | - | CODE-BACKED | Position net profit/loss. |
| 11 | LotCount | decimal | - | - | CODE-BACKED | Trade lot count. |
| 12 | OriginalProviderID | bigint | - | - | CODE-BACKED | Original broker/provider entity. |
| 13 | CountryID | int | - | - | CODE-BACKED | Customer's country. |
| 14 | ProviderID | bigint | - | - | CODE-BACKED | Current provider in the chain. |
| 15 | RealProviderID | bigint | - | - | CODE-BACKED | Actual executing provider. |
| 16 | AffiliateID | int | - | - | CODE-BACKED | Attributed affiliate. |
| 17 | LastCheckDate | datetime | - | - | CODE-BACKED | Computed: MAX(NonOrganicUpdated, ReAttributeUpdated) via dbo.InlineMax. Tells the engine when attribution last changed. |
| 18 | Source | nvarchar(50) | - | - | CODE-BACKED | Event source identifier. |
| 19 | GCID | bigint | - | - | CODE-BACKED | Global Customer ID. Added PART-3405. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPositionEvent | READ+WRITE (UPDATE OUTPUT) | Claims triggered events by setting DateModified; outputs event data |
| LastCheckDate | dbo.InlineMax | Function call | Computes MAX across NonOrganicUpdated and ReAttributeUpdated timestamps |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the closed position commission re-evaluation service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetClosedPositionTriggeredEvents (procedure)
+-- AffiliateCommission.ClosedPositionEvent (table)
+-- dbo.InlineMax (function, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionEvent | Table | UPDATE + OUTPUT for event claiming |
| dbo.InlineMax | Function (external) | Computes MAX across nullable datetime columns for LastCheckDate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission re-evaluation service) | External | Consumes triggered events for re-processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get triggered events for source 'Main' within 30 days
```sql
EXEC [AffiliateCommission].[GetClosedPositionTriggeredEvents]
    @ExpirationInDays = 30,
    @Source = 'Main',
    @LockDeferredInMinutes = 1
```

### 8.2 Check for unclaimed triggered events
```sql
SELECT ID, ClosedPositionID, CID, DateModified, NonOrganicUpdated, ReAttributeUpdated, [Source]
FROM [AffiliateCommission].[ClosedPositionEvent] WITH (NOLOCK)
WHERE (NonOrganicUpdated IS NOT NULL OR ReAttributeUpdated IS NOT NULL)
    AND Occurred >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY DateModified ASC
```

### 8.3 Count triggered events by source
```sql
SELECT [Source], COUNT(*) AS TriggerCount
FROM [AffiliateCommission].[ClosedPositionEvent] WITH (NOLOCK)
WHERE (NonOrganicUpdated IS NOT NULL OR ReAttributeUpdated IS NOT NULL)
    AND Occurred >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-3405: Added GCID to output (2025-02-23)
- PART-2448: CPA New Compensation Design + CountryID (2023-12-17)
- PART-2889: Fix RegistrationCommission AffiliateID (2023-03-28)
- Unlabeled: Performance rewrite of time functions (2024-02-11)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetClosedPositionTriggeredEvents | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetClosedPositionTriggeredEvents.sql*
