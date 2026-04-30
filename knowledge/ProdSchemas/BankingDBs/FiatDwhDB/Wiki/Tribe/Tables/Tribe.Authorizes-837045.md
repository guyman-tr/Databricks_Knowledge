# Tribe.Authorizes-837045

> Parent container table for Tribe Authorizes data files. Each row represents a received JSON file containing card authorization records from the Tribe provider.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Authorizes-837045 is a parent/container table for Tribe card authorization data files. Each row represents a JSON file containing card authorization events (real-time authorization requests processed by the card network). Child tables: Authorizes_Authorize-312243, Authorizes_RiskActions-796100, Authorizes_SecurityChecks-30662.

Same JSON file container pattern as all Tribe parent tables.

---

## 2. Business Logic

### 2.1 JSON File Container Pattern

Same as all Tribe parent tables. Parent with GUID PK, children reference via @Authorizes@Id-837045.

---

## 3. Data Overview

N/A - file container metadata.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique file identifier. PK. Referenced by child tables. |
| 3 | @FileName | nvarchar(max) | YES | - | CODE-BACKED | Source file name. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.Authorizes_Authorize-312243 | @Authorizes@Id-837045 | Implicit FK | Authorization details |
| Tribe.Authorizes_RiskActions-796100 | @Authorizes@Id-837045 | Implicit FK | Risk actions |
| Tribe.Authorizes_SecurityChecks-30662 | @Authorizes@Id-837045 | Implicit FK | Security checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Authorizes_Authorize-312243 | Table | Child |
| Tribe.Authorizes_RiskActions-796100 | Table | Child |
| Tribe.Authorizes_SecurityChecks-30662 | Table | Child |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Authorizes-837045 | CLUSTERED | @Id ASC | - | - | Active |
| IX_Authorizes-837045_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent authorization files
```sql
SELECT TOP 10 [@Id], [@FileName], Created FROM Tribe.[Authorizes-837045] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with authorization details
```sql
SELECT TOP 5 p.[@FileName], c.*
FROM Tribe.[Authorizes-837045] p WITH (NOLOCK)
JOIN Tribe.[Authorizes_Authorize-312243] c WITH (NOLOCK) ON c.[@Authorizes@Id-837045] = p.[@Id]
ORDER BY p.Created DESC;
```

### 8.3 Count files per day
```sql
SELECT CAST(Created AS DATE) AS FileDate, COUNT(*) FROM Tribe.[Authorizes-837045] WITH (NOLOCK) GROUP BY CAST(Created AS DATE) ORDER BY FileDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.Authorizes-837045 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Authorizes-837045.sql*
