# Dictionary.Justefied

> Configuration table storing justified (acceptable) failure identifiers for trading position failure reporting — entries in this table represent known failure patterns that have been reviewed and deemed acceptable, filtering them out of operational failure dashboards.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Name (VARCHAR(900), CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Justefied stores a whitelist of known, reviewed, and accepted failure patterns for the trading position failure reporting system. When positions fail to open or close, the system generates failure reports. However, some failures are expected or acceptable — certain instruments during market close, specific error conditions during maintenance windows, or known edge cases that don't require investigation. These accepted patterns are registered in this table.

This table exists because position failure dashboards are critical operational tools, and false positives (expected failures flagged as problems) create alert fatigue. By maintaining a whitelist of "justified" failure patterns, the reporting system can distinguish between unexpected failures requiring investigation and known acceptable failures that can be filtered out. Note: the table name contains a misspelling ("Justefied" instead of "Justified").

The table is consumed by multiple failure reporting procedures: Trade.Report_PositionsFailSummary, dbo.PR_Report_FailDashbord, dbo.PR_Report_FailDashbordNew, dbo.PR_Report_FailDashbordTest, and dbo.SplunkFailedPositions. The Name column is the PK (not the ID), and the current production table is empty — suggesting all failures are currently considered unjustified and reported.

---

## 2. Business Logic

### 2.1 Failure Whitelist Filtering

**What**: Position failure reports exclude failures whose identifier matches a Name in this table.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- The Name column (clustered PK, VARCHAR(900)) stores the failure pattern identifier — likely a combination of error code, instrument, and conditions
- Position failure reporting procedures LEFT JOIN or NOT EXISTS against this table to filter justified failures
- When the table is empty (current state), all failures are reported — no whitelist filtering occurs
- The IDENTITY column (ID) is secondary — the Name is the primary lookup key
- The large varchar(900) size suggests the Name may contain composite identifiers or structured failure descriptions

---

## 3. Data Overview

Table is empty in production (0 rows). When populated, rows would contain failure pattern identifiers that the operations team has reviewed and marked as acceptable. Currently, all position failures are reported without filtering.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing identifier. Secondary to the Name column — not used as a join key by consuming procedures. Provides a numeric reference for each justified failure entry. |
| 2 | Name | varchar(900) | NO | - | CODE-BACKED | Primary key and lookup column. Stores the failure pattern identifier that is matched against position failure reports. The large size (900 chars) accommodates composite failure identifiers. Used by 5+ failure reporting procedures for whitelist filtering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Report_PositionsFailSummary | Name | JOIN | Filters justified failures from position fail summary report |
| dbo.PR_Report_FailDashbord | Name | JOIN | Filters justified failures from the main fail dashboard |
| dbo.PR_Report_FailDashbordNew | Name | JOIN | Filters justified failures from the updated fail dashboard |
| dbo.PR_Report_FailDashbordTest | Name | JOIN | Test variant of the fail dashboard |
| dbo.SplunkFailedPositions | Name | JOIN | Filters justified failures from Splunk-integrated fail reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Report_PositionsFailSummary | Stored Procedure | Reads — whitelist filter |
| dbo.PR_Report_FailDashbord | Stored Procedure | Reads — whitelist filter |
| dbo.PR_Report_FailDashbordNew | Stored Procedure | Reads — whitelist filter |
| dbo.PR_Report_FailDashbordTest | Stored Procedure | Reads — whitelist filter |
| dbo.SplunkFailedPositions | Stored Procedure | Reads — whitelist filter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Justefied_Name | CLUSTERED PK | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Justefied_Name | PRIMARY KEY | Unique failure pattern identifier (clustered on Name, not ID) |

---

## 8. Sample Queries

### 8.1 List all justified failure patterns
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[Justefied] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Check if a specific failure is justified
```sql
SELECT  CASE WHEN EXISTS (
            SELECT 1
            FROM   [Dictionary].[Justefied] WITH (NOLOCK)
            WHERE  Name = 'SomeFailurePattern'
        ) THEN 'JUSTIFIED (filtered)' ELSE 'UNJUSTIFIED (reported)' END AS Status;
```

### 8.3 Count justified vs unjustified failures
```sql
SELECT  'Justified' AS Category, COUNT(*) AS Count
FROM    [Dictionary].[Justefied] WITH (NOLOCK)
UNION ALL
SELECT  'Total Failure Patterns', 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Justefied | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Justefied.sql*
