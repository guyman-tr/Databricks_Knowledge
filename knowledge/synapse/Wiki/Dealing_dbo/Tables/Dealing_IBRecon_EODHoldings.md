# Dealing_dbo.Dealing_IBRecon_EODHoldings

## 1. Overview

**Daily end-of-day holdings reconciliation** for Interactive Brokers (IB) equity accounts, comparing IB's custodian positions against eToro's hedge positions and client NOP. Uses a naming convention distinct from other LP recon tables: diff columns are `Reality-Supposed` (LP vs eToro) and `Reality-Client` (LP vs client), and the direction flag is a boolean `IsBuy` rather than a Buy/Sell string.

**Row grain**: `Date` + `InstrumentID` + `IsBuy` + `ClientAccountID`.

---

## 2. Business Context

`SP_IB_Recon` (Author: Adar Cahlon, 2021-07-01; many updates) is the oldest of the LP recon SPs. It runs daily as a **SB_Daily Priority 0** task. The SP has undergone extensive evolution (25+ change log entries) reflecting IB account additions/removals and structural improvements.

**IB account history**:
- **HS 126 / I3158027 (UL3148833)** — Primary IB account, still active as of 2026-03-09. Most recent data with UL3148833 account.
- **HS 126 / I1893329 (I16058395)** — Secondary IB account, contains sanctioned Russian ADR stocks (Gazprom, Lukoil, Norilsk). Last data 2026-03-09.
- **HS 121 (UL1894678)** — Removed 2024-04-16 (SR-247903). Last data 2024-04-15.
- **HS 25** — Legacy account, stopped 2023-06-12.

**Reconciliation flow**:
1. **eToro side** — from `Dealing_Duco_EODRecon` filtered to HS 126.
2. **IB side** — from `Dealing_staging.LP_IB_I3158027_Open_Positions` and `LP_IB_I1893329_Open_Positions`.
3. The SP uses `@Date2 = MAX(ReportDate) WHERE ReportDate <= @Date` — if IB data for the exact date is unavailable, falls back to the nearest prior date.
4. **JOIN key**: ISIN + currency (with dual symbol columns IB_Symbol and eToro_Symbol for cross-reference).

**Diff column naming** (different from other LP tables):
- `Reality-Supposed` = LP (IB) amount − eToro amount.
- `Reality-Client` = LP (IB) amount − client amount.

**Key changes** (from SP change log):
- 2021-06-15: Migrated to use Duco files (SP_DataForDuco as eToro source).
- SR-247903 (2024-04-16): Removed HS 121 (equity accounts).
- SR-302234 (2025-02-25): Added IB CFD (HS 121 initially, then changed to HS 300 in Apr 2025).

**Data currency**: Near-current as of 2026-03-09. ~652K rows.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 29 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

