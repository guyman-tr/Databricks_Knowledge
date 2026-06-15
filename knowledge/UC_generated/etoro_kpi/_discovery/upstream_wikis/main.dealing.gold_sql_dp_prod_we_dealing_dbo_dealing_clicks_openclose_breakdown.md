# Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown

> Daily aggregated breakdown of trading position opens and closes ("clicks"), segmented by customer, instrument, regulation, direction, and ticket size — the core dealing activity metric table.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived (multi-source ETL from DWH dimensions) |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX + NCI on Date |
| | |
| **UC Target** | `dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table captures every trading "click" — a position open or close event — aggregated daily at the customer × instrument × dimension level. Each row represents one unique combination of date, customer, instrument, direction, open/close type, and various segmentation flags. It answers: "How many positions were opened/closed today, by whom, on what instrument, with what volume and commission?"

The data is entirely ETL-derived from DWH_dbo dimension and fact tables. Primary sources are `DWH_dbo.Dim_Position` (position lifecycle), `DWH_dbo.Dim_Instrument` (instrument metadata), `DWH_dbo.Fact_SnapshotCustomer` (customer attributes at the snapshot date), and `DWH_dbo.Dim_Customer` (static customer data). Ticket fees come from `DWH_dbo.Fact_CustomerAction` (ActionTypeID=35, IsFeeDividend=4). IBAN trade flags from `BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN` / `BI_DB_Positions_Closed_To_IBAN`. eMoney account flags from `eMoney_dbo.eMoney_Dim_Account`.

Loaded daily by `SP_Clicks_OpenClose_Breakdown(@Date)` using DELETE+INSERT for the given date. The SP was created 2024-05-14 (SR-252040) and has undergone 11 revisions. The table holds ~1.35 billion rows (2022-01-01 to present), with last load at 2026-03-11.

---

## 2. Business Logic

### 2.1 Open vs Close Click Separation

**What**: Each position event is split into separate rows for the open click and the close click.

**Columns Involved**: `OpenOrClose`, `OpenOrCloseID`, `Click`, `Volume`, `Units`, `FullCommission`

**Rules**:
- Open Click (`OpenOrCloseID=1`): counted when `OpenDateID=@DateID AND IsPartialCloseChild=0`. Volume = SUM over OriginalPositionID partition. Units = InitialUnits. Commission = accumulated FullCommissionByUnits including partial close children.
- Close Click (`OpenOrCloseID=0`): counted when `CloseDateID=@DateID`. Volume = VolumeOnClose. Units = AmountInUnitsDecimal. Commission = FullCommissionOnClose (minus FullCommissionByUnits for non-same-day opens).
- AirDrop opens are UNION ALL'd separately with Click=NumberofPositionsOpened, zero ticket fees, and IsFTDClick always 0.

**Diagram**:
```
Position opened today ──► Open Click row (OpenOrCloseID=1)
                           Volume = SUM(dp.Volume) over OriginalPositionID
                           Units  = InitialUnits
                           Commission = FullCommissionOnOpenInit

Position closed today ──► Close Click row (OpenOrCloseID=0)
                           Volume = VolumeOnClose
                           Units  = AmountInUnitsDecimal
                           Commission = FullCommissionOnClose[-ByUnits]
