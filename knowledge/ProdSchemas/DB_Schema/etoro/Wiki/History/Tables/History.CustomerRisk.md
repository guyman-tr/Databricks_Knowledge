# History.CustomerRisk

> Audit log table recording previous states of customer risk flag events - each row captures the "before" state of a risk classification whenever its event status changes in BackOffice.CustomerRisk.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY PK, CLUSTERED, NOT FOR REPLICATION) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ID) |

---

## 1. Business Meaning

This table is the **manual audit log** for changes to customer risk event statuses. It is NOT a SQL Server temporal table - rows are explicitly inserted by `BackOffice.SetRiskStatus` whenever a risk flag on a customer changes its event state (e.g., from `On` to `InProcess`). Each row captures the previous state of that risk record before the change was applied.

The companion current-state table is `BackOffice.CustomerRisk`, which holds the live set of active risk flags per customer. When a back-office agent or automated system updates a risk flag's status, the old state is preserved in this table for compliance and investigation purposes. A customer can have multiple simultaneous risk flags (one row per `RiskStatusID`), and each change to any flag generates one history row.

This table serves the risk management, fraud, and AML (Anti-Money Laundering) teams who need to answer: "What was the risk status of this customer at time X?", "When did this risk flag change?", and "Who made the change?". With 140,000+ rows spanning from 2010, it is the primary audit trail for eToro's customer risk classification system.

---

## 2. Business Logic

### 2.1 How History Is Written (BackOffice.SetRiskStatus Flow)

**What**: History rows are explicitly inserted only when an existing risk flag's event status changes - not on initial flag creation.

**Columns/Parameters Involved**: `GCID`, `RiskStatusID`, `RiskEventStatusID`, `Occurred`, `ModifiedDate`, `ManagerID`

**Rules**:
- **Case 1 - Existing flag with different status**: Customer already has RiskStatusID X with status A. Caller requests status B. Action:
  1. Current row from BackOffice.CustomerRisk is copied to History.CustomerRisk (the "before" state). `ModifiedDate` = NOW (time of this history write).
  2. BackOffice.CustomerRisk is updated: RiskEventStatusID = B, ManagerID = @ManagerID, ModifiedDate = NOW.
- **Case 2 - New risk flag**: Customer does not have RiskStatusID X (or does but with the same status). Action: INSERT to BackOffice.CustomerRisk only. No history row is created.
- `Occurred` in the history row carries the original timestamp from BackOffice.CustomerRisk (when the risk was first raised), NOT when the history was written. Use `ModifiedDate` to know when the change occurred.

**Diagram**:
```
Customer CID=1234 has risk flag: RiskStatusID=1 (Normal), RiskEventStatusID=1 (On)

BackOffice agent calls: BackOffice.SetRiskStatus(@CID=1234, @RiskStatusID=1, @ManagerID=567, @RiskEventStatusID=2)

Step 1: Copy current row to History.CustomerRisk:
  INSERT: GCID=..., RiskStatusID=1, Occurred=ORIGINAL_TIME, ModifiedDate=NOW, RiskEventStatusID=1 (old), ManagerID=OLD_MANAGER

Step 2: Update BackOffice.CustomerRisk:
  SET RiskEventStatusID=2 (InProcess), ManagerID=567, ModifiedDate=NOW
```

### 2.2 Risk Status Classification System

**What**: RiskStatusID classifies the type of risk concern raised for a customer, grouped into categories.

**Columns/Parameters Involved**: `RiskStatusID`, `RiskEventStatusID`

**Rules**:
- `RiskStatusID` references Dictionary.RiskStatus (90 statuses, many inactive/legacy). Active statuses span categories including: deposit velocity (2=OverTheLimit, 38=OverTheLimitSingleDeposit), fraud (37=FraudRequestResponseMismatch, 42=CreditCardBruteForce, 63=BinInBlackList), identity conflicts (6=BinToRegCountryConflict, 7=DepositNameConflict, 28=NameConflict), AML (86=AML-Suspicious activity), and more.
- `RiskEventStatusID` references Dictionary.RiskEventStatus: **1=On** (risk is active/confirmed), **2=InProcess** (risk is being investigated), **3=Off** (inactive, deprecated status).
- A customer can have multiple simultaneous risk flags of different `RiskStatusID` values - each is tracked independently.
- `ManagerID=0` in sample data indicates automated system-generated risk flags (no human manager); non-zero values identify the back-office agent.

