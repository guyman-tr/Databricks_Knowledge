# Hedge.GetActiveProviderLiquidityAccounts

> Returns all active liquidity provider accounts with their hedge server assignments, LP type, account details. 11 rows. Joins Hedge.Accounts, Trade.LiquidityProviderType, and Hedge.HedgeServerToLiquidityAccount, filtered to IsActive=1.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | View |
| **Row Count** | 11 (all active LP accounts) |

---

## 1. Business Meaning

Hedge.GetActiveProviderLiquidityAccounts is the primary read surface for the hedge system to discover which LP accounts are active and which hedge server manages each. It is the startup/initialization query that hedge servers use to know their LP account assignments.

The view combines:
- **Who** the LP accounts are (name, type, username) from Hedge.Accounts
- **What kind** of LP they are (provider name, type ID) from Trade.LiquidityProviderType
- **Which hedge server** manages each account and any alternate rates account from Hedge.HedgeServerToLiquidityAccount

Filtering to IsActive=1 ensures only live, operational accounts are returned - deactivated/historical accounts are excluded.

The 11 active accounts span multiple LP types:
- **ZBFX**: 3 accounts (servers 1, 2, 1100) - the primary FX execution LP
- **OMS**: 3 accounts (servers 8, 9, 222) - internal OMS routing (IM pricing, DMA Virtu, DMA Marex)
- **APEX/TRAFIX**: 1 account (server 3) - UAT fractional execution
- **Talos**: 1 account (server 10) - crypto/digital asset LP
- **MarketMaker Direct**: 1 account (server 125) - direct market maker connection
- **Marex**: 1 account (server 222) - commodity/multi-asset broker
- **FD**: 1 account (server 5454) - FD provider

---

## 2. Business Logic

### 2.1 Three-Table Join: Account + Provider Type + Server Mapping

**Source Tables**:
- `Hedge.Accounts HA` - LP account master data (IsActive, Name, Username, AccountTypeID, LiquidityProviderTypeID)
- `Trade.LiquidityProviderType TLPT` - LP type lookup (Name for each type)
- `Hedge.HedgeServerToLiquidityAccount HSTLA` - server-to-account assignment (HedgeServerID, AltRatesLiquidityAccountID)

**Join Logic**:
- `TLPT.LiquidityProviderTypeID = HA.LiquidityProviderTypeID` - enriches each account with its LP name
- `HSTLA.LiquidityAccountID = HA.ID` - brings in the hedge server assignment
- Both JOINs are INNER - accounts without a LP type or without a server assignment are excluded

**Filter**: `WHERE HA.IsActive = 1` - only active accounts. The `IsActive` column appears in the SELECT but is always `true` in the output.

### 2.2 AltRatesLiquidityAccountID (Currently NULL for All Rows)

**What**: The `AltRatesLiquidityAccountID` from HSTLA provides an alternative LP account to use for rate queries when the primary account is unavailable.

**Rules**:
- All 11 current rows have AltRatesLiquidityAccountID = NULL - no alternate rates accounts are configured
- When populated, this would point to another LiquidityAccountID in Hedge.Accounts
- Purpose: failover rates - if the primary LP is unavailable for pricing, fetch rates from the alternate account

---

## 3. Output Columns

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.HedgeServerToLiquidityAccount | The hedge server managing this LP account |
| LiquidityAccountID | Hedge.Accounts.ID | The LP account identifier |
| AltRatesLiquidityAccountID | Hedge.HedgeServerToLiquidityAccount | Alternate LP account for rates fallback (NULL for all active rows) |
| LiquidityAccountName | Hedge.Accounts.Name | Display name of the LP account (e.g., "ZBFX Price2 Execution") |
| LiquidityProviderTypeID | Trade.LiquidityProviderType | Numeric LP type identifier |
| LiquidityProviderName | Trade.LiquidityProviderType.Name | LP type display name (e.g., "ZBFX", "OMS", "Talos") |
| AccountTypeID | Hedge.Accounts | LP account type: 2=Execution, 4=OMS IM Pricing (pricing only, no execution) |
| Username | Hedge.Accounts | Credentials username for connecting to the LP |
| IsActive | Hedge.Accounts | Always true (view filters to IsActive=1) |

