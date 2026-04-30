# Tribe.Lookups_CardStatusCodes-124076

> Child collection for card status codes array. Intermediate: Lookups -> CardStatusCodes -> CardStatusCode. Referenced by CardStatusCode-540871.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Card status codes collection from Tribe lookups. Referenced by CardStatusCode-540871 grandchild.

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

Parent: Lookups-75520. Child: CardStatusCode-540871.

---

## 6. Dependencies

Depends on: Lookups-75520. Depended on by: CardStatusCode-540871.

---

## 7. Technical Details

Standard Tribe collection indexes and defaults.

---

## 8. Sample Queries

### 8.1 View with codes
```sql
SELECT col.[@Id], c.[@cc], c.[#text] FROM Tribe.[Lookups_CardStatusCodes-124076] col WITH (NOLOCK)
JOIN Tribe.[Lookups_CardStatusCode-540871] c WITH (NOLOCK) ON c.[@Lookups_CardStatusCodes@Id-124076] = col.[@Id];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_CardStatusCodes-124076] WITH (NOLOCK);
```

### 8.3 Recent
```sql
SELECT TOP 10 * FROM Tribe.[Lookups_CardStatusCodes-124076] WITH (NOLOCK) ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_CardStatusCodes-124076 | Type: Table*
