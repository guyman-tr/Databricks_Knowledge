# Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades

> 4,226-row FX and commodities trade-level reconciliation table comparing SAXO Bank LP executed trades against eToro internal hedge allocations and client positions. Data spans 2022-01-02 to 2023-12-05. **ORPHANED** — no writer SP exists in the SSDT codebase; the Trades INSERT was removed from `SP_SAXO_Recon_FXnCommed` (which now writes only to `Dealing_SaxoRecon_FXnCommed_EODHoldings`). Production source unknown (dormant).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant) — writer SP removed from codebase |
| **Refresh** | None — data stopped 2023-12-05 (orphaned) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on `[Date]` ASC |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | None |
| **UC Table Type** | N/A (dormant table, not migrated) |

---

## 1. Business Meaning

This table is the **trade-side** companion to `Dealing_SaxoRecon_FXnCommed_EODHoldings` in the SAXO Bank FX and commodities reconciliation suite. Each row represents one instrument x hedge-server x side (Buy/Sell) on a given date, comparing three perspectives:

- **SAXO**: Units, rates, and USD amounts from SAXO Bank LP trade execution reports
- **eToro**: Internal hedge allocation units, rates, and USD amounts
- **Clients**: Aggregated client-side traded units and USD amounts

Differential columns (`SAXO-eToro_*`, `SAXO-Clients_*`) quantify the discrepancy between these perspectives — the core reconciliation signal.

The table contains 4,226 rows covering 15 instruments (predominantly Platinum, Silver, Gold, GBP/USD, EUR/USD, AUD/USD) across 3 hedge servers (HS 7, 8, 23). Data was loaded daily from 2022-01-02 to 2023-12-05, when the writer process was decommissioned. The sibling SP `SP_SAXO_Recon_FXnCommed` (author: Evgeny, 2021-10-21) originally contained both Trades and EOD Holdings logic; the Trades INSERT was removed during subsequent restructuring (SR-247184, SR-282224, SR-282666).

---

## 2. Business Logic

### 2.1 Three-Way Reconciliation

**What**: Each row compares trade execution data from three independent sources for the same instrument/date/side.
**Columns Involved**: `SAXO_Units`, `eToro_Units`, `Clients_Units`, `SAXO_AmountUSD`, `eToro_AmountUSD`, `Clients_AmountUSD`
**Rules**:
- SAXO values represent the liquidity provider's view of executed trades
- eToro values represent the internal hedge system's allocation view
- Client values represent the aggregate of retail client positions
- Non-zero differentials indicate reconciliation breaks requiring investigation

### 2.2 Differential Metrics

**What**: Computed columns showing the difference between SAXO and eToro/Client perspectives.
**Columns Involved**: `SAXO-eToro_Units`, `SAXO-Clients_Units`, `SAXO-eToro_Rate`, `SAXO-eToro_AmountUSD`, `SAXO-Clients_AmountUSD`
**Rules**:
- Formula: `SAXO_X − eToro_X` or `SAXO_X − Clients_X` (inferred from sibling SP pattern and data values)
- `SAXO-eToro_AmountUSD` is the primary reconciliation metric (USD value discrepancy)
- `SAXO-Clients_AmountUSD` is the secondary metric (LP vs client value discrepancy)
- Zero differentials indicate matched positions

### 2.3 Instrument Coverage

**What**: FX pairs and commodities hedged through SAXO Bank.
**Columns Involved**: `InstrumentID`, `InstrumentDisplayName`, `ISINCode`
**Rules**:
- FX pairs: EUR/USD (466), GBP/USD (485), AUD/USD (438), USD/CHF (54), USD/TRY (7), plus minor pairs
- Commodities: Platinum (1,033), Silver (1,015), Gold (667), Natural Gas (25), Oil (16)
- ISINCode is NULL for ~35% of rows (1,468/4,226) — primarily FX pairs which lack ISIN codes

### 2.4 Hedge Server Segmentation

**What**: Trades are segmented by dealing desk / hedge server.
**Columns Involved**: `HedgeServerID`
**Rules**:
- HS 7: 3,235 rows (76.5%) — primary FX/commodities hedge server
- HS 8: 932 rows (22.1%) — secondary hedge server
- HS 23: 59 rows (1.4%) — added January 2022 per SP change history

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution — no co-located joins possible. Acceptable for a small (4K row) reconciliation table.
- **CLUSTERED INDEX on `[Date]`** — date-range scans are efficient. Always filter on `Date` first.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily reconciliation breaks | `WHERE [SAXO-eToro_AmountUSD] <> 0 ORDER BY [Date]` |
| Largest discrepancies | `ORDER BY ABS([SAXO-eToro_AmountUSD]) DESC` |
| Instrument-level summary | `GROUP BY InstrumentDisplayName` with `SUM([SAXO-eToro_AmountUSD])` |
| Hedge server comparison | `GROUP BY HedgeServerID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings` | `Date, HedgeServerID, InstrumentID, Side` | Compare trade-level vs EOD holdings reconciliation |
| `DWH_dbo.Dim_Instrument` | `InstrumentID` | Resolve instrument metadata (type, currency, symbol) |

