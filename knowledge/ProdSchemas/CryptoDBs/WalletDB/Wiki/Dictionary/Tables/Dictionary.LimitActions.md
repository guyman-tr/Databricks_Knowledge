# Dictionary.LimitActions

> Lookup table defining the enforcement actions taken when a wallet transaction limit is reached - either hard-enforce (block) or soft-alert (warn).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines what happens when a customer reaches a configured transaction limit in the wallet system. Limits can either be hard-enforced (blocking the transaction) or soft-enforced (allowing the transaction but raising an alert for compliance review).

The two-action model gives the compliance team flexibility to configure limits appropriate to the risk level. High-risk limits (e.g., sanctions thresholds) are enforced, while lower-risk limits (e.g., unusual activity patterns) generate alerts without blocking customers.

The table is FK-referenced by `Wallet.LimitationsDefinitions` and consumed by limitation configuration stored procedures.

---

## 2. Business Logic

### 2.1 Limit Enforcement Model

**What**: Binary enforcement choice for each configured limit.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Enforce` (1): Hard limit - the transaction is blocked if it exceeds the configured threshold. Customer receives an error and must contact support. Used for regulatory hard caps and compliance-mandated limits.
- `Alert` (2): Soft limit - the transaction proceeds but an alert is raised for compliance review. Used for monitoring thresholds where blocking would be too disruptive but oversight is needed.

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Enforce | Transaction is blocked when the limit is exceeded. The customer cannot proceed until the limit is adjusted or the period resets. Appropriate for regulatory limits where exceeding the threshold would violate compliance rules. |
| 2 | Alert | Transaction is allowed but flagged for review. The compliance team receives an alert and can investigate. Appropriate for monitoring thresholds where false positives would harm customer experience but oversight is still needed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the limit action. Values: 1=Enforce (block), 2=Alert (warn). FK target for Wallet.LimitationsDefinitions.LimitActionId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Label for the enforcement action. Used in limit configuration UIs and compliance reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.LimitationsDefinitions | LimitActionId | FK | Each limit rule specifies whether to enforce or alert |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitationsDefinitions | Table | FK on LimitActionId |
| Wallet.GetLimitationsConfigurations | Stored Procedure | Reads limit configs with action names |
| Wallet.AddLimitationDefinition | Stored Procedure | Validates action ID when creating limits |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LimitActions | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all limit actions
```sql
SELECT Id, Name FROM Dictionary.LimitActions WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count limits by enforcement action
```sql
SELECT la.Name AS Action, COUNT(ld.Id) AS LimitCount
FROM Dictionary.LimitActions la WITH (NOLOCK)
LEFT JOIN Wallet.LimitationsDefinitions ld WITH (NOLOCK) ON ld.LimitActionId = la.Id
GROUP BY la.Name
```

### 8.3 List enforced limits with their definitions
```sql
SELECT ld.Id, la.Name AS Action, ld.LimitValue, ld.Created
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitActions la WITH (NOLOCK) ON ld.LimitActionId = la.Id
WHERE la.Id = 1 -- Enforce
ORDER BY ld.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.LimitActions | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.LimitActions.sql*
