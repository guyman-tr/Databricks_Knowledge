# Dealing_dbo.V_Dealing_Duco_EODRecon

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | V_Dealing_Duco_EODRecon |
| **Type** | View |
| **Base Table** | `Dealing_dbo.Dealing_Duco_EODRecon` |
| **Filter** | `WHERE Date >= '2023-01-01'` |
| **Hint** | `WITH (NOLOCK)` |
| **Columns** | Same as base table + alias `BuyOrSell` for `[Buy/Sell]` |
| **Dedup** | `SELECT DISTINCT *` |
| **PII** | NO |
| **Tags** | dealing, duco, recon, eod, holdings, view, reconciliation, lp |

---

## 1. Business Meaning

A **time-filtered and deduplicated view** over `Dealing_Duco_EODRecon`, the primary foundation for all LP broker reconciliation pipelines. The base table compares eToro's LP hedge holdings against client NOP at EOD for each liquidity account and instrument.

This view:
1. **Filters** to data from 2023 onwards (removes pre-2023 history)
2. **Deduplicates** using `SELECT DISTINCT *` to handle any duplicate rows
3. **Aliases** the `[Buy/Sell]` column to `BuyOrSell` (bracket-free name for BI tool compatibility)

The Duco platform (automated reconciliation service) likely consumes this view directly, requiring clean column names without special characters.

---

## 2. Business Logic

```sql
SELECT DISTINCT *, [Buy/Sell] AS BuyOrSell
FROM Dealing_dbo.Dealing_Duco_EODRecon WITH (NOLOCK)
WHERE Date >= '2023-01-01'
```

The `BuyOrSell` alias resolves a common BI tool issue: column names with `/` or brackets can break SQL generators. This computed alias makes the Buy/Sell direction queryable without escaping.

---

## 3. Relationships

| Related Object | Relationship |
|----------------|--------------|
| [Dealing_Duco_EODRecon](../Tables/Dealing_Duco_EODRecon.md) | Base table — all columns inherited |
| `SP_DataForDuco` | Writer SP for the base table |
| 11+ downstream recon tables | Apex, GS, IB, IG, JPM, SAXO, VISION, BNY VIRTU, CloseOnly |

---

## 4. Elements

All columns are inherited from `Dealing_Duco_EODRecon`, plus one alias:

| # | Element | Type | Note |
|---|---------|------|------|
| N+1 | BuyOrSell | Alias | Alias for `[Buy/Sell]` column — same values (`Buy`/`Sell`), bracket-free name |

See [base table documentation](../Tables/Dealing_Duco_EODRecon.md) for full element descriptions. Key columns include `Date`, `LiquidityAccountID`, `InstrumentID`, `eToro_Units`, `ClientUnits`, `HedgingPercent`, `MKTcap`, `CUSIP`.

---

## 5. Usage Notes

**DISTINCT**: The `SELECT DISTINCT` removes any duplicate rows that may arise from the base table's DELETE+INSERT ETL pattern or edge cases in the SP. In normal operation, duplicates should be rare.

**Fixed date filter**: Unlike the CEP views which use `GETDATE()-180`, this view uses a hard-coded date (`2023-01-01`). The filter boundary does NOT move automatically.

**NOLOCK**: Dirty reads are acceptable for reconciliation dashboards where minor inconsistency is tolerable.

**Duco integration**: The `BuyOrSell` alias suggests this view is consumed by the Duco recon platform, which may have restrictions on column naming.

---

## 6. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Base Table | 5/5 | Base table extensively documented |
| Business Context | 4/5 | Duco platform integration clear; alias purpose documented |
| **Total** | **7.5/10** | Filter + alias view over well-documented base |

---

*Generated: 2026-03-21 | Batch 20 | Schema: Dealing_dbo*
