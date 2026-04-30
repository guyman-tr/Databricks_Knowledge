# Price.GetPriceAccounts

> View of active price-capable liquidity accounts (excluding execution-only accounts) with an IsAllocated flag indicating whether each account has been assigned to a PCS (Price Calculation Service) instance.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | LiquidityAccountID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetPriceAccounts answers: "Which active liquidity accounts are available for price sourcing, and which ones have already been allocated to a PCS instance?" It filters Trade.LiquidityAccounts to active price-capable accounts (IsActive=1 AND LiquidityAccountTypeID != 2) and LEFT JOINs Price.PCSToLiquidityAccount to mark each with IsAllocated=1 (already assigned to a PCS) or IsAllocated=0 (available but not yet assigned).

The view exists to support pricing configuration operations: tooling that allocates liquidity accounts to PCS instances can query this view to see unallocated accounts (IsAllocated=0) and already-allocated ones. The LiquidityAccountTypeID <> 2 filter excludes pure execution accounts (type 2 = Execution Account) - only accounts that participate in pricing (type 1=Price, type 3=Price+Execution, type 4=OMS IM Pricing) are shown.

Live data shows 5 accounts: simulation accounts 1-4 (IsAllocated=0) and "eToro Custom Price Provider" account 5 (IsAllocated=1 - assigned to a PCS).

---

## 2. Business Logic

### 2.1 Account Type Filter: Price-Capable Only

**What**: LiquidityAccountTypeID <> 2 ensures only price-capable accounts appear - execution-only accounts are excluded.

**Columns/Parameters Involved**: `LiquidityAccountID`, `LiquidityAccountTypeID`

**Rules**:
- LiquidityAccountTypeID=1 (Price Account): included
- LiquidityAccountTypeID=2 (Execution Account): excluded - these accounts route trades, not prices
- LiquidityAccountTypeID=3 (Price and Execution): included
- LiquidityAccountTypeID=4 (OMS IM Pricing): included
- LiquidityAccountTypeID=0 (NONE): included (not explicitly excluded)

### 2.2 IsAllocated Flag via PCSToLiquidityAccount

**What**: LEFT JOIN to PCSToLiquidityAccount determines if the account has been assigned to any PCS instance.

**Columns/Parameters Involved**: `IsAllocated`, `LiquidityAccountID`

**Rules**:
- IsAllocated = CASE ISNULL(PTLA.LiquidityAccountID, -1) WHEN -1 THEN 0 ELSE 1 END
- IsAllocated=1: account appears in PCSToLiquidityAccount (assigned to a PCS instance)
- IsAllocated=0: account NOT in PCSToLiquidityAccount (unallocated - available for assignment)
- LEFT JOIN means unallocated accounts still appear in the result (IsAllocated=0)
- Simulation accounts (1-4) are currently unallocated; eToro Custom Price Provider (5) is allocated

---

## 3. Data Overview

| LiquidityAccountID | LiquidityAccountName | AccountRateSourceID | IsAllocated | Meaning |
|---|---|---|---|---|
| 1 | Simulation Non Stocks | 1 | 0 | Simulation feed for non-stocks. Active but not assigned to any PCS instance - not in current live pricing topology. |
| 2 | Simulation Stocks BATS | 2 | 0 | BATS simulation account. Active but unallocated - available for PCS assignment. |
| 3 | Simulation Stocks DAX | 3 | 0 | DAX simulation account. Unallocated. |
| 4 | Simulation Stocks FTSE | 4 | 0 | FTSE simulation account. Unallocated. |
| 5 | eToro Custom Price Provider | 5 | 1 | eToro's custom pricing feed. IsAllocated=1 - this account is assigned to a PCS instance and actively used for price calculation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | CODE-BACKED | Active liquidity account identifier from Trade.LiquidityAccounts. Only active (IsActive=1) non-execution-only accounts. |
| 2 | LiquidityAccountName | varchar(50) | YES | - | CODE-BACKED | Human-readable account name from Trade.LiquidityAccounts. Examples: "Simulation Non Stocks", "eToro Custom Price Provider", "ZBFX Price1". |
| 3 | AccountRateSourceID | int | YES | - | CODE-BACKED | Rate source assigned to this account from Trade.LiquidityAccounts. FK to Price.AccountRateSource. Identifies the feed type (simulation, ZBFX, Bloomberg, etc.). |
| 4 | IsAllocated | int | NO | - | CODE-BACKED | PCS allocation status: 1=account is assigned to a PCS instance (row exists in PCSToLiquidityAccount), 0=account is not assigned to any PCS. Computed via LEFT JOIN: CASE ISNULL(PTLA.LiquidityAccountID, -1) WHEN -1 THEN 0 ELSE 1 END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID + name + AccountRateSourceID | Trade.LiquidityAccounts | FROM source (IsActive=1, TypeID<>2 filter) | Active price-capable accounts |
| LiquidityAccountID + IsAllocated | Price.PCSToLiquidityAccount | LEFT JOIN | PCS assignment status |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetPriceAccounts (view)
├── Trade.LiquidityAccounts (table)
└── Price.PCSToLiquidityAccount (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FROM (TLA alias) - active (IsActive=1), non-execution (TypeID<>2) accounts |
| Price.PCSToLiquidityAccount | Table | LEFT JOIN on LiquidityAccountID - provides PCS assignment for IsAllocated flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. WHERE IsActive=1 AND LiquidityAccountTypeID <> 2. LEFT JOIN allows unallocated accounts to appear with IsAllocated=0.

---

## 8. Sample Queries

### 8.1 List all unallocated price accounts

```sql
SELECT LiquidityAccountID, LiquidityAccountName, AccountRateSourceID
FROM Price.GetPriceAccounts WITH (NOLOCK)
WHERE IsAllocated = 0
ORDER BY LiquidityAccountID;
```

### 8.2 List allocated accounts with rate source names

```sql
SELECT
    GPA.LiquidityAccountID,
    GPA.LiquidityAccountName,
    ARS.Name AS RateSourceName,
    GPA.IsAllocated
FROM Price.GetPriceAccounts GPA WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = GPA.AccountRateSourceID
WHERE GPA.IsAllocated = 1
ORDER BY GPA.LiquidityAccountID;
```

### 8.3 Count of allocated vs unallocated accounts

```sql
SELECT IsAllocated, COUNT(*) AS AccountCount
FROM Price.GetPriceAccounts WITH (NOLOCK)
GROUP BY IsAllocated;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetPriceAccounts | Type: View | Source: etoro/etoro/Price/Views/Price.GetPriceAccounts.sql*
