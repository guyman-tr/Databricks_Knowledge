# Dealing_dbo.Dealing_Marex_Recon_EODHoldings

> Daily end-of-day holdings reconciliation comparing Marex's custodian position for each CFD contract against eToro's internal hedge position and client NOP, with full local and USD amount breakdowns for both sides.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | LP_EdnF_CorePosition + LP_EdnF_CoreBalance + etoro_Hedge_Netting |
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

EOD holdings reconciliation for Marex (a derivatives/CFD clearing broker). Each row represents one Contract × LiquidityAccountID combination for a given date, comparing Marex's reported EOD position against eToro's internal hedge position (from `etoro_Hedge_Netting`) and aggregated client NOP.

This is the most structurally complex of the standard LP recon tables: it exposes `Contract` and `ContractName` (Marex's internal position identifiers), retains both `LiquidityAccountID` and `HedgeServerID` granularity, and provides local currency amounts for all three parties (eToro, Marex, and Clients). Both ISINCode and CUSIP are available.

The eToro side is sourced from `etoro_Hedge_Netting` / `History_Netting_History` (temporal netting config tables), mapped to InstrumentID via `External_Bronze_Fivetran_google_sheets_marex_mapping_table` (a Google Sheets-backed Fivetran table mapping Marex contract names to eToro instruments). Marex positions come from `LP_EdnF_CorePosition` (net position) and `LP_EdnF_CoreBalance`.

Written by `SP_Marex_Recon` (Dealing_dbo). DELETE-INSERT by Date. Uses `DateToDateID()` UDF for date conversion.

---

## 2. Business Logic

### 2.1 Contract-to-Instrument Mapping

**What**: Marex uses internal contract identifiers; eToro instruments are resolved via a Google Sheets mapping table.

**Columns involved**: `Contract`, `ContractName`, `InstrumentID`

**Rules**:
- `Contract` = Marex position contract code (e.g., futures ticker)
- `ContractName` = human-readable contract name from Marex
- `InstrumentID` resolved via `External_Bronze_Fivetran_google_sheets_marex_mapping_table` (Contract → InstrumentID)
- Contracts with no mapping will have NULL InstrumentID; these cannot be JOIN'd to `Dim_Instrument`

### 2.2 Temporal Netting Configuration

**What**: eToro hedge position uses temporally versioned netting config.

**Columns involved**: `eToro_Units`, `eToroLocalAmount`, `eToroUSDAmount`

**Rules**:
- eToro side sourced from `etoro_Hedge_Netting` (current config) and `History_Netting_History` (historical config)
- Correct netting record selected using date range logic (`ValidFrom` ≤ `@Date` < `ValidTo` or equivalent)
- Ensures position calculation uses the netting configuration that was active on the given date

### 2.3 Reconciliation Diff Columns

**What**: Standard LP-eToro diff pattern, with both local and USD breakdowns.

**Rules**:
- `Marex-eToro_Units` = `ISNULL(Marex_Units,0) − ISNULL(eToro_Units,0)`
- `Marex-eToro_LocalAmount` = `ISNULL(Marex_LocalAmount,0) − ISNULL(eToroLocalAmount,0)`
- `Marex-eToro_USDAmount` = `ISNULL(Marex_AmountUSD,0) − ISNULL(eToroUSDAmount,0)`
- `Marex-Clients_Units` and `Marex-Clients_USDAmount` compare Marex position to client NOP

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. Filter on Date first; add `InstrumentID` or `Contract` filters.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Filter on `Date` for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| EOD recon breaks | `WHERE Date=@d AND [Marex-eToro_Units]<>0` |
| Breaks by LP account | `GROUP BY Date, LiquidityAccountID, InstrumentID` |
| Unmapped contracts | `WHERE InstrumentID IS NULL AND Marex_Units<>0` |
| Marex-only positions | `WHERE Marex_Units<>0 AND eToro_Units=0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata (may be NULL for unmapped) |
| Dealing_Marex_Recon_Trades | Date + InstrumentID | Trade vs holdings reconciliation |
| Dealing_Duco_EODRecon | Date + HedgeServerID | Trace eToro-side source rows |

### 3.4 Gotchas

- **NULL InstrumentID for unmapped contracts**: Marex contracts not in the Google Sheets mapping table will have NULL InstrumentID — filter these separately when investigating unmapped positions
- **Google Sheets mapping table latency**: `External_Bronze_Fivetran_google_sheets_marex_mapping_table` is updated via Fivetran from a Google Sheet; new contracts may not be mapped immediately
- **Column name `Currency` not `CurrencyPrimary`**: Marex uses `Currency` as column name (not `CurrencyPrimary` like IG/JPM) — be careful with cross-LP queries
- **Temporal netting**: eToro units reflect the netting config active on the given date; comparing across dates may show structural jumps if netting config changed
- **Both ISINCode and CUSIP available**: Unlike Vision (CUSIP-only) or IG (ISIN-only), this table carries both identifiers

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_Marex_Recon)` |
| ★★ | Tier 3 — DDL/live | `(Tier 3 — DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | EOD snapshot date. SP parameter; DELETE-INSERT by Date. Converted via DateToDateID() UDF. (Tier 2 — SP_Marex_Recon) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. Resolved from External_Bronze_Fivetran_google_sheets_marex_mapping_table via Contract. May be NULL for unmapped contracts. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_Marex_Recon) |
| 3 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. From eToro side or Marex ContractName. (Tier 2 — SP_Marex_Recon) |
| 4 | Symbol | varchar(50) | YES | Ticker symbol from eToro side. (Tier 2 — SP_Marex_Recon) |
| 5 | ISINCode | varchar(20) | YES | ISIN code. From Dim_Instrument or Marex feed. (Tier 2 — SP_Marex_Recon) |
| 6 | CUSIP | varchar(20) | YES | CUSIP identifier. From Dim_Instrument or Marex feed. (Tier 2 — SP_Marex_Recon) |
| 7 | Currency | varchar(10) | YES | Instrument local currency. Note: column named `Currency`, not `CurrencyPrimary`. (Tier 2 — SP_Marex_Recon) |
| 8 | Exchange | varchar(50) | YES | Trading venue. From eToro side. (Tier 2 — SP_Marex_Recon) |
| 9 | LiquidityAccountID | int | YES | eToro's LP account identifier. From Fivetran LP='Marex' mapping. Primary LP account key. (Tier 2 — SP_Marex_Recon) |
| 10 | HedgeServerID | int | YES | eToro hedge server. From etoro_Hedge_Netting via LiquidityAccountID mapping. NULL for Marex-only rows. (Tier 2 — SP_Marex_Recon) |
| 11 | Account | varchar(30) | YES | Marex LP account name/code. From LP_EdnF_CorePosition or LP_EdnF_CoreBalance. (Tier 2 — SP_Marex_Recon) |
| 12 | Contract | varchar(10) | YES | Marex contract code (position identifier). Used to resolve InstrumentID via mapping table. (Tier 2 — SP_Marex_Recon) |
| 13 | ContractName | varchar(100) | YES | Marex contract human-readable name. From LP_EdnF_CorePosition. (Tier 2 — SP_Marex_Recon) |
| 14 | eToro_Units | decimal(16,6) | YES | eToro's internal hedge units. From etoro_Hedge_Netting / History_Netting_History (temporally versioned). ISNULL(,0). (Tier 2 — SP_Marex_Recon) |
| 15 | eToroLocalAmount | money | YES | eToro's local currency position value. From etoro_Hedge_Netting. (Tier 2 — SP_Marex_Recon) |
| 16 | eToroUSDAmount | money | YES | eToro's USD position value. From etoro_Hedge_Netting. (Tier 2 — SP_Marex_Recon) |
| 17 | eToroRate | decimal(16,6) | YES | eToro's closing price per unit. From etoro_Hedge_Netting. (Tier 2 — SP_Marex_Recon) |
| 18 | eToro_FX | decimal(16,6) | YES | eToro's FX rate (local → USD). From etoro_Hedge_Netting. (Tier 2 — SP_Marex_Recon) |
| 19 | Marex_Units | decimal(16,6) | YES | Marex's EOD position in units. From LP_EdnF_CorePosition. ISNULL(,0). (Tier 2 — SP_Marex_Recon) |
| 20 | Marex_LocalAmount | money | YES | Marex's position value in local currency. From LP_EdnF_CorePosition. (Tier 2 — SP_Marex_Recon) |
| 21 | Marex_AmountUSD | money | YES | Marex's position value in USD. From LP_EdnF_CorePosition or LP_EdnF_CoreBalance. (Tier 2 — SP_Marex_Recon) |
| 22 | Marex_FX | decimal(16,6) | YES | Marex's FX rate (local → USD). From LP_EdnF_CorePosition. (Tier 2 — SP_Marex_Recon) |
| 23 | ClientUnits | decimal(16,6) | YES | Aggregated client NOP units. From Dealing_Duco_EODRecon.ClientUnits. (Tier 2 — SP_Marex_Recon) |
| 24 | ClientsLocalAmount | money | YES | Aggregated client NOP in local currency. From Dealing_Duco_EODRecon. (Tier 2 — SP_Marex_Recon) |
| 25 | ClientsUSDAmount | money | YES | Aggregated client NOP in USD. From Dealing_Duco_EODRecon.ClientAmount. (Tier 2 — SP_Marex_Recon) |
| 26 | Marex-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Marex_Units,0) − ISNULL(eToro_Units,0)`. Non-zero = position break. (Tier 2 — SP_Marex_Recon) |
| 27 | Marex-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Marex_Units,0) − ISNULL(ClientUnits,0)`. Marex vs client NOP. (Tier 2 — SP_Marex_Recon) |
| 28 | Marex-eToro_LocalAmount | money | YES | `ISNULL(Marex_LocalAmount,0) − ISNULL(eToroLocalAmount,0)`. Local currency position break. (Tier 2 — SP_Marex_Recon) |
| 29 | Marex-eToro_USDAmount | money | YES | `ISNULL(Marex_AmountUSD,0) − ISNULL(eToroUSDAmount,0)`. USD position break. (Tier 2 — SP_Marex_Recon) |
| 30 | Marex-Clients_USDAmount | money | YES | `ISNULL(Marex_AmountUSD,0) − ISNULL(ClientsUSDAmount,0)`. USD break vs client NOP. (Tier 2 — SP_Marex_Recon) |
| 31 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_Marex_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| Marex_Units | LP_EdnF_CorePosition | Net position SUM |
| Marex_LocalAmount | LP_EdnF_CorePosition | Local currency value |
| Marex_AmountUSD | LP_EdnF_CorePosition / LP_EdnF_CoreBalance | USD value |
| Marex_FX | LP_EdnF_CorePosition | FX rate |
| Contract | LP_EdnF_CorePosition | Marex contract code |
| InstrumentID | External_Bronze_Fivetran_google_sheets_marex_mapping_table | Contract → InstrumentID lookup |
| eToro_Units | etoro_Hedge_Netting + History_Netting_History | Temporal join on date range |
| eToroUSDAmount | etoro_Hedge_Netting | Passthrough |
| ClientUnits | Dealing_Duco_EODRecon.ClientUnits | SUM, Marex HS filter |
| ClientsUSDAmount | Dealing_Duco_EODRecon.ClientAmount | Passthrough |
| Diff columns | Computed | ISNULL(Marex,0)−ISNULL(eToro/Clients,0) |

### 5.2 ETL Pipeline

```
LP_EdnF_CorePosition + LP_EdnF_CoreBalance (Marex position/balance files)
  +
