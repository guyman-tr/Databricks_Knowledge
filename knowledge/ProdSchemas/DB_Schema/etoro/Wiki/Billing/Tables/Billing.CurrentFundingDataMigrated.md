# Billing.CurrentFundingDataMigrated

> Single-column migration scratch table used to track which FundingIDs have been processed during a data migration; currently empty and inactive.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | No primary key |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | None |

---

## 1. Business Meaning

`Billing.CurrentFundingDataMigrated` is a temporary migration tracking table holding a single nullable column: `FundingID int NULL`. The naming pattern ("CurrentFunding" + "DataMigrated") indicates it was used to record which FundingIDs had been successfully processed during a bulk data migration of the Billing.Funding table or a related funding dataset.

The table is currently empty (0 rows). No stored procedures reference it. It is completely inactive and represents a migration artifact - likely created to support a one-time migration and left in the schema afterward.

For active funding data, see `Billing.Funding`.

---

## 2. Business Logic

No business logic. This is a static migration scratch table with no active procedures and no data.

---

## 3. Data Overview

Table is empty (0 rows). No sample data available.

When active, rows would have contained FundingIDs that were successfully migrated, allowing a migration script to:
- INSERT a FundingID after processing it
- JOIN or EXCEPT against this table to find unprocessed FundingIDs
- Provide a restart checkpoint if the migration was interrupted

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | YES | - | CODE-BACKED | ID of a Billing.Funding record that was processed during the migration. Nullable with no PK - allows duplicate inserts if needed during migration. Implicit FK to Billing.Funding(FundingID) but no constraint enforced. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints in DDL).

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this table. It is inactive.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

No indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | No constraints. No PK, no FK, no check constraints. |

---

## 8. Sample Queries

### 8.1 Verify the table is empty
```sql
SELECT COUNT(*) AS RowCount
FROM   Billing.CurrentFundingDataMigrated WITH (NOLOCK);
```

### 8.2 Find funding records NOT yet migrated (migration checkpoint pattern)
```sql
-- If migration were active, this would find unprocessed FundingIDs
SELECT  f.FundingID
FROM    Billing.Funding f WITH (NOLOCK)
WHERE   f.FundingID NOT IN (
    SELECT FundingID
    FROM   Billing.CurrentFundingDataMigrated WITH (NOLOCK)
    WHERE  FundingID IS NOT NULL
);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 6.5/10 (Elements: 7/10, Logic: 4/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CurrentFundingDataMigrated | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CurrentFundingDataMigrated.sql*
