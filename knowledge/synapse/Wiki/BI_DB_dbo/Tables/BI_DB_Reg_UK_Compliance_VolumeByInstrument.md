# BI_DB_dbo.BI_DB_Reg_UK_Compliance_VolumeByInstrument

> Daily weekday snapshot of full notional trading volume (Stocks and ETFs only) broken out by instrument, regulation, and settlement type — one row per InstrumentID/Regulation/IsReal combination for the previous business day's opened and closed positions. 20,932 rows as of 2026-04-13. Created under DSR-1848 for the UK compliance team (Edward Drake and Bradley Roberts). Writer: `SP_Reg_UK_Compliance_VolumeByInstrument`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + Dim_Instrument + Dim_Customer + Dim_Regulation (via SP_Reg_UK_Compliance_VolumeByInstrument) |
| **Refresh** | Daily — weekdays only (Saturday/Sunday skipped; TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Reg_UK_Compliance_VolumeByInstrument` captures the full notional value of positions opened or closed on each business day, for Stocks and ETF instruments only, segmented by instrument, regulatory regime, and settlement type. Created in March 2022 under DSR-1848, this table serves the UK compliance team's weekly instrument volume reporting — despite the "UK Compliance" prefix, the data covers **all regulatory regimes** (CySEC, FCA, FSA Seychelles, FSRA, ASIC & GAML, FinCEN+FINRA, MAS, NYDFS+FINRA), not just FCA/UK.

The table contains **20,932 rows** as of 2026-04-13 (the latest weekday snapshot). Each row represents the aggregated full notional amount (SUM of Leverage × Amount) for a unique combination of instrument, regulation, and settlement status, covering positions that opened or closed on the previous business day. The SP determines "last business day" dynamically at runtime — Sunday and Monday back-date to the preceding Friday; all other weekdays step back one day.

Regulation distribution: CySEC (7,304 rows, ~35% of rows, ~51% of notional), FCA (5,097 rows), FSA Seychelles (3,423 rows), FSRA (2,068 rows), ASIC & GAML (2,248 rows), with smaller segments for FinCEN+FINRA, MAS, ASIC, and NYDFS+FINRA. InstrumentType: Stocks 85.6% (17,922 rows), ETF 14.4% (3,010 rows). IsReal=1 (real/settled) accounts for ~70% of rows, IsReal=0 (CFD/leveraged) ~30%.

---

## 2. Business Logic

### 2.1 Instrument Type Filter

**What**: Only Stocks and ETF instruments are included — cryptocurrencies, indices, currencies, and other types are excluded.
**Columns Involved**: InstrumentType
**Rules**:
- `di.InstrumentType IN ('Stocks', 'ETF')` — hard-coded filter in both UNION ALL legs
- All other instrument types (Crypto, Currencies, Indices, Commodities, etc.) are excluded
- Adding new instrument types requires SP code change

### 2.2 Last Weekday Date Logic

**What**: The SP always targets the most recent completed business day, not today's date.
**Columns Involved**: (internal — affects all rows)
**Rules**:
- If rundate is Sunday → startdate = Friday (2 days back)
- If rundate is Monday → startdate = Friday (3 days back)
- All other weekdays → startdate = yesterday
- SP does NOT run on weekends (DATEPART(weekday) NOT IN (1=Sunday, 7=Saturday))
- @startdateid = YYYYMMDD integer of startdate, used in DateID comparisons

### 2.3 Full Notional Calculation

**What**: FullNotionalAmount represents the full economic exposure of each position, not just the margin.
**Columns Involved**: FullNotionalAmount
**Rules**:
- `SUM(dp.Leverage * dp.Amount)` — Amount is the USD position value; Leverage multiplies to full notional
- Aggregated first within each UNION leg, then summed again in the outer GROUP BY
- The UNION ALL combines positions opened on last weekday + positions closed on last weekday — a position opened and closed on the same day is counted twice (once per leg)

### 2.4 IsReal — Settlement Type Flag

**What**: `IsReal` is the BI_DB naming convention for the DWH column `IsSettled`.
**Columns Involved**: IsReal
**Rules**:
- IsReal = 1: real (settled asset) position — customer owns the underlying asset
- IsReal = 0: CFD (Contract for Difference) / leveraged position
- Sourced as `dp.IsSettled AS IsReal` in the SP

### 2.5 Regulation Coverage — Not UK-Only

**What**: Despite the table name prefix "UK_Compliance", no regulation filter is applied — all regulated and unregulated customers are included.
**Columns Involved**: Regulation
**Rules**:
- Regulation = `Dim_Regulation.Name` via customer's `DesignatedRegulationID`
- 16 regulation values observed in current data (CySEC, FCA, FSA Seychelles, FSRA, ASIC & GAML, FinCEN+FINRA, MAS, ASIC, NYDFS+FINRA, and others)
- The UK compliance team consumes this data to isolate FCA rows — the filtering is done by the consumer, not the SP

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Aspect | Detail |
|--------|--------|
| **Distribution** | ROUND_ROBIN — no skew concern (8 columns, 20K rows per day snapshot). |
| **Clustered Index** | HEAP — no clustered index; full scan for any query. |
| **Filter recommendation** | This is a single-day snapshot (no date column); table always reflects last weekday. Do not expect multi-date history. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| FCA-regulated Stocks notional for UK compliance | `WHERE Regulation = 'FCA' AND InstrumentType = 'Stocks'` |
| Top instruments by notional (all regulations) | `ORDER BY FullNotionalAmount DESC` |
| CFD vs real notional split | `GROUP BY IsReal` on `SUM(FullNotionalAmount)` |
| Regulation breakdown | `GROUP BY Regulation ORDER BY SUM(FullNotionalAmount) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Resolve additional instrument metadata (sector, asset class) |

### 3.4 Gotchas

- **No date column**: This table holds one day's snapshot only — UpdateDate records when the SP ran, not the business date being reported. If you need the business date, derive it from UpdateDate or the @startdate logic.
- **Double-count risk**: Positions opened AND closed on the same business day appear in both UNION legs — their notional is summed twice in FullNotionalAmount.
- **Dim_Country in SP but not in output**: The SP JOINs Dim_Country but does not use it in SELECT or WHERE filtering — this is a dead JOIN left over from the original query design.
- **Not UK-only**: All regulations appear in this table. Filter `WHERE Regulation = 'FCA'` to isolate UK/FCA regulated activity.
- **IsReal vs IsSettled naming**: IsReal in this table maps to IsSettled in DWH_dbo.Dim_Position (1=real/settled, 0=CFD).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki or DWH_dbo wiki (exact copy, no paraphrase) |
| Tier 2 | Derived from SP code and writer stored procedure analysis |
| Tier 3 | ETL metadata or system-generated columns confirmed from SP |
| Tier 4 | Inferred from context, sample data, or naming convention |
| Tier 5 | Expert review required — uncertain semantics |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | NO | Instrument identifier. Passthrough from DWH_dbo.Dim_Instrument via DWH_dbo.Dim_Position. (Tier 2 — SP_Reg_UK_Compliance_VolumeByInstrument, Dim_Instrument.InstrumentID) |
| 2 | InstrumentDisplayName | varchar(100) | YES | Human-readable instrument name (e.g., "NVIDIA Corporation", "Shell PLC"). Passthrough from DWH_dbo.Dim_Instrument.InstrumentDisplayName. (Tier 2 — SP_Reg_UK_Compliance_VolumeByInstrument, Dim_Instrument.InstrumentDisplayName) |
| 3 | ISINCode | varchar(30) | YES | International Securities Identification Number. Passthrough from DWH_dbo.Dim_Instrument.ISINCode. (Tier 2 — SP_Reg_UK_Compliance_VolumeByInstrument, Dim_Instrument.ISINCode) |
| 4 | InstrumentType | varchar(50) | NO | Instrument category. Always 'Stocks' or 'ETF' — hard-coded filter IN ('Stocks', 'ETF') in both SP legs. (Tier 2 — SP_Reg_UK_Compliance_VolumeByInstrument, Dim_Instrument.InstrumentType) |
| 5 | Regulation | varchar(50) | YES | Customer's designated regulation name at position time. Resolved from DWH_dbo.Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. 16 values observed: CySEC, FCA, FSA Seychelles, FSRA, ASIC & GAML, FinCEN+FINRA, MAS, ASIC, NYDFS+FINRA, and others. (Tier 2 — SP_Reg_UK_Compliance_VolumeByInstrument, Dim_Regulation.Name) |
| 6 | IsReal | int | YES | Settlement type flag. 1 = real/settled asset position (customer holds underlying); 0 = CFD/leveraged position. Sourced as `dp.IsSettled AS IsReal` in SP. (Tier 2 — SP_Reg_UK_Compliance_VolumeByInstrument, Dim_Position.IsSettled) |
| 7 | FullNotionalAmount | money | YES | Total full notional position value in USD for this instrument/regulation/settlement combination on the previous business day. Computed as SUM(Leverage × Amount) across positions opened and closed on last weekday. NOTE: positions opened and closed on the same day are counted in both UNION legs. (Tier 2 — SP_Reg_UK_Compliance_VolumeByInstrument, Dim_Position.Leverage × Dim_Position.Amount) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the SP (GETDATE() at insert time). Represents the SP run time on the latest weekday, not the business date being reported. (Tier 3 — SP_Reg_UK_Compliance_VolumeByInstrument) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| InstrumentID | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentID | Passthrough |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Passthrough |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Filtered: IN ('Stocks', 'ETF') |
| Regulation | DWH_dbo.Dim_Regulation | Name | Via Dim_Customer.DesignatedRegulationID |
| IsReal | DWH_dbo.Dim_Position | IsSettled | Passthrough with column rename |
| FullNotionalAmount | DWH_dbo.Dim_Position | Leverage, Amount | SUM(Leverage × Amount) — UNION ALL legs then outer SUM |
| UpdateDate | ETL metadata | — | GETDATE() at insert |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (OpenDateID = last weekday)
  + DWH_dbo.Dim_Instrument (filter: Stocks/ETF)
  + DWH_dbo.Dim_Customer (DesignatedRegulationID)
  + DWH_dbo.Dim_Regulation (Name)
  + DWH_dbo.Dim_Country (JOINed but not used in output)
    [Leg 1: positions opened on last weekday]
UNION ALL
DWH_dbo.Dim_Position (CloseDateID = last weekday)
  + same JOINs
    [Leg 2: positions closed on last weekday]
    → outer GROUP BY + SUM(FullNotionalAmount)
    |-- SP_Reg_UK_Compliance_VolumeByInstrument (Daily weekdays only, Priority 21, SB_Daily) ---|
    v                                                                     [TRUNCATE + INSERT]
BI_DB_dbo.BI_DB_Reg_UK_Compliance_VolumeByInstrument
  (20,932 rows | latest 2026-04-13 | ROUND_ROBIN HEAP | Stocks + ETF | 16 regulations)
    |-- UC: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolves to full instrument metadata |
| Regulation | DWH_dbo.Dim_Regulation | Sourced from Regulation name at write time |

### 6.2 Referenced By (other objects point to this)

No downstream objects identified in `opsdb-procedure-dependencies.json` that read this table. Table is consumed directly by the UK compliance team via SQL query / file export.

---

## 7. Sample Queries

### FCA Regulated Stocks Notional (for UK Compliance Team)

```sql
SELECT 
    InstrumentID,
    InstrumentDisplayName,
    ISINCode,
    IsReal,
    FullNotionalAmount
FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_VolumeByInstrument]
WHERE Regulation = 'FCA'
  AND InstrumentType = 'Stocks'
ORDER BY FullNotionalAmount DESC
```

### Top 20 Instruments by Total Notional (All Regulations)

```sql
SELECT 
    InstrumentID,
    InstrumentDisplayName,
    ISINCode,
    InstrumentType,
    SUM(FullNotionalAmount) AS total_notional
FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_VolumeByInstrument]
GROUP BY InstrumentID, InstrumentDisplayName, ISINCode, InstrumentType
ORDER BY total_notional DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
```

### Regulation × Settlement Type Breakdown

```sql
SELECT 
    Regulation,
    IsReal,
    COUNT(*) AS instrument_count,
    SUM(FullNotionalAmount) AS total_notional
FROM [BI_DB_dbo].[BI_DB_Reg_UK_Compliance_VolumeByInstrument]
GROUP BY Regulation, IsReal
ORDER BY total_notional DESC
```

---

## 8. Atlassian Knowledge Sources

Jira ticket: **DSR-1848** — created this table (March 2022, Nir Weber). Requested by UK compliance team members Edward Drake and Bradley Roberts to automate weekly instrument volume reporting. Migrated to Synapse by Slavane in June 2023. Same DSR as `BI_DB_Reg_UK_Compliance_KYC_Weekly_Export` — both tables serve the same compliance workflow.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 14/14 | P16: PASS*
*Tiers: 0 T1, 7 T2, 1 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 9/10, ETL: confirmed*
*Object: BI_DB_dbo.BI_DB_Reg_UK_Compliance_VolumeByInstrument | Type: Table | Production Source: Dim_Position SUM(Leverage×Amount) via SP_Reg_UK_Compliance_VolumeByInstrument*