External_Bronze_Fivetran_google_sheets_marex_mapping_table (contract→instrument)
  +
etoro_Hedge_Netting / History_Netting_History (eToro hedge, temporally versioned)
  +
Dealing_Duco_EODRecon (client NOP, Marex HS filter)
  → SP_Marex_Recon (JOIN on Contract + LiquidityAccountID)
  → Dealing_Marex_Recon_EODHoldings (DELETE-INSERT by Date)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| Contract | External_Bronze_Fivetran_google_sheets_marex_mapping_table | Contract→InstrumentID mapping |
| (Date) | etoro_Hedge_Netting | eToro hedge position source |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_Marex_Recon_Trades | Same SP | Trade activity companion |

---

## 7. Sample Queries

### 7.1 EOD position breaks on latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, Contract, LiquidityAccountID,
  Marex_Units, eToro_Units, [Marex-eToro_Units], [Marex-eToro_USDAmount]
FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings)
  AND [Marex-eToro_Units] <> 0
ORDER BY ABS([Marex-eToro_USDAmount]) DESC
```

### 7.2 Unmapped Marex contracts (no InstrumentID)
```sql
SELECT DISTINCT Contract, ContractName, SUM(ABS(Marex_Units)) AS Total_Abs_Units
FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings)
  AND InstrumentID IS NULL AND Marex_Units <> 0
GROUP BY Contract, ContractName
ORDER BY Total_Abs_Units DESC
```

### 7.3 FX rate comparison
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, Currency,
  eToro_FX, Marex_FX, eToro_FX - Marex_FX AS FX_Diff
FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_Marex_Recon_EODHoldings)
  AND Currency <> 'USD'
  AND ABS(eToro_FX - Marex_FX) > 0.001
ORDER BY ABS(eToro_FX - Marex_FX) DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.3/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
