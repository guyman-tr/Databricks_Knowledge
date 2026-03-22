---
object: Dealing_ManualPositionClose
schema: Dealing_dbo
type: Table
description: Daily log of positions manually closed by dealers (crisis/admin operations). Captures position NOP, child position counts, operation description, operator username, and US-client flag.
etl_sp: Dealing_dbo.SP_ManualPositionClose
frequency: Daily
status: Active (last: 2026-03-10)
row_count: ~2,246,253
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.5
---

# Dealing_ManualPositionClose

Records every position manually closed by a dealer through the crisis/admin interface. Each row is one position that was force-closed, with NOP impact for both the root position and its child (copy) positions. Used by the Dealing team to audit manual intervention events and quantify NOP impact of crisis closures.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `Dealing_staging.External_DB_Logs_History_ManualPositionClose_Crisis` | Log of manual close actions (PositionID, OperationID, InsertDate) |
| Source | `Dealing_staging.External_DB_Logs_History_ManualOperationPositionClose_Crisis` | Operation metadata (OperationDescription, UserName) |
| Dimension | `DWH_dbo.Dim_Position` | Position details (InstrumentID, AmountInUnitsDecimal, EndForexRate, CloseOccurred) |
| Dimension | `DWH_dbo.Dim_Customer` | CountryID → US client flag (CountryID IN (4, 86, 153, 166, 214, 219)) |
| Writer | `Dealing_dbo.SP_ManualPositionClose` | Daily, OpsDB Priority 0 |

**Author**: Graham Ellinson (2023-05-23), migrated to Synapse by Ziv (2023-12-14, SR-222400).

**US client countries**: CountryID IN (4=USA, 86=Guam, 153=Northern Mariana Islands, 166=Puerto Rico, 214=US Virgin Islands, 219=American Samoa) → US_Client = 'Yes'.

**Tree (child) positions**: For each manually closed root position, the SP finds all copy positions (Dim_Position where TreeID = PositionID AND MirrorID > 0) and counts/sums them. NOP_ChildPositions = total NOP impact of copies.

**Date window**: Covers positions with InsertDate in [DateMinus1, Date) — i.e., yesterday's close operations mapped to today's Date.

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date (the Date parameter passed to the SP). |
| `DateID` | int | NULL | Integer date key (YYYYMMDD). |
| `PositionID` | bigint | NULL | Root position identifier (the position that was manually closed). |
| `InstrumentID` | int | NULL | Instrument of the closed position. |
| `ClosingPrice` | money | NULL | EndForexRate from Dim_Position — the execution price at position close. |
| `Conversion` | money | NULL | LastOpConversionRate — FX conversion rate used to convert position value to USD. |
| `NumberOfChildPositions` | int | NULL | Count of copy positions (MirrorID > 0) in the same tree as this root position. 0 if no copiers. |
| `NumberOfChildCIDs` | int | NULL | Count of distinct CIDs among the child positions. |
| `NOP_PositionID` | float | NULL | NOP of the root position in USD: AmountInUnitsDecimal × EndForexRate × Conversion. |
| `NOP_ChildPositions` | float | NULL | Total NOP of all child (copy) positions in USD: TotalChildUnits × EndForexRate × Conversion. 0 if no children. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| `OperationDescription` | varchar(max) | NULL | Free-text description of the operation entered by the dealer. Example: "Close position by Rate_Kyri_09Mar26_2". Useful for auditing which crisis event triggered the close. |
| `US_Client` | varchar(5) | NULL | 'Yes' if the CID belongs to a US-jurisdiction country; 'No' otherwise. US positions may require separate regulatory handling. |
| `FromDate` | date | NULL | DateMinus1 — the previous day (start of the log window scanned by the SP). Indicates the temporal source range. |
| `UserName` | varchar(255) | NULL | Username of the dealer who performed the manual close operation. Example: "tomerre". Audit trail. |
| `CloseOccurred` | datetime | NULL | Actual close timestamp from Dim_Position.CloseOccurred — when the position actually closed in the trading system. |

## Distributions & Observations

- Active: 2023-01-09 → 2026-03-10 (daily), 2,246,253 rows — the table has grown significantly
- ROUND_ROBIN distribution — cross-node joins required; filter by Date for efficient access
- Sample (2026-03-10): InstrumentID 204012, operations by user "tomerre", NOP_PositionID ~$10–30K per position, descriptions like "Close position by Rate_Kyri_09Mar26_1"
- OperationDescription is free-text: naming convention appears to be "Close position by Rate_{OperationName}_{Date}" but is not enforced
- NumberOfChildPositions=0 is common (non-PI root positions with no copiers)

## Business Context

Primary audit log for dealer intervention in client positions. Used by:
1. Risk team: quantify NOP impact of crisis events
2. Compliance/Operations: audit trail of who closed which positions and why
3. Reporting: US regulatory reporting (US_Client flag separates regulated populations)
4. Dealing team retrospectives: analyze past crisis events

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `DWH_dbo.Dim_Position` | Source for position details and tree structure |
| `Dealing_staging.External_DB_Logs_History_ManualPositionClose_Crisis` | Upstream source log |

## Quality Score: 8.5/10
*Strong: SP logic fully traced, US-client country list documented, tree-child NOP computation explained. Sample data confirms active operation. Minor deduction: no upstream generic pipeline mapping (staging log table).*
