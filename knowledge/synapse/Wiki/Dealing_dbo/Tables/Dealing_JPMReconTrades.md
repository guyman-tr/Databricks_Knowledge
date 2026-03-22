# Dealing_dbo.Dealing_JPMReconTrades

> Daily trade activity reconciliation comparing JPMorgan's executed trade volume against eToro's internal dealing records by instrument and direction, surfacing unit and value discrepancies across NA, EMEA, and ASIA regions.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | LP_JPM_ETORO_NA/EMEA/ASIA_Trade_Summary + Dealing_Duco_ActivityRecon |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Companion table to `Dealing_JPMReconEODHolding`, covering the **trade activity** dimension of the JPMorgan reconciliation. Each row represents one instrument × direction (Buy/Sell) combination for a given date, comparing JPMorgan's reported executed trade volume across NA, EMEA, and ASIA against eToro's internal trade records from `Dealing_Duco_ActivityRecon`.

Where `Dealing_JPMReconEODHolding` shows end-of-day position snapshots, this table shows intraday trade flows. Non-zero `JP-eToro_*` values flag trades that appear on JPM's books but not eToro's (or vice versa). `Total_Commission_USD` captures commission costs charged by JPMorgan on trades, converted to USD using the daily FX rate.

Same SP as EOD holdings (`SP_JPMRecon`, Gili Goldbaum, Nov 2023). JP trades sourced from three regional LP tables: `LP_JPM_ETORO_NA_Trade_Summary`, `LP_JPM_ETORO_EMEA_Trade_Summary`, `LP_JPM_ETORO_ASIA_Trade_Summary`. eToro trades from `Dealing_Duco_ActivityRecon`. DELETE-INSERT by Date.

---

## 2. Business Logic

### 2.1 Trade Direction Encoding

**What**: Trades are broken down by Buy/Sell direction.

**Columns involved**: `Buy/Sell`, `JP_Units`, `eToro_Units`

**Rules**:
- `Buy/Sell` = 'Buy' or 'Sell' from both JP and eToro sides
- `JP_Units` = SUM of trade units from JPM regional trade summary tables
- `eToro_Units` = SUM of eToro trade units from `Dealing_Duco_ActivityRecon` for JPM HS (2, 8, 22, 9, 121, 110, 129, 319)
- GBX ÷100 normalisation applied on eToro side

### 2.2 Commission Calculation

**What**: `Total_Commission_USD` captures JPM commission per instrument per date.

**Rules**:
- Commission value from JPM trade summary tables, converted using daily FX rate
- Stored in USD; zero for USD-denominated instruments (no FX conversion needed)

### 2.3 Reconciliation Diff Columns

**What**: `{JP}-{side}_*` columns show arithmetic difference between LP and eToro sides.

**Rules**:
- Formula: `ISNULL(JP_value, 0) − ISNULL(eToro_value, 0)`
- Non-zero = trade recon break; zero = reconciled

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. Filter on Date first; add `InstrumentID` or `Buy/Sell` filters to narrow results.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Filter on `Date` for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Trade breaks for a date | `WHERE Date = @d AND [JP-eToro_Units] <> 0` |
| Buy vs Sell volume comparison | `GROUP BY Date, InstrumentID, [Buy/Sell]` |
| Commission cost by instrument | `SELECT InstrumentID, SUM(Total_Commission_USD) GROUP BY Date, InstrumentID` |
| Reconcile against EOD holdings | JOIN to Dealing_JPMReconEODHolding on Date + InstrumentID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata |
| Dealing_JPMReconEODHolding | Date + InstrumentID | Pair trade recon with EOD holdings |
| Dealing_Duco_ActivityRecon | Date + HedgeServerID | Trace eToro-side source trades |

### 3.4 Gotchas

