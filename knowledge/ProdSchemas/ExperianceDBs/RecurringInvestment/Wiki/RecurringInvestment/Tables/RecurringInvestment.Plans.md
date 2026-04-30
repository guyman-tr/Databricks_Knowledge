# RecurringInvestment.Plans

> Core table storing recurring investment plan subscriptions - each row is a user's automated investment configuration for a specific instrument or copy target.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 4 active (PK + 3 NC including 1 unique filtered) |

---

## 1. Business Meaning

This table is the heart of the Recurring Investment system. Each row represents a single recurring investment plan - a subscription that automatically invests a specified amount of money into a specific instrument (stock, ETF, crypto) or copies a specific trader (Popular Investor or SmartPortfolio) on a recurring schedule. A user (GCID) can have multiple plans, but cannot have more than one active plan for the same instrument (enforced by unique filtered index UIX_Plans_GCIDInstrumentID).

Without this table, the entire recurring investment feature would not exist. Every other object in the schema either serves, reads from, writes to, or validates against this table. It is the configuration hub that drives the Plan Instances Job, Before Deposit Job, Deposit Message Handler, and Order Execution Job.

Plans are created by the application via PlanInsert when a user sets up a recurring investment. The plan is linked to a Recurring Deposit Plan managed by the Money Group via RecurringDepositID. All of a user's active investment plans share the same recurring deposit program. The deposit amount across all plans is collected as a single deposit per cycle, tracked in UserDeposits.

---

## 2. Business Logic

### 2.1 Plan Type Routing

**What**: The PlanType + CopyType combination determines the entire execution path for the plan.

**Columns/Parameters Involved**: `PlanType`, `CopyType`, `InstrumentID`, `CopyParentCID`, `CopyParentGCID`

**Rules**:
- PlanType=1 (Instrument) + CopyType=0 (None): Direct investment. Uses InstrumentID. InstrumentID is NOT NULL, CopyParentCID/GCID are NULL.
- PlanType=2 (Copy) + CopyType=1 (PI): Copy a Popular Investor. InstrumentID is NULL, CopyParentCID/GCID identify the trader.
- PlanType=2 (Copy) + CopyType=4 (SmartPortfolio): Copy a managed portfolio. Same pattern as PI.

**Diagram**:
```
Plan Created
    |
    +-- PlanType=1 --> InstrumentID set --> Direct order via TAPI
    |
    +-- PlanType=2 --> CopyParentCID/GCID set
                         |
                         +-- CopyType=1 (PI) --> Mirror order to PI
                         +-- CopyType=4 (SP) --> Mirror order to SmartPortfolio
```

### 2.2 Plan Lifecycle

**What**: Plans follow a lifecycle controlled by PlanStatusID with reasons tracked by StatusReasonID.

**Columns/Parameters Involved**: `PlanStatusID`, `StatusReasonID`, `CreationDate`, `EndDate`

**Rules**:
- Created: PlanStatusID=0 (Initializing) if creation fails, or PlanStatusID=1 (Active) on success. StatusReasonID=100 (CreatePlanSuccess).
- Active: Only PlanStatusID=1 generates instances and processes deposits
- Cancelled: PlanStatusID=2. EndDate is set. StatusReasonID captures why (700=user, 300-303=deposit plan cancelled, 800+=eligibility/compliance)
- Unique constraint: only one active plan (PlanStatusID=1) per GCID+InstrumentID+CopyParentGCID

### 2.3 Multi-Currency Support

**What**: Plans support multiple currencies with both local and USD amounts.

**Columns/Parameters Involved**: `Amount`, `AmountUsd`, `CurrencyID`

**Rules**:
- Amount is in the plan's CurrencyID (based on [etoro].[Dictionary].[Currency] per Confluence)
- AmountUsd is the USD equivalent
- When CurrencyID is USD, Amount equals AmountUsd
- The deposit amount per cycle aggregates all plan amounts for a user

### 2.4 Deposit Plan Linkage

