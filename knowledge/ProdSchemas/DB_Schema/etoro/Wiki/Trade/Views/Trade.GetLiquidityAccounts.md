# Trade.GetLiquidityAccounts

> View of active liquidity provider accounts with rate source names, joining LiquidityAccounts and Price.AccountRateSource. Contains credential columns (Username, Password) - restrict access and anonymize in documentation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | LiquidityAccountID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLiquidityAccounts exposes **active** liquidity provider accounts (IsActive=1) with their rate source names resolved from Price.AccountRateSource. Each row is a liquidity account (login credentials for an external broker) tied to a provider instance, used by the price subsystem for rate feeds and by the hedge subsystem for execution routing. The view filters out inactive accounts so consumers see only accounts currently in use.

This view exists because Trade.GetInstrumentRateSource, Trade.GetLiquidityAccountsDetails, Hedge.GetHedgeServersDetails, and Price.GetAccountRateSourceMapping need a filtered, enriched list of liquidity accounts with human-readable rate source names. Without it, each would JOIN Trade.LiquidityAccounts and Price.AccountRateSource separately and apply IsActive=1. The view centralizes that logic. **Security note**: The view exposes Username and Password - access should be restricted to authorized roles (ERMUser, NBBOUser, HPHUser have SELECT). Anonymize credentials when displaying sample data.

Data flows from Trade.LiquidityAccounts and Price.AccountRateSource. Rows are filtered WHERE IsActive = 1. The view is read by Trade.GetLiquidityAccountsDetails, Trade.GetInstrumentRateSources, Hedge.GetHedgeServersDetails, and Price.GetAccountRateSourceMapping.

---

## 2. Business Logic

### 2.1 Active Accounts Only

**What**: The view returns only accounts with IsActive=1. Inactive accounts are excluded from price and hedge routing.

**Columns/Parameters Involved**: `IsActive`

**Rules**:
- IsActive=1: Account is in use for price feeds and/or execution.
- IsActive=0: Account disabled; not returned by this view.

### 2.2 Account Rate Source Resolution

**What**: AccountRateSourceID is resolved to AccountRateSourceName via JOIN to Price.AccountRateSource.

**Columns/Parameters Involved**: `AccountRateSourceID`, `AccountRateSourceName`

**Rules**:
- AccountRateSourceName provides human-readable label for the rate source (e.g., "Simulation Non Stocks", "eToro Custom Price Provider").
- AccountRateSourceID=0 means "Do not use!"; -1 means "US" (execution routing).

---

## 3. Data Overview

| LiquidityAccountID | LiquidityAccountName | LiquidityProviderID | AccountRateSourceName | Meaning |
|--------------------|---------------------|---------------------|------------------------|---------|
| 1 | Simulation Non Stocks | 4 | Simulation Non Stocks | FD provider simulation account for non-stock pricing. Price-only. |
| 2 | Simulation Stocks BATS | 4 | Simulation Stocks BATS | FD simulation for BATS-listed stocks. |
| 3 | Simulation Stocks DAX | 4 | Simulation Stocks DAX | FD simulation for DAX-listed stocks. |
| 4 | Simulation Stocks FTSE | 4 | Simulation Stocks FTSE | FD simulation for FTSE-listed stocks. |
| 5 | eToro Custom Price Provider | 2 | eToro Custom Price Provider | FXCM Real provider - custom pricing. Price-only account. |

