# RecurringInvestment.PlanInsert

> Creates a new recurring investment plan and returns all plans for the user. The primary plan creation entry point.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | 18 input parameters, returns plan list via PlansGetByGCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary entry point for creating a new recurring investment plan. When a user sets up a recurring investment through the UI, the backend service calls this procedure with all plan configuration parameters. After inserting the plan, it returns all plans for the user by calling PlansGetByGCID - the application uses this to refresh the user's plan list. Created per EDGE-3688 (Nilly Ron & Noga, 24/4/24).

Supports both Instrument-type (PlanType=1) and Copy-type (PlanType=2) plans through the PlanType, CopyType, CopyParentCID, and CopyParentGCID parameters.

---

## 2. Business Logic

### 2.1 Plan Creation with Auto-Return

**What**: INSERT + automatic return of all user plans.

**Columns/Parameters Involved**: All 18 parameters + EXEC PlansGetByGCID

**Rules**:
- Inserts a new row into Plans with all provided parameters
- MopType defaults to 1 (primary payment method) if not specified
- HasBackupPayment defaults to 0 (no backup) if not specified
- After insert, calls PlansGetByGCID to return all plans for the user (including the new one)
- Does NOT handle the unique constraint violation for duplicate GCID+InstrumentID+PlanStatusID=1 - the application must check eligibility first

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the plan owner. |
| 2 | @CID | bigint | NO | - | VERIFIED | Customer ID of the plan owner. |
| 3 | @InstrumentID | int | NO | - | VERIFIED | Target instrument ID. NULL for copy plans (PlanType=2). |
| 4 | @Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle in the plan's currency. |
| 5 | @CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 6 | @FrequencyID | int | NO | - | VERIFIED | Execution frequency: 3=Monthly. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 7 | @RepeatsOn | int | NO | - | VERIFIED | Day of month for execution (1-28). |
| 8 | @DepositStartDate | datetime | NO | - | VERIFIED | When the first deposit should occur. |
| 9 | @PlanCreationDate | datetime | NO | - | VERIFIED | Plan creation timestamp. Maps to Plans.CreationDate. |
| 10 | @EndDate | datetime | NO | - | VERIFIED | End date. Typically NULL for new plans (active). |
| 11 | @PlanStatusID | int | NO | - | VERIFIED | Initial status. Typically 1 (Active) or 0 (Initializing). See [Plan Status](../../_glossary.md#plan-status). |
| 12 | @StatusReasonID | int | NO | - | VERIFIED | Initial reason. Typically 100 (CreatePlanSuccess). See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 13 | @FundingID | int | NO | - | VERIFIED | Payment method ID. |
| 14 | @PlanType | int | NO | - | VERIFIED | 1=Instrument, 2=Copy. See [Plan Type](../../_glossary.md#plan-type). |
| 15 | @CopyType | int | NO | - | VERIFIED | 0=None, 1=PI, 4=SmartPortfolio. See [Copy Type](../../_glossary.md#copy-type). |
| 16 | @CopyParentCID | bigint | NO | - | VERIFIED | Copied trader's CID. NULL for instrument plans. |
| 17 | @CopyParentGCID | bigint | NO | - | VERIFIED | Copied trader's GCID. NULL for instrument plans. |
| 18 | @MopType | int | YES | 1 | VERIFIED | Method of payment type. Defaults to 1. See [MOP Type](../../_glossary.md#mop-type). |
| 19 | @HasBackupPayment | bit | YES | 0 | VERIFIED | Whether fallback payment is configured. Defaults to 0 (no). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Write | INSERT INTO |
| - | RecurringInvestment.PlansGetByGCID | EXEC | Calls to return all user plans after insert |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInsert (procedure)
├── RecurringInvestment.Plans (table) [INSERT]
└── RecurringInvestment.PlansGetByGCID (procedure) [EXEC]
      ├── RecurringInvestment.Plans (table)
      └── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | INSERT INTO |
| RecurringInvestment.PlansGetByGCID | Stored Procedure | Called after insert |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create an instrument plan
```sql
EXEC [RecurringInvestment].[PlanInsert]
  @GCID = 12345678, @CID = 12345000, @InstrumentID = 2175,
  @Amount = 100.00, @CurrencyID = 1, @FrequencyID = 3, @RepeatsOn = 1,
  @DepositStartDate = '2026-05-01', @PlanCreationDate = '2026-04-13',
  @EndDate = NULL, @PlanStatusID = 1, @StatusReasonID = 100,
  @FundingID = 5001, @PlanType = 1, @CopyType = 0,
  @CopyParentCID = NULL, @CopyParentGCID = NULL
```

### 8.2 Create a copy plan
```sql
EXEC [RecurringInvestment].[PlanInsert]
  @GCID = 12345678, @CID = 12345000, @InstrumentID = NULL,
  @Amount = 200.00, @CurrencyID = 1, @FrequencyID = 3, @RepeatsOn = 15,
  @DepositStartDate = '2026-05-15', @PlanCreationDate = '2026-04-13',
  @EndDate = NULL, @PlanStatusID = 1, @StatusReasonID = 100,
  @FundingID = 5001, @PlanType = 2, @CopyType = 1,
  @CopyParentCID = 87654321, @CopyParentGCID = 87654321
```

### 8.3 Verify the insert
```sql
SELECT TOP 1 * FROM [RecurringInvestment].[Plans] WITH (NOLOCK) WHERE GCID = 12345678 ORDER BY CreationDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Create Plan flow: user creates plan via UI, backend calls PlanInsert; code comment references EDGE-3688 |
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans table column descriptions and relationships |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 17 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanInsert | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInsert.sql*
