# RecurringInvestment.RecurringDepositIDListType

> Table-valued parameter type for passing a list of RecurringDepositIDs to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with RecurringDepositID (int) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This table-valued parameter type enables procedures to accept a list of Recurring Deposit IDs as input. RecurringDepositID links a recurring investment plan to its corresponding recurring deposit plan managed by the Money Group's billing system (Billing DB [Recurring].[Payment]).

Used by PlansGetInstrumentIdsByRecurringDepositIDs to look up which instruments are associated with a set of recurring deposit plans - for example, when the Money system needs to know which instruments would be affected by a deposit plan change.

---

## 2. Business Logic

No complex business logic. This is a single-column list type for RecurringDepositID lookups.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RecurringDepositID | int | NO | - | VERIFIED | ID of a recurring deposit plan from the Money Group's billing system. Links to Plans.RecurringDepositID. All of a user's active investment plans share the same RecurringDepositID (per Confluence). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RecurringDepositID | RecurringInvestment.Plans | Implicit FK | Links to plans via Plans.RecurringDepositID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlansGetInstrumentIdsByRecurringDepositIDs | Stored Procedure | Accepts this type for multi-deposit-ID instrument lookups |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @DepositIds RecurringInvestment.RecurringDepositIDListType
INSERT INTO @DepositIds (RecurringDepositID) VALUES (1001), (1002), (1003)
```

### 8.2 Use to find instruments for deposit IDs
```sql
DECLARE @DepositIds RecurringInvestment.RecurringDepositIDListType
INSERT INTO @DepositIds (RecurringDepositID) VALUES (1001)
EXEC [RecurringInvestment].[PlansGetInstrumentIdsByRecurringDepositIDs] @RecurringDepositIDs = @DepositIds
```

### 8.3 Check type structure
```sql
SELECT c.name, t.name AS TypeName, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'RecurringDepositIDListType' AND SCHEMA_NAME(tt.schema_id) = 'RecurringInvestment'
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | RecurringDepositID links investment plans to MIMO deposit plans; all active plans share the same deposit plan per user |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.RecurringDepositIDListType | Type: User Defined Type | Source: RecurringInvestment/RecurringInvestment/User Defined Types/RecurringInvestment.RecurringDepositIDListType.sql*
