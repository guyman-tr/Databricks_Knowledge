# Dealing_dbo.V_Dealing_Duco_EODRecon

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_Duco_EODRecon |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_Duco_EODRecon` |
| **Filter** | `WHERE Date >= '2023-01-01'` (static cutoff) + DISTINCT dedup |
| **Distribution** | N/A (view) |
| **PII** | None |

---

## 1. Business Meaning

Filtered, deduplicated view over `Dealing_Duco_EODRecon` — the daily EOD LP reconciliation table — with two enhancements:

1. **2023-01-01 cutoff**: Limits to data from 2023 onwards (pre-2023 data excluded)
2. **DISTINCT dedup**: Removes any duplicate rows that may exist in the base table
3. **`BuyOrSell` alias**: The base table column `[Buy/Sell]` (bracket-required due to `/`) is aliased as `BuyOrSell` for SQL-safe consumption without brackets

This is the standard entry point for **Duco reconciliation queries** — most downstream broker-specific recon tables (Apex, GS, IB, IG, JPM, VISION, BNY VIRTU etc.) reference this view rather than the base table directly.

See [Dealing_Duco_EODRecon.md](Dealing_Duco_EODRecon.md) for full business context and column definitions.

---

## 2. View Definition

```sql
SELECT DISTINCT *, [Buy/Sell] AS BuyOrSell
FROM [Dealing_dbo].[Dealing_Duco_EODRecon] WITH (NOLOCK)
WHERE Date >= '2023-01-01';
```

---

## 3. Key Column Enhancement

| Column | Notes |
|--------|-------|
| All base columns | Passthrough from Dealing_Duco_EODRecon |
| `BuyOrSell` | Alias for `[Buy/Sell]` — allows referencing without bracket quoting |

---

## 4. Common Query Patterns

```sql
-- Recent EOD reconciliation for a specific instrument
SELECT Date, LiquidityAccountID, InstrumentID, BuyOrSell,
       eToro_Units, Client_Units, HedgingPercent
FROM Dealing_dbo.V_Dealing_Duco_EODRecon
WHERE Date >= '2026-01-01'
  AND InstrumentID = 1234
ORDER BY Date DESC;
```

> ⚠️ **BuyOrSell alias**: The column `[Buy/Sell]` from the base table appears **twice** in this view — once as `[Buy/Sell]` (from `SELECT *`) and once as `BuyOrSell` (from the explicit alias). Use `BuyOrSell` for cleaner SQL.

---

## 5. Known Issues & Quirks

- **Duplicate column**: SELECT * then [Buy/Sell] AS BuyOrSell means `[Buy/Sell]` appears twice — once from the `*` expansion, and once aliased. Use `BuyOrSell` to avoid ambiguity
- **Static cutoff**: Date >= '2023-01-01' is hardcoded — older data requires direct base table query
- **NOLOCK hint**: May return uncommitted data
- **DISTINCT cost**: DISTINCT on a large table adds overhead; ensure this view is used with additional filters

---

## 6. Lineage Summary

Thin filter/alias wrapper over `Dealing_dbo.Dealing_Duco_EODRecon`. Only transformation is the `BuyOrSell` alias and DISTINCT dedup. See [Dealing_Duco_EODRecon.md](Dealing_Duco_EODRecon.md) for full lineage.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_Duco_EODRecon` | Base table — this view is a filtered window |
| `Dealing_dbo.Dealing_ApexRecon_Holdings`, `Dealing_IBRecon_EODHoldings`, etc. | Downstream broker recon tables that join to this view |

---

*Quality score: 7.5/10 — widely used standard entry point for Duco recon, BuyOrSell alias is helpful*
