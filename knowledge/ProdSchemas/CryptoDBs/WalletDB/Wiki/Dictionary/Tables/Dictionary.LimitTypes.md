# Dictionary.LimitTypes

> Lookup table defining whether a transaction limit enforces a minimum floor or maximum ceiling on transaction amounts.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the direction of a transaction limit - whether it sets a minimum amount (floor) or maximum amount (ceiling). This enables the platform to enforce both "transactions must be at least X" and "transactions may not exceed Y" rules.

Minimum limits prevent uneconomically small transactions (where fees would exceed the transaction value), while maximum limits enforce regulatory caps and risk controls.

The table is FK-referenced by `Wallet.LimitationsDefinitions` and works with LimitScopes, LimitActions, LimitClassifications, and LimitTargets to form complete limit rules.

---

## 2. Business Logic

### 2.1 Limit Direction

**What**: Floor vs. ceiling enforcement.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Min` (1): Minimum threshold - transaction amount must be >= the limit value. Prevents dust transactions and uneconomically small operations.
- `Max` (2): Maximum threshold - transaction amount must be <= the limit value. Enforces regulatory caps, risk limits, and anti-money laundering thresholds.

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Min | Minimum amount floor. Transactions below this threshold are rejected. Prevents dust transactions that would cost more in fees than they are worth, and enforces minimum order sizes required by business rules. |
| 2 | Max | Maximum amount ceiling. Transactions above this threshold are blocked (Enforce) or flagged (Alert). Enforces regulatory limits like AML reporting thresholds, daily/monthly caps, and risk management ceilings. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the limit type. Values: 1=Min (floor), 2=Max (ceiling). FK target for Wallet.LimitationsDefinitions.LimitTypeId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Label for the limit direction. Used in limit configuration UIs and compliance reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.LimitationsDefinitions | LimitTypeId | FK | Each limit rule specifies Min or Max direction |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitationsDefinitions | Table | FK on LimitTypeId |
| Wallet.GetLimitationsConfigurations | Stored Procedure | Reads limit configs with type names |
| Wallet.AddLimitationDefinition | Stored Procedure | Validates type ID when creating limits |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LimitTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all limit types
```sql
SELECT Id, Name FROM Dictionary.LimitTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Maximum limits by transaction type
```sql
SELECT tt.Name AS TransactionType, ld.LimitValue AS MaxLimit
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitTypes lt WITH (NOLOCK) ON ld.LimitTypeId = lt.Id
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON ld.TransactionTypeId = tt.Id
WHERE lt.Id = 2 -- Max
ORDER BY ld.LimitValue DESC
```

### 8.3 Minimum limits (dust prevention)
```sql
SELECT ld.Id, lt.Name AS Type, ld.LimitValue
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitTypes lt WITH (NOLOCK) ON ld.LimitTypeId = lt.Id
WHERE lt.Id = 1 -- Min
ORDER BY ld.LimitValue
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.LimitTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.LimitTypes.sql*
