# BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_eToroDB

> 14.3K-row eToro side of the US stock/ETF activity reconciliation — capturing daily settled position deliveries and airdrop receipts for FinCEN+FINRA-regulated customers from Dim_Position, from November 2021 to present. Paired with BI_DB_US_Apex_Stocks_Activity_Apex for cross-system reconciliation. Refreshed daily via SP_US_Apex_Stocks_Activity_Recon with DELETE+INSERT by Date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position (settled positions) + DWH_dbo.Dim_Instrument (name/CUSIP) + DWH_dbo.Dim_ClosePositionReason (close reason) |
| **Refresh** | Daily (SP_US_Apex_Stocks_Activity_Recon, DELETE+INSERT by Date, SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_US_Apex_Stocks_Activity_eToroDB` is the eToro-side half of a two-table reconciliation pair that compares stock/ETF settlement activity between Apex Clearing and eToro's internal position records. This table contains share deliveries and receipts as recorded in eToro's DWH from Dim_Position.

Each row represents a settled stock/ETF position event for a US-regulated (RegulationIDOnOpen=8) customer on a specific date, with both rounded and exact unit counts. The SP captures two event types:
1. **Deliveries** (ClosePositionReasonID IN 9, 10): Hierarchical or system closes on @Date → shares delivered to Apex
2. **Receipts** (IsAirDrop=1): Stock/crypto airdrops opened on @Date → shares received from issuer

The companion table `BI_DB_US_Apex_Stocks_Activity_Apex` contains the same activity from Apex's SOD 870 files, enabling unit-level reconciliation.

---

## 2. Business Logic

### 2.1 Delivery vs Receipt Classification

**What**: Position events are classified as delivered or received based on close reason.
**Columns Involved**: `Category`, `ClosePositionReasonID`, `IsAirDrop`
**Rules**:
- ClosePositionReasonID IN (9, 10) → 'Delivered' (hierarchical close / system close — shares sent to Apex)
- IsAirDrop = 1 → 'Recieved' (airdrop — shares received)
- Date determination follows the same logic: Delivered uses CloseOccurred, Received uses OpenOccurred

### 2.2 Unit Rounding

**What**: Both exact fractional and rounded integer units are tracked.
**Columns Involved**: `RoundeUnits`, `ExactUnits`
**Rules**:
- RoundeUnits = SUM(ROUND(AmountInUnitsDecimal, 0)) — integer units for reconciliation with Apex (which reports integers)
- ExactUnits = SUM(AmountInUnitsDecimal) — precise fractional units for internal tracking
- Discrepancies between the two indicate fractional share rounding effects

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN, HEAP. Small table (14K rows). Full scan acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| eToro activity for a date | `WHERE [Date] = @date` |
| Airdrops only | `WHERE IsAirDrop = 1` |
| Reconciliation with Apex | JOIN with BI_DB_US_Apex_Stocks_Activity_Apex on CID+CUSIP+Date+Category |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_Apex | CID + CUSIP + Date=EntryDate + Category | Reconciliation pair |
| DWH_dbo.Dim_Instrument | CUSIP | Full instrument attributes |

### 3.4 Gotchas

- **"RoundeUnits" typo**: Column name missing 'd' — `RoundeUnits` not `RoundedUnits`. In the DDL; cannot rename without ALTER
- **"Recieved" spelling**: Same typo as Apex side — consistent across both tables
- **ExactUnits fractional**: Values like 0.446090 for fractional shares. Apex side only has integer Units — rounding differences expected
- **ClosePositionReasonID NULL for airdrops**: Airdrops have NULL ClosePositionReasonID and NULL CloseReason (they're opens, not closes)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL infrastructure / standard metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. From Dim_Position.CID. Filtered to RegulationIDOnOpen=8 (US). (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, Dim_Position) |
| 2 | InstrumentDisplayName | varchar(200) | YES | Human-readable instrument name (e.g., "First Solar, Inc.", "ServiceNow Inc"). From Dim_Instrument via DWHInstrumentID. InstrumentTypeID IN (5, 6) = stocks and ETFs only. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, Dim_Instrument) |
| 3 | CUSIP | varchar(100) | YES | CUSIP identifier for the security. From Dim_Instrument. Standard 9-character format (e.g., "336433107"). Used as reconciliation key with the Apex side. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, Dim_Instrument) |
| 4 | Date | date | YES | Date of the activity. For deliveries (ClosePositionReasonID IN 9,10): CAST(CloseOccurred AS DATE). For receipts (IsAirDrop=1): CAST(OpenOccurred AS DATE). Range: 2021-11-08 to present. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, Dim_Position) |
| 5 | Category | varchar(50) | YES | Direction of share movement. 'Delivered' (62%) = ClosePositionReasonID IN (9,10) — shares sent to Apex. 'Recieved' (38%) = IsAirDrop=1 — shares received as airdrop. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon) |
| 6 | IsAirDrop | int | YES | Whether the position was a stock/crypto airdrop. 1 = airdrop receipt. NULL/0 = regular close/delivery. From Dim_Position.IsAirDrop. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, Dim_Position) |
| 7 | CloseReason | varchar(50) | YES | Close position reason name. "Hierarchical Close" for ID=9, other system close reasons for ID=10. NULL for airdrops (they are opens, not closes). From Dim_ClosePositionReason.Name. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, Dim_ClosePositionReason) |
| 8 | ClosePositionReasonID | int | YES | Close position reason ID. 9=Hierarchical Close, 10=system close. NULL for airdrops. From Dim_Position. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, Dim_Position) |
| 9 | RoundeUnits | int | YES | Rounded integer number of shares/units. SUM(ROUND(AmountInUnitsDecimal, 0)). Used for reconciliation with Apex (which reports integer units). Note: column name has typo (missing 'd'). (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, Dim_Position) |
| 10 | ExactUnits | decimal(16,6) | YES | Exact fractional number of shares/units. SUM(AmountInUnitsDecimal). Precision for fractional shares (e.g., 0.446090). (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, Dim_Position) |
| 11 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_US_Apex_Stocks_Activity_Recon (GETDATE()). (Tier 5 — SP_US_Apex_Stocks_Activity_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CID | Dim_Position | CID | Passthrough |
| InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | JOIN |
| CUSIP | Dim_Instrument | CUSIP | JOIN |
| Date | Dim_Position | CloseOccurred / OpenOccurred | CASE by ClosePositionReasonID |
| Category | Dim_Position | ClosePositionReasonID / IsAirDrop | CASE logic |
| IsAirDrop | Dim_Position | IsAirDrop | Passthrough |
| CloseReason | Dim_ClosePositionReason | Name | JOIN |
| ClosePositionReasonID | Dim_Position | ClosePositionReasonID | Passthrough |
| RoundeUnits | Dim_Position | AmountInUnitsDecimal | SUM(ROUND(..., 0)) |
| ExactUnits | Dim_Position | AmountInUnitsDecimal | SUM |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
Trade.PositionTbl (production)
  |-- Generic Pipeline (Bronze) ---|
  v
DWH_staging → DWH_dbo.Dim_Position (settled positions)
  |                                              |
  |  + DWH_dbo.Dim_Instrument (name, CUSIP)      |
  |  + DWH_dbo.Dim_ClosePositionReason (reason)   |
  |                                              |
  |-- SP_US_Apex_Stocks_Activity_Recon @date ----|
  v
BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_eToroDB (14.3K rows)
  |
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Position | Position-level data |
| CUSIP | DWH_dbo.Dim_Instrument | Instrument dimension |
| ClosePositionReasonID | DWH_dbo.Dim_ClosePositionReason | Close reason lookup |

### 6.2 Referenced By (other objects point to this)

No known consumers.

---

## 7. Sample Queries

### 7.1 Daily Airdrop Activity

```sql
SELECT
    [Date], CID, InstrumentDisplayName, ExactUnits
FROM BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_eToroDB
WHERE IsAirDrop = 1
    AND [Date] >= DATEADD(MONTH, -1, GETDATE())
ORDER BY [Date] DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4, 1 T5 | Elements: 11/11, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_eToroDB | Type: Table | Production Source: Dim_Position + Dim_Instrument + Dim_ClosePositionReason*
