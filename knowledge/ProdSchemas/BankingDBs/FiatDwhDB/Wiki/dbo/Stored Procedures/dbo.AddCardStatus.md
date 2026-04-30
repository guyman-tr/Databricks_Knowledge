# dbo.AddCardStatus

> Upsert procedure that records a card status change event, with deduplication based on CardId + CardStatusId + EventTimestamp.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatCardStatuses, returns Results (ID or 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddCardStatus records a card lifecycle event (activation, blocking, suspension, etc.) into FiatCardStatuses. It uses a transaction with deduplication logic: if a status record already exists with the same CardId, CardStatusId, and an EventTimestamp >= the incoming one, it returns 0 (already recorded). Otherwise it inserts and returns the new ID.

This deduplication prevents recording outdated or duplicate status events, which is critical in event-driven architectures where messages may be delivered more than once.

---

## 2. Business Logic

### 2.1 Timestamp-Based Deduplication

**What**: Prevents inserting status events that are older than or equal to an existing record for the same card and status.

**Columns/Parameters Involved**: `@CardId`, `@CardStatusId`, `@EventTimestamp`

**Rules**:
- If FiatCardStatuses already has a record with same CardId AND same CardStatusId AND EventTimestamp >= @EventTimestamp -> skip (return 0)
- This ensures only the latest status event is recorded, preventing replay of old events
- @CardInstanceId defaults to 0 for backward compatibility

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCards.Id. The card whose status changed. |
| 2 | @CardStatusId | int | NO | - | CODE-BACKED | New status: 0-8. See [Card Status](../../_glossary.md#card-status). |
| 3 | @EventTimestamp | datetime2 | NO | - | CODE-BACKED | When the status change occurred. Used for deduplication. |
| 4 | @ExpirationDate | datetime2 | NO | - | CODE-BACKED | Card expiration date at the time of the status event. |
| 5 | @Created | datetime2 | NO | - | CODE-BACKED | DWH recording timestamp. |
| 6 | @CardInstanceId | bigint | YES | 0 | CODE-BACKED | FK to FiatCardInstances.Id. Which card instance this status applies to. Default 0 for legacy compatibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.FiatCardStatuses | Read/Write | Dedup check + insert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddCardStatus (procedure)
└── dbo.FiatCardStatuses (table)
    ├── dbo.FiatCards (table)
    └── dbo.FiatCardInstances (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCardStatuses | Table | Dedup check + insert target |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Record a card activation
```sql
EXEC dbo.AddCardStatus @CardId = 105279, @CardStatusId = 1, @EventTimestamp = '2026-04-14T13:52:38',
    @ExpirationDate = '2029-04-01', @Created = SYSUTCDATETIME(), @CardInstanceId = 200001;
```

### 8.2 Record a card block (risk triggered)
```sql
EXEC dbo.AddCardStatus @CardId = 105279, @CardStatusId = 4, @EventTimestamp = '2026-04-14T14:00:00',
    @ExpirationDate = '2029-04-01', @Created = SYSUTCDATETIME(), @CardInstanceId = 200001;
```

### 8.3 Verify deduplication (old event should return 0)
```sql
EXEC dbo.AddCardStatus @CardId = 105279, @CardStatusId = 1, @EventTimestamp = '2026-04-14T12:00:00',
    @ExpirationDate = '2029-04-01', @Created = SYSUTCDATETIME();
-- Should return Results = 0 (older than existing event)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddCardStatus | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddCardStatus.sql*
