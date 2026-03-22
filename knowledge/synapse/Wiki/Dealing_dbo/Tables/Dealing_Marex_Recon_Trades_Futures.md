# Dealing_dbo.Dealing_Marex_Recon_Trades_Futures

> Daily futures trade activity reconciliation comparing Marex's executed trade volume against both eToro's internal dealing records and client trade flow, with lot-based, unit, and USD breakdowns, ADJ-adjusted rates, and execution-level metadata.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Marex futures trade feed + Dealing_Duco_ActivityRecon + etoro_Hedge client data |
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

Futures-specific trade activity reconciliation for Marex. Added in May 2025. Each row represents one futures execution at CID × OrderID × IsBuy × IsOpen granularity. This is the most granular LP recon table in Dealing_dbo: it stores individual execution identifiers (`ExecutionID`), commission per trade, and a 3-way comparison: Marex traded volume vs eToro's internal records vs client trade flow.

Unlike `Dealing_Marex_Recon_EODHoldings_Futures` (which only compares Marex vs Clients), this table adds `eToro_Units` and `Marex-eToro_*` diff columns — enabling a full three-way recon check at trade level.

Column names for several Marex-sourced fields use all-caps with spaces (`CHIT NUMBER`, `MULTIPLICATION FACTOR`, `LST TRD DATE`, `CURRENCY SYMBOL`), reflecting direct pass-through from Marex's LP trade file without column renaming.

`eToroRate_AfterADJ` is an additional ADJ column specific to the trades table (not in EODHoldings). Written by `SP_Marex_Recon`. DELETE-INSERT by Date.

---

## 2. Business Logic

### 2.1 Three-Way Reconciliation

**What**: Trades table reconciles three parties simultaneously — Marex, eToro, and Clients.

**Columns involved**: `Marex_Units`, `eToro_Units`, `ClientUnits`; both `Marex-Clients_*` and `Marex-eToro_*` diff sets

**Rules**:
- `Marex-Clients_Units` = `ISNULL(Marex_Units,0) − ISNULL(ClientUnits,0)`
- `Marex-eToro_Units` = `ISNULL(Marex_Units,0) − ISNULL(eToro_Units,0)`
- Both sets of diffs are present; use `Marex-Clients_*` for client-to-LP recon, `Marex-eToro_*` for hedge-to-LP recon

### 2.2 IsOpen Flag

**What**: Distinguishes between opening and closing trades.

**Columns involved**: `IsOpen`, `eToro_Units`, `Marex_Units`

**Rules**:
- `IsOpen = 1` → opening trade (new position); `IsOpen = 0` → closing trade (existing position exit)
- Both opening and closing trades are present in the same table

### 2.3 ADJ Adjustments

**What**: Rate adjustments applied post-execution.

**Columns involved**: `ForexRate_AfterADJ`, `ADJ_Value`, `eToroRate_AfterADJ`

**Rules**:
- `ForexRate_AfterADJ` = Marex FX rate after ADJ adjustment
- `eToroRate_AfterADJ` = eToro execution rate after ADJ adjustment (unique to trades, not in EODHoldings)
- `ADJ_Value` = the adjustment factor
- NULL for trades before July 2025

### 2.4 Legacy Column Names

**What**: Several Marex-sourced columns use all-caps with spaces.

