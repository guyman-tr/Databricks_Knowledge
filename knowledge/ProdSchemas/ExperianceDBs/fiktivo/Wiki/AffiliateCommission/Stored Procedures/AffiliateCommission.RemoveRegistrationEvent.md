# AffiliateCommission.RemoveRegistrationEvent

> Deletes a single registration event by ID after commission calculation has completed, preventing reprocessing of already-handled registration events. Created PART-1195.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from RegistrationEvent by ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveRegistrationEvent is the cleanup step in the registration commission pipeline, introduced as part of PART-1195 which added the registration-based commission model. When a new user registers through an affiliate link, a registration event is created. The commission engine picks it up via GetRegistrationTriggeredEvents, evaluates the affiliate agreement for CPA (cost-per-acquisition) or hybrid commission structures, saves the commission via SaveRegistrationCommission, and then calls this procedure to remove the spent event.

Registration events represent one-time occurrences - a user registers only once. Unlike credit events which can recur for the same customer, a registration event has a single processing cycle. Removing it promptly after processing ensures the triggered-events query does not return already-handled registrations.

The single-ID deletion model mirrors the pattern established by RemoveClosedPositionEvent and RemoveCreditEvent, giving the calling service per-event control over cleanup. This is critical because registration commission calculation may involve external lookups (e.g., country-specific regulations, affiliate tier checks) that can fail for individual events.

---

## 2. Business Logic

### 2.1 Single-Row Event Deletion

**What**: Removes exactly one processed registration event by its primary key.

**Columns/Parameters Involved**: `@ID`, `RegistrationEvent.ID`

**Rules**:
- DELETE FROM RegistrationEvent WHERE ID = @ID
- Only one row is affected per call (ID is the primary key)
- Called only after registration commission calculation and persistence complete
- If the ID does not exist, the DELETE is a no-op (no error raised)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint (IN) | NO | - | CODE-BACKED | Primary key of the RegistrationEvent row to delete. Corresponds to the ID returned by GetRegistrationTriggeredEvents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | AffiliateCommission.RegistrationEvent | WRITE (DELETE) | Removes the event row by primary key |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline after SaveRegistrationCommission.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveRegistrationEvent (procedure)
+-- AffiliateCommission.RegistrationEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationEvent | Table | DELETE by primary key |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Removes processed registration events after commission is saved |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove a processed registration event
```sql
EXEC [AffiliateCommission].[RemoveRegistrationEvent] @ID = 15200
```

### 8.2 Verify the event was removed
```sql
SELECT ID, CID, AffiliateID, RegistrationDate, [Source]
FROM [AffiliateCommission].[RegistrationEvent] WITH (NOLOCK)
WHERE ID = 15200
```

### 8.3 Count remaining unprocessed registration events by source
```sql
SELECT [Source], COUNT(*) AS RemainingEvents
FROM [AffiliateCommission].[RegistrationEvent] WITH (NOLOCK)
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-1195: Registration commission events

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveRegistrationEvent | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveRegistrationEvent.sql*
