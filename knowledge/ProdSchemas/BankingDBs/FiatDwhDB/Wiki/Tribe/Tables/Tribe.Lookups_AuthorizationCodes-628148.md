# Tribe.Lookups_AuthorizationCodes-628148

> Child collection for authorization codes array. Intermediate: Lookups -> AuthorizationCodes -> AuthorizationCode.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Authorization codes collection from Tribe lookups. Referenced by AuthorizationCode-820530 grandchild.

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
| 3 | @Lookups@Id-75520 | uniqueidentifier | NO | - | CODE-BACKED | FK to Lookups parent. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Lookups@Id-75520 | Tribe.Lookups-75520 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.Lookups_AuthorizationCode-820530 | FK | Implicit FK | Grandchild |

---

## 6. Dependencies

Depends on: Tribe.Lookups-75520. Depended on by: Tribe.Lookups_AuthorizationCode-820530.

---

## 7. Technical Details

Standard Tribe collection indexes and defaults.

---

## 8. Sample Queries

### 8.1 View with codes
```sql
SELECT col.[@Id], c.[@cc], c.[#text] FROM Tribe.[Lookups_AuthorizationCodes-628148] col WITH (NOLOCK)
JOIN Tribe.[Lookups_AuthorizationCode-820530] c WITH (NOLOCK) ON c.[@Lookups_AuthorizationCodes@Id-628148] = col.[@Id];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_AuthorizationCodes-628148] WITH (NOLOCK);
```

### 8.3 Recent
```sql
SELECT TOP 10 * FROM Tribe.[Lookups_AuthorizationCodes-628148] WITH (NOLOCK) ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_AuthorizationCodes-628148 | Type: Table*
