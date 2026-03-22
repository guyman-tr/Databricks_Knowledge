# Dealing_dbo.Dealing_AbuseAPI

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_AbuseAPI |
| **Type** | Table |
| **Distribution** | HASH (`CID`) |
| **Index** | CLUSTERED on `CloseDate` |
| **Columns** | 18 |
| **Primary Source** | `DWH_dbo.Dim_Position` (Trade.PositionTbl, etoroDB-REAL) |
| **ETL SP** | `Dealing_dbo.SP_AbuseAPI` |
| **Refresh** | Daily per @Date (delete+insert) |
| **PII** | YES — contains CID, Country, Region |
| **Tags** | dealing, compliance, abuse-detection, api-abuse, surveillance, high-frequency, position-detection |

---

## 1. Business Meaning

`Dealing_AbuseAPI` is a **daily API abuse detection table** for the Dealing/Compliance team. It identifies customers who opened 3 or more positions in the same instrument type within 1 second AND earned a daily net profit ≥ $5,000 on the open date.

The detection pattern targets potential automated API exploitation: a customer using an API to rapidly place many positions in quick succession suggests algorithmic trading or an API exploit, particularly when combined with significant profit. This is a compliance signal for the dealing desk to review.

**Flagging criteria (all must be met)**:
1. Position **closed on @Date** and open duration **≤ 24 hours**
2. Customer has **≥ 3 positions** in the same `InstrumentType` opened on the same day
3. Among those positions, at least 3 consecutive positions (by open time) have a combined inter-open gap of **≤ 1,000 milliseconds** (1 second total)
4. Customer's **DailyNetProfit ≥ $5,000** in that InstrumentType on the open date

**Clean days**: On days with no flagged customers, the SP still inserts one row from `Dim_Date` via a LEFT JOIN, resulting in a row where all columns except `UpdateDate` are NULL. This is expected behavior — it confirms the SP ran. Use `WHERE CID IS NOT NULL` to filter for actual abuse events.

**SP Author**: Jenia (2019-12-09); Synapse migration 2023 (SR-222941).

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per CloseDate

`SP_AbuseAPI(@Date)` works in stages:

1. **`#base`**: All positions closed on @Date within 24 hours of opening, by valid manual customers (MirrorID=0, IsValidCustomer=1, IsPartialCloseChild=0). Includes InstrumentType, CID, NetProfit, OpenOccurred.

2. **`#minimum3`**: Filters to customers who have ≥3 positions in the same InstrumentType on the same open date.

3. **`#msdiff`**: Adds `MS_Diff` = millisecond gap between consecutive position opens (LAG window within InstrumentType×CID×OpenDate).

4. **`#DailyNetProfit`**: Per CID×InstrumentType×OpenDate: sum of NetProfit. Used to enforce the $5,000 threshold.

5. **`#lead`**: Adds `MS_Diff2` and `MS_Diff3` (LEAD of gaps) and `PositionID2/3` (IDs of the following positions).

6. **`#OneSec`**: Rows where 3 consecutive positions have total combined time ≤ 1,000ms: `ISNULL(MS_Diff,0) + MS_Diff2 + MS_Diff3 <= 1000`. These represent the "bursts".

