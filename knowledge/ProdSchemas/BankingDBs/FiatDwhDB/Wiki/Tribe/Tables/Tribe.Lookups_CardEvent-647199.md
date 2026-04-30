# Tribe.Lookups_CardEvent-647199

> Grandchild lookup: individual card event code values. Code (@cc) + description (#text). Collection parent: Lookups_CardEvents-880121.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

---

## 1. Business Meaning

Card event code values from Tribe lookups. Defines the types of card lifecycle events (activation, block, etc.).

---

## 2. Business Logic

No complex logic. Code/description pair.

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_CardEvents@Id-880121 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Card event code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FK | Tribe.Lookups_CardEvents-880121 | Implicit FK | Collection |

### 5.2 Referenced By (other objects point to this)

Not analyzed.

---

## 6. Dependencies

Depends on: Lookups_CardEvents-880121 -> Lookups-75520.

---

## 7. Technical Details

Standard Tribe lookup indexes and defaults.

---

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc] AS Code, [#text] AS Description FROM Tribe.[Lookups_CardEvent-647199] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_CardEvent-647199] WITH (NOLOCK);
```

### 8.3 Join
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_CardEvents-880121] col WITH (NOLOCK)
JOIN Tribe.[Lookups_CardEvent-647199] c WITH (NOLOCK) ON c.[@Lookups_CardEvents@Id-880121] = col.[@Id];
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_CardEvent-647199 | Type: Table*
