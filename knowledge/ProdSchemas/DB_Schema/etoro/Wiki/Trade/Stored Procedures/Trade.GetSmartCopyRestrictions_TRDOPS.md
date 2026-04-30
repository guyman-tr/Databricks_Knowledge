# Trade.GetSmartCopyRestrictions_TRDOPS

> Trading operations extended variant of Trade.GetSmartCopyRestrictions - adds AccountTypeID and AccountType dimension to the output. No parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the extended version of `Trade.GetSmartCopyRestrictions` for the **TRDOPS** (Trading Operations) team. It adds the `AccountTypeID` and `AccountType` columns to the output, enabling operations staff to see whether a restriction is scoped to a specific account type (e.g., professional accounts vs. retail accounts).

All other behavior is identical to the base procedure. See `Trade.GetSmartCopyRestrictions.md` for full business context, restriction semantics, and dimension explanations.

**Additional column vs. base procedure**:
- `AccountTypeID` from Trade.CopyTradeSettlementRestrictions (NULL if restriction applies to all account types)
- `AccountType` resolved from Dictionary.AccountType (AccountTypeName)

---

## 2. Business Logic

See `Trade.GetSmartCopyRestrictions` - logic is identical except for the additional account type dimension.

### 2.1 Account Type Scoping

**What**: Restrictions can optionally be scoped to a specific account type.

**Columns/Parameters Involved**: `AccountTypeID`, `AccountType`

**Rules**:
- LEFT JOIN Dictionary.AccountType ON restriction.AccountTypeID = accountType.AccountTypeID
- NULL AccountTypeID -> restriction applies to all account types -> AccountType column is NULL
- Non-NULL AccountTypeID -> restriction is narrowed to specific account type (e.g., professional, retail, institutional)
- Useful for ESMA-style rules where professional clients have different access than retail

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** - identical to Trade.GetSmartCopyRestrictions plus:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-17 | (same as GetSmartCopyRestrictions) | - | - | - | CODE-BACKED | See Trade.GetSmartCopyRestrictions.md for full column descriptions. |
| 18 | AccountTypeID | INT | YES | - | CODE-BACKED | Account type this restriction targets. NULL = applies to all account types. FK to Dictionary.AccountType. Useful for professional vs. retail differentiation. |
| 19 | AccountType | VARCHAR | YES | - | CODE-BACKED | Account type name. From Dictionary.AccountType.AccountTypeName. NULL if AccountTypeID is NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as `Trade.GetSmartCopyRestrictions`, plus:

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountTypeID / AccountType | Dictionary.AccountType | Reader (LEFT JOIN, cross-schema) | Resolves account type name for scoped restrictions |

(All other references same as base procedure - see Trade.GetSmartCopyRestrictions.md)

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading operations team | (none) | Application call | Extended restriction matrix view with account type dimension |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetSmartCopyRestrictions_TRDOPS (procedure)
+-- Trade.CopyTradeSettlementRestrictions (table)
+-- Trade.InstrumentMetaData (table)
+-- Dictionary.Country (cross-schema)
+-- Dictionary.Regulation (cross-schema)
+-- Dictionary.AccountType (cross-schema) [ADDITIONAL vs base]
+-- Dictionary.CurrencyType (cross-schema)
+-- Dictionary.ExchangeInfo (cross-schema)
+-- Dictionary.RestrictionType (cross-schema)
+-- Dictionary.BlockUnBlockReason (cross-schema)
+-- Dictionary.TradingInstrumentGroups (cross-schema)
```

### 6.1 Objects This Depends On

Same as `Trade.GetSmartCopyRestrictions`, plus:

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AccountType | Table (Dictionary schema) | LEFT JOIN on AccountTypeID for AccountTypeName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TRDOPS tooling | External application | Extended restriction matrix with account type dimension for ops team |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Same as `Trade.GetSmartCopyRestrictions`. Additionally: LEFT JOIN Dictionary.AccountType is nullable - restrictions without an account type scope are not excluded.

---

## 8. Sample Queries

### 8.1 Get all copy-trade restrictions with account type

```sql
EXEC Trade.GetSmartCopyRestrictions_TRDOPS;
```

### 8.2 View restrictions scoped to specific account types only

```sql
-- Run procedure and filter in application, or use inline query:
SELECT restriction.AccountTypeID, accountType.AccountTypeName, COUNT(*) AS RestrictionCount
FROM Trade.CopyTradeSettlementRestrictions restriction WITH(NOLOCK)
LEFT JOIN Dictionary.AccountType accountType WITH(NOLOCK) ON restriction.AccountTypeID = accountType.AccountTypeID
GROUP BY restriction.AccountTypeID, accountType.AccountTypeName
ORDER BY RestrictionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

See `Trade.GetSmartCopyRestrictions` - no additional Atlassian sources found.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetSmartCopyRestrictions_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetSmartCopyRestrictions_TRDOPS.sql*
