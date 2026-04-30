# Tribe.Lookups_Network-592401

> Grandchild lookup: individual network code values. Collection: Networks-128332. Defines payment networks (Visa, Mastercard, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

## 1. Business Meaning

Payment network codes from Tribe. Grandchild of Lookups via Networks.

## 2. Business Logic

Code/description pair.

## 3. Data Overview

N/A.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_Networks@Id-128332 | uniqueidentifier | NO | - | CODE-BACKED | FK. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Network code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

## 5. Relationships

Parent: Networks-128332 -> Lookups-75520.

## 6. Dependencies

Depends on: Networks-128332.

## 7. Technical Details

Standard Tribe lookup indexes.

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc], [#text] FROM Tribe.[Lookups_Network-592401] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_Network-592401] WITH (NOLOCK);
```

### 8.3 Join
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_Networks-128332] col WITH (NOLOCK)
JOIN Tribe.[Lookups_Network-592401] c WITH (NOLOCK) ON c.[@Lookups_Networks@Id-128332] = col.[@Id];
```

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_Network-592401 | Type: Table*
