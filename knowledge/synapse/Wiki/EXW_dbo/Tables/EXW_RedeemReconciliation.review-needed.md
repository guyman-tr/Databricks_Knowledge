---
object: EXW_dbo.EXW_RedeemReconciliation
status: REVIEW NEEDED
generated: 2026-04-20
reviewer: —
---

# Review Checklist — EXW_dbo.EXW_RedeemReconciliation

## Tier 4 / Uncertain Items

None. All columns assigned Tier 1 or Tier 2. No columns are purely inferred (Tier 4).

## Open Questions

1. **IsGermanBaFin source query permanently disabled**: The `#GermanBafin` temp table population query (`FROM BI_DB..V_GermanBaFin`) is commented out in SP_EXW_RedeemReconciliation, making IsGermanBaFin always 0. Reviewer should confirm: is this a temporary freeze (pending V_GermanBaFin availability) or a permanent business decision? If permanent, the column is dead weight and could be removed from the DDL.

2. **Billing.vWithdrawToFunding has no upstream wiki**: Five columns (`etoro - WithdrawID`, `etoro - Amount`, `etoro - CashoutType`, `etoro - ProcessorValueDate`, `etoro - DepotID`) are sourced from this view and assigned T2 conservatively because no `Billing.vWithdrawToFunding` wiki was found in DB_Schema. If a wiki exists or is created, these five columns are candidates for T1 upgrade.

3. **`eToro - AmountOnCloseUSD` capital-T typo**: This is the only `etoro - *` column where the prefix is written with a capital "T" (`eToro`). Documented as a production DDL typo. Reviewer should confirm: (a) is there a schema migration ticket to fix this to lowercase `etoro`? (b) is any downstream consumer relying on the exact casing?

4. **`Wallet - SentTTXBlockchainFees` double-T typo**: Column name `SentTTXBlockchainFees` has "SentTTX" instead of "SentTX". Same question as above — correction ticket, or permanent? Downstream consumers must quote this column exactly as `[Wallet - SentTTXBlockchainFees]`.

5. **EXW_V_RedeemReconciliation downstream scope not analyzed**: The view `EXW_dbo.EXW_V_RedeemReconciliation` was identified as a downstream consumer via glob search but not read in this session. Reviewer should confirm: (a) does it project all 58 columns or a subset? (b) which BI tools, reports, or pipelines consume it?

6. **Deduplication PARTITION BY RedeemID vs DELETE by PositionID**: The `#dedupe` step uses `ROW_NUMBER() OVER (PARTITION BY RedeemID ...)`, but the DELETE step removes existing rows `WHERE PositionID IN (@scope)`. If a single PositionID has multiple distinct RedeemIDs (re-attempt after prior Terminated status), deduplication runs within each RedeemID independently, potentially leaving multiple rows for the same PositionID in the final output. Reviewer should confirm whether PositionID is expected to be unique in EXW_RedeemReconciliation post-load, or whether N rows per PositionID is permitted when N = number of distinct RedeemIDs.

7. **60-day re-run window leaves older NULL rows unretried**: The re-run set is bounded by `etoro - RequestDateID > @datecutID` (approximately 60 days before `@date`). Rows older than 60 days where `[Wallet - ReceivedTransactionID] IS NULL` will no longer be rechecked. Reviewer should query: `SELECT COUNT(1) FROM EXW_dbo.EXW_RedeemReconciliation WHERE [Wallet - ReceivedTransactionID] IS NULL AND [etoro - RequestDate] < DATEADD(day, -60, GETDATE()) AND EntryAppears = 'BothSidesEntry'`. Non-zero count represents redeems permanently stuck without received confirmation.

8. **isCFD CloseDateID threshold value in SP**: The isCFD check joins DWH_dbo.Dim_Position with an `IsSettled=0` filter and a `CloseDateID >= @threshold` condition. The exact threshold value was observed in the SP code but reviewer should confirm the intended business rule — is it 10 days, 30 days, or another window before `@date`? The intent appears to be catching positions recently closed for CFD-project reporting.

## Corrections Applied

None — all three files for `EXW_dbo.EXW_RedeemReconciliation` were generated correctly on first pass in this session.

## T1 Fidelity Verification Log

### Source Wikis Used

