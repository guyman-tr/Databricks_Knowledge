# Dealing_dbo.Dealing_JPMReconEODHolding

> Daily end-of-day holdings reconciliation comparing JPMorgan's custodian position for each real-stock instrument against eToro's internal hedge position and client NOP across NA, EMEA, and ASIA regions.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | LP_JPM_EOD_eToro_Report_ComponentUnderlyings + Dealing_Duco_EODRecon |
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

The largest LP reconciliation table in the Dealing schema (2.4M+ rows, active since Nov 2023). Each row represents one real-stock instrument × currency combination for a given date, showing JPMorgan's reported EOD custodian holdings alongside eToro's internal hedge position and aggregated client NOP. Used daily by the Dealing desk to verify that JPM's custodian records match eToro's books.

JPMorgan acts as custodian/prime broker for eToro's real-stock portfolio across three global regions: North America (NA), EMEA, and ASIA. Coverage is broad — all real stocks accessible on eToro across these regions. JPM EOD data arrives via `LP_JPM_EOD_eToro_Report_ComponentUnderlyings` and `LP_JPM_EOD_eToro_Report_FXRates`.

The SP (`SP_JPMRecon`, Gili Goldbaum, Nov 2023) handles a special case for HS 9 (matched differently — by InstrumentDisplayName/ISINCode rather than InstrumentID/Symbol/Exchange), uses FULL OUTER JOIN on ISINCode + CurrencyPrimary. GBX→GBP normalisation applied. DELETE-INSERT by Date. Date uses the max available ReportDateID from JPM files (may lag eToro date by 1 day when JPM report is delayed).

---

## 2. Business Logic

### 2.1 HS 9 Special Handling

**What**: HedgeServer 9 uses a different grouping key than other HS due to LP reporting differences.

**Columns involved**: `InstrumentID`, `ISINCode`, `InstrumentDisplayName`

**Rules**:
- HS 2,8,22,121,110,129 grouped by full instrument tuple (InstrumentID, Symbol, Exchange)
- HS 9 grouped by ISINCode + DisplayName only (no InstrumentID or Exchange) — joined separately via `#eToroSide_EOD_9` and `#eToroSide_EOD_Only_9`
- Final FULL OUTER JOIN merges both HS groups on ISINCode + CurrencyPrimary

### 2.2 JPM Date Alignment

**What**: JPM report dates may lag eToro by 1 day; SP adjusts.

**Rules**:
- `@DateID2 = MAX(ReportDateID) FROM LP_JPM_EOD_eToro_Report_ComponentUnderlyings WHERE ReportDateID <= @DateID`
- If JPM's latest available date < @Date, SP uses JPM's latest available date (backfill prevention)

### 2.3 Reconciliation Diff Columns

**What**: `{LP}-{side}_*` columns show the discrepancy.

