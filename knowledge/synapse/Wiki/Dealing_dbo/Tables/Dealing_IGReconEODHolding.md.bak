# Dealing_dbo.Dealing_IGReconEODHolding

> Daily end-of-day holdings reconciliation comparing IG's custodian position for each instrument against eToro's internal hedge position and client NOP, surfacing unit and value discrepancies for Dealing desk review.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | LP_IG_PS_EODPositions (IG parquet feed) + Dealing_Duco_EODRecon |
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

Daily LP reconciliation snapshot for IG as liquidity provider. Each row represents one instrument × IG account combination for a given date, showing IG's reported EOD position alongside eToro's internal hedge book and client NOP. The `IG-eToro_*` diff columns flag discrepancies; a non-zero diff signals a recon break requiring investigation.

IG acts as LP for a limited set of CFD instruments — primarily major indices (Wall Street/29, US500/27, US Tech/28, UK100/30, Germany/32, France/31, Australia/33, Spain/34, Japan/36, HK HS50/38), key commodities (Oil/17 ×100 multiplier, Natural Gas/22, Gold/18, Silver/19), FX majors (EUR/USD, GBP/USD, AUD/USD, etc.), and a small set of individual stocks. IG data arrives as Parquet files loaded via COPY INTO from the data lake (`/LP/Silver/IG/PS_EODPositions`).

The SP (`SP_IGRecon`) loads the parquet file into `Dealing_staging.LP_IG_PS_EODPositions_daily`, upserts `LP_IG_PS_EODPositions`, then computes the final comparison via FULL OUTER JOIN on (InstrumentID, Account_Number). Saturday is skipped. Sunday runs against Friday data. DELETE-INSERT pattern by Date.

---

## 2. Business Logic

### 2.1 IG Instrument Scope

**What**: IG covers a fixed set of CFD instruments (not real stocks).

**Columns involved**: `InstrumentID`, `Account_Number`, `Symbol`

**Rules**:
- IG instruments are primarily index CFDs, key FX pairs, and commodities — NOT individual equities
- Instrument mapping uses a hardcoded MarketName→InstrumentID lookup in the SP (`#MarketNameToID`); unrecognised market names resolve via ISIN join to `DWH_dbo.Dim_Instrument`
- Oil contract multiplier: 1 IG lot = 100 barrels (IG_Units multiplied by 100)
- GBX instruments (e.g., UK100): amounts and rates divided by 100 to normalise to GBP

### 2.2 Reconciliation Diff Columns

**What**: `{LP}-{side}_*` columns show the arithmetic difference between LP-reported values and eToro values.

**Columns involved**: `IG-eToro_Units`, `IG-Clients_Units`, `IG-eToro_LocalAmount`, `IG-eToro_AmountUSD`, `IG-Clients_AmountUSD`, `IG-eToro_Rate`

**Rules**:
- Formula: `ISNULL(IG_value, 0) − ISNULL(eToro_value, 0)`
- Zero = reconciled; non-zero = break requiring Dealing desk investigation
- `IG-eToro` compares LP book vs eToro internal hedge; `IG-Clients` compares LP book vs aggregated client NOP

### 2.3 Weekend/Holiday Handling

**What**: IG does not report on weekends; SP uses a date-adjustment rule.

**Rules**:
- Saturday: SP skips entirely (no rows written)
- Sunday: `@TotalDate` set to Friday (`DATEADD(DAY, -2, @Date)` when `DayNumberOfWeek_Sun_Start=1`)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN with a CLUSTERED INDEX on `Date ASC`. Range queries by date perform well. For multi-instrument joins, consider materialising filtered results to a temp table before joining to `Dim_Instrument`.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Filter on `Date` for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Recon breaks for a specific date | `WHERE Date = @d AND [IG-eToro_Units] <> 0` |
| Oil contract reconciliation | `WHERE InstrumentID = 17 AND Date = @d` — note IG_Units already ×100 |
| IG account-level view | Filter by `Account_Number` |
| Trend of breaks over time | `GROUP BY Date, InstrumentID` on diff columns |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Resolve instrument details, AssetClassID |
| Dealing_dbo.Dealing_IGReconTrades | Date + InstrumentID | Pair EOD holdings with daily trade activity |
| Dealing_dbo.Dealing_Duco_EODRecon | Date + HedgeServerID + LiquidityAccountID | Trace eToro-side source rows |

