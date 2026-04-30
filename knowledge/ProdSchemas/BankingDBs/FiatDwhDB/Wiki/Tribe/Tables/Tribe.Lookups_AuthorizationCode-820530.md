# Tribe.Lookups_AuthorizationCode-820530

> Grandchild lookup: individual authorization code values. Code (@cc) + description (#text). Grandparent: Lookups_AuthorizationCodes-628148.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

---

## 1. Business Meaning

Authorization code values from Tribe lookups. Same pattern as all singular lookup tables.

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
| 2 | @Lookups_AuthorizationCodes@Id-628148 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Authorization code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FK | Tribe.Lookups_AuthorizationCodes-628148 | Implicit FK | Collection |

### 5.2 Referenced By (other objects point to this)

Not analyzed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
-> Lookups_AuthorizationCodes-628148 -> Lookups-75520
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Lookups_AuthorizationCodes-628148 | Table | Collection parent |

### 6.2 Objects That Depend On This

No dependents.

---

## 7. Technical Details

Standard Tribe lookup indexes and defaults.

---

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc] AS Code, [#text] AS Description FROM Tribe.[Lookups_AuthorizationCode-820530] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_AuthorizationCode-820530] WITH (NOLOCK);
```

### 8.3 Join
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_AuthorizationCodes-628148] col WITH (NOLOCK)
JOIN Tribe.[Lookups_AuthorizationCode-820530] c WITH (NOLOCK) ON c.[@Lookups_AuthorizationCodes@Id-628148] = col.[@Id];
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_AuthorizationCode-820530 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Lookups_AuthorizationCode-820530.sql*
