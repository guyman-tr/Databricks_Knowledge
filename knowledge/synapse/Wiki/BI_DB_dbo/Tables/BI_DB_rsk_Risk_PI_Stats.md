# BI_DB_dbo.BI_DB_rsk_Risk_PI_Stats

> 162K-row daily per-PI statistics table tracking AUM components, copier counts, risk metrics, daily profit, MIMO flows, and buy/sell directional bias for the top ~200 Popular Investors and Smart Portfolios. Built by SP_rsk_RiskCorelation_PIs alongside BI_DB_rsk_Risk_PI_Correl. Data from April 2024 to present with 2-year rolling retention.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_rsk_RiskCorelation_PIs (BI_DB_dbo) — Bar Arian 2024-02-14 |
| **Refresh** | Daily — DELETE+INSERT by Date (+ purge >2 years old) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rsk_risk_pi_stats` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

This table provides a daily snapshot for each top Popular Investor (PI) and Smart Portfolio, capturing their complete AUM breakdown, copier metrics, portfolio risk (standard deviation), daily profit attribution, mirror money flows, and directional trading bias.

The population matches BI_DB_rsk_Risk_PI_Correl: top 100 PIs by AUM or effective copiers (partitioned by Regular vs Copyfund type), filtered to valid depositing customers with positive realized equity. With ~200 PIs per day and ~730 days of data, this produces approximately 162K rows.

Key analytics enabled:
- **AUM decomposition**: Cash, Investment, PnL, DetachedPosInvestment, Dit_PnL per PI
- **Daily profit attribution**: TotalProfit = today's unrealized PnL - yesterday's + realized (closed) profit
- **Capital flow monitoring**: MoneyIn/MoneyOut from mirror copy actions (ActionTypeID 15-18)
- **Directional bias**: IsBuyPercent shows what fraction of manual position equity is in long positions

---

## 2. Business Logic

### 2.1 Daily Profit Computation

**What**: Net daily profit combining unrealized PnL change and realized closes.
**Columns Involved**: TotalProfit, PnL, Dit_PnL, YesterdayAUM
**Rules**:
- `TotalProfit = PnL + Dit_PnL - YesterdayPnL - YesterdayDit_PnL + NetProfit(closed)`
- NetProfit from Dim_Position for positions closed on DateID between yesterday and today, MirrorTypeID=1
- Zero if all components are NULL/zero

### 2.2 IsBuy Percentage (Directional Bias)

**What**: Proportion of manual position equity in long (buy) positions.
**Columns Involved**: IsBuyPercent
**Rules**:
- Source: BI_DB_PositionPnL WHERE MirrorID=0 (manual positions only), DateID=@DateINT
- UnrealizedEquity = Amount + PositionPnL, grouped by IsBuy
- IsBuyPercent = BuyEquity / (BuyEquity + SellEquity)
- Uses LEAD window function over IsBuy DESC partition by CID
- 1.0 = 100% long; 0.0 = 100% short; NULL if no manual positions

### 2.3 MIMO Capital Flows

**What**: Mirror money-in and money-out from copy actions.
**Columns Involved**: MoneyIn, MoneyOut
**Rules**:
- Source: Fact_CustomerAction WHERE ActionTypeID IN (15=CopyMirrorIn, 16=CopyMirrorOut, 17=CopyMirrorInPartial, 18=CopyMirrorOutPartial)
- MoneyIn = SUM(Amount × -1) for ActionTypeID 15,17 (inflows shown as positive)
- MoneyOut = SUM(Amount) for ActionTypeID 16,18

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on [Date]. Small table (162K rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top PIs by AUM today | `WHERE Date = '2026-04-12' ORDER BY AUM DESC` |
| PI profit trend | `WHERE ParentCID = X ORDER BY Date` |
| Copyfund vs copytrader comparison | `GROUP BY Type` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_rsk_Risk_PI_Correl | Date + ParentCID = CID1 | Correlation with other PIs |
| DWH_dbo.Dim_Customer | ParentCID = RealCID | Customer attributes |

### 3.4 Gotchas

- **%AUM column name starts with %**: Must use `[%AUM]` in queries
- **MoneyIn is sign-inverted**: Original Amount is negative for inflows; SP multiplies by -1 so positive = money flowing in
- **IsBuyPercent is manual-only**: Based on MirrorID=0 positions from BI_DB_PositionPnL, not copy positions
- **2-year rolling retention**: Historical data is purged

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High — derived from stored procedure logic |
| Tier 5 | ETL metadata | Standard ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | datetime | YES | Reporting date. One row per PI per day. Clustered index key. 2-year rolling retention. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 2 | ParentCID | bigint | YES | PI customer ID. The leader whose trades are copied. Top 100 by AUM or eCopiers within their Type. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 3 | ParentUserName | nvarchar(500) | YES | PI display username from etoroGeneral_History_GuruCopiers. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 4 | Type | varchar(8) | NOT NULL | Copy type: 'Copyfund' (AccountTypeID=9 Smart Portfolios) or 'Regular' (standard PIs). Used as ranking partition. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 5 | Timestamp | datetime | YES | GuruCopiers snapshot timestamp. Typically the start of the reporting day. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 6 | Copiers | int | YES | Total copier count for this PI on this date. COUNT(*) of copier rows from GuruCopiers (valid, depositing). (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 7 | eCopiers | int | YES | Effective copier count. Copiers with equity >= $100 (Cash + Investment + PnL). Key ranking metric. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 8 | AUM | money | YES | Total AUM including unrealized PnL. SUM(Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL) across copiers. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 9 | Cash | money | YES | Total cash held by copiers of this PI. SUM(Cash) from GuruCopiers. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 10 | Investment | money | YES | Total invested amount by copiers. SUM(Investment) from GuruCopiers. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 11 | PnL | money | YES | Total unrealized PnL across copiers. SUM(PnL) from GuruCopiers. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 12 | DetachedPosInvestment | money | YES | Total detached position investment. SUM(DetachedPosInvestment) from GuruCopiers. Detached positions retain their initial investment after the mirror closes. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 13 | Dit_PnL | money | YES | Total detached position PnL. SUM(Dit_PnL) from GuruCopiers. Unrealized PnL on detached positions. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 14 | rn_AUM | bigint | YES | AUM rank within Type. ROW_NUMBER() PARTITION BY Type ORDER BY AUM DESC. 1 = highest AUM in segment. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 15 | rn_eCopiers | bigint | YES | eCopiers rank within Type. ROW_NUMBER() PARTITION BY Type ORDER BY eCopiers DESC. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 16 | %AUM | money | YES | Share of total platform copy AUM. Computed: AUM / SUM(AUM across all PIs). Decimal fraction (e.g., 0.0172 = 1.72%). (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 17 | RealizedEquity | money | NOT NULL | PI's own realized equity from V_Liabilities.RealizedEquity. Filter: > 0 for inclusion. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 18 | STD | float | YES | Portfolio standard deviation from V_Liabilities.StandardDeviation. The PI's individual portfolio risk. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 19 | RealizedAUM | money | YES | Realized AUM excluding unrealized PnL. Cash + Investment + DetachedPosInvestment. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 20 | TotalProfit | money | YES | Daily net profit. (PnL + Dit_PnL) - (YesterdayPnL + YesterdayDit_PnL) + NetProfit from closed positions (MirrorTypeID=1). Zero if all components are null. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 21 | YesterdayAUM | money | NOT NULL | Previous day's AUM from yesterday's GuruCopiers snapshot. Used for daily change and MIMO reconciliation. ISNULL defaults to 0. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 22 | MoneyIn | decimal(38,2) | NOT NULL | Daily mirror money-in. SUM(Amount × -1) for ActionTypeID IN (15=CopyMirrorIn, 17=CopyMirrorInPartial). Positive = capital flowing into this PI's copies. ISNULL defaults to 0. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 23 | MoneyOut | decimal(38,2) | NOT NULL | Daily mirror money-out. SUM(Amount) for ActionTypeID IN (16=CopyMirrorOut, 18=CopyMirrorOutPartial). Positive = capital leaving copies. ISNULL defaults to 0. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 24 | UpdateDate | datetime | YES | ETL metadata: row insert timestamp (GETDATE()). (Tier 5 — ETL metadata) |
| 25 | IsBuyPercent | float | YES | Proportion of manual position equity in long (buy) positions. From BI_DB_PositionPnL WHERE MirrorID=0. 1.0 = 100% long. NULL if no manual positions. (Tier 2 — SP_rsk_RiskCorelation_PIs) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| ParentCID, ParentUserName | etoroGeneral_History_GuruCopiers | ParentCID, ParentUserName | Top 100 filter |
| Copiers, eCopiers, AUM components | etoroGeneral_History_GuruCopiers | Multiple | SUM aggregation |
| RealizedEquity, STD | V_Liabilities | RealizedEquity, StandardDeviation | Passthrough |
| TotalProfit | Dim_Position + GuruCopiers | NetProfit, PnL delta | Day-over-day computation |
| MoneyIn/Out | Fact_CustomerAction | Amount by ActionTypeID | Mirror MIMO |
| IsBuyPercent | BI_DB_PositionPnL | Amount+PositionPnL by IsBuy | Equity proportion |

### 5.2 ETL Pipeline

```
general.etoroGeneral_History_GuruCopiers (today + yesterday snapshots)
DWH_dbo.V_Liabilities (equity + STD)
DWH_dbo.Dim_Position + Dim_Mirror (closed position profit)
DWH_dbo.Fact_CustomerAction (MIMO flows)
BI_DB_dbo.BI_DB_PositionPnL (directional bias)
  |-- SP_rsk_RiskCorelation_PIs @Date (DELETE+INSERT, 2yr retention) ---|
  v
