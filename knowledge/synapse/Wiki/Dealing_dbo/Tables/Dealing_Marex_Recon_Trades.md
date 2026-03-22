# Dealing_dbo.Dealing_Marex_Recon_Trades

> Daily trade activity reconciliation comparing Marex's executed trade volume against eToro's internal dealing records by contract, surfacing unit and value discrepancies in both local currency and USD.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | CopyFromLake.etoro_Hedge_ExecutionLog (Marex trades) + Dealing_Duco_ActivityRecon |
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

Companion table to `Dealing_Marex_Recon_EODHoldings`, covering the **trade activity** dimension of the Marex reconciliation. Each row represents one Contract × LiquidityAccountID combination for a given date, comparing Marex's reported executed trade volume against eToro's internal trade records.

The column structure is identical to `Dealing_Marex_Recon_EODHoldings` — same instrument identifiers, account metadata, amount breakdowns, and diff columns. Unlike IG/Vision trades tables, there is **no direction column** (no Buy/Sell or IsBuy) — trades are aggregated at the contract level without direction split.

Marex trade data is sourced from `CopyFromLake.etoro_Hedge_ExecutionLog` (eToro's execution log for Marex-routed trades) rather than a dedicated LP trade file. eToro activity from `Dealing_Duco_ActivityRecon`. Same SP writer as EOD holdings (`SP_Marex_Recon`). DELETE-INSERT by Date.

---

## 2. Business Logic

### 2.1 No Direction Split

**What**: Unlike IG and Vision trade tables, Marex trades are not split by Buy/Sell direction.

**Columns involved**: `Marex_Units`, `eToro_Units`

**Rules**:
- `Marex_Units` represents net or gross trade volume depending on SP aggregation
- No `IsBuy` or `Buy/Sell` column — direction analysis requires joining to source execution log
- `Marex-eToro_Units` reflects the net discrepancy regardless of direction

### 2.2 Contract-to-Instrument Mapping

**What**: Same mapping logic as EODHoldings.

**Rules**:
- InstrumentID resolved via `External_Bronze_Fivetran_google_sheets_marex_mapping_table`
- Contracts with no mapping will have NULL InstrumentID

### 2.3 Reconciliation Diff Columns

**What**: Full local and USD diff breakdown.

**Rules**:
- `Marex-eToro_Units` = `ISNULL(Marex_Units,0) − ISNULL(eToro_Units,0)`
- `Marex-eToro_LocalAmount` = `ISNULL(Marex_LocalAmount,0) − ISNULL(eToroLocalAmount,0)`
- `Marex-eToro_USDAmount` = `ISNULL(Marex_AmountUSD,0) − ISNULL(eToroUSDAmount,0)`
- `Marex-Clients_Units` and `Marex-Clients_USDAmount` compare Marex trades to client flow

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. Filter on Date first; add `InstrumentID` or `Contract` filters.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Filter on `Date` for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Trade breaks for a date | `WHERE Date=@d AND [Marex-eToro_Units]<>0` |
| Breaks by LP account | `GROUP BY Date, LiquidityAccountID, InstrumentID` |
| Unmapped contracts | `WHERE InstrumentID IS NULL AND Marex_Units<>0` |
| Cross-check with EOD | JOIN to Dealing_Marex_Recon_EODHoldings on Date + InstrumentID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata |
| Dealing_Marex_Recon_EODHoldings | Date + InstrumentID | Compare trade flow with EOD position |
| Dealing_Duco_ActivityRecon | Date + HedgeServerID | Trace eToro-side source trades |

### 3.4 Gotchas

- **No direction column**: Cannot split by Buy/Sell within this table — use source execution logs for directional analysis
- **Same column structure as EODHoldings**: Queries referencing column names are interchangeable, but semantic meaning differs (flow vs snapshot)
- **NULL InstrumentID for unmapped contracts**: Same issue as EODHoldings — filter `InstrumentID IS NOT NULL` for instrument-dimension analysis
- **Column `Currency` not `CurrencyPrimary`**: Same naming as EODHoldings counterpart

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_Marex_Recon)` |
| ★★ | Tier 3 — DDL/live | `(Tier 3 — DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trade date. SP parameter; DELETE-INSERT by Date. Converted via DateToDateID() UDF. (Tier 2 — SP_Marex_Recon) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. Resolved via External_Bronze_Fivetran_google_sheets_marex_mapping_table. May be NULL for unmapped contracts. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_Marex_Recon) |
| 3 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. Prefer eToro naming; fall back to Marex ContractName. (Tier 2 — SP_Marex_Recon) |
| 4 | Symbol | varchar(50) | YES | Ticker symbol from eToro side. (Tier 2 — SP_Marex_Recon) |
| 5 | ISINCode | varchar(20) | YES | ISIN code. From Dim_Instrument. (Tier 2 — SP_Marex_Recon) |
| 6 | CUSIP | varchar(20) | YES | CUSIP identifier. From Dim_Instrument. (Tier 2 — SP_Marex_Recon) |
| 7 | Currency | varchar(10) | YES | Instrument local currency. Named `Currency` (not `CurrencyPrimary`). (Tier 2 — SP_Marex_Recon) |
| 8 | Exchange | varchar(50) | YES | Trading venue. From eToro side. (Tier 2 — SP_Marex_Recon) |
| 9 | LiquidityAccountID | int | YES | eToro's LP account identifier. From Fivetran LP='Marex' mapping. (Tier 2 — SP_Marex_Recon) |
| 10 | HedgeServerID | int | YES | eToro hedge server. From Dealing_Duco_ActivityRecon via LiquidityAccountID mapping. NULL for Marex-only rows. (Tier 2 — SP_Marex_Recon) |
| 11 | Account | varchar(30) | YES | Marex LP account code. From execution log / trade source. (Tier 2 — SP_Marex_Recon) |
| 12 | Contract | varchar(10) | YES | Marex contract code. Used to resolve InstrumentID via mapping table. (Tier 2 — SP_Marex_Recon) |
| 13 | ContractName | varchar(100) | YES | Marex contract description. (Tier 2 — SP_Marex_Recon) |
| 14 | eToro_Units | decimal(16,6) | YES | eToro's executed trade volume. From Dealing_Duco_ActivityRecon for Marex HS. ISNULL(,0). (Tier 2 — SP_Marex_Recon) |
| 15 | eToroLocalAmount | money | YES | eToro's local currency trade amount. From Dealing_Duco_ActivityRecon. (Tier 2 — SP_Marex_Recon) |
| 16 | eToroUSDAmount | money | YES | eToro's USD trade amount. From Dealing_Duco_ActivityRecon. (Tier 2 — SP_Marex_Recon) |
| 17 | eToroRate | decimal(16,6) | YES | eToro's average execution rate. From Dealing_Duco_ActivityRecon. (Tier 2 — SP_Marex_Recon) |
| 18 | eToro_FX | decimal(16,6) | YES | eToro's FX rate (local → USD). From Dealing_Duco_ActivityRecon. (Tier 2 — SP_Marex_Recon) |
| 19 | Marex_Units | decimal(16,6) | YES | Marex's executed trade volume. From CopyFromLake.etoro_Hedge_ExecutionLog. ISNULL(,0). (Tier 2 — SP_Marex_Recon) |
| 20 | Marex_LocalAmount | money | YES | Marex's notional trade value in local currency. From execution log. (Tier 2 — SP_Marex_Recon) |
| 21 | Marex_AmountUSD | money | YES | Marex's notional trade value in USD. From execution log. (Tier 2 — SP_Marex_Recon) |
| 22 | Marex_FX | decimal(16,6) | YES | Marex's FX rate. From execution log. (Tier 2 — SP_Marex_Recon) |
| 23 | ClientUnits | decimal(16,6) | YES | Aggregated client trade volume. SUM(ClientUnits) from Dealing_Duco_ActivityRecon. ISNULL(,0). (Tier 2 — SP_Marex_Recon) |
| 24 | ClientsLocalAmount | money | YES | Aggregated client trade value in local currency. From Dealing_Duco_ActivityRecon. (Tier 2 — SP_Marex_Recon) |
| 25 | ClientsUSDAmount | money | YES | Aggregated client trade value in USD. From Dealing_Duco_ActivityRecon.ClientAmount. (Tier 2 — SP_Marex_Recon) |
| 26 | Marex-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Marex_Units,0) − ISNULL(eToro_Units,0)`. Non-zero = trade recon break. (Tier 2 — SP_Marex_Recon) |
| 27 | Marex-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Marex_Units,0) − ISNULL(ClientUnits,0)`. Marex vs client flow. (Tier 2 — SP_Marex_Recon) |
| 28 | Marex-eToro_LocalAmount | money | YES | `ISNULL(Marex_LocalAmount,0) − ISNULL(eToroLocalAmount,0)`. Local currency trade break. (Tier 2 — SP_Marex_Recon) |
| 29 | Marex-eToro_USDAmount | money | YES | `ISNULL(Marex_AmountUSD,0) − ISNULL(eToroUSDAmount,0)`. USD trade break. (Tier 2 — SP_Marex_Recon) |
| 30 | Marex-Clients_USDAmount | money | YES | `ISNULL(Marex_AmountUSD,0) − ISNULL(ClientsUSDAmount,0)`. USD break vs client flow. (Tier 2 — SP_Marex_Recon) |
| 31 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_Marex_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| Marex_Units | CopyFromLake.etoro_Hedge_ExecutionLog | SUM by Contract+Account; ISNULL(,0) |
| Marex_LocalAmount | CopyFromLake.etoro_Hedge_ExecutionLog | Notional local |
| Marex_AmountUSD | CopyFromLake.etoro_Hedge_ExecutionLog | Notional USD |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM, Marex HS filter |
| eToroUSDAmount | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough |
| ClientUnits | Dealing_Duco_ActivityRecon.ClientUnits | SUM |
| ClientsUSDAmount | Dealing_Duco_ActivityRecon.ClientAmount | Passthrough |
| InstrumentID | External_Bronze_Fivetran_google_sheets_marex_mapping_table | Contract → InstrumentID |
| Diff columns | Computed | ISNULL(Marex,0)−ISNULL(eToro/Clients,0) |

