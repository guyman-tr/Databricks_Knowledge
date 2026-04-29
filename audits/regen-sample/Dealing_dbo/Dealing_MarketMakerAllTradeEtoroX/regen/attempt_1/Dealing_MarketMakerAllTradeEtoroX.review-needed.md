# Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX — Review Needed

## Status: Dormant / Archived

The active table `Dealing_MarketMakerAllTradeEtoroX` was dropped on 2024-03-04 (SR-239249). Only the `HOLD_` archive remains with ~5M historical rows (2022-05 to 2024-02).

---

## Items Requiring Human Review

### 1. Confirm dormant status and retention policy

- **Issue**: The table was removed from active ETL on 2024-03-04. The HOLD archive retains ~5M rows. Confirm whether the HOLD table should be retained for historical analysis or can be purged.
- **Action**: Check with the Dealing team (Adva, Gili) whether there are downstream consumers of this archived data.

### 2. No upstream wiki available — all descriptions are Tier 2/3

- **Issue**: No production wiki exists for `MarketMaker_ExchangesData_Trades` or the staging lookup tables. All column descriptions are grounded in SP code analysis and live data observation, not upstream documentation.
- **Action**: If the MarketMaker team documents their exchange data model, column descriptions could be upgraded to Tier 1.

### 3. TradeId format inconsistency

- **Issue**: TradeId has two distinct formats: GUID format (e.g., `0093bb25-97e7-4763-b63b-b5da002baf38`) for eToroX-sourced records and timestamp-based format (e.g., `231018-122908`) for Aggregated-sourced records. This may indicate different data sources were merged.
- **Action**: Verify whether the format difference reflects distinct exchange APIs or a data pipeline change over time.

### 4. FeeCurrency inconsistent casing

- **Issue**: FeeCurrency values show mixed casing: 'USD' vs 'usd', 'MANA' vs 'mana'. This suggests the source system does not normalize currency codes.
- **Action**: If any downstream logic depends on FeeCurrency values, case-insensitive comparison should be used.

### 5. Value computation edge cases

- **Issue**: The Value formula has complex branching on FeeCurrency. When Price = -1 (sentinel), ApiPrice is substituted. Combined with the Fee subtraction logic, edge cases may produce unexpected results (e.g., ApiPrice = -1 AND Price = -1).
- **Action**: Validate Value computation correctness for the ~6.5K rows where FeeCurrency is non-blank.

### 6. Relationship to Dealing_MarketMakerAllTrade

- **Issue**: The main table `Dealing_MarketMakerAllTrade` (non-EtoroX) is still active and loaded by the same SP. The EtoroX variant was the exchange-specific subset. Confirm whether the main table now captures all trades including former eToroX trades, or if eToroX trading was discontinued entirely.
- **Action**: Check with Market Maker team for context on the eToroX decommissioning.

---

*Generated: 2026-04-27*
