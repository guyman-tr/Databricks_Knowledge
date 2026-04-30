# History.RiskStatus

> Audit log of customer risk status changes recorded between 2010-2017, capturing who changed which customer's risk classification from what old status to what new status and for what validity period.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ID) |

---

## 1. Business Meaning

This table is the **legacy customer risk status change audit log**, recording every time a BackOffice manager manually changed a customer's risk flag between 2010 and 2017. Each row records: which customer (CID), what risk status was removed (OldRiskStatusID), what risk status was applied (NewRiskStatusID), who made the change (ManagerID), and the validity period (ValidFrom/ValidTo).

The table was the primary risk status audit trail in the early eToro risk management system. It supported a validity-period model where `ValidTo = '3000-01-01'` indicates the current active status for a customer, and a specific date indicates when the status was superseded.

Around 2017, risk status management was refactored. `BackOffice.CustomerSetRiskStatus` (the primary writer) was updated to write to `BackOffice.CustomerRisk` + `History.CustomerRisk` instead of `History.RiskStatus`. The old INSERT logic is preserved in comments within the procedure. This table is now a read-only historical archive with 78,941 records covering September 2010 through May 2017.

---

## 2. Business Logic

### 2.1 Risk Status Change Tracking

**What**: Each row represents a single risk classification event - a BackOffice manager flagging or clearing a customer risk issue.

**Columns/Parameters Involved**: `CID`, `OldRiskStatusID`, `NewRiskStatusID`, `ManagerID`, `ValidFrom`, `ValidTo`

**Rules**:
- `ValidTo = '3000-01-01'` is the sentinel value for "currently active" - the status has not been superseded
- When a new risk status is assigned, the previous row's ValidTo was set to the current date, and a new row was inserted with ValidFrom = now, ValidTo = '3000-01-01'
- ManagerID=0 appears in records where the change was made by an automated system (e.g., Maintenance.JOB_AffiliateMultipleAccounts auto-sets risk status 10 = Affiliate Multiple Accounts)
- A customer can have multiple active rows (one per distinct risk issue they currently have)

**Diagram**:
```
Customer gets flagged:
  Old row: ValidFrom=T1, ValidTo=T1 (updated from 3000-01-01 to T1)
  New row: ValidFrom=T1, ValidTo=3000-01-01, OldStatus=X, NewStatus=Y

Customer cleared to Normal (1):
  Old row: ValidTo=T2 (closed)
  New row: ValidFrom=T2, ValidTo=3000-01-01, OldStatus=Y, NewStatus=1
```

### 2.2 Risk Status Taxonomy

**What**: The risk status values classify customers by fraud/risk vector category.

**Columns/Parameters Involved**: `OldRiskStatusID`, `NewRiskStatusID`

**Rules**:
- 0=None (unset), 1=Normal (cleared)
- Fraud/chargeback: 2=OverTheLimit, 3=FTDOverDailyLimit, 4=TooManyCreditCards, 5=TooManyPayPalAccounts
- Country conflicts: 6=BinToRegCountryConflict, 7=DepositNameConflict, 8=LoginToRegCountryConflict
- Affiliates: 10=AffiliateMultipleAccounts, 11=AffiliateDormantAccounts
- Document issues: 30=Poor/FakeDocs, 43=AllDocsFake, 45=FakeBills, 46=FakeID, 48=InvalidEmailAddress
- Velocity: 39=CreditCardVelocity, 40=UserVelocity, 41=First24HVelocity, 66=TooManyDeclines
- AML/sanctions: 17=HighRiskAccountCountry, 70=HighRiskFATFCountry
- Investigation: 12=PayPalInvestigation, 37=FraudRequestResponseMismatch, 42=CreditCardBruteForce
- Multiple/related accounts: 52=MultipleAccounts, 58=RelatedAccountsBlocked, 76=MultipleAccountsFunding
- Withdrawal patterns: 82=WithdrawWithShortTermTrades, 83=WithdrawWithLowTradingRatio
- Full list: 90 defined values (0-90, with gaps); inactive statuses marked IsActive=false in Dictionary.RiskStatus

