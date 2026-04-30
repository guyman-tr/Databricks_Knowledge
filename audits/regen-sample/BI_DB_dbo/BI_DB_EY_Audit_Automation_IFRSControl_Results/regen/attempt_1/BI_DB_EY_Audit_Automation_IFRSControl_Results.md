# BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results

> 1,066-row EY audit control table that cross-checks daily crypto buy/sell unit totals computed from position-level data against the aggregated IFRS 15 Daily Balance, running daily since 2024-01-24 via SP_EY_Audit_IFRS_Control. Each row stores one metric comparison (Buy or Sell) with the calculated value, the IFRS reference value, the difference, and the difference percentage.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_EY_Audit_Closed_Positions + BI_DB_EY_Audit_Opened_Positions + BI_DB_EY_Audit_ChangeLog + BI_DB_IFRS15_Daily_Balance via SP_EY_Audit_IFRS_Control |
| **Refresh** | Daily DELETE+INSERT keyed on Date via SP_EY_Audit_IFRS_Control @date |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_EY_Audit_Automation_IFRSControl_Results is an automated audit control table created by Guy Manova (2024-01-25) for EY's IFRS 15 revenue recognition audit cycle. It contains 1,066 rows spanning 2024-01-24 to 2025-06-30, with exactly 2 rows per execution date — one comparing total crypto **Buy** units and one comparing total crypto **Sell** units.

The table serves as a reconciliation checkpoint: **Metric_a** ("TotalBuy_Calc_detailed" / "TotalSell_Calc_detailed") represents the sum of crypto position units computed bottom-up from three position-level audit tables (BI_DB_EY_Audit_Closed_Positions, BI_DB_EY_Audit_Opened_Positions, BI_DB_EY_Audit_ChangeLog), while **Metric_b** ("IFRSTotalBuy" / "IFRSTotalSell") represents the same totals as reported by BI_DB_IFRS15_Daily_Balance. The **Diff** and **Diff_Percentage** columns quantify any discrepancy between the two calculation paths.

The SP scopes to crypto instruments only (InstrumentTypeID=10 via Dim_Instrument join). The Buy metric aggregates: (a) regular buys — IsBuy=1 positions opened today (InitialUnits), and (b) short-sell closes — IsBuy=0 positions closed today (Units). The Sell metric aggregates: (a) regular sells — IsBuy=1 positions closed today (Units), and (b) short-buy opens — IsBuy=0 positions opened today (InitialUnits). Changelog entries (CFD↔Real conversions, ChangeTypeID=13) are included in both directions.

The Buy comparison against IFRS balance sums Metrics 'BuyCFD', 'BuyReal', 'StakingBuy'; the Sell comparison sums 'RedeemSell', 'SellCFD', 'SellReal', 'StakingSell', 'RedeemStakingSell'.

---

## 2. Business Logic

### 2.1 Two-Metric Comparison Pattern

**What**: Each execution date produces exactly two rows — one for Buy, one for Sell — comparing position-level aggregates against IFRS balance aggregates.

**Columns Involved**: `Metric_a`, `Metric_a_Value`, `Metric_b`, `Metric_b_Value`, `Diff`, `Diff_Percentage`

**Rules**:
- Buy row: Metric_a='TotalBuy_Calc_detailed', Metric_b='IFRSTotalBuy'
- Sell row: Metric_a='TotalSell_Calc_detailed', Metric_b='IFRSTotalSell'
- Diff = Metric_a_Value − Metric_b_Value (negative when IFRS total exceeds position-level total)
- Diff_Percentage = ROUND(ABS(Diff) / Metric_b_Value × 100, 4)

### 2.2 Position Timing Classification

**What**: The SP classifies positions into three timing buckets before aggregating units.

**Columns Involved**: Intermediate PositionTiming (not stored, used in aggregation)

**Rules**:
- 'Opened_Before_Period_Closed_InPeriod' — opened before @date, closed on @date (uses Units for close volume)
- 'Opened_And_Closed_In_Period' — opened and closed on same @date (uses both InitialUnits for open, Units for close)
- 'Opened_In_Period_Not_Closed' — opened on @date, still open or closed later (uses InitialUnits for open volume)
- CFD↔Real changelog entries (ChangeTypeID=13) are added as a fourth category with AmountChanged as volume

### 2.3 Buy/Sell Unit Aggregation Logic

**What**: The SP determines Buy vs Sell based on IsBuy flag direction combined with position timing.

**Columns Involved**: `Metric_a_Value` (computed Buy or Sell total)

**Rules**:
- Buy = (IsBuy=1 AND opened today → InitialUnits) + (IsBuy=0 AND closed today → Units as BuyShort)
- Sell = (IsBuy=1 AND closed today → Units as RegulatSell) + (IsBuy=0 AND opened today → InitialUnits as SellShort)
- Partial close children (IsPartialCloseChild=1) are excluded from Buy/SellShort initial unit counts