**Rules**:
- `JP-eToro_*`: JPM value − eToro value; zero = reconciled
- `JP-Clients_*`: JPM value − client NOP; zero = LP matches client exposure

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. This is the largest LP recon table — use tight date filters. For instrument-level analysis, add `InstrumentID` or `ISINCode` filters.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Always filter on `Date` to avoid full table scans (2.4M rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| EOD recon breaks | `WHERE Date=@d AND [JP-eToro_Units]<>0` |
| USD-denominated breaks only | `WHERE CurrencyPrimary='USD'` |
| Multi-currency instrument | GROUP BY ISINCode, look at each CurrencyPrimary row |
| JP-only positions | `WHERE JP_Units<>0 AND eToro_Units=0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument details |
| Dealing_JPMReconTrades | Date + InstrumentID | Trade vs holdings reconciliation |
| Dealing_Duco_EODRecon | Date + InstrumentID | Trace eToro-side source rows |

### 3.4 Gotchas

- **No InstrumentID for HS9-only rows**: When only HS 9 had the instrument, `InstrumentID` may be NULL
- **CurrencyPrimary is secondary join key**: Same ISIN can appear in multiple currencies (currency sweeps); do not deduplicate on ISIN alone
- **JPM date lag**: On days when JPM's report is delayed, `Date` in this table may be 1 day behind eToro's date
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
| 1 | Date | date | YES | EOD snapshot date. Uses JPM's `MAX(ReportDateID)` ≤ requested date — may lag by 1 day when JPM report is delayed. (Tier 2 — SP_JPMRecon) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. Resolved via ISNULL(eToro_side, JP_side). May be NULL for HS 9 positions where instrument mapping is absent. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_JPMRecon) |
| 3 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. `ISNULL(eToro_side, JP.[Name])`. (Tier 2 — SP_JPMRecon) |
| 4 | Symbol | varchar(250) | YES | Ticker symbol. `ISNULL(eToro_side, JP.[RIC Code])`. (Tier 2 — SP_JPMRecon) |
| 5 | ISINCode | varchar(250) | YES | ISIN. `ISNULL(eToro_side, JP.[ISIN Code])`. Primary join key between eToro and JPM sides. (Tier 2 — SP_JPMRecon) |
| 6 | CurrencyPrimary | varchar(50) | YES | Local currency. `ISNULL(eToro_side, JP.Currency)`. Secondary join key — same ISIN can appear in multiple currencies. (Tier 2 — SP_JPMRecon) |
| 7 | Exchange | varchar(80) | YES | Trading venue. `ISNULL(eToro_side, 0)`. (Tier 2 — SP_JPMRecon) |
| 8 | JP_Units | decimal(16,6) | YES | JPM's EOD custodian position in units. `ISNULL(jp.JP_Units, 0)` from `LP_JPM_EOD_eToro_Report_ComponentUnderlyings.Quantity`. (Tier 2 — SP_JPMRecon) |
| 9 | eToro_Units | decimal(16,6) | YES | eToro's internal hedge units. `ISNULL(tse.eToro_Units, 0)` from `Dealing_Duco_EODRecon` for JPM HS (2,8,22,9,121,110,129/319). (Tier 2 — SP_JPMRecon) |
| 10 | Clients_Units | decimal(16,6) | YES | Aggregated client NOP units. `ISNULL(tse.ClientUnits, 0)` from `Dealing_Duco_EODRecon`. (Tier 2 — SP_JPMRecon) |
| 11 | JP-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(JP_Units,0) − ISNULL(eToro_Units,0)`. Non-zero = JPM vs eToro position break. (Tier 2 — SP_JPMRecon) |
| 12 | JP-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(JP_Units,0) − ISNULL(Clients_Units,0)`. JPM custodian vs client NOP comparison. (Tier 2 — SP_JPMRecon) |
| 13 | JP_LocalAmount | money | YES | JPM's position market value in local currency. `ISNULL(jp.JP_LocalAmount, 0)` from `LP_JPM_EOD_eToro_Report_ComponentUnderlyings.[Market Value (local)]`. (Tier 2 — SP_JPMRecon) |
| 14 | eToro_LocalAmount | money | YES | eToro's local currency position value from `Dealing_Duco_EODRecon.eToroLocalAmount`. GBX ÷100. (Tier 2 — SP_JPMRecon) |
| 15 | JP-eToro_LocalAmount | money | YES | `ISNULL(JP_LocalAmount,0) − ISNULL(eToro_LocalAmount,0)`. Local currency recon break. (Tier 2 — SP_JPMRecon) |
| 16 | JP_AmountUSD | money | YES | JPM's position value in USD. `ISNULL(jp.JP_AmountUSD, 0)` from `LP_JPM_EOD_eToro_Report_ComponentUnderlyings.[Market Value (USD)]`. (Tier 2 — SP_JPMRecon) |
| 17 | eToro_AmountUSD | money | YES | eToro's USD position value from `Dealing_Duco_EODRecon.eToroUSDAmount`. (Tier 2 — SP_JPMRecon) |
| 18 | Clients_AmountUSD | money | YES | Aggregated client NOP value in USD from `Dealing_Duco_EODRecon.ClientAmount`. (Tier 2 — SP_JPMRecon) |
| 19 | JP-eToro_AmountUSD | money | YES | `ISNULL(JP_AmountUSD,0) − ISNULL(eToro_AmountUSD,0)`. USD value of the JPM vs eToro recon break. (Tier 2 — SP_JPMRecon) |
| 20 | JP-Clients_AmountUSD | money | YES | `ISNULL(JP_AmountUSD,0) − ISNULL(Clients_AmountUSD,0)`. USD break vs client NOP. (Tier 2 — SP_JPMRecon) |
| 21 | JP_Rate | decimal(16,6) | YES | JPM's closing price per unit in local currency. `MAX([Current Price])` from `LP_JPM_EOD_eToro_Report_ComponentUnderlyings`. (Tier 2 — SP_JPMRecon) |
| 22 | eToro_Rate | decimal(16,6) | YES | eToro's price per unit. `MAX(eToroRate)` from `Dealing_Duco_EODRecon`. (Tier 2 — SP_JPMRecon) |
| 23 | JP-eToro_Rate | decimal(16,6) | YES | `ISNULL(JP_Rate,0) − ISNULL(eToro_Rate,0)`. Closing price discrepancy. (Tier 2 — SP_JPMRecon) |
| 24 | JP_FXRate | decimal(16,6) | YES | JPM's FX rate (local → USD). `MAX(FX_Rate)` from `LP_JPM_EOD_eToro_Report_FXRates` joined on Currency. (Tier 2 — SP_JPMRecon) |
| 25 | eToro_FXRate | decimal(16,6) | YES | eToro's FX rate from `Dealing_Duco_EODRecon.FXratetoUSD`. (Tier 2 — SP_JPMRecon) |
| 26 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_JPMRecon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| JP_Units | LP_JPM_EOD_eToro_Report_ComponentUnderlyings.Quantity | SUM grouped by ISIN+Currency |
| JP_Rate | LP_JPM_EOD_eToro_Report_ComponentUnderlyings.[Current Price] | MAX |
| JP_LocalAmount | LP_JPM_EOD_eToro_Report_ComponentUnderlyings.[Market Value (local)] | SUM |
| JP_AmountUSD | LP_JPM_EOD_eToro_Report_ComponentUnderlyings.[Market Value (USD)] | SUM |
| JP_FXRate | LP_JPM_EOD_eToro_Report_FXRates.Rate | MAX, join on Currency |
| eToro_Units | Dealing_Duco_EODRecon.eToro_Units | SUM, HS 2/8/22/9/121/110/129 |
| eToro_LocalAmount | Dealing_Duco_EODRecon.eToroLocalAmount | GBX ÷100 |
| eToro_AmountUSD | Dealing_Duco_EODRecon.eToroUSDAmount | Passthrough |
| Diff columns | Computed | ISNULL(JP,0)−ISNULL(eToro,0) |

### 5.2 ETL Pipeline

```
JPM EOD Report (ComponentUnderlyings + FXRates) → Dealing_staging
  +
Dealing_Duco_EODRecon (eToro side, JPM HS filter: 2,8,22,9,121,110,129)
  → SP_JPMRecon (FULL OUTER JOIN on ISINCode + CurrencyPrimary)
  → Dealing_JPMReconEODHolding (DELETE-INSERT by Date)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| (Date + InstrumentID) | Dealing_Duco_EODRecon | eToro EOD source |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_JPMReconTrades | Same SP | Trade activity companion |

---

## 7. Sample Queries

### 7.1 Largest USD recon breaks for latest date
```sql
SELECT TOP 20 Date, InstrumentID, InstrumentDisplayName, ISINCode, CurrencyPrimary,
  JP_Units, eToro_Units, [JP-eToro_Units], [JP-eToro_AmountUSD]
FROM Dealing_dbo.Dealing_JPMReconEODHolding
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_JPMReconEODHolding)
  AND [JP-eToro_AmountUSD] <> 0
ORDER BY ABS([JP-eToro_AmountUSD]) DESC
```

### 7.2 Instruments present on JP side only (potential orphan positions)
```sql
SELECT Date, ISINCode, InstrumentDisplayName, JP_Units, JP_AmountUSD
FROM Dealing_dbo.Dealing_JPMReconEODHolding
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_JPMReconEODHolding)
  AND eToro_Units = 0 AND JP_Units <> 0
```

### 7.3 FX rate discrepancy check
```sql
SELECT Date, ISINCode, CurrencyPrimary, JP_FXRate, eToro_FXRate,
  JP_FXRate - eToro_FXRate AS FX_Diff
FROM Dealing_dbo.Dealing_JPMReconEODHolding
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_JPMReconEODHolding)
  AND CurrencyPrimary <> 'USD'
  AND ABS(JP_FXRate - eToro_FXRate) > 0.001
ORDER BY ABS(JP_FXRate - eToro_FXRate) DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*
