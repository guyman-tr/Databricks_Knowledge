# BI_DB_dbo.BI_DB_ASIC_GAML_Invested_Amount

| Attribute | Value |
|-----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_ASIC_GAML_Invested_Amount |
| **SP Author** | Artyom Bogomolsky (2022-10-25) |
| **Refresh Pattern** | TRUNCATE + INSERT daily (single-date snapshot) |
| **UC Target** | `_Not_Migrated` |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX (RealCID ASC) |
| **Row Count** | ~112,470 rows (2026-04-12 sample) |
| **Columns** | 17 |

---

## Summary

Daily snapshot of open-position invested amounts and unrealized P&L for ASIC- and GAML-regulated customers (RegulationID=10) holding Stocks or ETF positions. The table is TRUNCATE+INSERT on each run, always containing a single date's snapshot (today). Used by ASIC regulatory reporting to monitor invested exposure across customer segments, trading modes, and asset classes.

Grain: one row per customer × InstrumentType × AssetType × Copy_IND combination. Customers without any open Stocks/ETF positions on the snapshot date are excluded.

---

## Business Context

Serves ASIC (Australian Securities and Investments Commission) regulatory reporting, specifically the GAML (General Anti-Money Laundering) use case. The table supports monitoring of:

- **Customer exposure**: Total invested amount and unrealized P&L per customer, broken down by instrument type (Stocks vs ETF) and trading mode (Copy vs Manual).
- **Population scope**: ASIC-regulated customers only (RegulationID=10, VL=3, IsDepositor=1). These are Australian-regulated retail accounts.
- **Activity flags**: Login and trading activity indicators over the prior 30 days, used to classify active vs dormant customers for AML monitoring purposes.

**Key distributions (2026-04-12):**
- 82,305 distinct customers across 112,470 rows
- Total invested: ~$425.9M USD
  - Stocks/Manual: $301.8M (70.8%)
  - ETF/Manual: $68.2M (16.0%)
  - Stocks/Copy: $48.7M (11.4%)
  - ETF/Copy: $7.1M (1.7%)
- Player level (Club): Bronze 66.1%, Silver 12.0%, Gold 11.5%

---

## ETL / Refresh

**Pattern**: TRUNCATE → INSERT — previous day's snapshot is fully replaced on each run. No historical data is retained in this table.

**ETL chain**:
```
DWH_dbo.Dim_Customer (RegulationID=10, VL=3, IsDepositor=1)
  + DWH_dbo.Dim_PlayerLevel (Club name)
  + DWH_dbo.Dim_Country (Country name)
    → #pop (ASIC/GAML customer population, ~82K CIDs)

BI_DB_dbo.BI_DB_PositionPnL (DateID=@date, InstrumentTypeID IN(5,6), IsSettled=1)
  JOIN #pop ON CID=RealCID
  + DWH_dbo.Dim_Instrument (InstrumentType label)
    → #final (SUM Invested_Amount, Current_PNL per customer × InstrumentType × AssetType × Copy_IND)

DWH_dbo.Fact_CustomerAction (ActionTypeID IN(1,4,14), DateID>=@Date30INT)
  JOIN #pop
    → #activity (LogginInd, TradingInd per customer)

TRUNCATE BI_DB_ASIC_GAML_Invested_Amount
INSERT FROM #final LEFT JOIN #activity
```

**Position filter**: `InstrumentTypeID IN(5,6)` (Stocks=5, ETF=6) AND `IsSettled=1` (open, unsettled positions only).

---

## Column Catalog