### 2.4 DELETE+INSERT Refresh Pattern

**What**: Each run deletes all rows for the target date before inserting fresh results.

**Columns Involved**: `Date`

**Rules**:
- `DELETE FROM ... WHERE Date = @date` runs before any INSERT
- Guarantees idempotent re-execution for the same date
- No historical versioning — re-run overwrites

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no distribution key or clustered index. With only ~1,066 rows, full scans are trivial. No optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Check today's IFRS reconciliation | `WHERE Date = @date` — returns exactly 2 rows (Buy + Sell) |
| Find dates with large discrepancies | `WHERE Diff_Percentage > 1.0 ORDER BY Date` |
| Trend of Sell discrepancy over time | `WHERE Metric_a = 'TotalSell_Calc_detailed' ORDER BY Date` |
| Check if audit ran for a date | `WHERE Date = @date` — empty = not yet run |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_IFRS15_Daily_Balance | ON Date = Date | Drill into the IFRS balance rows being compared |
| BI_DB_EY_Audit_Closed_Positions | ON CloseDateID = CAST(Date AS int YYYYMMDD) | Trace position-level detail behind Metric_a |
| BI_DB_EY_Audit_Opened_Positions | ON OpenDateID = CAST(Date AS int YYYYMMDD) | Trace position-level detail behind Metric_a |

### 3.4 Gotchas

- **Stored_Proc contains a typo**: The value is 'SP_EY_Audit_Automation_IFRS_Contorl' (misspelling of 'Control') — this is hardcoded in the SP and consistent across all rows
- **IsPriceFound is always NULL**: The column is populated with NULL in every INSERT statement; it appears to be a placeholder that was never implemented
- **Buy Diff_Percentage is routinely large (80–89%)**: The position-level Buy calculation excludes staking and some CFD categories that the IFRS balance includes — this is expected behavior, not a data quality issue
- **Sell Diff_Percentage is typically small (<1%)**: The Sell comparison has better coverage alignment between the two calculation paths
- **Additional metric rows exist (72 rows)**: Beyond the core TotalBuy/TotalSell pairs, 8 additional Metric_a values appear for 12 dates each (e.g., TotalBuyReal_Calc_detailed, TotalSellCFD_Calc_detailed) — these are from an expanded version of the SP

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | ETL-computed in SP_EY_Audit_IFRS_Control — transform documented from SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date for this audit control row. The @date parameter passed to SP_EY_Audit_IFRS_Control. One Buy row and one Sell row per date. Range: 2024-01-24 to present. (Tier 2 — SP_EY_Audit_IFRS_Control) |
| 2 | Stored_Proc | varchar(200) | YES | Hardcoded identifier of the generating stored procedure. Always 'SP_EY_Audit_Automation_IFRS_Contorl' (note: legacy typo of 'Control' is intentional and consistent). (Tier 2 — SP_EY_Audit_IFRS_Control) |
| 3 | Metric_a | varchar(200) | YES | Label for the position-level calculated metric. Primary values: 'TotalBuy_Calc_detailed' (sum of crypto buy units from position audit tables), 'TotalSell_Calc_detailed' (sum of crypto sell units). Additional granular values exist for Real/CFD breakdowns. (Tier 2 — SP_EY_Audit_IFRS_Control) |
| 4 | Metric_a_Value | decimal(18,4) | YES | Aggregated unit total computed bottom-up from position-level audit tables (BI_DB_EY_Audit_Closed_Positions, BI_DB_EY_Audit_Opened_Positions, BI_DB_EY_Audit_ChangeLog). For Buy: SUM of InitialUnits (long opens) + Units (short closes). For Sell: SUM of Units (long closes) + InitialUnits (short opens). Crypto instruments only (InstrumentTypeID=10). (Tier 2 — SP_EY_Audit_IFRS_Control) |
| 5 | Metric_b | varchar(200) | YES | Label for the IFRS 15 balance reference metric. Primary values: 'IFRSTotalBuy' (sum of BuyCFD + BuyReal + StakingBuy from BI_DB_IFRS15_Daily_Balance), 'IFRSTotalSell' (sum of RedeemSell + SellCFD + SellReal + StakingSell + RedeemStakingSell). (Tier 2 — SP_EY_Audit_IFRS_Control) |
| 6 | Metric_b_Value | decimal(18,4) | YES | Aggregated unit total from BI_DB_IFRS15_Daily_Balance.TotalUnits for the corresponding IFRS metric group on the same date. Represents the IFRS 15 pipeline's view of crypto buy or sell volume. (Tier 2 — SP_EY_Audit_IFRS_Control) |
| 7 | Diff | decimal(18,4) | YES | Arithmetic difference: Metric_a_Value minus Metric_b_Value. Negative when the IFRS balance total exceeds the position-level calculation. Used to detect discrepancies between the two computation paths. (Tier 2 — SP_EY_Audit_IFRS_Control) |
| 8 | Diff_Percentage | decimal(18,4) | YES | Percentage magnitude of the discrepancy: ROUND(ABS(Diff) / Metric_b_Value × 100, 4). Sell typically <1%; Buy routinely 80–89% due to scope differences (position-level calc excludes staking and some CFD categories included in the IFRS balance). (Tier 2 — SP_EY_Audit_IFRS_Control) |
| 9 | IsPriceFound | int | YES | Placeholder column. Hardcoded to NULL in every INSERT statement. No logic populates this column — appears reserved for a future price-validation check that was never implemented. (Tier 2 — SP_EY_Audit_IFRS_Control) |
| 10 | UpdateDate | datetime | YES | ETL metadata timestamp. Set to GETDATE() at INSERT time by SP_EY_Audit_IFRS_Control. Indicates when this audit control row was last generated. (Tier 2 — SP_EY_Audit_IFRS_Control) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| Date | SP_EY_Audit_IFRS_Control | @date parameter | Passthrough of SP input |
| Stored_Proc | SP_EY_Audit_IFRS_Control | — | Hardcoded 'SP_EY_Audit_Automation_IFRS_Contorl' |
| Metric_a | SP_EY_Audit_IFRS_Control | — | Hardcoded label per UNION branch |
| Metric_a_Value | BI_DB_EY_Audit_Closed_Positions + BI_DB_EY_Audit_Opened_Positions + BI_DB_EY_Audit_ChangeLog | TotalUnits (aggregated) | SUM via #IFRSCompare temp table |
| Metric_b | SP_EY_Audit_IFRS_Control | — | Hardcoded label per UNION branch |
| Metric_b_Value | BI_DB_IFRS15_Daily_Balance | TotalUnits | SUM WHERE Date + Metric filter |
| Diff | SP_EY_Audit_IFRS_Control | Metric_a_Value, Metric_b_Value | a − b |
| Diff_Percentage | SP_EY_Audit_IFRS_Control | Diff, Metric_b_Value | ROUND(ABS(a−b)/b×100, 4) |
| IsPriceFound | SP_EY_Audit_IFRS_Control | — | Hardcoded NULL |
| UpdateDate | SP_EY_Audit_IFRS_Control | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_EY_Audit_Closed_Positions (closed crypto positions)
BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions (opened crypto positions)
BI_DB_dbo.BI_DB_EY_Audit_ChangeLog (CFD↔Real conversions)
  |-- JOIN DWH_dbo.Dim_Instrument (InstrumentTypeID=10 filter) --|
  |-- aggregate into #IFRSCompare (Buy/Sell unit totals) --------|
  v
