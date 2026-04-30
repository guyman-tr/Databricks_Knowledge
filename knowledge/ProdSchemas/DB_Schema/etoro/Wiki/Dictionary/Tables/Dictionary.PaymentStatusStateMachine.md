# Dictionary.PaymentStatusStateMachine

> Configuration table defining the valid payment status transitions per funding type, acting as a state machine guard for the deposit processing pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FundingTypeID + BeforePaymentStatusID + AfterPaymentStatusID (composite PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 3 active (PK clustered + 2 NC on Before/After status) |

---

## 1. Business Meaning

Dictionary.PaymentStatusStateMachine is a configuration-driven state machine that defines which payment status transitions are allowed for each payment method (funding type). Before any deposit's status can change, the Billing engine checks this table to verify the transition is legal — preventing invalid state jumps that could corrupt financial records.

This table exists because different payment methods have different valid lifecycle paths. A credit card deposit might go from Pending → InProcess → Processed, but a wire transfer might skip InProcess entirely. A PayPal deposit might support reversal but a Rapid Transfer might not. Without this guard table, the system could accidentally move a deposit to an illegal state, causing reconciliation failures.

The table is consumed by `Billing.DepositProcess` (initial deposit processing) and `Billing.DepositUpdate` (subsequent status changes). Both procedures perform an EXISTS check against this table before allowing any status change. If the requested transition is not in the table, the update is blocked.

---

## 2. Business Logic

### 2.1 Payment Method-Specific State Machine

**What**: Each funding type has its own set of valid status transitions, forming a directed graph of allowed state changes.

**Columns/Parameters Involved**: `FundingTypeID`, `BeforePaymentStatusID`, `AfterPaymentStatusID`

**Rules**:
- A row (FundingType=X, Before=A, After=B) means: "For payment method X, transitioning from status A to status B is allowed"
- If no matching row exists, the transition is BLOCKED — the Billing procedure will not update the status
- Multiple "After" states can be valid from a single "Before" state (branching transitions)
- The same transition pattern may exist for some funding types but not others
- FundingTypeID references Dictionary.FundingType: 1=CreditCard, 2=ChinaUnionPay, 3=PayPal, 6=Wire, 7=PayPal(alt), 8=Skrill, etc.
- BeforePaymentStatusID/AfterPaymentStatusID reference Dictionary.PaymentStatus: 1=Pending, 2=Approved, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 13=WaitingForProvider, 35=Rejected

### 2.2 Common Transition Patterns

**What**: Despite per-method variation, most payment methods share common state transition patterns.

**Columns/Parameters Involved**: `BeforePaymentStatusID`, `AfterPaymentStatusID`

**Rules**:
- **Pending (1) → Approved (2)**: Direct approval — typical for instant methods
- **Pending (1) → Canceled (4)**: User or system canceled before processing
- **Pending (1) → Failed (5)**: Processing failed immediately
- **Pending (1) → WaitingForProvider (13)**: Sent to payment provider, awaiting response
- **WaitingForProvider (13) → Approved (2)**: Provider confirmed success
- **WaitingForProvider (13) → Canceled (4)**: Provider returned cancellation
- **WaitingForProvider (13) → Failed (5)**: Provider returned failure
- **Canceled (4) → Processed (3)**: Late success after cancellation (provider delayed response)
- **Approved (2) → status 11/12**: Post-approval transitions (chargebacks, reversals)

**Diagram**:
```
             ┌─────────────┐
             │ Pending (1)  │
             └──────┬───────┘
        ┌───────┬───┼───────┬──────────┐
        ▼       ▼   ▼       ▼          ▼
   Approved  Cancel Failed  Waiting   Rejected
     (2)      (4)   (5)   Provider    (35)
        │       │           (13)
        │       │      ┌────┼────┬────┐
        ▼       ▼      ▼    ▼    ▼    ▼
   Processed  Proc.  Appr. Canc. Fail Rev.
     (3)      (3)    (2)   (4)   (5)  (6)
```

---

## 3. Data Overview

| FundingTypeID | BeforePaymentStatusID | AfterPaymentStatusID | Meaning |
|---|---|---|---|
| 1 (CreditCard) | 1 (Pending) | 3 (Processed) | Credit card deposit can go directly from Pending to Processed — instant card authorization and capture |
| 1 (CreditCard) | 1 (Pending) | 13 (WaitingForProvider) | Credit card sent to payment gateway, awaiting asynchronous response from card network |
| 3 (PayPal) | 1 (Pending) | 2 (Approved) | PayPal deposit can be immediately approved — PayPal's instant payment notification confirms funds |
| 8 (Skrill) | 1 (Pending) | 16 | Skrill supports additional post-pending states not available to simpler payment methods |
| 6 (Wire) | 13 (WaitingForProvider) | 2 (Approved) | Wire transfer approved after bank confirmation — wires always go through WaitingForProvider first |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | VERIFIED | Payment method identifier — part of composite PK. References Dictionary.FundingType: 1=CreditCard, 2=ChinaUnionPay, 3=PayPal, 5=MoneyBookers, 6=Wire, 7=PayPal(alt), 8=Skrill, 9=Neteller, 10=WebMoney, 11=YandexMoney, etc. Each funding type has its own set of valid transitions. |
| 2 | BeforePaymentStatusID | int | NO | - | VERIFIED | The payment status BEFORE the transition — part of composite PK. FK to Dictionary.PaymentStatus: 1=Pending, 2=Approved/InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 12=ChargeBack, 13=WaitingForProvider. |
| 3 | AfterPaymentStatusID | int | NO | - | VERIFIED | The payment status AFTER the transition — part of composite PK. FK to Dictionary.PaymentStatus. A row's existence means "this transition is allowed." Billing.DepositProcess checks `AfterPaymentStatusID = 2` (approved) to validate deposit approval. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method whose transition rules this row defines |
| BeforePaymentStatusID | Dictionary.PaymentStatus | FK (FK_DPMT_DPMB) | The source state of the transition |
| AfterPaymentStatusID | Dictionary.PaymentStatus | FK (FK_DPMT_DPMA) | The target state of the transition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.DepositProcess | Direct query | Lookup | Validates that a deposit can transition to Approved (status 2) for the given funding type and current status |
| Billing.DepositUpdate | Direct query | Lookup | Validates any status change on an existing deposit is permitted for the funding type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PaymentStatusStateMachine (table)
```

This object has no dependencies (FK targets are lookup references, not code-level dependencies).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentStatus | Table | FK target for BeforePaymentStatusID and AfterPaymentStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositProcess | Stored Procedure | EXISTS check before approving a deposit |
| Billing.DepositUpdate | Stored Procedure | EXISTS check before updating deposit status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPSM | CLUSTERED PK | FundingTypeID, BeforePaymentStatusID, AfterPaymentStatusID | - | - | Active |
| DPSM_AFTERPAYMENTSTATUS | NONCLUSTERED | AfterPaymentStatusID | - | - | Active |
| DPSM_BEFOREPAYMENTSTATUS | NONCLUSTERED | BeforePaymentStatusID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPSM | PRIMARY KEY | Composite key ensuring unique transition rules per funding type |
| FK_DPMT_DPMA | FOREIGN KEY | AfterPaymentStatusID → Dictionary.PaymentStatus.PaymentStatusID |
| FK_DPMT_DPMB | FOREIGN KEY | BeforePaymentStatusID → Dictionary.PaymentStatus.PaymentStatusID |

---

## 8. Sample Queries

### 8.1 List all valid transitions for credit card deposits
```sql
SELECT  ps_before.Name  AS FromStatus,
        ps_after.Name   AS ToStatus
FROM    Dictionary.PaymentStatusStateMachine sm WITH (NOLOCK)
JOIN    Dictionary.PaymentStatus ps_before WITH (NOLOCK)
        ON sm.BeforePaymentStatusID = ps_before.PaymentStatusID
JOIN    Dictionary.PaymentStatus ps_after WITH (NOLOCK)
        ON sm.AfterPaymentStatusID = ps_after.PaymentStatusID
WHERE   sm.FundingTypeID = 1
ORDER BY ps_before.PaymentStatusID, ps_after.PaymentStatusID;
```

### 8.2 Check if a specific transition is allowed
```sql
SELECT  CASE WHEN EXISTS (
            SELECT 1
            FROM   Dictionary.PaymentStatusStateMachine WITH (NOLOCK)
            WHERE  FundingTypeID = 3 -- PayPal
                   AND BeforePaymentStatusID = 1 -- Pending
                   AND AfterPaymentStatusID = 2  -- Approved
        ) THEN 'ALLOWED' ELSE 'BLOCKED' END AS TransitionResult;
```

### 8.3 Count valid transitions per funding type
```sql
SELECT  ft.Name             AS FundingType,
        COUNT(*)            AS ValidTransitions
FROM    Dictionary.PaymentStatusStateMachine sm WITH (NOLOCK)
JOIN    Dictionary.FundingType ft WITH (NOLOCK)
        ON sm.FundingTypeID = ft.FundingTypeID
GROUP BY ft.Name
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Code comment reference: "Elrom B. 10/01/2023 Add PaymentStatusStateMachine check for status change for PAYIL-5632" — indicates the state machine validation was added to DepositUpdate in January 2023.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentStatusStateMachine | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PaymentStatusStateMachine.sql*
