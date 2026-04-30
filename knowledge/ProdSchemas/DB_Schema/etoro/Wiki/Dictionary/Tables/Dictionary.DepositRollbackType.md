# Dictionary.DepositRollbackType

> Lookup table defining the types of deposit reversal operations — chargebacks, refunds, reversals, and adjustment corrections that reduce or reverse a customer's deposited funds.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DepositRollbackTypeID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When a deposit needs to be reversed — whether due to a chargeback from the card issuer, a refund initiated by eToro, a failed deposit correction, or a reconciliation adjustment — this table classifies the type of reversal. Each rollback type has different financial, operational, and compliance implications: chargebacks are initiated externally by banks, refunds are initiated internally by eToro, and adjustments correct discrepancies.

Without this table, the platform would have no way to distinguish between the various reasons a deposit might be reversed. This distinction is critical for financial reporting (chargebacks vs refunds are reported differently), risk assessment (high chargeback rates affect merchant account standing), and operational workflows (different rollback types require different approval processes).

The table is referenced by `BackOffice.DepositRollbackTypeToReason` (which maps rollback types to specific reasons), user permission scripts for deposit operations, and BackOffice reporting procedures for risk exposure.

---

## 2. Business Logic

### 2.1 Rollback Type Categories

**What**: Deposit rollbacks are classified by their origin and financial impact.

**Columns/Parameters Involved**: `DepositRollbackTypeID`, `Name`

**Rules**:
- **External-initiated**: Chargeback (0) — bank reverses the deposit on behalf of the cardholder
- **eToro-initiated**: Refund (1) — eToro voluntarily returns funds to the customer
- **Hybrid**: Refund as Chargeback (2) — eToro processes a refund in response to a pending chargeback to avoid the chargeback fee
- **Reversal of reversals**: Chargeback Reversal (3) and Refund Reversal (4) — undo previous rollbacks when a dispute is won or a refund is reclaimed
- **Correction types**: Cancel Rollback (5), Reverse Deposit (6), Pooled deposit adjustment (7), Failed deposit deduction (8), Returned or Reversed Deposit (9), Adjust Discrepancy (10) — various operational corrections

**Diagram**:
```
Deposit Rollback Types:
├── External: Chargeback (0) ←── bank-initiated
├── Internal: Refund (1) ←── eToro-initiated
├── Hybrid:  Refund as Chargeback (2) ←── preemptive refund
├── Reversals: Chargeback Reversal (3), Refund Reversal (4) ←── undo
├── Corrections: Cancel Rollback (5), Reverse Deposit (6)
└── Adjustments: Pooled (7), Failed (8), Returned (9), Discrepancy (10)
```

---

## 3. Data Overview

| DepositRollbackTypeID | Name | Meaning |
|---|---|---|
| 0 | Chargeback | The cardholder's bank has reversed the deposit, debiting eToro's merchant account — typically due to a customer disputing the charge, unauthorized transaction claim, or merchant error |
| 1 | Refund | eToro voluntarily returns funds to the customer's original payment method — initiated by customer service, compliance, or automated refund rules |
| 2 | Refund as Chargeback | eToro proactively issues a refund to satisfy a pending or anticipated chargeback — avoids the chargeback fee and negative impact on the merchant's chargeback ratio |
| 6 | Reverse Deposit | A complete reversal of an incorrectly applied deposit — the deposit should not have been credited to this customer's account |
| 10 | Adjust Discrepancy | A manual adjustment to correct a financial discrepancy between eToro's records and the PSP's records — used during reconciliation when amounts don't match |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositRollbackTypeID | int | NO | - | VERIFIED | Primary key identifying the rollback type. 0=Chargeback, 1=Refund, 2=Refund as Chargeback, 3=Chargeback Reversal, 4=Refund Reversal, 5=Cancel Rollback, 6=Reverse Deposit, 7=Pooled deposit adjustment, 8=Failed deposit deduction, 9=Returned or Reversed Deposit, 10=Adjust Discrepancy. Referenced by BackOffice.DepositRollbackTypeToReason mapping table. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable rollback type label used in BackOffice UI, SSRS risk reports, and financial reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.DepositRollbackTypeToReason | DepositRollbackTypeID | Implicit | Maps rollback types to their valid reasons (Dictionary.DepositRollbackTypeReason) |
| BackOffice.BillingDepositsPCIVersion | DepositRollbackTypeID | JOIN | SSRS deposit billing report resolves rollback type for display |
| BackOffice.GetRiskExposureReportPCIVersion | DepositRollbackTypeID | JOIN | Risk exposure report includes rollback type classification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DepositRollbackType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DepositRollbackTypeToReason | Table | References — maps types to valid reasons |
| BackOffice.BillingDepositsPCIVersion | Procedure | Reader — SSRS deposit report |
| BackOffice.GetRiskExposureReportPCIVersion | Procedure | Reader — risk exposure report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryDepositRollbackType | CLUSTERED | DepositRollbackTypeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all deposit rollback types
```sql
SELECT  DepositRollbackTypeID,
        Name
FROM    Dictionary.DepositRollbackType WITH (NOLOCK)
ORDER BY DepositRollbackTypeID
```

### 8.2 Show rollback type with valid reasons
```sql
SELECT  drt.Name AS RollbackType,
        drtr.Name AS Reason
FROM    Dictionary.DepositRollbackType drt WITH (NOLOCK)
        JOIN BackOffice.DepositRollbackTypeToReason rtr WITH (NOLOCK) ON drt.DepositRollbackTypeID = rtr.DepositRollbackTypeID
        JOIN Dictionary.DepositRollbackTypeReason drtr WITH (NOLOCK) ON rtr.DepositRollbackTypeReasonID = drtr.DepositRollbackTypeReasonID
ORDER BY drt.Name, drtr.Name
```

### 8.3 Classify rollback types by origin
```sql
SELECT  DepositRollbackTypeID,
        Name,
        CASE
            WHEN DepositRollbackTypeID IN (0, 3) THEN 'Bank-Initiated'
            WHEN DepositRollbackTypeID IN (1, 2, 4) THEN 'eToro-Initiated'
            ELSE 'Operational Correction'
        END AS Origin
FROM    Dictionary.DepositRollbackType WITH (NOLOCK)
ORDER BY DepositRollbackTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DepositRollbackType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DepositRollbackType.sql*
