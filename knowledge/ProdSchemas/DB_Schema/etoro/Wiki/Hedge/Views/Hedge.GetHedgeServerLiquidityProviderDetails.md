# Hedge.GetHedgeServerLiquidityProviderDetails

> Minimal join of HedgeServerToLiquidityAccount and Accounts, returning the LP type for each server/account pair. 11 rows. Used as a filter surface to find LP accounts by provider type.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | View |
| **Row Count** | 11 |

---

## 1. Business Meaning

Hedge.GetHedgeServerLiquidityProviderDetails provides the minimum required information to identify what LP type each hedge server account belongs to. It is a thin join view - Hedge.HedgeServerToLiquidityAccount enriched with the LiquidityProviderTypeID from Hedge.Accounts.

This view is used as a secondary join surface in `Hedge.GetActiveAccountByProviderAndAccountType`, which needs to filter by LiquidityProviderTypeID. Without this view, the calling procedure would need to join HedgeServerToLiquidityAccount and Accounts directly each time.

The 11 rows match exactly the active LP account assignments (same set as Hedge.GetActiveProviderLiquidityAccounts, but without the IsActive filter and with fewer columns).

---

## 2. Output Columns

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.HedgeServerToLiquidityAccount | The hedge server ID |
| LiquidityAccountID | Hedge.HedgeServerToLiquidityAccount | The LP account ID |
| AltRatesLiquidityAccountID | Hedge.HedgeServerToLiquidityAccount | Alternate rates LP account (currently NULL for all rows) |
| LiquidityProviderTypeID | Hedge.Accounts | Numeric LP provider type ID |

---

## 3. Data Overview

11 rows (one per server-account assignment):

| HedgeServerID | LiquidityAccountID | AltRatesLiquidityAccountID | LiquidityProviderTypeID |
|---|---|---|---|
| 1 | 10 | NULL | 69 (ZBFX) |
| 2 | 8 | NULL | 69 (ZBFX) |
| 3 | 14 | NULL | 40 (APEX) |
| ... | ... | NULL | ... |

---

## 4. Relationships

### 4.1 Source Tables

| Table | Alias | Join Type | Condition |
|-------|-------|-----------|-----------|
| Hedge.HedgeServerToLiquidityAccount | HHLA | Base table | - |
| Hedge.Accounts | HA | INNER JOIN | HA.ID = HHLA.LiquidityAccountID |

### 4.2 Consumed By

| Consumer | How Used |
|----------|----------|
| Hedge.GetActiveAccountByProviderAndAccountType | INNER JOIN to filter by LiquidityProviderTypeID |

---

## 5. Dependencies

```
Hedge.GetHedgeServerLiquidityProviderDetails (view)
+-- Hedge.HedgeServerToLiquidityAccount (table) [see Hedge.HedgeServerToLiquidityAccount.md]
+-- Hedge.Accounts (table) [see Hedge.Accounts.md]
```

---

## 6. Sample Queries

### 6.1 Find all servers using a specific LP provider type
```sql
SELECT  HedgeServerID, LiquidityAccountID
FROM    [Hedge].[GetHedgeServerLiquidityProviderDetails] WITH (NOLOCK)
WHERE   LiquidityProviderTypeID = 69; -- ZBFX
```

---

## 7. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (View phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | Corrections: 0 applied*
*Object: Hedge.GetHedgeServerLiquidityProviderDetails | Type: View | Source: etoro/etoro/Hedge/Views/Hedge.GetHedgeServerLiquidityProviderDetails.sql*
