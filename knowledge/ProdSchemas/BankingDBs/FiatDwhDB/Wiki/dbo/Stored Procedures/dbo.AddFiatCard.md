# dbo.AddFiatCard

> Upsert procedure that creates a card record, resolving the AccountGuid to AccountId first, with idempotent deduplication on CardGuid + AccountId.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatCards (resolves AccountGuid first), returns Results (ID or 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddFiatCard creates a new card record in the DWH. Unlike other Add* procedures that accept an AccountId directly, this one accepts an @AccountGuid and resolves it to the internal AccountId via FiatAccount lookup. If the account is not found, returns 0. If the card (CardGuid + AccountId) already exists, returns the existing Id. Otherwise inserts and returns the new Id.

---

## 2. Business Logic

### 2.1 AccountGuid Resolution + Card Upsert

**What**: Two-step process - resolve GUID to ID, then check/insert card.

**Rules**:
- First resolves @AccountGuid -> AccountId from FiatAccount (UPDLOCK, HOLDLOCK)
- If AccountId not found -> return 0 (account must exist before cards)
- Then checks if CardGuid + AccountId already mapped in FiatCards
- If exists -> return existing Id; if not -> INSERT and return new Id

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique external identifier for the card. |
| 2 | @AccountGuid | uniqueidentifier | NO | - | CODE-BACKED | Account GUID to resolve to AccountId. Must exist in FiatAccount. |
| 3 | @Created | datetime2 | NO | - | CODE-BACKED | Card creation timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatAccount | Read | Resolves AccountGuid -> AccountId |
| INSERT/SELECT | dbo.FiatCards | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddFiatCard (procedure)
├── dbo.FiatAccount (table)
└── dbo.FiatCards (table)
    └── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | AccountGuid resolution |
| dbo.FiatCards | Table | Upsert target |

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

### 8.1 Create a card for an account
```sql
EXEC dbo.AddFiatCard @CardGuid = NEWID(),
    @AccountGuid = '8C3984A1-CF81-4534-A907-5D81F2362D90', @Created = SYSUTCDATETIME();
```

### 8.2 Verify card creation
```sql
SELECT c.Id, c.CardGuid, c.AccountId, a.Gcid
FROM dbo.FiatCards c WITH (NOLOCK)
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = c.AccountId
WHERE a.AccountGuid = '8C3984A1-CF81-4534-A907-5D81F2362D90';
```

### 8.3 Test with non-existent account (returns 0)
```sql
EXEC dbo.AddFiatCard @CardGuid = NEWID(),
    @AccountGuid = '00000000-0000-0000-0000-000000000000', @Created = SYSUTCDATETIME();
-- Returns Results = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddFiatCard | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddFiatCard.sql*
