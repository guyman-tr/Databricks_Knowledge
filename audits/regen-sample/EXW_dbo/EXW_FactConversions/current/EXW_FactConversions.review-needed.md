# EXW_FactConversions — Review Needed

**Generated**: 2026-04-20 | **Batch**: 3 | **Object**: EXW_dbo.EXW_FactConversions

---

## Tier 4 Items (Unverified / Needs Human Review)

| # | Column | Reason |
|---|--------|--------|
| 1 | ConversionID2 | Exact duplicate of ConversionID in all 50,298 rows. No distinct value, no added meaning. Source column is also `Wallet.Conversions.Id`. Tier 4 assigned — reviewer should confirm whether this was a copy-paste error in the original load query or intentionally reserved for a second join key that was never implemented. Safe to ignore in all analytical queries. |

---

## Open Questions for Reviewer

1. **No SP writer found — ad-hoc load or deliberate migration?** No stored procedure writing to this table was found in the SSDT repository. All rows share `UpdateDate = 2024-04-09`. This is consistent with a one-time ad-hoc `INSERT INTO ... SELECT ... FROM WalletDB...` executed manually. Confirm: Is there a migration script, ADO pipeline, or Jira ticket that documents this load? If not, there is no automated refresh mechanism, and the table is a permanent historical snapshot.

2. **ToEtoroEstimatedBCFee NULL for all 50,298 rows**: Column 13 (`ToEtoroEstimatedBCFee`) is present in the DDL and sourced from `Wallet.ConversionTransactions.EstimatedBlockChainFee` (TO-leg), but is NULL in every row. The FROM-leg equivalent (`FromEtoroEstimatedBCFee`) is populated for 97% of rows. Was `ToEtoroEstimatedBCFee` intentionally excluded from the historical load (e.g., the TO-leg EstimatedBlockChainFee was not available at load time), or is it a bug in the original load query that joined the wrong transaction leg?

3. **Conversion feature deprecation — confirmed or migrated?**: The last `RequestTime` in the table is 2023-06-14. The Wiki note and upstream source comment both suggest the crypto-to-crypto conversion feature was "deprecated or replaced after June 2023." Confirm: Was the conversion feature sunset entirely, or was it migrated to a different system (e.g., a new WalletDB table, an external provider, or a new DWH table)? If migrated, identify the successor table for continuity of historical analysis across the deprecation boundary.

4. **RecievingGCID spelling — intentional or typo?**: Column 18 is named `RecievingGCID` (misspelled — "Recieving" instead of "Receiving"). The misspelling appears in the SSDT DDL and is therefore the canonical column name. This is noted here for reviewer awareness. If correcting this spelling in a future DDL revision, all consumer queries (including `BI_DB_dbo.SP_US_Daily_Crypto`) must be updated.

5. **ToEtoroSentTXID NULL for 542 rows (1%)**: Column 25 (`ToEtoroSentTXID`) is NULL for 542 conversions. These represent conversions where no TO-leg sent transaction record was located in `EXW_Wallet.SentTransactions`. Confirm: Are these exclusively `ConversionStatus=2` (Failed) rows where the TO-leg was never executed, or do some NULL-TXID rows have `ConversionStatus=3` (Completed)? If Completed rows have NULL TXIDs, it may indicate a data quality issue in the join to SentTransactions.

6. **SendingGCID = RecievingGCID in all rows — design intent confirmed?**: Both GCIDs are always equal, meaning the conversion is an intra-user swap. Confirm: Does the system ever allow cross-user conversions (e.g., B2B wallet transfers using the conversion mechanism), or is the data design strictly intra-user by business rule? If cross-user conversions are possible in the source (WalletDB), they are absent here, which may indicate the historical load filtered them out.

---

## Cross-Object Consistency Check

✅ `SendingGCID` description: "Global Customer ID of the wallet holder initiating the swap. HASH distribution key for this table. Joins to EXW_DimUser.GCID." — consistent with GCID definition in EXW_DimUser.md and EXW_FactBalance.md.
✅ `RecievingGCID`: Documented as always equal to `SendingGCID` (intra-user swap) — consistent with the single-user wallet architecture documented in EXW_DimUser.md.
✅ Tier 1 assignments for passthrough columns (ConversionID, CorrelationID, RequestTime, FromWalletId, etc.) verified against Wallet.Conversions.md upstream wiki — column names and descriptions confirmed to match source.
✅ `ConversionStatus` values (1=Pending, 2=Failed, 3=Completed) confirmed against `Dictionary.ConversionStatuses.md` (upstream wiki read in Phase 10A).
✅ No other EXW_dbo object documents WalletDB.Wallet.Conversions — no cross-description parity conflict exists.

---

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 46 cols, HASH(SendingGCID), HEAP; confirmed from SSDT |
| P2 Sample | PASS | 50,298 rows total; UpdateDate uniform 2024-04-09; data range 2018-10-28 to 2023-06-14; 19,722 distinct GCIDs |
| P3 Distribution | PASS | ConversionStatus (97% Completed), FromCryptoID top values (ETH 34%, BTC 15%, XRP 15%), ToCryptoID top values (BTC 36%, ETH 17%) verified |
| P4 Lookup | PASS | Dictionary.ConversionStatuses read; CryptoTypes names confirmed |
| P5 JOINs | PASS | Consumer join pattern confirmed: BI_DB_dbo.SP_US_Daily_Crypto JOIN on ToEtoroSentTXID=EXW_FactTransactions.TranID WHERE ActionTypeID=1 AND IsConversion=1 |
| P6 BizLogic | PASS | Dual-leg architecture, status lifecycle, blockchain TX tracking, redundant columns (ConversionID2, RecievingGCID=SendingGCID) all documented |
| P7 Views | PASS | No views in EXW_dbo reference EXW_FactConversions |
| P8 SP Scan | PASS | No writer SP exists; BI_DB_dbo.SP_US_Daily_Crypto confirmed as only consumer |
| P9 SP Logic | PASS | Historical one-time load confirmed; source-to-target map built from upstream wiki + live data alignment |
| P9B ETL Orch | PASS | No active refresh; static historical snapshot since 2024-04-09 |
| P10 Atlassian | [-] | Skipped — no Atlassian MCP configured |
| P10A Upstream | PASS | WalletDB.Wallet.Conversions.md and Wallet.ConversionTransactions.md read; C2F.Conversions.md ruled out (different product — crypto-to-fiat) |
| P10B Lineage | PASS | .lineage.md written (46 cols: 14 T1, 31 T2, 1 T4); UC Target: _Not_Migrated |
| P11 Generate | PASS | .md written (46/46 elements, 8 sections); .review-needed.md written |
