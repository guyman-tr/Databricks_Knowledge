# BI_DB_dbo.BI_DB_DailyRiskAlert

> 5,433-row daily TRUNCATE+INSERT risk monitoring dashboard for Popular Investors (PIs) and Smart Portfolios, combining risk scores, activity flags, leverage exposure, portfolio concentration, copy metrics, and account status changes — covering all active depositing PIs (GuruStatusID >= 2) across Cadet/Champion/Elite/Elite Pro tiers, refreshed daily via SP_DailyRiskAlert (author: Bar, 2024-03-01).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source aggregation via SP_DailyRiskAlert — DWH_CIDsDailyRisk (risk scores), BI_DB_DailyPanel_Copy (PI tiers/classification), BI_DB_PositionPnL (exposure), Dim_Position (leverage), etoroGeneral_History_GuruCopiers (AUM/copiers), Fact_CustomerAction (logins), DWH_GainDaily (loss detection) |
| **Refresh** | Daily (SB_Daily, Priority 0) — TRUNCATE + INSERT (point-in-time snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_DailyRiskAlert is a daily risk monitoring dashboard for the eToro Popular Investor (PI) program. Each row represents one PI or Smart Portfolio manager with their current risk profile, activity status, leverage exposure, portfolio concentration, copy metrics, and any triggered alert flags.

The table contains 5,433 rows (current snapshot, TRUNCATE+INSERT daily). The population is all active depositing PIs: Dim_Customer WHERE GuruStatusID >= 2 AND IsValidCustomer = 1 AND IsDepositor = 1. The PI tiers are Cadet (58%), Champion (14%), Elite (3%), Elite Pro (<1%), with 25% having no tier assignment (NULL — not matched in BI_DB_DailyPanel_Copy).

The SP processes 9 distinct alert conditions, each generating a binary flag (1=triggered, 0=not):
1. **RiskJumpOver3**: Risk score changed by 3+ points from previous day
2. **InactiveLoginner**: No login in last 30 days
3. **InactiveFeedPoster**: No social feed post in last 6 months (100% triggered due to NULL date handling)
4. **InactiveTrader**: No position open/close in last 30 days
5. **EliteClassificationChange**: Elite/Elite Pro classification changed from yesterday
6. **Lost10Percent**: Lost >10% in a single day
7. **HoldsHighLevPosition**: Holds high-leverage position beyond thresholds
8. **InvestedValueover30**: Single instrument > 30% of portfolio
9. **ClosedAllPositions**: Had >5 positions and closed everything (Credit = RealizedEquity)

Risk scores (1-8) are derived from DWH_CIDsDailyRisk.AvgSTD mapped to bands via External_etoro_Internal_RiskScore. Mode at 4 (38%) and 5 (35%).

---

## 2. Business Logic

### 2.1 Risk Score Calculation

**What**: Converts portfolio volatility (AvgSTD) into a 1-8 risk score using predefined bands.
**Columns Involved**: RiskScore, RiskScore_prev2, LastAvgRiskScore, MaxRisckScore2Months
**Rules**:
- Source: DWH_CIDsDailyRisk.AvgSTD rounded to 4 decimal places
- Banded via External_etoro_Internal_RiskScore: ROUND(AvgSTD,4,1) BETWEEN MinValue AND MaxValue → RiskScore
- RiskScore_prev2: same calculation for @prevdate
- LastAvgRiskScore: AVG(RiskScore) for previous calendar month
- MaxRisckScore2Months: MAX(RiskScore) over last 2 months
- RiskJumpOver3 = ABS(RiskScore - RiskScore_prev2) >= 3

### 2.2 High Leverage Position Detection

**What**: Identifies PIs holding positions above leverage thresholds by instrument type.
**Columns Involved**: HoldsHighLevPosition, HighLevHoldingDetail, BuyPercent, SellPercent
**Rules**:
- Stocks/ETFs (InstrumentTypeID 5,6): leverage >= 5x
- Indices (InstrumentTypeID 4): leverage >= 10x
- Currencies/Commodities (InstrumentTypeID 1,2): leverage >= 20x
- Only open positions (CloseDateID = 0) with MirrorID = 0 (own, not copied), held > 30 days
- HighLevHoldingDetail = STRING_AGG of "{Leverage}-{InstrumentType}" per flagged position
- BuyPercent/SellPercent: proportion of flagged positions that are Buy vs Sell

### 2.3 Portfolio Concentration Detection

**What**: Identifies PIs with > 30% of portfolio value in a single instrument.
**Columns Involved**: InvestedValueover30, Value_percenet, MostInvestedInstrument
**Rules**:
- Value_percenet = Position_Value / (SUM(Position_Value) + Credit) for the top instrument per CID
- Position_Value = SUM(Amount + PositionPnL) from BI_DB_PositionPnL
- InvestedValueover30 = 1 when Value_percenet > 0.3
- MostInvestedInstrument = SymbolFull of the top instrument

### 2.4 AUM and Copy Metrics

**What**: Copy trading assets under management and copier count from the Guru Copiers snapshot.
**Columns Involved**: AUM, Copiers, Tier, DaysAsPI, Equity
**Rules**:
- AUM = SUM(Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL) from etoroGeneral_History_GuruCopiers
- Copiers = COUNT of active copy relationships
- Tier = GuruStatus from BI_DB_DailyPanel_Copy (Cadet/Champion/Elite/Elite Pro)
- DaysAsPI and Equity (TotalEquity) from same source

### 2.5 Activity Flags

**What**: Binary indicators for PI inactivity across login, trading, and social dimensions.
**Columns Involved**: InactiveLoginner, InactiveFeedPoster, InactiveTrader, ClosedAllPositions
**Rules**:
- InactiveLoginner: no Fact_CustomerAction ActionTypeID=14 (login) in last 30 days
- InactiveFeedPoster: LastPublishedPostDate > 6 months ago. NOTE: ISNULL defaults NULL to '1900-01-01', causing 100% trigger rate — likely a data quality issue
- InactiveTrader: no Dim_Position with CloseDateID >= 30 days ago or CloseDateID = 0 (still open)
- ClosedAllPositions: had > 5 positions yesterday AND Credit = RealizedEquity (all liquidated)

### 2.6 Block and Classification Tracking

**What**: Tracks PI copy-block status and Elite classification changes.
**Columns Involved**: CopiedBlock, BlockReason, BlockedOccurred, EliteClassificationChange, FromClassification, CurrentClassification
**Rules**:
- CopiedBlock = 1 when CID has OperationTypeID=2 in External_etoro_Customer_BlockedCustomerOperations
- BlockReason from Dictionary_BlockUnBlockReason.Reason
- EliteClassificationChange = 1 when today's Classification differs from yesterday's (Elite/Elite Pro only)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — small table (5K rows), no optimization needed
- **Index**: HEAP — no ordering benefit at this scale
- Table is TRUNCATE+INSERT daily — always contains exactly one day's snapshot

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PIs with triggered risk alerts | `WHERE RiskJumpOver3 = 1 OR Lost10Percent = 1 OR HoldsHighLevPosition = 1` |
| High-risk PIs by tier | `WHERE RiskScore >= 7 GROUP BY Tier` |
| PIs with concentrated portfolios | `WHERE InvestedValueover30 = 1 ORDER BY Value_percenet DESC` |
| Inactive PIs at risk | `WHERE InactiveTrader = 1 AND RiskScore >= 6` |
| Elite status changes | `WHERE EliteClassificationChange = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer profile details |
| BI_DB_dbo.BI_DB_DailyPanel_Copy | ON CID + DateID | Full PI panel metrics |
| BI_DB_dbo.BI_DB_PositionPnL | ON CID + DateID | Position-level detail |

### 3.4 Gotchas

- **InactiveFeedPoster = 1 for ALL rows** — ISNULL(LastPublishedPostDate, '1900-01-01') causes universal trigger. Likely a data quality issue in BI_DB_CIDFirstDates
- **DDL typo**: `MaxRisckScore2Months` has a typo ("Risck" instead of "Risk") — preserved from production DDL
- **DDL typo**: `Value_percenet` has a typo ("percenet" instead of "percent") — preserved from production DDL
- **BuyPercent/SellPercent are REVERSED in the SP**: `IsBuy=0` → BuyPercent, `IsBuy=1` → SellPercent. In eToro convention, `IsBuy=1` is Buy and `IsBuy=0` is Sell — the SP has the labels swapped
- **Single-day snapshot only** — no historical data retained. For historical analysis, use BI_DB_DailyPanel_Copy or DWH_CIDsDailyRisk
- **Tier NULL (25%)** means the PI was not found in BI_DB_DailyPanel_Copy for today's DateID
- **RiskScore NULL (33 rows)** means no matching risk band found for the AvgSTD value
- **PII present**: UserName, Manager names. Handle per data governance policies

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest — verified by source system owner |
| Tier 2 | SP code / ETL logic analysis | High — derived from version-controlled code |
| Tier 3 | Live data observation + schema inference | Medium — empirically verified but no code/wiki confirmation |
| Tier 4 | Inferred from naming / context | Lower — best-effort, needs reviewer validation |
| Tier 5 | Propagation rule (ETL metadata pattern) | Standard — canonical description for known ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReportTime | datetime | NO | Timestamp when the SP ran. Set to GETDATE() at execution. All rows share the same value per daily run. (Tier 2 — SP_DailyRiskAlert) |
| 2 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 3 | UserName | varchar(max) | YES | Customer login username. Unique (case-insensitive). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | AUM | money | YES | Assets Under Management — total copy portfolio value for this PI. SUM(Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL) from etoroGeneral_History_GuruCopiers. NULL if PI has no copiers. (Tier 2 — SP_DailyRiskAlert) |
| 5 | RealizedEquity | money | YES | Current realized equity from V_Liabilities for the reporting date. Represents account value excluding unrealized PnL. NULL if not in V_Liabilities for today. (Tier 2 — SP_DailyRiskAlert via V_Liabilities) |
| 6 | Tier | varchar(max) | YES | PI program tier: Cadet (58%), Champion (14%), Elite (3%), Elite Pro (<1%). Sourced from BI_DB_DailyPanel_Copy.GuruStatus. NULL (25%) when PI not found in DailyPanel_Copy for today. (Tier 2 — SP_DailyRiskAlert) |
| 7 | Country | varchar(max) | YES | Country name from Dim_Country.Name via Dim_Customer.CountryID JOIN. (Tier 2 — SP_DailyRiskAlert via Dim_Country) |
| 8 | Region | varchar(max) | YES | Geographic region from Dim_Country.Region via Dim_Customer.CountryID JOIN. (Tier 2 — SP_DailyRiskAlert via Dim_Country) |
| 9 | Manager | varchar(max) | YES | Account manager name (FirstName + LastName) from Dim_Manager via Dim_Customer.AccountManagerID. NULL if no manager assigned. (Tier 2 — SP_DailyRiskAlert via Dim_Manager) |
| 10 | RiskScore | int | YES | Portfolio risk score (1-8) derived from DWH_CIDsDailyRisk.AvgSTD mapped to bands via External_etoro_Internal_RiskScore. Mode at 4 (38%) and 5 (35%). NULL when no matching band found. (Tier 2 — SP_DailyRiskAlert) |
| 11 | RiskScore_prev2 | int | YES | Previous day's risk score, computed identically to RiskScore but for @prevdate. Used to detect RiskJumpOver3. NULL when no data for previous day. (Tier 2 — SP_DailyRiskAlert) |
| 12 | CopiedBlock | int | YES | Whether this PI has been blocked from being copied. 1=blocked (has OperationTypeID=2 in BlockedCustomerOperations), 0=not blocked. (Tier 2 — SP_DailyRiskAlert) |
| 13 | Copiers | int | YES | Number of active copiers for this PI. COUNT from etoroGeneral_History_GuruCopiers. NULL if not matched in #ParentUserName. (Tier 2 — SP_DailyRiskAlert) |
| 14 | BlockReason | varchar(max) | YES | Text reason for the copy block from Dictionary_BlockUnBlockReason.Reason. NULL when CopiedBlock=0 or no matching block record. (Tier 2 — SP_DailyRiskAlert) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — Propagation) |
| 16 | RiskJumpOver3 | int | YES | Alert flag: 1 when ABS(RiskScore - RiskScore_prev2) >= 3, indicating a significant risk score change. 0 otherwise. (Tier 2 — SP_DailyRiskAlert) |
| 17 | InactiveLoginner | int | YES | Alert flag: 1 when the PI has not logged in during the last 30 days (no Fact_CustomerAction ActionTypeID=14 in DateID range). 0 otherwise. (Tier 2 — SP_DailyRiskAlert) |
| 18 | InactiveFeedPoster | int | YES | Alert flag: 1 when @date > 6 months after LastPublishedPostDate. CAUTION: ISNULL defaults NULL LastPublishedPostDate to '1900-01-01', causing 100% trigger rate — effectively always 1. (Tier 2 — SP_DailyRiskAlert) |
| 19 | InactiveTrader | int | YES | Alert flag: 1 when the PI has no positions opened or closed in the last 30 days. 0 otherwise. (Tier 2 — SP_DailyRiskAlert) |
| 20 | EliteClassificationChange | int | YES | Alert flag: 1 when an Elite or Elite Pro PI's Classification changed from yesterday. 0 otherwise. Only triggers for Elite/Elite Pro tiers. (Tier 2 — SP_DailyRiskAlert) |
| 21 | Lost10Percent | int | YES | Alert flag: 1 when the PI lost more than 10% in a single day (DWH_GainDaily.Gain_d < -0.1). 0 otherwise. (Tier 2 — SP_DailyRiskAlert) |
| 22 | HoldsHighLevPosition | int | YES | Alert flag: 1 when the PI holds a high-leverage open position exceeding thresholds: Stocks/ETFs >= 5x, Indices >= 10x, FX/Commodities >= 20x. Only own positions (MirrorID=0) held > 30 days. (Tier 2 — SP_DailyRiskAlert) |
| 23 | HighLevHoldingDetail | varchar(max) | YES | Comma-separated list of high-leverage positions as "{Leverage}-{InstrumentType}" (e.g., "5-Stocks, 10-Indices"). NULL when HoldsHighLevPosition=0. Generated via STRING_AGG. (Tier 2 — SP_DailyRiskAlert) |
| 24 | InvestedValueover30 | int | YES | Alert flag: 1 when the PI's largest single-instrument position exceeds 30% of portfolio value. Portfolio = SUM(Position_Value) + Credit. (Tier 2 — SP_DailyRiskAlert) |
| 25 | Value_percenet | decimal(38,6) | YES | Percentage of portfolio value in the most concentrated instrument. Position_Value / (SUM(Position_Value) + Credit). 0 when InvestedValueover30=0. DDL typo: "percenet" instead of "percent". (Tier 2 — SP_DailyRiskAlert) |
| 26 | MostInvestedInstrument | varchar(max) | YES | Symbol (SymbolFull from Dim_Instrument) of the instrument with the highest portfolio concentration. NULL when InvestedValueover30=0. (Tier 2 — SP_DailyRiskAlert) |
| 27 | FromClassification | varchar(max) | YES | Previous day's PI classification tier (from BI_DB_DailyPanel_Copy yesterday). Only populated when EliteClassificationChange=1. NULL otherwise. (Tier 2 — SP_DailyRiskAlert) |
| 28 | CurrentClassification | varchar(max) | YES | Current day's PI classification tier (from BI_DB_DailyPanel_Copy today). Only populated when EliteClassificationChange=1. NULL otherwise. (Tier 2 — SP_DailyRiskAlert) |
| 29 | LastLoggedIn | date | YES | Most recent login date. ISNULL of last 30-day login from Fact_CustomerAction (ActionTypeID=14) or BI_DB_CIDFirstDates.LastLoggedIn fallback. (Tier 2 — SP_DailyRiskAlert) |
| 30 | LastPosOpenDate | date | YES | Date of the PI's most recent position opening. From BI_DB_CIDFirstDates.LastPosOpenDate. (Tier 2 — SP_DailyRiskAlert) |
| 31 | LastPublishedPostDate | date | YES | Date of the PI's most recent social feed post. From BI_DB_CIDFirstDates.LastPublishedPostDate. Used for InactiveFeedPoster calculation. (Tier 2 — SP_DailyRiskAlert) |
| 32 | DaysAsPI | int | YES | Number of days since becoming a Popular Investor. From BI_DB_DailyPanel_Copy.DaysAsPI. (Tier 2 — SP_DailyRiskAlert) |
| 33 | Equity | decimal(38,2) | YES | PI's total equity from BI_DB_DailyPanel_Copy.TotalEquity. Renamed to Equity in SP. (Tier 2 — SP_DailyRiskAlert) |
| 34 | ClosedAllPositions | int | YES | Alert flag: 1 when the PI had > 5 positions yesterday and now has zero (Credit = RealizedEquity). Indicates potential panic liquidation. (Tier 2 — SP_DailyRiskAlert) |
| 35 | BlockedOccurred | date | YES | Date when the PI was last blocked from being copied (MAX Occurred for OperationTypeID=2). NULL when not blocked. (Tier 2 — SP_DailyRiskAlert) |
| 36 | BuyPercent | decimal(12,2) | YES | Percentage of high-leverage flagged positions that are Buy-side. NOTE: SP labels are REVERSED — IsBuy=0 maps to BuyPercent in the SP, but in eToro convention IsBuy=0 is Sell. (Tier 2 — SP_DailyRiskAlert) |
| 37 | SellPercent | decimal(12,2) | YES | Percentage of high-leverage flagged positions that are Sell-side. NOTE: SP labels are REVERSED — IsBuy=1 maps to SellPercent in the SP, but in eToro convention IsBuy=1 is Buy. (Tier 2 — SP_DailyRiskAlert) |
| 38 | LastAvgRiskScore | int | YES | Average risk score for the previous calendar month. ROUND(AVG(RiskScore), 0) from DWH_CIDsDailyRisk for [FirstDayPrevMonth, LastDayPrevMonth]. (Tier 2 — SP_DailyRiskAlert) |
| 39 | MaxRisckScore2Months | int | YES | Maximum risk score over the last 2 months. MAX(RiskScore) from DWH_CIDsDailyRisk. DDL typo: "Risck" instead of "Risk". (Tier 2 — SP_DailyRiskAlert) |
| 40 | PlayerStatus | varchar(max) | YES | Player account status from Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID. Compliance and trading account status — 1=Normal (majority), other values indicate restricted, closed, banned, or special states. (Tier 2 — SP_DailyRiskAlert via Dim_PlayerStatus) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| UserName | DWH_dbo.Dim_Customer | UserName | Passthrough |
| AUM | general.etoroGeneral_History_GuruCopiers | Cash+Investment+PnL+... | SUM aggregation |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | Passthrough for DateID |
| RiskScore | DWH_CIDsDailyRisk + RiskScore bands | AvgSTD | BETWEEN band mapping |
| Country | DWH_dbo.Dim_Country | Name | JOIN via CountryID |
| Tier | BI_DB_DailyPanel_Copy | GuruStatus | Renamed |
| All alert flags | Multiple sources | Various | CASE-based computation |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (GuruStatusID>=2, IsValidCustomer=1, IsDepositor=1)
  + Dim_Country (Name, Region) + Dim_Manager (Name) + Dim_PlayerStatus (Name)
  |-- #gurus (PI population) ---|
  v
BI_DB_dbo.DWH_CIDsDailyRisk + External_etoro_Internal_RiskScore
  |-- AvgSTD → risk band mapping → #risk (today) + #Prev2Days (yesterday) ---|
  v
general.etoroGeneral_History_GuruCopiers
  |-- SUM(Cash+Inv+PnL+...) → AUM, COUNT(*) → Copiers ---|
  v
BI_DB_DailyPanel_Copy (Tier, Classification, DaysAsPI, Equity)
DWH_dbo.V_Liabilities (RealizedEquity, Credit)
Dim_Position (leverage, IsBuy → high-lev flags)
BI_DB_PositionPnL (concentration analysis → Value_percenet)
Fact_CustomerAction (logins), DWH_GainDaily (10% loss)
BI_DB_CIDFirstDates (last dates)
BlockedCustomerOperations (block status)
  |-- TRUNCATE + INSERT ---|
  v
BI_DB_dbo.BI_DB_DailyRiskAlert (5,433 rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension — full profile |
| Country | DWH_dbo.Dim_Country.Name | Country dimension |
| MostInvestedInstrument | DWH_dbo.Dim_Instrument.SymbolFull | Instrument dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none found in SSDT) | — | Risk management dashboard (consumed directly by BI tools) |

---

## 7. Sample Queries

### 7.1 PIs with Active Risk Alerts

```sql
SELECT CID, UserName, Tier, RiskScore, Country,
       RiskJumpOver3, Lost10Percent, HoldsHighLevPosition,
       InvestedValueover30, ClosedAllPositions
FROM [BI_DB_dbo].[BI_DB_DailyRiskAlert]
WHERE RiskJumpOver3 = 1
   OR Lost10Percent = 1
   OR HoldsHighLevPosition = 1
   OR ClosedAllPositions = 1
ORDER BY RiskScore DESC;
```

### 7.2 Elite PIs by Risk Score

```sql
SELECT CID, UserName, Tier, RiskScore, AUM, Copiers,
       DaysAsPI, Equity, LastAvgRiskScore, MaxRisckScore2Months
FROM [BI_DB_dbo].[BI_DB_DailyRiskAlert]
WHERE Tier IN ('Elite', 'Elite Pro')
ORDER BY RiskScore DESC, AUM DESC;
```

### 7.3 Portfolio Concentration Analysis

```sql
SELECT CID, UserName, MostInvestedInstrument,
       Value_percenet, AUM, Equity, Tier
FROM [BI_DB_dbo].[BI_DB_DailyRiskAlert]
WHERE InvestedValueover30 = 1
ORDER BY Value_percenet DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14 (P10 Atlassian unavailable)*
*Tiers: 2 T1, 37 T2, 0 T3, 0 T4, 1 T5 | Elements: 40/40, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_DailyRiskAlert | Type: Table | Production Source: Multi-source PI risk aggregation via SP_DailyRiskAlert*