BI_DB_dbo.BI_DB_rsk_Risk_PI_Stats (162K rows)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rsk_risk_pi_stats
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ParentCID | DWH_dbo.Dim_Customer | PI customer dimension |
| Date | DWH_dbo.Dim_Date | Calendar dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Join | Purpose |
|--------|------|---------|
| BI_DB_dbo.BI_DB_rsk_Risk_PI_Correl | Date + ParentCID = CID1/CID2 | Correlation context |

---

## 7. Sample Queries

### 7.1 Top 10 PIs by AUM Today

```sql
SELECT ParentCID, ParentUserName, Type, AUM, eCopiers, STD, TotalProfit
FROM BI_DB_dbo.BI_DB_rsk_Risk_PI_Stats
WHERE Date = CAST(GETDATE()-1 AS DATE)
ORDER BY AUM DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
```

### 7.2 PI Daily Profit Trend

```sql
SELECT Date, AUM, TotalProfit, MoneyIn, MoneyOut, IsBuyPercent
FROM BI_DB_dbo.BI_DB_rsk_Risk_PI_Stats
WHERE ParentCID = 5572971
ORDER BY Date DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 24 T2, 0 T3, 0 T4, 1 T5 | Elements: 25/25, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_rsk_Risk_PI_Stats | Type: Table | Production Source: SP_rsk_RiskCorelation_PIs*