- **No HedgeServerID or Account_Number**: Unlike the IGRecon counterpart, this table does not retain HS or account granularity — breaks are instrument+direction level only
- **Regional UNION**: JP trade data is UNIONed from three regional tables (NA, EMEA, ASIA); a single instrument may appear in multiple regions if traded across venues
- **HS 9 special handling**: Same as EOD — HS 9 matched by ISINCode/InstrumentDisplayName rather than InstrumentID
- **GBX normalisation**: Applied on eToro side amounts (÷100)

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_JPMRecon)` |
| ★★ | Tier 3 — DDL/live | `(Tier 3 — DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trade date. Uses JPM's `MAX(ReportDateID)` ≤ requested date — may lag 1 day when JPM report is delayed. (Tier 2 — SP_JPMRecon) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. Resolved via ISNULL(eToro_side, JP_side). May be NULL for HS 9 rows without instrument mapping. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_JPMRecon) |
| 3 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. ISNULL(eToro_side, JP.[Name]). (Tier 2 — SP_JPMRecon) |
| 4 | Symbol | varchar(250) | YES | Ticker symbol. ISNULL(eToro_side, JP.[RIC Code]). (Tier 2 — SP_JPMRecon) |
| 5 | ISINCode | varchar(250) | YES | ISIN. ISNULL(eToro_side, JP.[ISIN Code]). Primary join key. (Tier 2 — SP_JPMRecon) |
| 6 | Buy/Sell | varchar(100) | YES | Trade direction: 'Buy' or 'Sell'. Sourced from both JP and eToro sides. (Tier 2 — SP_JPMRecon) |
| 7 | CurrencyPrimary | varchar(50) | YES | Instrument local currency. GBX normalised to GBP. ISNULL(eToro, JP). (Tier 2 — SP_JPMRecon) |
| 8 | JP_Units | decimal(16,6) | YES | JPM's executed trade volume in units. SUM from LP_JPM_ETORO_NA/EMEA/ASIA_Trade_Summary. ISNULL(,0). (Tier 2 — SP_JPMRecon) |
| 9 | eToro_Units | decimal(16,6) | YES | eToro's executed trade volume. SUM from Dealing_Duco_ActivityRecon for JPM HS (2,8,22,9,121,110,129,319). ISNULL(,0). (Tier 2 — SP_JPMRecon) |
| 10 | Clients_Units | decimal(16,6) | YES | Aggregated client trade volume. SUM(ClientUnits) from Dealing_Duco_ActivityRecon. ISNULL(,0). (Tier 2 — SP_JPMRecon) |
| 11 | JP-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(JP_Units,0) − ISNULL(eToro_Units,0)`. Non-zero = trade recon break. (Tier 2 — SP_JPMRecon) |
| 12 | JP-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(JP_Units,0) − ISNULL(Clients_Units,0)`. JPM vs client NOP comparison. (Tier 2 — SP_JPMRecon) |
| 13 | JP_Rate | decimal(16,6) | YES | JPM's average execution price in local currency from LP_JPM_ETORO_*_Trade_Summary. (Tier 2 — SP_JPMRecon) |
| 14 | eToro_Rate | decimal(16,6) | YES | eToro's average execution rate. AVG(eToro_Rate) from Dealing_Duco_ActivityRecon. GBX ÷100. (Tier 2 — SP_JPMRecon) |
| 15 | JP-eToro_Rate | decimal(16,6) | YES | `ISNULL(JP_Rate,0) − ISNULL(eToro_Rate,0)`. Execution price discrepancy. (Tier 2 — SP_JPMRecon) |
| 16 | JP_LocalAmount | money | YES | JPM's notional trade value in local currency. From LP_JPM_ETORO_*_Trade_Summary. ISNULL(,0). (Tier 2 — SP_JPMRecon) |
| 17 | eToro_LocalAmount | money | YES | eToro's local currency trade amount from Dealing_Duco_ActivityRecon.eToroLocalAmount. GBX ÷100. (Tier 2 — SP_JPMRecon) |
| 18 | JP-eToro_LocalAmount | money | YES | `ISNULL(JP_LocalAmount,0) − ISNULL(eToro_LocalAmount,0)`. Local currency trade break. (Tier 2 — SP_JPMRecon) |
| 19 | JP_AmountUSD | money | YES | JPM's notional trade value in USD from LP_JPM_ETORO_*_Trade_Summary. ISNULL(,0). (Tier 2 — SP_JPMRecon) |
| 20 | eToro_AmountUSD | money | YES | eToro's USD trade amount from Dealing_Duco_ActivityRecon.eToroUSDAmount. (Tier 2 — SP_JPMRecon) |
| 21 | Clients_AmountUSD | money | YES | Aggregated client trade amount in USD from Dealing_Duco_ActivityRecon.ClientAmount. (Tier 2 — SP_JPMRecon) |
| 22 | JP-eToro_AmountUSD | money | YES | `ISNULL(JP_AmountUSD,0) − ISNULL(eToro_AmountUSD,0)`. USD trade break. (Tier 2 — SP_JPMRecon) |
| 23 | JP-Clients_AmountUSD | money | YES | `ISNULL(JP_AmountUSD,0) − ISNULL(Clients_AmountUSD,0)`. USD break vs client NOP. (Tier 2 — SP_JPMRecon) |
| 24 | JP_FXRate | decimal(16,6) | YES | JPM's FX rate (local → USD). MAX(FX_Rate) from LP_JPM_EOD_eToro_Report_FXRates joined on Currency. (Tier 2 — SP_JPMRecon) |
| 25 | eToro_FXRate | decimal(16,6) | YES | eToro's FX rate from Dealing_Duco_ActivityRecon.FXratetoUSD. (Tier 2 — SP_JPMRecon) |
| 26 | Total_Commission_USD | money | YES | JPM commission on the trade in USD. Commission amount from JP trade summary × FX rate. (Tier 2 — SP_JPMRecon) |
| 27 | Exchange | varchar(80) | YES | Trading venue. From eToro side (Dealing_Duco_ActivityRecon.Exchange). ISNULL(eToro, 0). (Tier 2 — SP_JPMRecon) |
| 28 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_JPMRecon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| JP_Units | LP_JPM_ETORO_NA/EMEA/ASIA_Trade_Summary | SUM, UNION across 3 regions |
| JP_Rate | LP_JPM_ETORO_*_Trade_Summary | Weighted avg or direct price |
| JP_LocalAmount | LP_JPM_ETORO_*_Trade_Summary | SUM |
| JP_AmountUSD | LP_JPM_ETORO_*_Trade_Summary | SUM |
| Total_Commission_USD | LP_JPM_ETORO_*_Trade_Summary + FX | Commission × FXRate |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM, JPM HS filter |
| eToro_LocalAmount | Dealing_Duco_ActivityRecon.eToroLocalAmount | GBX ÷100 |
| eToro_AmountUSD | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough |
| Diff columns | Computed | ISNULL(JP,0)−ISNULL(eToro,0) |

### 5.2 ETL Pipeline

```
JPM Trade Summary (NA + EMEA + ASIA) → UNION → JP trade side
  +
Dealing_Duco_ActivityRecon (eToro activity, JPM HS filter: 2,8,22,9,121,110,129,319)
  → SP_JPMRecon (FULL OUTER JOIN on ISINCode + CurrencyPrimary + Buy/Sell)
  → Dealing_JPMReconTrades (DELETE-INSERT by Date)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| (Date + ISINCode) | Dealing_Duco_ActivityRecon | eToro trade activity source |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_JPMReconEODHolding | Same SP | EOD holdings companion — same writer |

---

## 7. Sample Queries

### 7.1 Trade breaks on latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, [Buy/Sell],
  JP_Units, eToro_Units, [JP-eToro_Units], [JP-eToro_AmountUSD]
FROM Dealing_dbo.Dealing_JPMReconTrades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_JPMReconTrades)
  AND ABS([JP-eToro_Units]) > 0
ORDER BY ABS([JP-eToro_AmountUSD]) DESC
```

### 7.2 Total commission by instrument for latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName,
  SUM(Total_Commission_USD) AS Total_Commission_USD
FROM Dealing_dbo.Dealing_JPMReconTrades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_JPMReconTrades)
  AND Total_Commission_USD <> 0
GROUP BY Date, InstrumentID, InstrumentDisplayName
ORDER BY SUM(Total_Commission_USD) DESC
```

### 7.3 Net traded volume by instrument (JP side vs eToro side)
```sql
SELECT Date, InstrumentID, InstrumentDisplayName,
  SUM(CASE WHEN [Buy/Sell]='Buy' THEN JP_Units ELSE -JP_Units END) AS Net_JP_Units,
  SUM(CASE WHEN [Buy/Sell]='Buy' THEN eToro_Units ELSE -eToro_Units END) AS Net_eToro_Units
FROM Dealing_dbo.Dealing_JPMReconTrades
WHERE Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY Date, InstrumentID, InstrumentDisplayName
ORDER BY Date DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