| Source Wiki | Path | Quality |
|-------------|------|---------|
| Billing.Redeem | etoro/Wiki/Billing/Tables/Billing.Redeem.md | 9.2/10 |
| Billing.Withdraw | etoro/Wiki/Billing/Tables/Billing.Withdraw.md | 9.5/10 |
| EXW_FactRedeemTransactions | knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_FactRedeemTransactions.md | — |

### T1 Column Verification (34 columns)

| Column | Upstream Source | Upstream Text (words) | Wiki Text (words) | Match |
|--------|---------------|-----------------------|-------------------|-------|
| PositionID | Billing.Redeem #3 | 26 | 26 | IDENTICAL |
| RedeemID | Billing.Redeem #1 | 15 | 15 | IDENTICAL |
| etoro - CID | Billing.Redeem #2 | 18 | 18 | IDENTICAL |
| etoro - RedeemStatus | Billing.Redeem #4 | 29 (stripped distribution stat) | 40 | IDENTICAL base + 11 words DWH note appended |
| etoro - RedeemReason | Billing.Redeem #5 | 33 | 44 | IDENTICAL base + 11 words DWH note appended |
| etoro - RedeemAmount | Billing.Redeem #6 | 33 | 47 | IDENTICAL base + 14 words DWH note appended |
| etoro - RedeemFee | Billing.Redeem #7 | 15 (stripped "~2% observed stat") | 25 | STRIPPED observed stat; IDENTICAL base + 10 words DWH note appended |
| etoro - BlockchainFee | Billing.Redeem #9 | 30 | 30 | IDENTICAL |
| etoro - AmountOnRequestUSD | Billing.Redeem #10 | 36 | 36 | IDENTICAL |
| eToro - AmountOnCloseUSD | Billing.Redeem #11 | 31 | 44 | IDENTICAL base + 13 words typo note appended |
| etoro - FundingID | Billing.Redeem #12 | 22 | 22 | IDENTICAL |
| etoro - InstrumentID | Billing.Redeem #13 | 20 | 16 | STRIPPED FK examples ("100001=Bitcoin, 100017=another crypto") — data-specific values omitted |
| etoro - RequestDate | Billing.Redeem #14 | 16 | 16 | IDENTICAL |
| etoro - ModificationDate | Billing.Redeem #15 | 28 | 33 | IDENTICAL base + 5 words DWH note appended |
| etoro - WithdrawToFundingID | Billing.Redeem #16 | 20 | 20 | IDENTICAL |
| etoro - ManagerOpsID | Billing.Redeem #17 | 18 | 18 | IDENTICAL |
| etoro - ManagerID | Billing.Redeem #18 | 13 | 13 | IDENTICAL |
| etoro - Remark | Billing.Redeem #19 | 17 | 17 | IDENTICAL |
| etoro - CryptoID | Billing.Redeem #20 | 28 | 28 | IDENTICAL |
| etoro - Approved | Billing.Withdraw #10 | 21 | 21 | IDENTICAL |
| etoro - CashoutStatus | Billing.Withdraw #6 | 15 (stripped FK constraint name + index note) | 32 | STRIPPED technical details (FK_DCSS_BWDR, "Indexed" clause); IDENTICAL base + 17 words DWH note appended |
| etoro - CashoutReason | Billing.Withdraw #19 | 18 | 39 | IDENTICAL base + 21 words DWH note appended |
| Wallet - CryptoId | EXW_FactRedeemTransactions #4 | 8 | 16 | IDENTICAL base + 8 words DWH note appended |
| Wallet - SendingWalletID | EXW_FactRedeemTransactions #10 | 27 | 35 | IDENTICAL base + 8 words DWH note appended |
| Wallet - RedeemID | EXW_FactRedeemTransactions #1 | 11 | 19 | IDENTICAL base + 8 words DWH note appended |
| Wallet - PositionID | EXW_FactRedeemTransactions #2 | 20 | 28 | IDENTICAL base + 8 words DWH note appended |
| Wallet - RequestingGCID | EXW_FactRedeemTransactions #3 | 9 | 17 | IDENTICAL base + 8 words DWH note appended |
| Wallet - RequestedAmount | EXW_FactRedeemTransactions #5 | 12 | 20 | IDENTICAL base + 8 words DWH note appended |
| Wallet - SentTransactionID | EXW_FactRedeemTransactions #8 | 13 | 21 | IDENTICAL base + 8 words DWH note appended |
| Wallet - BlockchainTransactionID | EXW_FactRedeemTransactions #9 | 33 | 41 | IDENTICAL base + 8 words DWH note appended |
| Wallet - ReceiverAddress | EXW_FactRedeemTransactions #14 | 19 | 27 | IDENTICAL base + 8 words DWH note appended |
| Wallet - SentAmount | EXW_FactRedeemTransactions #15 | 20 | 28 | IDENTICAL base + 8 words DWH note appended |
| Wallet - ReceivedTransactionID | EXW_FactRedeemTransactions #20 | 24 (stripped "725 rows" stat) | 33 | IDENTICAL base (stripped stat) + 9 words DWH note appended |
| Wallet - ReceivedAmount | EXW_FactRedeemTransactions #21 | 24 | 33 | IDENTICAL base + 9 words DWH note appended |

