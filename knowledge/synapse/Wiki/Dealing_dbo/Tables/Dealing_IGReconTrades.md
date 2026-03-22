# Dealing_dbo.Dealing_IGReconTrades

> Daily trade activity reconciliation comparing IG's executed order history against eToro's internal dealing records by instrument and direction, surfacing unit and value discrepancies.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | LP_IG_OH_OrderHistory (IG trade feed) + Dealing_Duco_ActivityRecon |
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

Companion table to `Dealing_IGReconEODHolding`, covering the **trade activity** dimension of the IG reconciliation. Each row represents one instrument × direction (Buy/Sell) × IG account combination for a given date, comparing IG's reported executed order volume against eToro's internal trade records from `Dealing_Duco_ActivityRecon`.

Where `Dealing_IGReconEODHolding` shows end-of-day position snapshots, this table shows intraday trade flows. Non-zero `IG-eToro_*` values indicate trades that appear on IG's books but not eToro's (or vice versa), which can flag execution reporting failures, settlement mismatches, or LP-side rounding differences.

Same SP as EOD holdings (`SP_IGRecon`, Gili Goldbaum, 2023-12-28). IG trades sourced from `LP_IG_OH_OrderHistory` (order history parquet). eToro trades from `Dealing_Duco_ActivityRecon`. Same weekend logic applies (Saturday skip, Sunday → Friday). DELETE-INSERT by Date.

---

## 2. Business Logic

### 2.1 Trade Direction Encoding

**What**: Trades are broken down by Buy/Sell direction.

**Columns involved**: `Buy/Sell`, `IG_Units`, `eToro_Units`

**Rules**:
- `Buy/Sell` = 'Buy' or 'Sell' (from `CASE WHEN [Deal Size] < 0 THEN 'Sell' ELSE 'Buy'`)
- `IG_Units` = `SUM(ABS([Deal Size]) × [Lot Size] × (±1))` from `LP_IG_OH_OrderHistory`, filtered to `Result NOT LIKE '%Rejected:%'`
- Oil multiplier (×100) applied on IG side
- GBX normalisation (÷100) applied on eToro side

### 2.2 Reconciliation Diff Columns

**What**: `{LP}-{side}_*` columns show arithmetic difference between LP and eToro sides.

**Rules**:
- Formula: `ISNULL(IG_value, 0) − ISNULL(eToro_value, 0)`
- Non-zero = trade recon break

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. Filter on Date first; add InstrumentID or direction filters to narrow results.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Filter on `Date` for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Trade breaks for a date | `WHERE Date = @d AND [IG-eToro_Units] <> 0` |
| Buy vs Sell volume comparison | `GROUP BY Date, InstrumentID, [Buy/Sell]` |
| Reconcile against EOD holdings | JOIN to Dealing_IGReconEODHolding on Date + InstrumentID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata |
| Dealing_IGReconEODHolding | Date + InstrumentID | Pair trade recon with EOD holdings |
| Dealing_Duco_ActivityRecon | Date + HedgeServerID | Trace eToro-side source trades |

### 3.4 Gotchas

