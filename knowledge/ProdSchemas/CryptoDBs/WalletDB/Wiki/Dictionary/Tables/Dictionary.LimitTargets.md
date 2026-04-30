# Dictionary.LimitTargets

> Lookup table defining whether a transaction limit applies to an individual user or globally across all users on the platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the target audience for transaction limits. A limit can either apply per-user (each customer has their own limit threshold) or globally (one shared threshold across all customers). This enables both individual customer controls and platform-wide caps.

Works alongside LimitScopes, LimitTypes, LimitActions, and LimitClassifications to form the complete limit definition framework in `Wallet.LimitationsDefinitions`.

---

## 2. Business Logic

### 2.1 Limit Target Scope

**What**: Determines who the limit applies to.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `User` (1): Per-customer limit. Each customer has an independent threshold. Example: "Each user may withdraw up to $10,000 per day."
- `Global` (2): Platform-wide limit. One shared threshold for all customers combined. Example: "Total platform withdrawals may not exceed $1M per day." Used for liquidity management and risk controls.

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | User | Per-customer limit. Each customer's transactions are tracked independently against the threshold. When one customer hits their limit, other customers are unaffected. Standard for individual compliance limits. |
| 2 | Global | Platform-wide limit shared across all customers. All customer transactions count toward a single shared threshold. When the global limit is reached, all customers are affected. Used for liquidity management, hot wallet caps, and systemic risk controls. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the limit target. Values: 1=User (per-customer), 2=Global (platform-wide). FK target for Wallet.LimitationsDefinitions.LimitTargetId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Label for the target type. Used in limit configuration UIs and compliance reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.LimitationsDefinitions | LimitTargetId | FK | Each limit rule defines its target audience |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitationsDefinitions | Table | FK on LimitTargetId |
| Wallet.GetLimitationsConfigurations | Stored Procedure | Reads limit configs with target names |
| Wallet.AddLimitationDefinition | Stored Procedure | Validates target ID when creating limits |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LimitTargets | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all limit targets
```sql
SELECT Id, Name FROM Dictionary.LimitTargets WITH (NOLOCK) ORDER BY Id
```

### 8.2 Global limits (platform-wide caps)
```sql
SELECT ld.Id, lt.Name AS Target, la.Name AS Action, ld.LimitValue
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitTargets lt WITH (NOLOCK) ON ld.LimitTargetId = lt.Id
JOIN Dictionary.LimitActions la WITH (NOLOCK) ON ld.LimitActionId = la.Id
WHERE lt.Id = 2 -- Global
```

### 8.3 Compare user vs global limits
```sql
SELECT lt.Name AS Target, COUNT(ld.Id) AS LimitCount
FROM Dictionary.LimitTargets lt WITH (NOLOCK)
LEFT JOIN Wallet.LimitationsDefinitions ld WITH (NOLOCK) ON ld.LimitTargetId = lt.Id
GROUP BY lt.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.LimitTargets | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.LimitTargets.sql*
