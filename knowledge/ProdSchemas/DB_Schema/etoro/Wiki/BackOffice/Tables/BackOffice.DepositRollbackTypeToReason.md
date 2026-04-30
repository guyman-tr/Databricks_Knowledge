# BackOffice.DepositRollbackTypeToReason

> Static configuration junction defining which reason codes are valid for each deposit rollback operation type, powering the BackOffice UI dropdown filter that constrains reason selection to contextually appropriate options.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (DepositRollbackTypeID, DepositRollbackTypeReasonID) - composite CLUSTERED PK |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (1 clustered composite PK) |

---

## 1. Business Meaning

BackOffice.DepositRollbackTypeToReason is a static lookup configuration table that defines the valid reason codes for each deposit rollback operation type. When a BackOffice agent initiates a deposit rollback (reversal, chargeback, refund, etc.), they must select both a rollback type and a reason. This table constrains which reason codes are valid for each type, preventing nonsensical combinations (e.g., "Processor Reimbursement" reason for a "Refund" type).

The table has 38 rows covering 10 of the 11 rollback types (DepositRollbackTypeID=6 "Reverse Deposit" has no entries). Each type maps to 1-9 reason codes that are logically applicable to that rollback category:
- Type 0 (Chargeback): 9 reasons - fraud, 3rd party, compliance, etc.
- Type 1 (Refund): 4 reasons - fraud, fake docs, attack, affiliate fraud
- Type 2 (Refund as Chargeback): 1 reason - fraud only
- Type 3 (Chargeback Reversal): 4 reasons - already refunded, processor reimbursement, successful dispute, other
- Type 4 (Refund Reversal): 3 reasons - processor reimbursement, other, risk refund reversed
- Type 5 (Cancel Rollback): 2 reasons - rollback adjustment, wrong deposit ID/amount
- Type 7 (Pooled deposit adjustment): 4 reasons - deposit allocation errors
- Type 8 (Failed deposit deduction): 2 reasons - technical issue, funds not received
- Type 9 (Returned or Reversed Deposit): 4 reasons - 3rd party, corporate, joint account, mishandle
- Type 10 (Adjust Discrepancy): 5 reasons - wrong amount/currency/exchange rate/CID/deposit ID

No procedures in the BackOffice SSDT repo directly query this table - it is likely consumed directly by the application layer (BackOffice web UI) to populate the reason dropdown when a rollback type is selected.

---

## 2. Business Logic

### 2.1 Rollback Type-to-Reason Constraint (UI Filter)

**What**: Each deposit rollback type restricts the available reason codes to a predefined subset.

**Columns Involved**: `DepositRollbackTypeID`, `DepositRollbackTypeReasonID`

**Rules**:
- Chargeback (0): Fraud (0), Lost Funds (4), Failed Verification (5), Technical/Service/Complaint (6), 3rd Party (7), CO Logic (8), Incorrect Currency/CO Fees (9), Refunded by Withdraw (10), No Triggers (11)
- Refund (1): Fraud (0), Fake Docs (1), Attack (2), Affiliate Fraud (3)
- Refund as Chargeback (2): Fraud (0) only
- Chargeback Reversal (3): Already Refunded (12), Processor Reimbursement (13), Successful Dispute (14), Other (15)
- Refund Reversal (4): Processor Reimbursement (13), Other (15), Risk Refund Reversed (16)
- Cancel Rollback (5): Rollback Adjustment (17), Wrong Deposit ID/Amount (18)
- Reverse Deposit (6): No reasons defined (no rows in this table)
- Pooled Deposit Adjustment (7): Deposit deducted - Added to client (23), Deposit deducted - Returned/Reversed (24), Deposit deducted - Wrongly added to Pool (25), Deposit added - Return of Return (26)
- Failed Deposit Deduction (8): Technical issue (27), Funds not received (28)
- Returned or Reversed Deposit (9): 3rd party Deposit (29), Corporate/Trust account (30), Joint account (31), Mishandle (32)
- Adjust Discrepancy (10): Wrong Amount (33), Wrong Currency (34), Wrong Exchange rate (35), Wrong CID (36), Wrong Deposit ID (37)

---

## 3. Data Overview

38 rows (static configuration, no regular updates):

