# Tribe.AccountsActivities_SecurityChecks-471048

> Child table storing security check results from Tribe account activity records.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

AccountsActivities_SecurityChecks-471048 stores security check records from Tribe account activity files. Each row represents a security validation performed during transaction processing (e.g., 3D Secure, AVS, CVV checks). Parent: Tribe.AccountsActivities-862157.

---

## 2. Business Logic

No complex logic. Raw data child table.

---

## 3. Data Overview

N/A - raw provider security data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique record identifier. PK. |
| 3 | @AccountsActivities@Id-862157 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AccountsActivities@Id-862157 | Tribe.AccountsActivities-862157 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.AccountsActivities_SecurityChecks-471048 (table)
└── Tribe.AccountsActivities-862157 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.AccountsActivities-862157 | Table | Parent |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK | CLUSTERED | @Id ASC | - | - | Active |
| IX_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent records
```sql
SELECT TOP 10 * FROM Tribe.[AccountsActivities_SecurityChecks-471048] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with parent
```sql
SELECT p.[@FileName], c.* FROM Tribe.[AccountsActivities-862157] p WITH (NOLOCK)
JOIN Tribe.[AccountsActivities_SecurityChecks-471048] c WITH (NOLOCK) ON c.[@AccountsActivities@Id-862157] = p.[@Id] ORDER BY c.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[AccountsActivities_SecurityChecks-471048] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.AccountsActivities_SecurityChecks-471048 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.AccountsActivities_SecurityChecks-471048.sql*
