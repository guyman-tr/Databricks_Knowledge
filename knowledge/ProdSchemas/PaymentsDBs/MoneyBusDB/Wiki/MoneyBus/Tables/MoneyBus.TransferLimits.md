# MoneyBus.TransferLimits

> Configuration table defining minimum and maximum transfer amounts allowed between account types, with optional filtering by country, player level, flow, and currency.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap) - keyed by combination of DebitAccountTypeID + CreditAccountTypeID + CurrencyID + FlowID |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

MoneyBus.TransferLimits is a configuration/reference table that defines the minimum and maximum monetary amounts allowed for fund transfers between specific account type pairs. It acts as a business rule engine that the application consults before allowing a transfer to proceed - if the requested amount falls outside the configured limits for the given account type combination, currency, and optionally flow/country, the transfer is rejected.

This table exists to enforce financial controls on money movement. Without it, users could transfer any amount between any account types, bypassing compliance limits and risk management thresholds. The limits are configurable per direction (debit-to-credit pair), per currency, and can be further scoped by country, player level, and business flow.

TransferLimitsGet reads all rows at once (no parameters), suggesting the application loads the full configuration into memory at startup or caches it. The application then evaluates the appropriate limit rule in code based on the transaction context.

---

## 2. Business Logic

### 2.1 Multi-Dimensional Limit Rules

**What**: Transfer limits are defined along multiple dimensions, with NULL dimensions acting as wildcards that match any value.

**Columns/Parameters Involved**: `DebitAccountTypeID`, `CreditAccountTypeID`, `CurrencyID`, `CountryID`, `PlayerLevelID`, `FlowID`

**Rules**:
- A limit rule applies to a specific DebitAccountTypeID -> CreditAccountTypeID direction
- CurrencyID is always specified (no wildcard for currency)
- CountryID = NULL means "applies to all countries"
- PlayerLevelID = NULL means "applies to all player levels"
- FlowID = NULL means "applies to all flows" (default limit)
- When FlowID is specified, it represents a more restrictive override for that specific flow

**Diagram**:
```
Transfer Request: Debit=1(Trading) -> Credit=3(IBAN), Currency=1(USD), Flow=2
    |
    v
Limit Lookup (most specific match wins):
    [1] FlowID=2, Debit=1, Credit=3, Currency=1 -> Min=1, Max=50,000  <-- MATCH (specific)
    [2] FlowID=NULL, Debit=1, Credit=3, Currency=1 -> Min=1, Max=100M  <-- also matches (general)
    Result: Max=50,000 (flow-specific limit is more restrictive)
```

### 2.2 Directional Limits

**What**: Limits are defined per direction - Trading->IBAN may have different limits than IBAN->Trading.

**Columns/Parameters Involved**: `DebitAccountTypeID`, `CreditAccountTypeID`

**Rules**:
- DebitAccountTypeID=1 + CreditAccountTypeID=3 (Trading -> IBAN) has different rows than DebitAccountTypeID=3 + CreditAccountTypeID=1 (IBAN -> Trading)
- IBAN -> Trading supports multiple currencies (IDs 2, 3, 5, 46) while Trading -> IBAN is configured for currency 1 only
- This asymmetry reflects that deposits can arrive in multiple currencies but internal transfers use a base currency

---

## 3. Data Overview

