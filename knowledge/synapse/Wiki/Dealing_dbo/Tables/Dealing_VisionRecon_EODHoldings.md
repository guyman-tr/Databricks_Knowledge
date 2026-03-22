# Dealing_dbo.Dealing_VisionRecon_EODHoldings

> Daily end-of-day holdings reconciliation comparing Vision Financial Markets' custodian position for each real-stock instrument against eToro's internal hedge position and client NOP, with instrument boundary tolerance ranges.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | LP_VisionET_R006_EOD_Positions_ET + Dealing_Duco_EODRecon |
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

EOD holdings reconciliation for Vision Financial Markets (a UK-based LP/custodian for eToro's real-stock program). Each row represents one instrument × Vision account combination for a given date, showing Vision's reported EOD custodian holdings alongside eToro's internal hedge position and aggregated client NOP.

Unlike IG or JPM, Vision reconciliation uses **CUSIP** as the primary join key (rather than ISINCode) and groups by `AccountNumber`. The table includes `LowerBoundary` and `UpperBoundary` tolerance bands sourced from `etoro_Hedge_InstrumentBoundaries`, which the Dealing desk uses to determine whether a break is within acceptable tolerance before escalation.

`Reality-Supposed` and `Reality-Client` are the USD-denominated diff columns (Vision vs eToro, Vision vs Clients) — named differently from other LP recon tables but semantically equivalent to `LP-eToro_AmountUSD` and `LP-Clients_AmountUSD` in the IG/JPM tables.

Written by `SP_Vision_Recon` (Dealing_dbo). Vision EOD data arrives via `LP_VisionET_R006_EOD_Positions_ET`. DELETE-INSERT by Date.

---

## 2. Business Logic

### 2.1 CUSIP-Based Join Key

**What**: Vision side is joined to eToro side on CUSIP + AccountNumber rather than ISINCode.

**Columns involved**: `Cusip`, `AccountNumber`, `ISINCode`

**Rules**:
- Primary join key: CUSIP + AccountNumber (FULL OUTER JOIN)
- ISINCode available as supplementary identifier but not used as join key
- CUSIP originates from Vision LP feed; ISINCode resolved from `DWH_dbo.Dim_Instrument`

### 2.2 Boundary Tolerance Bands

**What**: `LowerBoundary` and `UpperBoundary` define acceptable recon break thresholds per instrument.

**Columns involved**: `LowerBoundary`, `UpperBoundary`

**Rules**:
- Sourced from `etoro_Hedge_InstrumentBoundaries` joined on InstrumentID
- Breaks within [LowerBoundary, UpperBoundary] range may be considered within tolerance
- Breaks outside range require Dealing desk investigation

### 2.3 Reconciliation Diff Columns

**What**: `Reality-Supposed` and `Reality-Client` are the USD-level diff columns for this LP.

**Rules**:
- `Reality-Supposed` = `Vision_AmountUSD − eToroAmountUSD`; zero = Vision matches eToro hedge
- `Reality-Client` = `Vision_AmountUSD − ClientAmountUSD`; zero = Vision matches client NOP
- Unit-level diff: `Vision-eToro_Units` = `ISNULL(Vision_Units,0) − ISNULL(eToro_Units,0)`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. Filter on Date first; add `InstrumentID` or `Cusip` filters to narrow results.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Always filter on `Date` to avoid full table scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| EOD recon breaks | `WHERE Date=@d AND [Vision-eToro_Units]<>0` |
| Breaks outside tolerance | `WHERE [Reality-Supposed] NOT BETWEEN LowerBoundary AND UpperBoundary` |
| Vision-only positions | `WHERE Vision_Units<>0 AND eToro_Units=0` |
| Rate discrepancy | `WHERE ABS([Vision-eToro_Rate]) > 0.01` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata |
| Dealing_VisionRecon_Trades | Date + InstrumentID | Trade vs holdings reconciliation |
| Dealing_Duco_EODRecon | Date + HedgeServerID | Trace eToro-side source rows |

### 3.4 Gotchas

- **CUSIP join, not ISIN**: Join key is CUSIP + AccountNumber — do not assume ISINCode deduplication works across this table and other LP recon tables
- **Reality-Supposed naming**: The "supposed" refers to eToro's expected hedge position; `Reality-Supposed = Vision − eToro` (not Clients)
- **No explicit FX columns**: Unlike IG/JPM, Vision does not have separate `LP_FXRate` / `eToro_FXRate` columns — USD amounts are pre-converted in the LP feed or SP
- **Boundary source**: LowerBoundary/UpperBoundary come from `etoro_Hedge_InstrumentBoundaries`, not from Vision; boundaries may be zero for instruments without configured tolerance

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_Vision_Recon)` |
| ★★ | Tier 3 — DDL/live | `(Tier 3 — DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | EOD snapshot date. Date parameter passed to SP; DELETE-INSERT by Date. (Tier 2 — SP_Vision_Recon) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. Resolved from Dim_Instrument via CUSIP or ISIN mapping. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_Vision_Recon) |
| 3 | InstrumentDisplayName | varchar(150) | YES | Instrument display name. Prefer eToro naming; fall back to Vision name. (Tier 2 — SP_Vision_Recon) |
| 4 | Symbol | varchar(50) | YES | Ticker symbol from eToro side. (Tier 2 — SP_Vision_Recon) |
| 5 | Cusip | varchar(20) | YES | CUSIP identifier. Primary join key between eToro and Vision sides. From LP_VisionET_R006_EOD_Positions_ET. (Tier 2 — SP_Vision_Recon) |
| 6 | ISINCode | varchar(50) | YES | ISIN code. Supplementary identifier; resolved from Dim_Instrument. (Tier 2 — SP_Vision_Recon) |
| 7 | CurrencyPrimary | varchar(10) | YES | Instrument local currency. ISNULL(eToro, Vision). (Tier 2 — SP_Vision_Recon) |
| 8 | Exchange | varchar(50) | YES | Trading venue. From eToro side (Dealing_Duco_EODRecon). (Tier 2 — SP_Vision_Recon) |
| 9 | HedgeServerID | int | YES | eToro hedge server for the Vision LP. From Fivetran mapping (LP='Vision'). NULL for Vision-only rows. (Tier 2 — SP_Vision_Recon) |
| 10 | eToro_Units | decimal(16,6) | YES | eToro's internal hedge units. SUM from Dealing_Duco_EODRecon for Vision HS. ISNULL(,0). (Tier 2 — SP_Vision_Recon) |
| 11 | Vision_Units | decimal(16,6) | YES | Vision's EOD custodian position in units. SUM from LP_VisionET_R006_EOD_Positions_ET. ISNULL(,0). (Tier 2 — SP_Vision_Recon) |
| 12 | Clients_Units | decimal(16,6) | YES | Aggregated client NOP units. SUM(ClientUnits) from Dealing_Duco_EODRecon. ISNULL(,0). (Tier 2 — SP_Vision_Recon) |
| 13 | Vision-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Vision_Units,0) − ISNULL(eToro_Units,0)`. Non-zero = Vision vs eToro position break. (Tier 2 — SP_Vision_Recon) |
| 14 | Vision-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Vision_Units,0) − ISNULL(Clients_Units,0)`. Vision custodian vs client NOP comparison. (Tier 2 — SP_Vision_Recon) |
| 15 | eToroAmountUSD | money | YES | eToro's hedge position value in USD. From Dealing_Duco_EODRecon.eToroUSDAmount. (Tier 2 — SP_Vision_Recon) |
| 16 | Vision_AmountUSD | money | YES | Vision's position market value in USD. From LP_VisionET_R006_EOD_Positions_ET. (Tier 2 — SP_Vision_Recon) |
| 17 | ClientAmountUSD | money | YES | Aggregated client NOP value in USD. From Dealing_Duco_EODRecon.ClientAmount. (Tier 2 — SP_Vision_Recon) |
| 18 | Reality-Supposed | money | YES | **Recon diff**: `Vision_AmountUSD − eToroAmountUSD`. "Reality" (Vision custodian) minus "Supposed" (eToro hedge book). Zero = reconciled. (Tier 2 — SP_Vision_Recon) |
| 19 | Reality-Client | money | YES | **Recon diff**: `Vision_AmountUSD − ClientAmountUSD`. Vision custodian vs client NOP in USD. Zero = reconciled. (Tier 2 — SP_Vision_Recon) |
| 20 | AccountNumber | varchar(40) | YES | Vision LP account identifier. Secondary join key (CUSIP + AccountNumber). From LP_VisionET_R006_EOD_Positions_ET. NULL for eToro-only rows. (Tier 2 — SP_Vision_Recon) |
| 21 | eToroRate | decimal(16,6) | YES | eToro's closing price per unit. MAX(eToroRate) from Dealing_Duco_EODRecon. (Tier 2 — SP_Vision_Recon) |
| 22 | Vision_Rate | decimal(16,6) | YES | Vision's closing price per unit. From LP_VisionET_R006_EOD_Positions_ET. (Tier 2 — SP_Vision_Recon) |
| 23 | Vision-eToro_Rate | decimal(16,6) | YES | `ISNULL(Vision_Rate,0) − ISNULL(eToroRate,0)`. Closing price discrepancy. (Tier 2 — SP_Vision_Recon) |
| 24 | LowerBoundary | int | YES | Lower tolerance bound for this instrument's acceptable recon break. From etoro_Hedge_InstrumentBoundaries. (Tier 2 — SP_Vision_Recon) |
| 25 | UpperBoundary | int | YES | Upper tolerance bound for this instrument's acceptable recon break. From etoro_Hedge_InstrumentBoundaries. (Tier 2 — SP_Vision_Recon) |
| 26 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_Vision_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| Vision_Units | LP_VisionET_R006_EOD_Positions_ET | SUM grouped by CUSIP+AccountNumber |
| Vision_Rate | LP_VisionET_R006_EOD_Positions_ET | EOD price |
| Vision_AmountUSD | LP_VisionET_R006_EOD_Positions_ET | Market value USD |
| eToro_Units | Dealing_Duco_EODRecon.eToro_Units | SUM, Vision HS filter |
| eToroAmountUSD | Dealing_Duco_EODRecon.eToroUSDAmount | Passthrough |
| Clients_Units | Dealing_Duco_EODRecon.ClientUnits | SUM |
| ClientAmountUSD | Dealing_Duco_EODRecon.ClientAmount | Passthrough |
| LowerBoundary | etoro_Hedge_InstrumentBoundaries | Join on InstrumentID |
| UpperBoundary | etoro_Hedge_InstrumentBoundaries | Join on InstrumentID |
| Diff columns | Computed | Vision − eToro / Vision − Clients |