### 3.4 Gotchas

- **Oil multiplier already applied**: `IG_Units` for Oil (InstrumentID=17) has been multiplied by 100 in the SP; do not multiply again
- **GBX normalisation already applied**: UK100 (InstrumentID=30) amounts and rates are ÷100 in the SP
- **Weekend gaps**: No rows for Saturdays; Sunday's Date = previous Friday
- **FULL OUTER JOIN rows**: Rows with `HedgeServerID IS NULL` are IG-only positions not in eToro's book; rows with `Account_Number IS NULL` are eToro-only positions not reported by IG

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_IGRecon)` |
| ★★ | Tier 3 — live data / DDL | `(Tier 3 — DDL/live)` |
| ★ | Tier 4-Inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | EOD snapshot date. Sunday values use previous Friday via `DayNumberOfWeek_Sun_Start=1` check against `DWH_dbo.Dim_Date`. (Tier 2 — SP_IGRecon) |
| 2 | HedgeServerID | int | YES | eToro hedge server identifier for the IG LP relationship. Sourced from `Dealing_Duco_EODRecon` via Fivetran HS mapping (`liquidity_provider='IG'`). NULL for IG-only rows (no matching eToro position). (Tier 2 — SP_IGRecon) |
| 3 | Account_Number | varchar(50) | YES | IG custodian account number (from `LP_IG_PS_EODPositions.[Account ID]`). Identifies the sub-account within IG's system. NULL for eToro-only rows (eToro position with no IG counterpart). (Tier 2 — SP_IGRecon) |
| 4 | InstrumentID | int | YES | eToro instrument identifier. Resolved from IG [Market Name] via `#MarketNameToID` lookup or ISIN join to `DWH_dbo.Dim_Instrument`. FK → DWH_dbo.Dim_Instrument.InstrumentID. (Tier 2 — SP_IGRecon) |
| 5 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. ISNULL(eToro_side, IG_side) — prefers eToro naming convention. (Tier 2 — SP_IGRecon) |
| 6 | Symbol | varchar(250) | YES | Ticker symbol from eToro side. NULL when only IG side present. (Tier 2 — SP_IGRecon) |
| 7 | ISINCode | varchar(30) | YES | ISIN. ISNULL(eToro_side, IG_side) — used as secondary join key between IG and eToro. (Tier 2 — SP_IGRecon) |
| 8 | CurrencyPrimary | varchar(50) | YES | Instrument's local currency. GBX normalised to 'GBP'. ISNULL(eToro_side, IG_side). (Tier 2 — SP_IGRecon) |
| 9 | Exchange | varchar(80) | YES | Trading venue from eToro side (Dealing_Duco_EODRecon.Exchange). ISNULL(eToro_side, 0) — 0 when eToro side absent. (Tier 2 — SP_IGRecon) |
| 10 | IG_Units | decimal(16,6) | YES | EOD position units reported by IG. `SUM((2*IsBuy-1)*IG_Units)` from `LP_IG_PS_EODPositions`. Oil (InstrumentID=17): ×100 multiplier applied. Negative = net short. (Tier 2 — SP_IGRecon) |
| 11 | eToro_Units | decimal(16,6) | YES | eToro's internal EOD hedge units for IG-mapped positions. `SUM(eToro_Units)` from `Dealing_Duco_EODRecon` where HedgeServerID matches IG Fivetran mapping. (Tier 2 — SP_IGRecon) |
| 12 | Clients_Units | decimal(16,6) | YES | Aggregated client NOP units for IG-matched positions. `SUM(ClientUnits)` from `Dealing_Duco_EODRecon`. (Tier 2 — SP_IGRecon) |
| 13 | IG-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(IG_Units,0) − ISNULL(eToro_Units,0)`. Non-zero = IG vs eToro position break. (Tier 2 — SP_IGRecon) |
| 14 | IG-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(IG_Units,0) − ISNULL(Clients_Units,0)`. IG position vs aggregated client NOP comparison. (Tier 2 — SP_IGRecon) |
| 15 | IG_LocalAmount | money | YES | IG's position market value in local currency. From `LP_IG_PS_EODPositions.[Current Value]` × units. GBX ÷100. Oil ×100 adjustment applied. (Tier 2 — SP_IGRecon) |
| 16 | eToro_LocalAmount | money | YES | eToro's local currency position value. From `Dealing_Duco_EODRecon.eToroLocalAmount`. GBX ÷100. (Tier 2 — SP_IGRecon) |
| 17 | IG-eToro_LocalAmount | money | YES | `ISNULL(IG_LocalAmount,0) − ISNULL(eToro_LocalAmount,0)`. Local currency recon break. (Tier 2 — SP_IGRecon) |
| 18 | IG_AmountUSD | money | YES | IG's position value in USD. From `LP_IG_PS_EODPositions.[Consideration (Base Ccy)]`. (Tier 2 — SP_IGRecon) |
| 19 | eToro_AmountUSD | money | YES | eToro's USD position value from `Dealing_Duco_EODRecon.eToroUSDAmount`. (Tier 2 — SP_IGRecon) |
| 20 | Clients_AmountUSD | money | YES | Aggregated client NOP value in USD from `Dealing_Duco_EODRecon.ClientAmount`. (Tier 2 — SP_IGRecon) |
| 21 | IG-eToro_AmountUSD | money | YES | `ISNULL(IG_AmountUSD,0) − ISNULL(eToro_AmountUSD,0)`. USD value of the IG vs eToro recon break. (Tier 2 — SP_IGRecon) |
| 22 | IG-Clients_AmountUSD | money | YES | `ISNULL(IG_AmountUSD,0) − ISNULL(Clients_AmountUSD,0)`. USD value of IG vs client NOP break. (Tier 2 — SP_IGRecon) |
| 23 | IG_Rate | decimal(16,6) | YES | IG's price per unit (closing price). `MAX(TRY_CONVERT(DECIMAL(16,6), [Latest]))` from `LP_IG_PS_EODPositions`. (Tier 2 — SP_IGRecon) |
| 24 | eToro_Rate | decimal(16,6) | YES | eToro's price per unit. `MAX(eToroRate)` from `Dealing_Duco_EODRecon`. (Tier 2 — SP_IGRecon) |
| 25 | IG-eToro_Rate | decimal(16,6) | YES | `ISNULL(IG_Rate,0) − ISNULL(eToro_Rate,0)`. Price discrepancy between IG and eToro valuation. (Tier 2 — SP_IGRecon) |
| 26 | IG_FXRate | decimal(16,6) | YES | IG's FX conversion rate (local → USD). `CASE WHEN Ccy='USD' THEN 1 ELSE CAST(LEFT([Conversion Rate], LEN-1) AS FLOAT)`. (Tier 2 — SP_IGRecon) |
| 27 | eToro_FXRate | decimal(16,6) | YES | eToro's FX rate from `Dealing_Duco_EODRecon.FXratetoUSD`. (Tier 2 — SP_IGRecon) |
| 28 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() on each INSERT. (Tier 2 — SP_IGRecon) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source | Transform |
|---------------|--------|-----------|
| IG_Units | LP_IG_PS_EODPositions.[Position] | SUM × (2×IsBuy−1); Oil ×100 |
| IG_Rate | LP_IG_PS_EODPositions.[Latest] | MAX, TRY_CONVERT |
| IG_FXRate | LP_IG_PS_EODPositions.[Conversion Rate] | Parse string, USD=1 |
| IG_AmountUSD | LP_IG_PS_EODPositions.[Consideration (Base Ccy)] | MAX aggregated |
| eToro_Units | Dealing_Duco_EODRecon.eToro_Units | SUM, Fivetran HS filter |
| Clients_Units | Dealing_Duco_EODRecon.ClientUnits | SUM |
| eToro_LocalAmount | Dealing_Duco_EODRecon.eToroLocalAmount | GBX ÷100 |
| eToro_AmountUSD | Dealing_Duco_EODRecon.eToroUSDAmount | Passthrough |
| eToro_FXRate | Dealing_Duco_EODRecon.FXratetoUSD | Passthrough |
| Diff columns | Computed | ISNULL(LP,0)−ISNULL(eToro,0) |
| UpdateDate | ETL | GETDATE() |