```

### 2.2 Ticket Size Bucketing

**What**: Positions are classified into 16 USD volume buckets for distribution analysis.

**Columns Involved**: `Size of Tickets`

**Rules**:
- Buckets: 1$-10$, 10$-25$, 25$-50$, 50$-100$, 100$-250$, 250$-500$, 500$-1000$, 1000$-5000$, 5000$-10000$, 10000$-50000$, 50000$-100000$, 100000$-250000$, 250000$-500000$, 500000$-1000000$, 1000000$-2000000$, Over2000000$
- Open clicks use VolumeOpened, Close clicks use VolumeClosed
- Value '0' means zero volume

### 2.3 Islamic Account Detection

**What**: Identifies swap-free (Islamic) accounts.

**Columns Involved**: `IsIslamic`

**Rules**:
- `IsIslamic = CASE WHEN WeekendFeePrecentage = 0 THEN 1 ELSE 0 END`
- Source: `Dim_Customer.WeekendFeePrecentage`. A value of 0 means the customer pays no weekend swap fees, indicating Islamic account status.

### 2.4 Ticket Fee Logic

**What**: Links position-level ticket fees from Fact_CustomerAction.

**Columns Involved**: `IsTicketFee`, `TicketFee`

**Rules**:
- Ticket fees: `Fact_CustomerAction WHERE ActionTypeID=35 AND IsFeeDividend=4 AND DateID=@DateID`
- Joined on PositionID AND OpenOrCloseID (open ticket fee matched to open click, close fee to close click)
- When a position has 2 fee records, ROW_NUMBER by Occurred assigns rn=1 to first (open), rn=2 to second (close)

### 2.5 Customer Inclusion Logic

**What**: Determines which customers' positions are included.

**Columns Involved**: `CID`, `HedgeServerID`

**Rules**:
- Standard path: `IsValidCustomer = 1` from Fact_SnapshotCustomer
- Exception: HedgeServerID = 35 positions are included even for invalid customers (`IsValidCustomer=0 AND HedgeServerID=35`)
- Positions must overlap with @Date: `OpenDateID <= @DateID` AND (`CloseDateID >= @DateID` OR `CloseDateID = 0`)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED COLUMNSTORE INDEX and a non-clustered index on `Date`. For date-range queries, always filter on `Date` (or `DateID`) to leverage the NCI. ROUND_ROBIN means JOINs on any column will require data movement — filter early to reduce shuffle.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily open/close click counts by regulation | `WHERE Date = @date GROUP BY Regulation, OpenOrClose` |
| Volume by instrument type for a date range | `WHERE Date BETWEEN @start AND @end GROUP BY InstrumentType, OpenOrClose` |
| Commission breakdown: open vs close | `SUM(FullCommission) WHERE Date = @date GROUP BY OpenOrCloseID` |
| Copy-trade vs direct trade activity | `GROUP BY IsCopy, OpenOrClose` filtered on Date |
| Islamic account trading patterns | `WHERE IsIslamic = 1 AND Date = @date` |
| Ticket fee analysis | `WHERE IsTicketFee = 1 AND Date BETWEEN ...` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Additional instrument details (AssetClass, ISIN) |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer profile |
| DWH_dbo.Dim_Country | ON CountryID | Additional country attributes beyond Region |

### 3.4 Gotchas

- **Open vs Close double-counting**: A position opened AND closed on the same day produces TWO rows (one open, one close). SUM(Click) across both OpenOrCloseIDs counts 2 events — filter on OpenOrCloseID if you want opens or closes only.
- **AirDrop positions**: AirDrop opens (IsAirDrop=1) are included separately and always have IsFTDClick=0 and TicketFee=0. They are UNION ALL'd and not deduplicated.
- **HeldOnReportDate is NOT IsOpen**: Renamed from IsOpen in SR-325240. Value 1 means the position was held (open) at end of report date; 0 means it was already closed by report date. For close clicks, this is always 0.
- **Volume is aggregated**: The Volume column is SUM(VolumeOpened) or SUM(VolumeClosed), already aggregated in the final GROUP BY. It is not position-level volume.
- **HaseMoneyAccount typo**: Column name has intentional typo (Hase instead of Has). Reflects eMoney account ownership.
- **Partial close children excluded from open clicks**: `IsPartialCloseChild=0` filter ensures only the original open is counted, not partial close fragments.

---

## 4. Elements

**Confidence Tier Legend**

| Stars | Tiers | Tag |
|-------|-------|-----|
| 4 stars | Tier 1 (upstream DWH_dbo wiki) | `(Tier 1 — ...)` |
| 3 stars | Tier 2 (SP code) | `(Tier 2 — ...)` |
| 2 stars | Tier 3 (live data / DDL) | `(Tier 3 — ...)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date. Set to `@Date` SP parameter (typically yesterday). One day's worth of clicks per load. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 2 | DateID | int | YES | Date as YYYYMMDD integer. `CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)`. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 3 | SellCurrency | varchar(10) | YES | Text abbreviation of the instrument's sell-side (denomination) currency. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 2 — SP_Dim_Instrument) |
| 4 | Club | varchar(100) | YES | Player tier name from Dim_PlayerLevel (e.g., Bronze, Silver, Gold, Platinum). Customer's loyalty/tier level at the snapshot date. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 5 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) |
| 6 | IsBuy | bit | YES | Trade direction. 1=Long (buy), 0=Short (sell). (Tier 1 — Trade.PositionTbl) |
| 7 | HeldOnReportDate | bit | YES | Whether position was still open at end of report date. `CASE WHEN CloseDateID > @DateID OR CloseDateID = 0 THEN 1 ELSE 0 END`. Renamed from IsOpen (SR-325240). Always 0 for close clicks. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 8 | HedgeServerID | int | YES | Liquidity provider server ID. Identifies which hedge server executed the position. Key servers: 2=JP Morgan legacy, 101=Goldman Sachs, 81=Real Stocks LP. HedgeServerID=35 allows invalid customer inclusion. (Tier 1 — Trade.PositionTbl) |
| 9 | InstrumentID | int | YES | Instrument identifier. FK to DWH_dbo.Dim_Instrument. (Tier 1 — Trade.PositionTbl) |
| 10 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than InstrumentName (e.g., 'Apple Inc.' vs 'Apple'). (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 11 | InstrumentName | varchar(100) | YES | Internal instrument name from Trade.Instrument. Renamed from Dim_Instrument.Name. For forex: pair notation (e.g., EUR/USD). For stocks: company name. (Tier 3 — live data, etoro.Trade.GetInstrument) |
| 12 | InstrumentTypeID | int | YES | Asset class: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. (Tier 2 — SP_Dim_Instrument) |
| 13 | InstrumentType | varchar(50) | YES | Text label for InstrumentTypeID. DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 — SP_Dim_Instrument) |
| 14 | IsCopy | bit | YES | Copy-trade flag. `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END`. 1=position opened via CopyTrader, 0=direct trade. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 15 | IsCFD | bit | YES | CFD vs Real asset flag. `CASE WHEN IsSettled = 1 THEN 0 ELSE 1 END`. 1=CFD (contract for difference), 0=Real stock/crypto ownership. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 16 | Symbol | varchar(100) | YES | Ticker symbol for the instrument (e.g., AAPL, EURUSD, BTCUSD). Used for display, search, and price feed identification. (Tier 3 — live data, etoro.Trade.GetInstrument) |
| 17 | Leverage | int | YES | Position leverage multiplier. 1=unleveraged (real stocks), 2-30=leveraged (CFDs). From Dim_Position.Leverage. (Tier 1 — Trade.PositionTbl) |
| 18 | Exchange | varchar(50) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-stock instruments. (Tier 3 — live data, etoro_Trade_InstrumentMetaData) |
| 19 | CountryID | int | YES | Customer's registered country at snapshot date. FK to Dim_Country. From Fact_SnapshotCustomer via Dim_Country. (Tier 1 — Dictionary.Country upstream wiki) |
| 20 | Country | varchar(50) | YES | Country name from Dim_Country.Name. (Tier 1 — Dictionary.Country upstream wiki) |
| 21 | Region | varchar(50) | YES | Marketing region manual override. From Dim_Country.MarketingRegionManualName. Examples: Latam, UK, German, CEE, SEA. (Tier 3 — Ext_Dim_Country live data) |
| 22 | RegulationID | int | YES | Customer's regulatory jurisdiction at snapshot date. FK to Dim_Regulation. 1=CySEC, 2=FCA, etc. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 23 | Regulation | varchar(50) | YES | Regulation name from Dim_Regulation.Name. Examples: CySEC, FCA, ASIC. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 24 | IsIslamic | bit | YES | Islamic (swap-free) account flag. `CASE WHEN WeekendFeePrecentage = 0 THEN 1 ELSE 0 END`. Source: Dim_Customer.WeekendFeePrecentage. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 25 | Size of Tickets | varchar(100) | YES | Volume bucket label. 16 buckets from '1$-10$' to 'Over2000000$'. Open clicks bucketed on VolumeOpened, close clicks on VolumeClosed. '0' = zero volume. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 26 | OpenOrClose | varchar(100) | YES | Row type: `'Open Click'` or `'Close Click'`. Literal string set by SP. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 27 | OpenOrCloseID | int | YES | Row type numeric: 1=Open Click, 0=Close Click. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 28 | Click | bigint | YES | Trade event count. `SUM(NumberofPositionsOpened)` for opens (1 per non-partial-close position opened on @Date), `SUM(NumberofPositionsClosed)` for closes. Aggregated in GROUP BY. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 29 | Volume | money | YES | USD trade volume. For opens: `SUM(CAST(VolumeOpened AS BIGINT))` where VolumeOpened = SUM(Dim_Position.Volume) over OriginalPositionID partition. For closes: `SUM(VolumeClosed)` where VolumeClosed = VolumeOnClose. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 30 | Units | money | YES | Instrument units traded. For opens: `SUM(InitialUnits)` WHERE OpenDateID=@DateID. For closes: `SUM(AmountInUnitsDecimal)` WHERE CloseDateID=@DateID. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 31 | FullCommission | money | YES | Commission amount. Opens: `SUM(FullCommissionOnOpenInit)` — accumulated FullCommissionByUnits including partial close children. Closes: `SUM(FullCommissionOnClose)` for same-day opens, `SUM(FullCommissionOnClose - FullCommissionByUnits)` for older positions. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 32 | InitialAmountUSDOnOpen | money | YES | Initial investment in USD for open clicks only. `SUM(InitialAmountCents/100) WHERE NumberofPositionsOpened=1`. Always 0 for close clicks. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 33 | UpdateDate | datetime | YES | ETL load timestamp. Set to `GETDATE()` on each daily reload. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 34 | IsPI | bit | YES | Popular Investor flag. `CASE WHEN GuruStatusID >= 2 THEN 1 ELSE 0 END`. Source: Fact_SnapshotCustomer.GuruStatusID. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 35 | IsTicketFee | bit | YES | Has ticket fee flag. `CASE WHEN Fact_CustomerAction.Amount IS NOT NULL THEN 1 ELSE 0 END`. Ticket fee = ActionTypeID=35 AND IsFeeDividend=4. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 36 | TicketFee | money | YES | Ticket fee amount. `SUM(Amount)` from Fact_CustomerAction WHERE ActionTypeID=35 AND IsFeeDividend=4 AND DateID=@DateID. Joined on PositionID+OpenOrCloseID. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 37 | IsAirDrop | bit | YES | AirDrop position flag. `CASE WHEN Dim_Position.IsAirDrop = 1 THEN 1 ELSE 0 END`. AirDrop opens are treated separately: zero ticket fees, IsFTDClick always 0. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 38 | IsFuture | bit | YES | Futures instrument flag. Direct from Dim_Instrument.IsFuture. Added SR-308870 (2025-04-07). (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 39 | HaseMoneyAccount | bit | YES | Has eMoney account flag (note: intentional typo in column name). `CASE WHEN eMoney_Dim_Account.CID IS NOT NULL THEN 1 ELSE 0 END` WHERE GCID_Unique_Count=1 AND IsValidETM=1. Added SR-346605 (2025-12-07). (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 40 | IsIBANClick | bit | YES | IBAN-originated trade flag. Opens: `CASE WHEN BI_DB_Positions_Opened_From_IBAN.PositionID IS NOT NULL THEN 1 ELSE 0 END`. Closes: same with BI_DB_Positions_Closed_To_IBAN. Added SR-346605 (2025-12-07). (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 41 | IsFTDClick | bit | YES | First Trade after Deposit flag. `CASE WHEN dp.PositionID = dc.PositionID THEN 1 ELSE 0 END`. dc.PositionID = first non-airdrop position opened after customer's first deposit date (ROW_NUMBER=1). Always 0 for close clicks and AirDrop opens. Added SR-346605. (Tier 2 — SP_Clicks_OpenClose_Breakdown) |
| 42 | IsLowTouch | bit | YES | Low-touch instrument flag. From Dim_Instrument.OperationMode. Indicates instruments with simplified execution flow. Added SR-346605 (2025-12-07). (Tier 2 — SP_Clicks_OpenClose_Breakdown) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Trade.PositionTbl (via Dim_Position) | CID | passthrough |
| IsBuy | Trade.PositionTbl (via Dim_Position) | IsBuy | passthrough |
| HedgeServerID | Trade.PositionTbl (via Dim_Position) | HedgeServerID | passthrough |
| InstrumentID | Trade.Instrument (via Dim_Instrument) | InstrumentID | passthrough |
| Leverage | Trade.PositionTbl (via Dim_Position) | Leverage | passthrough |
| CountryID | Dictionary.Country (via Dim_Country) | CountryID | passthrough |
| Click, Volume, Units, Commission | Multiple DWH sources | Various | ETL aggregation |

