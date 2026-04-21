# EXW_FactTransactions — Review Needed

**Generated**: 2026-04-20 | **Batch**: 3 | **Object**: EXW_dbo.EXW_FactTransactions

---

## Tier 4 Items (Unverified / Needs Human Review)

None — all 45 columns have Tier 1 or Tier 2 coverage. No Tier 4 items.

---

## Open Questions for Reviewer

1. **IsEtoroFee always NULL**: The column exists in the DDL and the INSERT list uses `NULL AS [IsEtoroFee]`. The commented-out code shows `CASE WHEN TransactionTypeId in(0,8) THEN 1 ELSE 0 END AS [IsRedeem]` etc. — but the `IsEtoroFee` logic was never written (or was written and then removed). Confirm: Is IsEtoroFee intentionally deprecated (always NULL going forward), or is there a business requirement to implement this flag? If deprecated, should the column be dropped from the schema?

2. **GCID stored as int vs bigint in source**: The DDL declares `GCID [int] NULL` but `Wallet.TransactionsView.gcid` is `bigint`. SQL Server silently downcasts bigint→int during INSERT. Current max GCID in production is within int range (max ~284K distinct in this table), but if customer IDs ever approach 2,147,483,647 this would silently truncate. Confirm: Is this a known design decision (GCIDs will not exceed int range) or an oversight?

3. **AML join for sent transactions restricted to TransactionTypeId=1**: In SP_EXW_Fact_Transactions, the `#sent` temp table is filtered `WHERE TransactionTypeId = 1` (CustomerMoneyOut only). This means AML data is joined for CustomerMoneyOut sent transactions, but not for Redeem (0,8), Conversion (5,6), Payment (7), Staking (9), or other sent types. These other types will have NULL AMLProviderStatus even if AML records exist for them. Confirm: Is this intentional (only CustomerMoneyOut is AML-checked for the sent path), or is this a known gap in AML coverage for the other sent transaction types?

4. **EtoroFees currency basis**: The SP computes `EtoroFees = v.EtoroFees * CONVERT(FLOAT, v.FeeExchangeRate)`. For ConversionOut (type 6), FeeExchangeRate = source CryptoRateUsd / dest CryptoRateUsd. This means EtoroFees in this table is expressed in "destination crypto units" rather than native-crypto units or USD. Confirm: Is this the intended semantics (fee normalized to destination), and should EtoroFeesUSD (= EtoroFees × AvgPrice) then use the source or destination crypto's price? The SP uses the transaction's `CryptoId` (source crypto) for the price join, which may produce an incorrect USD fee for ConversionOut transactions.

5. **DateOccured typo preserved**: Column `DateOccured` (not `DateOccurred`) has a typo in the DDL. This has been preserved verbatim in the wiki. Confirm: Is there any plan to correct this in a future schema migration, or is it frozen due to downstream dependencies?

6. **ReceivedTransactionTypeID NULLs (~76% of received rows)**: Only 1,144,573 of the 2,496,494 received rows have a ReceivedTransactionTypeID. The remaining ~1.35M received rows have NULL. This could mean: (a) older received transactions were not in ReceivedTransactions table at the time of load; (b) some received transactions don't have a matching ReceivedTransactions entry; (c) the join condition (TranID=Id) doesn't match all received rows. Confirm: Is the high NULL rate expected for older transactions, or is there a data quality issue in the received-side enrichment?

---

## Cross-Object Consistency Check

✅ GCID description verbatim from Wallet.TransactionsView.md (Tier 1); DWH note added for rename and int type
✅ WalletID description verbatim from Wallet.TransactionsView.md (Tier 1); DWH note added for rename and nvarchar(max) type
✅ TransactionTypeID values confirmed against live data: 13 distinct types, consistent with External_WalletDB_Wallet_TransactionsView (StakeAndRewardsRefund=14 not observed in Fact table vs 1.4K in External — expected since it's a small volume type that may not hit the date window)
✅ TranStatus values confirmed against live data: 7 distinct values (Verified=99.7%, WavedError=0.24%) — consistent with External table distribution
✅ ActionTypeID distribution: Received 53% / Sent 47% — consistent with External table
✅ IsRedeem logic documented from SP CASE statements (lines 347-350)
✅ IsConversion/IsPayment/IsFunding logic documented from SP lines 351-359
✅ AML values (Amber/NA/Green/Red/Error) confirmed from live data
✅ ReceivedTransactionTypeID values (1=MoneyIn, 2=Redeem, 5=ConversionFromEtoro, 6=Payment) confirmed from live data

---

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 45 cols, HASH(GCID), HEAP; all nullable |
| P2 Sample | PASS | 4,709,301 rows; 284,567 distinct GCIDs; TranDate 2018-04-23 to 2026-04-19; UpdateDate today |
| P3 Distribution | PASS | ActionTypeID (Received=53%/Sent=47%), TranStatus (Verified 99.7%), TransactionTypeID (13 types), AML (69% NULL), IsRedeem (47.9%), ReceivedTransactionTypeID values |
| P4 Lookup | PASS | TransactionTypeID 13 values, TranStatusID 7 values, AMLProviderStatus 5 values, ReceivedTransactionTypeID 4 values confirmed from live data |
| P5 JOINs | PASS | GCID joins to EXW_WalletInventory, Dim_Customer; TranID+ActionTypeID joins to External table |
| P6 BizLogic | PASS | Classification flags, EtoroFees normalization, AML join pattern, USD pricing, received enrichment all documented |
| P7 Views | PASS | SP_EXW_Transactions_Monthly, SP_EXW_Hourly, SP_EXW_UserCalculatedBalance identified as consumers |
| P8 SP Scan | PASS | Writer: SP_EXW_Fact_Transactions (DELETE+INSERT by date) |
| P9 SP Logic | PASS | Full 9-stage temp table pipeline traced; all 45 column origins mapped |
| P9B ETL Orch | PASS | Daily DELETE+INSERT; UpdateDate = 2026-04-20 (SP ran today, actively refreshed) |
| P10 Atlassian | [-] | Skipped — no Atlassian MCP configured |
| P10A Upstream | PASS | Wallet.TransactionsView.md (CryptoDBs repo) read; 21 T1 columns documented verbatim |
| P10B Lineage | PASS | .lineage.md written (45 cols: 21 T1, 24 T2); UC Target: _Not_Migrated |
| P11 Generate | PASS | .md written (45/45 elements, 8 sections); .review-needed.md written |
