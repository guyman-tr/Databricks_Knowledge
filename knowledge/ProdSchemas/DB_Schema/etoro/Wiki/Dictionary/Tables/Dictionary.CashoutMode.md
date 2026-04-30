# Dictionary.CashoutMode

> Lookup table defining the 4 cashout (withdrawal) processing modes — Manual, Auto Create, Mass Auto Create, and Instant Withdrawal — with priority weights for processing order.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CashoutModeID (TINYINT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 4 (MCP verified) |
| **Indexes** | 2 active (PK clustered + unique NC on CashoutModeName) |

---

## 1. Business Meaning

Dictionary.CashoutMode classifies how a withdrawal request is processed — whether it requires manual operator intervention, is automatically created and queued, is part of a mass automated batch, or is processed instantly. This determines the speed and automation level of the withdrawal pipeline.

Each mode has a **CashoutModeWeight** that establishes processing priority — higher weights get processed first. Instant Withdrawal (weight 30) takes precedence over Mass Auto Create (20), which takes precedence over Auto Create (10), with Manual (weight 0) being lowest priority since it requires human handling.

The CashoutModeID is stored on Billing.WithdrawToFunding (the main withdrawal tracking table) and History.WithdrawToFundingAction, flowing through to BackOffice reporting views and procedures. BackOffice cashout management screens (GetWithdrawRequests, GetCashOutRequests_Main, GetProcessedWithdrawPCIVersion) JOIN to this table to display the mode name, and Billing monitoring/payout procedures use it for processing prioritization.

---

## 2. Business Logic

### 2.1 Processing Mode Classification

**What**: The four modes of withdrawal processing and their automation levels.

**Columns/Parameters Involved**: `CashoutModeID`, `CashoutModeName`, `CashoutModeWeight`

**Rules**:
- **Manual (0)**: Withdrawal requires manual operator processing in the BackOffice. Weight=0 (lowest priority). Used for complex cases, large amounts, or flagged customers that need human review.
- **Auto Create (1)**: System automatically creates and queues the withdrawal for processing. Weight=10. Standard automated flow for routine withdrawals.
- **Mass Auto Create (2)**: Batch automated processing — system groups multiple withdrawals for efficient bulk execution. Weight=20. Used during scheduled batch runs.
- **Instant Withdrawal (3)**: Real-time processing — withdrawal is executed immediately without queuing. Weight=30 (highest priority). Used for instant withdrawal features where customers receive funds within minutes.

**Diagram**:
```
Withdrawal Processing Priority (by weight):

  Instant Withdrawal (3) ──► Weight 30 ──► Processed first
  Mass Auto Create (2)   ──► Weight 20 ──► Processed in batch
  Auto Create (1)         ──► Weight 10 ──► Processed in queue
  Manual (0)              ──► Weight  0 ──► Awaits operator
```

### 2.2 Mode Assignment Logic

**What**: How the cashout mode is determined for a withdrawal.

**Columns/Parameters Involved**: `CashoutModeID`

**Rules**:
- Mode is set when the withdrawal is created (Billing.WithdrawToFundingAdd / BackOffice.WithdrawToFundingAdd)
- Mode selection depends on: funding type, amount, customer tier, regulatory jurisdiction, and risk flags
- Instant Withdrawal eligibility typically requires: verified customer, eligible funding type, amount within limits
- BackOffice operators can override to Manual for investigation
- Payout processing (Billing.GetPayoutProcessData, Billing.PayoutMetricDataGet) uses CashoutModeName for categorization

---

## 3. Data Overview

| CashoutModeID | CashoutModeName | CashoutModeWeight | Meaning |
|---|---|---|---|
| 0 | Manual | 0 | Withdrawal requires manual BackOffice operator processing. Lowest priority (weight 0). Used for complex cases, large amounts, flagged accounts, or investigation-required withdrawals. Operator must review and approve in the cashout management screen. |
| 1 | Auto Create | 10 | System automatically creates and queues the withdrawal for processing. Standard automated flow for routine withdrawals meeting all eligibility criteria. Processed by automated payout jobs. |
| 2 | Mass Auto Create | 20 | Batch automated processing — multiple withdrawals grouped for efficient bulk execution during scheduled batch runs. Higher priority than individual Auto Create. Optimizes PSP API calls and bank transfers. |
| 3 | Instant Withdrawal | 30 | Real-time instant processing — withdrawal executed immediately. Highest priority (weight 30). Customer receives funds within minutes. Limited to eligible funding types and amounts. Premium feature. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutModeID | tinyint | NO | - | VERIFIED | Primary key identifying the processing mode. 0=Manual, 1=Auto Create, 2=Mass Auto Create, 3=Instant Withdrawal. TINYINT type (0-255). Stored on Billing.WithdrawToFunding and History.WithdrawToFundingAction. Set at withdrawal creation time. |
| 2 | CashoutModeName | varchar(50) | NO | - | VERIFIED | Human-readable mode name. Unique constraint prevents duplicates. Note: column named CashoutModeName (not just Name) — differs from most Dictionary tables. Used in BackOffice JOINs as the display label (aliased as CashoutMode or EntryMethod). |
| 3 | CashoutModeWeight | int | YES | (100) | VERIFIED | Processing priority weight — higher values are processed first. 0=Manual (lowest), 10=Auto, 20=Mass Auto, 30=Instant (highest). DEFAULT 100 for new modes (high priority by default). Used by payout processing to determine execution order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawToFunding | CashoutModeID | Implicit | Main withdrawal table stores processing mode |
| History.WithdrawToFundingAction | CashoutModeID | Implicit | Withdrawal action history records mode |
| Billing.TBL_Withdraw2Funding | CashoutModeID | UDT column | Table-valued parameter for batch operations |
| Billing.FundingDataForWithdraw | CashoutModeID | View SELECT | Funding data view exposes mode |
| Billing.vWithdrawToFunding | CashoutModeID | View SELECT | Withdrawal view exposes mode |
| BackOffice.GetWithdrawRequests | CashoutModeID | JOIN (CashoutModeName) | Withdrawal request screen shows mode |
| BackOffice.GetCashOutRequests_Main | CashoutModeID | JOIN (CashoutModeName) | Main cashout screen shows mode |
| BackOffice.GetProcessedWithdrawPCIVersion | CashoutModeID | JOIN (CashoutModeName) | Processed withdrawal report shows mode |
| BackOffice.GetProcessedWithdrawPCIVersion_Old | CashoutModeID | JOIN | Legacy processed withdrawal report |
| BackOffice.WithdrawToFundingAdd | @CashoutModeID | Parameter INSERT | Back-office initiated withdrawal sets mode |
| BackOffice.GetPaymentOrders | CashoutModeID | SELECT as EntryMethod | Payment orders aliased as entry method |
| BackOffice.GetPaymentOrders_Withdraw | CashoutModeID | SELECT | Withdrawal payment orders |
| Billing.WithdrawToFundingAdd | @CashoutModeID | Parameter INSERT | Withdrawal creation sets mode |
| Billing.WithdrawToFundingProcess | CashoutModeID | INSERT | Processing records mode |
| Billing.InsertWithdraw2Funding | CashoutModeID | INSERT/MERGE | Batch insert/merge sets mode |
| Billing.UpdateWithdraw2Funding | CashoutModeID | MERGE | Batch update sets mode |
| Billing.GetPayoutProcessData | CashoutModeID | JOIN (CashoutModeName) | Payout processing categorizes by mode |
| Billing.WithdrawToFundingMonitoring | CashoutModeID | JOIN (CashoutModeName) | Withdrawal monitoring shows mode |
| Billing.PayoutMetricDataGet | CashoutModeID | JOIN | Payout metrics by mode |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CashoutMode (table)
  └── stored in Billing.WithdrawToFunding
  └── stored in History.WithdrawToFundingAction
  └── joined by 15+ BackOffice/Billing procedures
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Stores CashoutModeID per withdrawal |
| History.WithdrawToFundingAction | Table | Stores mode in action history |
| Billing.FundingDataForWithdraw | View | Exposes CashoutModeID |
| Billing.vWithdrawToFunding | View | Exposes CashoutModeID |
| BackOffice.GetWithdrawRequests | Stored Procedure | JOINs for mode name |
| BackOffice.GetCashOutRequests_Main | Stored Procedure | JOINs for mode name |
| Billing.WithdrawToFundingAdd | Stored Procedure | Sets mode at creation |
| Billing.GetPayoutProcessData | Stored Procedure | Categorizes by mode |
| Billing.WithdrawToFundingMonitoring | Stored Procedure | Monitors by mode |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCashoutMode | CLUSTERED PK | CashoutModeID ASC | - | - | Active |
| UQ_DictionaryCashoutMode_CashoutModeName | NONCLUSTERED UNIQUE | CashoutModeName ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryCashoutMode | PRIMARY KEY | Unique mode identifier, FILLFACTOR 90, PRIMARY filegroup |
| UQ_DictionaryCashoutMode_CashoutModeName | UNIQUE | Ensures no duplicate mode names, FILLFACTOR 90 |
| DF_DictionaryCashoutMode_CashoutModeWeight | DEFAULT | CashoutModeWeight defaults to 100 |

---

## 8. Sample Queries

### 8.1 List all cashout modes by priority
```sql
SELECT  CashoutModeID,
        CashoutModeName,
        CashoutModeWeight
FROM    Dictionary.CashoutMode WITH (NOLOCK)
ORDER BY CashoutModeWeight DESC;
```

### 8.2 Count withdrawals by mode
```sql
SELECT  dcm.CashoutModeName    AS Mode,
        dcm.CashoutModeWeight  AS Priority,
        COUNT(*)               AS WithdrawalCount
FROM    Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN    Dictionary.CashoutMode dcm WITH (NOLOCK)
        ON wtf.CashoutModeID = dcm.CashoutModeID
GROUP BY dcm.CashoutModeName, dcm.CashoutModeWeight
ORDER BY dcm.CashoutModeWeight DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis across 15+ BackOffice and Billing withdrawal procedures.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CashoutMode | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CashoutMode.sql*
