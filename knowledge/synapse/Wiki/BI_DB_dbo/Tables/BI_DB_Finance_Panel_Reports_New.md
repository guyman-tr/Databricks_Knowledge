# BI_DB_dbo.BI_DB_Finance_Panel_Reports_New

> 66.7M-row daily UK Stamp Duty Reserve Tax (SDRT) reporting table tracking every stamp-duty-eligible GB-ISIN stock position from January 2018 to April 2026 — across three position phases (Open_Position 70%, Close_Position 30%, Change_CFD_To_Real <0.1%) — filtered exclusively to InstrumentTypeID=5, SellCurrencyID=666 (GBX), and UK-registered ISINs (GB-prefix). Written by `SP_Finance_Panel_Reports_New` as a daily DELETE by DateID + INSERT incremental refresh for HMRC/FCA Finance Panel financial reporting. All 66.7M rows have Is_Stamp_Duty=1 — only stamp-duty-eligible positions are stored.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + Dim_Instrument + Fact_CustomerAction + Fact_SnapshotCustomer via `SP_Finance_Panel_Reports_New` |
| **Refresh** | Daily incremental — DELETE WHERE DateID = @DateID + INSERT (SB_Daily, Priority 20) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Finance_Panel_Reports_New` is the authoritative UK Stamp Duty Reserve Tax (SDRT) position log, purpose-built for HMRC and FCA "Finance Panel Report" regulatory submissions. Each row represents a single stock position lifecycle event — either opened, closed, or converted from CFD to Real settlement — that triggered a UK stamp duty liability. 

**Scope restrictions**: The table is strictly limited to:
- UK-registered financial instruments only (ISINCode LIKE 'GB%')
- Stocks (InstrumentTypeID=5)
- GBX-denominated positions (SellCurrencyID=666)
- Six specific hedge execution venues (HedgeServerID IN 121, 124, 125, 126, 128, 130)
- Customers with IsCreditReportValidCB=1 AND IsValidCustomer=1

**66.7M rows** spanning **2,099 trading dates** (January 2018 – April 2026), distributed as: Open_Position (46.7M, 70%), Close_Position (20.0M, 30%), Change_CFD_To_Real (53K, <0.1%).

**Key regulatory change**: Stamp Duty on **close positions was abolished after 2021-01-18** (Bradley Roberts change, 2023-05-09). From 2021-01-18 onward, Close_Position rows have Is_Stamp_Duty=0 and are NOT inserted. Only Open_Position and Change_CFD_To_Real rows continue to accumulate.

**HedgeServerID=126 double-rate**: Before 2021-01-18, HedgeServerID=126 was charged 1% stamp duty (0.5% × 2) instead of the standard 0.5%. This server represented a specific execution venue with a different regulatory agreement.

**Amount dimensions**: Each row carries the position amount converted to three currencies — USD (raw), GBP (via Fact_CurrencyPriceWithSplit InstrumentID=2 rate), and EUR (via InstrumentID=1 rate) — using the settlement date's GBP/USD and EUR/USD exchange rates from price history. The `Total_Stamp_Duty` column is the computed SDRT liability in GBP.

**Partial-close diagnostic columns**: `PartialNULLS_Amount_OnOpen_USD/GBP` (IsPartialCloseChild IS NULL) and `PartialZero_Amount_OnOpen_USD/GBP` (IsPartialCloseChild = 0) are diagnostic debugging columns added during the 2023 HMRC overhaul. Only present on Open_Position rows; NULL for Close/Change rows.

**Ghost column**: `Notional_Value_GBP` appears in the DDL but is absent from the SP INSERT statement — it is always NULL in production.

**Context**: This table was substantially overhauled in April 2023 by Guy Manova and Bradley Roberts in collaboration with HMRC (the change log refers to "HMRS" which is the internal abbreviation for HMRC). The "New" suffix distinguishes this from the legacy `BI_DB_Finance_Panel_Reports` table (documented in Batch 5 as a P99 object).

---

## 2. Business Logic

### 2.1 Three-Phase UNION ALL Structure

**What**: The SP builds three independent temp tables and UNIONs them into a single INSERT.

**Columns Involved**: `Position_Phase`, all amount/settlement/regulation columns

**Rules**:
- **Open_Position**: Positions with OpenDateID = @Date, IsSettled_OnOpen=1, Is_Stamp_Duty=1. Amount_OnOpen_USD/GBP/EUR populated; Amount_OnClose_* = 0.
- **Change_CFD_To_Real**: Positions that changed settlement from CFD to Real on @Date (ChangeTypeID=13 from Dim_PositionChangeLog, PreviousIsSettled=0, Leverage=1). Uses a self-JOIN back to BI_DB_Finance_Panel_Reports_New to exclude positions that already have an Open_Position stamp duty record (deduplication).
- **Close_Position**: Positions with CloseDateID = @Date, IsSettled=1, Is_Stamp_Duty=1. Amount_OnClose_USD/GBP/EUR populated; Amount_OnOpen_* = 0.

### 2.2 Stamp Duty Rate Logic (Total_Stamp_Duty)

**What**: SDRT liability is calculated per-row using a CASE expression varying by HedgeServerID and date.

**Columns Involved**: `Total_Stamp_Duty`, `Amount_OnOpen_GBP`, `Amount_OnClose_GBP`, `HedgeServerID`, `DateID`

**Rules**:
- **Open/Change rows** (Is_Stamp_Duty=1):
  - HedgeServerID=126 AND DateID ≤ 20210117 → Amount_OnOpen_GBP × 0.005 × 2 = **1%**
  - HedgeServerID=126 AND DateID > 20210117 → Amount_OnOpen_GBP × 0.005 × 1 = **0.5%**
  - HedgeServerID IN (125, 128, 121, 124, 130) → Amount_OnOpen_GBP × 0.005 × 1 = **0.5%**
- **Close rows** (legacy, DateID ≤ 20210117 only):
  - Amount_OnClose_GBP × 0.005 × 1 = **0.5%**
  - Close rows after 2021-01-18: Is_Stamp_Duty=0 → NOT inserted (exempt)

### 2.3 IsSettled Sentinel Values

**What**: The -1 sentinel distinguishes "not applicable" from actual settled/unsettled values.

**Columns Involved**: `IsSettled_OnOpen`, `IsSettled_OnClose`, `RegulationID_OnOpen`, `RegulationID_OnClose`, `RegulationName_OnOpen`, `RegulationName_OnClose`

**Rules**:
- **Open_Position**: IsSettled_OnClose = -1; RegulationID_OnClose = -1; RegulationName_OnClose = 'N/A'
- **Close_Position**: IsSettled_OnOpen = -1; RegulationID_OnOpen = -1; RegulationName_OnOpen = 'N/A'
- **Change_CFD_To_Real**: IsSettled_OnClose = -1 (change event, no closing yet)

### 2.4 Partial-Close Diagnostic Columns

**What**: Four diagnostic columns (PartialNULLS/PartialZero variants) were added during the HMRC overhaul to investigate partial-close position amount anomalies.

**Columns Involved**: `PartialNULLS_Amount_OnOpen_USD`, `PartialNULLS_Amount_OnOpen_GBP`, `PartialZero_Amount_OnOpen_USD`, `PartialZero_Amount_OnOpen_GBP`

**Rules**:
- **PartialNULLS_***: CASE WHEN dp.IsPartialCloseChild IS NULL THEN Amount ELSE 0. Represents positions where IsPartialCloseChild has never been set (legacy or non-partial-close positions).
- **PartialZero_***: CASE WHEN dp.IsPartialCloseChild = 0 THEN Amount ELSE 0. Represents positions explicitly marked as non-partial-close (IsPartialCloseChild=0).
- Only populated for Open_Position branch; NULL for Close_Position and Change_CFD_To_Real rows.
- **DDL column names**: DDL says `PartialNULLS_*` / `PartialZero_*`; SP SELECT aliases are `ParialNULLS_*` / `ParialZero_*` (single 'l' typo in aliases). The INSERT column list uses the correct DDL names, so data inserts correctly despite the alias mismatch.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution means rows are evenly distributed across compute nodes with no co-location guarantee. Joins to HASH-distributed tables (Dim_Position on PositionID, Dim_Customer on CID) will require data movement.

**CLUSTERED INDEX on DateID**: Date-range queries are efficient. Always filter by `DateID` for best performance. Avoid full-table scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total SDRT liability for a date range | `SELECT SUM(Total_Stamp_Duty) WHERE DateID BETWEEN X AND Y AND Position_Phase = 'Open_Position'` |
| Daily stamp duty by regulation | `GROUP BY DateID, RegulationName_OnOpen WHERE Position_Phase != 'Close_Position'` |
| UK stock trading volume by hedge server | `GROUP BY HedgeServerID, DateID` with `SUM(Notional_Value)` |
| Position-level SDRT audit | `WHERE PositionID = X` — one Open row + (optionally) one Close row |
| CySEC vs FCA stamp duty split | `GROUP BY RegulationName_OnOpen` — note: CySEC dominates at 46% |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID | Get full position details (P&L, dates, etc.) |
| DWH_dbo.Dim_Instrument | ON InstrumentID | Instrument name, ISIN, asset metadata |
| DWH_dbo.Dim_Customer | ON CID | Customer info, tier, country |

### 3.4 Gotchas

- **All rows have Is_Stamp_Duty=1**: The SP only inserts Is_Stamp_Duty=1 rows. Do NOT filter by Is_Stamp_Duty — it is redundant and may confuse future analysts who assume the column has meaningful variation.
- **-1 sentinels**: RegulationID_OnOpen=-1 and RegulationID_OnClose=-1 mean "not applicable for this phase". Always filter `WHERE RegulationName_OnOpen NOT IN ('-1','N/A')` when aggregating by regulation on open.
- **Notional_Value_GBP always NULL**: This column is in the DDL but was never included in the SP INSERT list. Every row will have NULL. Do not use it.
- **No Is_Stamp_Duty=0 rows**: Unlike the old `BI_DB_Finance_Panel_Reports` table, this "New" version is pre-filtered — only duty-eligible rows are stored. The table cannot be used to measure total position count vs. duty-eligible count.
- **Change_CFD_To_Real deduplication**: The Change_CFD_To_Real branch uses a self-JOIN to exclude positions already counted as Open_Position stamp duty records. This means some CFD→Real conversions may be silently skipped if they already appeared as Open_Position rows.
- **GBP conversion uses @Date price**: Amount_OnOpen_GBP is computed using the GBP/USD rate from Fact_CurrencyPriceWithSplit on the position's OpenDateID (or CloseDate), not a fixed rate. Rates fluctuate; USD amounts are more stable for cross-date comparison.
- **Position_Quantity always=1**: Each row represents exactly one position. This column has no analytical variation. It exists as a placeholder for potential future partial-position support.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream DWH wiki (Dim_Position or Dim_Instrument) tracing to production source |
| Tier 2 | Derived from SP code — ETL-computed, renamed, or aggregated from source |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best-available estimate — low confidence, flagged for review |
| Tier 5 | Expert review required |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Position_Phase | varchar(50) | YES | ETL-assigned position lifecycle phase: 'Open_Position' (position opened on this date), 'Close_Position' (position closed on this date), 'Change_CFD_To_Real' (settlement type changed from CFD to Real on this date). The three phases form a mutually exclusive UNION ALL. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 2 | DateID | int | YES | Position event date in YYYYMMDD format. For Open_Position: OpenDateID. For Close_Position: CloseDateID. For Change_CFD_To_Real: the change event date. The table's clustering key and primary delete/insert anchor. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 3 | EOW | date | YES | End-of-week date (Saturday) of the event date. Computed via DATEADD logic: DATEADD(dd, -(DATEPART(dw, Occurred)-7), Occurred). Used for weekly aggregations in Finance Panel reports. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 4 | EOM | date | YES | End-of-month date for the event date. Computed via EOMONTH function. Used for monthly aggregations in Finance Panel reports. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 5 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl). In this table: always one of 6 values (121, 124, 125, 126, 128, 130). HedgeServerID=126 carries historical significance: it was charged double stamp duty (1%) before 2021-01-18. |
| 6 | ISINCountryCode | varchar(50) | YES | Country code extracted from the instrument's ISIN. Always 'GB' in this table (SP filters ISINCode LIKE 'GB%'). Computed via SUBSTRING(ISINCode, 1, 2) or SUBSTRING(ISINCode, 1, 3) depending on numeric check. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 7 | InstrumentTypeID | int | YES | Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Distribution: Stocks 82%, ETF 8%, Crypto 4%, Commodities 3%, Indices 2%, Currencies 1%. (Tier 2 — SP_Dim_Instrument). Always 5 (Stocks) in this table — hardcoded SP filter. |
| 8 | InstrumentTypeName | varchar(50) | YES | Text label for InstrumentTypeID — DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 — SP_Dim_Instrument). Always 'Stocks' in this table. |
| 9 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 — Trade.Instrument via Dim_Instrument) |
| 10 | InstrumentName | varchar(50) | YES | Instrument name from Dim_Instrument.Name — ticker-style (e.g., 'FRES.l/GBX', 'NG.l/GBX', 'RR.l/GBX'). UK-listed company names. Not normalized — SP aliases di.Name AS InstrumentName. (Tier 2 — SP_Finance_Panel_Reports_New via Dim_Instrument) |
| 11 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl via Dim_Position). Only IsCreditReportValidCB=1 AND IsValidCustomer=1 customers are included (SP JOIN to Fact_SnapshotCustomer). |
| 12 | PositionID | bigint | YES | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl via Dim_Position). A single PositionID can appear in up to two rows: one Open row and one Close row (if it was also closed on a different date). |
| 13 | IsSettled_OnOpen | int | YES | Whether the position was settled (real asset) at open time. From Fact_CustomerAction.IsSettled where ActionTypeID IN (1,2,3,39). 1=settled/real, -1=N/A (for Close_Position and Change_CFD_To_Real rows). Always 1 for Open_Position rows (SP filter). (Tier 2 — SP_Finance_Panel_Reports_New via Fact_CustomerAction) |
| 14 | IsSettled_OnClose | int | YES | Whether the position was settled (real asset) at close time. From Dim_Position.IsSettled. 1=settled, -1=N/A (for Open_Position rows). (Tier 2 — SP_Finance_Panel_Reports_New via Dim_Position) |
| 15 | Leverage | int | YES | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl via Dim_Position). Always 1 in this table — UK real stock positions are always unlevered (IsSettled=1 requires Leverage=1). |
| 16 | SellCurrencyID | int | YES | The sell-side (denomination) currency. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading denomination currency (USD, EUR, GBX). Only 67 distinct values since many assets share the same denomination. (Tier 1 — Trade.Instrument via Dim_Instrument). Always 666 (GBX) in this table — SP filter. |
| 17 | SellCurrency | varchar(50) | YES | Text abbreviation of SellCurrencyID — denormalized from Dictionary.Currency.Abbreviation. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 2 — SP_Dim_Instrument). Always 'GBX' in this table. |
| 18 | Amount_OnOpen_USD | money | YES | Position open amount in USD (InitialAmountCents / 100). 0 for Close_Position rows. Stored as money type. Base currency for cross-currency comparison. (Tier 2 — SP_Finance_Panel_Reports_New via Dim_Position.InitialAmountCents) |
| 19 | Amount_OnOpen_GBP | money | YES | Position open amount converted to GBP using the GBP/USD rate from Fact_CurrencyPriceWithSplit (InstrumentID=2) on OpenDateID. 0 for Close_Position rows. This column feeds Total_Stamp_Duty computation. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 20 | Amount_OnOpen_EUR | money | YES | Position open amount converted to EUR using the EUR/USD rate from Fact_CurrencyPriceWithSplit (InstrumentID=1) on OpenDateID. 0 for Close_Position rows and GBX-denominated positions (always 0 since SellCurrencyID=666 is not EUR). (Tier 2 — SP_Finance_Panel_Reports_New) |
| 21 | Notional_Value | money | YES | Position notional value in instrument units multiplied by the relevant forex rate. Open: AmountInUnitsDecimal / InitForexRate. Close: AmountInUnitsDecimal × EndForexRate. Represents the market value of the position in the instrument's home currency. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 22 | Amount_OnClose_USD | money | YES | Position close amount in USD (Dim_Position.Amount). 0 for Open_Position rows. The actual USD proceeds at close. (Tier 2 — SP_Finance_Panel_Reports_New via Dim_Position.Amount) |
| 23 | Amount_OnClose_GBP | money | YES | Position close amount converted to GBP using GBP/USD rate on CloseDateID. 0 for Open_Position rows. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 24 | Amount_OnClose_EUR | money | YES | Position close amount converted to EUR using EUR/USD rate on CloseDateID. 0 for Open_Position rows and non-EUR positions (always 0 since SellCurrencyID=666). (Tier 2 — SP_Finance_Panel_Reports_New) |
| 25 | RegulationID_OnOpen | int | YES | Regulatory jurisdiction ID at position open. From Dim_Position.RegulationIDOnOpen (computed by SP_Dim_Position via JOIN to etoro_History_BackOfficeCustomer). -1 sentinel for Close_Position rows (not applicable). (Tier 2 — SP_Finance_Panel_Reports_New via Dim_Position.RegulationIDOnOpen) |
| 26 | RegulationName_OnOpen | varchar(50) | YES | Regulation name at position open. From Dim_Regulation.Name JOIN on DWHRegulationID. Values: CySEC (46%), FCA (18%), ASIC & GAML (3%), FSA Seychelles (2%), FSRA (1%), N/A (Close_Position sentinel). (Tier 2 — SP_Finance_Panel_Reports_New via Dim_Regulation) |
| 27 | RegulationID_OnClose | int | YES | Regulatory jurisdiction ID at position close. From Fact_SnapshotCustomer.RegulationID at CloseDateID. -1 sentinel for Open_Position and Change_CFD_To_Real rows. (Tier 2 — SP_Finance_Panel_Reports_New via Fact_SnapshotCustomer) |
| 28 | RegulationName_OnClose | varchar(50) | YES | Regulation name at position close. From Dim_Regulation.Name. 'N/A' for Open_Position rows. (Tier 2 — SP_Finance_Panel_Reports_New via Dim_Regulation) |
| 29 | Is_Copy | int | YES | 1=copy-trading position (MirrorID≠0), 0=manual position. Derived from Dim_Position.MirrorID via CASE WHEN MirrorID<>0 THEN 1 ELSE 0. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 30 | Position_Quantity | int | YES | Hardcoded to 1 for every row. Placeholder for future partial-position support. No analytical value — always filter by PositionID if you need position counts. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 31 | Is_Stamp_Duty | int | YES | Always 1 in this table — the SP only inserts rows where Is_Stamp_Duty=1. Computed via CASE logic: position must be IsSettled=1, InstrumentTypeID=5, SellCurrencyID=666. This column has no analytical variation in BI_DB_Finance_Panel_Reports_New. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 32 | Is_MP | int | YES | 1=Manual Portfolio (MirrorID is NULL or 0), 0=Copy position. Inverse logic to Is_Copy: CASE WHEN ISNULL(MirrorID,0)=0 THEN 1 ELSE 0. Is_MP + Is_Copy ≤ 1 for all rows (a position is either manual or copy, never both). (Tier 2 — SP_Finance_Panel_Reports_New) |
| 33 | UpdateDate | datetime | YES | ETL timestamp: GETDATE() at INSERT time. Not a business date — reflects when the row was last refreshed by the ETL pipeline. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 34 | DateOccurred | date | YES | Calendar date when the position event occurred. For Open: CAST(OpenOccurred AS DATE). For Close: CAST(CloseOccurred AS DATE). For Change: CAST(ChangedOccurred AS DATE). Use this for display; use DateID (YYYYMMDD int) for filtering. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 35 | ISINCode | char(30) | YES | International Securities Identification Number — 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). NULL for forex, commodities, and instruments without ISIN. Country prefix + national code + check digit. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData). Always GB-prefix in this table. Right-padded to 30 chars (char type). |
| 36 | Units_OnOpen | decimal(16,6) | YES | Original unit count at open. Used for partial close ratio. (Tier 1 — Trade.PositionTbl via Dim_Position.InitialUnits). 0 for Close_Position rows. Fractional shares supported. |
| 37 | Units_OnClose | decimal(16,6) | YES | Position size in units/shares. Fractional lots. (Tier 1 — Trade.PositionTbl via Dim_Position.AmountInUnitsDecimal). 0 for Open_Position rows. For Change_CFD_To_Real: AmountInUnits from PositionChangeLog (may be slightly inaccurate — AmountInUnits is always NULL in PositionChangeLog, so Dim_Position.AmountInUnitsDecimal is used as a proxy). |
| 38 | Total_Stamp_Duty | money | YES | Computed UK Stamp Duty Reserve Tax (SDRT) liability in GBP. Rate varies by HedgeServerID and date: HedgeServerID=126 pre-2021-01-18 → 1%; all others → 0.5%. Close positions: 0.5% if DateID≤20210117, else 0 (exempt post-January 2021). This is the primary financial output column for HMRC reporting. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 39 | PartialNULLS_Amount_OnOpen_USD | money | YES | Diagnostic: position open amount (USD) where IsPartialCloseChild IS NULL. CASE WHEN dp.IsPartialCloseChild IS NULL THEN InitialAmountCents/100. NULL for Close_Position and Change_CFD_To_Real rows. Added during 2023 HMRC overhaul to investigate partial-close stamp duty discrepancies. DDL name differs from SP alias (DDL: 'PartialNULLS', SP alias: 'ParialNULLS' — one 'l' typo; INSERT uses correct DDL name). (Tier 2 — SP_Finance_Panel_Reports_New) |
| 40 | PartialNULLS_Amount_OnOpen_GBP | money | YES | Diagnostic: position open amount (GBP) where IsPartialCloseChild IS NULL. GBP conversion of PartialNULLS_Amount_OnOpen_USD via GBP/USD rate. NULL for Close_Position and Change_CFD_To_Real rows. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 41 | PartialZero_Amount_OnOpen_USD | money | YES | Diagnostic: position open amount (USD) where IsPartialCloseChild = 0. CASE WHEN dp.IsPartialCloseChild = 0 THEN InitialAmountCents/100. NULL for Close_Position and Change_CFD_To_Real rows. Distinguishes explicitly non-partial positions (IsPartialCloseChild=0) from unset positions (IS NULL). (Tier 2 — SP_Finance_Panel_Reports_New) |
| 42 | PartialZero_Amount_OnOpen_GBP | money | YES | Diagnostic: position open amount (GBP) where IsPartialCloseChild = 0. GBP conversion of PartialZero_Amount_OnOpen_USD. NULL for Close_Position and Change_CFD_To_Real rows. (Tier 2 — SP_Finance_Panel_Reports_New) |
| 43 | Notional_Value_GBP | float | YES | Ghost column: present in DDL but absent from the SP INSERT list. Always NULL in production. Intended to store the notional position value in GBP but was never implemented. Do not use. (Tier 4 — DDL only, never populated) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| PositionID | etoro.Trade.PositionTbl (via Dim_Position) | PositionID | Passthrough |
| CID | etoro.Trade.PositionTbl (via Dim_Position) | CID | Passthrough |
| HedgeServerID | etoro.Trade.HedgeServer (via Dim_Position) | HedgeServerID | Passthrough |
| Leverage | etoro.Trade.PositionTbl (via Dim_Position) | Leverage | Passthrough |
| InstrumentID | etoro.Trade.Instrument (via Dim_Instrument) | InstrumentID | Passthrough |
| SellCurrencyID | etoro.Trade.Instrument (via Dim_Instrument) | SellCurrencyID | Passthrough |
| Units_OnOpen | etoro.Trade.PositionTbl (via Dim_Position) | InitialUnits | Passthrough |
| Units_OnClose | etoro.Trade.PositionTbl (via Dim_Position) | AmountInUnitsDecimal | Passthrough |
| Amount_OnOpen_USD | etoro.Trade.PositionTbl (via Dim_Position) | InitialAmountCents | / 100 (cents to USD) |
| Total_Stamp_Duty | Computed | Amount_OnOpen/Close_GBP | CASE rate × amount |
| Position_Phase | Literal | — | Hardcoded string per branch |

### 5.2 ETL Pipeline

```
etoro.Trade.PositionTbl (active + history, etoroDB-REAL)
  + etoro.Trade.Instrument (instrument metadata)
  + etoro.History.BackOffice_Customer (regulation at time of open)
  + etoro.History.PositionChangeLog (CFD→Real changes)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument
