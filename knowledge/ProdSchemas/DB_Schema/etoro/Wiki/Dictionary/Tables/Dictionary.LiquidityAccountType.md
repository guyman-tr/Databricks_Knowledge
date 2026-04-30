# Dictionary.LiquidityAccountType

> Lookup table defining five liquidity account types — None, Price, Execution, combined Price+Execution, and OMS IM Pricing — classifying the role each liquidity provider account plays in the price sourcing and trade execution pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LiquidityAccountTypeID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.LiquidityAccountType classifies the functional role of each liquidity provider account in eToro's trading infrastructure. eToro connects to multiple liquidity providers (banks, brokers, exchanges), and each connection can serve different purposes: providing market prices (Price Account), executing hedge orders (Execution Account), or both. A separate category exists for OMS (Order Management System) pricing used in internal margin calculations.

This table exists because the same liquidity provider may have multiple accounts serving different functions. For example, a bank might provide real-time price feeds through one account (Price Account) and accept trade execution through another (Execution Account). Some providers offer both through a single combined account (Price and Execution Account). The account type determines how the system routes data and orders.

The LiquidityAccountTypeID is stored in Trade.LiquidityAccounts and consumed by hedge procedures (Hedge.GetActiveAccountByProviderAndAccountType, Hedge.GetActiveLiquidityAccounts, Hedge.GetHedgeSupportedInstruments, Hedge.SyncLiquidityAccounts), price procedures (Price.GetPriceAccounts, Price.CleanUnmappedInstrumentRateSources), and monitoring (Monitor.CheckOutOfSyncLiquidityProviders).

---

## 2. Business Logic

### 2.1 Account Role Separation

**What**: Five types separate pricing, execution, and combined roles in the liquidity infrastructure.

**Columns/Parameters Involved**: `LiquidityAccountTypeID`, `Name`

**Rules**:
- **NONE (0)**: Default/unclassified. The account has no assigned role — likely a placeholder or newly created account awaiting configuration.
- **Price Account (1)**: Receives real-time market price feeds from the liquidity provider. Used by the pricing engine to calculate bid/ask spreads shown to customers. Does NOT accept trade execution.
- **Execution Account (2)**: Accepts trade execution orders for hedging. Used by the hedge server to open/close hedge positions. Does NOT provide price feeds.
- **Price and Execution Account (3)**: Combined role — provides both price feeds AND accepts execution orders. Simplifies the setup for providers that support both functions through a single connection.
- **OMS IM Pricing Account (4)**: Specialized pricing account for the Order Management System's Internal Market (IM) pricing calculations. Used for internal margin calculations and position valuation, separate from the customer-facing price feed.
- The account type determines which system components connect to each account: pricing engine reads from type 1/3/4, hedge server writes to type 2/3.

**Diagram**:
```
Liquidity Account Types:
┌─────────────────────────────────────────────────┐
│  Market Data (Price Feeds)   │  Trade Execution │
│                              │                  │
│  Price Account (1) ──────►  Pricing Engine     │
│                              │                  │
│  Execution Account (2)       │ ◄──── Hedge     │
│                              │       Server     │
│  Price+Exec Account (3) ──►  Both ◄────┘       │
│                              │                  │
│  OMS IM Pricing (4) ──────► Internal Margin    │
│                              │   Calculations    │
│                              │                  │
│  NONE (0)                    │   (Unassigned)   │
└─────────────────────────────────────────────────┘
```

---

## 3. Data Overview

