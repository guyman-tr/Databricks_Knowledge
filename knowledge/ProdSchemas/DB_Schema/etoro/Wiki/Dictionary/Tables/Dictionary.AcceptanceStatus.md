# Dictionary.AcceptanceStatus

> Lookup table defining the 4 customer acceptance states — Pending, Accepted, Rejected, and Follow Up — used during the customer onboarding and compliance review process.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AcceptanceStatusID (TINYINT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK + unique on Name) |

---

## 1. Business Meaning

Dictionary.AcceptanceStatus defines the possible compliance acceptance states for customer accounts. When a new customer registers or undergoes periodic review, their account is assigned an acceptance status that tracks whether compliance has cleared them for trading.

This table is critical for the customer onboarding pipeline. The acceptance status gates whether a customer can trade, deposit, or access full platform features. Accounts stuck in "Pending" or "Follow Up" may have restricted functionality until compliance completes their review.

The acceptance status is stored in BackOffice.Customer and tracked historically in History.BackOfficeCustomer. It is set and updated by BackOffice.CustomerAcceptance (manual compliance decision), and read by procedures like BackOffice.GetCustomerByCID, Billing.DD_GetDepositFollowUpCID (finds customers needing deposit follow-up), and Customer.DynamicsInsert (CRM sync).

---

## 2. Business Logic

### 2.1 Acceptance Lifecycle

**What**: The compliance review workflow for customer accounts.

**Columns/Parameters Involved**: `AcceptanceStatusID`, `Name`

**Rules**:
- **Pending (0)**: Initial state when a customer registers. Account is under compliance review. May have restricted trading capabilities.
- **Accepted (1)**: Compliance has cleared the customer. Full platform access granted. This is the target state for all legitimate customers.
- **Rejected (2)**: Compliance has denied the customer. Account may be blocked or restricted from further activity. Common reasons include failed KYC, sanctions matches, or fraud indicators.
- **Follow Up (3)**: Additional information or documentation is required from the customer. Used when compliance cannot make a determination from existing data. Billing.DD_GetDepositFollowUpCID specifically queries for customers in this state to trigger follow-up deposit workflows.

**Diagram**:
```
Customer Registration
       │
       ▼
  ┌──────────┐
  │ Pending  │ (0)
  │  (new)   │
  └────┬─────┘
       │ Compliance Review
       ├───────────────────► Accepted (1) ──► Full Access
       │
       ├───────────────────► Rejected (2) ──► Restricted/Blocked
       │
       └───────────────────► Follow Up (3) ──► Request More Info
                                    │
                                    └──► Back to review ──► Accepted/Rejected
```

---

## 3. Data Overview

| AcceptanceStatusID | Name | Meaning |
|---|---|---|
| 0 | Pending | Default state for newly registered customers awaiting compliance review. Account may have limited functionality until cleared. |
| 1 | Accepted | Compliance has approved the customer for full platform access. Required before unrestricted trading and withdrawals. |
| 2 | Rejected | Compliance has denied the customer. Triggers account restrictions or closure workflows. May result from failed KYC, sanctions screening, or fraud detection. |
| 3 | Follow Up | Compliance review is incomplete — additional customer documentation or information is required. Deposit follow-up workflows (Billing.DD_GetDepositFollowUpCID) target customers in this state. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AcceptanceStatusID | tinyint | NO | - | VERIFIED | Primary key identifying the acceptance state. 0=Pending, 1=Accepted, 2=Rejected, 3=Follow Up. Stored in BackOffice.Customer.AcceptanceStatusID and History.BackOfficeCustomer. Set by BackOffice.CustomerAcceptance, read by BackOffice.GetCustomerByCID. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable acceptance state name. Unique constraint enforced (UK_DAS_Name). Used in JOIN queries to resolve IDs to display names in compliance reports and BackOffice views (BackOffice.CustomerSafty). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | AcceptanceStatusID | Implicit | Customer's current compliance acceptance state |
| History.BackOfficeCustomer | AcceptanceStatusID | Implicit | Historical snapshots of customer acceptance state changes |
| BackOffice.CustomerSafty | AcceptanceStatusID | View SELECT | Schema-bound customer view for safe reading |
| BackOffice.CustomerAcceptance | @AcceptanceStatusID | Parameter UPDATE | Sets the acceptance status during compliance review |
| BackOffice.GetCustomerByCID | AcceptanceStatusID | SELECT | Returns acceptance status as part of customer profile |
| Billing.DD_GetDepositFollowUpCID | AcceptanceStatusID | WHERE | Filters for Follow Up (3) customers needing deposit follow-up |
| Customer.DynamicsInsert | AcceptanceStatusID | SELECT | Reads acceptance status for CRM sync |
| BackOffice.GetHistoryBackOfficeCustomer | AcceptanceStatusID | SELECT | Returns historical acceptance status changes |
| BackOffice.NewRiskAlertsPCIVersion | AcceptanceStatusID | SELECT | Includes acceptance status in risk alert reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Stores AcceptanceStatusID per customer |
| History.BackOfficeCustomer | Table | Historical tracking |
| BackOffice.CustomerAcceptance | Stored Procedure | Writer — sets acceptance status |
| BackOffice.GetCustomerByCID | Stored Procedure | Reader — returns customer profile |
| Billing.DD_GetDepositFollowUpCID | Stored Procedure | Reader — finds follow-up customers |
| BackOffice.NewRiskAlertsPCIVersion | Stored Procedure | Reader — risk alert reports |
| Customer.DynamicsInsert | Stored Procedure | Reader — CRM sync |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DAS | CLUSTERED PK | AcceptanceStatusID ASC | - | - | Active |
| UK_DAS_Name | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DAS | PRIMARY KEY | Unique acceptance status identifier |
| UK_DAS_Name | UNIQUE | Prevents duplicate status names |

---

## 8. Sample Queries

### 8.1 List all acceptance statuses
```sql
SELECT  AcceptanceStatusID,
        Name
FROM    Dictionary.AcceptanceStatus WITH (NOLOCK)
ORDER BY AcceptanceStatusID;
```

### 8.2 Count customers by acceptance status
```sql
SELECT  das.Name            AS AcceptanceStatus,
        COUNT(*)            AS CustomerCount
FROM    BackOffice.Customer boc WITH (NOLOCK)
JOIN    Dictionary.AcceptanceStatus das WITH (NOLOCK)
        ON boc.AcceptanceStatusID = das.AcceptanceStatusID
GROUP BY das.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Find customers pending compliance review
```sql
SELECT  boc.CID,
        das.Name            AS AcceptanceStatus
FROM    BackOffice.Customer boc WITH (NOLOCK)
JOIN    Dictionary.AcceptanceStatus das WITH (NOLOCK)
        ON boc.AcceptanceStatusID = das.AcceptanceStatusID
WHERE   das.AcceptanceStatusID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AcceptanceStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AcceptanceStatus.sql*
