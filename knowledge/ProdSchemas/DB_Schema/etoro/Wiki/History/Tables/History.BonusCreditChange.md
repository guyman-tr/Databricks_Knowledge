# History.BonusCreditChange

> Legacy audit table intended to track changes to a customer's bonus credit amount over time intervals; currently empty and unreferenced by any active procedure or view.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | BonusCreditID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + 1 nonclustered) |

---

## 1. Business Meaning

History.BonusCreditChange was designed to maintain a time-series record of bonus credit balances for customers. Each row would represent one period during which a customer held a specific bonus credit amount, bounded by ValidFrom and ValidTo timestamps. The index on (CID, ValidTo) suggests the primary query pattern was: "find the active bonus credit record for customer X at time T" - a point-in-time lookup.

Without an active writer or reader, this table's original purpose cannot be fully reconstructed from code alone. The design pattern resembles a slowly-changing-dimension approach to bonus credit tracking - recording the history of changes rather than just the current value. The BonusCredit column (money type) likely represented a credit amount applied to a customer's trading account as a bonus.

The table is currently defunct: it holds 0 rows and is not referenced by any stored procedure, view, or function in the SSDT repository. It may have been superseded by the History.AccountToBonus / Billing account bonus pattern, or the bonus credit tracking feature was never fully implemented.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

The table structure implies a point-in-time lookup pattern:
```
Find bonus credit for CID at time T:
  SELECT BonusCredit FROM History.BonusCreditChange
  WHERE CID = @CID AND ValidFrom <= @T AND ValidTo >= @T
  (Index on CID, ValidTo supports this query pattern)
```

---

## 3. Data Overview

The table is empty (0 rows). No representative rows can be shown.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BonusCreditID | int | NO | IDENTITY(1,1) | NAME-INFERRED | Surrogate primary key, auto-incremented. Uniquely identifies each bonus credit change record. |
| 2 | CID | int | YES | - | NAME-INFERRED | Customer ID of the customer whose bonus credit changed. Implicit FK to Customer.Customer. Component of the nonclustered index (CID, ValidTo) optimized for point-in-time lookups. Nullable - no NOT NULL constraint suggests this may have been added before the design was finalized. |
| 3 | BonusCredit | money | YES | - | NAME-INFERRED | The bonus credit amount applicable during the ValidFrom-ValidTo interval, in the account's currency. SQL money type (4 decimal places). Nullable. |
| 4 | ValidFrom | datetime | YES | - | NAME-INFERRED | UTC start of the period during which this BonusCredit value was applicable. Nullable. |
| 5 | ValidTo | datetime | YES | - | NAME-INFERRED | UTC end of the period during which this BonusCredit value was applicable. Indexed with CID to support "find record valid at time T" queries. Nullable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer whose bonus credit change is recorded |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No procedures or views reference this table in the codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BonusCreditChange (table)
```

Tables are always leaf nodes - no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HBCC | CLUSTERED PK | BonusCreditID ASC | - | - | Active |
| IX_HBCC_CID_ValidTo | Nonclustered | CID ASC, ValidTo ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HBCC | PRIMARY KEY | BonusCreditID - surrogate key |

---

## 8. Sample Queries

### 8.1 Check current row count (table is empty)
```sql
SELECT COUNT(*) AS RowCount
FROM [History].[BonusCreditChange] WITH (NOLOCK)
```

### 8.2 Find bonus credit record valid at a specific time (intended usage pattern)
```sql
SELECT BonusCreditID, CID, BonusCredit, ValidFrom, ValidTo
FROM [History].[BonusCreditChange] WITH (NOLOCK)
WHERE CID = @CID
  AND ValidFrom <= @PointInTime
  AND ValidTo >= @PointInTime
```

### 8.3 Get full bonus credit history for a customer
```sql
SELECT BonusCreditID, BonusCredit, ValidFrom, ValidTo,
       DATEDIFF(DAY, ValidFrom, ValidTo) AS DurationDays
FROM [History].[BonusCreditChange] WITH (NOLOCK)
WHERE CID = @CID
ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 6.5/10 (Elements: 5/10, Logic: 5/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BonusCreditChange | Type: Table | Source: etoro/etoro/History/Tables/History.BonusCreditChange.sql*
