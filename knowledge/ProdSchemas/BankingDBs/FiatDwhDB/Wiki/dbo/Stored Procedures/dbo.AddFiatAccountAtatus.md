# dbo.AddFiatAccountAtatus

> Simple INSERT procedure that records an account status change event. Note: procedure name contains a typo ("Atatus" instead of "Status") preserved from the original DDL.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Simple INSERT into FiatAccountStatuses, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddFiatAccountAtatus (typo preserved) records an account status change event by inserting into FiatAccountStatuses. Unlike the upsert procedures, this is a simple INSERT with no deduplication - every call creates a new row. Returns the new SCOPE_IDENTITY() as Results.

---

## 2. Business Logic

No complex logic. Simple INSERT without deduplication or conditional logic.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. |
| 2 | @StatusType | int | NO | - | CODE-BACKED | Status: 0=Active, 1=Suspended, 2=Deleted. See [Account Status](../../_glossary.md#account-status). |
| 3 | @Created | datetime2 | NO | - | CODE-BACKED | Event timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | dbo.FiatAccountStatuses | Write | Insert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddFiatAccountAtatus (procedure)
└── dbo.FiatAccountStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccountStatuses | Table | INSERT target |

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

### 8.1 Record account suspension
```sql
EXEC dbo.AddFiatAccountAtatus @AccountId = 2135575, @StatusType = 1, @Created = SYSUTCDATETIME();
```

### 8.2 Record account reactivation
```sql
EXEC dbo.AddFiatAccountAtatus @AccountId = 2135575, @StatusType = 0, @Created = SYSUTCDATETIME();
```

### 8.3 Verify status history
```sql
SELECT StatusType, Created FROM dbo.FiatAccountStatuses WITH (NOLOCK)
WHERE AccountId = 2135575 ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddFiatAccountAtatus | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddFiatAccountAtatus.sql*
