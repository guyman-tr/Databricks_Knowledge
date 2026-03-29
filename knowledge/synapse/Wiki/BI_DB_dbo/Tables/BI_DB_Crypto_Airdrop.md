# BI_DB_dbo.BI_DB_Crypto_Airdrop

| Property | Value |
|----------|-------|
| **Object Type** | TABLE |
| **Schema** | BI_DB_dbo |
| **Row Count** | ~1,711,544 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Source System** | `BI_DB_CIDFirstDates` + `Dim_Position` + `Dim_Instrument` |
| **Writer SP** | `SP_BI_DB_Crypto_Airdrop` |
| **ETL Pattern** | TRUNCATE-INSERT (daily full reload) |
| **Refresh** | Daily (SB_Daily, Priority 20) |

## 1. Business Meaning

`BI_DB_Crypto_Airdrop` tracks the trading behaviour of newly verified (V3) customers in eligible countries after eToro's crypto airdrop campaign, which rolled out in three waves starting 2023-05-15. The table measures whether a customer's first engagement was an airdrop position or an organic trade, then tracks their subsequent trading activity across three asset categories — Real Crypto, Real Stocks/ETF, and CFDs — over 30-day and 60-day observation windows.

The business goal is to evaluate the effectiveness of the crypto airdrop as a customer activation tool: Do airdrop recipients (AD clients) go on to trade more, diversify into other asset classes, or start trading CFDs? The table enables comparison between airdrop recipients and organic customers from the same V3 cohort.

**Population scope:**
- V3-verified customers (`Verified = 3`, `VerificationLevel3Date >= 2023-05-15`)
- In 30 eligible countries (phased rollout: Wave 1 = Romania/Bulgaria, Wave 2 = AU/UAE/NL/CH/IE/CZ/CO/MY/MX/PH/TW/SG/TH/VN, Wave 3 = UK/DE/FR/IT)
- Excludes DesignatedRegulationIDs 7 and 8 (US/NFA regulations)
- Only customers who registered AFTER their country's rollout date (`IsRelevant = 1`)

**Eligible airdrop instruments:** BTC, ETH, DOGE, SHIBxM, LTC, COMP, LINK, BCH, XLM (InstrumentTypeID=10, IsMajorID=1)

## 2. Business Logic

### 2.1 Client Classification (AD vs Non-AD)

- **AD Client** (`IsADClient = 1`): Customer whose first position (RN=1 by open date) was a crypto airdrop (`IsAirDrop = 1` in Dim_Position) in one of the 9 eligible instruments.
- **Non-AD Client** (`IsADClient = 0`): Customer whose first action was organic (self-directed trade, not an airdrop).

### 2.2 First Position Logic

For AD clients, the "first position" columns (`FirstPositionID`, `FirstPositionOpenOccured`, etc.) capture the **2nd position** (RN=2), since the 1st was the airdrop itself. For non-AD clients, they capture the actual 1st position (RN=1). If no qualifying position exists, sentinel values are used: `-1` for IDs/amounts, `'1900-01-01'` for dates, `'A'` for text.

### 2.3 Observation Windows

The 30/60-day windows are anchored differently by client type:
- **AD clients**: Anchor = `OpenOccurredAD` (airdrop position open datetime)
- **Non-AD clients**: Anchor = `FirstPositionOpenOccured` (first organic trade datetime)

The 60-day metrics count activity in the 30–60 day range only (not cumulative from day 0).

### 2.4 Asset Category Classification

| Category | Rule |
|----------|------|
| Real Crypto | `IsSettledOnOpen = 1 AND InstrumentTypeID = 10` |
| Real Stocks/ETF | `IsSettledOnOpen = 1 AND InstrumentTypeID IN (5, 6)` |
| CFDs | `IsSettledOnOpen = 0` (any instrument, leveraged) |

_Encoding for `Dim_Position.IsSettledOnOpen` in the rules above: **1 = real asset, 0 = CFD asset** (Tier 5 — Expert Review)._