### 3.4 Gotchas

- **ORPHANED TABLE**: No writer SP. Data stopped 2023-12-05. Do NOT use for current reconciliation — use `Dealing_SaxoRecon_FXnCommed_EODHoldings` instead.
- **Special-character columns**: `[SAXO-eToro_Units]`, `[SAXO-Clients_Units]`, `[SAXO-eToro_Rate]`, `[SAXO-eToro_AmountUSD]`, `[SAXO-Clients_AmountUSD]` require square bracket quoting in all queries.
- **Commission is always ≤ 0**: Range -559.27 to 0.00, with 782/4,226 rows at zero. Represents a fee/cost, not revenue.
- **ISINCode is NULL for FX pairs**: ~35% of rows lack ISIN — FX currency pairs do not have ISIN codes by nature.
- **InstrumentID has 2 NULL rows**: Minor data quality issue in the 4,226-row dataset.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Traced to SP source code |
| Tier 3 | Grounded in DDL + data sample, no SP code available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reconciliation date for this trade comparison row. Clustered index key. Range: 2022-01-02 to 2023-12-05. All 4,226 rows are non-NULL. (Tier 3 — DDL + data sample; no writer SP in SSDT) |
| 2 | InstrumentID | int | YES | eToro internal instrument identifier. FK to `DWH_dbo.Dim_Instrument`. 15 distinct values observed (e.g., 40=Platinum, 19=Silver, 18=Gold, 2=GBP/USD, 1=EUR/USD, 7=AUD/USD). 2 NULL rows. (Tier 3 — DDL + data sample; no writer SP in SSDT) |
| 3 | InstrumentDisplayName | nvarchar(100) | YES | Human-readable instrument display name. Values include: Platinum, Silver, Gold, GBP/USD, EUR/USD, AUD/USD, USD/CHF, Natural Gas, Oil, and minor FX pairs. (Tier 3 — DDL + data sample; no writer SP in SSDT) |
| 4 | ISINCode | nvarchar(30) | YES | International Securities Identification Number. Used as a join key between SAXO and eToro sides. NULL for ~35% of rows (1,468/4,226) — FX currency pairs do not have ISIN codes. (Tier 3 — DDL + data sample; no writer SP in SSDT) |
| 5 | Side | varchar(100) | YES | Trade direction. Two distinct values: 'Buy' (1,868 rows) and 'Sell' (2,358 rows). Unlike the sibling Stocks recon table, this column uses plain text rather than `[Buy/Sell]` bracket notation. (Tier 3 — DDL + data sample; no writer SP in SSDT) |
| 6 | HedgeServerID | int | YES | Dealing desk / hedge server identifier for FX and commodities routing. Three distinct values: 7 (3,235 rows, primary), 8 (932 rows), 23 (59 rows, added Jan 2022). Maps to LP account via Fivetran `External_Fivetran_dealing_active_hs_mappings`. (Tier 3 — DDL + data sample + sibling SP pattern; no writer SP in SSDT) |
| 7 | SAXO_Units | decimal(16,6) | YES | Number of units executed by SAXO Bank LP for this instrument/date/side. Represents the liquidity provider's reported trade volume. Can be 0 when SAXO has no corresponding position. (Tier 3 — DDL + data sample + sibling SP pattern; no writer SP in SSDT) |
| 8 | eToro_Units | decimal(16,6) | YES | Number of units from eToro's internal FX/commodities hedge allocation for this instrument/date/side. Represents eToro's view of the hedged volume. Can be 0 when eToro has no corresponding allocation. (Tier 3 — DDL + data sample + sibling SP pattern; no writer SP in SSDT) |
| 9 | Clients_Units | decimal(16,6) | YES | Aggregate client-side net traded units for this instrument/date/side. Represents the sum of retail client positions that drive the hedge requirement. (Tier 3 — DDL + data sample + sibling SP pattern; no writer SP in SSDT) |
| 10 | SAXO-eToro_Units | decimal(16,6) | YES | Unit discrepancy: `SAXO_Units − eToro_Units`. Non-zero values indicate a mismatch between SAXO LP execution and eToro hedge allocation. Special-character column requiring bracket quoting. (Tier 3 — DDL + data sample + sibling SP differential pattern; no writer SP in SSDT) |
| 11 | SAXO-Clients_Units | decimal(16,6) | YES | Unit discrepancy: `SAXO_Units − Clients_Units`. Non-zero values indicate a mismatch between SAXO LP execution and aggregated client positions. Special-character column requiring bracket quoting. (Tier 3 — DDL + data sample + sibling SP differential pattern; no writer SP in SSDT) |
| 12 | SAXO_Rate | decimal(16,6) | YES | SAXO LP execution rate (price) for this instrument/date/side. For FX: the exchange rate. For commodities: the commodity price per unit. Can be 0 when SAXO has no corresponding position. (Tier 3 — DDL + data sample; no writer SP in SSDT) |
| 13 | eToro_Rate | decimal(16,6) | YES | eToro execution rate for this instrument/date/side. Represents the average (or max) rate at which eToro's hedge was allocated. Can be 0 when eToro has no corresponding allocation. (Tier 3 — DDL + data sample + sibling SP pattern; no writer SP in SSDT) |
| 14 | SAXO-eToro_Rate | decimal(16,6) | YES | Rate discrepancy: `SAXO_Rate − eToro_Rate`. Non-zero values indicate price slippage between SAXO execution and eToro allocation. Special-character column requiring bracket quoting. (Tier 3 — DDL + data sample + sibling SP differential pattern; no writer SP in SSDT) |
| 15 | SAXO_LocalAmount | money | YES | SAXO trade value in the instrument's local (primary) currency. For FX: the notional amount in the sell currency. For commodities: units x price in the commodity's denomination. (Tier 3 — DDL + data sample + sibling SP pattern; no writer SP in SSDT) |
| 16 | SAXO_AmountUSD | money | YES | SAXO trade value converted to USD. The USD-equivalent notional for the SAXO-side execution. Used as numerator in the primary reconciliation differential. (Tier 3 — DDL + data sample + sibling SP pattern; no writer SP in SSDT) |
| 17 | eToro_AmountUSD | money | YES | eToro hedge allocation value in USD. The USD-equivalent notional for eToro's internal hedge. (Tier 3 — DDL + data sample + sibling SP pattern; no writer SP in SSDT) |
| 18 | Clients_AmountUSD | money | YES | Aggregate client-side trade value in USD. The USD-equivalent total of retail client positions for this instrument/date/side. (Tier 3 — DDL + data sample + sibling SP pattern; no writer SP in SSDT) |
| 19 | SAXO-eToro_AmountUSD | money | YES | **Primary reconciliation metric.** USD discrepancy: `SAXO_AmountUSD − eToro_AmountUSD`. Non-zero values indicate a dollar-value mismatch between the LP execution and the internal hedge allocation. Special-character column requiring bracket quoting. (Tier 3 — DDL + data sample + sibling SP differential pattern; no writer SP in SSDT) |
| 20 | SAXO-Clients_AmountUSD | money | YES | **Secondary reconciliation metric.** USD discrepancy: `SAXO_AmountUSD − Clients_AmountUSD`. Non-zero values indicate a dollar-value mismatch between the LP execution and aggregated client positions. Special-character column requiring bracket quoting. (Tier 3 — DDL + data sample + sibling SP differential pattern; no writer SP in SSDT) |
| 21 | Commission | money | YES | SAXO commission amount associated with the trade. All observed values are ≤ 0 (range: -559.27 to 0.00), representing a fee/cost. 782/4,226 rows are zero (no commission). Currency is unconfirmed — likely USD given the column context. (Tier 3 — DDL + data sample; no writer SP in SSDT) |
| 22 | UpdateDate | datetime | YES | ETL metadata timestamp indicating when this row was inserted or last updated by the pipeline. All 4,226 rows are non-NULL. Range: 2022-04-07 to 2023-12-06. (Tier 3 — DDL + data sample + sibling SP GETDATE() pattern; no writer SP in SSDT) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | SP parameter (inferred) | @Date | Daily reconciliation date |
| InstrumentID | DWH_dbo.Dim_Instrument (inferred) | InstrumentID | Passthrough |
| InstrumentDisplayName | Dim_Instrument / SAXO LP (inferred) | InstrumentDisplayName | ISNULL coalesce (sibling pattern) |
| ISINCode | SAXO LP / Dim_Instrument (inferred) | ISINCode | Passthrough |
| Side | eToro hedge data (inferred) | direction field | Mapped to 'Buy'/'Sell' |
| HedgeServerID | Fivetran mapping (inferred) | hs_dealing_desk | Passthrough |
| SAXO_Units | SAXO LP Trades (inferred) | trade amount | SUM aggregation |
| eToro_Units | eToro hedge data (inferred) | units | SUM aggregation |
| Clients_Units | Client positions (inferred) | client units | SUM aggregation |
| SAXO-eToro_Units | Computed | — | SAXO_Units − eToro_Units |
| SAXO-Clients_Units | Computed | — | SAXO_Units − Clients_Units |
| SAXO_Rate | SAXO LP Trades (inferred) | price | MAX aggregation |
| eToro_Rate | eToro hedge data (inferred) | rate | MAX aggregation |
| SAXO-eToro_Rate | Computed | — | SAXO_Rate − eToro_Rate |
| SAXO_LocalAmount | SAXO LP Trades (inferred) | local amount | SUM aggregation |
| SAXO_AmountUSD | SAXO LP Trades (inferred) | USD amount | SUM aggregation |
| eToro_AmountUSD | eToro hedge data (inferred) | USD amount | SUM aggregation |
| Clients_AmountUSD | Client positions (inferred) | USD amount | SUM aggregation |
| SAXO-eToro_AmountUSD | Computed | — | SAXO_AmountUSD − eToro_AmountUSD |
| SAXO-Clients_AmountUSD | Computed | — | SAXO_AmountUSD − Clients_AmountUSD |
| Commission | SAXO LP Trades (inferred) | commission | SUM aggregation |
| UpdateDate | SP runtime (inferred) | GETDATE() | ETL insert timestamp |