**Rules**:
- `CHIT NUMBER` = Marex trade reference number
- `MULTIPLICATION FACTOR` = contract multiplier (same as `MultiplicationFactor` in EODHoldings)
- `LST TRD DATE` = last trading day as integer (same as `LastTradingDay` in EODHoldings)
- `CURRENCY SYMBOL` = currency symbol
- Must be quoted with brackets in SQL: `[CHIT NUMBER]`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. Filter on Date and `InstrumentID` or `ExecutionID`. High cardinality due to CID + execution granularity.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Filter on `Date` for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Trade breaks (Marex vs eToro) | `WHERE Date=@d AND [Marex-eToro_Units]<>0` |
| Trade breaks (Marex vs Clients) | `WHERE Date=@d AND [Marex-Clients_Units]<>0` |
| Open vs Close split | `GROUP BY Date, InstrumentID, IsBuy, IsOpen` |
| Commission by instrument | `GROUP BY Date, InstrumentID, SUM(Commission)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata |
| Dealing_Marex_Recon_EODHoldings_Futures | Date + InstrumentID + CID | Compare trade flow with EOD positions |
| DWH_dbo.Dim_Customer | CID | Client details |

### 3.4 Gotchas

- **Column names with spaces**: `[CHIT NUMBER]`, `[MULTIPLICATION FACTOR]`, `[LST TRD DATE]`, `[CURRENCY SYMBOL]` must be bracket-quoted in all SQL
- **ADJ columns NULL pre-July 2025**: `ForexRate_AfterADJ`, `ADJ_Value`, `eToroRate_AfterADJ` are NULL for all rows before July 2025
- **ExecutionID granularity**: This table may have multiple rows per CID per date (one per execution) — aggregate for totals
- **IsOpen semantics**: Closing trades (IsOpen=0) appear with negative or offsetting units; sum must net correctly

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_Marex_Recon)` |
| ★★ | Tier 3 — DDL/live | `(Tier 3 — DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trade date. SP parameter; DELETE-INSERT by Date. (Tier 2 — SP_Marex_Recon) |
| 2 | PositionID | bigint | YES | Marex position identifier. Links execution to parent position. (Tier 2 — SP_Marex_Recon) |
| 3 | CID | int | YES | eToro client identifier. Execution-level client granularity. FK → DWH_dbo.Dim_Customer. (Tier 2 — SP_Marex_Recon) |
| 4 | HedgeServerID | int | YES | eToro hedge server. From eToro side data for Marex futures HS. NULL for Marex-only rows. (Tier 2 — SP_Marex_Recon) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. Resolved from contract code. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_Marex_Recon) |
| 6 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. (Tier 2 — SP_Marex_Recon) |
| 7 | Exchange | varchar(50) | YES | Futures exchange venue. (Tier 2 — SP_Marex_Recon) |
| 8 | Symbol | varchar(50) | YES | Ticker symbol. (Tier 2 — SP_Marex_Recon) |
| 9 | SellCurrency | varchar(10) | YES | Settlement/P&L currency of the futures contract. (Tier 2 — SP_Marex_Recon) |
| 10 | IsBuy | bit | YES | Trade direction: 1=Buy/Open Long, 0=Sell/Open Short. (Tier 2 — SP_Marex_Recon) |
| 11 | IsOpen | bit | YES | Trade type: 1=Opening trade, 0=Closing trade. (Tier 2 — SP_Marex_Recon) |
| 12 | OrderID | int | YES | Marex order identifier. (Tier 2 — SP_Marex_Recon) |
| 13 | ConversionRate | decimal(16,6) | YES | eToro's FX conversion rate for the currency pair. (Tier 2 — SP_Marex_Recon) |
| 14 | Clients_Lots | int | YES | Client's executed lot count. From eToro client trade data. (Tier 2 — SP_Marex_Recon) |
| 15 | Marex_Lots | int | YES | Marex's executed lot count. From Marex trade file. (Tier 2 — SP_Marex_Recon) |
| 16 | Marex_Price | decimal(16,6) | YES | Marex execution price per unit/lot. From Marex trade file. (Tier 2 — SP_Marex_Recon) |
| 17 | ForexRate | decimal(16,6) | YES | Raw FX rate from Marex (pre-ADJ). (Tier 2 — SP_Marex_Recon) |
| 18 | ACCOUNT | varchar(25) | YES | Marex LP account code. All-caps column name from LP file. (Tier 2 — SP_Marex_Recon) |
| 19 | CURRENCY SYMBOL | varchar(10) | YES | Currency symbol. All-caps with space; direct from Marex LP file. Must be quoted: `[CURRENCY SYMBOL]`. (Tier 2 — SP_Marex_Recon) |
| 20 | CHIT NUMBER | varchar(200) | YES | Marex trade reference number. All-caps with space. Must be quoted: `[CHIT NUMBER]`. (Tier 2 — SP_Marex_Recon) |
| 21 | ExecutionID | bigint | YES | Unique execution identifier. Granularity key — one execution per row. (Tier 2 — SP_Marex_Recon) |
| 22 | MULTIPLICATION FACTOR | int | YES | Futures contract multiplier (units per lot). All-caps with space. Must be quoted. (Tier 2 — SP_Marex_Recon) |
| 23 | LST TRD DATE | int | YES | Last trading day (expiry) as integer DateID. All-caps with space. Must be quoted. (Tier 2 — SP_Marex_Recon) |
| 24 | Commission | decimal(16,6) | YES | Marex commission charged on this execution. (Tier 2 — SP_Marex_Recon) |
| 25 | ClientUnits | decimal(16,6) | YES | Client's executed units (= Clients_Lots × MULTIPLICATION FACTOR). (Tier 2 — SP_Marex_Recon) |
| 26 | Marex_Units | decimal(16,6) | YES | Marex's executed units. From Marex trade file. ISNULL(,0). (Tier 2 — SP_Marex_Recon) |
| 27 | eToro_Units | decimal(16,6) | YES | eToro's internally recorded executed units. From Dealing_Duco_ActivityRecon for Marex futures HS. ISNULL(,0). (Tier 2 — SP_Marex_Recon) |
| 28 | eToroRate | decimal(16,6) | YES | eToro's execution rate. From Dealing_Duco_ActivityRecon. (Tier 2 — SP_Marex_Recon) |
| 29 | ClientsLocalAmount | money | YES | Client trade value in local currency. (Tier 2 — SP_Marex_Recon) |
| 30 | Marex_LocalAmount | money | YES | Marex trade notional in local currency. (Tier 2 — SP_Marex_Recon) |
| 31 | eToroLocalAmount | money | YES | eToro's local currency trade amount from Dealing_Duco_ActivityRecon. (Tier 2 — SP_Marex_Recon) |
| 32 | ClientsUSDAmount | money | YES | Client trade value in USD. (Tier 2 — SP_Marex_Recon) |
| 33 | eToroUSDAmount | money | YES | eToro's USD trade amount from Dealing_Duco_ActivityRecon. (Tier 2 — SP_Marex_Recon) |
| 34 | Marex_USDAmount | money | YES | Marex trade notional in USD. Note: named `Marex_USDAmount` not `Marex_AmountUSD`. (Tier 2 — SP_Marex_Recon) |
| 35 | Marex-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Marex_Units,0) − ISNULL(ClientUnits,0)`. Marex vs client trade break. (Tier 2 — SP_Marex_Recon) |
| 36 | Marex-Clients_USDAmount | money | YES | **Recon diff**: `ISNULL(Marex_USDAmount,0) − ISNULL(ClientsUSDAmount,0)`. USD trade break vs clients. (Tier 2 — SP_Marex_Recon) |
| 37 | Marex-Clients_Lots | decimal(16,6) | YES | **Recon diff**: `Marex_Lots − Clients_Lots`. Lot-level trade break vs clients. (Tier 2 — SP_Marex_Recon) |
| 38 | Marex-Clients_Price | decimal(16,6) | YES | **Recon diff**: `Marex_Price − Client entry price`. Execution price discrepancy vs clients. (Tier 2 — SP_Marex_Recon) |
| 39 | Marex-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Marex_Units,0) − ISNULL(eToro_Units,0)`. Marex vs eToro trade break. (Tier 2 — SP_Marex_Recon) |
| 40 | Marex-eToro_USDAmount | money | YES | **Recon diff**: `ISNULL(Marex_USDAmount,0) − ISNULL(eToroUSDAmount,0)`. USD trade break vs eToro. (Tier 2 — SP_Marex_Recon) |
| 41 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_Marex_Recon) |
| 42 | ForexRate_AfterADJ | decimal(16,6) | YES | Marex FX rate after ADJ adjustment (added Jul 2025). NULL for trades before July 2025. (Tier 2 — SP_Marex_Recon) |
| 43 | ADJ_Value | decimal(16,6) | YES | ADJ adjustment factor applied to FX rate (added Jul 2025). NULL for trades before July 2025. (Tier 2 — SP_Marex_Recon) |
| 44 | eToroRate_AfterADJ | decimal(16,6) | YES | eToro execution rate after ADJ adjustment (added Jul 2025). Unique to trades table (absent from EODHoldings). NULL for trades before July 2025. (Tier 2 — SP_Marex_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| ExecutionID, CHIT NUMBER, Marex_Lots, Marex_Price | Marex futures trade feed | Direct from Marex LP trade file |
| Marex_Units, Marex_LocalAmount, Marex_USDAmount | Marex futures trade feed | Units = Lots × multiplier |
| ForexRate, ForexRate_AfterADJ, ADJ_Value | Marex futures trade feed | FX metadata |
| Commission | Marex futures trade feed | Per-execution commission |
| ClientUnits, Clients_Lots, ClientsUSDAmount | etoro_Hedge client trade data | CID-level client trade flow |
| eToro_Units, eToroRate, eToroUSDAmount | Dealing_Duco_ActivityRecon | eToro hedge activity, Marex futures HS |
| eToroRate_AfterADJ | Dealing_Duco_ActivityRecon + ADJ | eToro rate after ADJ (added Jul 2025) |
| Diff columns | Computed | ISNULL(Marex,0)−ISNULL(eToro/Clients,0) |

### 5.2 ETL Pipeline

```
Marex Futures Trade File (LP feed, execution-level)
  +