- **Rejected trades excluded**: IG side filters `Result NOT LIKE '%Rejected:%'` — rejected orders are not included
- **Oil multiplier and GBX normalization**: Same adjustments as EOD holdings table apply
- **FULL OUTER JOIN rows**: NULL HedgeServerID = IG-only trade; NULL Account_Number = eToro-only trade

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_IGRecon)` |
| ★★ | Tier 3 — live data / DDL | `(Tier 3 — DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trade date (same weekend adjustment as EOD: Saturday skip, Sunday→Friday). (Tier 2 — SP_IGRecon) |
| 2 | HedgeServerID | int | YES | eToro hedge server for the IG LP. From Fivetran mapping (`liquidity_provider='IG'`). NULL for IG-only trades. (Tier 2 — SP_IGRecon) |
| 3 | Account_Number | varchar(50) | YES | IG account number (`LP_IG_OH_OrderHistory.[Account ID]`). NULL for eToro-only trades. (Tier 2 — SP_IGRecon) |
| 4 | InstrumentID | int | YES | eToro instrument identifier. Resolved via #MarketNameToID or ISIN join. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_IGRecon) |
| 5 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. ISNULL(eToro_side, IG_side). (Tier 2 — SP_IGRecon) |
| 6 | Symbol | varchar(250) | YES | Ticker symbol. From eToro side. (Tier 2 — SP_IGRecon) |
| 7 | ISINCode | varchar(30) | YES | ISIN. ISNULL(eToro_side, IG_side). (Tier 2 — SP_IGRecon) |
| 8 | Buy/Sell | varchar(100) | YES | Trade direction: 'Buy' or 'Sell'. Derived from IG: `CASE WHEN [Deal Size] < 0 THEN 'Sell' ELSE 'Buy'`. From eToro: Dealing_Duco_ActivityRecon.[Buy/Sell]. (Tier 2 — SP_IGRecon) |
| 9 | CurrencyPrimary | varchar(50) | YES | Instrument local currency. GBX normalised to GBP. ISNULL(eToro, IG). (Tier 2 — SP_IGRecon) |
| 10 | IG_Units | decimal(16,6) | YES | IG's executed trade volume. `SUM(ABS([Deal Size])×[Lot Size]×(±1))` from `LP_IG_OH_OrderHistory` where Result not rejected. Oil ×100. (Tier 2 — SP_IGRecon) |
| 11 | eToro_Units | decimal(16,6) | YES | eToro's executed trade volume. `SUM(eToro_Units)` from `Dealing_Duco_ActivityRecon` for IG HS. (Tier 2 — SP_IGRecon) |
| 12 | Clients_Units | decimal(16,6) | YES | Aggregated client trade volume. `SUM(ClientUnits)` from `Dealing_Duco_ActivityRecon`. (Tier 2 — SP_IGRecon) |
| 13 | IG-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(IG_Units,0) − ISNULL(eToro_Units,0)`. (Tier 2 — SP_IGRecon) |
| 14 | IG-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(IG_Units,0) − ISNULL(Clients_Units,0)`. (Tier 2 — SP_IGRecon) |
| 15 | IG_Rate | decimal(16,6) | YES | IG's average execution price. `SUM(ABS([Deal Level]×[Deal Size])×Lot) / SUM(ABS([Deal Size]))` from `LP_IG_OH_OrderHistory`. (Tier 2 — SP_IGRecon) |
| 16 | eToro_Rate | decimal(16,6) | YES | eToro's average execution rate. `AVG(eToro_Rate)` from `Dealing_Duco_ActivityRecon`. GBX ÷100. (Tier 2 — SP_IGRecon) |
| 17 | IG-eToro_Rate | decimal(16,6) | YES | `ISNULL(IG_Rate,0) − ISNULL(eToro_Rate,0)`. Execution price discrepancy. (Tier 2 — SP_IGRecon) |
| 18 | IG_LocalAmount | money | YES | IG's notional trade value in local currency. Computed from `[Deal Level] × [Deal Size] × [Lot Size]` (sign adjusted). Oil ×100. (Tier 2 — SP_IGRecon) |
| 19 | eToro_LocalAmount | money | YES | eToro's local currency trade amount from `Dealing_Duco_ActivityRecon.eToroLocalAmount`. GBX ÷100. (Tier 2 — SP_IGRecon) |
| 20 | IG-eToro_LocalAmount | money | YES | `ISNULL(IG,0) − ISNULL(eToro,0)`. Local currency trade break. (Tier 2 — SP_IGRecon) |
| 21 | IG_AmountUSD | money | YES | IG's notional trade value in USD. `IG_LocalAmount × MAX(FX_Rate)`. (Tier 2 — SP_IGRecon) |
| 22 | eToro_AmountUSD | money | YES | eToro's USD trade amount from `Dealing_Duco_ActivityRecon.eToroUSDAmount`. (Tier 2 — SP_IGRecon) |
| 23 | Clients_AmountUSD | money | YES | Aggregated client trade amount in USD from `Dealing_Duco_ActivityRecon.ClientAmount`. (Tier 2 — SP_IGRecon) |
| 24 | IG-eToro_AmountUSD | money | YES | `ISNULL(IG,0) − ISNULL(eToro,0)`. USD trade break. (Tier 2 — SP_IGRecon) |
| 25 | IG-Clients_AmountUSD | money | YES | `ISNULL(IG,0) − ISNULL(Clients,0)`. USD break vs client NOP. (Tier 2 — SP_IGRecon) |
| 26 | IG_FXRate | decimal(16,6) | YES | IG's FX rate for currency conversion. `MAX(IG_FXRate)` from `#IG_FXRates` derived from `LP_IG_PS_EODPositions.[Conversion Rate]`. (Tier 2 — SP_IGRecon) |
| 27 | eToro_FXRate | decimal(16,6) | YES | eToro's FX rate. `AVG(eToro_FX_Rate)` from `Dealing_Duco_ActivityRecon.FXratetoUSD`. (Tier 2 — SP_IGRecon) |
| 28 | Exchange | varchar(80) | YES | Trading venue. From eToro side (`Dealing_Duco_ActivityRecon.Exchange`). ISNULL(eToro, 0). (Tier 2 — SP_IGRecon) |
| 29 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_IGRecon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| IG_Units | LP_IG_OH_OrderHistory.[Deal Size] | SUM×LotSize; rejected excluded; Oil ×100 |
| IG_Rate | LP_IG_OH_OrderHistory.[Deal Level] | Weighted avg price |
| IG_LocalAmount | LP_IG_OH_OrderHistory | Notional = DealLevel×DealSize×LotSize |
| IG_AmountUSD | LP_IG_OH_OrderHistory + FX | LocalAmount × FXRate |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM, IG HS filter |
| eToro_LocalAmount | Dealing_Duco_ActivityRecon.eToroLocalAmount | GBX ÷100 |
| eToro_AmountUSD | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough |
| Diff columns | Computed | ISNULL(LP,0)−ISNULL(eToro,0) |

### 5.2 ETL Pipeline

```
LP IG Files (Order History Parquet) → LP_IG_OH_OrderHistory
  +
Dealing_Duco_ActivityRecon (eToro activity, IG HS filter)
  → SP_IGRecon (FULL OUTER JOIN on InstrumentID + AccountID + Direction)
  → Dealing_IGReconTrades (DELETE-INSERT by Date)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| HedgeServerID | Dealing_Duco_ActivityRecon | eToro trade source |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_IGReconEODHolding | Same SP | EOD holdings companion — same writer |

---

## 7. Sample Queries

### 7.1 Trade breaks on latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, [Buy/Sell],
  IG_Units, eToro_Units, [IG-eToro_Units], [IG-eToro_AmountUSD]
FROM Dealing_dbo.Dealing_IGReconTrades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_IGReconTrades)
  AND ABS([IG-eToro_Units]) > 0
ORDER BY ABS([IG-eToro_AmountUSD]) DESC
```

### 7.2 Net daily traded volume by instrument (eToro side)
```sql
SELECT Date, InstrumentID, InstrumentDisplayName,
  SUM(CASE WHEN [Buy/Sell]='Buy' THEN eToro_Units ELSE -eToro_Units END) AS Net_eToro_Units
FROM Dealing_dbo.Dealing_IGReconTrades
WHERE Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY Date, InstrumentID, InstrumentDisplayName
ORDER BY Date DESC
```

### 7.3 Rate discrepancy across instruments
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, [Buy/Sell],
  IG_Rate, eToro_Rate, [IG-eToro_Rate]
FROM Dealing_dbo.Dealing_IGReconTrades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_IGReconTrades)
  AND ABS([IG-eToro_Rate]) > 0.01
ORDER BY ABS([IG-eToro_Rate]) DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
