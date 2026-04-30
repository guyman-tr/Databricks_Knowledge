# Dictionary.TravelRuleStatuses

> Lookup table defining the lifecycle statuses for travel rule compliance workflows on cryptocurrency transactions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 unique (Name) |

---

## 1. Business Meaning

This table defines the statuses for travel rule compliance workflows. When a crypto transaction requires travel rule information exchange (sender/recipient identification), the workflow progresses through these statuses. The travel rule is a regulatory requirement (FATF Recommendation 16) that requires VASPs to share originator and beneficiary information for transfers above certain thresholds.

FK-referenced by `Wallet.TransactionTravelRuleStatuses`. Heavily consumed by travel rule SPs and transaction list functions (10+ consumers).

---

## 2. Business Logic

### 2.1 Travel Rule Workflow States

**What**: Six-state lifecycle for travel rule compliance.

**Rules**:
- `PendingManualApproval` (0): Transaction requires manual compliance review for travel rule
- `Approved` (1): Travel rule requirements met, transaction may proceed
- `Canceled` (2): Travel rule process canceled (transaction withdrawn or rejected)
- `PendingMissingInformation` (3): Additional information needed from sender or recipient
- `MissingInformationAdded` (4): Required information has been provided, awaiting re-review
- `MustCancel` (5): System determined the transaction must be canceled (compliance block)

**Diagram**:
```
PendingManualApproval (0) --> Approved (1) [proceed]
    |                    --> Canceled (2) [withdrawn]
    |
    +--> PendingMissingInformation (3) --> MissingInformationAdded (4)
                                              --> back to review (0)
    +--> MustCancel (5) [forced cancellation]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | PendingManualApproval | Transaction awaiting manual travel rule compliance review. Information exchange has been initiated but a compliance officer must verify completeness. |
| 1 | Approved | Travel rule requirements satisfied. All required originator/beneficiary information has been exchanged. Transaction may proceed. |
| 2 | Canceled | Travel rule process canceled. The transaction will not proceed. May be due to customer withdrawal or compliance decision. |
| 3 | PendingMissingInformation | Additional information is required. The counterparty VASP or the customer must provide missing originator/beneficiary details. |
| 5 | MustCancel | System has determined the transaction must be canceled for compliance reasons. Automatic cancellation triggered by a compliance rule. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 0=PendingManualApproval, 1=Approved, 2=Canceled, 3=PendingMissingInformation, 4=MissingInformationAdded, 5=MustCancel. FK target for Wallet.TransactionTravelRuleStatuses. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Status label. Unique constraint ensures no duplicates. Used in compliance dashboards and travel rule workflow UIs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.TransactionTravelRuleStatuses | TravelRuleStatusId | FK | Records travel rule status transitions |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleStatuses | Table | FK |
| Wallet.GetPendingTravelRuleTransactions | Stored Procedure | Filters pending travel rule transactions |
| Wallet.GetMustBouncebackTransactions | Stored Procedure | Filters MustCancel travel rules |
| Wallet.AddTransactionTravelRuleStatus | Stored Procedure | Inserts travel rule status transitions |
| Wallet.GetSentTransactionList* | Functions (3) | JOINs for sent transaction reporting |
| Wallet.GetReceivedTransactionList | Function | JOINs for received transaction reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TravelRuleStatuses | CLUSTERED | Id ASC | - | - | Active |
| UQ_Dictionary_TravelRuleStatuses_Name | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

None beyond the PK and unique Name constraint.

---

## 8. Sample Queries

### 8.1 List all travel rule statuses
```sql
SELECT Id, Name FROM Dictionary.TravelRuleStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Pending travel rule transactions
```sql
SELECT trs.TransactionTravelRuleId, trstat.Name AS Status
FROM Wallet.TransactionTravelRuleStatuses trs WITH (NOLOCK)
JOIN Dictionary.TravelRuleStatuses trstat WITH (NOLOCK) ON trs.TravelRuleStatusId = trstat.Id
WHERE trstat.Id = 0 ORDER BY trs.Created DESC
```

### 8.3 Travel rule compliance rate
```sql
SELECT trstat.Name, COUNT(*) AS Count
FROM Wallet.TransactionTravelRuleStatuses trs WITH (NOLOCK)
JOIN Dictionary.TravelRuleStatuses trstat WITH (NOLOCK) ON trs.TravelRuleStatusId = trstat.Id
GROUP BY trstat.Name ORDER BY Count DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TravelRuleStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.TravelRuleStatuses.sql*