| LiquidityAccountTypeID | Name | Meaning |
|---|---|---|
| 0 | NONE | Unassigned account type. The liquidity account has been created but not yet configured with a functional role. Should not appear in active production accounts — indicates setup is incomplete. |
| 1 | Price Account | Dedicated pricing account that receives real-time market price feeds from the LP. The pricing engine consumes these feeds to calculate bid/ask spreads. This account CANNOT execute trades. |
| 2 | Execution Account | Dedicated execution account for sending hedge trade orders to the LP. The hedge server uses this to open/close positions. This account does NOT provide price feeds. |
| 3 | Price and Execution Account | Dual-purpose account providing both price feeds AND trade execution through a single connection. Reduces infrastructure complexity for LPs that support both functions. |
| 4 | OMS IM Pricing Account | Specialized pricing for the Order Management System's internal margin calculations. Provides pricing data used for position valuation and margin requirements, separate from the customer-facing price engine. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountTypeID | int | NO | - | VERIFIED | Primary key identifying the account type role. 0=NONE (unassigned), 1=Price Account (pricing only), 2=Execution Account (trading only), 3=Price and Execution (both), 4=OMS IM Pricing (internal margin). Stored in Trade.LiquidityAccounts and referenced by hedge, price, and monitoring procedures. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable description of the account role. Displayed in hedge server configuration, liquidity account management screens, and monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityAccounts | LiquidityAccountTypeID | Implicit FK | Classifies each LP account's role |
| Hedge.GetActiveAccountByProviderAndAccountType | LiquidityAccountTypeID | Parameter | Finds active accounts by provider and type |
| Hedge.GetActiveLiquidityAccounts | LiquidityAccountTypeID | Lookup | Lists active accounts with type resolution |
| Hedge.GetHedgeSupportedInstruments | LiquidityAccountTypeID | Lookup | Identifies instruments supported on execution accounts |
| Hedge.GetAccountSupportedInstruments | LiquidityAccountTypeID | Lookup | Lists instruments per account type |
| Hedge.SyncLiquidityAccounts | LiquidityAccountTypeID | Lookup | Synchronizes account configurations |
| Price.GetPriceAccounts | LiquidityAccountTypeID | Lookup | Lists pricing accounts for the price engine |
| Price.CleanUnmappedInstrumentRateSources | LiquidityAccountTypeID | Lookup | Cleans up orphaned price source mappings |
| Monitor.CheckOutOfSyncLiquidityProviders | LiquidityAccountTypeID | Lookup | Monitors LP account synchronization |
| Trade.SetNextLiquidityAccountID | LiquidityAccountTypeID | Lookup | Assigns next available account ID |
| Trade.GetLiquidityAccounts | LiquidityAccountTypeID | Lookup | View resolving account types |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | Stores account type per LP account |
| Hedge.GetActiveAccountByProviderAndAccountType | Stored Procedure | Reads — finds accounts by type |
| Hedge.GetActiveLiquidityAccounts | Stored Procedure | Reads — lists active accounts |
| Hedge.GetHedgeSupportedInstruments | Stored Procedure | Reads — instrument-to-account mapping |
| Price.GetPriceAccounts | View | Reads — lists pricing accounts |
| Monitor.CheckOutOfSyncLiquidityProviders | Stored Procedure | Reads — LP sync monitoring |
| Trade.GetLiquidityAccounts | View | Reads — account listing with types |
| History.LiquidityAccounts | Table | Historical tracking of account changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | LiquidityAccountTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PRIMARY KEY | Unique account type identifier |

---

## 8. Sample Queries

### 8.1 List all liquidity account types
```sql
SELECT  LiquidityAccountTypeID,
        Name
FROM    [Dictionary].[LiquidityAccountType] WITH (NOLOCK)
ORDER BY LiquidityAccountTypeID;
```

### 8.2 Join to active liquidity accounts
```sql
SELECT  la.LiquidityAccountID,
        la.AccountName,
        lat.Name AS AccountType,
        la.IsActive
FROM    [Trade].[LiquidityAccounts] la WITH (NOLOCK)
JOIN    [Dictionary].[LiquidityAccountType] lat WITH (NOLOCK)
        ON la.LiquidityAccountTypeID = lat.LiquidityAccountTypeID
WHERE   la.IsActive = 1
ORDER BY lat.LiquidityAccountTypeID, la.AccountName;
```

### 8.3 Count active accounts by type
```sql
SELECT  lat.Name AS AccountType,
        COUNT(*) AS ActiveAccountCount
FROM    [Trade].[LiquidityAccounts] la WITH (NOLOCK)
JOIN    [Dictionary].[LiquidityAccountType] lat WITH (NOLOCK)
        ON la.LiquidityAccountTypeID = lat.LiquidityAccountTypeID
WHERE   la.IsActive = 1
GROUP BY lat.Name
ORDER BY ActiveAccountCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.LiquidityAccountType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.LiquidityAccountType.sql*