### 2.5 Sentinel Values

| Sentinel | Meaning |
|----------|---------|
| `1900-01-01` | No date / no position opened |
| `2900-01-01` | Never traded CFD (future sentinel for MinOpenOccuredCFD) |
| `-1` | No position / not applicable (IDs, amounts) |
| `'A'` | No instrument / not applicable (text) |

### 2.6 Position Filters

Positions are filtered to:
- `MirrorID = 0` or `NULL` — excludes copy-trading positions
- `OpenOccurred >= VerificationLevel3Date` — only positions opened after V3 verification

## 3. Query Advisory

### 3.1 Distribution & Index Strategy

- **ROUND_ROBIN** — even distribution across all nodes. No collocated joins.
- **HEAP** — no clustered index. Full table scans for all queries.
- For customer-level lookup, consider adding a non-clustered index on CID.

### 3.2 Recommended Patterns

| Use Case | Pattern |
|----------|---------|
| Airdrop recipients only | `WHERE IsADClient = 1` |
| Organic customers only | `WHERE IsADClient = 0` |
| Customers who traded CFDs | `WHERE WasTradedCFD = 1` |
| Active within 30 days | `WHERE 30DaysCountRealCrypto + 30DaysCountRealStocksETF + 30DaysCountCFDs > 0` |
| By country | `WHERE Country = 'United Kingdom'` |
| Exclude sentinel rows | `WHERE FirstPositionID <> -1` |

### 3.3 Performance Notes

- **1.7M rows** — moderate size. ROUND_ROBIN + HEAP means any aggregation requires a full scan but performance is acceptable at this row count.
- **Sentinel values** — filter out `-1` and `'1900-01-01'` values before aggregating averages or counts to avoid skewing.
- **60-day metrics are NOT cumulative** — they cover day 31–60 only. To get total 60-day activity, add `30Days*` + `60Days*` metrics.

### 3.4 Data Freshness

