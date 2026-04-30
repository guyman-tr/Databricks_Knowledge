# Dictionary.LimitScopes

> Lookup table defining whether a transaction limit applies to a single operation or accumulates over a time period.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the temporal scope of transaction limits in the wallet system. A limit can either apply to each individual transaction (Single) or accumulate across multiple transactions within a defined period (Periodic). This distinction determines how the limit engine evaluates whether a transaction exceeds the threshold.

The scope classification works alongside LimitTypes (Min/Max), LimitActions (Enforce/Alert), LimitClassifications (Soft/Hard), and LimitTargets (User/Global) to form the complete limit definition framework. Together, these five Dictionary tables allow the compliance team to configure sophisticated limit rules.

The table is FK-referenced by `Wallet.LimitationsDefinitions` and consumed by limit configuration stored procedures.

---

## 2. Business Logic

### 2.1 Limit Temporal Scope

**What**: Determines whether a limit is evaluated per-transaction or accumulated over time.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Single` (1): Limit applies to each individual transaction independently. Example: "No single withdrawal may exceed $10,000." Each transaction is checked against the threshold without regard to previous transactions.
- `Periodic` (2): Limit accumulates over a rolling or calendar time period. Example: "Total withdrawals may not exceed $50,000 per month." The system sums all transactions in the period and compares the total (plus the proposed transaction) against the threshold.

**Diagram**:
```
Single (1):   Each TX checked independently
  TX1=$5K [OK]  TX2=$8K [OK]  TX3=$12K [LIMIT if max=$10K]

Periodic (2): Sum of TXs in period checked
  TX1=$5K + TX2=$8K = $13K [OK if period max=$50K]
  ...TX10=$5K -> total=$50K [LIMIT]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Single | Per-transaction scope. Each individual transaction is evaluated against the limit threshold independently. Used for minimum/maximum per-transaction amounts (e.g., "minimum withdrawal is $50"). |
| 2 | Periodic | Cumulative scope over a time window. Transactions are summed within the defined period (daily, weekly, monthly) and the running total is checked against the threshold. Used for velocity limits and periodic caps (e.g., "maximum $50,000 per month"). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the limit scope. Values: 1=Single (per-transaction), 2=Periodic (cumulative over time). FK target for Wallet.LimitationsDefinitions.LimitScopeId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Label for the scope type. Used in limit configuration UIs and compliance dashboards alongside LimitActions, LimitClassifications, LimitTargets, and LimitTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.LimitationsDefinitions | LimitScopeId | FK | Each limit rule defines its temporal scope |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitationsDefinitions | Table | FK on LimitScopeId |
| Wallet.GetLimitationsConfigurations | Stored Procedure | Reads limit configs with scope names |
| Wallet.AddLimitationDefinition | Stored Procedure | Validates scope ID when creating limits |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LimitScopes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all limit scopes
```sql
SELECT Id, Name FROM Dictionary.LimitScopes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Periodic limits with their configurations
```sql
SELECT ld.Id, ls.Name AS Scope, lt.Name AS Type, la.Name AS Action, ld.LimitValue
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitScopes ls WITH (NOLOCK) ON ld.LimitScopeId = ls.Id
JOIN Dictionary.LimitTypes lt WITH (NOLOCK) ON ld.LimitTypeId = lt.Id
JOIN Dictionary.LimitActions la WITH (NOLOCK) ON ld.LimitActionId = la.Id
WHERE ls.Id = 2 -- Periodic
ORDER BY ld.LimitValue DESC
```

### 8.3 Full limit definition with all Dictionary lookups
```sql
SELECT ld.Id, ls.Name AS Scope, lt.Name AS Type, la.Name AS Action,
       lc.Name AS Classification, ltar.Name AS Target, ld.LimitValue
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitScopes ls WITH (NOLOCK) ON ld.LimitScopeId = ls.Id
JOIN Dictionary.LimitTypes lt WITH (NOLOCK) ON ld.LimitTypeId = lt.Id
JOIN Dictionary.LimitActions la WITH (NOLOCK) ON ld.LimitActionId = la.Id
JOIN Dictionary.LimitClassifications lc WITH (NOLOCK) ON ld.LimitClassificationId = lc.Id
JOIN Dictionary.LimitTargets ltar WITH (NOLOCK) ON ld.LimitTargetId = ltar.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.LimitScopes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.LimitScopes.sql*