### 5.2 ETL Pipeline

```
CopyFromLake.etoro_Hedge_ExecutionLog (Marex execution log)
  +
External_Bronze_Fivetran_google_sheets_marex_mapping_table (contract→instrument)
  +
Dealing_Duco_ActivityRecon (eToro activity, Marex HS filter)
  → SP_Marex_Recon (JOIN on Contract + LiquidityAccountID)
  → Dealing_Marex_Recon_Trades (DELETE-INSERT by Date)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| Contract | External_Bronze_Fivetran_google_sheets_marex_mapping_table | Contract→InstrumentID mapping |
| (Date + HedgeServerID) | Dealing_Duco_ActivityRecon | eToro trade activity source |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_Marex_Recon_EODHoldings | Same SP | EOD holdings companion — same writer |

---

## 7. Sample Queries

### 7.1 Trade breaks on latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, Contract, LiquidityAccountID,
  Marex_Units, eToro_Units, [Marex-eToro_Units], [Marex-eToro_USDAmount]
FROM Dealing_dbo.Dealing_Marex_Recon_Trades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_Trades)
  AND ABS([Marex-eToro_Units]) > 0
ORDER BY ABS([Marex-eToro_USDAmount]) DESC
```

### 7.2 Net daily traded volume by instrument (eToro side)
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, SUM(eToro_Units) AS Total_eToro_Units
FROM Dealing_dbo.Dealing_Marex_Recon_Trades
WHERE Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY Date, InstrumentID, InstrumentDisplayName
ORDER BY Date DESC
```

### 7.3 Unmapped contracts with trade activity
```sql
SELECT DISTINCT Contract, ContractName, Date, SUM(ABS(Marex_Units)) AS Traded_Units
FROM Dealing_dbo.Dealing_Marex_Recon_Trades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_Trades)
  AND InstrumentID IS NULL AND Marex_Units <> 0
GROUP BY Contract, ContractName, Date
ORDER BY Traded_Units DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.3/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
