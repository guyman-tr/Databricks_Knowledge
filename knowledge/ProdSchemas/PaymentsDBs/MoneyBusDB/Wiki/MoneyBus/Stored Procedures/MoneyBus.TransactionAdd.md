# MoneyBus.TransactionAdd

> Creates a new transaction record in the Transactions table with full creditor/debitor details, exchange rates, and flow context, returning the auto-generated ID.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @ID - returns new Transactions.ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionAdd creates a single transaction record in MoneyBus.Transactions. This is the individual transaction creation path (vs. TransactionsAndGroupAdd which creates a group + multiple transactions atomically). Used when the group has already been created via TransactionsGroupAdd and transactions are being added individually.

The procedure accepts the full set of transaction attributes: creditor/debitor account types and IDs, status, amount, currency, exchange rates for both sides, flow ID, and extra data. Created/Modified default to GETUTCDATE() if not provided.

---

## 2. Business Logic

No complex multi-column business logic. This is a direct INSERT into the partitioned Transactions table.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint OUTPUT | NO | - | CODE-BACKED | Returns the auto-generated IDENTITY value (SCOPE_IDENTITY()) of the new transaction. |
| 2 | @GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Maps to Transactions.GCID. |
| 3 | @Created | datetime | YES | GETUTCDATE() | CODE-BACKED | Optional creation timestamp. Defaults to GETUTCDATE(). |
| 4 | @CreditorTypeID | int | NO | - | CODE-BACKED | Creditor account type: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. Required. |
| 5 | @DebitorTypeID | int | NO | - | CODE-BACKED | Debitor account type: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. Required. |
| 6 | @StatusID | int | NO | - | CODE-BACKED | Initial transaction status: typically 1 (InProcess). Required. |
| 7 | @GroupID | bigint | YES | NULL | CODE-BACKED | FK to TransactionsGroup.ID. Links to parent group if this transaction is part of a multi-leg operation. |
| 8 | @ReferenceID | nvarchar(500) | YES | NULL | CODE-BACKED | External reference ID for cross-system correlation. |
| 9 | @Amount | money | NO | - | CODE-BACKED | Transaction amount in @CurrencyID currency. Required. |
| 10 | @CurrencyID | int | NO | - | CODE-BACKED | Currency of the amount. Required. |
| 11 | @Modified | datetime | YES | GETUTCDATE() | CODE-BACKED | Optional last-modified timestamp. Defaults to GETUTCDATE(). |
| 12 | @CreditorAccountID | nvarchar(500) | YES | NULL | CODE-BACKED | Specific creditor account identifier. |
| 13 | @DebitorAccountID | nvarchar(500) | YES | NULL | CODE-BACKED | Specific debitor account identifier. |
| 14 | @StatusReasonID | int | YES | NULL | CODE-BACKED | Initial status reason: typically 1 (Created). |
| 15 | @CreditorReferenceID | varchar(100) | YES | NULL | CODE-BACKED | Provider reference for the credit leg. |
| 16 | @DebitorReferenceID | varchar(100) | YES | NULL | CODE-BACKED | Provider reference for the debit leg. |
| 17 | @FlowID | int | YES | NULL | CODE-BACKED | Business flow: 1=Open, 2=Close, 3=Deposit/Withdrawal. |
| 18 | @ExtraData | nvarchar(4000) | YES | NULL | CODE-BACKED | JSON metadata with trading context (instrument, units, leverage, etc.). |
| 19 | @CreditorBaseExchangeRate | decimal(16,8) | YES | NULL | CODE-BACKED | Market exchange rate for creditor currency. |
| 20 | @CreditorExchangeFee | decimal(16,8) | YES | NULL | CODE-BACKED | Fee rate for creditor-side conversion. |
| 21 | @CreditorExchangeRate | decimal(16,8) | YES | NULL | CODE-BACKED | Effective exchange rate for creditor side. |
| 22 | @DebitorBaseExchangeRate | decimal(16,8) | YES | NULL | CODE-BACKED | Market exchange rate for debitor currency. |
| 23 | @DebitorExchangeFee | decimal(16,8) | YES | NULL | CODE-BACKED | Fee rate for debitor-side conversion. |
| 24 | @DebitorExchangeRate | decimal(16,8) | YES | NULL | CODE-BACKED | Effective exchange rate for debitor side. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT target) | MoneyBus.Transactions | Writer | Creates new transaction record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionAdd (procedure)
└── MoneyBus.Transactions (table) [INSERT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | INSERT INTO - creates new transaction |

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

### 8.1 Create a deposit transaction
```sql
DECLARE @NewID BIGINT;
EXEC MoneyBus.TransactionAdd @ID = @NewID OUTPUT,
    @GCID = 12345, @CreditorTypeID = 1, @DebitorTypeID = 3,
    @StatusID = 1, @Amount = 500.00, @CurrencyID = 2,
    @StatusReasonID = 1, @FlowID = 1;
SELECT @NewID AS TransactionID;
```

### 8.2 Create with exchange rate data
```sql
DECLARE @NewID BIGINT;
EXEC MoneyBus.TransactionAdd @ID = @NewID OUTPUT,
    @GCID = 67890, @CreditorTypeID = 3, @DebitorTypeID = 1,
    @StatusID = 1, @Amount = 1000.00, @CurrencyID = 1,
    @GroupID = 7746360, @FlowID = 2,
    @CreditorBaseExchangeRate = 0.84790313, @CreditorExchangeRate = 0.84162332;
```

### 8.3 Minimal call
```sql
DECLARE @NewID BIGINT;
EXEC MoneyBus.TransactionAdd @ID = @NewID OUTPUT,
    @GCID = 11111, @CreditorTypeID = 1, @DebitorTypeID = 3,
    @StatusID = 1, @Amount = 100.00, @CurrencyID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionAdd | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionAdd.sql*