---

## 4. Data Overview

11 rows (all active LP accounts as of 2026-03-19):

| HedgeServerID | LiquidityAccountID | LiquidityAccountName | LiquidityProviderName | AccountTypeID |
|---|---|---|---|---|
| 1 | 10 | ZBFX Price2 Execution | ZBFX | 2 |
| 2 | 8 | ZBFX Price1 Execution | ZBFX | 2 |
| 3 | 14 | TRAFIX UAT Fract | APEX | 2 |
| 8 | 2147 | OMS UAT IM3 IM Pricing | OMS | 4 |
| 8 | 2148 | OMS UAT IM4 IM Hedging | OMS | 2 |
| 9 | 2150 | OMS UAT DMA Virtu | OMS | 2 |
| 10 | 346 | Talos | Talos | 2 |
| 125 | 12566 | MM Direct STG | MarketMaker Direct Connection | 2 |
| 222 | 2151 | OMS UAT DMA Marex | Marex | 2 |
| 1100 | 11 | ZBFX Price3 Execution | ZBFX | 2 |
| 5454 | 354541 | FD Provider UAT Account | FD | 2 |

AccountTypeID=4 (OMS UAT IM3 IM Pricing) is pricing-only; all others (type=2) are execution accounts.

---

## 5. Relationships

### 5.1 Source Tables (this view reads from)

| Table | Alias | Join Type | Join Condition |
|-------|-------|-----------|----------------|
| Hedge.Accounts | HA | Base table (filtered to IsActive=1) | WHERE HA.IsActive = 1 |
| Trade.LiquidityProviderType | TLPT | INNER JOIN | TLPT.LiquidityProviderTypeID = HA.LiquidityProviderTypeID |
| Hedge.HedgeServerToLiquidityAccount | HSTLA | INNER JOIN | HSTLA.LiquidityAccountID = HA.ID |

### 5.2 Consumed By

| Consumer | How Used |
|----------|----------|
| Hedge.GetActiveAccountByProviderAndAccountType | INNER JOINs this view to filter by LiquidityProviderTypeID and AccountTypeID |

---

## 6. Dependencies

```
Hedge.GetActiveProviderLiquidityAccounts (view)
+-- Hedge.Accounts (table) [primary source - see Hedge.Accounts.md]
+-- Trade.LiquidityProviderType (table) [LP type enrichment]
+-- Hedge.HedgeServerToLiquidityAccount (table) [server assignment - see Hedge.HedgeServerToLiquidityAccount.md]
```

---

## 7. Sample Queries

### 7.1 Get all active LP accounts for a specific provider type
```sql
SELECT  LiquidityAccountID,
        LiquidityAccountName,
        HedgeServerID,
        AccountTypeID,
        Username
FROM    [Hedge].[GetActiveProviderLiquidityAccounts] WITH (NOLOCK)
WHERE   LiquidityProviderName = 'ZBFX'
ORDER BY HedgeServerID;
```

### 7.2 Get execution-only accounts (exclude pricing-only)
```sql
SELECT  HedgeServerID,
        LiquidityAccountID,
        LiquidityAccountName,
        LiquidityProviderName
FROM    [Hedge].[GetActiveProviderLiquidityAccounts] WITH (NOLOCK)
WHERE   AccountTypeID = 2  -- Execution accounts only
ORDER BY HedgeServerID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this view.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (View phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetActiveProviderLiquidityAccounts | Type: View | Source: etoro/etoro/Hedge/Views/Hedge.GetActiveProviderLiquidityAccounts.sql*
