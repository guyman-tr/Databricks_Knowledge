# Tribe.Lookups_AccountStatusCode-11277

> Grandchild lookup table storing individual account status code values from Tribe reference data. Contains code (@cc) and description (#text) pairs.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, no PK constraint) |
| **Partition** | No |
| **Indexes** | 2 active |

---

## 1. Business Meaning

Lookups_AccountStatusCode-11277 stores individual account status code values from Tribe's lookup data. Each row has a code (@cc) and description (#text). Grandchild: references Lookups_AccountStatusCodes-618179 (collection). This pattern repeats for all 16 Tribe lookup types.

---

## 2. Business Logic

### 2.1 Tribe Lookup Code/Description Pattern

**What**: All Tribe lookup singular tables store code-description pairs.

**Columns**: `@cc` (the code value), `#text` (the human-readable description)

---

## 3. Data Overview

N/A - lookup reference data from Tribe.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record identifier (no PK constraint). |
| 2 | @Lookups_AccountStatusCodes@Id-618179 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection parent. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Account status code value from Tribe. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Human-readable description of the status code. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Lookups_AccountStatusCodes@Id-618179 | Tribe.Lookups_AccountStatusCodes-618179 | Implicit FK | Collection parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Lookups_AccountStatusCode-11277 (table)
└── Tribe.Lookups_AccountStatusCodes-618179 (table)
    └── Tribe.Lookups-75520 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Lookups_AccountStatusCodes-618179 | Table | Collection parent |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_FK | NONCLUSTERED | @Lookups_AccountStatusCodes@Id-618179 | - | - | Active |
| IX_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | Created defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 View all account status codes
```sql
SELECT [@cc] AS Code, [#text] AS Description FROM Tribe.[Lookups_AccountStatusCode-11277] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Join with collection parent
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_AccountStatusCodes-618179] col WITH (NOLOCK)
JOIN Tribe.[Lookups_AccountStatusCode-11277] c WITH (NOLOCK) ON c.[@Lookups_AccountStatusCodes@Id-618179] = col.[@Id]
ORDER BY c.[@cc];
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_AccountStatusCode-11277] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.Lookups_AccountStatusCode-11277 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Lookups_AccountStatusCode-11277.sql*