| Metric | Value |
|--------|-------|
| Last loaded | 2026-03-11 04:55:54 |
| Refresh frequency | Daily |
| Latency | Same-day V3 verifications and position opens reflected next morning |

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer Real account ID. From BI_DB_CIDFirstDates.CID. (Tier 1 — BI_DB_CIDFirstDates, ultimately Dim_Customer) |
| 2 | IsDepositor | int | YES | Whether the customer has ever deposited (1=yes, 0=no). From Fact_SnapshotCustomer at V3 verification date via Dim_Range. (Tier 1 — CustomerStatic.IsDepositor) |
| 3 | Country | varchar(50) | YES | Country of residence name. From BI_DB_CIDFirstDates.Country (resolved from Dim_Country.Name). Filtered to 30 eligible airdrop countries. (Tier 1 — Dim_Country.Name, join-enriched) |
| 4 | DesignatedRegulation | varchar(50) | YES | Designated regulation name. From Dim_Regulation.Name via DesignatedRegulationID. Excludes IDs 7 and 8 (US/NFA). (Tier 1 — Dictionary.Regulation, join-enriched) |
| 5 | IsADClient | int | YES | Airdrop client flag. 1 = first position was a crypto airdrop in an eligible instrument; 0 = first position was organic. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 6 | OpenOccurredAD | datetime | YES | Datetime when the airdrop position was opened. Sentinel `1900-01-01` if not an AD client. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed from Dim_Position.OpenOccurred) |
| 7 | FirstPositionID | bigint | YES | Position ID of the first organic trade. For AD clients = 2nd position (1st was airdrop); for non-AD = 1st position. Sentinel `-1` if no qualifying position. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed from Dim_Position.PositionID) |
| 8 | IsFirstPositionCFD | int | YES | Whether the first organic position was a CFD (1) or settled/real (0). Derived from `IsSettledOnOpen=0 → CFD`. Sentinel `-1` if no position. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 9 | FirstPositionOpenOccured | datetime | YES | Datetime when the first organic position was opened. Sentinel `1900-01-01` if no position. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed from Dim_Position.OpenOccurred) |
| 10 | FirstPositionInstrument | varchar(50) | YES | Asset class of the first organic position from Dim_Instrument.InstrumentType: "Crypto Currencies", "Stocks", "ETF", "Commodities", "Currencies", "Indices". Sentinel `'A'` if no position. (Tier 2 — SP_BI_DB_Crypto_Airdrop, from Dim_Instrument) |
| 11 | FirstPositionAmount | money | YES | First organic position amount in USD. `InitialAmountCents / 100`. Sentinel `-1` if no position. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed from Dim_Position.InitialAmountCents) |
| 12 | FirstPositionType | varchar(50) | YES | Categorized first position type: "Real Crypto", "Real Stocks/ETF", "CFDs", or "A" (sentinel). (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 13 | 30DaysAfterAD/FA | datetime | YES | End of 30-day observation window. `DATEADD(DAY, 30, anchor)` where anchor = airdrop open (AD) or first position open (non-AD). (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 14 | 60DaysAfterAD/FA | datetime | YES | End of 60-day observation window. `DATEADD(DAY, 60, anchor)`. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 15 | Is30DaysFromAirdropPassed | int | YES | 1 if AD client and 30+ days have elapsed since airdrop date; 0 otherwise. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 16 | Is60DaysFromAirdropPassed | int | YES | 1 if AD client and 60+ days have elapsed since airdrop date; 0 otherwise. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 17 | Is30DaysFromFAPassed | int | YES | 1 if non-AD client and 30+ days have elapsed since first action date; 0 otherwise. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 18 | Is60DaysFromFAPassed | int | YES | 1 if non-AD client and 60+ days have elapsed since first action date; 0 otherwise. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 19 | 30DaysCountRealStocksETF | int | YES | Count of Real Stocks/ETF positions opened within 30 days of anchor. `IsSettledOnOpen=1 AND InstrumentTypeID IN (5,6)`. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 20 | 30DaysCountRealCrypto | int | YES | Count of Real Crypto positions opened within 30 days of anchor. `IsSettledOnOpen=1 AND InstrumentTypeID=10`. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 21 | 30DaysCountCFDs | int | YES | Count of CFD positions opened within 30 days of anchor. `IsSettledOnOpen=0`. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 22 | 30DaysAmountRealCrypto | money | YES | Total USD amount of Real Crypto positions in first 30 days. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 23 | 30DaysAmountRealStocksETF | money | YES | Total USD amount of Real Stocks/ETF positions in first 30 days. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 24 | 30DaysAmountCFDs | money | YES | Total USD amount of CFD positions in first 30 days. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 25 | 60DaysCountRealStocksETF | int | YES | Count of Real Stocks/ETF positions opened in day 31–60 window (NOT cumulative). (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 26 | 60DaysCountRealCrypto | int | YES | Count of Real Crypto positions opened in day 31–60 window. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 27 | 60DaysCountCFDs | int | YES | Count of CFD positions opened in day 31–60 window. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 28 | 60DaysAmountRealCrypto | money | YES | Total USD amount of Real Crypto positions in day 31–60 window. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 29 | 60DaysAmountRealStocksETF | money | YES | Total USD amount of Real Stocks/ETF positions in day 31–60 window. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 30 | 60DaysAmountCFDs | money | YES | Total USD amount of CFD positions in day 31–60 window. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 31 | MinOpenOccuredCFD | datetime | YES | Earliest CFD trade datetime. Sentinel `2900-01-01` if customer never traded CFDs. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed from Dim_Position) |
| 32 | WasTradedCFD | int | YES | 1 if customer ever traded a CFD (MinOpenOccuredCFD ≠ sentinel); 0 otherwise. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 33 | WasTardedCFDIn30Days | int | YES | 1 if customer traded at least one CFD within 30 days of anchor. Column name contains typo ("Tarded" instead of "Traded"). (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 34 | WasTardedCFDAfter30Days | int | YES | 1 if customer's first CFD trade occurred after the 30-day window. Column name contains typo ("Tarded" instead of "Traded"). (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |
| 35 | UpdateDate | datetime | YES | ETL execution timestamp. `GETDATE()` — identical across all rows for a given daily load. (Tier 2 — SP_BI_DB_Crypto_Airdrop, ETL-computed) |

## 5. Lineage

| Source | Relationship | Objects |
|--------|-------------|---------|
| **BI_DB_dbo.BI_DB_CIDFirstDates** | Primary — V3 customer population with milestones | `CID`, `VerificationLevel3Date`, `Country`, `DesignatedRegulationID`, `IsRelevant` |
| **DWH_dbo.Dim_Position** | Primary — position-level trading data | `PositionID`, `IsAirDrop`, `IsSettledOnOpen`, `OpenOccurred`, `InitialAmountCents`, `InstrumentID`, `MirrorID` |
| **DWH_dbo.Dim_Instrument** | Secondary — instrument classification | `InstrumentTypeID`, `InstrumentType`, `BuyCurrency`, `IsMajorID` |
| **DWH_dbo.Fact_SnapshotCustomer** | Secondary — depositor status at V3 date | `IsDepositor` via `Dim_Range` date matching |
| **DWH_dbo.Dim_Regulation** | Secondary — regulation name decode | `Name` via `DesignatedRegulationID` |
| **DWH_dbo.Dim_Country** | Secondary — country rollout eligibility | `CountryID`, `Name` (hardcoded to 30 countries) |

Full column-level lineage: [BI_DB_Crypto_Airdrop.lineage.md](BI_DB_Crypto_Airdrop.lineage.md)

## 6. Relationships

| Related Object | Join Condition | Purpose |
|---------------|----------------|---------|
| BI_DB_dbo.BI_DB_CIDFirstDates | `ON CID = bdcd.CID` | Source: V3 customer milestones |
| DWH_dbo.Dim_Position | `ON CID = dp.CID AND MirrorID=0 AND OpenOccurred >= V3Date` | Source: positions after V3 |
| DWH_dbo.Dim_Instrument | `ON InstrumentID = di.InstrumentID` | Source: instrument classification |
| DWH_dbo.Fact_SnapshotCustomer | `ON CID = fsc.RealCID` (with Dim_Range date window) | Source: depositor status at V3 date |

## 7. Sample Queries

```sql
-- AD vs Non-AD conversion to CFD within 30 days
SELECT  IsADClient,
        COUNT(*) AS TotalCustomers,
        SUM(WasTardedCFDIn30Days) AS TradedCFD30d,
        CAST(SUM(WasTardedCFDIn30Days) AS FLOAT) / COUNT(*) AS CFDConversionRate
FROM    BI_DB_dbo.BI_DB_Crypto_Airdrop
WHERE   Is30DaysFromAirdropPassed = 1 OR Is30DaysFromFAPassed = 1
GROUP BY IsADClient;

-- Average first position amount by country and client type
SELECT  Country,
        IsADClient,
        AVG(CASE WHEN FirstPositionAmount > 0 THEN FirstPositionAmount END) AS AvgFirstPositionUSD,
        COUNT(*) AS Customers
FROM    BI_DB_dbo.BI_DB_Crypto_Airdrop
WHERE   FirstPositionID <> -1
GROUP BY Country, IsADClient
ORDER BY Country;
```

## 8. Atlassian Knowledge Sources

_No specific Confluence/Jira pages found for the crypto airdrop campaign BI table. The airdrop feature is referenced in Dim_Position wiki (IsAirDrop=1 for positions created via airdrop events)._

---

| Metric | Value |
|--------|-------|
| **Quality Score** | 8.5 / 10 |
| **Tier 1 Elements** | 4 / 37 (11%) |
| **Tier 2 Elements** | 33 / 37 (89%) |
| **Tier 4 Elements** | 0 |
| **Confidence** | HIGH — SP code fully analyzed, all sentinel values documented |