### 5.2 ETL Pipeline

```
LP_VisionET_R006_EOD_Positions_ET (Vision EOD positions file)
  +
Dealing_Duco_EODRecon (eToro side, Vision HS filter)
  +
etoro_Hedge_InstrumentBoundaries (tolerance bands)
  → SP_Vision_Recon (FULL OUTER JOIN on Cusip + AccountNumber)
  → Dealing_VisionRecon_EODHoldings (DELETE-INSERT by Date)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| (Date + HedgeServerID) | Dealing_Duco_EODRecon | eToro EOD source |
| (InstrumentID) | etoro_Hedge_InstrumentBoundaries | Tolerance bounds |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_VisionRecon_Trades | Same SP | Trade activity companion |

---

## 7. Sample Queries

### 7.1 EOD recon breaks outside tolerance for latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, Cusip,
  Vision_Units, eToro_Units, [Vision-eToro_Units], [Reality-Supposed],
  LowerBoundary, UpperBoundary
FROM Dealing_dbo.Dealing_VisionRecon_EODHoldings
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_VisionRecon_EODHoldings)
  AND [Reality-Supposed] NOT BETWEEN LowerBoundary AND UpperBoundary
  AND [Vision-eToro_Units] <> 0
ORDER BY ABS([Reality-Supposed]) DESC
```

### 7.2 Vision-only positions (potential orphan holdings)
```sql
SELECT Date, Cusip, InstrumentDisplayName, AccountNumber,
  Vision_Units, Vision_AmountUSD
FROM Dealing_dbo.Dealing_VisionRecon_EODHoldings
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_VisionRecon_EODHoldings)
  AND eToro_Units = 0 AND Vision_Units <> 0
```

### 7.3 Rate discrepancy check
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, eToroRate, Vision_Rate,
  [Vision-eToro_Rate]
FROM Dealing_dbo.Dealing_VisionRecon_EODHoldings
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_VisionRecon_EODHoldings)
  AND ABS([Vision-eToro_Rate]) > 0.01
ORDER BY ABS([Vision-eToro_Rate]) DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