### 5.2 ETL Pipeline

```
LP IG Files (Parquet) → Lake (/LP/Silver/IG/PS_EODPositions)
  → COPY INTO Dealing_staging.LP_IG_PS_EODPositions_daily
  → Upsert Dealing_staging.LP_IG_PS_EODPositions
  +
Dealing_dbo.Dealing_Duco_EODRecon (eToro side, Fivetran HS mapping)
  → SP_IGRecon (FULL OUTER JOIN on InstrumentID + Account_Number)
  → Dealing_dbo.Dealing_IGReconEODHolding (DELETE-INSERT by Date)
```

| Step | Object | Description |
|------|--------|-------------|
| LP Source | LP_IG_PS_EODPositions | IG's EOD position file (Parquet, loaded daily via COPY INTO) |
| eToro Source | Dealing_Duco_EODRecon | eToro's internal EOD recon snapshot |
| HS Mapping | Dealing_staging.External_Fivetran_dealing_active_hs_mappings | LP='IG' filter |
| ETL | SP_IGRecon | Author: Gili Goldbaum (Dec 2023) |
| Target | Dealing_IGReconEODHolding | DELETE-INSERT by Date |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata lookup |
| HedgeServerID | Dealing_Duco_EODRecon | eToro EOD position source |
| HedgeServerID + LiquidityAccountID | Dealing_staging.External_Fivetran_dealing_active_hs_mappings | IG HS mapping |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_IGReconTrades | Same SP | Daily trades counterpart — same SP writes both |