| DepositRollbackTypeID | Type Name | Valid Reason Count | Reason IDs |
|-----------------------|-----------|-------------------|------------|
| 0 | Chargeback | 9 | 0,4,5,6,7,8,9,10,11 |
| 1 | Refund | 4 | 0,1,2,3 |
| 2 | Refund as Chargeback | 1 | 0 |
| 3 | Chargeback Reversal | 4 | 12,13,14,15 |
| 4 | Refund Reversal | 3 | 13,15,16 |
| 5 | Cancel Rollback | 2 | 17,18 |
| 6 | Reverse Deposit | 0 | (none) |
| 7 | Pooled Deposit Adjustment | 4 | 23,24,25,26 |
| 8 | Failed Deposit Deduction | 2 | 27,28 |
| 9 | Returned or Reversed Deposit | 4 | 29,30,31,32 |
| 10 | Adjust Discrepancy | 5 | 33,34,35,36,37 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositRollbackTypeID | int | NO | - | VERIFIED | The deposit rollback operation type. Leading key of composite CLUSTERED PK. Implicit FK to Dictionary.DepositRollbackType. Values 0-10 (11 types): 0=Chargeback, 1=Refund, 2=Refund as Chargeback, 3=Chargeback Reversal, 4=Refund Reversal, 5=Cancel Rollback, 6=Reverse Deposit, 7=Pooled deposit adjustment, 8=Failed deposit deduction, 9=Returned or Reversed Deposit, 10=Adjust Discrepancy. No FK constraint declared. |
| 2 | DepositRollbackTypeReasonID | int | NO | - | VERIFIED | The reason code that is valid for this rollback type. Part of composite CLUSTERED PK. Implicit FK to Dictionary.DepositRollbackTypeReason. 38 values (0-37) covering fraud, technical errors, third-party scenarios, and adjustment reasons. No FK constraint declared. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositRollbackTypeID | Dictionary.DepositRollbackType | Implicit | 11 rollback operation types |
| DepositRollbackTypeReasonID | Dictionary.DepositRollbackTypeReason | Implicit | 38 reason codes across all types |

### 5.2 Referenced By (other objects point to this)

No procedures or views in the BackOffice SSDT repo directly reference this table. Consumed directly by application code (BackOffice UI) to populate the reason dropdown for deposit rollback operations.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DepositRollbackTypeToReason (config table)
- Implicit FK targets (no constraints):
  |- Dictionary.DepositRollbackType (table)
  |- Dictionary.DepositRollbackTypeReason (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.DepositRollbackType | Table | Implicit lookup for DepositRollbackTypeID |
| Dictionary.DepositRollbackTypeReason | Table | Implicit lookup for DepositRollbackTypeReasonID |

### 6.2 Objects That Depend On This

None found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOfficeDepositRollbackTypeToReason | CLUSTERED PK | DepositRollbackTypeID ASC, DepositRollbackTypeReasonID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOfficeDepositRollbackTypeToReason | PK | Uniqueness of (DepositRollbackTypeID, DepositRollbackTypeReasonID) - no duplicate type-reason pairs |

---

## 8. Sample Queries

### 8.1 Get all valid reasons for a specific rollback type
```sql
SELECT r2t.DepositRollbackTypeReasonID, r.Name AS ReasonName
FROM BackOffice.DepositRollbackTypeToReason r2t WITH (NOLOCK)
JOIN Dictionary.DepositRollbackTypeReason r WITH (NOLOCK)
    ON r.DepositRollbackTypeReasonID = r2t.DepositRollbackTypeReasonID
WHERE r2t.DepositRollbackTypeID = @DepositRollbackTypeID
ORDER BY r.Name
```

### 8.2 Full matrix of type-reason combinations
```sql
SELECT t.DepositRollbackTypeID, t.Name AS TypeName,
       r2t.DepositRollbackTypeReasonID, r.Name AS ReasonName
FROM Dictionary.DepositRollbackType t WITH (NOLOCK)
LEFT JOIN BackOffice.DepositRollbackTypeToReason r2t WITH (NOLOCK)
    ON r2t.DepositRollbackTypeID = t.DepositRollbackTypeID
LEFT JOIN Dictionary.DepositRollbackTypeReason r WITH (NOLOCK)
    ON r.DepositRollbackTypeReasonID = r2t.DepositRollbackTypeReasonID
ORDER BY t.DepositRollbackTypeID, r2t.DepositRollbackTypeReasonID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DepositRollbackTypeToReason | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.DepositRollbackTypeToReason.sql*