**Diagram**:
```
RiskStatus categories (sample):
  Category 1 (Deposit limits):  2=OverTheLimit, 3=FTDOverDailyLimit, 38=OverTheLimitSingleDeposit
  Category 2 (Velocity):        4=TooManyCreditCards, 39=CreditCardVelocity, 40=UserVelocity
  Category 3 (Conflicts):       6=BinToRegCountryConflict, 7=DepositNameConflict, 28=NameConflict
  Category 7 (Fraud):           31=FundingStolenReportedByProcessor, 63=BinInBlackList, 64=SuspiciousDepositPattern
  Category 8 (Relations):       14=Relations, 52=MultipleAccounts, 58=RelatedAccountsBlocked
  Category 11 (Documentation):  29=NotCommunicative, 30=Poor/FakeDocs, 46=FakeID, 71=PendingVerification

RiskEventStatus lifecycle:
  [New risk detected] -> RiskEventStatusID=1 (On) -> [Review started] -> RiskEventStatusID=2 (InProcess)
  -> [Resolved/cleared in BackOffice.CustomerRisk, not here]
```

---

## 3. Data Overview

| ID | GCID | RiskStatusID | RiskEventStatusID | Occurred | ModifiedDate | Meaning |
|----|------|-------------|------------------|---------|--------------|---------|
| 140597 | 4101059 | 63 (BinInBlackList) | 1 (On) | 2026-01-21 08:21 | 2024-07-25 09:19 | BIN blacklist risk on customer 4101059: at the time this history row was written (Jan 2026), the risk was in On state. The old ModifiedDate (Jul 2024) suggests this risk had not been reviewed for 18 months. |
| 140596 | 17657110 | 1 (Normal) | 1 (On) | 2026-01-04 16:50 | 2026-01-04 16:50 | Customer 17657110, Normal risk status transitioning from On - one of four history rows written within 1 minute, indicating an automated bulk risk reclassification. |
| 140595 | 17657110 | 1 (Normal) | 1 (On) | 2026-01-04 16:50 | 2026-01-04 16:50 | Same customer, same risk status - another version captured moments later. Multiple rapid history writes suggest automated processing with intermediate states. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY | CODE-BACKED | Surrogate primary key, auto-incremented. NOT FOR REPLICATION prevents identity synchronization in replication topologies. Uniquely identifies each history record. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Identifies the customer whose risk flag is being logged. FK to Customer.CustomerStatic (GCID column). The BackOffice.SetRiskStatus procedure joins via Customer.CustomerStatic to translate CID->GCID before writing. |
| 3 | RiskStatusID | int | NO | - | VERIFIED | The type of risk flag. FK to Dictionary.RiskStatus. Active values include: 1=Normal, 2=OverTheLimit, 3=FTDOverDailyLimit, 4=TooManyCreditCards, 6=BinToRegCountryConflict, 7=DepositNameConflict, 26=AggressiveTrading, 28=NameConflict, 37=FraudRequestResponseMismatch, 38=OverTheLimitSingleDeposit, 42=CreditCardBruteForce, 63=BinInBlackList, 64=SuspiciousDepositPattern, 67=IPBlackList, 69=RafDeclineFundingAlreadyExists, and many more. 90 total values; many legacy statuses are inactive (IsActive=false). |
| 4 | RiskStatusID (see 3) | - | - | - | - | (see above - full value list in Dictionary.RiskStatus) |
| 5 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | The UTC timestamp when the risk flag was originally raised (carried from BackOffice.CustomerRisk at the time this history row was written). This is NOT the time when this history row was written - use ModifiedDate for that. Enables reconstructing when a risk event first occurred. |
| 6 | ModifiedDate | datetime | NO | getutcdate() | VERIFIED | The UTC timestamp when this history row was written - i.e., when BackOffice.SetRiskStatus executed the INSERT to this table. Represents the exact moment the risk status changed. Defaults to getutcdate() at insert time. |
| 7 | Remark | varchar(255) | YES | - | CODE-BACKED | Free-text note explaining the reason for the risk flag, entered by the back-office agent. NULL for system-automated risk flags. Carries over from BackOffice.CustomerRisk at the time the history row is written. |
| 8 | RiskEventStatusID | int | NO | - | VERIFIED | The event status of the risk flag at the time this history row was written (i.e., the "before" state). FK to Dictionary.RiskEventStatus: 1=On (risk actively flagged), 2=InProcess (under investigation), 3=Off (deprecated). After this history row is written, BackOffice.CustomerRisk is updated to the new status. |
| 9 | ManagerID | int | YES | - | CODE-BACKED | The back-office manager ID who set this risk status, carried from BackOffice.CustomerRisk. 0 = system-automated (no human agent). NULL = not recorded. Non-zero values reference BackOffice.Manager. Enables accountability tracking for manual risk decisions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Customer.CustomerStatic | Implicit | The customer whose risk flag changed |
| RiskStatusID | Dictionary.RiskStatus | Implicit | The type of risk classification |
| RiskEventStatusID | Dictionary.RiskEventStatus | Implicit | The event status at time of history capture: 1=On, 2=InProcess, 3=Off |
| ManagerID | BackOffice.Manager | Implicit | The back-office agent who made the change (0 = automated) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.SetRiskStatus | History.CustomerRisk | Writer | Primary writer - inserts one row per risk status event state change |
| BackOffice.GetRiskHistoryByCID | History.CustomerRisk | Reader | Reads full risk history for a customer for back-office investigation |
| BackOffice.GetUserRisksByCID | History.CustomerRisk | Reader | Aggregates risk history by customer |
| BackOffice.GetUserRisksByCID_AGG | History.CustomerRisk | Reader | Aggregated risk history query |
| BackOffice.GetUserRisksByCID_V2 | History.CustomerRisk | Reader | V2 aggregated risk history query |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CustomerRisk (table)
- Leaf node - no code-level dependencies
- Written from BackOffice.CustomerRisk (table) via BackOffice.SetRiskStatus (procedure)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SetRiskStatus | Stored Procedure | Writer - inserts prior state when risk event status changes |
| BackOffice.GetRiskHistoryByCID | Stored Procedure | Reader - risk history lookup per customer |
| BackOffice.GetUserRisksByCID | Function | Reader - risk history aggregation |
| BackOffice.GetUserRisksByCID_AGG | Function | Reader - aggregated risk history |
| BackOffice.GetUserRisksByCID_V2 | Function | Reader - V2 risk history aggregation |
| BackOffice.NewRiskAlertsPCIVersion | Stored Procedure | Reader - new risk alerts reporting |
| Billing.FundingCustomerRisk_Add | Stored Procedure | Reads/joins risk history for billing risk context |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryCustomerRisk | CLUSTERED (PK) | ID ASC | - | - | Active |

