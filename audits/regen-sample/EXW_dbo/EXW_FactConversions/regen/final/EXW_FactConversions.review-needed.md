# Review Needed: EXW_dbo.EXW_FactConversions

## Open Questions

1. **No writer SP exists in SSDT repo.** How is this table populated? External Python script, ADF pipeline, or manual load? The single `UpdateDate` of 2024-04-09 suggests a one-time bulk load. Was this intentional or is there a missing ETL process?

2. **Feature appears dormant.** Last conversion `RequestTime` is 2023-06-14. Is the crypto-to-crypto conversion feature deprecated? If so, should this table be marked as archived?

3. **ConversionID vs ConversionID2.** These appear identical in all sampled rows. Is ConversionID2 a legacy column, or can it differ in edge cases (e.g., split conversions)?

4. **RequestedFromAmount vs FromAmount / RequestedToAmount vs ToAmount.** Based on data analysis, RequestedFromAmount maps to Wallet.Conversions.FromAmount (user's original request), while FromAmount maps to Wallet.ConversionTransactions.Amount for the From-leg (actual executed amount). The typical difference is ~0.00005 for FixedFrom conversions (micro-fee deduction). For the To-side, RequestedToAmount maps to Conversions.ToAmount and ToAmount maps to ConversionTransactions.Amount (To-leg), with differences up to ~1,259 units due to market price movement. **Confirm this source mapping interpretation.**

5. **Received-side columns (ToEtoroReceivedTXID, ToEtoroReceivedAmount, etc.).** These appear to come from `Wallet.ReceivedTransactions` which has no wiki in the bundle. The column descriptions are Tier 3 based on naming patterns. If a wiki for ReceivedTransactions becomes available, these should be upgraded to Tier 1.

6. **Sent-side transaction IDs (ToEtoroSentTXID, FromEtoroSentTXID).** These appear to come from `Wallet.SentTransactions` which also has no wiki. Same upgrade opportunity as #5.

7. **SendingGCID / RecievingGCID mapping.** The wallet-to-customer GCID mapping is not documented in any upstream wiki. Where is this mapping maintained? EXW_DimUser? Direct WalletDB lookup?

8. **Dropped ConversionTypeId.** The upstream Wallet.Conversions has ConversionTypeId (1=FixedFrom, 2=FixedTo) which determines whether the user fixed the sell or buy amount. This column was dropped during ETL. Was this intentional? Should it be added to the table for analytical clarity?

## Tier 3 Columns Requiring Upstream Wiki

The following 16 columns are Tier 3 because their production sources (SentTransactions, ReceivedTransactions, ConversionStatuses, customer mapping) lack upstream wikis in the bundle:

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