+ DWH_dbo.Fact_CustomerAction + DWH_dbo.Fact_SnapshotCustomer
+ DWH_dbo.Dim_PositionChangeLog + DWH_dbo.Fact_CurrencyPriceWithSplit
  |-- SP_Finance_Panel_Reports_New @Date (DELETE DateID + INSERT) ---|
  v
BI_DB_dbo.BI_DB_Finance_Panel_Reports_New (66.7M rows, UK SDRT positions)
  (UC Target: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo.Dim_Position | Source position details, PnL, dates |
| CID | DWH_dbo.Dim_Customer | Customer demographics, tier, country |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument name, ISIN, exchange |
| HedgeServerID | DWH_dbo.Dim_HedgeServer (not yet documented) | Hedge execution venue |
| RegulationID_OnOpen/OnClose | DWH_dbo.Dim_Regulation | Regulation name (CySEC/FCA/etc.) |

### 6.2 Referenced By (other objects point to this)

No downstream SPs or views in the SSDT repo reference this table. It is consumed externally (Excel Finance Panel reports, HMRC regulatory submissions).

---

## 7. Sample Queries

### Total SDRT Liability by Regulation (Monthly)

```sql
SELECT
    SUBSTRING(CAST(DateID AS VARCHAR(8)), 1, 6) AS YearMonth,
    RegulationName_OnOpen,
    SUM(Total_Stamp_Duty) AS total_sdrt_gbp,
    COUNT(*) AS position_count
FROM [BI_DB_dbo].[BI_DB_Finance_Panel_Reports_New]
WHERE DateID BETWEEN 20260101 AND 20260430
  AND Position_Phase = 'Open_Position'
  AND RegulationName_OnOpen NOT IN ('N/A')
GROUP BY SUBSTRING(CAST(DateID AS VARCHAR(8)), 1, 6), RegulationName_OnOpen
ORDER BY 1, total_sdrt_gbp DESC;
```

### SDRT by HedgeServer and Date (Rate Analysis)

```sql
SELECT
    DateID,
    HedgeServerID,
    COUNT(*) AS positions,
    SUM(Amount_OnOpen_GBP) AS total_amount_gbp,
    SUM(Total_Stamp_Duty) AS total_sdrt,
    AVG(Total_Stamp_Duty * 1.0 / NULLIF(Amount_OnOpen_GBP, 0)) AS effective_rate
FROM [BI_DB_dbo].[BI_DB_Finance_Panel_Reports_New]
WHERE DateID BETWEEN 20260301 AND 20260410
  AND Position_Phase = 'Open_Position'
GROUP BY DateID, HedgeServerID
ORDER BY DateID, HedgeServerID;
```

### Specific Position Lifecycle

```sql
SELECT
    PositionID,
    Position_Phase,
    DateOccurred,
    InstrumentName,
    ISINCode,
    Amount_OnOpen_GBP,
    Amount_OnClose_GBP,
    Total_Stamp_Duty,
    RegulationName_OnOpen,
    RegulationName_OnClose
FROM [BI_DB_dbo].[BI_DB_Finance_Panel_Reports_New]
WHERE PositionID = 3036982157
ORDER BY DateOccurred;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found. Business context sourced from SP change history:
- **2023-04-09**: Guy Manova — HMRC overhaul with Bradley Roberts final additions
- **2023-05-09**: Bradley Roberts — Added logic to exclude Stamp Duty on Close on or after 2021-01-18

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 7 T1, 33 T2, 0 T3, 3 T4, 0 T5 | Elements: 43/43, Logic: 9/10*
*Object: BI_DB_dbo.BI_DB_Finance_Panel_Reports_New | Type: Table | Production Source: DWH_dbo.Dim_Position + Fact_CustomerAction via SP_Finance_Panel_Reports_New*