Full production documentation: see upstream wikis in `DWH_dbo/Tables/` (source configured in dwh-semantic-doc-config.json).

### 5.2 ETL Pipeline

```
DWH_dbo dimensions/facts → SP_Clicks_OpenClose_Breakdown(@Date) → Dealing_Clicks_OpenClose_Breakdown
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_dbo.Dim_Position, Dim_Instrument, Fact_SnapshotCustomer, Dim_Customer, etc. | Pre-computed DWH dimensions |
| ETL | SP_Clicks_OpenClose_Breakdown | DELETE+INSERT for @Date. Builds 10+ temp tables, aggregates clicks. |
| Target | Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown | Final aggregated table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who executed the trade |
| InstrumentID | DWH_dbo.Dim_Instrument | Financial instrument traded |
| CountryID | DWH_dbo.Dim_Country | Customer's registered country |
| RegulationID | DWH_dbo.Dim_Regulation | Regulatory jurisdiction |
| HedgeServerID | Dealing_staging sources | Liquidity provider server |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | No known downstream consumers in SSDT |

---

## 7. Sample Queries

### 7.1 Daily open/close breakdown by regulation
```sql
SELECT Date, Regulation, OpenOrClose,
       SUM(Click) AS TotalClicks,
       SUM(Volume) AS TotalVolume,
       SUM(FullCommission) AS TotalCommission
