# Wallet.LimitationsDefinitions

> Configuration table defining transaction amount limits per cryptocurrency, transaction type, and scope - controlling minimum/maximum thresholds that trigger enforcement or alerting for wallet operations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + FK indexes on multiple dimension columns |

---

## 1. Business Meaning

This table is the central configuration store for all transaction amount limits enforced by the wallet platform. Each row defines a single limit rule combining a cryptocurrency, transaction type, scope (single transaction vs. periodic aggregate), and threshold direction (minimum or maximum). With 240 rows, the table represents a rich matrix of business rules that govern what transaction amounts are permitted for each user and globally.

Limits serve multiple compliance and risk purposes. Minimum limits prevent dust transactions that would be uneconomical to process on-chain. Maximum limits cap single transactions or periodic rolling totals to contain exposure to fraud, money laundering, or operational risk. Hard limits block the transaction entirely; soft limits allow the operation but trigger an alert for review. The `LimitClassificationId` column distinguishes these two enforcement modes.

The `DefinitionJson` column stores the full structured definition consumed by the limits evaluation service. When a new transaction request arrives, the service queries this table (filtering by `CryptoId`, `TransactionTypeId`, `LimitScopeId`, and `IsActive=1`) to determine which rules apply, then evaluates each rule against the request amount. Violations are recorded in `Wallet.LimitExceeds`. Operations teams manage this table to tune risk thresholds without requiring code deployments.

---

## 2. Business Logic

### 2.1 Limit Classification (Hard vs Soft)

**What**: Determines whether a limit violation blocks the transaction or only triggers an alert.

**Columns/Parameters Involved**: `LimitClassificationId`, `LimitActionId`

**Rules**:
- LimitClassificationId=1 (Soft): Limit breach is logged and may trigger an alert but the transaction proceeds
- LimitClassificationId=2 (Hard): Limit breach blocks the transaction; the request is rejected
- LimitActionId=1 (Enforce): The limit is actively evaluated and applied
- LimitActionId=2 (Alert): The limit generates an alert only, regardless of classification
- Rows with `IsActive=0` are historical configurations that are no longer evaluated

### 2.2 Scope: Single vs Periodic Limits

**What**: Limits can apply to a single transaction amount or to the rolling aggregate over a time period.

**Columns/Parameters Involved**: `LimitScopeId`, `LimitTypeId`, `LimitTargetId`

**Rules**:
- LimitScopeId=1 (Single): The limit applies to the individual transaction amount
- LimitScopeId=2 (Periodic): The limit applies to the sum of transactions over a rolling window (period defined in `DefinitionJson`)
- LimitTypeId=1 (Min): The amount must be at or above this threshold
- LimitTypeId=2 (Max): The amount must be at or below this threshold
- LimitTargetId=1 (User): The limit is evaluated per individual customer
- LimitTargetId=2 (Global): The limit is evaluated across all users (platform-wide aggregate)

### 2.3 Crypto Category Grouping

**What**: Limits can be defined for a specific crypto or a named category of cryptos.

**Columns/Parameters Involved**: `CryptoId`, `CryptoCategoryName`

**Rules**:
- When `CryptoId` is set, the rule applies to that specific cryptocurrency only
- When `CryptoCategoryName` is set, the rule applies to all cryptos in that named category (e.g., "Stablecoins", "Layer2")
- The limits service resolves the applicable rules by joining on CryptoId or matching the CryptoCategoryName of the requested asset

---

## 3. Data Overview

