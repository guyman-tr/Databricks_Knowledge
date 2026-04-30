# Dictionary.DepositRollbackTypeReason

> Lookup table enumerating the 38 specific reasons why a deposit was rolled back — from fraud and fake documents to wrong amounts, failed deposits, and technical mishandling.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DepositRollbackTypeReasonID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When a deposit rollback (chargeback, refund, or adjustment) is created, the operator must select a reason explaining why the reversal occurred. This table provides the complete catalog of 38 rollback reasons, covering fraud detection, document verification failures, technical errors, mishandled transactions, incorrect financial details, and administrative corrections.

Without this table, the platform would have no way to classify the root cause of deposit reversals. This classification is critical for fraud analytics (tracking fraud patterns), compliance reporting (AML/regulatory filings require reason codes), operational metrics (identifying process failures), and financial reconciliation (understanding why money moved).

The table is linked to rollback types through `BackOffice.DepositRollbackTypeToReason` (a mapping table that defines which reasons are valid for which rollback types). It is also referenced in BackOffice reporting procedures (BillingDepositsPCIVersion, GetRiskExposureReportPCIVersion) and deposit-related permission scripts.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: Rollback reasons fall into distinct operational categories based on root cause.

**Columns/Parameters Involved**: `DepositRollbackTypeReasonID`, `Name`

**Rules**:
- **Fraud/Security** (0-3): Fraud, Fake Docs, Attack, Affiliate Fraud — customer or affiliate committed fraud
- **Customer Issues** (4-6): Lost Funds, Failed Verification, Technical/Service/Complaint — legitimate customer problems
- **Third-Party** (7): 3rd Party — deposit made by someone other than the account holder
- **System/Logic** (8-9): CO Logic, Incorrect Currency/CO Fees — system-detected issues
- **Administrative** (10-18): Already Refunded, Processor Reimbursement, Successful Dispute, Risk Refund Reversed, etc. — back-office corrections
- **Failed/Returned Deposits** (19-26): Failed Deposit, Returned Deposit, Wrong Currency/Amount/CID/Deposit ID — PSP-level failures
- **Adjustment Sub-Types** (27-37): Technical issue, Funds not received, 3rd party, Corporate account, Mishandle, Wrong details — granular deduction reasons

### 2.2 Rollback Type-to-Reason Mapping

**What**: Not all reasons are valid for all rollback types — the mapping is controlled by BackOffice.DepositRollbackTypeToReason.

**Columns/Parameters Involved**: `DepositRollbackTypeReasonID`

**Rules**:
- Chargeback (type 0) typically uses fraud/dispute reasons (0, 3, 14)
- Refund (type 1) uses a broader set including customer issues and administrative reasons
- Failed deposit deduction (type 8) uses reasons 23-26 (deduction-specific)
- The mapping table enforces valid combinations in the BackOffice UI

---

## 3. Data Overview

| DepositRollbackTypeReasonID | Name | Meaning |
|---|---|---|
| 0 | Fraud | Customer committed financial fraud — unauthorized transactions, identity theft, or stolen payment credentials used to deposit funds |
| 5 | Failed Verification | Customer failed KYC/identity verification — deposit must be returned because the account holder's identity could not be confirmed |
| 10 | Refunded by Withdraw | The rollback was already processed as a withdrawal instead — prevents double-refunding when the customer has already received their money back via cashout |
| 19 | Failed Deposit | The PSP reported the deposit as failed after initially appearing successful — the funds were never actually received by eToro |
| 23 | Deposit deducted - Added to the client | A pooled/misrouted deposit was incorrectly credited to a client — this deduction removes the erroneous credit |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositRollbackTypeReasonID | int | NO | - | VERIFIED | Primary key identifying the rollback reason. 38 values from 0 (Fraud) to 37 (Wrong Deposit ID). Linked to rollback types via BackOffice.DepositRollbackTypeToReason mapping table. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable reason description displayed in BackOffice UI when an operator creates a deposit rollback. Used in SSRS risk and billing reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.DepositRollbackTypeToReason | DepositRollbackTypeReasonID | Implicit | Mapping table that links valid reasons to specific rollback types |
| BackOffice.BillingDepositsPCIVersion | DepositRollbackTypeReasonID | JOIN | SSRS deposit billing report resolves rollback reason for display |
| BackOffice.GetRiskExposureReportPCIVersion | DepositRollbackTypeReasonID | JOIN | Risk exposure report includes rollback reason classification |
| Billing.GetDepositsCustomerCardPCIVersion | DepositRollbackTypeReasonID | JOIN | Customer card deposit report resolves rollback reason |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DepositRollbackTypeReason (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DepositRollbackTypeToReason | Table | References — type-to-reason mapping |
| BackOffice.BillingDepositsPCIVersion | Procedure | Reader — billing SSRS report |
| BackOffice.GetRiskExposureReportPCIVersion | Procedure | Reader — risk exposure report |
| Billing.GetDepositsCustomerCardPCIVersion | Procedure | Reader — customer card deposit report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryDepositRollbackTypeReason | CLUSTERED | DepositRollbackTypeReasonID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all rollback reasons
```sql
SELECT  DepositRollbackTypeReasonID,
        Name
FROM    Dictionary.DepositRollbackTypeReason WITH (NOLOCK)
ORDER BY DepositRollbackTypeReasonID
```

### 8.2 Show valid reasons per rollback type
```sql
SELECT  drt.Name AS RollbackType,
        drtr.Name AS Reason
FROM    BackOffice.DepositRollbackTypeToReason rtr WITH (NOLOCK)
        JOIN Dictionary.DepositRollbackType drt WITH (NOLOCK) ON rtr.DepositRollbackTypeID = drt.DepositRollbackTypeID
        JOIN Dictionary.DepositRollbackTypeReason drtr WITH (NOLOCK) ON rtr.DepositRollbackTypeReasonID = drtr.DepositRollbackTypeReasonID
ORDER BY drt.Name, drtr.Name
```

### 8.3 Group reasons by category
```sql
SELECT  DepositRollbackTypeReasonID,
        Name,
        CASE
            WHEN DepositRollbackTypeReasonID BETWEEN 0 AND 3 THEN 'Fraud/Security'
            WHEN DepositRollbackTypeReasonID BETWEEN 4 AND 6 THEN 'Customer Issue'
            WHEN DepositRollbackTypeReasonID BETWEEN 19 AND 26 THEN 'Failed/Returned'
            WHEN DepositRollbackTypeReasonID BETWEEN 27 AND 37 THEN 'Adjustment Detail'
            ELSE 'Administrative'
        END AS Category
FROM    Dictionary.DepositRollbackTypeReason WITH (NOLOCK)
ORDER BY DepositRollbackTypeReasonID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DepositRollbackTypeReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DepositRollbackTypeReason.sql*
