# History.Publications

> System versioning history table for dbo.Publications, storing temporal snapshots of user bio/sticky/strategy changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (clustered on ValidTo,ValidFrom) |
| **Partition** | No |
| **Indexes** | 1 (clustered on ValidTo,ValidFrom) |

---

## 1. Business Meaning

System versioning history target for dbo.Publications. Stores previous versions of user profile content (Sticky message, AboutMe, AboutMeShort, StrategyID, LanguageCode). Queryable via FOR SYSTEM_TIME syntax on dbo.Publications.

---

## 2. Business Logic

Automatically managed by SQL Server system versioning.

---

## 3. Data Overview

N/A - system-managed history.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Legacy Customer ID. |
| 2 | Sticky | nvarchar(1000) | YES | - | CODE-BACKED | Pinned message at this point. |
| 3 | AboutMe | nvarchar(1000) | YES | - | CODE-BACKED | Bio text at this point. |
| 4 | LanguageCode | varchar(50) | YES | - | CODE-BACKED | Content language at this point. |
| 5 | StrategyID | int | YES | - | CODE-BACKED | Trading strategy at this point. |
| 6 | Trace | nvarchar(733) | NO | - | CODE-BACKED | Connection audit context. |
| 7 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Version start. |
| 8 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Version end. |
| 9 | AboutMeShort | nvarchar(300) | YES | - | CODE-BACKED | Short bio at this point. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

System versioning pair with dbo.Publications.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

System versioning pair.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Publications | CLUSTERED | ValidTo, ValidFrom | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bio history (temporal)
```sql
SELECT * FROM dbo.Publications FOR SYSTEM_TIME ALL WHERE CID = @CID ORDER BY ValidFrom
```

### 8.2 Direct history query
```sql
SELECT CID, AboutMe, StrategyID, ValidFrom, ValidTo FROM History.Publications WITH (NOLOCK) WHERE CID = @CID ORDER BY ValidFrom
```

### 8.3 Strategy changes
```sql
SELECT p.ValidFrom, s.StrategyValue FROM History.Publications p WITH (NOLOCK)
LEFT JOIN Dictionary.Strategies s WITH (NOLOCK) ON p.StrategyID = s.StrategyID WHERE p.CID = @CID ORDER BY p.ValidFrom
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.Publications | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.Publications.sql*
