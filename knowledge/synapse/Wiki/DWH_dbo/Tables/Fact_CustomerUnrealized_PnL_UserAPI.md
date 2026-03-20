# DWH_dbo.Fact_CustomerUnrealized_PnL_UserAPI

> API-optimized subset of Fact_CustomerUnrealized_PnL — contains only the PnL breakdowns, commission metrics, NOP/Notional values, and standard deviation per customer per day. Designed for lighter API consumption without the full equity detail.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact — daily snapshot, API subset) |
| **Row Count** | Tens of millions (one row per CID per date, same as parent table) |
| **Production Source** | DWH_dbo.Fact_CustomerUnrealized_PnL (column subset, no transformation) |
| **Refresh** | Daily — populated within SP_Fact_CustomerUnrealized_PnL after parent table |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **Synapse PK** | (CID, DateModified) NOT ENFORCED |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Fact_CustomerUnrealized_PnL_UserAPI` is a narrowed-down copy of `Fact_CustomerUnrealized_PnL`, containing 34 of the parent table's ~60 columns. The retained columns focus on:

- **PnL breakdowns** — total, copy trading, manual, stocks, crypto, by asset class
- **Commission metrics** — open commissions, full commissions, commission by units
- **NOP/Notional values** — Net Open Position and Notional values segmented by asset class (Crypto, CFD, Stock, Crypto CFD, Stock CFD)
- **Risk metric** — StandardDeviation (portfolio-level risk)
- **Transparency metric** — TransURPnL (translated unrealized PnL)

The "UserAPI" suffix indicates this table is optimized for external API exposure — reduced column count for faster data transfer and simpler consumer integration. All values are identical to the parent table; no aggregation or transformation is applied.

### What's excluded

Columns NOT in the UserAPI version (present only in the full table): equity breakdowns, cash, liabilities, regulatory metrics, position counts, overnight fees, and other internal risk metrics.

---

## 2. Business Logic

### 2.1 Simple Column Subset

```
DELETE Fact_CustomerUnrealized_PnL_UserAPI WHERE DateModified = @dateid
INSERT INTO Fact_CustomerUnrealized_PnL_UserAPI
SELECT [34 specific columns] FROM Fact_CustomerUnrealized_PnL WHERE DateModified = @dateid
```

No joins, no aggregations, no transformations. This is a direct column subset copy within the same SP that populates the parent table.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(CID) matches the parent table distribution, enabling co-located JOINs. CLUSTERED COLUMNSTORE provides excellent compression. Always filter on DateModified.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer demographics |
| DWH_dbo.Dim_Date | ON DateModified = DateID | Calendar attributes |
| DWH_dbo.Fact_CustomerUnrealized_PnL | ON CID = CID AND DateModified = DateModified | Full equity details |

### 3.3 Gotchas

- **Identical to parent**: Every row in this table exists in Fact_CustomerUnrealized_PnL with the same values. Use the parent for full equity analysis; use this table only for API/lightweight consumption
- **"Menual" typo**: Column `MenualPositionPnL` is a known typo for "Manual" — maintained for backward compatibility

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID (Real account). Distribution key. PK component. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 2 | DateModified | int | NO | Date in YYYYMMDD format. PK component. JOINs to Dim_Date. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 3 | PositionPnL | decimal(16,2) | NO | Total unrealized PnL across all open positions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 4 | CopyPositionPnL | decimal(16,2) | NO | Unrealized PnL from copy trading positions only. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 5 | MenualPositionPnL | decimal(16,2) | NO | Unrealized PnL from manually opened positions (not copy trading). Note: "Menual" is a legacy typo for "Manual". (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 6 | StocksPositionPnL | decimal(16,2) | NO | Unrealized PnL from stock positions (both CFD and real). (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 7 | UpdateDate | datetime | YES | ETL load timestamp. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 8 | TransURPnL | decimal(16,2) | YES | Translated unrealized PnL — aligns with portfolio unrealized equity / open-position P&L reporting; internal DB Scripts list this table beside equity snapshot objects for downstream services. (Tier 4 — Confluence, Portfolio Value (formerly known as Equity on the platform)) |
| 9 | StandardDeviation | float | YES | Portfolio-level risk metric — standard deviation of returns computed using instrument correlations. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 10 | CommissionOnOpen | decimal(16,2) | YES | Total commission charged on currently open positions (partial — excluding already-closed portions). (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 11 | MirrorStocksPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy trading stock positions. Subset of CopyPositionPnL. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 12 | CryptoPositionPnL | decimal(16,2) | YES | Total unrealized PnL from crypto positions (CFD + real). (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 13 | ManualCryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from manually opened crypto positions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 14 | CopyCryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy trading crypto positions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 15 | CopyFundPnL | decimal(16,2) | YES | Unrealized PnL from Smart Portfolio (fund) positions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 16 | FullCommissionOnOpen | decimal(16,2) | YES | Full commission on open positions including the portions from already-closed partial positions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 17 | NOP | decimal(16,2) | YES | Net Open Position — total net exposure across all asset classes. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 18 | Notional | decimal(16,2) | YES | Notional value — total gross position value across all asset classes. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 19 | NOP_Crypto | decimal(16,2) | YES | Net Open Position for crypto positions only. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 20 | Notional_Crypto | decimal(16,2) | YES | Notional value for crypto positions only. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 21 | NOP_CFD | decimal(16,2) | YES | Net Open Position for CFD positions only. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 22 | Notional_CFD | decimal(16,2) | YES | Notional value for CFD positions only. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 23 | NOP_Crypto_CFD | decimal(16,2) | YES | Net Open Position for crypto CFD positions (crypto traded as CFD). (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 24 | Notional_Crypto_CFD | decimal(16,2) | YES | Notional value for crypto CFD positions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 25 | CommissionByUnits | decimal(38,6) | YES | Commission calculated per unit (share-based). (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 26 | FullCommissionByUnits | decimal(38,6) | YES | Full commission per unit including partial-close portions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 27 | NOP_Stock | decimal(16,2) | YES | Net Open Position for stock positions (real + CFD). (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 28 | Notional_Stock | decimal(16,2) | YES | Notional value for stock positions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 29 | NOP_Stock_CFD | decimal(16,2) | YES | Net Open Position for stock CFD positions only. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 30 | Notional_Stock_CFD | decimal(16,2) | YES | Notional value for stock CFD positions only. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 31 | PositionPnLStocksReal | decimal(16,2) | YES | Unrealized PnL from real (non-CFD) stock positions only. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 32 | PositionPnLCryptoReal | decimal(16,2) | YES | Unrealized PnL from real (non-CFD) crypto positions only. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 33 | FullCommissionByUnitsStocksReal | decimal(38,6) | YES | Full commission per unit for real stock positions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |
| 34 | FullCommissionByUnitsCryptoReal | decimal(38,6) | YES | Full commission per unit for real crypto positions. (Tier 2 — Fact_CustomerUnrealized_PnL passthrough) |

---

## 5. Lineage

### 5.1 Pipeline

```
[Full PnL computation pipeline] → Fact_CustomerUnrealized_PnL
                                      │
                                      └─ SELECT 34 columns WHERE DateModified = @dateid
                                          → Fact_CustomerUnrealized_PnL_UserAPI
