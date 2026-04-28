# Review Needed: EXW_dbo.EXW_FactConversions

## Open Questions

1. **No writer SP exists in SSDT repo.** How is this table populated? External Python script, ADF pipeline, or manual load? The single `UpdateDate` of 2024-04-09 suggests a one-time bulk load. Was this intentional or is there a missing ETL process?

2. **Feature appears dormant.** Last conversion `RequestTime` is 2023-06-14. Is the crypto-to-crypto conversion feature deprecated? If so, should this table be marked as archived?

3. **ConversionID vs ConversionID2.** These appear identical in all sampled rows. Is ConversionID2 a legacy column, or can it differ in edge cases (e.g., split conversions)?

4. **RequestedFromAmount vs FromAmount / RequestedToAmount vs ToAmount.** The "Requested" amounts appear to be the user's original input, while the non-"Requested" amounts are actuals after micro-fee deduction. Confirm this interpretation. Are both sourced from Wallet.Conversions.FromAmount/ToAmount or from different fields?

5. **Received-side columns (ToEtoroReceivedTXID, ToEtoroReceivedAmount, etc.).** These appear to come from `Wallet.ReceivedTransactions` which has no wiki in the bundle. The column descriptions are Tier 3 based on naming patterns. If a wiki for ReceivedTransactions becomes available, these should be upgraded to Tier 1.

6. **Sent-side transaction IDs (ToEtoroSentTXID, FromEtoroSentTXID).** These appear to come from `Wallet.SentTransactions` which also has no wiki. Same upgrade opportunity as #5.

7. **SendingGCID / RecievingGCID mapping.** The wallet-to-customer GCID mapping is not documented in any upstream wiki. Where is this mapping maintained? EXW_DimUser? Direct WalletDB lookup?

## Tier 3 Columns Requiring Upstream Wiki

The following 18 columns are Tier 3 because their production sources (SentTransactions, ReceivedTransactions, ConversionStatuses, customer mapping) lack upstream wikis in the bundle:

- SendingGCID, RecievingGCID — customer mapping
- ConversionStatus — from Wallet.ConversionStatuses
- ModificationTime — lifecycle timestamp
- ToEtoroSentTXID, ToEtoroSentBlockchainTXID — Wallet.SentTransactions
- FromEtoroSentTXID, FromEtoroSentBlockchainTXID — Wallet.SentTransactions
- ToEtoroReceivedTXID, ToEtoroReceivedAmount, ToEtoroReceiveBlockchainFee — Wallet.ReceivedTransactions
- FromEtoroReceivedTXID, FromEtoroReceivedAmount, FromEtoroReceiveBlockchainFee — Wallet.ReceivedTransactions
- ReceivedTime — completion timestamp
- UpdateDate — ETL metadata

## Spelling Note

- Column `RecievingGCID` is misspelled ("ie" instead of "ei"). This matches the DDL and cannot be changed without an ALTER.
