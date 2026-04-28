# Compare — `Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX`

**Bucket**: `dormant`

**Verdict**: **BETTER**  (score delta +3.85; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 4.5 | 8.35 | 3.85 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 0 | 21 | +21 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 0 | 10 | +10 |
| T3 count | 0 | 11 | +11 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 7 | 9 |
| completeness | 4 | 8 |
| data_evidence | 2 | 7 |
| shape_fidelity | 3 | 8 |
| tier_accuracy | 3 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `1` | 0.0 | None | 2 |  | The reporting date for the trade batch. Set from the SP @Date input parameter. Used as the clustered index key and DELETE+INSERT partition key for daily loads. (Tier 2 — SP_MarketMakerAllTrade) |
| `2` | 0.0 | None | 3 |  | Trade record identifier from the source exchange system (`MarketMaker_ExchangesData_Trades.Id`). Not guaranteed unique across dates. Sample values: 82991130, 79021348. (Tier 3 — CopyFromLake.MarketMak |
| `3` | 0.0 | None | 3 |  | Timestamp when the trade was created on the exchange platform. Passthrough from `MarketMaker_ExchangesData_Trades.CreationTime`. Millisecond precision. (Tier 3 — CopyFromLake.MarketMaker_ExchangesData |
| `4` | 0.0 | None | 3 |  | Crypto instrument trading pair name (e.g., 'BTC-USD', 'ETH-USD', 'LUNA-USD'). Resolved via JOIN to `Dealing_staging.External_MarketMaker_dbo_Instruments` on InstrumentId. Top instruments: LUNA-USD, BT |
| `5` | 0.0 | None | 3 |  | Exchange or aggregation source name. Two values: 'Aggregated' (~65%) and 'eToroX' (~35%). Resolved via JOIN to `Dealing_staging.External_MarketMaker_dbo_Exchanges` on ExchangeId. (Tier 3 — External_Ma |
| `6` | 0.0 | None | 2 |  | Trade direction. ETL-transformed from numeric code: 0='Buy', 1='Sell'. Distribution: ~56% Sell, ~44% Buy. (Tier 2 — SP_MarketMakerAllTrade) |
| `7` | 0.0 | None | 2 |  | Execution price of the trade in the instrument's quote currency (USD). SP converts -1 sentinel to '0' indicating no price available. (Tier 2 — SP_MarketMakerAllTrade) |
| `8` | 0.0 | None | 2 |  | Number of units traded. SP converts -1 sentinel to '0' indicating no quantity available. (Tier 2 — SP_MarketMakerAllTrade) |
| `9` | 0.0 | None | 2 |  | Gross trade value. ETL-computed as Price × Quantity. Represents the total notional value of the trade before fees. (Tier 2 — SP_MarketMakerAllTrade) |
| `10` | 0.0 | None | 3 |  | API-submitted price from the exchange. Passthrough from source. Value is -1 when no API price was provided. In the HOLD data, most rows show -1.0, indicating the exchange did not return a distinct API |

## Top issues — regen wiki (per judge)

- [medium] `Section 4 (all columns)` — No DDL available in SSDT to verify the wiki's 21 element count against the actual table definition. Column inventory is unverifiable.
- [medium] `Structure` — No explicit Phase Gate Checklist section with [x]/[ ] markers. Footer says 'Phases: 11/14' but does not identify which phases were completed or skipped.
- [low] `ApiFunds (column 12)` — Description notes ApiPrice × ApiQuantity = 1.0 when both are -1 but does not flag this as a data quality artifact that should be filtered in analysis.
- [low] `Value (column 20)` — The ApiPrice fallback when Price = -1 is buried in a parenthetical in the element description. This critical branching condition deserves more prominent treatment.
- [low] `Instrument_Name, Name, Side, FeeCurrency, PartyName, OrderId, TradeId` — char(50)/char(70) fixed-width padding not mentioned in individual element descriptions. Only the Gotchas section warns about RTRIM(). Analysts reading Elements in isolation would not know to trim.