| Id | CryptoId | TransactionTypeId | LimitClassificationId | LimitTypeId | LimitScopeId | IsActive | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | 1 (BTC) | 2 (Send) | 2 (Hard) | 2 (Max) | 1 (Single) | 1 | Maximum single BTC send amount - hard limit that blocks oversized transactions |
| 15 | 3 (ETH) | 2 (Send) | 1 (Soft) | 2 (Max) | 2 (Periodic) | 1 | Periodic ETH send ceiling - soft limit that alerts on large rolling send volumes |
| 42 | NULL | 4 (Receive) | 2 (Hard) | 1 (Min) | 1 (Single) | 1 | Global minimum receive amount for all cryptos - rejects dust deposits |
| 78 | 5 (XRP) | 1 (Buy) | 1 (Soft) | 2 (Max) | 2 (Periodic) | 0 | Retired XRP periodic buy limit - superseded by a category-level rule |
| 120 | NULL | 2 (Send) | 2 (Hard) | 2 (Max) | 1 (Single) | 1 | Category-level max single send for stablecoins (CryptoCategoryName populated) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Referenced by LimitExceeds when recording which rule was breached. |
| 2 | DefinitionJson | nvarchar(max) | YES | - | CODE-BACKED | Full structured definition of the limit rule consumed by the evaluation service. Contains threshold values, period windows, and any additional rule parameters not captured in scalar columns. |
| 3 | LastChanged | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp of the most recent modification to this limit definition. Tracks when operations last adjusted this rule. |
| 4 | LastChangedBy | nvarchar(max) | YES | - | CODE-BACKED | Identity (username or service account) that last modified this row. Provides an audit trail for limit configuration changes. |
| 5 | IsActive | bit | YES | - | VERIFIED | 1=limit rule is currently evaluated; 0=retired/deactivated. Only active rules are applied during transaction validation. |
| 6 | LimitClassificationId | tinyint | NO | - | VERIFIED | Enforcement mode: 1=Soft (alert only), 2=Hard (block transaction). FK to Dict.LimitClassifications. |
| 7 | LimitTypeId | tinyint | NO | - | VERIFIED | Threshold direction: 1=Min (amount must be >= threshold), 2=Max (amount must be <= threshold). FK to Dict.LimitTypes. |
| 8 | LimitTargetId | tinyint | NO | - | VERIFIED | Evaluation scope target: 1=User (per customer), 2=Global (platform-wide). FK to Dict.LimitTargets. |
| 9 | TransactionTypeId | tinyint | NO | - | VERIFIED | The transaction type this limit governs. FK to Dict.TransactionTypes (e.g., Send, Receive, Buy). |
| 10 | CryptoId | int | YES | - | VERIFIED | Specific cryptocurrency this rule applies to. NULL when rule is defined at category level (see CryptoCategoryName). FK to Wallet.CryptoTypes. |
| 11 | CryptoCategoryName | nvarchar(max) | YES | - | CODE-BACKED | Named category of cryptocurrencies this rule applies to (e.g., "Stablecoins"). Used when the rule covers a group rather than a single asset. Mutually exclusive with CryptoId per convention. |
| 12 | LimitScopeId | tinyint | NO | - | VERIFIED | Aggregation scope: 1=Single (applies to individual transaction), 2=Periodic (applies to rolling sum over a time window). FK to Dict.LimitScopes. |
| 13 | LimitActionId | tinyint | NO | - | VERIFIED | Action taken on breach: 1=Enforce (apply the limit), 2=Alert (notify only). FK to Dict.LimitActions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LimitClassificationId | Dict.LimitClassifications | FK | Soft vs Hard enforcement mode |
| LimitTypeId | Dict.LimitTypes | FK | Min vs Max threshold direction |
| LimitTargetId | Dict.LimitTargets | FK | User vs Global evaluation scope |
| TransactionTypeId | Dict.TransactionTypes | FK | Transaction category the limit governs |
| CryptoId | Wallet.CryptoTypes | FK | Specific cryptocurrency (nullable) |
| LimitScopeId | Dict.LimitScopes | FK | Single vs Periodic aggregation |
| LimitActionId | Dict.LimitActions | FK | Enforce vs Alert action |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.LimitExceeds | (implicit via LimitClassificationId/TransactionTypeId) | Implicit | Records which limit rules were breached by transactions |

---

## 6. Dependencies

### 6.0 Dependency Chain