| DebitAccountTypeID | CreditAccountTypeID | MinAmount | MaxAmount | CurrencyID | FlowID | Meaning |
|---|---|---|---|---|---|---|
| 1 (Trading) | 2 (Options) | 1 | 100,000,000 | 1 | NULL | Internal transfer from Trading to Options account - high limit, broad default |
| 1 (Trading) | 3 (IBAN) | 1 | 100,000,000 | 1 | NULL | Withdrawal from Trading to bank account - default limit is very high |
| 1 (Trading) | 3 (IBAN) | 1 | 50,000 | 1 | 2 | Same direction but for Flow 2 - significantly lower max ($50K vs $100M), indicating a restricted flow type |
| 3 (IBAN) | 1 (Trading) | 1 | 100,000,000 | 2 | NULL | Deposit from bank to Trading in currency 2 - standard high limit |
| 3 (IBAN) | 1 (Trading) | 1 | 100,000,000 | 46 | NULL | Deposit from bank to Trading in currency 46 - same limit for a less common currency |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | YES | - | CODE-BACKED | Country filter for the limit rule. NULL means the rule applies to all countries. When set, restricts this limit to users in the specified country. Currently all rows have NULL (global rules). |
| 2 | DebitAccountTypeID | int | YES | - | CODE-BACKED | Source account type being debited: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). Defines the "from" side of the transfer direction. |
| 3 | CreditAccountTypeID | int | YES | - | CODE-BACKED | Destination account type being credited: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). Defines the "to" side of the transfer direction. |
| 4 | MinAmount | money | YES | - | CODE-BACKED | Minimum transfer amount allowed in the specified currency. Currently set to 1 for all rules - prevents zero-amount transfers. |
| 5 | MaxAmount | money | YES | - | CODE-BACKED | Maximum transfer amount allowed in the specified currency. Ranges from 50,000 (flow-specific restriction) to 100,000,000 (default). The application rejects transfers exceeding this. |
| 6 | CurrencyID | int | NO | - | CODE-BACKED | Currency the limit applies to. Each currency requires its own limit row because acceptable ranges differ by currency denomination. Maps to an external currency reference. |
| 7 | PlayerLevelID | int | YES | - | NAME-INFERRED | Player/user tier level filter. NULL means the rule applies to all levels. When set, allows different transfer limits for VIP vs. standard users. Currently all rows have NULL (uniform limits). |
| 8 | FlowID | int | YES | - | CODE-BACKED | Business flow identifier. NULL means "default for all flows." When specified (e.g., FlowID=2), applies a more specific limit that overrides the default. One row uses FlowID=2 with a lower MaxAmount, indicating a restricted flow type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DebitAccountTypeID | Dictionary.AccountTypes | Implicit Lookup | Source account type for the transfer |
| CreditAccountTypeID | Dictionary.AccountTypes | Implicit Lookup | Destination account type for the transfer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.TransferLimitsGet | (whole table) | Reader | Reads all limit configuration rows for application-side caching |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.TransferLimitsGet | Stored Procedure | Reader - retrieves full configuration for application caching |

---

## 7. Technical Details

### 7.1 Indexes

This table has no indexes (heap). With only 8 rows, a full table scan is optimal.

### 7.2 Constraints

None. This is a heap table with no PK, no FKs, and no check constraints. Data integrity relies on the application/admin process that populates the configuration.

---

## 8. Sample Queries

### 8.1 Get all limits with resolved account type names
```sql
SELECT tl.*, d.Name AS DebitAccountType, c.Name AS CreditAccountType
FROM MoneyBus.TransferLimits tl WITH (NOLOCK)
LEFT JOIN Dictionary.AccountTypes d WITH (NOLOCK) ON d.ID = tl.DebitAccountTypeID
LEFT JOIN Dictionary.AccountTypes c WITH (NOLOCK) ON c.ID = tl.CreditAccountTypeID
ORDER BY tl.DebitAccountTypeID, tl.CreditAccountTypeID;
```

### 8.2 Find limits for a specific transfer direction
```sql
SELECT MinAmount, MaxAmount, CurrencyID, FlowID
FROM MoneyBus.TransferLimits WITH (NOLOCK)
WHERE DebitAccountTypeID = 1 AND CreditAccountTypeID = 3
ORDER BY FlowID;
```

### 8.3 Find flow-specific overrides (non-default limits)
```sql
SELECT tl.*, d.Name AS DebitType, c.Name AS CreditType
FROM MoneyBus.TransferLimits tl WITH (NOLOCK)
LEFT JOIN Dictionary.AccountTypes d WITH (NOLOCK) ON d.ID = tl.DebitAccountTypeID
LEFT JOIN Dictionary.AccountTypes c WITH (NOLOCK) ON c.ID = tl.CreditAccountTypeID
WHERE tl.FlowID IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 8.75/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransferLimits | Type: Table | Source: MoneyBusDB/MoneyBus/Tables/MoneyBus.TransferLimits.sql*
