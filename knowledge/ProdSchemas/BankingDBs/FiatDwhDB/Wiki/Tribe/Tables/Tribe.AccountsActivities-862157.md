# Tribe.AccountsActivities-862157

> Parent container table for Tribe AccountsActivities data files. Each row represents a received JSON file containing account activity (transaction) records from the Tribe provider.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

AccountsActivities-862157 is a parent/container table in the Tribe JSON-flattened data warehouse. Each row represents a single data file received from the Tribe provider containing account activity (transaction) records. The actual transaction details are stored in child tables (AccountsActivities_AccountActivity-833937, AccountsActivities_RiskActions-322546, AccountsActivities_SecurityChecks-471048) which reference this table via the @Id GUID.

The numeric suffix (-862157) is a Tribe schema version identifier. The @FileName column stores the source file name. This table is part of the raw data layer - no transformation is applied, data is stored as-received.

---

## 2. Business Logic

### 2.1 JSON File Container Pattern

**What**: All Tribe parent tables follow the same pattern: file-level container with GUID PK.

**Columns/Parameters Involved**: `@Id`, `@FileName`, `@Created`, `Created`

**Rules**:
- @Id: GUID assigned to each file, used as the FK in all child tables
- @FileName: Source file name from Tribe's delivery system
- @Created: DWH insertion timestamp (datetime2, auto-set)
- Created: Source system timestamp (datetime, from Tribe)
- Child tables reference this via column named @AccountsActivities@Id-862157

---

## 3. Data Overview

N/A - file container metadata.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. Auto-set on insert. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique identifier for this data file. PK. Referenced by child tables. |
| 3 | @FileName | nvarchar(max) | YES | - | CODE-BACKED | Name of the source data file from Tribe. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system creation timestamp from Tribe. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.AccountsActivities_AccountActivity-833937 | @AccountsActivities@Id-862157 | Implicit FK | Transaction detail records |
| Tribe.AccountsActivities_RiskActions-322546 | @AccountsActivities@Id-862157 | Implicit FK | Risk action records |
| Tribe.AccountsActivities_SecurityChecks-471048 | @AccountsActivities@Id-862157 | Implicit FK | Security check records |
| Tribe.AccountsActivities_862157 (view) | SELECT | Read | View wrapper for this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.AccountsActivities_AccountActivity-833937 | Table | Child table |
| Tribe.AccountsActivities_RiskActions-322546 | Table | Child table |
| Tribe.AccountsActivities_SecurityChecks-471048 | Table | Child table |
| Tribe.AccountsActivities_862157 (view) | View | View wrapper |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountsActivities-862157 | CLUSTERED | @Id ASC | - | - | Active |
| IX_AccountsActivities-862157_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | @Created defaults to getutcdate() |
| DF_Created_AccountsActivities-862157 | DEFAULT | Created defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent data files
```sql
SELECT TOP 10 [@Id], [@FileName], [@Created], Created
FROM Tribe.[AccountsActivities-862157] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Count files per day
```sql
SELECT CAST(Created AS DATE) AS FileDate, COUNT(*) AS FileCount
FROM Tribe.[AccountsActivities-862157] WITH (NOLOCK)
WHERE Created >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY CAST(Created AS DATE) ORDER BY FileDate DESC;
```

### 8.3 Join with child table to get transaction details
```sql
SELECT TOP 5 p.[@FileName], c.HolderId, c.AccountId, c.TransactionAmount, c.TransactionCurrencyAlpha
FROM Tribe.[AccountsActivities-862157] p WITH (NOLOCK)
JOIN Tribe.[AccountsActivities_AccountActivity-833937] c WITH (NOLOCK) ON c.[@AccountsActivities@Id-862157] = p.[@Id]
ORDER BY p.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.AccountsActivities-862157 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.AccountsActivities-862157.sql*