---

## 3. Data Overview

| ID | CID | OldRiskStatusID | NewRiskStatusID | ManagerID | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|
| 79941 | 692008 | 7 (DepositNameConflict) | 1 (Normal) | 723 | 2017-05-22 | 3000-01-01 | Manager 723 cleared customer 692008's DepositNameConflict flag on May 22, 2017; current active record (ValidTo=3000-01-01) |
| 79940 | 1188675 | 10 (AffiliateMultipleAccounts) | 7 (DepositNameConflict) | 0 (system) | 2017-03-06 | 3000-01-01 | Automated job changed status from Affiliate Multiple Accounts to DepositNameConflict on March 6, 2017 |
| 79939 | 1652737 | 68 (MultiplePaymentMethods) | 7 (DepositNameConflict) | 0 (system) | 2017-02-15 | 3000-01-01 | System-automated risk reclassification from MultiplePaymentMethods to DepositNameConflict |
| 79938 | 28 | 6 (BinToRegCountryConflict) | 5 (TooManyPayPalAccounts) | 723 | 2017-02-15 | 3000-01-01 | Manager 723 changed CID 28's risk from BIN-country conflict to PayPal account volume flag |
| 79937 | 3635307 | 1 (Normal) | 7 (DepositNameConflict) | 0 (system) | 2017-02-15 | 3000-01-01 | System flagged previously-normal customer with DepositNameConflict risk |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology usage. Uniquely identifies each risk status change event. |
| 2 | CID | int | YES | - | VERIFIED | Customer ID whose risk status changed. FK to Customer.CustomerStatic. Nullable in DDL (but in practice all rows reference real customers). The customer for whom this risk audit trail applies. |
| 3 | OldRiskStatusID | int | YES | - | VERIFIED | The risk status the customer had BEFORE this change. FK to Dictionary.RiskStatus. Key values: 0=None, 1=Normal (cleared state), 2-90=various fraud/risk flags. See Section 2.2 for full taxonomy. Nullable for the very first entry when no prior risk was assigned. |
| 4 | NewRiskStatusID | int | YES | - | VERIFIED | The risk status assigned to the customer by this event. FK to Dictionary.RiskStatus. Same value set as OldRiskStatusID. Setting NewRiskStatusID=1 (Normal) is the "clearing" action - a customer is no longer considered at risk. |
| 5 | ManagerID | int | YES | - | VERIFIED | BackOffice manager who made this risk status change. FK to BackOffice.Manager. ManagerID=0 indicates an automated system change (e.g., Maintenance.JOB_AffiliateMultipleAccounts batch job). Nullable in DDL but populated for all known records. |
| 6 | ValidFrom | datetime | YES | - | CODE-BACKED | Timestamp when this risk status assignment became effective. Set to GETUTCDATE() at time of INSERT by the (now-commented) code in BackOffice.CustomerSetRiskStatus. |
| 7 | ValidTo | datetime | YES | - | CODE-BACKED | Timestamp when this risk status assignment ended. Sentinel value '3000-01-01' means the status is still active (never superseded). A specific date means this status was replaced by a new assignment at that time. Nullable in DDL. Used to implement the active-period pattern: filter WHERE ValidTo = '3000-01-01' to get the current risk status per customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK | Customer whose risk status changed. |
| OldRiskStatusID | Dictionary.RiskStatus | FK | Previous risk classification: 0=None, 1=Normal, 2-90=various risk flags. |
| NewRiskStatusID | Dictionary.RiskStatus | FK | New risk classification applied. Same lookup as OldRiskStatusID. |
| ManagerID | BackOffice.Manager | FK | BackOffice staff who made the change; 0=automated system. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerSetRiskStatus | INSERT (commented out) | Writer (legacy) | The INSERT/UPDATE logic for this table is preserved in comments; the procedure now writes to History.CustomerRisk instead. |
| Maintenance.JOB_AffiliateMultipleAccounts | INSERT (presumed) | Writer (legacy) | Automated job that flagged affiliate multiple-account risk; likely wrote to this table before 2017 migration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RiskStatus (table)
  (leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK on CID - validates customer reference. |
| BackOffice.Manager | Table | FK on ManagerID - validates who made the change. |
| Dictionary.RiskStatus | Table | FK on OldRiskStatusID and NewRiskStatusID - validates risk status values. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerSetRiskStatus | Procedure | Had INSERT/UPDATE logic for this table (now commented out - migrated to History.CustomerRisk) |
| Maintenance.JOB_AffiliateMultipleAccounts | Procedure | References History.RiskStatus for affiliate multiple-account detection |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryRiskStatus | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryRiskStatus | PRIMARY KEY | Uniqueness on ID. CLUSTERED. |
| FK_HistoryRiskStatus_BackOfficeManager | FOREIGN KEY | ManagerID -> BackOffice.Manager |
| FK_HistoryRiskStatus_CustomerCustomer | FOREIGN KEY | CID -> Customer.CustomerStatic |
| FK_HistoryRiskStatus_OldRiskStatusID_DictionaryRiskStatus | FOREIGN KEY | OldRiskStatusID -> Dictionary.RiskStatus |
| FK_HistoryRiskStatus_NewRiskStatusID_DictionaryRiskStatus | FOREIGN KEY | NewRiskStatusID -> Dictionary.RiskStatus |

---

## 8. Sample Queries

### 8.1 Get risk status change history for a specific customer
```sql
SELECT
    rs.ID,
    dr_old.Name AS OldStatus,
    dr_new.Name AS NewStatus,
    rs.ManagerID,
    rs.ValidFrom,
    rs.ValidTo
FROM [History].[RiskStatus] rs WITH (NOLOCK)
LEFT JOIN [Dictionary].[RiskStatus] dr_old WITH (NOLOCK) ON dr_old.RiskStatusID = rs.OldRiskStatusID
LEFT JOIN [Dictionary].[RiskStatus] dr_new WITH (NOLOCK) ON dr_new.RiskStatusID = rs.NewRiskStatusID
WHERE rs.CID = @CID
ORDER BY rs.ValidFrom DESC
```

### 8.2 Find customers who had a specific risk status active
```sql
SELECT
    rs.CID,
    dr_new.Name AS RiskStatus,
    rs.ValidFrom,
    rs.ValidTo,
    rs.ManagerID
FROM [History].[RiskStatus] rs WITH (NOLOCK)
JOIN [Dictionary].[RiskStatus] dr_new WITH (NOLOCK) ON dr_new.RiskStatusID = rs.NewRiskStatusID
WHERE rs.NewRiskStatusID = @RiskStatusID
  AND rs.ValidTo = '30000101'  -- currently active records
ORDER BY rs.ValidFrom DESC
```

### 8.3 Most common risk flags applied (historical frequency)
```sql
SELECT
    dr.Name AS RiskStatus,
    COUNT(*) AS TimesFlagged,
    SUM(CASE WHEN rs.ValidTo = '30000101' THEN 1 ELSE 0 END) AS StillActive,
    MIN(rs.ValidFrom) AS FirstSeen,
    MAX(rs.ValidFrom) AS LastSeen
FROM [History].[RiskStatus] rs WITH (NOLOCK)
JOIN [Dictionary].[RiskStatus] dr WITH (NOLOCK) ON dr.RiskStatusID = rs.NewRiskStatusID
WHERE rs.NewRiskStatusID != 1  -- exclude "Normal" (clearings)
GROUP BY rs.NewRiskStatusID, dr.Name
ORDER BY TimesFlagged DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RiskStatus | Type: Table | Source: etoro/etoro/History/Tables/History.RiskStatus.sql*