**What**: Each recurring investment plan is linked to a recurring deposit plan managed by the Money Group.

**Columns/Parameters Involved**: `RecurringDepositID`, `DepositStartDate`, `FundingID`, `MopType`, `HasBackupPayment`

**Rules**:
- RecurringDepositID links to Billing DB [Recurring].[Payment]
- All of a user's active plans share the same RecurringDepositID
- FundingID identifies the payment method
- MopType classifies the payment method type (defaults to 1)
- HasBackupPayment indicates whether a fallback payment method is configured
- DepositStartDate is when the first deposit occurs

---

## 3. Data Overview

| ID | GCID | InstrumentID | Amount | CurrencyID | PlanStatusID | PlanType | CopyType | Meaning |
|----|------|--------------|--------|------------|--------------|----------|----------|---------|
| 76747 | 24776282 | 100003 | 50.00 | 2 | 1 | 1 | 0 | Active instrument plan. User invests 50 in currency 2 (non-USD) monthly into instrument 100003. Standard direct investment. |
| 76746 | 42368313 | 2175 | 49.00 | 1 | 1 | 1 | 0 | Active instrument plan. Same user as #76745 has multiple plans. USD-denominated ($49/month) for instrument 2175. |
| 76733 | 40359244 | NULL | 200.00 | 1 | 1 | 2 | 1 | Active copy plan. User copies a Popular Investor (CopyParentCID=14123814). $200/month. InstrumentID is NULL because copy plans don't target specific instruments. |
| 76744 | 36056103 | 4238 | 50.00 | 5 | 1 | 1 | 0 | Active instrument plan in currency 5. User invests 50 units of their local currency monthly into instrument 4238. |
| 76743 | 47576545 | 3025 | 100.00 | 5 | 1 | 1 | 0 | Active instrument plan with RepeatsOn=28 (executes on the 28th of each month). Most plans use RepeatsOn=1 (1st of month). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | VERIFIED | Unique auto-incrementing identifier for the recurring investment plan. Primary key. Users can have multiple plans (since Phase 0.5 per Confluence). (Source: Confluence) |
| 2 | GCID | bigint | NO | - | VERIFIED | Global Customer ID - unique identifier of the eToro user who owns this plan. A user can have multiple active plans for different instruments. (Source: Confluence) |
| 3 | CID | bigint | YES | - | VERIFIED | Customer ID - alternate unique identifier of the user. Both GCID and CID identify the same user in different systems. (Source: Confluence) |
| 4 | InstrumentID | int | YES | - | VERIFIED | ID of the specific instrument (stock, ETF, crypto) for Instrument-type plans (PlanType=1). NULL for Copy-type plans (PlanType=2) which use CopyParentCID instead. A user cannot have more than one active plan for the same InstrumentID (unique filtered index). (Source: Confluence) |
| 5 | RecurringDepositID | int | YES | - | VERIFIED | ID of the Recurring Deposit Plan from MIMO/Money Group that this investment plan is linked to. All of a user's active investment plans are linked to the same recurring deposit program. More details in Billing DB [Recurring].[Payment]. (Source: Confluence) |
| 6 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle in the plan's CurrencyID. For example, if CurrencyID=2 (EUR) and Amount=50, the user invests 50 EUR per cycle. (Source: Confluence) |
| 7 | CurrencyID | int | NO | - | VERIFIED | Currency of the plan's Amount. Based on [etoro].[Dictionary].[Currency] (external DB). When CurrencyID is USD, Amount equals AmountUsd. (Source: Confluence) |
| 8 | PlanStatusID | int | NO | - | VERIFIED | Lifecycle state of the plan: 0=Initializing (failed creation), 1=Active (operational), 2=Cancelled (terminal), 3=Stopped (unused), 4=Invalid (unused). Only Active (1) plans generate instances. See [Plan Status](../../_glossary.md#plan-status). (Dictionary.PlanStatus) |
| 9 | DepositPlanStatusID | int | YES | - | VERIFIED | DEPRECATED - marked for deletion per Confluence. Status of the linked recurring deposit plan. Being phased out as this tracking moves to the Money Group system. |
| 10 | StatusReasonID | int | YES | - | VERIFIED | Reason for the current plan status. Maps to Dictionary.PlanEventCode (e.g., 100=CreatePlanSuccess, 700=CancelPlanByUser, 300=DepositPlanCancelled). See [Plan Event Code](../../_glossary.md#plan-event-code). (Source: Confluence) |
| 11 | CreationDate | datetime | NO | GETUTCDATE() | VERIFIED | When the plan was created. Auto-set to current UTC time on creation. |
| 12 | EndDate | datetime | YES | - | VERIFIED | When the plan was cancelled. NULL for active plans. Set when PlanStatusID changes to 2 (Cancelled). (Source: Confluence: "An active plan will be EndDate = NULL") |
| 13 | DepositStartDate | datetime | YES | GETUTCDATE() | VERIFIED | When the plan's first deposit occurred or is scheduled. Auto-defaults to creation time. (Source: Confluence) |
| 14 | FrequencyID | int | NO | - | VERIFIED | Execution cadence: 3=Monthly (only active frequency). Weekly (1) and BiWeekly (2) exist but are not in use. See [Plan Frequencies](../../_glossary.md#plan-frequencies). (Dictionary.PlanFrequencies) |
| 15 | RepeatsOn | int | NO | - | VERIFIED | Day of the month when the plan executes (1-28). For monthly frequency, this is the calendar day the deposit and order occur. Most plans use 1 (first of month). (Source: Confluence: "The date when the plan is executed") |
| 16 | FundingID | int | YES | - | VERIFIED | ID of the plan's payment method in the billing system. (Source: Confluence: "The ID of the plan's payment method") |
| 17 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName. |
| 18 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 19 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end. |
| 20 | PlanType | int | NO | - | VERIFIED | Fundamental plan classification: 1=Instrument (direct investment), 2=Copy (copy trading). Determines which columns are relevant and which execution path is used. See [Plan Type](../../_glossary.md#plan-type). (Dictionary.PlanType) |
| 21 | CopyParentCID | bigint | YES | - | VERIFIED | CID of the trader being copied. Only set for Copy-type plans (PlanType=2). NULL for Instrument-type plans. |
| 22 | CopyParentGCID | bigint | YES | - | VERIFIED | GCID of the trader being copied. Used with CopyParentCID for unique identification. Part of the unique filtered index for active plans. |
| 23 | CopyType | int | NO | - | VERIFIED | Copy trading relationship type: 0=None (instrument plan), 1=PI (Popular Investor), 4=SmartPortfolio. See [Copy Type](../../_glossary.md#copy-type). (Dictionary.CopyType) |
| 24 | HasBackupPayment | bit | YES | - | CODE-BACKED | Whether the plan has a fallback payment method configured. Used for deposit resilience. |
| 25 | MopType | int | NO | 1 | VERIFIED | Method of Payment type for the plan's deposits. Defaults to 1. See [MOP Type](../../_glossary.md#mop-type). (Dictionary.MopType) |
| 26 | AmountUsd | decimal(18,2) | YES | - | CODE-BACKED | Investment amount per cycle converted to USD. Equals Amount when CurrencyID is USD. Used for USD-normalized reporting and calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlanStatusID | Dictionary.PlanStatus | Implicit Lookup | Plan lifecycle state |
| StatusReasonID | Dictionary.PlanEventCode | Implicit Lookup | Reason for current status |
| FrequencyID | Dictionary.PlanFrequencies | Implicit Lookup | Execution cadence |
| PlanType | Dictionary.PlanType | Implicit Lookup | Instrument vs Copy classification |
| CopyType | Dictionary.CopyType | Implicit Lookup | Copy trading relationship type |
| MopType | Dictionary.MopType | Implicit Lookup | Payment method type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInstances | PlanID | Implicit FK | Each instance belongs to a plan |
| RecurringInvestment.UserDeposits | GCID | Implicit | Deposits are per user, plans determine deposit amounts |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (no FROM/JOIN in CREATE TABLE).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | PlanID references Plans.ID |
| RecurringInvestment.PlanInsert | SP | Writer - creates new plans |
| RecurringInvestment.PlanUpdate | SP | Modifier - updates plan fields |
| RecurringInvestment.PlansGetByGCID | SP | Reader - queries by user |
| RecurringInvestment.PlansGetByPlanID | SP | Reader - queries by plan ID |
| RecurringInvestment.PlansGetByRecurringDepositID | SP | Reader - queries by deposit plan |
| RecurringInvestment.PlansGetActivePlansToCreateNewInstanceRecord | SP | Reader - finds plans needing new instances |
| RecurringInvestment.PlansCancelAllUserPlansUpdateInstanceStatus | SP | Modifier - batch cancellation |
| RecurringInvestment.UpdatePlansAndUpsertInstances | SP | Modifier - batch plan updates |
| RecurringInvestment.UpdatePlansAndUpsertInstancesCopyVersion | SP | Modifier - batch copy plan updates |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Plans_ID | CLUSTERED PK | ID | - | - | Active |
| IX_Plan_GCIDInstrumentIDPlanStatusID | NONCLUSTERED | GCID, InstrumentID, PlanStatusID | - | - | Active |
| IX_Plan_InstrumentID_PlanStatusID | NONCLUSTERED | InstrumentID, PlanStatusID | - | - | Active |
| IX_Plan_RecurringDepositID | NONCLUSTERED | RecurringDepositID | - | - | Active |
| UIX_Plans_GCIDInstrumentID | UNIQUE NC | GCID, InstrumentID, PlanStatusID, CopyParentGCID | - | WHERE PlanStatusID=1 | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Plans_CreationDate | DEFAULT | GETUTCDATE() - auto-timestamps plan creation |
| DF_Plans_StartDate | DEFAULT | GETUTCDATE() - auto-timestamps deposit start |
| (unnamed) | DEFAULT | 1 for MopType - defaults to primary payment method |

### 7.3 Temporal

System-versioned with history table `History.RecurringInvestmentPlans`.

---

## 8. Sample Queries

### 8.1 Get all active plans for a user
```sql
SELECT p.ID, p.InstrumentID, p.Amount, p.CurrencyID, ps.StatusName,
       pt.Name AS PlanTypeName, ct.Name AS CopyTypeName
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[PlanStatus] ps WITH (NOLOCK) ON p.PlanStatusID = ps.ID
JOIN [Dictionary].[PlanType] pt WITH (NOLOCK) ON p.PlanType = pt.ID
JOIN [Dictionary].[CopyType] ct WITH (NOLOCK) ON p.CopyType = ct.ID
WHERE p.GCID = @GCID AND p.PlanStatusID = 1
```

### 8.2 Find cancelled plans with cancellation reasons
```sql
SELECT p.ID, p.GCID, p.EndDate, pec.EventName AS CancellationReason
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[PlanEventCode] pec WITH (NOLOCK) ON p.StatusReasonID = pec.ID
WHERE p.PlanStatusID = 2
ORDER BY p.EndDate DESC
```

### 8.3 Find copy plans with their parent trader details
```sql
SELECT p.ID, p.GCID, p.Amount, p.CurrencyID,
       ct.Name AS CopyTypeName, p.CopyParentCID, p.CopyParentGCID
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[CopyType] ct WITH (NOLOCK) ON p.CopyType = ct.ID
WHERE p.PlanType = 2 AND p.PlanStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Complete Plans table documentation: column descriptions, data types, relationships, deprecated columns, Dictionary references |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan is a recurring investment subscription; linked to Recurring Deposit Plan; system diagram and job descriptions |
| [Recurring Investment - Available Balance HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13828784154/Recurring+Investment+-+Available+Balance+HLD) | Confluence | Plan creation flow and balance checking context |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 20 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.Plans | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.Plans.sql*