---

## 7. Sample Queries

### 7.1 Recon breaks for latest available date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, IG_Units, eToro_Units, [IG-eToro_Units], IG_AmountUSD
FROM Dealing_dbo.Dealing_IGReconEODHolding
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_IGReconEODHolding)
  AND ABS([IG-eToro_Units]) > 0
ORDER BY ABS([IG-eToro_AmountUSD]) DESC
```

### 7.2 Oil contract history (multiplier awareness)
```sql
-- IG_Units already ×100 (barrels); divide by 100 to get IG lots
SELECT Date, IG_Units / 100.0 AS IG_Lots, eToro_Units / 100.0 AS eToro_Lots, [IG-eToro_Units] / 100.0 AS Break_Lots
FROM Dealing_dbo.Dealing_IGReconEODHolding
WHERE InstrumentID = 17
ORDER BY Date DESC
```

### 7.3 Recent recon trend by instrument
```sql
SELECT Date, InstrumentID, InstrumentDisplayName,
  SUM(ABS([IG-eToro_AmountUSD])) AS TotalBreakUSD
FROM Dealing_dbo.Dealing_IGReconEODHolding
WHERE Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY Date, InstrumentID, InstrumentDisplayName
HAVING SUM(ABS([IG-eToro_AmountUSD])) > 0
ORDER BY Date DESC, TotalBreakUSD DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
