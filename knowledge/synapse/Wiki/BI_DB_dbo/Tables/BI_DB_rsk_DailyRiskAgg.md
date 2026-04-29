# BI_DB_dbo.BI_DB_rsk_DailyRiskAgg

> 2,929-row daily platform-wide risk aggregation table tracking portfolio standard deviation, AUM, equity, PnL, and net money flows segmented by trading mode (Manual, Copy All, Copyfund, Copytrader). Built by SP_rsk_AgregatedRisk using instrument covariance matrices from Dim_Instrument_Correlation and NOP data from BI_DB_rsk_Portfolio. Data from January 2017 to present, one row per day.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_rsk_AgregatedRisk (BI_DB_dbo) — Gil Alpert, 2023-10-12 |
| **Refresh** | Daily — DELETE+INSERT by Date + UPDATE for MIMO columns |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rsk_dailyriskagg` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

This is the central Risk Dashboard aggregation table providing a single daily row summarizing the platform's portfolio risk metrics. Each row captures the standard deviation of returns (both raw and equity-normalized), assets under management (AUM), equity, PnL, and net money-in/money-out for five segments:

1. **All** — entire platform (STD, RealizedEquity, Equity)
2. **Copy All** — all copy-trading AUM (CopySTD, CopyAUM, AUMIncUnPnL)
3. **Copyfund** — smart portfolio/fund AUM where parent has AccountTypeID=9 (CopyfundSTD, Copyfund_AUM)
4. **Copytrader** — copy-trading excluding copyfunds (CopytraderSTD, Traders_AUM)
5. **Manual/FX** — non-copy manual trading (FXSTD, ManualEquity)

The risk computation uses a covariance-weighted portfolio standard deviation: for each instrument pair, the NOP weight from BI_DB_rsk_Portfolio is multiplied by the instrument covariance from Dim_Instrument_Correlation, then summed and square-rooted to produce unweighted STD. The normalized STD divides by the segment's equity/AUM.

The MIMO columns (NetMoneyIn) are populated in a second pass via UPDATE using Fact_CustomerAction money-in/money-out events (ActionTypeID 15-18) through Dim_Mirror to segment by copyfund vs regular.

---

## 2. Business Logic

### 2.1 Covariance-Weighted Portfolio Standard Deviation

**What**: Calculates the portfolio standard deviation using instrument-pair covariance.
**Columns Involved**: UnWeighted_STD_h, Copy_UnWeighted_STD_h, Copyfund_UnWeighted_STD_h, CopytraderWeight_UnWeighted_STD_h, FX_UnWeighted_STD_h
**Rules**:
- NOP from BI_DB_rsk_Portfolio is scaled by 1/1000 to get weights per segment
- Weights are cross-multiplied with instrument covariance: `Covariance * Weight1 * Weight2`
- Result: `SQRT(ABS(SUM(weighted_covariance)))` per segment
- Uses latest available DateID from Dim_Instrument_Correlation

### 2.2 Normalized STD (Equity-Relative Risk)

**What**: Converts raw STD to percentage of segment equity/AUM.
**Columns Involved**: STD, CopySTD, FXSTD, CopytraderSTD, CopyfundSTD
**Rules**:
- `STD = UnWeighted_STD_h * 1000 / RealizedEquity` (all)
- `CopySTD = Copy_UnWeighted_STD_h * 1000 / AUM` (copy)
- `FXSTD = FX_UnWeighted_STD_h * 1000 / (RealizedEquity - AUM)` (manual)
- `CopytraderSTD = CopytraderWeight_UnWeighted_STD_h * 1000 / Traders_AUM`
- `CopyfundSTD = Copyfund_UnWeighted_STD_h * 1000 / Copyfund_AUM`
- Division by zero possible if segment AUM is zero — produces NULL/Infinity

### 2.3 AUM Segmentation by Copy Type

**What**: Splits copy AUM into copyfund (AccountTypeID=9) and regular copytrader.
**Columns Involved**: CopyAUM, Traders_AUM, Copyfund_AUM, Traders_PnL, Copyfund_PnL
**Rules**:
- Source: etoroGeneral_History_GuruCopiers joined with Dim_Customer on ParentCID
- Copyfund parent: ParentCID has AccountTypeID=9
- Child filter: IsDepositor=1, IsValidCustomer=1
- AUM = Cash + Investment + DetachedPosInvestment

### 2.4 Net Money-In/Out by Segment (MIMO)

**What**: Net capital flows through copy relationships by segment.
**Columns Involved**: NetMoneyIn - Copyfund, NetMoneyIn - Traders, NetMoneyIn - CopyAll
**Rules**:
- Source: Fact_CustomerAction WHERE ActionTypeID IN (15=CopyMirrorIn, 16=CopyMirrorOut, 17=CopyMirrorInPartial, 18=CopyMirrorOutPartial)
- Computation: MoneyIn*(-1) + MoneyOut*(-1) — negative values = net inflow to copy
- Populated via UPDATE after initial INSERT (two-phase ETL)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on [Date] ASC. Queries filtering on Date are efficient. Only 2,929 rows total.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Platform risk for a date range | `WHERE Date BETWEEN '2026-01-01' AND '2026-04-01'` |
| Copy vs manual risk comparison | Compare STD (all), CopySTD, FXSTD columns |
| AUM trend over time | SELECT Date, CopyAUM, Traders_AUM, Copyfund_AUM |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_rsk_Portfolio | Date (offset by 1 day) | Drill into per-instrument NOP |
| DWH_dbo.Dim_Date | Date = FullDate | Calendar attributes |

### 3.4 Gotchas

- **Date is @sd+1 day**: The Date column is one day ahead of the input parameter (the data reflects end-of-day for @sd, stored as @sd+1)
- **Division by zero**: CopytraderSTD and CopyfundSTD can be NULL/Infinity when segment AUM is zero
- **MIMO columns are UPDATE-populated**: NetMoneyIn columns are NULL until the UPDATE phase runs — if the SP fails mid-execution, these may be NULL for that date
- **Column names with spaces**: `[NetMoneyIn - Copyfund]` requires bracket notation in queries
- **Data from 2017**: Early data (2017-2019) uses a different equity calculation path (legacy #equity join) than the current V_Liabilities+GuruCopiers approach

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High — derived from stored procedure logic |
| Tier 5 | ETL metadata | Standard ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date (= input @sd + 1 day). One row per calendar day. Clustered index key. Range: 2017-01-02 to present. (Tier 2 — SP_rsk_AgregatedRisk) |
| 2 | UnWeighted_STD_h | float | YES | Raw (unweighted) portfolio standard deviation across ALL instruments and segments. Computed: SQRT(ABS(SUM(NOP_weight1 × NOP_weight2 × instrument_covariance))). In USD thousands. (Tier 2 — SP_rsk_AgregatedRisk) |
| 3 | Copy_UnWeighted_STD_h | float | YES | Raw portfolio standard deviation for COPY segment only (all copy-trading: copyfund + copytrader). Same formula as UnWeighted_STD_h but using copy-only NOP weights. (Tier 2 — SP_rsk_AgregatedRisk) |
| 4 | Copyfund_UnWeighted_STD_h | float | YES | Raw portfolio standard deviation for COPYFUND segment only (AccountTypeID=9 parents). (Tier 2 — SP_rsk_AgregatedRisk) |
| 5 | CopytraderWeight_UnWeighted_STD_h | float | YES | Raw portfolio standard deviation for COPYTRADER segment (copy excluding copyfunds). (Tier 2 — SP_rsk_AgregatedRisk) |
| 6 | FX_UnWeighted_STD_h | float | YES | Raw portfolio standard deviation for MANUAL/FX segment (non-copy positions). Computed: total NOP minus copy NOP. (Tier 2 — SP_rsk_AgregatedRisk) |
| 7 | STD | float | YES | Equity-normalized platform-wide risk: UnWeighted_STD_h × 1000 / RealizedEquity. Dimensionless ratio (~0.003-0.004 range). (Tier 2 — SP_rsk_AgregatedRisk) |
| 8 | CopySTD | float | YES | AUM-normalized copy risk: Copy_UnWeighted_STD_h × 1000 / CopyAUM. (Tier 2 — SP_rsk_AgregatedRisk) |
| 9 | FXSTD | float | YES | Equity-normalized manual/FX risk: FX_UnWeighted_STD_h × 1000 / (RealizedEquity - CopyAUM). (Tier 2 — SP_rsk_AgregatedRisk) |
| 10 | CopytraderSTD | float | YES | AUM-normalized copytrader risk: CopytraderWeight_UnWeighted_STD_h × 1000 / Traders_AUM. (Tier 2 — SP_rsk_AgregatedRisk) |
| 11 | CopyfundSTD | float | YES | AUM-normalized copyfund risk: Copyfund_UnWeighted_STD_h × 1000 / Copyfund_AUM. (Tier 2 — SP_rsk_AgregatedRisk) |
| 12 | RealizedEquity | money | YES | Platform-wide total realized equity. SUM(V_Liabilities.RealizedEquity) across all valid customers. ~$16.5B as of Apr 2026. (Tier 2 — SP_rsk_AgregatedRisk) |
| 13 | ManualEquity | money | YES | Non-copy equity. Computed: RealizedEquity - CopyAUM. Represents self-directed trading capital. (Tier 2 — SP_rsk_AgregatedRisk) |
| 14 | CopyAUM | money | YES | Total copy-trading AUM. SUM(Cash + Investment + DetachedPosInvestment) from etoroGeneral_History_GuruCopiers for valid depositing customers. ~$2.26B as of Apr 2026. (Tier 2 — SP_rsk_AgregatedRisk) |
| 15 | Traders_AUM | money | YES | Copytrader AUM excluding copyfunds. Same as CopyAUM but WHERE parent AccountTypeID != 9. ~$1.48B. (Tier 2 — SP_rsk_AgregatedRisk) |
| 16 | Copyfund_AUM | money | YES | Copyfund/Smart Portfolio AUM. Same as CopyAUM but WHERE parent AccountTypeID = 9. ~$778M. (Tier 2 — SP_rsk_AgregatedRisk) |
| 17 | Traders_PnL | decimal(38,2) | YES | Unrealized PnL for copytrader segment (excluding copyfund). SUM(PnL + Dit_PnL) WHERE parent not copyfund. (Tier 2 — SP_rsk_AgregatedRisk) |
| 18 | Copyfund_PnL | money | YES | Unrealized PnL for copyfund segment. SUM(PnL + Dit_PnL) WHERE parent AccountTypeID = 9. (Tier 2 — SP_rsk_AgregatedRisk) |
| 19 | AUMIncUnPnL | decimal(38,2) | YES | Total copy AUM including unrealized PnL. SUM(Cash + Investment + DetachedPosInvestment + PnL + Dit_PnL). ~$2.37B. (Tier 2 — SP_rsk_AgregatedRisk) |
| 20 | Equity | decimal(38,2) | YES | Platform-wide total equity including unrealized. SUM(ActualNWA + Liabilities) from V_Liabilities. ~$15.9B. (Tier 2 — SP_rsk_AgregatedRisk) |
| 21 | Copyfund_AUMIncUnPnL | money | YES | Copyfund AUM + copyfund PnL. ISNULL(Copyfund_AUM,0) + ISNULL(Copyfund_PnL,0). (Tier 2 — SP_rsk_AgregatedRisk) |
| 22 | Traders_AUMIncUnPnL | decimal(38,2) | YES | Copytrader AUM + copytrader PnL. ISNULL(Traders_AUM,0) + ISNULL(Traders_PnL,0). (Tier 2 — SP_rsk_AgregatedRisk) |
| 23 | UpdateDate | datetime | NOT NULL | ETL metadata: row insert/update timestamp (GETDATE()). Updated again during MIMO UPDATE phase. (Tier 5 — ETL metadata) |
| 24 | NetMoneyIn - Copyfund | decimal(38,2) | YES | Daily net capital flow into copyfund mirrors. SUM(MoneyIn × -1 + MoneyOut × -1) for AccountTypeID=9 parents. Negative = net inflow. Populated via UPDATE after initial INSERT. (Tier 2 — SP_rsk_AgregatedRisk) |
| 25 | NetMoneyIn - Traders | decimal(38,2) | YES | Daily net capital flow into regular copytrader mirrors. Same formula as copyfund but for non-AccountTypeID=9. (Tier 2 — SP_rsk_AgregatedRisk) |
| 26 | NetMoneyIn - CopyAll | decimal(38,2) | YES | Daily net capital flow into all copy mirrors. SUM(MoneyIn × -1 + MoneyOut × -1) across all mirror types. (Tier 2 — SP_rsk_AgregatedRisk) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | Parameter | @sd + 1 day | Date shift |
| UnWeighted_STD_h–FX_UnWeighted_STD_h | BI_DB_rsk_Portfolio + Dim_Instrument_Correlation | NOP × Covariance | SQRT(ABS(SUM(weighted))) |
| STD–CopyfundSTD | Computed | STD_h × 1000 / equity | Normalization |
| RealizedEquity, Equity | V_Liabilities | RealizedEquity, ActualNWA+Liabilities | SUM |
| CopyAUM–Copyfund_PnL | etoroGeneral_History_GuruCopiers | Cash, Investment, PnL, etc. | SUM by segment |
| NetMoneyIn columns | Fact_CustomerAction + Dim_Mirror | Amount by ActionTypeID 15-18 | SUM by mirror type |

### 5.2 ETL Pipeline

```
DWH_dbo.V_Liabilities + general.etoroGeneral_History_GuruCopiers (equity & copy AUM)
BI_DB_dbo.BI_DB_rsk_Portfolio (per-instrument NOP)
DWH_dbo.Dim_Instrument_Correlation (covariance matrix)
DWH_dbo.Fact_CustomerAction + Dim_Mirror (MIMO flows)
  |-- SP_rsk_AgregatedRisk @sd (DELETE+INSERT+UPDATE) ---|
  v
BI_DB_dbo.BI_DB_rsk_DailyRiskAgg (2,929 rows, one per day)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rsk_dailyriskagg
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Date | DWH_dbo.Dim_Date | Calendar dimension |

### 6.2 Referenced By (other objects point to this)

No known direct consumers in the documented wiki set. Used by Tableau Risk Dashboard.

---

## 7. Sample Queries

### 7.1 Platform Risk Trend (Last 30 Days)

```sql
SELECT Date, STD, CopySTD, FXSTD, RealizedEquity, CopyAUM
FROM BI_DB_dbo.BI_DB_rsk_DailyRiskAgg
WHERE Date >= DATEADD(DAY, -30, GETDATE())
ORDER BY Date
```

### 7.2 Copy vs Manual AUM Split

```sql
SELECT Date, CopyAUM, ManualEquity,
       CopyAUM * 100.0 / RealizedEquity AS CopyPct
FROM BI_DB_dbo.BI_DB_rsk_DailyRiskAgg
WHERE Date >= '2026-01-01'
ORDER BY Date
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 25 T2, 0 T3, 0 T4, 1 T5 | Elements: 26/26, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_rsk_DailyRiskAgg | Type: Table | Production Source: SP_rsk_AgregatedRisk*