BI_DB_dbo.BI_DB_IFRS15_Daily_Balance (IFRS 15 reference totals)
  |-- SUM(TotalUnits) by Metric group --|
  v
SP_EY_Audit_IFRS_Control @date (CROSS JOIN + comparison)
  |-- DELETE WHERE Date = @date + INSERT 2 rows --|
  v
BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results (1,066 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Metric_a_Value (indirect) | BI_DB_dbo.BI_DB_EY_Audit_Closed_Positions | Closed position units aggregated into Buy/Sell totals |
| Metric_a_Value (indirect) | BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions | Opened position units aggregated into Buy/Sell totals |
| Metric_a_Value (indirect) | BI_DB_dbo.BI_DB_EY_Audit_ChangeLog | CFD↔Real conversion units included in totals |
| Metric_b_Value (indirect) | BI_DB_dbo.BI_DB_IFRS15_Daily_Balance | IFRS 15 balance reference values |
| InstrumentTypeID filter | DWH_dbo.Dim_Instrument | Crypto scope filter (InstrumentTypeID=10) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | No downstream consumers found in SSDT repo |

---

## 7. Sample Queries

### 7.1 Latest audit results
```sql
SELECT *
FROM BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results
WHERE Date = (SELECT MAX(Date) FROM BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results)
ORDER BY Metric_a
```

### 7.2 Dates with Sell discrepancy above 1%
```sql
SELECT Date, Metric_a_Value, Metric_b_Value, Diff, Diff_Percentage
FROM BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results
WHERE Metric_a = 'TotalSell_Calc_detailed'
  AND Diff_Percentage > 1.0
ORDER BY Diff_Percentage DESC
```

### 7.3 Monthly average discrepancy trend
```sql
SELECT FORMAT(Date, 'yyyy-MM') AS YearMonth,
       Metric_a,
       AVG(Diff_Percentage) AS AvgDiffPct,
       COUNT(*) AS DaysRun
FROM BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results
WHERE Metric_a IN ('TotalBuy_Calc_detailed', 'TotalSell_Calc_detailed')
GROUP BY FORMAT(Date, 'yyyy-MM'), Metric_a
ORDER BY YearMonth, Metric_a
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results | Type: Table | Production Source: BI_DB_EY_Audit_* tables + BI_DB_IFRS15_Daily_Balance via SP_EY_Audit_IFRS_Control*