Dict.LimitClassifications → Wallet.LimitationsDefinitions
Dict.LimitTypes → Wallet.LimitationsDefinitions
Dict.LimitTargets → Wallet.LimitationsDefinitions
Dict.TransactionTypes → Wallet.LimitationsDefinitions
Wallet.CryptoTypes → Wallet.LimitationsDefinitions
Dict.LimitScopes → Wallet.LimitationsDefinitions
Dict.LimitActions → Wallet.LimitationsDefinitions

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dict.LimitClassifications | Table | FK target - Soft/Hard classification lookup |
| Dict.LimitTypes | Table | FK target - Min/Max direction lookup |
| Dict.LimitTargets | Table | FK target - User/Global target lookup |
| Dict.TransactionTypes | Table | FK target - transaction category lookup |
| Wallet.CryptoTypes | Table | FK target - cryptocurrency lookup |
| Dict.LimitScopes | Table | FK target - Single/Periodic scope lookup |
| Dict.LimitActions | Table | FK target - Enforce/Alert action lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitExceeds | Table | Records violations against limit rules defined here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LimitationsDefinitions | CLUSTERED PK | Id ASC | - | - | Active |
| FK index on LimitClassificationId | NC | LimitClassificationId ASC | - | - | Active |
| FK index on LimitTypeId | NC | LimitTypeId ASC | - | - | Active |
| FK index on LimitTargetId | NC | LimitTargetId ASC | - | - | Active |
| FK index on TransactionTypeId | NC | TransactionTypeId ASC | - | - | Active |
| FK index on CryptoId | NC | CryptoId ASC | - | - | Active |
| FK index on LimitScopeId | NC | LimitScopeId ASC | - | - | Active |
| FK index on LimitActionId | NC | LimitActionId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_LimitationsDefinitions_LimitClassificationId | FK | LimitClassificationId -> Dict.LimitClassifications.Id |
| FK_LimitationsDefinitions_LimitTypeId | FK | LimitTypeId -> Dict.LimitTypes.Id |
| FK_LimitationsDefinitions_LimitTargetId | FK | LimitTargetId -> Dict.LimitTargets.Id |
| FK_LimitationsDefinitions_TransactionTypeId | FK | TransactionTypeId -> Dict.TransactionTypes.Id |
| FK_LimitationsDefinitions_CryptoId | FK | CryptoId -> Wallet.CryptoTypes.Id |
| FK_LimitationsDefinitions_LimitScopeId | FK | LimitScopeId -> Dict.LimitScopes.Id |
| FK_LimitationsDefinitions_LimitActionId | FK | LimitActionId -> Dict.LimitActions.Id |

---

## 8. Sample Queries

### 8.1 All active hard limits for a specific crypto and transaction type
```sql
SELECT ld.Id, ld.LimitTypeId, ld.LimitScopeId, ld.LimitTargetId,
       ld.LimitActionId, ld.DefinitionJson
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
WHERE ld.CryptoId = 1            -- BTC
  AND ld.TransactionTypeId = 2   -- Send
  AND ld.LimitClassificationId = 2  -- Hard
  AND ld.IsActive = 1
ORDER BY ld.LimitScopeId, ld.LimitTypeId
```

### 8.2 Summary of active limits by crypto and classification
```sql
SELECT ld.CryptoId, ld.LimitClassificationId,
       COUNT(*) AS RuleCount
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
WHERE ld.IsActive = 1
GROUP BY ld.CryptoId, ld.LimitClassificationId
ORDER BY ld.CryptoId, ld.LimitClassificationId
```

### 8.3 Recently modified limit definitions
```sql
SELECT ld.Id, ld.CryptoId, ld.TransactionTypeId, ld.LimitClassificationId,
       ld.LastChanged, ld.LastChangedBy
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
WHERE ld.LastChanged >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY ld.LastChanged DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.LimitationsDefinitions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.LimitationsDefinitions.sql*
