# Dictionary.InitTokenStatuses

> Lookup table defining the outcomes of ERC-20 token initialization on a blockchain address, tracking whether token support was newly created or already existed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table tracks the result of initializing ERC-20 token support on a customer's wallet address. Before a customer can receive an ERC-20 token, the system may need to perform initialization steps (e.g., registering the token contract address or creating a trust line). This table records whether the initialization succeeded, found an existing configuration, or failed.

Token initialization is a prerequisite for receiving ERC-20 tokens. The system checks whether a wallet address has already been initialized for a specific token, and this status table records the outcome of each initialization attempt.

---

## 2. Business Logic

### 2.1 Token Initialization Outcomes

**What**: Three possible results of a token initialization attempt.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Initiated` (1): Token initialization was newly created. The system successfully registered the token for the first time on this address.
- `FoundExisted` (2): Token was already initialized on this address. No action needed - the address can already receive this token.
- `Failed` (3): Token initialization failed. The address cannot receive this token until initialization is retried and succeeds.

**Diagram**:
```
Token Init Request
    |
    +---> Already initialized? --YES--> FoundExisted (2)
    |
    +---> Attempt init --SUCCESS--> Initiated (1)
    |
    +---> Attempt init --FAILURE--> Failed (3)
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Initiated | Token support was newly initialized on the address. The system created the necessary on-chain or off-chain configuration for this token on this address. The address can now receive this token type. |
| 2 | FoundExisted | Token support was already present on the address. No initialization was needed. This is an idempotency check - the system detected the token was already configured and skipped initialization. |
| 3 | Failed | Token initialization failed. Possible causes: blockchain error, gas insufficient for the init transaction, or provider API failure. The address cannot receive this token until initialization is retried. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the init status. Values: 1=Initiated, 2=FoundExisted, 3=Failed. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Human-readable label for the initialization outcome. Used in operational monitoring and retry logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK references found in the Wallet schema.

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in the Wallet schema SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InitTokenStatuses | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all init token statuses
```sql
SELECT Id, Name FROM Dictionary.InitTokenStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Resolve status ID to name
```sql
SELECT Name FROM Dictionary.InitTokenStatuses WITH (NOLOCK) WHERE Id = 3 -- Failed
```

### 8.3 All statuses with action guidance
```sql
SELECT Id, Name,
  CASE Id WHEN 1 THEN 'New init - ready' WHEN 2 THEN 'Already ready' WHEN 3 THEN 'Retry needed' END AS Action
FROM Dictionary.InitTokenStatuses WITH (NOLOCK) ORDER BY Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.InitTokenStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.InitTokenStatuses.sql*