| # | Column | Type | Tier | Description |
|---|--------|------|------|-------------|
| 1 | RealCID | int NOT NULL | T1 — Customer.CustomerStatic | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. |
| 2 | GCID | int NOT NULL | T1 — Customer.CustomerStatic | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. |
| 3 | PlayerLevelID | int NULL | T1 — Customer.CustomerStatic | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Bronze, 4=Internal, 7=Diamond. Determines available features and risk limits. Default=0. |
| 4 | Club | varchar(50) NULL | T1 — Dictionary.PlayerLevel | Player level tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Renamed from Dim_PlayerLevel.Name via PlayerLevelID JOIN. Used in BackOffice reporting JOINs and customer-facing UI. |
| 5 | IsValidCustomer | int NULL | T1 — SP_Dim_Customer (DWH-computed) | DWH-computed: 1 when not Internal (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. |
| 6 | CountryID | int NULL | T1 — Customer.CustomerStatic | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. |
| 7 | Country | varchar(100) NULL | T1 — Dictionary.Country | Full country name in English. Resolved from CountryID via Dim_Country JOIN. Unique per CountryID. Used in compliance documents and analytical reports. |
| 8 | RegulationID | int NULL | T1 — BackOffice.Customer | Regulatory entity governing this account. FK to Dictionary.Regulation. Always 10 (ASIC) in this table — population filter RegulationID=10 applied at source. |
| 9 | Date_Relevance | date NULL | T2 — SP_ASIC_GAML_Invested_Amount | Snapshot date — the ETL run date parameter (@Date) passed to SP_ASIC_GAML_Invested_Amount. All rows in the table always carry the same date (today's date at ETL run time). TRUNCATE+INSERT means this represents current-day only. |
| 10 | Invested_Amount | money NULL | T2 — SP_ASIC_GAML_Invested_Amount | Total invested amount in USD for open Stocks/ETF positions (IsSettled=1) as of Date_Relevance. SUM(Amount) from BI_DB_PositionPnL, aggregated per customer × InstrumentType × AssetType × Copy_IND grain. Amount is rewound via Dim_PositionChangeLog when SL/partial-close edits occur after the snapshot date. |
| 11 | Current_PNL | decimal(16,4) NULL | T2 — SP_ASIC_GAML_Invested_Amount | Unrealized P&L in USD for open Stocks/ETF positions as of Date_Relevance. SUM(PositionPnL) from BI_DB_PositionPnL (sourced from PnLInDollars), aggregated per customer × InstrumentType × AssetType × Copy_IND grain. |
| 12 | UpdateDate | datetime NOT NULL | Propagation | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| 13 | InstrumentType | varchar(200) NULL | T2 — SP_Dim_Instrument | Text label for the instrument type — DWH-computed via CASE on InstrumentTypeID: 5=Stocks, 6=ETF. In this table always 'Stocks' or 'ETF' since InstrumentTypeID IN(5,6) filter is applied at source. |
| 14 | AssetType | varchar(50) NULL | T2 — SP_ASIC_GAML_Invested_Amount | Asset category derived in SP: CASE WHEN InstrumentTypeID=5 THEN 'Stocks' WHEN InstrumentTypeID=6 THEN 'ETF'. Functionally redundant with InstrumentType but present as a dedicated ASIC reporting column. |
| 15 | Copy_IND | varchar(50) NULL | T2 — SP_ASIC_GAML_Invested_Amount | Trading mode indicator: 'Copy' when MirrorID>0 (position opened via CopyTrading), 'Manual' when MirrorID IS NULL or 0. Derived from BI_DB_PositionPnL.MirrorID. |
| 16 | LogginInd | int NULL | T2 — SP_ASIC_GAML_Invested_Amount | Login activity flag: MAX(CASE WHEN ActionTypeID=14 THEN 1 ELSE 0 END) from Fact_CustomerAction in the prior 30 days. Intended to indicate whether the customer has logged in recently. **See SP Bug below — this flag is unreliable.** |
| 17 | TradingInd | int NULL | T2 — SP_ASIC_GAML_Invested_Amount | Trading activity flag: MAX(CASE WHEN ActionTypeID IN(1,4) THEN 1 ELSE 0 END) from Fact_CustomerAction in the prior 30 days. Intended to indicate whether the customer has placed or closed a trade recently. **See SP Bug below — this flag is unreliable.** |

---

## Data Quality / Known Issues

### SP Bug: @Date30INT computed from wrong variable

**Severity**: High — data correctness issue affecting two columns (LogginInd, TradingInd)

In `SP_ASIC_GAML_Invested_Amount`, the 30-day lookback boundary is declared as:
```sql
DECLARE @Date30INT INT = CONVERT(VARCHAR, @Date, 112)
```
This should be:
```sql
DECLARE @Date30INT INT = CONVERT(VARCHAR, @Date30, 112)
```

Because `@Date30INT` is computed from `@Date` (today's run date) rather than `@Date30` (30 days ago), the WHERE clause `DateID >= @Date30INT` in the Fact_CustomerAction query becomes `DateID >= today` — effectively a zero-day window. As a result:

- **LogginInd** will be 1 only for customers who logged in on the exact run date (not the past 30 days)
- **TradingInd** will be 1 only for customers who traded on the exact run date

Both columns likely show severe underreporting of activity. This bug has been present since at least 2022-10-25 (SP creation date). Downstream consumers using these flags for AML dormancy classification should treat them as unreliable until the SP is corrected.

---

## Lineage

Full column-level lineage: [BI_DB_ASIC_GAML_Invested_Amount.lineage.md](./BI_DB_ASIC_GAML_Invested_Amount.lineage.md)

**Tier Summary**: 7 Tier 1, 9 Tier 2, 1 Propagation

**Upstream sources**:
- `DWH_dbo.Dim_Customer` → population filter + customer attributes (RealCID, GCID, PlayerLevelID, IsValidCustomer, CountryID, RegulationID)
- `DWH_dbo.Dim_PlayerLevel` → Club name
- `DWH_dbo.Dim_Country` → Country name
- `BI_DB_dbo.BI_DB_PositionPnL` → Invested_Amount, Current_PNL, Copy_IND
- `DWH_dbo.Dim_Instrument` → InstrumentType
- `DWH_dbo.Fact_CustomerAction` → LogginInd, TradingInd
