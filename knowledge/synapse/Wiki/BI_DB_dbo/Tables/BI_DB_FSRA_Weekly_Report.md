# BI_DB_dbo.BI_DB_FSRA_Weekly_Report

> 6.4M-row FSRA (Abu Dhabi, RegulationID=11) weekly regulatory report tracking all valid customers and their position activity (closed, opened, currently open) with instrument details, sourced via TRUNCATE+INSERT every Wednesday from DWH_dbo.Fact_SnapshotCustomer, Dim_Position, Dim_Instrument, and BI_DB_PositionPnL via SP_W_Wed_BI_DB_FSRA_Weekly_Report. Each row is a customer-position pair for the 7-day reporting window.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer + Dim_Position + Dim_Instrument + BI_DB_PositionPnL via `BI_DB_dbo.SP_W_Wed_BI_DB_FSRA_Weekly_Report` |
| **Refresh** | Weekly Wednesday (SB_Daily), TRUNCATE+INSERT — only latest week retained |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_FSRA_Weekly_Report is a **regulatory compliance snapshot** for the **FSRA (Financial Services Regulatory Authority, Abu Dhabi)** jurisdiction. It captures all valid customers (IsValidCustomer=1) under RegulationID=11 and their position-level trading activity for a rolling 7-day window (Monday–Sunday, ending on the Wednesday execution date).

Each row represents a **customer-position pair**: one row per CID per position that was closed during the period, opened during the period, or currently open at period end. Customers with no position activity still appear with NULL position columns (35,836 rows in current snapshot). The report includes customer classification (Retail/Retail Pending/Pending from MifidCategorization), verification status, and whether the customer newly reached VL2 during the period.

**Key metrics**: 6,439,638 rows in current snapshot. 3 client classifications: Retail (92.0%), Retail Pending (7.9%), Pending (0.1%). 7 instrument types: Stocks (90.2%), Crypto (3.9%), ETF (3.7%), Commodities (1.3%), Indices (0.2%), Currencies (0.1%). Position breakdown: currently open (92.3%), opened during period (3.7%), closed during period (3.4%), no positions (0.6%).

**Author**: Yarden Sabadra (2024-03-11).

---

## 2. Business Logic

### 2.1 FSRA Population Filter

**What**: Restricts to FSRA-regulated valid customers using SCD snapshot.
**Columns Involved**: RealCID, Regulation, VerificationLevelID
**Rules**:
- Fact_SnapshotCustomer WHERE RegulationID=11 AND IsValidCustomer=1
- Dim_Range SCD resolution: @EndDateID BETWEEN FromDateID AND ToDateID
- JOIN to Dim_Regulation (ID field, not DWHRegulationID) for regulation name

### 2.2 Position Activity Classification (Three-Way UNION)

**What**: Classifies each position into one of three activity categories.
**Columns Involved**: PositionID, WasClosedDuringPeriod, WasOpenedDuringPeriod, IsCurrentOpen
**Rules**:
- **Closed**: Dim_Position WHERE CloseDateID BETWEEN StartDateID AND EndDateID → WasClosedDuringPeriod=1. Amount = Amount + NetProfit (realized value)
- **Opened**: Dim_Position WHERE OpenDateID BETWEEN StartDateID AND EndDateID AND IsPartialCloseChild=0 → WasOpenedDuringPeriod=1. Amount = InitialAmountCents/100 (initial investment)
- **Currently Open**: BI_DB_PositionPnL WHERE DateID=EndDateID → IsCurrentOpen=1. Amount = Amount + PositionPnL (current equity)
- UNION (not UNION ALL) — deduplicates positions appearing in multiple categories
- LEFT JOIN to population: customers with no matching positions get NULL position columns

### 2.3 New V2 Customer Detection

**What**: Flags customers who reached verification level 2 during the reporting period.
**Columns Involved**: IsNewV2Customer, VerificationLevel2Date
**Rules**:
- VerificationLevel2Date from BI_DB_CIDFirstDates (joined on GCID)
- ISNULL(VerificationLevel2Date, '1900-01-01') — sentinel for never-verified
- IsNewV2Customer = 1 when VL2Date falls within StartDate–EndDate

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RealCID) — co-located JOINs on RealCID to Fact_SnapshotCustomer and other CID-based tables. Clustered index on RealCID for efficient customer lookups. TRUNCATE pattern means only one week of data exists at any time.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many FSRA customers have open positions? | `SELECT COUNT(DISTINCT RealCID) FROM BI_DB_FSRA_Weekly_Report WHERE IsCurrentOpen = 1` |
| Position count by instrument type | `SELECT InstrumentType, COUNT(*) FROM BI_DB_FSRA_Weekly_Report WHERE PositionID IS NOT NULL GROUP BY InstrumentType` |
| New VL2 customers this week | `SELECT * FROM BI_DB_FSRA_Weekly_Report WHERE IsNewV2Customer = 1 AND PositionID IS NULL` (unique per CID) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Additional customer attributes (TanganyID, PlayerLevelID) |
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Full instrument details (leverage rules, exchange) |

