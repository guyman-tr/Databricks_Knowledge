# RecurringInvestment.PlansGetByGCID

> Retrieves all recurring investment plans for a user (by GCID) with aggregated position amounts across all instances.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID input, returns plan list with SumPositionAmountUsd |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary plan retrieval procedure, used whenever the application needs to display a user's recurring investment plans. It returns all plans (active, cancelled, initializing) for a specific user, enriched with the sum of all position amounts in USD across all instances of each plan.

The SumPositionAmountUsd column was added per EDGE-4618 (Oded Levy, 6/1/2025) to show users how much has actually been invested through each plan. This procedure is also called internally by PlanInsert and PlanUpdate to return the updated plan list after modifications.

---

## 2. Business Logic

### 2.1 Aggregated Position Tracking

**What**: Each plan row includes the total USD position amount across all its instances.

**Columns/Parameters Involved**: `SumPositionAmountUsd` (computed), `PlanInstances.PositionAmountUsd`

**Rules**:
- LEFT JOIN to PlanInstances ensures plans with no instances still appear (SumPositionAmountUsd = 0)
- ISNULL handles NULL PositionAmountUsd (instances without positions)
- GROUP BY all plan columns enables the SUM aggregation
- Returns ALL plans for the user, not just active ones

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the user whose plans to retrieve. |

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlanID | int | NO | - | VERIFIED | Plans.ID - unique plan identifier. |
| 2 | GCID | bigint | NO | - | VERIFIED | User's Global Customer ID. |
| 3 | CID | bigint | YES | - | VERIFIED | User's Customer ID. |
| 4 | InstrumentID | int | YES | - | VERIFIED | Instrument for instrument-type plans. NULL for copy plans. |
| 5 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID from Money Group. |
| 6 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle in plan currency. |
| 7 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 8 | PlanStatusID | int | NO | - | VERIFIED | Plan lifecycle state. See [Plan Status](../../_glossary.md#plan-status). |
| 9 | StatusReasonID | int | YES | - | VERIFIED | Reason for current status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 10 | CreationDate | datetime | NO | - | VERIFIED | When the plan was created. |
| 11 | EndDate | datetime | YES | - | VERIFIED | When the plan was cancelled. NULL if active. |
| 12 | DepositStartDate | datetime | YES | - | VERIFIED | When the first deposit occurred. |
| 13 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 14 | RepeatsOn | int | NO | - | VERIFIED | Day of month for execution. |
| 15 | HasBackupPayment | bit | YES | - | VERIFIED | Whether fallback payment is configured. |
| 16 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 17 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 18 | CopyType | int | NO | - | VERIFIED | Copy trading type. See [Copy Type](../../_glossary.md#copy-type). |
| 19 | InstrumentID | int | YES | - | CODE-BACKED | Duplicate column in SELECT (appears twice in SP code). |
| 20 | PlanType | int | NO | - | VERIFIED | Instrument (1) or Copy (2). See [Plan Type](../../_glossary.md#plan-type). |
| 21 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader's CID. |
| 22 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader's GCID. |
| 23 | MopType | int | NO | - | VERIFIED | Payment method type. See [MOP Type](../../_glossary.md#mop-type). |
| 24 | SumPositionAmountUsd | decimal(38,2) | NO | - | VERIFIED | Total USD position amount across all instances of this plan. 0 if no positions opened yet. Added per EDGE-4618. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Read | Main data source |
| - | RecurringInvestment.PlanInstances | LEFT JOIN | Aggregates PositionAmountUsd |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInsert | - | EXEC | Called after insert to return all user plans |
| RecurringInvestment.PlanUpdate | - | EXEC | Called after update to return all user plans |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetByGCID (procedure)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | SELECT FROM with NOLOCK |
| RecurringInvestment.PlanInstances | Table | LEFT JOIN for SUM aggregation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInsert | Stored Procedure | Calls this SP after inserting a plan |
| RecurringInvestment.PlanUpdate | Stored Procedure | Calls this SP after updating a plan |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute for a user
```sql
EXEC [RecurringInvestment].[PlansGetByGCID] @GCID = 12345678
```

### 8.2 Get active plans only (post-filter)
```sql
EXEC [RecurringInvestment].[PlansGetByGCID] @GCID = 12345678
-- Application filters result where PlanStatusID = 1
```

### 8.3 Verify aggregation
```sql
SELECT p.ID, SUM(ISNULL(pi.PositionAmountUsd, 0)) AS TotalInvested
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
LEFT JOIN [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK) ON p.ID = pi.PlanID
WHERE p.GCID = 12345678
GROUP BY p.ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans table column descriptions and relationships |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan retrieval is used in Create Plan flow and user-facing API |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 21 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlansGetByGCID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetByGCID.sql*
