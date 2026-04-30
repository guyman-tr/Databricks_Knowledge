# dbo.AddFiatAccount

> Compound upsert procedure that creates a fiat account AND automatically inserts an initial Active status record in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatAccount + auto-insert into FiatAccountStatuses, returns Results (ID or 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddFiatAccount is the entry point for creating new fiat accounts in the DWH. It performs a compound operation: creates the FiatAccount record AND automatically inserts an initial FiatAccountStatuses record with StatusType=0 (Active). This ensures every account starts with a documented status. Uses TRY/CATCH with UPDLOCK/HOLDLOCK for concurrency safety.

If the account already exists (same Gcid + AccountGuid), returns 0 (idempotent). The @AccountProgramId defaults to 1 (card) and @SubProgramId defaults to NULL for backward compatibility.

---

## 2. Business Logic

### 2.1 Compound Account Creation

**What**: Atomic creation of account + initial status in one transaction.

**Columns/Parameters Involved**: `@Gcid`, `@AccountGuid`, `@AccountProgramId`, `@SubProgramId`

**Rules**:
- Deduplicates on Gcid + AccountGuid with UPDLOCK/HOLDLOCK
- If account exists, returns 0 (no insert)
- On new account: INSERT into FiatAccount, then INSERT StatusType=0 (Active) into FiatAccountStatuses with Created=GETUTCDATE()
- TRY/CATCH handles transaction rollback on error
- Returns new @fiatAccountId as Results

**Diagram**:
```
AddFiatAccount(@Gcid, @AccountGuid, ...)
  |
  v
BEGIN TRANSACTION
  1. Check: FiatAccount WHERE Gcid=@Gcid AND AccountGuid=@AccountGuid
  2. If exists -> return 0
  3. INSERT INTO FiatAccount -> get @fiatAccountId
  4. INSERT INTO FiatAccountStatuses (AccountId=@fiatAccountId, StatusType=0)
  5. Return @fiatAccountId
COMMIT TRANSACTION
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @AccountGuid | uniqueidentifier | NO | - | CODE-BACKED | External-facing account GUID. |
| 3 | @Created | datetime2 | NO | - | CODE-BACKED | Account creation timestamp. |
| 4 | @AccountProgramId | tinyint | YES | 1 | CODE-BACKED | Account program: 1=card (default), 2=iban. See [Account Program](../../_glossary.md#account-program). |
| 5 | @SubProgramId | tinyint | YES | NULL | CODE-BACKED | Sub-program: 1-16 or NULL. See [Sub-Program](../../_glossary.md#sub-program). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT (1) | dbo.FiatAccount | Write | Creates account record |
| INSERT (2) | dbo.FiatAccountStatuses | Write | Creates initial Active status |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddFiatAccount (procedure)
├── dbo.FiatAccount (table)
└── dbo.FiatAccountStatuses (table)
    └── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | Dedup check + insert |
| dbo.FiatAccountStatuses | Table | Initial status insert |

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

### 8.1 Create a new IBAN account
```sql
EXEC dbo.AddFiatAccount @Gcid = 17689308, @AccountGuid = NEWID(),
    @Created = SYSUTCDATETIME(), @AccountProgramId = 2, @SubProgramId = 6;
```

### 8.2 Verify account and initial status
```sql
SELECT a.Id, a.Gcid, a.AccountProgramId, s.StatusType, s.Created AS StatusCreated
FROM dbo.FiatAccount a WITH (NOLOCK)
JOIN dbo.FiatAccountStatuses s WITH (NOLOCK) ON s.AccountId = a.Id
WHERE a.Gcid = 17689308
ORDER BY s.Created DESC;
```

### 8.3 Test idempotency (same Gcid + AccountGuid returns 0)
```sql
EXEC dbo.AddFiatAccount @Gcid = 17689308,
    @AccountGuid = '8C3984A1-CF81-4534-A907-5D81F2362D90',
    @Created = SYSUTCDATETIME();
-- Returns Results = 0 (already exists)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddFiatAccount | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddFiatAccount.sql*
