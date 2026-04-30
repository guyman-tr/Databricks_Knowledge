# BackOffice.CustomerRisk

> Active risk flag registry tracking all risk alerts raised against customers, used by Risk team to monitor fraud indicators, AML triggers, deposit velocity, document quality, and behavioral anomalies.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (GCID, RiskStatusID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (1 clustered composite PK) |

---

## 1. Business Meaning

BackOffice.CustomerRisk is the Risk team's central alert registry. Each row represents one active risk flag against a customer group (GCID), recording what type of risk was detected, when it occurred, whether it's still active, and which BackOffice agent last modified it. A customer may have multiple simultaneous risk flags (multiple rows with the same GCID but different RiskStatusIDs), creating a multi-dimensional risk profile.

The table drives the risk management workflow in BackOffice: when automated risk rules fire (e.g., velocity checks, country conflicts, FATF country detection), they write rows here. BackOffice Risk agents then review, investigate (InProcess), and resolve (Off) these flags. The table also drives account restrictions - customers with active risk flags may have deposits blocked, withdrawals suspended, or accounts frozen depending on the risk type.

1.46M total rows for 1.36M unique customer groups, with 93% currently "On" (active risk flags). The composite PK on (GCID, RiskStatusID) ensures one row per risk type per customer group, supporting efficient upserts via CustomerSetRiskStatus/SetRiskStatus procedures.

---

## 2. Business Logic

### 2.1 Risk Category Classification

**What**: Risk statuses are grouped into categories representing the nature of the detected risk, enabling the Risk team to filter and prioritize by risk domain.

**Columns Involved**: `RiskStatusID`

**Rules**:
- Category 1 (Deposit Limits): OverTheLimit, FTDOverDailyLimit, OverTheLimitSingleDeposit, PMWBChargeback, BlacklistedRegistrationIp, FtdsWithSameRegistrationIp
- Category 2 (Payment Velocity): TooManyCreditCards, TooManyPayPalAccounts, CreditCardVelocity, UserVelocity, First24HVelocity, TooManyMoPs, TooManyDeclines, MultiplePaymentMethods, eToroCardVelocity, FirstHoursFromFtdVelocity
- Category 3 (Identity Conflicts): BinToRegCountryConflict, DepositNameConflict, NameConflict, WithdrawCountryConflict
- Category 4 (Geo Conflicts): LoginToRegCountryConflict
- Category 5 (Affiliate): AffiliateMultipleAccounts
- Category 6 (Dormant Affiliates): AffiliateDormantAccounts
- Category 7 (Fraud): PayPalInvestigation, FundingStolenReportedByProcessor, FraudRequestResponseMismatch, CreditCardBruteForce, BinInBlackList, SuspiciousDepositPattern, RafDeclineFundingAlreadyExists, ACHInvestigation, CreditcardInvestigation
- Category 8 (Multiple Accounts): Relations, MultipleAccounts, RelatedAccountsBlocked, MultipleAccountsFunding, HighFtd, HighTotalDepositsWithinFirstHoursFromFtd
- Category 9 (High Risk Country): HighRiskAccountCountry, HighRiskFATFCountry
- Category 10 (Trading Behavior): AggressiveTrading
- Category 11 (Document Quality): NotCommunicative, Poor/FakeDocs, FakeBills, FakeID, InvalidEmailAddress, InvalidPhoneNumber, InvalidDetails, PendingVerification
- Category 12 (Login Geo): HighRiskLoginCountry, HRCLoginToRegCountryConflict
- Category 13 (IP): IPOnBlockedAccounts
- Category 14 (Card): PickUp/RetainCC
- Category 15 (Suspicious Affiliate): SuspiciousAffiliate
- Category 16 (Withdraw): IPBlackList, WithdrawNameConflict
- Category 17 (Withdraw Behavior): WithdrawWithShortTermTrades, WithdrawWithLowTradingRatio

### 2.2 Risk Event Lifecycle

**What**: Each risk flag moves through a lifecycle from detection to resolution.

**Columns Involved**: `RiskEventStatusID`, `Occurred`, `ModifiedDate`, `ManagerID`, `Remark`

**Rules**:
- RiskEventStatusID=1 (On): Active risk flag - risk rule triggered or manually set. Requires Risk team review
- RiskEventStatusID=2 (InProcess): Under investigation by a Risk agent. ManagerID identifies who is working it
- RiskEventStatusID=3 (Off): Resolved/cleared. Flag no longer active (IsActive=false in dictionary)
- Occurred: When the risk event originally happened (default GETUTCDATE()). Some historical rows have Occurred='1900-01-01' indicating unknown/missing event time from legacy imports
- ModifiedDate: When the flag was last changed (automatic GETUTCDATE() default, updated on every modification)
- Remark: Free-text agent note explaining the risk situation or resolution rationale

**Diagram**:
```
Automated Rule Fires           BackOffice Agent Action
       |                              |
       v                              v
INSERT (On, Occurred=now)    UPDATE RiskEventStatusID
       |                         1=On -> 2=InProcess
       |                         2=InProcess -> 3=Off
       v                         3=Off -> 1=On (re-flag)
Risk Queue in BackOffice UI
```

---

## 3. Data Overview

| GCID | RiskStatusID | RiskStatus | RiskEventStatusID | Meaning |
|------|-------------|-----------|------------------|---------|
| (any) | 2 (OverTheLimit) | OverTheLimit | 1 (On) | Customer's total deposits exceed the configured limit threshold. Risk team must verify source of funds and identity before allowing further deposits. Category 1. |
| (any) | 46 (Fake ID) | Fake ID | 1 (On) | AI vendor or BackOffice agent determined the submitted ID document is counterfeit. Account access restricted pending re-verification. Category 11. |
| (any) | 70 (HighRiskFATFCountry) | High Risk FATF Country | 1 (On) | Customer's country is on the FATF (Financial Action Task Force) high-risk list. Enhanced due diligence required under AML regulations. Category 9. |
| (any) | 42 (CreditCardBruteForce) | CreditCardBruteForce | 2 (InProcess) | Multiple failed credit card attempts detected - possible stolen card testing. Under active Risk investigation. Category 7. |
| (any) | 82 (WithdrawWithShortTermTrades) | WithdrawWithShortTermTrades | 1 (On) | Withdrawal pattern detected alongside very short-term trading - possible bonus abuse or scalping/front-running behavior. Category 17. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Group Customer ID - person-level identifier spanning all accounts across regulatory jurisdictions. Part of composite PK. A customer can have multiple risk flags (different RiskStatusIDs for same GCID). See BackOffice.CustomerDocument for GCID description. |
| 2 | RiskStatusID | int | NO | - | VERIFIED | The specific risk alert type. Part of composite PK. FK to Dictionary.RiskStatus. 90 defined types (0=None, 1=Normal, 2-90=specific risk flags). Active types include: velocity checks (2,3,38-42,61,66,68,74,88), country/geo conflicts (6,7,8,17,28,32,72,87), fraud indicators (12,31,37,42,63,64,69,73,89,90), document quality (30,43,45,46,48-50,62,71), affiliate abuse (10,11,60), AML/behavior (26,29,70,82,83). Inactive types (IsActive=false) represent deprecated risk categories. |
| 3 | Occurred | datetime | YES | GETUTCDATE() | VERIFIED | Timestamp when the risk event originally occurred. Defaults to current UTC time on INSERT. Historical rows with '1900-01-01' indicate legacy imports where the original event time was unknown. |
| 4 | ModifiedDate | datetime | NO | GETUTCDATE() | VERIFIED | Timestamp of the last status change or update to this risk flag. Always reflects the most recent modification. Used for risk queue ordering and SLA tracking. |
| 5 | Remark | varchar(255) | YES | - | CODE-BACKED | Free-text note by the Risk agent explaining the risk situation, investigation findings, or resolution rationale. Optional - may be NULL for automatically-generated flags before agent review. |
| 6 | RiskEventStatusID | int | NO | - | VERIFIED | Current lifecycle status of the risk flag. FK to Dictionary.RiskEventStatus. Values: 1=On (active, requires attention), 2=InProcess (under investigation), 3=Off (resolved/cleared, dictionary IsActive=false). 1.37M rows are On, 97K are InProcess or Off. |
| 7 | ManagerID | int | YES | - | CODE-BACKED | BackOffice Risk agent who last modified this flag. NULL for system-generated flags not yet reviewed. FK to BackOffice.Manager (no constraint). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RiskStatusID | Dictionary.RiskStatus | FK (WITH CHECK) | Classifies the type of risk detected |
| RiskEventStatusID | Dictionary.RiskEventStatus | FK (WITH CHECK) | Current lifecycle state of the alert |
| GCID | Customer.CustomerStatic (GCID) | Implicit | Cross-account person identity link |
| ManagerID | BackOffice.Manager | Implicit FK | Agent who last modified the flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerSetRiskStatus | GCID, RiskStatusID | WRITER/MODIFIER | Creates or updates risk flags |
| BackOffice.SetRiskStatus | GCID, RiskStatusID | WRITER/MODIFIER | Alternative risk status setter |
| BackOffice.GetCustomerRisks | GCID | READER | Returns all risk flags for a customer |
| BackOffice.GetRiskHistoryByCID | CID/GCID | READER | Risk history reporting |
| BackOffice.NewRiskAlertsPCIVersion | - | READER | New risk alert report (PCI-compliant) |
| BackOffice.CustomerRiskOccurredCheck | GCID | READER | Checks if specific risk occurred |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerRisk (table)
- FK targets: Dictionary.RiskStatus (table), Dictionary.RiskEventStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RiskStatus | Table | FK constraint on RiskStatusID |
| Dictionary.RiskEventStatus | Table | FK constraint on RiskEventStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerSetRiskStatus | Procedure | WRITER/MODIFIER - primary risk flag management |
| BackOffice.SetRiskStatus | Procedure | WRITER/MODIFIER - risk status setter |
| BackOffice.GetCustomerRisks | Procedure | READER - per-customer risk profile |
| BackOffice.GetRiskHistoryByCID | Procedure | READER - historical risk audit |
| BackOffice.NewRiskAlertsPCIVersion | Procedure | READER - new alerts report |
| BackOffice.CustomerRiskOccurredCheck | Procedure | READER - point-in-time risk check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOfficeCustomerRisk | CLUSTERED PK | GCID ASC, RiskStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BackOfficeCustomerRiskOccurred | DEFAULT | Occurred = GETUTCDATE() |
| DF_BackOfficeCustomerRiskModificationDate | DEFAULT | ModifiedDate = GETUTCDATE() |
| FK_BackOfficeCustomerRisk | FK | RiskStatusID -> Dictionary.RiskStatus(RiskStatusID) |
| FK_BackOfficeCustomerRisk_DictionaryRiskEventStatus | FK | RiskEventStatusID -> Dictionary.RiskEventStatus(RiskEventStatusID) |

---

## 8. Sample Queries

### 8.1 Get all active risk flags for a customer (by GCID)
```sql
SELECT
    cr.GCID,
    rs.Name AS RiskType,
    res.Name AS Status,
    cr.Occurred,
    cr.ModifiedDate,
    cr.Remark,
    m.FirstName + ' ' + m.LastName AS LastModifiedBy
FROM BackOffice.CustomerRisk cr WITH (NOLOCK)
JOIN Dictionary.RiskStatus rs WITH (NOLOCK) ON rs.RiskStatusID = cr.RiskStatusID
JOIN Dictionary.RiskEventStatus res WITH (NOLOCK) ON res.RiskEventStatusID = cr.RiskEventStatusID
LEFT JOIN BackOffice.Manager m WITH (NOLOCK) ON m.ManagerID = cr.ManagerID
WHERE cr.GCID = 12345  -- replace with target GCID
ORDER BY cr.ModifiedDate DESC
```

### 8.2 Get all active fraud indicators across the platform
```sql
SELECT
    cr.GCID,
    rs.Name AS RiskType,
    cr.Occurred,
    cr.Remark
FROM BackOffice.CustomerRisk cr WITH (NOLOCK)
JOIN Dictionary.RiskStatus rs WITH (NOLOCK) ON rs.RiskStatusID = cr.RiskStatusID
WHERE cr.RiskEventStatusID = 1  -- On
  AND rs.RiskCategoryID = 7  -- Fraud category
ORDER BY cr.Occurred DESC
```

### 8.3 Get new risk alerts from the last 24 hours
```sql
SELECT
    cr.GCID,
    rs.Name AS RiskType,
    cr.Occurred,
    cr.ModifiedDate,
    cr.Remark
FROM BackOffice.CustomerRisk cr WITH (NOLOCK)
JOIN Dictionary.RiskStatus rs WITH (NOLOCK) ON rs.RiskStatusID = cr.RiskStatusID
WHERE cr.RiskEventStatusID = 1  -- On
  AND cr.ModifiedDate >= DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY cr.ModifiedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.8/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerRisk | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerRisk.sql*
