# dbo.AddFiatMerchants

> Upsert procedure that creates a merchant record from a transaction description string, with NULL handling and deduplication on Description.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatMerchants, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddFiatMerchants creates or retrieves a merchant record based on the merchant description string from card transactions. Returns early (no insert) if @Description is NULL. Deduplicates on the Description text with UPDLOCK/HOLDLOCK. Sets Created to GETUTCDATE() on insert (not caller-provided). Uses TRY/CATCH with transaction rollback.

---

## 2. Business Logic

### 2.1 Description-Based Deduplication

**Rules**:
- NULL @Description -> early return (no merchant created)
- Deduplicates on exact Description match (case-sensitive per collation)
- Created is set to GETUTCDATE() by the procedure, not passed by caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Description | nvarchar(256) | YES | - | CODE-BACKED | Merchant description string from the payment network. NULL triggers early return. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.FiatMerchants | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddFiatMerchants (procedure)
└── dbo.FiatMerchants (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatMerchants | Table | Upsert target |

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

### 8.1 Create a merchant
```sql
EXEC dbo.AddFiatMerchants @Description = 'AMAZON EU SARL LUXEMBOURG LU';
```

### 8.2 Test NULL handling (no insert)
```sql
EXEC dbo.AddFiatMerchants @Description = NULL;
-- No row inserted, no result returned
```

### 8.3 Test idempotency
```sql
EXEC dbo.AddFiatMerchants @Description = 'AMAZON EU SARL LUXEMBOURG LU';
-- Returns same ID as first call
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddFiatMerchants | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddFiatMerchants.sql*
