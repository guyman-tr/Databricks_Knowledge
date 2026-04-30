# Tribe.AccountsActivities_862157 (View)

> Simple view wrapper over the Tribe.AccountsActivities-862157 table, providing a clean view name without the hyphen that some tools struggle with.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | View |
| **Key Identifier** | Wraps Tribe.[AccountsActivities-862157] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AccountsActivities_862157 (view) is a thin wrapper over the Tribe.[AccountsActivities-862157] table. It provides an alternative name using underscore instead of hyphen, which is easier to reference in some SQL tools and application code that don't handle hyphenated table names well. The view selects all 4 columns from the base table unchanged.

---

## 2. Business Logic

No transformation. Simple `SELECT [@Created], [@Id], [@FileName], Created FROM tribe.[AccountsActivities-862157]`.

---

## 3. Data Overview

Same as base table Tribe.AccountsActivities-862157.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | - | CODE-BACKED | DWH insertion timestamp. From base table. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | File GUID. From base table. |
| 3 | @FileName | nvarchar(max) | YES | - | CODE-BACKED | Source file name. From base table. |
| 4 | Created | datetime | NO | - | CODE-BACKED | Source timestamp. From base table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Tribe.AccountsActivities-862157 | Base table | All columns from this table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.AccountsActivities_862157 (view)
└── Tribe.AccountsActivities-862157 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.AccountsActivities-862157 | Table | Base table for SELECT |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View (not indexed).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query through view
```sql
SELECT TOP 10 * FROM Tribe.AccountsActivities_862157 ORDER BY Created DESC;
```

### 8.2 Compare view vs table
```sql
SELECT COUNT(*) AS ViewCount FROM Tribe.AccountsActivities_862157;
SELECT COUNT(*) AS TableCount FROM Tribe.[AccountsActivities-862157] WITH (NOLOCK);
```

### 8.3 Use view for joins
```sql
SELECT TOP 5 v.[@FileName], c.HolderId, c.TransactionAmount
FROM Tribe.AccountsActivities_862157 v
JOIN Tribe.[AccountsActivities_AccountActivity-833937] c WITH (NOLOCK) ON c.[@AccountsActivities@Id-862157] = v.[@Id]
ORDER BY v.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Object: Tribe.AccountsActivities_862157 | Type: View | Source: FiatDwhDB/Tribe/Views/Tribe.AccountsActivities_862157.sql*