### 5.2 ETL Pipeline

```
SAXO Bank FX/Commed LP Trade Reports (external)
  + eToro Hedge Allocation / Duco Recon Data
  + Fivetran HS Mapping (Dealing_staging.External_Fivetran_dealing_active_hs_mappings)
  + Client Positions (DWH_dbo.Dim_Position or risk matrix — inferred)
    |
    |-- SP_SAXO_Recon_FXnCommed (Trades section — NOW REMOVED from SP)
    v
  Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades (4,226 rows)
    |
    |-- DATA STOPPED 2023-12-05 — ORPHANED
    v
  _Not_Migrated (no UC target)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | `DWH_dbo.Dim_Instrument` | Instrument dimension lookup (inferred) |
| HedgeServerID | Fivetran HS mapping | Hedge server / dealing desk identifier |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Key | Description |
|-------------------|----------|-------------|
| None found | — | No SPs, views, or tables reference this object in the SSDT codebase |

---

## 7. Sample Queries

### 7.1 Find All Non-Zero Reconciliation Breaks

```sql
SELECT [Date], InstrumentDisplayName, [Side], HedgeServerID,
       [SAXO-eToro_AmountUSD], [SAXO-Clients_AmountUSD]
FROM [Dealing_dbo].[Dealing_SaxoRecon_FXnCommed_Trades]
WHERE [SAXO-eToro_AmountUSD] <> 0
ORDER BY ABS([SAXO-eToro_AmountUSD]) DESC
```

### 7.2 Daily Instrument Summary

```sql
SELECT [Date], InstrumentDisplayName,
       SUM(SAXO_Units) AS Total_SAXO_Units,
       SUM(eToro_Units) AS Total_eToro_Units,
       SUM([SAXO-eToro_AmountUSD]) AS Net_Discrepancy_USD
