# Dealing_dbo.Dealing_VisionRecon_Trades

> Daily trade activity reconciliation comparing Vision Financial Markets' executed trade volume against eToro's internal dealing records by instrument and direction, surfacing unit and value discrepancies.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | LP_VisionET_R002_EOD_Trades_ET + Dealing_Duco_ActivityRecon |
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

Companion table to `Dealing_VisionRecon_EODHoldings`, covering the **trade activity** dimension of the Vision Financial Markets reconciliation. Each row represents one instrument × direction (IsBuy) × Vision account combination for a given date, comparing Vision's reported executed trade volume against eToro's internal trade records from `Dealing_Duco_ActivityRecon`.

Unlike `Dealing_VisionRecon_EODHoldings`, this table uses standard named diff columns (`Vision-eToro_AmountUSD`, `Vision-Client_AmountUSD`) rather than the `Reality-Supposed`/`Reality-Client` naming. No tolerance boundary columns are present on the trades side.

Trade direction is encoded as `IsBuy` (bit: 1=Buy, 0=Sell) rather than the varchar `Buy/Sell` convention used by IG and JPM tables. Vision LP trade activity comes from `LP_VisionET_R002_EOD_Trades_ET`. Same SP writer as EOD holdings (`SP_Vision_Recon`). DELETE-INSERT by Date.

---

## 2. Business Logic

### 2.1 Trade Direction via IsBuy Flag

**What**: Direction is a bit flag rather than a varchar enum.

**Columns involved**: `IsBuy`, `eToro_Units`, `Vision_Units`

**Rules**:
- `IsBuy = 1` → Buy direction; `IsBuy = 0` → Sell direction
- Vision source encodes direction as 'B' or 'C'; SP maps to IsBuy=1. Other codes map to IsBuy=0
- Units are always positive; direction is determined by `IsBuy` alone

### 2.2 CUSIP-Based Join Key

**What**: Same as EODHoldings — Vision side joined to eToro on CUSIP + AccountNumber.

**Rules**:
- FULL OUTER JOIN on CUSIP + AccountNumber + IsBuy
- ISINCode available as supplementary identifier

### 2.3 Reconciliation Diff Columns

**What**: Standard LP-eToro diff pattern.

**Rules**:
- `Vision-eToro_Units` = `ISNULL(Vision_Units,0) − ISNULL(eToro_Units,0)`
- `Vision-eToro_AmountUSD` = `ISNULL(Vision_AmountUSD,0) − ISNULL(eToroAmountUSD,0)`
- `Vision-Client_AmountUSD` = `ISNULL(Vision_AmountUSD,0) − ISNULL(ClientAmountUSD,0)`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. Filter on Date first; add IsBuy or InstrumentID filters to narrow results.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Filter on `Date` for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Trade breaks for a date | `WHERE Date=@d AND [Vision-eToro_Units]<>0` |
| Buy vs Sell comparison | `GROUP BY Date, InstrumentID, IsBuy` |
| Vision-only trades | `WHERE Vision_Units<>0 AND eToro_Units=0` |
| Reconcile against EOD holdings | JOIN to Dealing_VisionRecon_EODHoldings on Date + InstrumentID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata |
| Dealing_VisionRecon_EODHoldings | Date + InstrumentID | Pair trade recon with EOD holdings |
| Dealing_Duco_ActivityRecon | Date + HedgeServerID | Trace eToro-side source trades |

### 3.4 Gotchas

