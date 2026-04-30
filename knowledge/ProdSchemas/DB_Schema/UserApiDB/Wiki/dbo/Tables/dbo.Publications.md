# dbo.Publications

> Stores user profile bio/publication data (sticky message, about me, strategy) with system versioning for temporal history.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.Publications stores user-generated profile content for the social trading platform: a "sticky" message (pinned post), "about me" text, language preference, and declared trading strategy. Uses system versioning with History.Publications for full temporal history. The Trace computed column captures session/connection metadata for audit purposes.

---

## 2. Business Logic

No complex multi-column business logic. User-editable profile content with temporal tracking.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Primary key. Legacy Customer ID (not GCID). One publication record per user. |
| 2 | Sticky | nvarchar(1000) | YES | - | CODE-BACKED | User's pinned/sticky message shown at top of their profile feed. |
| 3 | AboutMe | nvarchar(1000) | YES | - | CODE-BACKED | User's "About Me" bio text displayed on their profile page. |
| 4 | LanguageCode | varchar(50) | YES | - | CODE-BACKED | Language code for the publication content. |
| 5 | StrategyID | int | YES | NULL | CODE-BACKED | User's declared trading strategy. Implicit FK to Dictionary.Strategies. See [Strategies](_glossary.md#strategies). |
| 6 | Trace | computed | - | - | CODE-BACKED | Computed: JSON object with HostName, AppName, SUserName, SPID, DBName, ObjectName. For audit trail. |
| 7 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System versioning row start (GENERATED ALWAYS AS ROW START). |
| 8 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System versioning row end (GENERATED ALWAYS AS ROW END). |
| 9 | AboutMeShort | nvarchar(300) | YES | NULL | CODE-BACKED | Shortened version of AboutMe for preview/thumbnail display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Publications | - | System Versioning | Temporal history |
| Customer.GetUserBio | CID | SP reads | Returns bio data |
| Customer.UpdateUserBio | CID | SP writes | Updates bio data |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Publications | Table | System versioning history |
| Customer.GetUserBio | Stored Procedure | Reads from |
| Customer.UpdateUserBio | Stored Procedure | Writes to |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | CID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | NULL for StrategyID |
| (unnamed) | DEFAULT | NULL for AboutMeShort |
| SYSTEM_VERSIONING | Temporal | History table: History.Publications |

---

## 8. Sample Queries

### 8.1 Get user bio
```sql
SELECT CID, Sticky, AboutMe, AboutMeShort, StrategyID FROM dbo.Publications WITH (NOLOCK) WHERE CID = @CID
```

### 8.2 Users with a strategy declared
```sql
SELECT p.CID, s.StrategyValue FROM dbo.Publications p WITH (NOLOCK)
JOIN Dictionary.Strategies s WITH (NOLOCK) ON p.StrategyID = s.StrategyID WHERE p.StrategyID IS NOT NULL
```

### 8.3 Bio change history (temporal)
```sql
SELECT CID, AboutMe, ValidFrom, ValidTo FROM dbo.Publications FOR SYSTEM_TIME ALL WHERE CID = @CID ORDER BY ValidFrom
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.Publications | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.Publications.sql*
