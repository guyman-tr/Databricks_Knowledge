# Dictionary.RiskManagementStatus

> Lookup table for the outcome/result status of deposit risk management checks. Status 1 (Success) means the deposit passed; all other IDs indicate a specific reason for flagging or blocking the deposit.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RiskManagementStatusID (int, PK NONCLUSTERED) |
| **Partition** | No (DICTIONARY filegroup, FILLFACTOR 90) |
| **Indexes** | 2 active (PK + UNIQUE on Name) |

---

## 1. Business Meaning

Dictionary.RiskManagementStatus defines the outcome status of deposit risk management checks. When a deposit is attempted, the payment risk engine evaluates it against multiple rules — card velocity, BIN blacklists, country conflicts, KYC levels, fraud signals (e.g., Sift, ML), and business rules — and assigns a RiskManagementStatus. Status 1 (Success) means the deposit passed all checks. All other statuses indicate a specific reason for flagging or blocking: e.g., CardIsBlocked, BinInBlackList, DeclinedBlackListCountry, KYCLevel0–3, CreditCardVelocity, ThreeDsVerificationFail, BusinessRuleRisk.

This table is the central enumeration for all deposit risk decisions. Billing.Deposit stores RiskManagementStatusID per deposit. Billing.RiskManagementCheck records individual risk check results. Billing.RiskManagementConfiguration defines configuration per status. Billing.DepositSetRiskManagementStatus, Billing.RiskManagementCheckAdd, and Billing.LoadRiskManagementStatuses maintain the status lifecycle. Withdrawal risk mapping uses Billing.WithdrawToRiskManagementStatus and Billing.WithdrawalService_RiskManagementStatus_Add.

Reporting and PCI-safe procedures (Billing.GetDepositsCustomerCardPCIVersion, Billing.DepositAlertReportByRiskManagementStatus, BackOffice.BillingDepositsPCIVersion, BackOffice.NewRiskAlertsPCIVersion) use this table to resolve status IDs for dashboards and compliance alerts.

---

## 2. Business Logic

### 2.1 Deposit Risk Check Flow

**What**: The lifecycle of a deposit through the risk engine, resulting in a RiskManagementStatus assignment.

**Columns Involved**: `RiskManagementStatusID`, `Name`

**Rules**:
- **Success (1)**: Deposit passed all checks. Proceeds to payment processing.
- **Block/Decline statuses (2–69)**: Each ID maps to a specific rule or system that triggered the block — e.g., velocity (CreditCardVelocity, UserVelocity), funding restrictions (BlockedPayPalAccount, FundingTypeLimit), geographic (DeclinedBlackListCountry, BinToRegCountryConflict), KYC (KYCLevel0–3, KYCLevel3PendingReview), fraud (ML, SiftWorkFlow, BusinessRuleRisk), technical (InsufficientFunds, BalanceNotAvailable).

**Diagram**:
```
Deposit Risk Check Flow:

  Deposit Request
        │
        ▼
  ┌─────────────────────────────────┐
  │ Risk Engine (multiple rules)     │
  │ • Card/BIN blacklist             │
  │ • Velocity (card, user, FTD)     │
  │ • Country / regulation checks    │
  │ • KYC level checks              │
  │ • Fraud (ML, Sift)               │
  │ • Business rules                 │
  └─────────────────────────────────┘
        │
        ▼
  Billing.Deposit.RiskManagementStatusID
  Billing.RiskManagementCheck
  Billing.CreditCardAuthentication
        │
        ▼
  Dictionary.RiskManagementStatus (68 statuses)
  • 1 = Success
  • 2–69 = Block/Decline reason
```

---

## 3. Data Overview

