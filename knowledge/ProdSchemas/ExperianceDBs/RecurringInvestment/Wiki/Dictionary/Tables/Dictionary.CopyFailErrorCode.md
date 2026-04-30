# Dictionary.CopyFailErrorCode

> Lookup table defining error codes for copy trading position failures in the recurring investment system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table defines the error codes that classify why a copy trading position failed to open or replicate within the recurring investment system. When a recurring investment plan of type "Copy" (copying a Popular Investor or SmartPortfolio) attempts to open a position and fails, the specific failure reason is captured using codes from this table.

Without this table, the system would have no standardized way to categorize copy trading failures, making it impossible to distinguish between different failure modes (e.g., registration failure vs. fund allocation failure) for reporting, troubleshooting, and automated retry logic.

The table is currently empty in the database - error codes may be maintained externally in application code enums or populated at runtime. The PlanInstances.CopyFailErrorCode column references this conceptual domain.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple lookup table with a single domain of error code values.

---

## 3. Data Overview

Table is currently empty (0 rows). Error codes for copy trading failures may be defined in application enums (e.g., in the eToro/recurring-investment-back repository) rather than in this database table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Unique numeric identifier for the copy fail error code. Primary key. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable name/label describing the specific copy trading failure reason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInstances | CopyFailErrorCode | Implicit Lookup | Error code when a copy trading position fails to open for a plan instance |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | CopyFailErrorCode column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CopyFailErrorCode | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all copy fail error codes
```sql
SELECT ID, Name
FROM [Dictionary].[CopyFailErrorCode] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find plan instances with copy failures
```sql
SELECT pi.InstanceID, pi.PlanID, pi.CopyFailErrorCode, cfe.Name AS ErrorName
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
LEFT JOIN [Dictionary].[CopyFailErrorCode] cfe WITH (NOLOCK) ON pi.CopyFailErrorCode = cfe.ID
WHERE pi.CopyFailErrorCode IS NOT NULL
```

### 8.3 Count copy failures by error code
```sql
SELECT pi.CopyFailErrorCode, cfe.Name, COUNT(*) AS FailureCount
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
LEFT JOIN [Dictionary].[CopyFailErrorCode] cfe WITH (NOLOCK) ON pi.CopyFailErrorCode = cfe.ID
WHERE pi.CopyFailErrorCode IS NOT NULL
GROUP BY pi.CopyFailErrorCode, cfe.Name
ORDER BY FailureCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Confirms PlanInstances.CopyFailErrorCode references this domain |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CopyFailErrorCode | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.CopyFailErrorCode.sql*
