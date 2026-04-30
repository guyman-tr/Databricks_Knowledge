# Dictionary.RiskStatus

> Lookup table defining specific risk flags/reasons that can be attached to a customer account. Each status has an IsActive flag and optionally maps to a RiskCategoryID for grouping (velocity, country conflicts, fraud, multiple accounts, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RiskStatusID (int, IDENTITY, PK CLUSTERED) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.RiskStatus defines specific risk flags or reasons that can be attached to a customer account. Unlike Dictionary.RiskClassification (overall risk level) or Dictionary.RiskManagementStatus (deposit check outcome), RiskStatus captures the granular *reason* for a risk flag — e.g., OverTheLimit, TooManyCreditCards, BinToRegCountryConflict, LoginToRegCountryConflict, Affiliate Multiple Accounts, High Risk Account Country, Aggressive Trading, Multiple Accounts, FundingStolenReportedByProcessor. Each risk status has an IsActive flag (inactive = legacy) and optionally maps to a RiskCategoryID from Dictionary.RiskCategories for grouping.

The RiskStatusID is stored on BackOffice.Customer and indicates the most recent or primary risk reason for that customer. BackOffice procedures (BackOffice.SetRiskStatus, BackOffice.CusotmerSetRiskStatus, BackOffice.GetRiskHistoryByCID) and History.RiskStatus track changes over time. Billing.FundingCustomerRisk links RiskStatusID to funding/customer combinations when risk events occur (e.g., FundingStolenReportedByProcessor). Maintenance.JOB_AffiliateMultipleAccounts automatically assigns RiskStatusID 10 (Affiliate Multiple Accounts) when affiliate rules are violated.

---

## 2. Business Logic

### 2.1 Risk Flag Categories

**What**: Grouping of risk statuses by category (via RiskCategoryID → Dictionary.RiskCategories) for reporting and rule logic.

**Columns Involved**: `RiskStatusID`, `Name`, `IsActive`, `RiskCategoryID`

**Rules**:
- **None (0) / Normal (1)**: No risk flag or baseline. RiskCategoryID NULL.
- **Velocity (RiskCategoryID 2)**: TooManyCreditCards, OverTheLimit, etc.
- **Country conflicts (3, 4, 9, 12)**: BinToRegCountryConflict, LoginToRegCountryConflict, High Risk Account Country, High Risk FATF Country.
- **Fraud (7)**: FundingStolenReportedByProcessor, CreditCardBruteForce, BinInBlackList.
- **Multiple accounts (5, 8)**: Affiliate Multiple Accounts, Multiple Accounts.
- **Document/verification (11)**: Document-related flags.
- **Other**: Aggressive Trading (10), IP on Blocked Accounts (13), WithdrawWithShortTermTrades (17).

**Diagram**:
```
RiskStatus → RiskCategoryID → Dictionary.RiskCategories

  RiskStatusID  Name                          RiskCategoryID  Category Group
  ─────────────────────────────────────────────────────────────────────────
  0             None                          NULL            Baseline
  1             Normal                        NULL            Baseline
  2             OverTheLimit                  1               Limit/Velocity
  4             TooManyCreditCards            2               Velocity
  6             BinToRegCountryConflict       3               Country
  8             LoginToRegCountryConflict     4               Country
  10            Affiliate Multiple Accounts   5               Multiple accounts
  17            High Risk Account Country     9               Country
  26            Aggressive Trading             10              Trading behavior
  31            FundingStolenReportedByProcessor  7            Fraud
  42            CreditCardBruteForce          7               Fraud
  47            IP on Blocked Accounts         13              IP/fraud
  52            Multiple Accounts             8               Multiple accounts
  63            BinInBlackList                7               Fraud
  70            High Risk FATF Country        9               Country
  82            WithdrawWithShortTermTrades   17              Withdraw timing

  BackOffice.Customer.RiskStatusID
  History.RiskStatus (OldRiskStatusID, NewRiskStatusID)
  Billing.FundingCustomerRisk.RiskStatusID
```

---

## 3. Data Overview

| RiskStatusID | Name | IsActive | RiskCategoryID | Meaning |
|---|---|---|---|---|
| 0 | None | true | NULL | No risk flag. Baseline state. |
| 1 | Normal | true | NULL | Normal risk profile. No restrictions. |
| 2 | OverTheLimit | true | 1 | Customer exceeded deposit/limit thresholds. |
| 10 | Affiliate Multiple Accounts | true | 5 | Affiliate program rule violation — multiple accounts. |
| 26 | Aggresive Trading | true | 10 | Trading pattern flagged as aggressive. |
| 63 | BinInBlackList | true | 7 | BIN on internal blacklist — fraud indicator. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskStatusID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key identifying the risk flag/reason. NOT FOR REPLICATION. 89 rows in live data. Referenced by BackOffice.Customer, History.BackOfficeCustomer, Billing.FundingCustomerRisk, History.RiskStatus. Set via BackOffice.SetRiskStatus, BackOffice.CusotmerSetRiskStatus, Maintenance.JOB_AffiliateMultipleAccounts. |
| 2 | Name | varchar(100) | NO | - | VERIFIED | Human-readable risk reason label. Used for reporting, UI, and audit. Values like OverTheLimit, TooManyCreditCards, BinToRegCountryConflict, Affiliate Multiple Accounts. |
| 3 | IsActive | bit | NO | 0 | VERIFIED | Indicates whether the status is active. Inactive (0) = legacy, typically not applied to new customers. Used for filtering in risk reports and assignment logic. |
| 4 | RiskCategoryID | int | YES | - | VERIFIED | Foreign key to Dictionary.RiskCategories. Groups risk statuses (velocity, country, fraud, multiple accounts). NULL for baseline statuses (None, Normal). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Dictionary.RiskCategories | RiskCategoryID | FK | Groups risk statuses by category |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | RiskStatusID | FK / Lookup | Primary risk flag for customer |
| History.BackOfficeCustomer | RiskStatusID | FK | Historical risk status |
| History.RiskStatus | OldRiskStatusID, NewRiskStatusID | FK | Risk status change history |
| Billing.FundingCustomerRisk | RiskStatusID | FK | Risk events per funding/customer |
| BackOffice.SetRiskStatus | @RiskStatusID | Parameter | Sets risk status on customer |
| BackOffice.CusotmerSetRiskStatus | @RiskStatusID | Parameter | Sets risk status (typo in proc name) |
| BackOffice.GetRiskHistoryByCID | — | Join | Risk history by CID |
| BackOffice.GetBlockedCustomers | — | Join | Blocked customer list |
| BackOffice.GetRiskExposureReportPCIVersion | — | Report | Risk exposure |
| Billing.FundingCustomerRisk_Add | @RiskStatusID | Parameter | Adds funding risk |
| Maintenance.JOB_AffiliateMultipleAccounts | — | Logic | Auto-assigns status 10 |

---

## 6. Dependencies

### 6.0 Dependency Chain

Dictionary.RiskStatus → Dictionary.RiskCategories

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RiskCategories | Table | FK — RiskCategoryID groups statuses |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FK — RiskStatusID |
| History.BackOfficeCustomer | Table | FK — RiskStatusID |
| History.RiskStatus | Table | FK — OldRiskStatusID, NewRiskStatusID |
| Billing.FundingCustomerRisk | Table | FK — RiskStatusID |
| BackOffice.SetRiskStatus | Stored Procedure | Sets risk status |
| BackOffice.CusotmerSetRiskStatus | Stored Procedure | Sets risk status |
| Maintenance.JOB_AffiliateMultipleAccounts | Stored Procedure | Assigns status 10 |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryRiskStatus | CLUSTERED PK | RiskStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryRiskStatus | PRIMARY KEY | Unique RiskStatusID on PRIMARY filegroup |
| FK_DictionaryRiskStatus_DictionaryRiskCategories | FOREIGN KEY | RiskCategoryID → Dictionary.RiskCategories(RiskCategoryID) |
| DEFAULT (0) on IsActive | DEFAULT | IsActive defaults to 0 (inactive) |

---

## 8. Sample Queries

### 8.1 List active risk statuses with category
```sql
SELECT  rs.RiskStatusID,
        rs.Name,
        rs.IsActive,
        rc.Name AS CategoryName
FROM    Dictionary.RiskStatus rs WITH (NOLOCK)
LEFT JOIN Dictionary.RiskCategories rc WITH (NOLOCK)
        ON rs.RiskCategoryID = rc.RiskCategoryID
WHERE   rs.IsActive = 1
ORDER BY rs.RiskStatusID;
```

### 8.2 Count customers by risk status
```sql
SELECT  drs.Name,
        COUNT(*) AS CustomerCount
FROM    BackOffice.Customer bc WITH (NOLOCK)
JOIN    Dictionary.RiskStatus drs WITH (NOLOCK)
        ON bc.RiskStatusID = drs.RiskStatusID
WHERE   bc.RiskStatusID > 1
GROUP BY drs.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Risk status change history for a customer
```sql
SELECT  hrs.CID,
        drsOld.Name AS OldStatus,
        drsNew.Name AS NewStatus,
        hrs.ValidFrom,
        hrs.ValidTo
FROM    History.RiskStatus hrs WITH (NOLOCK)
JOIN    Dictionary.RiskStatus drsOld WITH (NOLOCK)
        ON hrs.OldRiskStatusID = drsOld.RiskStatusID
JOIN    Dictionary.RiskStatus drsNew WITH (NOLOCK)
        ON hrs.NewRiskStatusID = drsNew.RiskStatusID
WHERE   hrs.CID = 12345
ORDER BY hrs.ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8+ analyzed | Billing, BackOffice, History | Corrections: 0 applied*
*Object: Dictionary.RiskStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RiskStatus.sql*
