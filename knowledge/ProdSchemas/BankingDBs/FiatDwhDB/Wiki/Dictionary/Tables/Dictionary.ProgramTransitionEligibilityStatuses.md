# Dictionary.ProgramTransitionEligibilityStatuses

> Lookup table defining Eligibility outcome values for the fiat platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (TINYINT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

Dictionary.ProgramTransitionEligibilityStatuses is a lookup/reference table that defines the valid values for Eligibility outcome. Each row maps an integer Id to a human-readable Name. These values are referenced by dbo schema tables via implicit or explicit FK relationships.

See [ProgramTransitionEligibilityStatuses](../../_glossary.md) in the Business Glossary for full value descriptions and business meaning.

---

## 2. Business Logic

No complex logic. Static lookup table with pre-defined values.

---

## 3. Data Overview

Values: 0=Pending through 4=Expired

See glossary for full value map with business descriptions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Lookup identifier. Primary key. |
| 2 | Name | nvarchar(32-50) | NO | - | CODE-BACKED | Human-readable name for this value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Referenced by: dbo.ProgramTransitionsEligibilityStatuses

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (leaf lookup table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Referenced by dbo schema tables (see Section 5.2).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ProgramTransitionEligibilityStatuses | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK).

---

## 8. Sample Queries

### 8.1 View all values
```sql
SELECT * FROM Dictionary.ProgramTransitionEligibilityStatuses WITH (NOLOCK) ORDER BY Id;
```

### 8.2 Look up by Id
```sql
SELECT Name FROM Dictionary.ProgramTransitionEligibilityStatuses WITH (NOLOCK) WHERE Id = 1;
```

### 8.3 Join with referencing table
```sql
SELECT d.Id, d.Name, COUNT(*) AS UsageCount
FROM Dictionary.ProgramTransitionEligibilityStatuses d WITH (NOLOCK)
-- JOIN with appropriate dbo table
GROUP BY d.Id, d.Name ORDER BY d.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.ProgramTransitionEligibilityStatuses | Type: Table | Source: FiatDwhDB/Dictionary/Tables/Dictionary.ProgramTransitionEligibilityStatuses.sql*
