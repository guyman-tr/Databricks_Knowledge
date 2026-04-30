# Tribe.Authorizes_Authorize-312243

> Child table storing detailed card authorization records from Tribe, containing authorization request/response fields including amounts, currencies, merchant data, and authorization codes.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Authorizes_Authorize-312243 stores the detailed authorization records from Tribe. Each row represents a single real-time card authorization request/response containing amounts in multiple currencies, merchant info, authorization codes, and card present indicators. This is the raw data complement to dbo.FiatTransactionsStatuses for authorization events. Parent: Tribe.Authorizes-837045.

---

## 2. Business Logic

No complex logic. Raw Tribe authorization data with all fields as nvarchar(max).

---

## 3. Data Overview

N/A - raw provider authorization data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @Authorizes@Id-837045 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent Tribe.Authorizes-837045. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

(Additional nvarchar(max) columns for authorization fields)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Authorizes@Id-837045 | Tribe.Authorizes-837045 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Authorizes_Authorize-312243 (table)
└── Tribe.Authorizes-837045 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Authorizes-837045 | Table | Parent |

### 6.2 Objects That Depend On This

No dependents found.

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

### 8.1 View recent authorizations
```sql
SELECT TOP 10 * FROM Tribe.[Authorizes_Authorize-312243] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with parent
```sql
SELECT TOP 5 p.[@FileName], c.* FROM Tribe.[Authorizes-837045] p WITH (NOLOCK)
JOIN Tribe.[Authorizes_Authorize-312243] c WITH (NOLOCK) ON c.[@Authorizes@Id-837045] = p.[@Id] ORDER BY c.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[Authorizes_Authorize-312243] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.Authorizes_Authorize-312243 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Authorizes_Authorize-312243.sql*