```

All 34 columns are direct passthroughs from `Fact_CustomerUnrealized_PnL`. No transformations.

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer |
| DateModified | DWH_dbo.Dim_Date | Snapshot date |
| (all columns) | DWH_dbo.Fact_CustomerUnrealized_PnL | Parent table (1:1 subset) |

---

## 7. Sample Queries

### 7.1 Customer portfolio PnL breakdown

```sql
SELECT
    CID,
    DateModified,
    PositionPnL AS TotalPnL,
    CopyPositionPnL,
    MenualPositionPnL AS ManualPnL,
    StocksPositionPnL,
    CryptoPositionPnL,
    StandardDeviation AS PortfolioRisk
FROM DWH_dbo.Fact_CustomerUnrealized_PnL_UserAPI
WHERE CID = @cid
  AND DateModified >= 20260301
ORDER BY DateModified DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [DB Scripts](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13955596294/DB+Scripts) | Confluence | Explicitly lists **Fact_CustomerUnrealized_PnL_UserAPI** under DWH read access (with Fact_SnapshotEquity). |
| [PeriodicRankingService Documentation](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13951959407/PeriodicRankingService+Documentation) | Confluence | Cites DWH customer equity snapshots and unrealized PnL as inputs. |
| [Portfolio Value (formerly known as Equity on the platform)](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12039520520/Portfolio+Value+formerly+known+as+Equity+on+the+platform) | Confluence | Defines unrealized equity / open P&amp;L vs cash and invested amounts. |

---

*Generated: 2026-03-19 | Quality: 7.5/10 (★★★☆☆) | Phases: 5/14 (derivative table — inherits from parent)*
*Tiers: 0 T1, 33 T2, 0 T3, 0 T4 [UNVERIFIED], 1 T4 — Confluence, 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Fact_CustomerUnrealized_PnL_UserAPI | Type: Table | Production Source: Fact_CustomerUnrealized_PnL (subset)*
