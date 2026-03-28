# Column Lineage: BI_DB_dbo.BI_DB_Crypto_Airdrop

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_Crypto_Airdrop` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `BI_DB_dbo.BI_DB_CIDFirstDates` (V3 customer milestones) + `DWH_dbo.Dim_Position` (trading activity) |
| **ETL SP** | `SP_BI_DB_Crypto_Airdrop` |
| **Secondary Sources** | `Dim_Country`, `Dim_Regulation`, `Dim_Instrument`, `Dim_Range`, `Fact_SnapshotCustomer` |
| **Generated** | 2026-03-28 |

## Lineage Chain

```
BI_DB_dbo.BI_DB_CIDFirstDates (V3-verified customers, since 2023-05-15)
DWH_dbo.Dim_Position (positions, non-mirror, post-V3)
DWH_dbo.Dim_Instrument (instrument classification + airdrop eligibility)
    │
    └─ SP_BI_DB_Crypto_Airdrop (no parameters)
        ├─ Stage 0: CTAS #countries — 30 hardcoded eligible countries with rollout dates
        ├─ Stage 1: CTAS #V3Clients — V3 customers JOIN BI_DB_CIDFirstDates + Fact_SnapshotCustomer + Dim_Range + Dim_Regulation
        ├─ Stage 2: CTAS #popFull — Filter: IsRelevant=1, exclude RegulationIDs 7,8
        ├─ Stage 3: CTAS #pos → #pos_RN → #first_second_action — JOIN Dim_Position + Dim_Instrument, ROW_NUMBER per CID
        ├─ Stage 4: CTAS #ClientType_Culc → #ClientType → #popCulc → #popFinal — AD/non-AD classification, first position extraction
        ├─ Stage 5: CTAS #ClientActivity → #FinalTable — 30/60-day activity windows + CFD tracking
        ├─ TRUNCATE TABLE target
        └─ INSERT → BI_DB_dbo.BI_DB_Crypto_Airdrop (1.7M rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| CID | BI_DB_dbo.BI_DB_CIDFirstDates | CID | passthrough | Direct | Customer Real account ID |
| IsDepositor | DWH_dbo.Fact_SnapshotCustomer (fsc) | IsDepositor | passthrough | `fsc.IsDepositor` via `fsc.RealCID = bdcd.CID` + Dim_Range date validation | Ever-deposited flag at V3 date |
| Country | BI_DB_dbo.BI_DB_CIDFirstDates | Country | passthrough | Direct (originally from Dim_Country.Name) | Country of residence name |
| DesignatedRegulation | DWH_dbo.Dim_Regulation (dr1) | Name | join-enriched | `dr1.Name` via `BI_DB_CIDFirstDates.DesignatedRegulationID = dr1.ID` | Designated regulation name |
| IsADClient | — | — | ETL-computed | `1` if first position (RN=1) was airdrop (`IsAirDrop=1`) in eligible crypto instruments, else `0` | Airdrop client classification |
| OpenOccurredAD | DWH_dbo.Dim_Position | OpenOccurred | ETL-computed | Position open datetime if IsADClient=1, else `'1900-01-01'` sentinel | Airdrop position open date |
| FirstPositionID | DWH_dbo.Dim_Position | PositionID | ETL-computed | For AD: 2nd position (RN=2); for non-AD: 1st position (RN=1); sentinel `-1` if none | First organic position ID |
| IsFirstPositionCFD | DWH_dbo.Dim_Position | IsSettledOnOpen | ETL-computed | `CASE WHEN IsSettledOnOpen=0 THEN 1 ELSE 0 END`; sentinel `-1` if no position | Whether first position was CFD |
| FirstPositionOpenOccured | DWH_dbo.Dim_Position | OpenOccurred | ETL-computed | Open datetime of first organic position; sentinel `'1900-01-01'` if none | First organic position open date |
| FirstPositionInstrument | DWH_dbo.Dim_Instrument | InstrumentType | rename | `fsa.InstrumentType`; sentinel `'A'` if no position | Asset class of first position |
| FirstPositionAmount | DWH_dbo.Dim_Position | InitialAmountCents | ETL-computed | `InitialAmountCents / 100`; sentinel `-1` if no position | First position amount USD |
| FirstPositionType | — | — | ETL-computed | CASE: Real Crypto / Real Stocks/ETF / CFDs / A (sentinel) based on IsSettledOnOpen + InstrumentType | Categorized first position type |
| 30DaysAfterAD/FA | — | — | ETL-computed | `DATEADD(DAY, 30, OpenOccurredAD)` if AD, else `DATEADD(DAY, 30, FirstPositionOpenOccured)` | End of 30-day observation window |
| 60DaysAfterAD/FA | — | — | ETL-computed | `DATEADD(DAY, 60, ...)` same logic as above | End of 60-day observation window |
| Is30DaysFromAirdropPassed | — | — | ETL-computed | `1` if AD client and 30+ days elapsed since airdrop | 30-day milestone flag (AD only) |
| Is60DaysFromAirdropPassed | — | — | ETL-computed | `1` if AD client and 60+ days elapsed since airdrop | 60-day milestone flag (AD only) |
| Is30DaysFromFAPassed | — | — | ETL-computed | `1` if non-AD client and 30+ days elapsed since first action | 30-day milestone flag (non-AD) |
| Is60DaysFromFAPassed | — | — | ETL-computed | `1` if non-AD client and 60+ days elapsed since first action | 60-day milestone flag (non-AD) |
| 30DaysCountRealStocksETF | DWH_dbo.Dim_Position + Dim_Instrument | COUNT | ETL-computed | `COUNT(PositionID) WHERE IsSettledOnOpen=1 AND InstrumentTypeID IN (5,6) AND OpenOccurred <= 30DaysAfterAD/FA` | Real stocks/ETF count in 30d |
| 30DaysCountRealCrypto | DWH_dbo.Dim_Position + Dim_Instrument | COUNT | ETL-computed | `COUNT(PositionID) WHERE IsSettledOnOpen=1 AND InstrumentTypeID=10 AND OpenOccurred <= 30DaysAfterAD/FA` | Real crypto count in 30d |
| 30DaysCountCFDs | DWH_dbo.Dim_Position | COUNT | ETL-computed | `COUNT(PositionID) WHERE IsSettledOnOpen=0 AND OpenOccurred <= 30DaysAfterAD/FA` | CFD count in 30d |
| 30DaysAmountRealCrypto | DWH_dbo.Dim_Position + Dim_Instrument | SUM(InitialAmountCents/100) | ETL-computed | Real crypto amount in first 30 days | Real crypto amount USD in 30d |
| 30DaysAmountRealStocksETF | DWH_dbo.Dim_Position + Dim_Instrument | SUM(InitialAmountCents/100) | ETL-computed | Real stocks/ETF amount in first 30 days | Real stocks/ETF amount USD in 30d |
| 30DaysAmountCFDs | DWH_dbo.Dim_Position | SUM(InitialAmountCents/100) | ETL-computed | CFD amount in first 30 days | CFD amount USD in 30d |
| 60DaysCountRealStocksETF | DWH_dbo.Dim_Position + Dim_Instrument | COUNT | ETL-computed | Real stocks/ETF count in 30-60d window (NOT cumulative) | Real stocks/ETF count in 30-60d |
| 60DaysCountRealCrypto | DWH_dbo.Dim_Position + Dim_Instrument | COUNT | ETL-computed | Real crypto count in 30-60d window | Real crypto count in 30-60d |
| 60DaysCountCFDs | DWH_dbo.Dim_Position | COUNT | ETL-computed | CFD count in 30-60d window | CFD count in 30-60d |
| 60DaysAmountRealCrypto | DWH_dbo.Dim_Position + Dim_Instrument | SUM(InitialAmountCents/100) | ETL-computed | Real crypto amount in 30-60d window | Real crypto amount USD in 30-60d |
| 60DaysAmountRealStocksETF | DWH_dbo.Dim_Position + Dim_Instrument | SUM(InitialAmountCents/100) | ETL-computed | Real stocks/ETF amount in 30-60d window | Real stocks/ETF amount USD in 30-60d |
| 60DaysAmountCFDs | DWH_dbo.Dim_Position | SUM(InitialAmountCents/100) | ETL-computed | CFD amount in 30-60d window | CFD amount USD in 30-60d |
| MinOpenOccuredCFD | DWH_dbo.Dim_Position | MIN(OpenOccurred) | ETL-computed | `MIN(CASE WHEN IsSettledOnOpen=0 THEN OpenOccurred ELSE '2900-01-01')` | Earliest CFD trade date; sentinel 2900-01-01 if never |
| WasTradedCFD | — | — | ETL-computed | `CASE WHEN MinOpenOccuredCFD <> '2900-01-01' THEN 1 ELSE 0` | Ever traded CFD flag |
| WasTardedCFDIn30Days | — | — | ETL-computed | `CASE WHEN 30DaysCountCFDs > 0 THEN 1 ELSE 0` | Traded CFD within 30d flag (typo in name) |
| WasTardedCFDAfter30Days | — | — | ETL-computed | `1` if MinOpenOccuredCFD > 30DaysAfterAD/FA | Traded CFD after 30d flag (typo in name) |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **Rename** | 1 |
| **Join-enriched** | 1 |
| **ETL-computed** | 32 |
| **Total** | 37 |
