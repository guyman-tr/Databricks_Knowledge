# MoneyBus.WithdrawAdd

> Creates a new withdrawal record in the Withdrawals table, returning the auto-generated ID both as an output parameter and a result set.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @ID - returns new Withdrawals.ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawAdd is the entry point for creating withdrawal requests in the MoneyBus system. When a user initiates a withdrawal (requesting funds be moved from their platform account to an external destination), the withdrawal execution service calls this procedure to create the initial record with the withdrawal details.

The procedure accepts the full set of withdrawal attributes (customer, account type, amount, currency, payment method, status, etc.) and inserts a new row into MoneyBus.Withdrawals. It returns the new auto-generated ID both as an OUTPUT parameter (for programmatic use) and as a SELECT result set (for ORM/data reader consumption). Error handling uses TRY/CATCH with RAISERROR propagation.

---

## 2. Business Logic

### 2.1 Dual ID Return Pattern

**What**: The procedure returns the new withdrawal ID in two ways for maximum caller compatibility.

**Columns/Parameters Involved**: `@ID`

**Rules**:
- @ID OUTPUT parameter: for callers that capture output parameters directly
- SELECT @ID AS InsertedID: for callers that read result sets (common with ORMs)
- Both return the same SCOPE_IDENTITY() value
- RETURN 0 indicates success, RETURN -1 indicates error (caught in CATCH block)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | YES | NULL | CODE-BACKED | Global Customer ID. Nullable for system-generated withdrawals. Maps to Withdrawals.GCID. |
| 2 | @AccountID | nvarchar(200) | YES | NULL | CODE-BACKED | External account identifier (e.g., specific IBAN). Maps to Withdrawals.AccountID. |
| 3 | @AccountTypeID | int | NO | - | CODE-BACKED | Account type: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). Required. |
| 4 | @StatusID | int | NO | - | CODE-BACKED | Initial status: typically 1 (InProcess). See [Withdraw Status](../../_glossary.md#withdraw-status). Required. |
| 5 | @StatusReasonID | int | YES | NULL | CODE-BACKED | Initial status reason: typically 1 (Created). See [Withdraw Status Reason](../../_glossary.md#withdraw-status-reason). |
| 6 | @ReferenceID | nvarchar(500) | YES | NULL | CODE-BACKED | External reference for cross-system correlation. |
| 7 | @PaymentMethodID | nvarchar(200) | YES | NULL | CODE-BACKED | Payment method UUID from the payment provider. |
| 8 | @Amount | money | NO | - | CODE-BACKED | Withdrawal amount in the currency specified by @CurrencyID. Required. |
| 9 | @CurrencyID | int | NO | - | CODE-BACKED | Currency of the withdrawal amount. Required. |
| 10 | @ApprovalID | int | YES | NULL | CODE-BACKED | External approval/authorization reference. |
| 11 | @ExtID | nvarchar(200) | YES | NULL | CODE-BACKED | External transaction ID from the payment provider. |
| 12 | @CorrelationID | varchar(200) | YES | NULL | CODE-BACKED | Distributed tracing correlation ID. |
| 13 | @ExtraData | nvarchar(4000) | YES | NULL | CODE-BACKED | JSON extensible metadata. |
| 14 | @ManagerID | int | YES | NULL | CODE-BACKED | Back-office manager ID if manually created. |
| 15 | @Comments | varchar(200) | YES | NULL | CODE-BACKED | Free-text comments from back-office. |
| 16 | @ID | bigint OUTPUT | NO | - | CODE-BACKED | Returns the auto-generated Withdrawals.ID via SCOPE_IDENTITY(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT target) | MoneyBus.Withdrawals | Writer | Creates new withdrawal record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawAdd (procedure)
└── MoneyBus.Withdrawals (table) [INSERT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Withdrawals | Table | INSERT INTO - creates new withdrawal records |

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

### 8.1 Create a basic withdrawal
```sql
DECLARE @NewID BIGINT;
EXEC MoneyBus.WithdrawAdd
    @GCID = 12345, @AccountTypeID = 3, @StatusID = 1, @StatusReasonID = 1,
    @Amount = 500.00, @CurrencyID = 2, @ID = @NewID OUTPUT;
SELECT @NewID AS WithdrawID;
```

### 8.2 Create with full details
```sql
DECLARE @NewID BIGINT;
EXEC MoneyBus.WithdrawAdd
    @GCID = 12345, @AccountID = 'DE89370400440532013000',
    @AccountTypeID = 3, @StatusID = 1, @StatusReasonID = 1,
    @ReferenceID = 'WD-2026-001', @PaymentMethodID = 'abc-def-123',
    @Amount = 1000.00, @CurrencyID = 1, @CorrelationID = 'trace-xyz',
    @ID = @NewID OUTPUT;
```

### 8.3 Verify the created withdrawal
```sql
EXEC MoneyBus.WithdrawGet @ID = @NewID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawAdd | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawAdd.sql*
