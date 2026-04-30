# RecurringInvestment.PlansGetByRecurringDepositID

> Retrieves all plans linked to a specific recurring deposit plan ID, including plans with NULL RecurringDepositID.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RecurringDepositID input, returns plan list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all plans linked to a specific recurring deposit plan. Since all of a user's active investment plans share the same RecurringDepositID, this effectively returns all plans for the deposit program. Used when the Money Group's billing system needs to know which investment plans are affected by a deposit plan event (e.g., cancellation, failure).

The WHERE clause handles NULL RecurringDepositID: `WHERE RecurringDepositID=@RecurringDepositID OR (RecurringDepositID IS NULL AND @RecurringDepositID IS NULL)`. This allows finding plans that haven't yet been linked to a deposit plan (e.g., plans stuck in Initializing status). Created per EDGE-3688.

---

## 2. Business Logic

### 2.1 NULL-Safe Comparison

**What**: Handles plans with no linked deposit plan.

**Columns/Parameters Involved**: `@RecurringDepositID`, `Plans.RecurringDepositID`

**Rules**:
- Standard match: Plans.RecurringDepositID = @RecurringDepositID
- NULL match: If @RecurringDepositID IS NULL, returns plans where RecurringDepositID IS NULL (unlinked plans)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RecurringDepositID | int | YES | - | VERIFIED | Recurring deposit plan ID from Money Group (Billing DB). NULL finds unlinked plans. |

**Return Columns**: Same as Plans table columns (PlanID, GCID, CID, InstrumentID, RecurringDepositID, Amount, CurrencyID, PlanStatusID, StatusReasonID, CreationDate, EndDate, DepositStartDate, FrequencyID, RepeatsOn, HasBackupPayment, ValidFrom, FundingID, CopyType, PlanType, CopyParentCID, CopyParentGCID, MopType).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Read | SELECT by RecurringDepositID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetByRecurringDepositID (procedure)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | SELECT FROM with NOLOCK |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses IX_Plan_RecurringDepositID index.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find plans for a deposit plan
```sql
EXEC [RecurringInvestment].[PlansGetByRecurringDepositID] @RecurringDepositID = 155942
```

### 8.2 Find unlinked plans
```sql
EXEC [RecurringInvestment].[PlansGetByRecurringDepositID] @RecurringDepositID = NULL
```

### 8.3 Verify deposit plan linkage
```sql
SELECT ID, GCID, RecurringDepositID, PlanStatusID FROM [RecurringInvestment].[Plans] WITH (NOLOCK) WHERE RecurringDepositID = 155942
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | RecurringDepositID links to MIMO; all active plans share same deposit program; code comment references EDGE-3688 |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlansGetByRecurringDepositID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetByRecurringDepositID.sql*
