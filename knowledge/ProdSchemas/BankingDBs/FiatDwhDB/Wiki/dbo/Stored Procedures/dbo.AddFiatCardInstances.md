# dbo.AddFiatCardInstances

> Upsert procedure that creates a card instance record, deduplicating on Name + MaskedPan + ExpirationDate + CorrelationId.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatCardInstances, returns Results (ID or 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddFiatCardInstances creates a physical or virtual card instance record. Deduplicates on the combination of Name, MaskedPan, CardExpirationDate, and CorrelationId (UPDLOCK/HOLDLOCK). Returns 0 if already exists, otherwise inserts and returns new ID.

---

## 2. Business Logic

### 2.1 Multi-Column Deduplication

**Rules**: Deduplicates on (Name + MaskedPan + CardExpirationDate + CorrelationId) rather than a single GUID, because card instances may be replayed with the same business details.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardId | bigint | NO | - | CODE-BACKED | Implicit FK to dbo.FiatCards.Id. |
| 2 | @MaskedPan | nvarchar(128) | NO | - | CODE-BACKED | Masked card number. |
| 3 | @IsVirtual | bit | NO | - | CODE-BACKED | 1=virtual, 0=physical. |
| 4 | @Name | nvarchar(128) | NO | - | CODE-BACKED | Cardholder name (PII). |
| 5 | @ExpirationDate | datetime2 | NO | - | CODE-BACKED | Card expiration date. |
| 6 | @Created | datetime2 | NO | - | CODE-BACKED | DWH recording timestamp. |
| 7 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Distributed tracing ID. |
| 8 | @CardInstanceGuid | uniqueidentifier | NO | - | CODE-BACKED | External-facing instance GUID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.FiatCardInstances | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddFiatCardInstances (procedure)
└── dbo.FiatCardInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCardInstances | Table | Upsert target |

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

### 8.1 Create a virtual card instance
```sql
EXEC dbo.AddFiatCardInstances @CardId = 105279, @MaskedPan = '****1234', @IsVirtual = 1,
    @Name = 'John Doe', @ExpirationDate = '2029-04-01', @Created = SYSUTCDATETIME(),
    @CorrelationId = NEWID(), @CardInstanceGuid = NEWID();
```

### 8.2 Verify instance
```sql
SELECT * FROM dbo.FiatCardInstances WITH (NOLOCK) WHERE CardId = 105279;
```

### 8.3 Count instances per card
```sql
SELECT CardId, COUNT(*) AS InstanceCount FROM dbo.FiatCardInstances WITH (NOLOCK) GROUP BY CardId ORDER BY InstanceCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddFiatCardInstances | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddFiatCardInstances.sql*
