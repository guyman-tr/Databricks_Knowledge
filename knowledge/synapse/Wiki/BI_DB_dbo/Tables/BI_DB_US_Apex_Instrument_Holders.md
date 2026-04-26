# BI_DB_US_Apex_Instrument_Holders

**Schema:** BI_DB_dbo  
**Type:** Table  
**Distribution:** ROUND_ROBIN  
**Index:** CLUSTERED INDEX (DateID ASC)  
**Writer SP:** `SP_US_Apex_Instrument_Holders`  
**Frequency:** Daily (SB_Daily, Priority 20)

---

## 1. Summary

Daily snapshot of long equity positions held by eToro US customers at Apex Clearing. Each row represents one customer's holding of one US stock or ETF instrument on a given trading day, including the USD value and share count of their position. Covers only NYDFS-regulated (RegulationID=8) US customers with settled long positions (IsBuy=1, IsSettled=1) in RealStocks and ETFs (InstrumentTypeID IN(5,6)).

Used for US regulatory reporting, reconciliation with Apex Clearing, and US equity exposure monitoring.

---

## 2. Business Context

- **Domain**: US equities / Apex Clearing integration
- **Population**: eToro US customers regulated under NYDFS (RegulationID=8, IsValidCustomer=1) who held at least one settled long position in a US stock or ETF on the given date.
- **Coverage**: RealStocks (InstrumentTypeID=5) and ETFs (InstrumentTypeID=6) only — no CFDs, crypto, or forex.
- **Producers**: `SP_US_Apex_Instrument_Holders` (no author header; companion to Artyom Bogomolsky's Apex SP suite).
- **Consumers**: US regulatory reporting, Apex reconciliation pipelines, US equity exposure dashboards.

**Scale**: ~82.8M rows (Nov 2021–Apr 2026). ~1,600 distinct trading dates; ~52,800 distinct customers; ~4,060 distinct instruments.

---

## 3. Column Descriptions

| # | Column | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | DateID | int | YES | ETL partition date in YYYYMMDD format. Identifies the trading day this snapshot covers. All rows in a single ETL run share the same DateID. |
| 2 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Sourced from External_USABroker_Apex_UserData. (Tier 1 — DWH_dbo.Dim_Customer) |
| 3 | RealCID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within the eToro platform. Filtered to RegulationID=8 (NYDFS) and IsValidCustomer=1. (Tier 1 — DWH_dbo.Dim_Customer) |
| 4 | InstrumentID | int | YES | Primary key identifying the tradeable instrument. Allocated by Trade.InstrumentAdd during instrument creation. Restricted here to RealStocks (InstrumentTypeID=5) and ETFs (InstrumentTypeID=6). (Tier 1 — DWH_dbo.Dim_Instrument) |
| 5 | InstrumentName | varchar(100) | YES | Instrument name as stored in Dim_Instrument.Name — internal eToro format (e.g., "NVDA/USD", not display name "NVIDIA Corporation"). For US stocks: ticker/currency pair notation. (Tier 3 — inferred from DWH_dbo.Dim_Instrument.Name) |
| 6 | Symbol | varchar(40) | YES | Ticker symbol for the instrument (e.g., AAPL, NVDA, VOO). Standard US exchange ticker. (Tier 3 — DWH_dbo.Dim_Instrument.Symbol) |
| 7 | CUSIP | varchar(40) | YES | Committee on Uniform Securities Identification Procedures number — 9-character alphanumeric code identifying the US/Canadian security. NULL for ~0.05% of instruments without an assigned CUSIP. Used for regulatory reporting and Apex reconciliation. (Tier 2 — DWH_dbo.Dim_Instrument.CUSIP) |
| 8 | Amount | money | YES | Total USD value of the customer's long position in this instrument on DateID. Aggregated as SUM(BI_DB_PositionPnL.Amount) across all settled positions. Position amount in USD; derived from Dim_Position.Amount with PositionChangeLog rewind when SL/partial-close edits occurred after the snapshot date. (Tier 1 — BI_DB_dbo.BI_DB_PositionPnL.Amount) |
| 9 | Units | money | YES | Total share count of the customer's long position in this instrument on DateID. Aggregated as SUM(BI_DB_PositionPnL.AmountInUnitsDecimal). Size in instrument units; split-adjusted and rewound from partial-close log when applicable. (Tier 1 — BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 10 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Always set to GETDATE() at ETL run time. |

---

## 4. Distribution & Partitioning

- **Distribution**: ROUND_ROBIN — rows spread evenly across distributions. No hash key, reflecting varied query access patterns (by customer, by instrument, by date).
- **Index**: CLUSTERED INDEX on DateID ASC — optimized for date-range scans and daily DELETE+INSERT ETL pattern.
- **ETL Pattern**: DELETE WHERE DateID=@DateID → INSERT SELECT. Single-date replace; no full-table rebuild.

---

## 5. Relationships

**Upstream (inputs to this table):**

| Source Table | Join Key | Role |
|---|---|---|
| `BI_DB_dbo.BI_DB_PositionPnL` | RealCID, InstrumentID, DateID | Core position amounts (Amount, Units). Filtered: IsBuy=1, IsSettled=1. |
| `DWH_dbo.Dim_Customer` | RealCID | Customer filter: RegulationID=8, IsValidCustomer=1. |
| `DWH_dbo.Dim_Instrument` | InstrumentID | Instrument attributes: Name, Symbol, CUSIP. Filtered: InstrumentTypeID IN(5,6). |
| `External_USABroker_Apex_ApexData` | AccountNumber | Apex broker account linkage. |
| `External_USABroker_Apex_ApexStatus` | AccountNumber | Apex account status filtering. |
| `External_USABroker_Apex_UserData` | AccountNumber | GCID identity mapping. |

**Downstream (tables that read from this table):**
- US regulatory reporting procedures
- Apex reconciliation pipelines
- No confirmed downstream SP references found in BI_DB_dbo SP set.

---

## 6. ETL & Lifecycle

- **Frequency**: Daily, run via SB_Daily scheduler.
- **Priority**: 20 (third wave — depends on Priority 0 outputs including BI_DB_PositionPnL).
- **ProcessType**: 1 (SQL stored procedure).
- **Backfill**: Single-date pattern; rerun the SP with a specific @DateID to refresh that day.
- **Data start**: 2021-11-01 (US real stocks launch).
- **Latest data**: 2026-04-12 (confirmed via live Synapse query).

---

## 7. Known Caveats & Gotchas

- **Long positions only**: IsBuy=1 filter — short positions (if any) are NOT in this table.
- **Settled positions only**: IsSettled=1 — open/pending positions are excluded.
- **InstrumentName is internal format**: `Dim_Instrument.Name` returns "NVDA/USD" style, not the consumer-facing display name "NVIDIA Corporation". Use `Dim_Instrument.InstrumentDisplayName` if human-readable names are needed.
- **GCID from Apex external table**: GCID is sourced via `External_USABroker_Apex_UserData`, not from Dim_Customer directly. May differ for edge-case accounts.
- **CUSIP is nullable**: ~43,317 rows (~0.05%) have NULL CUSIP — instruments without assigned CUSIP codes. This is expected for some ETFs and newer instruments.
- **No SP author header**: Unlike companion Apex SPs (authored by Artyom Bogomolsky), this SP has no author/date header.
- **NYDFS only**: RegulationID=8 — captures only eToro US customers under NY DFS regulation. NFA-regulated US customers (RegulationID=7) are excluded.

---

## 8. Sample Data (2026-04-12)

| Symbol | InstrumentName | Customer Count | Avg Amount (USD) |
|---|---|---|---|
| NVDA | NVDA/USD | 5,251 | ~$1,200 |
| TSLA | TSLA/USD | 3,826 | ~$900 |
| AMZN | AMZN/USD | 3,497 | ~$800 |
| VOO | VOO/USD | 2,678 | ~$2,100 |
| AAPL | AAPL/USD | ~2,400 | ~$700 |

Amount range: $0–$2.88M. Units range: 0–160,000 shares.
