# Tribe.Lookups_EntryModeCodes-113961

> Child collection for entry mode codes array. Intermediate: Lookups -> EntryModeCodes -> EntryModeCode. Referenced by EntryModeCode-990006.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Entry mode codes collection from Tribe lookups. Referenced by EntryModeCode-990006 grandchild.

---

## 2. Business Logic

No complex logic. JSON array container.

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @Lookups@Id-75520 | uniqueidentifier | NO | - | CODE-BACKED | FK to Lookups. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

Parent: Lookups-75520. Child: EntryModeCode-990006.

---

## 6. Dependencies

Depends on: Lookups-75520. Depended on by: EntryModeCode-990006.

---

## 7. Technical Details

Standard Tribe collection indexes and defaults.

---

## 8. Sample Queries

### 8.1 View with codes
```sql
SELECT col.[@Id], c.[@cc], c.[#text] FROM Tribe.[Lookups_EntryModeCodes-113961] col WITH (NOLOCK)
JOIN Tribe.[Lookups_EntryModeCode-990006] c WITH (NOLOCK) ON c.[@Lookups_EntryModeCodes@Id-113961] = col.[@Id];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_EntryModeCodes-113961] WITH (NOLOCK);
```

### 8.3 Recent
```sql
SELECT TOP 10 * FROM Tribe.[Lookups_EntryModeCodes-113961] WITH (NOLOCK) ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_EntryModeCodes-113961 | Type: Table*
