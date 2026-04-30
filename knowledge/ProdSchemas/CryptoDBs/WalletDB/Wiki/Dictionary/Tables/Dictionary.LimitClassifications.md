# Dictionary.LimitClassifications

> Lookup table defining whether a transaction limit is a soft (advisory) or hard (mandatory) constraint, controlling the severity of limit enforcement.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table classifies transaction limits by their severity level. While `LimitActions` determines what happens when a limit is hit (enforce vs. alert), `LimitClassifications` determines the limit's inherent strictness. A soft limit can potentially be overridden by authorized personnel, while a hard limit is absolute and cannot be bypassed.

The classification system supports a layered compliance model. Regulatory limits (anti-money laundering thresholds, sanctions limits) are hard - they cannot be overridden regardless of business need. Business limits (daily withdrawal caps, new-user restrictions) are soft - they can be adjusted or overridden by authorized staff.

The table is FK-referenced by `Wallet.LimitationsDefinitions` and consumed by limitation configuration stored procedures.

---

## 2. Business Logic

### 2.1 Limit Severity Model

**What**: Binary classification of limit strictness.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Soft` (1): Advisory limit that can be overridden by authorized personnel. Used for business-driven restrictions that may have legitimate exceptions (e.g., a high-value customer needs a one-time higher withdrawal).
- `Hard` (2): Absolute limit that cannot be bypassed. Used for regulatory-mandated thresholds where no exception is permitted (e.g., AML reporting thresholds, sanctions compliance limits).

**Diagram**:
```
Limit Hit
    |
    +---> Soft (1): "Can be overridden"
    |       Back-office can approve exception
    |
    +---> Hard (2): "Cannot be bypassed"
            No exceptions, even for high-value customers
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Soft | Advisory limit that authorized personnel can override on a case-by-case basis. Applied to business-driven caps like daily withdrawal limits or new-user restrictions. Override requests are logged for audit trail purposes. |
| 2 | Hard | Absolute limit with no override capability. Applied to regulatory-mandated thresholds where exceeding would violate compliance obligations. Even back-office staff with elevated permissions cannot bypass a hard limit. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the classification. Values: 1=Soft (overridable), 2=Hard (absolute). FK target for Wallet.LimitationsDefinitions.LimitClassificationId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Label for the classification. Used in limit configuration UIs and compliance dashboards to indicate override capability. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.LimitationsDefinitions | LimitClassificationId | FK | Each limit rule is classified as soft or hard |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitationsDefinitions | Table | FK on LimitClassificationId |
| Wallet.GetLimitationsConfigurations | Stored Procedure | Reads limit configs with classification names |
| Wallet.AddLimitationDefinition | Stored Procedure | Validates classification ID when creating limits |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LimitClassifications | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all classifications
```sql
SELECT Id, Name FROM Dictionary.LimitClassifications WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count limits by classification
```sql
SELECT lc.Name AS Classification, COUNT(ld.Id) AS LimitCount
FROM Dictionary.LimitClassifications lc WITH (NOLOCK)
LEFT JOIN Wallet.LimitationsDefinitions ld WITH (NOLOCK) ON ld.LimitClassificationId = lc.Id
GROUP BY lc.Name
```

### 8.3 Hard limits (no override possible)
```sql
SELECT ld.Id, lc.Name AS Classification, la.Name AS Action, ld.LimitValue
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitClassifications lc WITH (NOLOCK) ON ld.LimitClassificationId = lc.Id
JOIN Dictionary.LimitActions la WITH (NOLOCK) ON ld.LimitActionId = la.Id
WHERE lc.Id = 2 -- Hard
ORDER BY ld.LimitValue DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.LimitClassifications | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.LimitClassifications.sql*