| RiskManagementStatusID | Name | Meaning |
|---|---|---|
| 1 | Success | Deposit passed all risk checks. Proceeds to payment processing. |
| 2 | CardIsBlocked | Card is on internal block list. |
| 11 | DeclinedHighRiskDeposit | Deposit flagged as high risk by risk engine. |
| 32 | KYCLevel0 | KYC level 0 — insufficient verification for deposit. |
| 33 | KYCLevel1 | KYC level 1 check failed or not met. |
| 47 | ML | Machine learning / fraud model flagged the deposit. |
| 55 | ThreeDsVerificationFail | 3DS verification failed. |
| 63 | BinIsPrepaid | BIN identified as prepaid — may be restricted. |
| 69 | BusinessRuleRisk | Custom business rule triggered a block. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskManagementStatusID | int | NO | - | VERIFIED | Primary key identifying the risk check outcome. 1=Success, 2–69=block/decline reason. Referenced by Billing.Deposit, Billing.CreditCardAuthentication, Billing.RiskManagementCheck, Billing.RiskManagementConfiguration, Billing.WithdrawToRiskManagementStatus. Set via Billing.DepositSetRiskManagementStatus, Billing.RiskManagementCheckAdd. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable status label. UNIQUE (DRMS_NAME). Used for reporting, UI, and audit. 68 distinct values in live data (e.g., Success, CardIsBlocked, BinInBlackList, KYCLevel0, ML, BusinessRuleRisk). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | RiskManagementStatusID | FK | Deposit risk outcome per payment |
| Billing.CreditCardAuthentication | RiskManagementStatusID | FK | Risk status per auth attempt |
| Billing.RiskManagementCheck | RiskManagementStatusID | FK | Individual risk check results |
| Billing.RiskManagementConfiguration | RiskManagementStatusID | FK | Config per status |
| Billing.WithdrawToRiskManagementStatus | RiskManagementStatusID | FK | Withdrawal risk mapping |
| History.Deposit | RiskManagementStatusID | FK | Historical deposit snapshots |
| Billing.DepositSetRiskManagementStatus | @RiskManagementStatusID | Parameter | Sets status on deposit |
| Billing.RiskManagementCheckAdd | — | Parameter / Logic | Adds risk checks |
| Billing.LoadRiskManagementStatuses | — | Bulk load | Loads statuses |
| Billing.WithdrawalService_RiskManagementStatus_Add | — | Logic | Withdrawal risk status |
| Billing.DepositAlertReportByRiskManagementStatus | — | Report | Alerts by status |
| Billing.GetRiskManagementConfiguration | — | Config | Returns config by status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FK — stores RiskManagementStatusID per deposit |
| Billing.CreditCardAuthentication | Table | FK — risk status per auth |
| Billing.RiskManagementCheck | Table | FK — risk check results |
| Billing.RiskManagementConfiguration | Table | FK — config per status |
| Billing.WithdrawToRiskManagementStatus | Table | FK — withdrawal risk mapping |
| History.Deposit | Table | FK — historical snapshots |
| Billing.DepositSetRiskManagementStatus | Stored Procedure | Sets deposit status |
| Billing.RiskManagementCheckAdd | Stored Procedure | Adds risk checks |
| Billing.LoadRiskManagementStatuses | Stored Procedure | Bulk load |
| Billing.WithdrawalService_RiskManagementStatus_Add | Stored Procedure | Withdrawal risk |
| Billing.DepositAlertReportByRiskManagementStatus | Stored Procedure | Alert reporting |
| Billing.GetDepositsCustomerCardPCIVersion | Stored Procedure | PCI-safe deposit proc |
| BackOffice.BillingDepositsPCIVersion | View | BO deposit report |
| BackOffice.NewRiskAlertsPCIVersion | View | Risk alert report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DRMS | NONCLUSTERED PK | RiskManagementStatusID ASC | - | - | Active |
| DRMS_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DRMS | PRIMARY KEY | Unique RiskManagementStatusID. NONCLUSTERED. FILLFACTOR 90 on DICTIONARY filegroup. |
| DRMS_NAME | UNIQUE | Unique Name. FILLFACTOR 90. |

---

## 8. Sample Queries

### 8.1 List all risk management statuses
```sql
SELECT  RiskManagementStatusID,
        Name
FROM    Dictionary.RiskManagementStatus WITH (NOLOCK)
ORDER BY RiskManagementStatusID;
```

### 8.2 Count deposits by risk status (exclude Success)
```sql
SELECT  rms.Name,
        COUNT(*) AS DepositCount
FROM    Billing.Deposit d WITH (NOLOCK)
JOIN    Dictionary.RiskManagementStatus rms WITH (NOLOCK)
        ON d.RiskManagementStatusID = rms.RiskManagementStatusID
WHERE   d.RiskManagementStatusID <> 1
GROUP BY rms.Name
ORDER BY DepositCount DESC;
```

### 8.3 KYC-related block counts (statuses 32–37)
```sql
SELECT  rms.RiskManagementStatusID,
        rms.Name,
        COUNT(*) AS BlockCount
FROM    Billing.Deposit d WITH (NOLOCK)
JOIN    Dictionary.RiskManagementStatus rms WITH (NOLOCK)
        ON d.RiskManagementStatusID = rms.RiskManagementStatusID
WHERE   d.RiskManagementStatusID IN (32, 33, 34, 35, 36, 37)
GROUP BY rms.RiskManagementStatusID, rms.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12+ analyzed | Billing schema | Corrections: 0 applied*
*Object: Dictionary.RiskManagementStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RiskManagementStatus.sql*