- **IsBuy is bit, not varchar**: Unlike IG/JPM tables which use `Buy/Sell` varchar, filtering requires `IsBuy = 1` (Buy) or `IsBuy = 0` (Sell)
- **CUSIP join**: Same CUSIP-based join as EODHoldings — do not attempt cross-table joins on ISINCode alone
- **Column naming variance**: `Client_Units` (singular) vs `Clients_Units` (plural) in EODHoldings — be explicit when writing cross-table queries
- **No boundary columns**: `LowerBoundary`/`UpperBoundary` are absent from trades table; only in EODHoldings

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_Vision_Recon)` |
| ★★ | Tier 3 — DDL/live | `(Tier 3 — DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trade date. SP parameter; DELETE-INSERT by Date. (Tier 2 — SP_Vision_Recon) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. Resolved from Dim_Instrument via CUSIP/ISIN. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_Vision_Recon) |
| 3 | InstrumentDisplayName | varchar(150) | YES | Instrument display name. Prefer eToro naming; fall back to Vision name. (Tier 2 — SP_Vision_Recon) |
| 4 | Symbol | varchar(50) | YES | Ticker symbol from eToro side. (Tier 2 — SP_Vision_Recon) |
| 5 | Cusip | varchar(20) | YES | CUSIP identifier. Primary join key between eToro and Vision sides. (Tier 2 — SP_Vision_Recon) |
| 6 | ISINCode | varchar(50) | YES | ISIN code. Supplementary identifier resolved from Dim_Instrument. (Tier 2 — SP_Vision_Recon) |
| 7 | CurrencyPrimary | varchar(10) | YES | Instrument local currency. ISNULL(eToro, Vision). (Tier 2 — SP_Vision_Recon) |
| 8 | Exchange | varchar(40) | YES | Trading venue. From eToro side (Dealing_Duco_ActivityRecon). (Tier 2 — SP_Vision_Recon) |
| 9 | HedgeServerID | int | YES | eToro hedge server for the Vision LP. From Fivetran mapping (LP='Vision'). NULL for Vision-only rows. (Tier 2 — SP_Vision_Recon) |
| 10 | IsBuy | bit | YES | Trade direction: 1=Buy, 0=Sell. Derived from Vision feed order type codes (B/C→1, others→0). (Tier 2 — SP_Vision_Recon) |
| 11 | eToro_Units | decimal(16,6) | YES | eToro's executed trade volume. SUM from Dealing_Duco_ActivityRecon for Vision HS. ISNULL(,0). (Tier 2 — SP_Vision_Recon) |
| 12 | Vision_Units | decimal(16,6) | YES | Vision's executed trade volume in units. SUM from LP_VisionET_R002_EOD_Trades_ET. ISNULL(,0). (Tier 2 — SP_Vision_Recon) |
| 13 | Client_Units | decimal(16,6) | YES | Aggregated client trade volume. SUM(ClientUnits) from Dealing_Duco_ActivityRecon. ISNULL(,0). (Tier 2 — SP_Vision_Recon) |
| 14 | Vision-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Vision_Units,0) − ISNULL(eToro_Units,0)`. Non-zero = trade recon break. (Tier 2 — SP_Vision_Recon) |
| 15 | Vision-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(Vision_Units,0) − ISNULL(Client_Units,0)`. Vision vs client NOP. (Tier 2 — SP_Vision_Recon) |
| 16 | eToroAmountUSD | money | YES | eToro's USD trade amount from Dealing_Duco_ActivityRecon.eToroUSDAmount. (Tier 2 — SP_Vision_Recon) |
| 17 | Vision_AmountUSD | money | YES | Vision's notional trade value in USD. From LP_VisionET_R002_EOD_Trades_ET. (Tier 2 — SP_Vision_Recon) |
| 18 | ClientAmountUSD | money | YES | Aggregated client trade amount in USD from Dealing_Duco_ActivityRecon.ClientAmount. (Tier 2 — SP_Vision_Recon) |
| 19 | Vision-eToro_AmountUSD | money | YES | **Recon diff**: `ISNULL(Vision_AmountUSD,0) − ISNULL(eToroAmountUSD,0)`. USD trade break. (Tier 2 — SP_Vision_Recon) |
| 20 | Vision-Client_AmountUSD | money | YES | **Recon diff**: `ISNULL(Vision_AmountUSD,0) − ISNULL(ClientAmountUSD,0)`. USD break vs client NOP. (Tier 2 — SP_Vision_Recon) |
| 21 | AccountNumber | varchar(40) | YES | Vision LP account identifier. Secondary join key. From LP_VisionET_R002_EOD_Trades_ET. NULL for eToro-only rows. (Tier 2 — SP_Vision_Recon) |
| 22 | eToroRate | decimal(16,6) | YES | eToro's average execution rate. AVG(eToro_Rate) from Dealing_Duco_ActivityRecon. (Tier 2 — SP_Vision_Recon) |
| 23 | Vision_Rate | decimal(16,6) | YES | Vision's average execution price per unit. From LP_VisionET_R002_EOD_Trades_ET. (Tier 2 — SP_Vision_Recon) |
| 24 | Vision-eToro_Rate | decimal(16,6) | YES | `ISNULL(Vision_Rate,0) − ISNULL(eToroRate,0)`. Execution price discrepancy. (Tier 2 — SP_Vision_Recon) |
| 25 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_Vision_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| Vision_Units | LP_VisionET_R002_EOD_Trades_ET | SUM grouped by CUSIP+AccountNumber+IsBuy |
| Vision_Rate | LP_VisionET_R002_EOD_Trades_ET | Execution price |
| Vision_AmountUSD | LP_VisionET_R002_EOD_Trades_ET | Notional value USD |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM, Vision HS filter |
| eToroAmountUSD | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough |
| Client_Units | Dealing_Duco_ActivityRecon.ClientUnits | SUM |
| ClientAmountUSD | Dealing_Duco_ActivityRecon.ClientAmount | Passthrough |
| Diff columns | Computed | ISNULL(Vision,0)−ISNULL(eToro,0) |

### 5.2 ETL Pipeline

```
LP_VisionET_R002_EOD_Trades_ET (Vision trade file)
  +
Dealing_Duco_ActivityRecon (eToro activity, Vision HS filter)
  → SP_Vision_Recon (FULL OUTER JOIN on Cusip + AccountNumber + IsBuy)
  → Dealing_VisionRecon_Trades (DELETE-INSERT by Date)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| (Date + HedgeServerID) | Dealing_Duco_ActivityRecon | eToro trade activity source |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_VisionRecon_EODHoldings | Same SP | EOD holdings companion — same writer |

---

## 7. Sample Queries

### 7.1 Trade breaks on latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, IsBuy,
  Vision_Units, eToro_Units, [Vision-eToro_Units], [Vision-eToro_AmountUSD]
FROM Dealing_dbo.Dealing_VisionRecon_Trades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_VisionRecon_Trades)
  AND ABS([Vision-eToro_Units]) > 0
ORDER BY ABS([Vision-eToro_AmountUSD]) DESC
```

### 7.2 Net daily traded volume by instrument (eToro side)
```sql
SELECT Date, InstrumentID, InstrumentDisplayName,
  SUM(CASE WHEN IsBuy=1 THEN eToro_Units ELSE -eToro_Units END) AS Net_eToro_Units
FROM Dealing_dbo.Dealing_VisionRecon_Trades
WHERE Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY Date, InstrumentID, InstrumentDisplayName
ORDER BY Date DESC
```

### 7.3 Vision-only trades (no matching eToro activity)
```sql
SELECT Date, Cusip, InstrumentDisplayName, AccountNumber, IsBuy,
  Vision_Units, Vision_AmountUSD
FROM Dealing_dbo.Dealing_VisionRecon_Trades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_VisionRecon_Trades)
  AND Vision_Units <> 0 AND eToro_Units = 0
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