**Filegroup**: [HISTORY] - dedicated history filegroup for large audit tables.
**Storage**: DATA_COMPRESSION = PAGE (specified on PK constraint).
**Replication**: `NOT FOR REPLICATION` on IDENTITY and PK - identity values are not re-seeded on subscriber nodes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryCustomerRisk | PRIMARY KEY | Uniqueness on ID |
| DF_HistoryCustomerRisk_Occurred | DEFAULT | Occurred = getutcdate() if not provided |
| DF_HistoryCustomerRisk_ModifiedDate | DEFAULT | ModifiedDate = getutcdate() if not provided |

---

## 8. Sample Queries

### 8.1 Full risk history for a customer (by GCID)
```sql
SELECT hr.ID, hr.RiskStatusID, rs.Name AS RiskStatus,
       hr.RiskEventStatusID, res.Name AS EventStatus,
       hr.Occurred, hr.ModifiedDate, hr.Remark, hr.ManagerID
FROM [History].[CustomerRisk] hr WITH (NOLOCK)
INNER JOIN [Dictionary].[RiskStatus] rs WITH (NOLOCK) ON hr.RiskStatusID = rs.RiskStatusID
INNER JOIN [Dictionary].[RiskEventStatus] res WITH (NOLOCK) ON hr.RiskEventStatusID = res.RiskEventStatusID
WHERE hr.GCID = 4101059
ORDER BY hr.ModifiedDate DESC
```

### 8.2 Risk changes made by the automated system vs. manual managers
```sql
SELECT
    CASE WHEN ManagerID = 0 THEN 'Automated' ELSE 'Manual (Manager ' + CAST(ManagerID AS VARCHAR) + ')' END AS ChangeSource,
    COUNT(*) AS ChangeCount,
    MIN(ModifiedDate) AS FirstChange,
    MAX(ModifiedDate) AS LastChange
FROM [History].[CustomerRisk] WITH (NOLOCK)
GROUP BY CASE WHEN ManagerID = 0 THEN 'Automated' ELSE 'Manual (Manager ' + CAST(ManagerID AS VARCHAR) + ')' END
ORDER BY ChangeCount DESC
```

### 8.3 Most common risk status transitions in history
```sql
SELECT hr.RiskStatusID, rs.Name AS RiskStatus,
       hr.RiskEventStatusID, res.Name AS PreviousEventStatus,
       COUNT(*) AS TransitionCount
FROM [History].[CustomerRisk] hr WITH (NOLOCK)
INNER JOIN [Dictionary].[RiskStatus] rs WITH (NOLOCK) ON hr.RiskStatusID = rs.RiskStatusID
INNER JOIN [Dictionary].[RiskEventStatus] res WITH (NOLOCK) ON hr.RiskEventStatusID = res.RiskEventStatusID
GROUP BY hr.RiskStatusID, rs.Name, hr.RiskEventStatusID, res.Name
ORDER BY TransitionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CustomerRisk | Type: Table | Source: etoro/etoro/History/Tables/History.CustomerRisk.sql*
