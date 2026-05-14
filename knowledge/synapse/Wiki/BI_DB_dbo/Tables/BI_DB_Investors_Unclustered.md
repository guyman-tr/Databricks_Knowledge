# BI_DB_dbo.BI_DB_Investors_Unclustered

> Estimated ~75M-row daily investor activity report aggregating customer count, net money invested (Amount), and AUM/AUA by AccountManagerID x CountryID x RegulationID x ActionType (Manual/Copy/Balance) x InstrumentType x AssetType. Date range: Jan 2021 -- Apr 2026 (~1,926 daily snapshots, ~37K rows/day). Companion to BI_DB_Investors but WITHOUT Salesforce ClusterSF dimension. Daily delete-insert via SP_InvestorReport.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Investor Activity Report -- Daily Aggregate, Unclustered) |
| **Production Source** | Derived -- DWH dimensions/facts aggregated by SP_InvestorReport |
| **Refresh** | Daily delete-insert by DateID (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_Investors_Unclustered` is a **daily investor activity report** providing a multi-dimensional aggregation of customer engagement across the eToro platform. Each row represents a unique combination of Date x AccountManager x Country x Regulation x ActionType x InstrumentType x AssetType, with counts of customers, net money invested, and assets under management/administration.

The table holds an estimated ~75M rows across ~1,926 daily snapshots from January 2021 to April 2026 (~37K rows per day). SP_InvestorReport processes three source streams:

1. **Manual**: Direct (non-copy) position activity -- open/close trades from Fact_CustomerAction (ActionTypeID 1=Open, 4=Close). AUA from BI_DB_PositionPnL (Amount + PositionPnL for non-mirror positions).
2. **Copy**: Copy-trading activity -- mirror-based investments from Dim_Mirror + Fact_CustomerAction (ActionTypeID 15-18). AUM from etoroGeneral_History_GuruCopiers (Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL).
3. **Balance**: Cash balance positions -- uninvested credit from V_Liabilities (current day minus prior day for NetMI).

Each stream is aggregated by dimensional axes, then UNION'd into the final table.

### Relationship to BI_DB_Investors

This table is the **unclustered companion** to `BI_DB_Investors` (which adds a ClusterSF column from BI_DB_CID_DailyCluster). SP_InvestorReport populates both BI_DB_Investors_STG (staging) and this table. SP_InvestorReport_Cluster then reads STG to populate the clustered version. The Unclustered version starts from Jan 2021; the clustered version goes back to Jul 2019.

---

## 2. Business Logic

### 2.1 Three Source Streams

**What**: Activity is segmented into Manual, Copy, and Balance streams.
**Columns Involved**: ActionType, Customers, Amount, AUM_AUA
**Rules**:
- Manual: Direct position open/close from Fact_CustomerAction (ActionTypeID IN 1, 4). Customers = COUNT(DISTINCT CID), Amount = SUM(-1 * fca.Amount), AUA = SUM(BI_DB_PositionPnL.Amount + PositionPnL)
- Copy: Mirror-based copy trading from Dim_Mirror + Fact_CustomerAction (ActionTypeID IN 15, 16, 17, 18). Customers = COUNT(DISTINCT CID), Amount = SUM(fca.Amount * -1), AUM = SUM(GuruCopiers components)
- Balance: Cash positions from V_Liabilities. Customers = COUNT(CID), Amount = today's credit minus yesterday's credit, AUA = today's credit

### 2.2 Asset Type Classification

**What**: Classifies activity into investment vs trading vs non-invested vs copy.
**Columns Involved**: AssetType
**Rules**:
- 'Investment': InstrumentTypeID IN (4, 5, 6) AND Leverage < 3 -- long-term, low-leverage stock/ETF holding
- 'Trade': All other manual positions -- short-term/leveraged
- 'Copy': All copy-trading activity
- 'NonInvested': Balance stream (uninvested cash)

### 2.3 Instrument Type for Copy Stream

**What**: Copy stream uses MirrorTypeID to determine InstrumentType.
**Columns Involved**: InstrumentType
**Rules**:
- MirrorTypeID IN (1, 2) -> 'Copy Trading' (Regular, CopyMe)
- Other MirrorTypeID -> 'Copy Portfolio' (Smart Portfolio, Fund)

### 2.4 Customer Validity Filter

**What**: Only valid depositing customers are included.
**Columns Involved**: All rows
**Rules**:
- Fact_SnapshotCustomer.IsValidCustomer = 1
- Fact_SnapshotCustomer.IsDepositor = 1
- Dim_Range date boundaries: FromDateID <= @ddINT AND ToDateID >= @ddINT

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date ASC. Large table (~75M rows). Always filter on Date or DateID for efficient index seeks.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily investor activity by regulation | `WHERE DateID = @date GROUP BY RegulationID` |
| AUM trend by country | `SELECT DateID, CountryID, SUM(AUM_AUA) GROUP BY DateID, CountryID` |
| Net money invested by instrument type | `WHERE DateID = @date GROUP BY InstrumentType` |
| Manual vs Copy activity comparison | `WHERE DateID = @date GROUP BY ActionType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Regulation | RegulationID | Regulation name |
| DWH_dbo.Dim_Country | CountryID | Country name |
| DWH_dbo.Dim_AccountManager | AccountManagerID | Account manager details |

### 3.4 Gotchas

- **Large table**: ~75M rows -- always filter on Date or DateID. Without a date filter, queries scan the entire table
- **Amount = NetMI**: The DDL column "Amount" is populated from the SP's "NetMI" (Net Money Invested) field. The naming mismatch can be confusing
- **AUM_AUA dual meaning**: Maps to AUM for Copy streams (mirror portfolio value) and AUA for Manual/Balance streams (position value or cash credit). The semantic distinction is collapsed into one column
- **Customers count inconsistency**: Manual/Copy use COUNT(DISTINCT CID), Balance uses COUNT(CID) -- potential double-counting in Balance if a CID appears in multiple balance rows
- **No ClusterSF**: Unlike BI_DB_Investors, this table has no Salesforce cluster dimension. Use BI_DB_Investors if cluster-level analysis is needed
- **Index on Date not DateID**: The clustered index is on the `Date` column (date type), not `DateID` (int). Filter on `Date` for optimal index usage, or on `DateID` for semantic clarity (both map 1:1)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date for this daily snapshot. (Tier 2 -- SP_InvestorReport) |
| 2 | DateID | int | YES | Date identifier in YYYYMMDD integer format. Derived as CONVERT(CHAR(8), @dd, 112). Used for delete-insert partitioning and efficient date-range queries. (Tier 2 -- SP_InvestorReport) |
| 3 | AccountManagerID | int | YES | Salesforce account manager ID. FK to DWH_dbo.Dim_AccountManager. Identifies which AM manages the customers in this bucket. Sourced from Fact_SnapshotCustomer. (Tier 2 -- SP_InvestorReport) |
| 4 | CountryID | int | YES | Country of customer registration. FK to DWH_dbo.Dim_Country. Sourced from Fact_SnapshotCustomer. (Tier 2 -- SP_InvestorReport) |
| 5 | RegulationID | tinyint | YES | Regulatory entity ID. FK to DWH_dbo.Dim_Regulation. 1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, 10=eToro US, 11=FSRA, etc. Sourced from Fact_SnapshotCustomer. (Tier 2 -- SP_InvestorReport) |
| 6 | ActionType | varchar(50) | YES | Activity source stream: 'Manual' (direct position open/close), 'Copy' (copy-trading mirror activity), 'Balance' (uninvested cash). Determines how Customers/Amount/AUM_AUA are computed. (Tier 2 -- SP_InvestorReport) |
| 7 | InstrumentType | varchar(50) | YES | Instrument category. Manual stream: Stocks, ETF, Crypto Currencies, Commodities, Indices, Currencies (from Dim_Instrument.InstrumentType). Copy stream: 'Copy Trading' (MirrorTypeID 1,2) or 'Copy Portfolio' (other). Balance stream: 'Balance'. (Tier 2 -- SP_InvestorReport) |
| 8 | AssetType | varchar(50) | YES | Investment classification. 'Investment' (InstrumentTypeID 4/5/6 AND Leverage<3), 'Trade' (all other manual positions), 'Copy' (copy stream), 'NonInvested' (balance stream). (Tier 2 -- SP_InvestorReport) |
| 9 | Customers | decimal(38,2) | YES | Count of customers in this dimensional bucket. Manual/Copy: COUNT(DISTINCT CID). Balance: COUNT(CID). Stored as decimal for aggregation flexibility. (Tier 2 -- SP_InvestorReport) |
| 10 | Amount | decimal(38,2) | YES | Net money invested (NetMI) for this bucket. Manual: SUM(-1 * Fact_CustomerAction.Amount). Copy: SUM(mirror action amounts * -1). Balance: today's V_Liabilities.Credit minus yesterday's. In USD. Note: DDL column name is "Amount" but populated from SP's "NetMI" field. NULL for some Copy rows where no action occurred on the date. (Tier 2 -- SP_InvestorReport) |
| 11 | AUM_AUA | decimal(38,2) | YES | Assets Under Management (for Copy stream: GuruCopiers Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL) or Assets Under Administration (for Manual stream: BI_DB_PositionPnL Amount+PositionPnL; for Balance stream: V_Liabilities.Credit). In USD. 49 NULLs observed in recent April 2026 data (~0.01%). (Tier 2 -- SP_InvestorReport) |
| 12 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_InvestorReport. Set to GETDATE(). (Tier 5 -- SP_InvestorReport) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | SP parameter | @dd | Direct assignment |
| DateID | SP parameter | @dd | CONVERT(CHAR(8), @dd, 112) |
| AccountManagerID | DWH_dbo.Fact_SnapshotCustomer | AccountManagerID | Passthrough via temp tables |
| CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | Passthrough via temp tables |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | Passthrough via temp tables |
| ActionType | SP_InvestorReport | Computed | CASE on ActionTypeID (Manual) / literal 'Copy' / literal 'Balance' |
| InstrumentType | DWH_dbo.Dim_Instrument / DWH_dbo.Dim_Mirror | InstrumentType / MirrorTypeID | Passthrough for Manual; CASE for Copy; literal for Balance |
| AssetType | SP_InvestorReport | Computed | CASE on InstrumentTypeID + Leverage |
| Customers | SP_InvestorReport | CID | COUNT(DISTINCT CID) or COUNT(CID) |
| Amount | DWH_dbo.Fact_CustomerAction / DWH_dbo.V_Liabilities | Amount / Credit | SUM(-1*Amount) or credit delta |
| AUM_AUA | BI_DB_PositionPnL / etoroGeneral_History_GuruCopiers / V_Liabilities | Various | SUM of position/portfolio/credit values |
| UpdateDate | SP_InvestorReport | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (leverage, open/close dates)
DWH_dbo.Fact_CustomerAction (ActionTypeID 1,4,15-18)
DWH_dbo.Dim_Instrument (InstrumentType classification)
DWH_dbo.Fact_SnapshotCustomer (AM, Country, Regulation, validity)
DWH_dbo.Dim_Mirror (active copy relationships)
BI_DB_dbo.BI_DB_PositionPnL (position AUA)
general.etoroGeneral_History_GuruCopiers (copy AUM)
DWH_dbo.V_Liabilities (cash credit)
  |-- SP_InvestorReport @dd (daily, delete-insert by DateID) --------|
  |   Step 1: Build #leverage, #fca temp tables                      |
  |   Step 2: #openClose = Manual open/close with AssetType CASE     |
  |   Step 3: #ManNetMI = Net MI aggregation                         |
  |   Step 4: #AUA = Position PnL aggregation                        |
  |   Step 5: #manual = FULL OUTER JOIN AUA + NetMI                  |
  |   Step 6: INSERT BI_DB_Investors_STG (Manual stream)             |
  |   Step 7: #ActiveMirror = active copy mirrors                    |
  |   Step 8: #CopyType, #AUM = copy portfolio AUM                   |
  |   Step 9: INSERT BI_DB_Investors_STG (Copy stream)               |
  |   Step 10: INSERT BI_DB_Investors_STG (Balance stream)           |
  |   Step 11: Aggregate STG -> #ManualInvestment, #CopyInvestment,  |
  |            #Cash temp tables                                      |
  |   Step 12: DELETE + INSERT Unclustered = UNION of 3 aggregates   |
  v
BI_DB_dbo.BI_DB_Investors_Unclustered (~75M rows, daily)
  (Not in Generic Pipeline -- _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountManagerID | DWH_dbo.Dim_AccountManager | AM details |
| CountryID | DWH_dbo.Dim_Country | Country name |
| RegulationID | DWH_dbo.Dim_Regulation | Regulation name |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo. SP_InvestorReport_Cluster reads from BI_DB_Investors_STG (not from this table) to populate the clustered BI_DB_Investors version.

---

## 7. Sample Queries

### 7.1 Daily AUM by Regulation

```sql
SELECT RegulationID,
       SUM(AUM_AUA) AS total_aum,
       SUM(Customers) AS total_customers
FROM [BI_DB_dbo].[BI_DB_Investors_Unclustered]
WHERE DateID = 20260411
GROUP BY RegulationID
ORDER BY total_aum DESC
```

### 7.2 Monthly Net Investment Trend by ActionType

```sql
SELECT DateID / 100 AS year_month,
       ActionType,
       SUM(Amount) AS net_investment,
       SUM(Customers) AS customer_buckets
FROM [BI_DB_dbo].[BI_DB_Investors_Unclustered]
WHERE DateID >= 20260101
GROUP BY DateID / 100, ActionType
ORDER BY year_month, ActionType
```

### 7.3 Instrument Type Distribution for a Date

```sql
SELECT InstrumentType,
       SUM(Customers) AS customers,
       SUM(AUM_AUA) AS total_aum_aua
FROM [BI_DB_dbo].[BI_DB_Investors_Unclustered]
WHERE DateID = 20260411
GROUP BY InstrumentType
ORDER BY total_aum_aua DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4, 1 T5 | Elements: 12/12, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Investors_Unclustered | Type: Table | Production Source: Derived -- DWH dimensions/facts by SP_InvestorReport*
