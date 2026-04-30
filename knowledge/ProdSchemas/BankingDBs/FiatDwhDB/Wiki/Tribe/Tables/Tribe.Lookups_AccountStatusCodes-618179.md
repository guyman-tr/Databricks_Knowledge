# Tribe.Lookups_AccountStatusCodes-618179

> Child collection table for account status codes array in Tribe lookup files. Intermediate between Lookups parent and individual AccountStatusCode records.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Account status codes collection from Tribe lookups. Intermediate: Lookups-75520 -> AccountStatusCodes -> AccountStatusCode-11277.

---

## 2. Business Logic

No complex logic. JSON array container for account status code entries.

---

## 3. Data Overview

N/A - collection container.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. Referenced by AccountStatusCode-11277. |
| 3 | @Lookups@Id-75520 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent Lookups. |
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
| Tribe.Lookups_AccountStatusCode-11277 | @Lookups_AccountStatusCodes@Id-618179 | Implicit FK | Grandchild |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Lookups_AccountStatusCodes-618179 (table)
└── Tribe.Lookups-75520 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Lookups-75520 | Table | Parent |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Lookups_AccountStatusCode-11277 | Table | Grandchild |

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

### 8.1 View with codes
```sql
SELECT col.[@Id], c.[@cc] AS Code, c.[#text] AS Description
FROM Tribe.[Lookups_AccountStatusCodes-618179] col WITH (NOLOCK)
JOIN Tribe.[Lookups_AccountStatusCode-11277] c WITH (NOLOCK) ON c.[@Lookups_AccountStatusCodes@Id-618179] = col.[@Id]
ORDER BY c.[@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_AccountStatusCodes-618179] WITH (NOLOCK);
```

### 8.3 Recent records
```sql
SELECT TOP 10 * FROM Tribe.[Lookups_AccountStatusCodes-618179] WITH (NOLOCK) ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.Lookups_AccountStatusCodes-618179 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Lookups_AccountStatusCodes-618179.sql*