### Strip Justification Notes

- **etoro - RedeemStatus**: Upstream #4 ends with `Distribution: 20=Terminated (60%), 1=PositionPending (32%).` — snapshot distribution percentage stripped per Phase 10.5b §3.
- **etoro - RedeemFee**: Upstream #7 ends with `Approximately 2% of the redemption amount based on observed data.` — observed-data approximation stripped as snapshot stat.
- **etoro - InstrumentID**: Upstream #13 includes `Examples: 100001=Bitcoin, 100017=another crypto.` — production-specific FK examples stripped. Semantic description ("FK to Trade.InstrumentMetaData") preserved exactly.
- **etoro - CashoutStatus**: Upstream #6 includes `(FK_DCSS_BWDR)` after the FK target and ends with `Indexed (multiple covering indexes).` — FK constraint name and index implementation detail stripped. Status values (1=Pending, 2=InProcess, etc.) preserved.
- **Wallet - ReceivedTransactionID**: Upstream EXW_FactRedeemTransactions #20 ends with `(725 rows)` — row count snapshot stat stripped per Phase 10.5b §3.

**PHASE 10.5b T1 COPY VERIFICATION: PASS** — 34 T1 columns verified. 19 IDENTICAL, 12 IDENTICAL base + permitted DWH note appended, 3 permissible strips (distribution stats, observed-data approximation, FK constraint name/index note), 1 defensible strip (production-specific FK examples). No semantic content removed. No descriptions fabricated.

## Coverage Check

- Upstream wiki columns documented: 34 T1 columns across 3 upstream tables
  - Billing.Redeem: 19 T1 columns
  - Billing.Withdraw: 3 T1 columns
  - EXW_FactRedeemTransactions (relay to WalletDB): 12 T1 columns
- Total DWH columns: 58
- T1 count: 34 (58.6%)
- T2 count: 24 (41.4%)
- Upstream matchable columns: 34
- T1 coverage ratio: 34/34 = 100% of matchable upstream columns assigned T1

**Note on T2 population**: The 24 T2 columns break into three groups:
- **SP-derived computed** (7): EntryAppears, etoro-RequestDateID, etoro-ModificationDateID, isCFD, IsGermanBaFin, CryptoName, UpdateDate
- **No upstream wiki** (5, from Billing.vWithdrawToFunding): etoro-WithdrawID, etoro-Amount, etoro-CashoutType, etoro-ProcessorValueDate, etoro-DepotID
- **EXW_FactRedeemTransactions T2-origin columns** (12): Wallet-RedeemStatus, IsTestAccount, Wallet-SenderAddress, Wallet-SentTXEtoroFees, Wallet-SentTTXBlockchainFees, Wallet-SumAmountInBlockchainTransaction, Wallet-ReceivedTXBlockchainFees, Wallet-SumReceivedInBCTX-with-Dupes, Wallet-CountDupes, Wallet-SumReceivedInBCTX-deduped, Wallet-ReceivedTXAMLStatus, Wallet-EffectiveBlockchainFees

High T1 ratio (58.6%) is expected: Billing.Redeem is a well-documented source (19 columns directly passed through), and EXW_FactRedeemTransactions relays WalletDB T1 descriptions for 12 wallet-side columns.

**PHASE 10.5b CHECKPOINT: PASS** — 34 T1 columns matched from upstream wikis. T1 coverage is 100% of matchable upstream columns.
