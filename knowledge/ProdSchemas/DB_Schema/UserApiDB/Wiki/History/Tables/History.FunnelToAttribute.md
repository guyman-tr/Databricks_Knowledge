# History.FunnelToAttribute

> System versioning history table mapping registration funnels to user attributes with temporal validity.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (clustered on ValidTo,ValidFrom) |
| **Partition** | No |
| **Indexes** | 1 (clustered on ValidTo,ValidFrom) |

---

## 1. Business Meaning

History.FunnelToAttribute is a system versioning history table that stores previous versions of funnel-to-attribute mappings. Tracks how registration funnels map to user interest attributes over time. This enables analyzing which funnels drove which attribute assignments historically.

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
| 1 | FunnelID | int | NO | - | CODE-BACKED | Registration funnel identifier. |
| 2 | AttributeID | int | NO | - | CODE-BACKED | User attribute mapped to this funnel. See [Attribute](_glossary.md#attribute). |
| 3 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Mapping version start. |
| 4 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Mapping version end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

System versioning pair with its source table.

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
| ix_FunnelToAttribute | CLUSTERED | ValidTo, ValidFrom | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Historical mappings
```sql
SELECT FunnelID, AttributeID, ValidFrom, ValidTo FROM History.FunnelToAttribute WITH (NOLOCK) ORDER BY ValidFrom
```

### 8.2 Mappings for a funnel
```sql
SELECT * FROM History.FunnelToAttribute WITH (NOLOCK) WHERE FunnelID = @FunnelID ORDER BY ValidFrom DESC
```

### 8.3 Count historical changes
```sql
SELECT FunnelID, COUNT(*) AS ChangeCount FROM History.FunnelToAttribute WITH (NOLOCK) GROUP BY FunnelID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.FunnelToAttribute | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.FunnelToAttribute.sql*