etoro_Hedge client trade data (CID-level client executions)
  +
Dealing_Duco_ActivityRecon (eToro hedge activity, Marex futures HS)
  → SP_Marex_Recon (JOIN on ExecutionID / OrderID + CID)
  → Dealing_Marex_Recon_Trades_Futures (DELETE-INSERT by Date)
```

*Futures functionality added May 2025. ADJ columns (ForexRate_AfterADJ, ADJ_Value, eToroRate_AfterADJ) added Jul 2025.*

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| CID | DWH_dbo.Dim_Customer | Client details |
| (Date + HedgeServerID) | Dealing_Duco_ActivityRecon | eToro trade activity source |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_Marex_Recon_EODHoldings_Futures | Same SP | EOD holdings companion — same writer |

---

## 7. Sample Queries

### 7.1 Trade breaks (Marex vs eToro) on latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, CID, IsBuy, IsOpen,
  Marex_Units, eToro_Units, [Marex-eToro_Units], [Marex-eToro_USDAmount]
FROM Dealing_dbo.Dealing_Marex_Recon_Trades_Futures
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_Trades_Futures)
  AND ABS([Marex-eToro_Units]) > 0
ORDER BY ABS([Marex-eToro_USDAmount]) DESC
```

### 7.2 Commission summary by instrument for latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName,
  SUM(Commission) AS Total_Commission,
  SUM(Marex_Units) AS Total_Marex_Units
FROM Dealing_dbo.Dealing_Marex_Recon_Trades_Futures
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_Trades_Futures)
GROUP BY Date, InstrumentID, InstrumentDisplayName
ORDER BY SUM(Commission) DESC
```

### 7.3 Open vs close trade volume split
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, IsBuy, IsOpen,
  SUM(Marex_Lots) AS Total_Lots, SUM(Marex_USDAmount) AS Total_USD
FROM Dealing_dbo.Dealing_Marex_Recon_Trades_Futures
WHERE Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY Date, InstrumentID, InstrumentDisplayName, IsBuy, IsOpen
ORDER BY Date DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.0/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
