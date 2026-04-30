# dbo.AddCurrencyBalances

> Upsert procedure that creates or retrieves a currency balance record, deduplicating on CurrencyBalanceGuid.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatCurrencyBalances, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddCurrencyBalances creates or retrieves a currency balance record. Uses UPDLOCK/HOLDLOCK for concurrency-safe deduplication on CurrencyBalanceGuid. Returns existing ID if already present, otherwise inserts and returns new ID.

---

## 2. Business Logic

### 2.1 Idempotent Currency Balance Creation

**What**: Ensures each CurrencyBalanceGuid maps to exactly one record.

**Rules**:
- Deduplicates on CurrencyBalanceGuid (not AccountId+Currency)
- UPDLOCK, HOLDLOCK for concurrency safety
- Returns existing or new Id as Results

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CurrencyBalanceGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique external identifier for deduplication. |
| 2 | @AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. |
| 3 | @BankAccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatBankAccount.Id. |
| 4 | @CurrencyISON | nvarchar(128) | NO | - | CODE-BACKED | ISO numeric currency code (e.g., "826", "978"). |
| 5 | @Created | datetime2 | NO | - | CODE-BACKED | Event timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.FiatCurrencyBalances | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddCurrencyBalances (procedure)
└── dbo.FiatCurrencyBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCurrencyBalances | Table | Upsert target |

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

### 8.1 Create a GBP currency balance
```sql
EXEC dbo.AddCurrencyBalances @CurrencyBalanceGuid = NEWID(), @AccountId = 2135580,
    @BankAccountId = 0, @CurrencyISON = '826', @Created = SYSUTCDATETIME();
```

### 8.2 Verify the balance
```sql
SELECT * FROM dbo.FiatCurrencyBalances WITH (NOLOCK) WHERE AccountId = 2135580;
```

### 8.3 Test idempotency
```sql
DECLARE @guid UNIQUEIDENTIFIER = '26C43A5A-E8D5-4452-957B-015DF55A7453';
EXEC dbo.AddCurrencyBalances @CurrencyBalanceGuid = @guid, @AccountId = 2135580,
    @BankAccountId = 0, @CurrencyISON = '826', @Created = SYSUTCDATETIME();
-- Returns existing ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddCurrencyBalances | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddCurrencyBalances.sql*