| Check | Result |
|--------|--------|
| **Row count** | ~652,188 |
| **Date range** | Near-current (most recent: 2026-03-09) |
| **Active accounts** | HS 126 / UL3148833 (primary), HS 126 / I16058395 (Russian ADRs) |
| **Inactive accounts** | HS 121 (stopped 2024-04-15), HS 25 (stopped 2023-06-12) |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | EOD snapshot date. May differ from @Date if IB data unavailable (falls back to nearest prior date). |
| 2 | InstrumentID | int | YES | eToro instrument identifier. FK → DWH_dbo.Dim_Instrument. |
| 3 | InstrumentDisplayName | varchar(100) | YES | Instrument name. |
| 4 | ISINCode | varchar(50) | YES | ISIN — primary join key between IB and eToro sides. |
| 5 | IB_Symbol | varchar(50) | YES | Ticker symbol as reported by IB (may differ from eToro symbol). |
| 6 | eToro_Symbol | varchar(50) | YES | Ticker symbol as used by eToro. Cross-reference for symbol mapping validation. |
| 7 | IsBuy | bit | YES | Direction flag: 1 = buy (long), 0 = sell (short). Different convention from other LP recon tables which use 'Buy'/'Sell' text. |
| 8 | CurrencyPrimary | varchar(50) | YES | Instrument local currency (SellCurrency from Duco). GBX retained; amounts adjusted by ÷100. |
| 9 | IB_Units | decimal(16,6) | YES | EOD position units reported by IB (from LP_IB_...Open_Positions). (Tier 2 — LP_IB_I3158027/I1893329_Open_Positions) |
| 10 | eToro_Units | decimal(16,6) | YES | eToro hedge units. (Tier 1 — Dealing_Duco_EODRecon.eToro_Units) |
| 11 | Clients_Units | decimal(16,6) | YES | Client NOP units. (Tier 1 — Dealing_Duco_EODRecon.ClientUnits) |
| 12 | IB-eToro_Units | decimal(16,6) | YES | **Reconciliation diff**: IB_Units − eToro_Units. |
| 13 | IB-Clients_Units | decimal(16,6) | YES | IB_Units − Clients_Units. |
| 14 | IB_LocalAmount | money | YES | IB position value in local currency. GBX instruments: amounts ÷100 to normalise to GBP. |
| 15 | IB_AmountUSD | money | YES | IB position value in USD. |
| 16 | eToro_AmountUSD | money | YES | eToro position value in USD. |
| 17 | Clients_AmountNOP | money | YES | Client NOP value (naming follows SP convention: "NOP" = net open position). |
| 18 | Reality-Supposed | money | YES | **LP-eToro USD diff**: IB_AmountUSD − eToro_AmountUSD. "Reality" = LP truth; "Supposed" = eToro internal assumption. |
| 19 | Reality-Client | money | YES | IB_AmountUSD − Clients_AmountNOP. LP vs client NOP discrepancy. |
| 20 | IB_Rate | decimal(16,6) | YES | IB price per unit in local currency. |
| 21 | FX_Rate | decimal(16,6) | YES | FX rate (local → USD) used for USD conversion. |
| 22 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| 23 | HedgeServerID | int | YES | eToro hedge server identifier (126 = primary IB equity account). |
| 24 | Exchange | varchar(100) | YES | Trading venue. |
| 25 | LastExecutionTime | datetime | YES | Timestamp of the most recent execution for this instrument in the IB account. From IB data, used for reconciliation freshness checks. |
| 26 | ClientAccountID | varchar(30) | YES | IB client account identifier (e.g., "UL3148833", "I16058395"). Links to specific sub-account within HS 126. |

---

## 6. Relationships

| Relationship | Object | Join Columns |
|---|---|---|
| Upstream (eToro) | [Dealing_Duco_EODRecon](Dealing_Duco_EODRecon.md) | HedgeServerID + Date |
| Upstream (instrument) | DWH_dbo.Dim_Instrument | InstrumentID |
| Sibling (trades) | [Dealing_IBRecon_Trades](Dealing_IBRecon_Trades.md) | Same SP_IB_Recon |
| Sibling (CFD EOD) | [Dealing_IBRecon_EODHoldings_CFD](Dealing_IBRecon_EODHoldings_CFD.md) | Same SP_IB_Recon, HS 300 |

---

## 7. ETL / Lineage

| Property | Value |
|---|---|
| **Writer** | `Dealing_dbo.SP_IB_Recon` |
| **Schedule** | Daily (SB_Daily), Priority 0 |
| **OpsDB** | Registered as Dealing_dbo.Dealing_IBRecon_EODHoldings |
| **Pattern** | DELETE-INSERT by Date |
| **Date fallback** | Uses MAX(ReportDate ≤ @Date) from LP_IB_I3158027_Open_Positions |
| **eToro Source** | Dealing_dbo.Dealing_Duco_EODRecon (HS 126) |
| **LP Sources** | Dealing_staging.LP_IB_I3158027_Open_Positions, LP_IB_I1893329_Open_Positions |

---

## 8. Usage Notes

- Rows with Russian ADR ISINs (Gazprom US3682872078, Lukoil US69343P1057, Norilsk US55315J1025) in `ClientAccountID = I16058395` are sanctioned instruments — position reconciliation is informational only, trading halted.
- Filter `HedgeServerID = 126` and `ClientAccountID = 'UL3148833'` for the main active account.
- `LastExecutionTime` is absent from `Dealing_IBRecon_EODHoldings_CFD` — only present here.
