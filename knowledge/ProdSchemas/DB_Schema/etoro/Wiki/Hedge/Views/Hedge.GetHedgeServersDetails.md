# Hedge.GetHedgeServersDetails

> Returns all hedge servers with their assigned LP account ID and account name (from Trade.GetLiquidityAccounts). 50 rows including servers with no LP assignment (NULL account columns). All LEFT JOINs.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | View |
| **Row Count** | 50 |

---

## 1. Business Meaning

Hedge.GetHedgeServersDetails provides the complete list of hedge servers with their optional LP account assignments. It joins Trade.HedgeServer to the LP account name via two LEFT JOINs, making this a server-centric view (vs GetActiveProviderLiquidityAccounts which is account-centric).

Key differences from GetActiveProviderLiquidityAccounts:
- Starts from ALL hedge servers (Trade.HedgeServer), not from active LP accounts
- Includes servers with no LP assignment (HedgeServerID=0, HedgeServerID=4 in sample data show NULL LiquidityAccountID)
- Sources account name from `Trade.GetLiquidityAccounts` (a cross-schema view in Trade), not Hedge.Accounts
- All JOINs are LEFT - maximum server coverage

50 rows = all hedge servers configured in Trade.HedgeServer, whether assigned to an LP account or not.

---

## 2. Business Logic

### 2.1 Server-Centric Left Join Pattern

**Source Tables**: Trade.HedgeServer (base), Hedge.HedgeServerToLiquidityAccount (LEFT), Trade.GetLiquidityAccounts (LEFT)

**Rules**:
- Every HedgeServer row appears exactly once
- Servers with no LP account assignment: LiquidityAccountID = NULL, LiquidityAccountName = NULL
- The account name comes from Trade.GetLiquidityAccounts (cross-schema view), not Hedge.Accounts directly

---

## 3. Output Columns

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Trade.HedgeServer | The hedge server ID - all servers included |
| LiquidityAccountID | Hedge.HedgeServerToLiquidityAccount | The assigned LP account ID (NULL if server has no LP assignment) |
| LiquidityAccountName | Trade.GetLiquidityAccounts | Display name of the LP account (NULL if no assignment; may say "Obsolete!" for legacy entries) |

---

## 4. Data Overview

50 rows. Sample:

| HedgeServerID | LiquidityAccountID | LiquidityAccountName |
|---|---|---|
| 0 | NULL | NULL |
| 1 | 10 | ZBFX Price2 Execution |
| 2 | 8 | ZBFX Price1 Execution |
| 3 | 14 | TRAFIX UAT Fract - Obsolete! Use Hedge Account |
| 4 | NULL | NULL |

HedgeServerID=0 and HedgeServerID=4 have no LP accounts. HedgeServerID=3's account is marked "Obsolete" in the name - indicates deprecated configuration still present.

---

## 5. Relationships

### 5.1 Source Tables

| Table | Alias | Join Type | Condition |
|-------|-------|-----------|-----------|
| Trade.HedgeServer | THS | Base table | - |
| Hedge.HedgeServerToLiquidityAccount | HHS | LEFT JOIN | HHS.HedgeServerID = THS.HedgeServerID |
| Trade.GetLiquidityAccounts | TLA | LEFT JOIN | TLA.LiquidityAccountID = HHS.LiquidityAccountID |

### 5.2 Consumed By

No stored procedures found referencing this view in the Hedge schema.

---

## 6. Dependencies

```
Hedge.GetHedgeServersDetails (view)
+-- Trade.HedgeServer (table) [source - all servers]
+-- Hedge.HedgeServerToLiquidityAccount (table) [see Hedge.HedgeServerToLiquidityAccount.md]
+-- Trade.GetLiquidityAccounts (view) [cross-schema - provides account names]
```

---

## 7. Sample Queries

### 7.1 Find servers with no LP account assigned
```sql
SELECT HedgeServerID
FROM   [Hedge].[GetHedgeServersDetails] WITH (NOLOCK)
WHERE  LiquidityAccountID IS NULL
ORDER BY HedgeServerID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (View phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | Corrections: 0 applied*
*Object: Hedge.GetHedgeServersDetails | Type: View | Source: etoro/etoro/Hedge/Views/Hedge.GetHedgeServersDetails.sql*
