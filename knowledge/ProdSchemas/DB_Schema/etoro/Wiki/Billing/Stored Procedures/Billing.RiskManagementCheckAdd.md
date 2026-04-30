# Billing.RiskManagementCheckAdd

> Inserts a new risk management check record linking a payment to a risk management status result.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns @@ERROR (0=success) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a payment (deposit or withdrawal) goes through a risk management / AML check, the result of that check is recorded in `Billing.RiskManagementCheck`. `Billing.RiskManagementCheckAdd` is the single INSERT entry point for this table - it logs which payment was checked and what risk management status was assigned.

This procedure is part of eToro's fraud and AML compliance workflow. Risk management checks are performed by an external system that evaluates deposits and withdrawals against risk rules. The check result (as a `RiskManagementStatusID`) is then persisted via this procedure to create an auditable record.

Returns `@@ERROR` (0 if INSERT succeeded, non-zero SQL error code on failure). This is an older pattern pre-dating TRY/CATCH error handling.

---

## 2. Business Logic

### 2.1 Simple Risk Check Logging

**What**: Single-row INSERT to record the outcome of a risk check on a payment.

**Columns/Parameters Involved**: `@PaymentID`, `@RiskManagementStatusID`

**Rules**:
- Unconditional INSERT (no existence check, no state machine).
- Returns @@ERROR after the INSERT (0 = success).
- No transaction wrapping.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | The payment being risk-checked. FK to Billing.RiskManagementCheck.PaymentID. The PaymentID likely refers to a deposit or withdrawal record ID depending on context. |
| 2 | @RiskManagementStatusID | INTEGER | NO | - | CODE-BACKED | The outcome of the risk check from Dictionary.RiskManagementStatus (e.g., Approved, Flagged, Rejected). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentID, @RiskManagementStatusID | Billing.RiskManagementCheck | Direct write (INSERT) | Creates the risk check audit record |
| @RiskManagementStatusID | Dictionary.RiskManagementStatus | Lookup | Risk check outcome code |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by the risk management integration service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RiskManagementCheckAdd (procedure)
└── Billing.RiskManagementCheck (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RiskManagementCheck | Table | INSERT target for risk check records |

### 6.2 Objects That Depend On This

No SQL dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN @@ERROR | Legacy pattern | Returns the SQL error code after INSERT. 0=success. Older pattern pre-TRY/CATCH. |

---

## 8. Sample Queries

### 8.1 Log a risk management check result

```sql
EXEC Billing.RiskManagementCheckAdd
    @PaymentID = 123456,
    @RiskManagementStatusID = 2  -- e.g., Flagged
```

### 8.2 View risk management check history for a payment

```sql
SELECT rmc.PaymentID, rmc.RiskManagementStatusID,
       rms.Name AS StatusName
FROM Billing.RiskManagementCheck rmc WITH (NOLOCK)
JOIN Dictionary.RiskManagementStatus rms WITH (NOLOCK)
    ON rms.RiskManagementStatusID = rmc.RiskManagementStatusID
WHERE rmc.PaymentID = 123456
```

### 8.3 View all risk management status values

```sql
SELECT RiskManagementStatusID, Name
FROM Dictionary.RiskManagementStatus WITH (NOLOCK)
ORDER BY RiskManagementStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 10/10, Logic: 3/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RiskManagementCheckAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RiskManagementCheckAdd.sql*
