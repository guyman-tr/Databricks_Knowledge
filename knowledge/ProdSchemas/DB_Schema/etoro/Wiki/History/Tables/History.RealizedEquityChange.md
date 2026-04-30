# History.RealizedEquityChange

> Historical log of realized equity change events per customer, recording the net monetary shift in a customer's equity at a point in time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | RealizedEquityID (IDENTITY, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered on Occurred, 1 nonclustered on CID) |

---

## 1. Business Meaning

This table captures discrete realized equity change events for customers - moments when a customer's equity materially changes due to a closed position, dividend, fee, or other settlement event. Each row records who (CID), when (Occurred), and by how much (RealizedEquity) the customer's equity shifted.

The table appears to have been an early mechanism for tracking per-customer equity delta events. It predates the more granular `History.Credit` table which now records all cash-flow events with credit type classification. The table currently has no active rows in production, indicating it has been superseded.

Note: the column name "RealizedEquityChange" appears frequently across `dbo.AccountStatement_GetTransactionsReport*` procedures, but those are computed column aliases in CTEs - they do not reference this table. This table has no active procedure writers or readers identified in the codebase.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

### 2.1 Deprecation Status

**What**: This table is no longer actively written to and has zero production rows.

**Columns/Parameters Involved**: `RealizedEquityID`, `CID`, `RealizedEquity`, `Occurred`

**Rules**:
- 0 rows exist in production; no stored procedure inserts into this table
- The concept of "realized equity change" is now tracked through `History.Credit` (TotalCashChange column) with full CreditTypeID classification
- AccountStatement procedures compute a RealizedEquityChange value inline from `History.Credit` data - they do not read from this table

**Diagram**:
```
Old flow (inactive):
  [Trading Event] -> INSERT History.RealizedEquityChange

New flow (active):
  [Trading Event] -> INSERT History.Credit (CreditTypeID + TotalCashChange)
                  -> AccountStatement proc computes RealizedEquityChange as alias
```

---

## 3. Data Overview

The table has no rows in production. No representative rows available.

| RealizedEquityID | CID | RealizedEquity | Occurred | Meaning |
|---|---|---|---|---|
| (no rows) | - | - | - | Table is empty; deprecated in favor of History.Credit for realized equity tracking |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RealizedEquityID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key, system-assigned identity. Uniquely identifies each realized equity change event record. NOT FOR REPLICATION flag indicates the identity seed is not replicated in replication scenarios. |
| 2 | CID | int | YES | - | NAME-INFERRED | Customer ID - the account whose equity changed. Implicit FK to Customer.CustomerStatic or equivalent customer master. No explicit FK constraint defined. Indexed (IX_HREC_CID) for per-customer lookups. Nullable, which may indicate some system-level entries not tied to a specific customer. |
| 3 | RealizedEquity | money | YES | - | NAME-INFERRED | The net equity change amount in USD (money type). Positive values represent equity increases (profits, credits); negative values represent decreases (losses, fees). The exact definition of "realized" in this context is not confirmed by code evidence - no procedure logic was found that writes to this column. |
| 4 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp of when the equity change occurred. Used as the clustered index key (IX_History_RealizedEquityChange_Occurred), making time-range scans the primary access pattern. Nullable in DDL despite being the cluster key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic (presumed) | Implicit | Customer whose equity changed. No explicit FK constraint; naming convention implies customer account reference. |

### 5.2 Referenced By (other objects point to this)

No stored procedures, views, or functions were found that reference this table by its fully-qualified name `History.RealizedEquityChange`. The table is not consumed by any active code in the SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. The table is referenced only by its DDL file; no procedures, views, or functions query or write to it.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HREC | NC PK | RealizedEquityID ASC | - | - | Active |
| IX_History_RealizedEquityChange_Occurred | CLUSTERED | Occurred ASC | - | - | Active |
| IX_HREC_CID | NONCLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HREC | PRIMARY KEY | Uniqueness on RealizedEquityID. NONCLUSTERED (the clustered index is on Occurred instead, optimizing for time-range access patterns). |

---

## 8. Sample Queries

### 8.1 Check if any rows exist
```sql
SELECT TOP 5 *
FROM [History].[RealizedEquityChange] WITH (NOLOCK)
ORDER BY [Occurred] DESC
```

### 8.2 Lookup equity changes for a specific customer
```sql
SELECT
    RealizedEquityID,
    CID,
    RealizedEquity,
    Occurred
FROM [History].[RealizedEquityChange] WITH (NOLOCK)
WHERE CID = @CID
ORDER BY Occurred DESC
```

### 8.3 Daily realized equity summary by customer
```sql
SELECT
    CID,
    CAST(Occurred AS DATE) AS EventDate,
    SUM(RealizedEquity) AS TotalRealizedEquity,
    COUNT(*) AS EventCount
FROM [History].[RealizedEquityChange] WITH (NOLOCK)
WHERE Occurred BETWEEN @StartDate AND @EndDate
GROUP BY CID, CAST(Occurred AS DATE)
ORDER BY EventDate DESC, TotalRealizedEquity DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.2/10 (Elements: 7.5/10, Logic: 5.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no direct references) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RealizedEquityChange | Type: Table | Source: etoro/etoro/History/Tables/History.RealizedEquityChange.sql*