**Selection criteria**: First 5 active accounts. Mix of simulation and production. Username/Password omitted in display (anonymized per security guidance).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | CODE-BACKED | Primary key from Trade.LiquidityAccounts. Allocated by Trade.SetNextLiquidityAccountID. Referenced by Price.InstrumentRateSources, Hedge.ExecutionLog. |
| 2 | LiquidityAccountName | varchar(50) | YES | - | CODE-BACKED | Human-readable account name (e.g., Simulation Non Stocks, eToro Custom Price Provider). From Trade.LiquidityAccounts. |
| 3 | LiquidityProviderID | int | YES | - | CODE-BACKED | FK to Trade.LiquidityProviders. Links account to provider instance (e.g., FXCM Real=2, FD=4). From Trade.LiquidityAccounts. |
| 4 | Username | varchar(50) | YES | - | CODE-BACKED | Login username for the external broker. **SENSITIVE** - restrict access, anonymize in docs. From Trade.LiquidityAccounts. |
| 5 | Password | varchar(50) | YES | - | CODE-BACKED | Login password for the external broker. **SENSITIVE** - restrict access, anonymize in docs. Audited on INSERT/UPDATE/DELETE. From Trade.LiquidityAccounts. |
| 6 | SettingsXML | xml | YES | - | CODE-BACKED | Account-specific XML settings (FIX sessions, connection params). From Trade.LiquidityAccounts. |
| 7 | LiquidityAccountTypeID | int | NO | 1 | CODE-BACKED | FK to Dictionary.LiquidityAccountType. 0=NONE, 1=Price Account, 2=Execution Account, 3=Price and Execution, 4=OMS IM Pricing. From Trade.LiquidityAccounts. |
| 8 | AccountRateSourceID | int | YES | - | CODE-BACKED | FK to Price.AccountRateSource. Maps account to price feed. 0="Do not use!", -1="US". From Trade.LiquidityAccounts. |
| 9 | AccountRateSourceName | varchar(250) | - | - | CODE-BACKED | Resolved from Price.AccountRateSource.Name via JOIN. Human-readable rate source label (e.g., "Simulation Non Stocks"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderID | Trade.LiquidityProviders | FK | Each account links to a provider instance. |
| LiquidityAccountTypeID | Dictionary.LiquidityAccountType | FK | Classifies account role (Price, Execution, or both). |
| AccountRateSourceID | Price.AccountRateSource | FK | Maps account to price feed for rate allocation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetLiquidityAccountsDetails | FROM | JOIN | View extends GetLiquidityAccounts with provider details. |
| Trade.GetInstrumentRateSources | LEFT JOIN | JOIN | Instrument rate source mapping. |
| Hedge.GetHedgeServersDetails | LEFT JOIN | JOIN | Hedge server details with account info. |
| Price.GetAccountRateSourceMapping | JOIN | JOIN | Account-to-rate-source mapping. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLiquidityAccounts (view)
├── Trade.LiquidityAccounts (table)
└── Price.AccountRateSource (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FROM - base table with WHERE IsActive=1 |
| Price.AccountRateSource | Table | INNER JOIN on AccountRateSourceID for AccountRateSourceName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLiquidityAccountsDetails | View | FROM Trade.GetLiquidityAccounts |
| Trade.GetInstrumentRateSources | View | LEFT JOIN Trade.GetLiquidityAccounts |
| Hedge.GetHedgeServersDetails | View | LEFT JOIN Trade.GetLiquidityAccounts |
| Price.GetAccountRateSourceMapping | View | JOIN Trade.GetLiquidityAccounts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List active accounts with rate source names
```sql
SELECT LiquidityAccountID, LiquidityAccountName, LiquidityProviderID,
       AccountRateSourceID, AccountRateSourceName
  FROM Trade.GetLiquidityAccounts WITH (NOLOCK)
 ORDER BY LiquidityProviderID, LiquidityAccountID
```

### 8.2 Count accounts per provider
```sql
SELECT LiquidityProviderID,
       COUNT(*) AS AccountCount
  FROM Trade.GetLiquidityAccounts WITH (NOLOCK)
 GROUP BY LiquidityProviderID
 ORDER BY AccountCount DESC
```

### 8.3 Resolve account to provider name (avoid credential columns)
```sql
SELECT GLA.LiquidityAccountID, GLA.LiquidityAccountName,
       LP.LiquidityProviderName, GLA.AccountRateSourceName
  FROM Trade.GetLiquidityAccounts GLA WITH (NOLOCK)
  JOIN Trade.LiquidityProviders LP WITH (NOLOCK)
    ON LP.LiquidityProviderID = GLA.LiquidityProviderID
 ORDER BY GLA.LiquidityAccountID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: N/A | App Code: N/A | Corrections: 0 applied*
*Object: Trade.GetLiquidityAccounts | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetLiquidityAccounts.sql*
