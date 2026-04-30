# Recurring.CreatePayment

> Creates a new recurring payment plan for a customer with duplicate detection per program type, returning the new or existing payment record.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns payment record (new or existing duplicate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary WRITER procedure for the Recurring.Payment table. It creates a new recurring payment plan for a customer, enforcing the business rule that a customer may have only ONE active plan per program type. If a duplicate is detected (same Cid + RecurringProgramTypeId with StatusId IN (1, 5)), the existing plan is returned with an IsDuplicated=1 flag instead of creating a new row.

Called by the application service when a customer enrolls in a recurring deposit or investment program.

---

## 2. Business Logic

### 2.1 Duplicate Detection and Idempotent Creation

**What**: Prevents duplicate active plans per customer per program type.

**Columns/Parameters Involved**: `@CID`, `@RecurringProgramTypeId`, Payment.`StatusId`

**Rules**:
- Reads all payments for @CID into a table variable
- Checks for existing payment with same RecurringProgramTypeId AND StatusId IN (1=Active, 5=Pending)
- If EXISTS: returns the existing record with IsDuplicated=1 (no INSERT)
- If NOT EXISTS: INSERTs new payment with StatusId=1 (Active), outputs with IsDuplicated=0
- StatusId=5 is included in duplicate check, meaning Pending plans also block new creation
- New payments get CreateDate=GETDATE(), ModificationDate=GETDATE()

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int (IN) | NO | - | CODE-BACKED | Customer ID for the new payment plan. |
| 2 | @FundingId | int (IN) | NO | - | CODE-BACKED | Payment method reference (credit card, bank account). |
| 3 | @RecurringProgramTypeId | int (IN) | NO | - | CODE-BACKED | Program type: 1=RecurringDeposit, 2=RecurringInvestment. Used in duplicate detection. |
| 4 | @Amount | money (IN) | NO | - | CODE-BACKED | Recurring charge amount in the specified currency. |
| 5 | @CurrencyId | int (IN) | NO | - | CODE-BACKED | Currency for the recurring amount. |
| 6 | @AuthenticationId | int (IN) | YES | NULL | CODE-BACKED | SCA/authentication reference if required. |
| 7 | @Generation | int (IN) | NO | 0 | CODE-BACKED | Modification generation counter. Typically 0 for new payments. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentId | int | NO | - | CODE-BACKED | The payment ID (new or existing). |
| 2 | IsDuplicated | bit | NO | - | VERIFIED | 0=newly created, 1=existing duplicate returned. Critical for the caller to distinguish between new enrollment and duplicate detection. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.Payment | WRITER + READER | SELECT existing payments, INSERT new payment |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.CreatePayment (procedure)
└── Recurring.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | SELECT for duplicate check, INSERT for new payment |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create a recurring deposit
```sql
EXEC Recurring.CreatePayment @CID = 12345, @FundingId = 100, @RecurringProgramTypeId = 1, @Amount = 100, @CurrencyId = 1
```

### 8.2 Create a recurring investment
```sql
EXEC Recurring.CreatePayment @CID = 12345, @FundingId = 100, @RecurringProgramTypeId = 2, @Amount = 50, @CurrencyId = 2, @AuthenticationId = 5678
```

### 8.3 Calling again returns duplicate
```sql
-- Second call with same CID + ProgramType returns IsDuplicated=1
EXEC Recurring.CreatePayment @CID = 12345, @FundingId = 200, @RecurringProgramTypeId = 1, @Amount = 200, @CurrencyId = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.CreatePayment | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.CreatePayment.sql*
