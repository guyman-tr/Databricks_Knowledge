# Column Lineage: Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX` |
| **Status** | **DEPRECATED (HOLD)** — renamed to HOLD_Dealing_MarketMakerAllTradeEtoroX |
| **UC Target** | N/A — deprecated |
| **Primary Source** | Was: `MarketMaker.ExchangesData.Trades` (production) |
| **ETL SP** | Was: `SP_MarketMakerAllTrade` (eToroX section commented out since SR-239249, 2024-03-04) |
| **Generated** | 2026-03-21 |

## Notes

This table was deprecated in SR-239249 (2024-03-04). The DDL file has been renamed to `HOLD_Dealing_MarketMakerAllTradeEtoroX.sql`. The SP section that loaded it is fully commented out. No new data is being loaded.
