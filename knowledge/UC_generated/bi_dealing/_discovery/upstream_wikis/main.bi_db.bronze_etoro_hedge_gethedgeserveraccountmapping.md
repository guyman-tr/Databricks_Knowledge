# Hedge.GetHedgeServerAccountMapping

> Maps supported instruments to their LP accounts and hedge servers. 10,605 rows. Joins SupportedInstrumentsAccount with Accounts, LiquidityProviderType, and HedgeServerToLiquidityAccount. Used to discover which LP account handles each instrument on which server.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | View |
| **Row Count** | 10,605 |

---

## 1. Business Meaning

Hedge.GetHedgeServerAccountMapping produces the instrument-level account routing table: for each supported instrument on each LP account, it shows the LP name and the hedge server assignment. This is the "where does this instrument get hedged and on which server" lookup.

The view joins four tables:
- **Hedge.SupportedInstrumentsAccount** (SIA): the primary source - one row per (LiquidityAccountID, InstrumentID) pair defining which instruments are supported on each LP account
- **Hedge.Accounts** (HA): enriches with LP account name
- **Trade.LiquidityProviderType** (LPT): LEFT JOIN - enriches with LP provider name (NULL if account has no LP type)
- **Hedge.HedgeServerToLiquidityAccount** (HSLA): LEFT JOIN - adds the HedgeServerID (NULL if account has no server assignment)

With 10,605 rows, this represents all active instrument/account support combinations across all LP accounts.

**Important**: HedgeServerID can be NULL (as seen in sample data - LiquidityAccountID=439 "DLT" has no server assignment). This indicates accounts that are configured but not yet assigned to a hedge server.

---

## 2. Business Logic

### 2.1 Instrument-Account-Server Triple Mapping

**Source Tables**: SIA (INNER base), HA (INNER), LPT (LEFT), HSLA (LEFT)

**Rules**:
- Every row has a valid LiquidityAccountID and InstrumentID (INNER join with HA)
- LiquidityProviderName may be NULL if the account type has no LP type entry
- HedgeServerID may be NULL for accounts not yet assigned to a hedge server

---

## 3. Output Columns

| Column | Source | Description |
|--------|--------|-------------|
| LiquidityAccountID | Hedge.SupportedInstrumentsAccount | The LP account supporting this instrument |
| LiquidityAccountName | Hedge.Accounts.Name | Display name of the LP account |
| LiquidityProviderName | Trade.LiquidityProviderType.Name | LP provider type name (e.g., "ZBFX", "OMS"). NULL if no LP type. |
| HedgeServerID | Hedge.HedgeServerToLiquidityAccount | The hedge server managing this LP account. NULL if not assigned. |
| InstrumentID | Hedge.SupportedInstrumentsAccount | The instrument supported on this LP account |

---

## 4. Data Overview

10,605 rows. Sample:

| LiquidityAccountID | LiquidityAccountName | LiquidityProviderName | HedgeServerID | InstrumentID |
|---|---|---|---|---|
| 439 | DLT | DLT | NULL | 100000 |
| 8 | ZBFX Price1 Execution | ZBFX | 2 | 4 |
| 8 | ZBFX Price1 Execution | ZBFX | 2 | 3 |

---

## 5. Relationships

### 5.1 Source Tables

| Table | Alias | Join Type | Condition |
|-------|-------|-----------|-----------|
| Hedge.SupportedInstrumentsAccount | SIA | Base table | - |
| Hedge.Accounts | HA | INNER JOIN | HA.ID = SIA.LiquidityAccountID |
| Trade.LiquidityProviderType | LPT | LEFT JOIN | LPT.LiquidityProviderTypeID = HA.LiquidityProviderTypeID |
| Hedge.HedgeServerToLiquidityAccount | HSLA | LEFT JOIN | HSLA.LiquidityAccountID = SIA.LiquidityAccountID |

### 5.2 Consumed By

No stored procedures found referencing this view. Application code reads directly.

---

## 6. Dependencies

```
Hedge.GetHedgeServerAccountMapping (view)
+-- Hedge.SupportedInstrumentsAccount (table) [see Hedge.SupportedInstrumentsAccount.md]
+-- Hedge.Accounts (table) [see Hedge.Accounts.md]
+-- Trade.LiquidityProviderType (table)
+-- Hedge.HedgeServerToLiquidityAccount (table) [see Hedge.HedgeServerToLiquidityAccount.md]
```

---

## 7. Sample Queries

### 7.1 Find all LP accounts and servers supporting a specific instrument
```sql
SELECT  LiquidityAccountID, LiquidityAccountName, LiquidityProviderName, HedgeServerID
FROM    [Hedge].[GetHedgeServerAccountMapping] WITH (NOLOCK)
WHERE   InstrumentID = 1 -- EUR/USD
ORDER BY HedgeServerID;
```

### 7.2 Find accounts with no hedge server assigned
```sql
SELECT  DISTINCT LiquidityAccountID, LiquidityAccountName, LiquidityProviderName
FROM    [Hedge].[GetHedgeServerAccountMapping] WITH (NOLOCK)
WHERE   HedgeServerID IS NULL;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (View phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | Corrections: 0 applied*
*Object: Hedge.GetHedgeServerAccountMapping | Type: View | Source: etoro/etoro/Hedge/Views/Hedge.GetHedgeServerAccountMapping.sql*
