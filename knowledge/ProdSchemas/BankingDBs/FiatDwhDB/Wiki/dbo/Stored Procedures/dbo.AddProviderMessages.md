# dbo.AddProviderMessages

> Bulk INSERT procedure that inserts provider messages from the ProviderMessageType TVP, using a LEFT JOIN anti-pattern to skip messages that already exist (by Id).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Anti-join INSERT into ProviderMessages from TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddProviderMessages bulk-inserts provider messages from the ProviderMessageType TVP into ProviderMessages. Uses a LEFT JOIN WHERE IS NULL anti-pattern to only insert messages whose Id doesn't already exist in the table. This is efficient for idempotent batch processing - re-submitting the same message batch won't create duplicates.

---

## 2. Business Logic

### 2.1 Anti-Join Deduplication

**What**: Only inserts messages with Ids not already present in ProviderMessages.

**Rules**:
- LEFT JOIN on ProviderMessages.Id = TVP.Id
- WHERE pm.Id IS NULL filters to only new messages
- No transaction wrapping (relies on INSERT atomicity)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderMessages | ProviderMessageType | NO | READONLY | CODE-BACKED | TVP containing batch of provider messages. See dbo.ProviderMessageType for column details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.ProviderMessages | Read/Write | Anti-join insert target |
| @param | dbo.ProviderMessageType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddProviderMessages (procedure)
├── dbo.ProviderMessages (table)
└── dbo.ProviderMessageType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ProviderMessages | Table | Anti-join insert target |
| dbo.ProviderMessageType | UDT | TVP parameter type |

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

### 8.1 Bulk insert messages
```sql
DECLARE @Messages dbo.ProviderMessageType;
INSERT INTO @Messages (Id, ProviderId, Message, Created)
VALUES (1001, 1, '{"event":"card.activated"}', SYSUTCDATETIME()),
       (1002, 1, '{"event":"transaction.settled"}', SYSUTCDATETIME());
EXEC dbo.AddProviderMessages @ProviderMessages = @Messages;
```

### 8.2 Test idempotency
```sql
-- Re-running same batch should insert zero rows (all Ids already exist)
EXEC dbo.AddProviderMessages @ProviderMessages = @Messages;
```

### 8.3 Verify
```sql
SELECT * FROM dbo.ProviderMessages WITH (NOLOCK) WHERE Id IN (1001, 1002);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddProviderMessages | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddProviderMessages.sql*