FROM Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown
WHERE Date = '2026-03-10'
GROUP BY Date, Regulation, OpenOrClose
ORDER BY Regulation, OpenOrClose;
```

### 7.2 Real vs CFD click distribution by instrument type
```sql
SELECT InstrumentType, IsCFD,
       SUM(CASE WHEN OpenOrCloseID = 1 THEN Click ELSE 0 END) AS Opens,
       SUM(CASE WHEN OpenOrCloseID = 0 THEN Click ELSE 0 END) AS Closes,
       SUM(Volume) AS TotalVolume
FROM Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown
WHERE Date BETWEEN '2026-03-01' AND '2026-03-10'
GROUP BY InstrumentType, IsCFD
ORDER BY InstrumentType;
```

### 7.3 Ticket fee revenue analysis with instrument details
```sql
SELECT c.Date, c.InstrumentDisplayName, c.Regulation,
       SUM(c.TicketFee) AS TotalTicketFee,
       SUM(c.Click) AS Clicks,
       SUM(c.FullCommission) AS Commission
FROM Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown c
WHERE c.IsTicketFee = 1
  AND c.Date BETWEEN '2026-03-01' AND '2026-03-10'
GROUP BY c.Date, c.InstrumentDisplayName, c.Regulation
ORDER BY TotalTicketFee DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Close/Close All/Partial Close Position Request](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/11895996970) | Confluence | Position close flows and BackOffice close scenarios |
| [Trade From IBAN Account - Open / Close Position](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12211912747) | Confluence | IBAN trade flow context for IsIBANClick column |
| SR-252040 | Jira | Original SP creation ticket |
| SR-325240 | Jira | Renamed IsOpen to HeldOnReportDate |
| SR-346605 | Jira | Added HaseMoneyAccount, IsIBANClick, IsFTDClick, IsLowTouch columns |

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★★☆) | Phases: 9/14*
*Tiers: 6 T1, 30 T2, 4 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 5/10, Sources: 8/10*
*Object: Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown | Type: Table | Production Source: Derived (multi-source ETL)*
