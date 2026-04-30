# dbo.AddBankAccount

> Upsert procedure that creates a new bank account record or returns the existing one if the BankAccountGuid already exists.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatBankAccount, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddBankAccount creates or retrieves a bank account record in the DWH. It uses a transaction with UPDLOCK/HOLDLOCK to safely check if the BankAccountGuid already exists. If it does, the existing ID is returned (idempotent). If not, a new record is inserted with all bank account details (IBAN, sort code, BIC, BSB code, etc.) and the new ID is returned.

This supports both internal (platform) and external (customer payee) bank accounts. The @BsbCode and @Ncc parameters have NULL defaults for backward compatibility (added after initial deployment).

---

## 2. Business Logic

### 2.1 Idempotent Bank Account Creation

**What**: Ensures each BankAccountGuid maps to exactly one record.

**Columns/Parameters Involved**: `@BankAccountGuid`, `@IsExternal`, all bank detail parameters

**Rules**:
- Uses UPDLOCK, HOLDLOCK for concurrency safety during check-then-insert
- SET NOCOUNT ON + SET XACT_ABORT ON for clean transaction handling
- Returns existing Id if BankAccountGuid already exists (no update of existing data)
- @BsbCode and @Ncc default to NULL for backward compatibility with callers that don't pass them

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BankAccountGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique external identifier for the bank account. Used for deduplication. |
| 2 | @IsExternal | bit | NO | - | CODE-BACKED | 0=internal platform bank account, 1=external customer payee. |
| 3 | @FullName | nvarchar(128) | NO | - | CODE-BACKED | Account holder name (PII, masked in table). |
| 4 | @Nickname | nvarchar(128) | YES | - | CODE-BACKED | Optional friendly name. |
| 5 | @BankAccountNumber | nvarchar(128) | YES | - | CODE-BACKED | Bank account number (PII, masked). |
| 6 | @SortCode | nvarchar(128) | YES | - | CODE-BACKED | UK sort code (NULL for non-UK). |
| 7 | @BsbCode | nvarchar(128) | YES | NULL | CODE-BACKED | Australian BSB code. Default NULL for backward compatibility. |
| 8 | @Ncc | nvarchar(128) | YES | NULL | CODE-BACKED | National Clearing Code. Default NULL. |
| 9 | @Iban | nvarchar(128) | YES | - | CODE-BACKED | IBAN for SEPA accounts (PII, masked). |
| 10 | @Bic | nvarchar(128) | YES | - | CODE-BACKED | BIC/SWIFT code. |
| 11 | @CurrencyBalanceId | bigint | YES | NULL | CODE-BACKED | FK to FiatCurrencyBalances. Links internal accounts to their balance. NULL for external. |
| 12 | @Created | datetime2 | NO | - | CODE-BACKED | Timestamp of the event. |
| 13 | @EventTimestamp | datetime2 | YES | NULL | CODE-BACKED | Source system event timestamp. Default NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.FiatBankAccount | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddBankAccount (procedure)
└── dbo.FiatBankAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatBankAccount | Table | Upsert target |

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

### 8.1 Create an internal bank account
```sql
EXEC dbo.AddBankAccount @BankAccountGuid = '0573B98D-EA13-4487-8E4F-6B1D9E533D85',
    @IsExternal = 0, @FullName = 'John Doe', @Nickname = NULL,
    @BankAccountNumber = '12345678', @SortCode = '040004',
    @Iban = NULL, @Bic = NULL, @CurrencyBalanceId = 2135646,
    @Created = '2026-04-14T13:32:36';
```

### 8.2 Create an external payee bank account with IBAN
```sql
EXEC dbo.AddBankAccount @BankAccountGuid = NEWID(),
    @IsExternal = 1, @FullName = 'Jane Smith', @Nickname = 'My EU account',
    @BankAccountNumber = NULL, @SortCode = NULL,
    @Iban = 'DE89370400440532013000', @Bic = 'COBADEFFXXX',
    @CurrencyBalanceId = NULL, @Created = SYSUTCDATETIME();
```

### 8.3 Verify idempotency
```sql
-- Call twice with same GUID - should return same Results
EXEC dbo.AddBankAccount @BankAccountGuid = '0573B98D-EA13-4487-8E4F-6B1D9E533D85',
    @IsExternal = 0, @FullName = 'John Doe', @Nickname = NULL,
    @BankAccountNumber = '12345678', @SortCode = '040004',
    @Iban = NULL, @Bic = NULL, @Created = SYSUTCDATETIME();
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddBankAccount | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddBankAccount.sql*
