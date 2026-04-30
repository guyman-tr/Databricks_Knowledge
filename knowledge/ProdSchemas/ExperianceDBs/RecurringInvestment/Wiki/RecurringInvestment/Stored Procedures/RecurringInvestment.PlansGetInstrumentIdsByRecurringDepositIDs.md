# RecurringInvestment.PlansGetInstrumentIdsByRecurringDepositIDs

> Batch version: returns InstrumentIDs for multiple recurring deposit plan IDs using a table-valued parameter.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RecurringDepositIDs (TVP) input, returns InstrumentID + RecurringDepositId pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the batch version of PlansGetInstrumentIdsByRecurringDepositID. Instead of querying one deposit plan at a time, it accepts a RecurringDepositIDListType table-valued parameter containing multiple deposit plan IDs and returns all instrument + deposit plan pairs in a single call. Created per EDGE-3688 (Nilly Ron, 09/10/2024).

Uses INNER JOIN (not NULL-safe) since the TVP provides explicit deposit plan IDs.

---

## 2. Business Logic

No complex business logic. INNER JOIN between TVP and Plans table on RecurringDepositID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RecurringDepositIDs | RecurringInvestment.RecurringDepositIDListType READONLY | NO | - | CODE-BACKED | Table-valued parameter containing a list of RecurringDepositIDs to look up. |
| 2 | InstrumentID (return) | int | YES | - | CODE-BACKED | Instrument ID from matching plans. |
| 3 | RecurringDepositId (return) | int | YES | - | CODE-BACKED | Matching recurring deposit plan ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RecurringDepositIDs | RecurringInvestment.RecurringDepositIDListType | Parameter Type | Uses this UDT for input |
| - | RecurringInvestment.Plans | Read | INNER JOIN on RecurringDepositID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetInstrumentIdsByRecurringDepositIDs (procedure)
├── RecurringInvestment.RecurringDepositIDListType (type)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.RecurringDepositIDListType | UDT | Input parameter type |
| RecurringInvestment.Plans | Table | INNER JOIN |

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

### 8.1 Execute with TVP
```sql
DECLARE @Ids RecurringInvestment.RecurringDepositIDListType
INSERT INTO @Ids (RecurringDepositID) VALUES (155942), (200426)
EXEC [RecurringInvestment].[PlansGetInstrumentIdsByRecurringDepositIDs] @RecurringDepositIDs = @Ids
```

### 8.2 Direct query equivalent
```sql
SELECT InstrumentID, RecurringDepositID FROM [RecurringInvestment].[Plans] WITH (NOLOCK) WHERE RecurringDepositID IN (155942, 200426)
```

### 8.3 Check type definition
```sql
SELECT c.name FROM sys.table_types tt JOIN sys.columns c ON c.object_id = tt.type_table_object_id WHERE tt.name = 'RecurringDepositIDListType'
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
*Object: RecurringInvestment.PlansGetInstrumentIdsByRecurringDepositIDs | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetInstrumentIdsByRecurringDepositIDs.sql*
