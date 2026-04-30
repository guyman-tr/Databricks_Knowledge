# Tribe.Lookups_CardStatusCode-540871

> Grandchild lookup: individual card status code values. Code (@cc) + description (#text). Collection parent: Lookups_CardStatusCodes-124076.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

---

## 1. Business Meaning

Card status code values from Tribe lookups. Defines the possible card states in Tribe's system. Referenced by CardsSnapshots_CardSnapshot CardStatusCode column.

---

## 2. Business Logic

Code/description pair for card statuses.

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_CardStatusCodes@Id-124076 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Card status code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

---

## 5. Relationships

Parent: Lookups_CardStatusCodes-124076.

---

## 6. Dependencies

Depends on: Lookups_CardStatusCodes-124076 -> Lookups-75520.

---

## 7. Technical Details

Standard Tribe lookup indexes and defaults.

---

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc] AS Code, [#text] AS Description FROM Tribe.[Lookups_CardStatusCode-540871] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_CardStatusCode-540871] WITH (NOLOCK);
```

### 8.3 Join
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_CardStatusCodes-124076] col WITH (NOLOCK)
JOIN Tribe.[Lookups_CardStatusCode-540871] c WITH (NOLOCK) ON c.[@Lookups_CardStatusCodes@Id-124076] = col.[@Id];
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_CardStatusCode-540871 | Type: Table*