7. **`#Final`**: Joins back to Dim_Position for all 3 positions in each burst (PositionID, PositionID2, PositionID3 from #OneSec), filtered to `DailyNetProfit >= 5000`. Enriched with Dim_Customer, Dim_Country, Dim_Instrument.

8. **YTD Zero/Commission (`#a`, `#b`, `#YTD`)**: For flagged CIDs, computes year-to-date:
   - `ZeroPnL` = NetProfit + commission (closed positions) or mark-to-market PnL (open positions) — the "zero PnL" metric
   - `FullCommission` = cumulative commission paid YTD
   - Split into `#a` (positions opened this year) and `#b` (positions opened before this year but still in YTD scope)

9. **INSERT**: LEFT JOINs `Dim_Date` to `#Final` (ensuring at least one row per day even when no abuse detected) and joins `#YTD` for the YTD metrics.

### Zero PnL Concept

`Zero = NetProfit + FullCommissionOnClose` = the "commission-adjusted" profit of the position. If a customer's profit comes entirely from commission rebates or spread manipulation, Zero would be close to zero or negative even if NetProfit is positive.

`YTD_Zero` extends this to the full year-to-date, accounting for open positions using mark-to-market PnL from `BI_DB_PositionPnL`.

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `DWH_dbo.Dim_Position` | `PositionID, CID` | Position data (primary source) |
| `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument type and name |
| `DWH_dbo.Dim_Customer` | `RealCID` | Valid customer filter |
| `DWH_dbo.Dim_Country` | `CountryID` | Country and Region enrichment |
| `DWH_dbo.Dim_Date` | `FullDate` | Ensures one row per reporting date (sentinel) |
| `BI_DB_dbo.BI_DB_PositionPnL` | `PositionID, DateID` | Mark-to-market PnL for open positions in YTD calc |
| `Dealing_dbo.Dealing_AbusersCIDs` | `CID` | Related watchlist — CIDs that triggered this signal historically |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_AbuseAPI)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CloseDate | date | YES | The date the position was closed (@Date SP parameter). Clustered index key. NULL on sentinel rows (clean days with no flagged positions). (Tier 2 — SP_AbuseAPI) |
| 2 | OpenDate | date | YES | The date the position was opened. Derived from `CAST(OpenOccurred AS DATE)`. NULL on sentinel rows. (Tier 2 — SP_AbuseAPI) |
| 3 | PositionID | bigint | YES | The flagged position ID. One row per position in the burst (3 positions per burst event, one of PositionID/PositionID2/PositionID3). NULL on sentinel rows. (Tier 2 — SP_AbuseAPI) |
| 4 | CID | int | YES | Customer account ID. NULL on sentinel rows. **PII field.** (Tier 2 — SP_AbuseAPI) |
| 5 | Country | varchar(50) | YES | Customer's country. From Dim_Country. **PII field.** (Tier 2 — SP_AbuseAPI) |
| 6 | Region | varchar(50) | YES | Customer's sales region. From Dim_Country. **PII field.** (Tier 2 — SP_AbuseAPI) |
| 7 | InstrumentID | int | YES | Instrument identifier. FK to Dim_Instrument. (Tier 2 — SP_AbuseAPI) |
| 8 | Instrument | varchar(50) | YES | Instrument internal name (Dim_Instrument.Name). (Tier 2 — SP_AbuseAPI) |
| 9 | InstrumentType | varchar(50) | YES | Instrument type (e.g., 'Stocks', 'Crypto', 'Currencies'). The burst detection groups by InstrumentType, not InstrumentID — bursts across different instruments of the same type are detected. (Tier 2 — SP_AbuseAPI) |
| 10 | OpenOccurred | datetime | YES | Timestamp when the position was opened. Used for millisecond-level burst detection. (Tier 2 — SP_AbuseAPI) |
| 11 | CloseOccurred | datetime | YES | Timestamp when the position was closed. (Tier 2 — SP_AbuseAPI) |
| 12 | NetProfit | money | YES | Position-level net profit in USD from Dim_Position. (Tier 2 — SP_AbuseAPI) |
| 13 | DailyNetProfit | money | YES | Sum of NetProfit for this CID×InstrumentType on the open date. Flagging threshold: ≥ $5,000. (Tier 2 — SP_AbuseAPI) |
| 14 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at time SP ran. Always populated, including sentinel rows. (Tier 2 — SP_AbuseAPI) |
| 15 | FullCommissionOnClose | money | YES | Commission paid on position close from Dim_Position.FullCommissionOnClose. (Tier 2 — SP_AbuseAPI) |
| 16 | Zero | money | YES | `NetProfit + FullCommissionOnClose` — commission-adjusted position PnL. If a customer profits purely from spread/commission mechanics, Zero will be near 0 or negative. (Tier 2 — SP_AbuseAPI) |
| 17 | YTD_Zero | money | YES | Year-to-date commission-adjusted PnL for this CID: `SUM(NetProfit + Commission)` across all positions (closed and open, using BI_DB_PositionPnL for open positions), from Jan 1 of @Date's year through @Date. (Tier 2 — SP_AbuseAPI) |
| 18 | YTD_Commission | money | YES | Year-to-date commission paid by this CID (FullCommissionOnClose for closed; FullCommissionByUnits for open). Companion to YTD_Zero for understanding how much of YTD Zero is pure profit vs commission offset. (Tier 2 — SP_AbuseAPI) |

---

## 5. Usage Notes

**Filter NULL rows**: Always include `WHERE CID IS NOT NULL` to exclude sentinel rows (clean days). The sentinel rows exist to confirm the SP ran, but contain no business data.

**Burst detection granularity**: Bursts are detected at the `InstrumentType` level (not InstrumentID). A customer opening 3 positions in 3 different stocks within 1 second would still be flagged if all are 'Stocks' type.

**3 rows per burst**: Each burst event produces 3 rows (PositionID, PositionID2, PositionID3). To count unique burst events, use `COUNT(DISTINCT PositionID)` or group by the "first position" logic — not straightforward from this table alone.

**YTD context**: `YTD_Zero` and `YTD_Commission` are computed for the entire CID's portfolio YTD — not just the flagged positions. They provide context on whether this is a repeat offender accumulating large YTD profits.

**Distribution on CID**: Efficient for CID-based lookups. NULLable CID (sentinel rows) all hash to the same bucket — minor skew risk.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Dim_Position (Trade.PositionTbl via DWH ETL) |
| **Refresh** | Daily per date via `SP_AbuseAPI(@Date)` |
| **SP Author** | Jenia (2019-12-09); Synapse migration 2023 (SR-222941) |
| **PII** | YES — CID, Country, Region |
| **Compliance** | API abuse detection for dealing desk surveillance |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 4/5 | Table active (UpdateDate 2026-03-11); recent rows are sentinel-only (no flagged events) — normal behavior |
| SP Logic | 5/5 | Short SP (298 lines) fully analyzed; burst detection logic fully traced |
| Upstream Wiki | 3/5 | Primary source (Dim_Position) documented; BI_DB_PositionPnL documented |
| Business Context | 2/5 | Atlassian MCP unavailable; purpose inferred from SP comments and logic |
| **Total** | **7.8/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
