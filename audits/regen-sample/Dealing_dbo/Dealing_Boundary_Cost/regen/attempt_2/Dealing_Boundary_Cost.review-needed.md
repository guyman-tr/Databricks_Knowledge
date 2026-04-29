# Review Needed: Dealing_dbo.Dealing_Boundary_Cost

## Items Requiring Human Review

### 1. Data Loading Status — Paused or Deprecated?

The table has no data after 2024-03-17. SP_Boundary_Cost exists in SSDT but may no longer be scheduled. Confirm:
- Is the SP still running? If so, is it writing to a different target?
- Was it intentionally deprecated? If so, should the wiki note this?
- Are there migration scripts (NoDbObjectsScripts/2024_09_* files suggest Dealing_Migration activity)?

### 2. IsSettled NULL Values

Live data shows 3 distinct IsSettled values: 0, 1, and NULL. The NULL case is not handled explicitly in the SP code — it appears to flow through from Dim_Position where IsSettled may be NULL for some positions. Confirm whether NULL IsSettled has business meaning or is a data quality issue.

### 3. etoro_Hedge_InstrumentBoundaries — No Upstream Wiki

The boundary columns (LowerBoundary, UpperBoundary, HedgeRiskLimit) are sourced from `dbo.etoro_Hedge_InstrumentBoundaries`, which has no wiki documentation. The descriptions are based on SP code analysis:
- `LowerBoundary = (-1) * CloseThresholdPercentage * OpenThresholdUSD / 100`
- `UpperBoundary = OpenThresholdUSD`
- `HedgeRiskLimit = HedgeRiskLimitUSD`

Confirm these business semantics with the Dealing team.

### 4. VolumeBuy/VolumeSell Direction Flip Semantics

The SP flips buy/sell direction for closing positions (closing a long registers as a sell). This is standard for NOP accounting but may surprise analysts. Confirm this is the intended interpretation for downstream consumers.

### 5. Previous-Day NOP Source

The SP reads previous-day NOP from `BI_DB_dbo.BI_DB_PositionPnL` (not from a prior day's Dealing_Boundary_Cost row). Confirm this is intentional and that BI_DB_PositionPnL is the authoritative source for overnight NOP.

### 6. PriceLog Data Lake COPY INTO Pattern

The SP dynamically constructs a `COPY INTO` statement to load intraday price data from `internal-sources` external data source into `BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp`. This staging table is ephemeral (auto-created). No upstream wiki exists for the PriceLog feed. Confirm the price feed schema (Bid, Ask, BidSpreaded, AskSpreaded, Occurred, InstrumentID) is stable.

### 7. Companion Table: Dealing_Boundary_Cost_H_Indices

A companion table `Dealing_dbo.Dealing_Boundary_Cost_H_Indices` exists in the same schema. Its relationship to this table should be documented once that table is processed.

---

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 1 | InstrumentID (passthrough from Trade.Instrument via Dim_Instrument) |
| Tier 2 | 28 | Most columns — ETL-computed by SP_Boundary_Cost |
| Tier 5 | 2 | IsSettled (domain-expert confirmed semantics from Dim_Position) |
| **Total** | **31** | |

No Tier 3 or Tier 4 columns. All columns are grounded in SP code analysis and/or upstream wiki inheritance.
