# Dictionary.InterestStatus

> Lookup table defining interest processing statuses for overnight fee calculations — currently empty in production, with the schema reserved for future interest processing state tracking.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StatusID (TINYINT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup (PAGE compressed) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.InterestStatus is designed to hold processing statuses for interest (overnight fee) calculations. The table structure suggests it was created to track the lifecycle of interest rate processing jobs — similar to how other status tables track dividend processing or payment processing states.

This table currently contains no rows in the production database. The schema and constraint name ("PK_Dictionary_InteresrStatus" — note the typo) suggest it was created early in the interest rate subsystem's development. The interest processing system may use application-level status tracking instead, or this table was provisioned but never populated.

The table is referenced by Trade.InterestMonthly_July and Trade.InterestDaily_July, which are legacy interest calculation tables. The "_July" suffix suggests these were created during a specific monthly processing run or migration.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is empty — no business rules can be inferred from data.

---

## 3. Data Overview

Table is empty in production (0 rows). No data to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusID | tinyint | NO | - | NAME-INFERRED | Primary key identifying the interest processing status. No values exist in production. Likely intended to hold states like Pending/Processing/Completed/Failed for interest rate calculation jobs. |
| 2 | Status | varchar(50) | NO | - | NAME-INFERRED | Human-readable description of the interest processing status. No values exist in production. Would be displayed in interest processing monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InterestMonthly_July | StatusID | Implicit FK | Legacy monthly interest calculation status tracking |
| Trade.InterestDaily_July | StatusID | Implicit FK | Legacy daily interest calculation status tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InterestMonthly_July | Table | References StatusID for monthly interest processing |
| Trade.InterestDaily_July | Table | References StatusID for daily interest processing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_InteresrStatus | CLUSTERED PK | StatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_InteresrStatus | PRIMARY KEY | Unique interest status identifier (note: typo "Interesr" in constraint name) |

---

## 8. Sample Queries

### 8.1 List all interest statuses
```sql
SELECT  StatusID,
        Status
FROM    [Dictionary].[InterestStatus] WITH (NOLOCK)
ORDER BY StatusID;
```

### 8.2 Check if table has any data
```sql
SELECT  COUNT(*) AS RowCount
FROM    [Dictionary].[InterestStatus] WITH (NOLOCK);
```

### 8.3 Find referencing interest tables
```sql
SELECT  'Trade.InterestMonthly_July' AS ReferencingTable, 'Monthly' AS Frequency
UNION ALL
SELECT  'Trade.InterestDaily_July', 'Daily';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 8/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.InterestStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.InterestStatus.sql*