### 3.4 Gotchas

- **TRUNCATE table** — only the most recent weekly snapshot is retained. Historical weeks are lost on each Wednesday refresh.
- **NULL position columns** — 35,836 rows have NULL PositionID/WasClosedDuringPeriod/WasOpenedDuringPeriod/IsCurrentOpen. These are FSRA customers with no position activity during the period. Do NOT filter them out if counting total FSRA population.
- **UNION deduplication** — a position that was both opened AND closed within the same 7-day window appears only once (per UNION behavior). The flag values determine which category won.
- **Amount calculation varies by category** — closed uses realized value (Amount+NetProfit), opened uses initial investment (InitialAmountCents/100), current-open uses equity (Amount+PositionPnL). Do not compare Amount values across categories without understanding this.
- **Regulation is always 'FSRA'** — the column exists for schema consistency but has zero analytical variance in this table.
- **Backup table exists**: BI_DB_FSRA_Weekly_Report_Backup_20241114 — a one-time snapshot preserved before a schema change.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Domain expert input or ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | StartDate | date | NO | Start of the 7-day reporting window. Computed as DATEADD(DAY, -6, @Date) — always a Monday when @Date is Wednesday. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 2 | StartDateID | int | NO | YYYYMMDD int of StartDate. Used for date-range filtering on Dim_Position. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 3 | EndDate | date | NO | End of the 7-day reporting window. The @Date parameter value (Wednesday execution date). (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 4 | EndDateID | int | NO | YYYYMMDD int of EndDate. Used for PositionPnL and SCD snapshot resolution. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 5 | RealCID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 6 | Regulation | varchar(50) | YES | Regulatory entity name. Always 'FSRA' in this table (filtered to RegulationID=11). FK to Dim_Regulation.Name via Dim_Regulation.ID. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 7 | Country | varchar(50) | YES | Country name from Dim_Country via Fact_SnapshotCustomer.CountryID. Top values: United Arab Emirates, Saudi Arabia, and other GCC/MENA countries. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 8 | Client_Classification | varchar(50) | YES | MiFID categorization from Dim_MifidCategorization. 3 values: Retail (92.0%), Retail Pending (7.9%), Pending (0.1%). (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 9 | VerificationLevelID | int | YES | Customer verification level at snapshot time. From Fact_SnapshotCustomer. Values observed: 2, 3. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 10 | VerificationLevel2Date | datetime2(7) | NO | Date when customer reached verification level 2. From BI_DB_CIDFirstDates (joined on GCID). ISNULL sentinel: 1900-01-01 = never reached VL2. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 11 | IsNewV2Customer | int | YES | Flag: 1 if customer reached VL2 during this reporting period (VL2Date BETWEEN StartDate AND EndDate), 0 otherwise. Used for new customer onboarding metrics. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 12 | PositionID | bigint | YES | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. NULL for customers with no position activity during the period. (Tier 1 — Trade.PositionTbl) |
| 13 | WasClosedDuringPeriod | int | YES | Flag: 1 if this position was closed during StartDateID–EndDateID, 0 otherwise. NULL for no-position rows. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 14 | WasOpenedDuringPeriod | int | YES | Flag: 1 if this position was opened during StartDateID–EndDateID (excludes IsPartialCloseChild=1), 0 otherwise. NULL for no-position rows. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 15 | IsCurrentOpen | int | YES | Flag: 1 if this position is currently open (in BI_DB_PositionPnL on EndDateID), 0 otherwise. NULL for no-position rows. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 16 | InstrumentType | varchar(50) | YES | Text label for InstrumentTypeID -- DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 17 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. NULL for no-position rows. (Tier 1 — Trade.Instrument) |
| 18 | InstrumentName | varchar(max) | YES | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). (Tier 3 — live data, etoro.Trade.GetInstrument) |
| 19 | InstrumentDisplayName | varchar(max) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Emaar Properties PJSC' vs 'EMAAR.AE/AED'). NULL for instruments without metadata entries or no-position rows. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 20 | Amount | money | YES | Position value in USD. Calculation varies by position category: closed=Amount+NetProfit (realized), opened=InitialAmountCents/100 (initial), current-open=Amount+PositionPnL (equity). NULL for no-position rows. (Tier 2 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |
| 21 | UpdateDate | date | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — SP_W_Wed_BI_DB_FSRA_Weekly_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| StartDate | — | — | DATEADD(DAY, -6, @Date) |
| StartDateID | — | — | YYYYMMDD int of StartDate |
| EndDate | — | — | @Date parameter |
| EndDateID | — | — | YYYYMMDD int of EndDate |
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (FSRA filter) |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough via RegulationID=11 |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via CountryID |
| Client_Classification | DWH_dbo.Dim_MifidCategorization | Name | Passthrough via MifidCategorizationID |
| VerificationLevelID | DWH_dbo.Fact_SnapshotCustomer | VerificationLevelID | Passthrough |
| VerificationLevel2Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel2Date | ISNULL(..., '1900-01-01') |
| IsNewV2Customer | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel2Date | CASE WHEN VL2Date BETWEEN dates THEN 1 ELSE 0 |
| PositionID | DWH_dbo.Dim_Position / BI_DB_PositionPnL | PositionID | Passthrough from 3-way UNION |
| WasClosedDuringPeriod | DWH_dbo.Dim_Position | CloseDateID | ETL flag: 1 if closed in window |
| WasOpenedDuringPeriod | DWH_dbo.Dim_Position | OpenDateID | ETL flag: 1 if opened in window |
| IsCurrentOpen | BI_DB_dbo.BI_DB_PositionPnL | DateID | ETL flag: 1 if open on EndDateID |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Passthrough |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough |
| Amount | Multiple | Multiple | Category-dependent calculation |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Trade.PositionTbl + Customer.CustomerStatic + Trade.Instrument (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Trade_PositionTbl + etoro_Customer_CustomerStatic + etoro_Trade_Instrument
  |-- SP_Dim_Position / SP_Dim_Customer / SP_Dim_Instrument ---|
  v
DWH_dbo.Dim_Position + Fact_SnapshotCustomer + Dim_Instrument + Dim_Regulation + Dim_Country + Dim_MifidCategorization
  |
  |-- BI_DB_dbo.BI_DB_CIDFirstDates (dependency: VL2 dates)
  |-- BI_DB_dbo.BI_DB_PositionPnL (dependency: current open positions)
  |
  |-- SP_W_Wed_BI_DB_FSRA_Weekly_Report @Date (Weekly Wednesday) ---|
  |   (TRUNCATE + 3-way UNION of closed/opened/current-open + LEFT JOIN population)
  v
BI_DB_dbo.BI_DB_FSRA_Weekly_Report (6.4M rows, single week snapshot)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| RealCID | DWH_dbo.Dim_Customer.RealCID | FSRA-regulated customer |
| PositionID | DWH_dbo.Dim_Position.PositionID | Position with activity during period |
| InstrumentID | DWH_dbo.Dim_Instrument.InstrumentID | Traded instrument |
| VerificationLevel2Date | BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel2Date | VL2 milestone date |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the BI_DB_dbo codebase.

---

## 7. Sample Queries

### 7.1 FSRA Customer Position Summary by Country

```sql
SELECT Country,
       COUNT(DISTINCT RealCID) AS TotalCustomers,
       SUM(CASE WHEN IsCurrentOpen = 1 THEN 1 ELSE 0 END) AS OpenPositions,
       SUM(CASE WHEN WasClosedDuringPeriod = 1 THEN 1 ELSE 0 END) AS ClosedPositions
FROM BI_DB_dbo.BI_DB_FSRA_Weekly_Report
GROUP BY Country
ORDER BY TotalCustomers DESC
```

### 7.2 Instrument Type Breakdown for Current Week

```sql
SELECT InstrumentType,
       COUNT(DISTINCT RealCID) AS UniqueCIDs,
       COUNT(PositionID) AS PositionCount,
       SUM(Amount) AS TotalAmount
FROM BI_DB_dbo.BI_DB_FSRA_Weekly_Report
WHERE PositionID IS NOT NULL
GROUP BY InstrumentType
ORDER BY TotalAmount DESC
```

### 7.3 New VL2 Customers This Week

```sql
SELECT RealCID, VerificationLevel2Date, Client_Classification, Country
FROM BI_DB_dbo.BI_DB_FSRA_Weekly_Report
WHERE IsNewV2Customer = 1
GROUP BY RealCID, VerificationLevel2Date, Client_Classification, Country
ORDER BY VerificationLevel2Date DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 3 T1, 15 T2, 1 T3, 0 T4, 1 T5 | Elements: 21/21, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_FSRA_Weekly_Report | Type: Table | Production Source: Multiple DWH_dbo sources via SP_W_Wed_BI_DB_FSRA_Weekly_Report*
