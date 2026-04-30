# Dictionary.ValidateTokenStatuses

> Lookup table defining the outcomes of ERC-20 token validation checks on blockchain addresses.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the outcomes of validating whether a blockchain address can properly handle a specific ERC-20 token. Unlike InitTokenStatuses (which tracks initialization), this table tracks post-initialization validation - confirming the token contract interaction works correctly. Two simple outcomes: Verified (works) or Failed (doesn't work).

No direct FK references found. Consumed by application-layer token validation logic.

---

## 2. Business Logic

No complex multi-column business logic. Binary validation outcome: `Verified` (1) = address can handle the token, `Failed` (2) = address cannot handle the token.

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Verified | Token validation passed. The address can correctly interact with the ERC-20 token contract. Safe for receiving this token type. |
| 2 | Failed | Token validation failed. The address cannot properly handle this token. May indicate an incompatible contract version or address configuration issue. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 1=Verified, 2=Failed. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Validation outcome label. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct references found.

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ValidateTokenStatuses | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all validation statuses
```sql
SELECT Id, Name FROM Dictionary.ValidateTokenStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Resolve status
```sql
SELECT Name FROM Dictionary.ValidateTokenStatuses WITH (NOLOCK) WHERE Id = 1
```

### 8.3 All statuses with guidance
```sql
SELECT Id, Name, CASE Id WHEN 1 THEN 'Ready for tokens' WHEN 2 THEN 'Needs investigation' END AS Guidance
FROM Dictionary.ValidateTokenStatuses WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ValidateTokenStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ValidateTokenStatuses.sql*
