# RecurringInvestment.PlansGetInstrumentIdsByRecurringDepositID

> Returns InstrumentIDs linked to a specific recurring deposit plan - used to determine which instruments are affected by deposit plan events.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RecurringDepositID input, returns InstrumentID + RecurringDepositId pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the instruments associated with a specific recurring deposit plan. When the Money Group processes a deposit event, it may need to know which instruments will be affected. Created per EDGE-3688 (Nilly Ron, 19/07/2024).

Returns InstrumentID and RecurringDepositId pairs. NULL-safe comparison on RecurringDepositID.

---

## 2. Business Logic

Same NULL-safe comparison as PlansGetByRecurringDepositID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RecurringDepositID | int | YES | - | CODE-BACKED | Recurring deposit plan ID to look up instruments for. |
| 2 | InstrumentID (return) | int | YES | - | CODE-BACKED | Instrument ID from the plan. NULL for copy-type plans. |
| 3 | RecurringDepositId (return) | int | YES | - | CODE-BACKED | The recurring deposit plan ID (echoed back for confirmation). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Read | SELECT InstrumentID, RecurringDepositId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetInstrumentIdsByRecurringDepositID (procedure)
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

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute
```sql
EXEC [RecurringInvestment].[PlansGetInstrumentIdsByRecurringDepositID] @RecurringDepositID = 155942
```

### 8.2 Direct query equivalent
```sql
SELECT InstrumentID, RecurringDepositID FROM [RecurringInvestment].[Plans] WITH (NOLOCK) WHERE RecurringDepositID = 155942
```

### 8.3 Find instruments for active plans only
```sql
SELECT InstrumentID FROM [RecurringInvestment].[Plans] WITH (NOLOCK) WHERE RecurringDepositID = 155942 AND PlanStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | RecurringDepositID linkage; code comment references EDGE-3688 |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlansGetInstrumentIdsByRecurringDepositID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetInstrumentIdsByRecurringDepositID.sql*