FROM [Dealing_dbo].[Dealing_SaxoRecon_FXnCommed_Trades]
GROUP BY [Date], InstrumentDisplayName
ORDER BY [Date] DESC, ABS(SUM([SAXO-eToro_AmountUSD])) DESC
```

### 7.3 Hedge Server Break Summary

```sql
SELECT HedgeServerID,
       COUNT(*) AS Rows,
       SUM(CASE WHEN [SAXO-eToro_AmountUSD] <> 0 THEN 1 ELSE 0 END) AS Break_Count,
       SUM([SAXO-eToro_AmountUSD]) AS Total_Break_USD
FROM [Dealing_dbo].[Dealing_SaxoRecon_FXnCommed_Trades]
GROUP BY HedgeServerID
ORDER BY HedgeServerID
```

---

## 8. Atlassian Knowledge Sources

- [Trade Reporting Data Source Inventory](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/14081490998) — General trade reporting reconciliation architecture; mentions SAXO (REGIS) full reconciliation
- [Saxo Bank](https://etoro-jira.atlassian.net/wiki/spaces/HOMS/pages/11553997036) — SAXO Bank connectivity details, FIX sessions, account IDs
- [SOD Reconciliation](https://etoro-jira.atlassian.net/wiki/spaces/EMM/pages/13301481562) — Start of Day reconciliation tool overview; general recon framework
- No Jira ticket or Confluence page specific to `Dealing_SaxoRecon_FXnCommed_Trades` was found

---

*Generated: 2026-04-27 | Quality: 5.0/10 | Phases: 12/14 (P9, P9B skipped — orphaned)*
*Tiers: 0 T1, 0 T2, 22 T3, 0 T4, 0 T5 | Elements: 22/22, Logic: 6/10, Lineage: 4/10*
*Object: Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades | Type: Table | Production Source: Unknown (dormant)*
