# Tribe.AccountsSnapshots_AccountSnapshot-956050

> Child table storing account snapshot details from Tribe, containing point-in-time account state (status, balance, program info) as raw nvarchar data.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

AccountsSnapshots_AccountSnapshot-956050 stores detailed account snapshot records from Tribe. Each row captures the point-in-time state of an account including status, program assignment, holder details, and balance information. Parent: Tribe.AccountsSnapshots-509416.

---

## 2. Business Logic

No complex logic. Raw data child table with account state snapshot columns.

---

## 3. Data Overview

N/A - raw provider snapshot data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique record identifier. PK. |
| 3 | @AccountsSnapshots@Id-509416 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent Tribe.AccountsSnapshots-509416. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

(Additional nvarchar(max) columns for account state data)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AccountsSnapshots@Id-509416 | Tribe.AccountsSnapshots-509416 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.AccountsSnapshots_AccountSnapshot-956050 (table)
└── Tribe.AccountsSnapshots-509416 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.AccountsSnapshots-509416 | Table | Parent |

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

### 8.1 View recent snapshots
```sql
SELECT TOP 10 * FROM Tribe.[AccountsSnapshots_AccountSnapshot-956050] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with parent
```sql
SELECT TOP 5 p.[@FileName], c.* FROM Tribe.[AccountsSnapshots-509416] p WITH (NOLOCK)
JOIN Tribe.[AccountsSnapshots_AccountSnapshot-956050] c WITH (NOLOCK) ON c.[@AccountsSnapshots@Id-509416] = p.[@Id] ORDER BY c.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[AccountsSnapshots_AccountSnapshot-956050] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.AccountsSnapshots_AccountSnapshot-956050 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.AccountsSnapshots_AccountSnapshot-956050.sql*
