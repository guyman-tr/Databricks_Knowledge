# EXW_FactTransactions — Review Needed

## 1. Columns Needing Human Review

### IsEtoroFee — Hardcoded NULL
- Column is hardcoded to NULL in SP_EXW_Fact_Transactions (line 261: `NULL AS [IsEtoroFee]`)
- The upstream view's CryptoTypes table has an IsEtoroHandlingFee field (used for a different column)
- **Question**: Was this column intended to carry the CryptoTypes.IsEtoroFee value? Or is it a deprecated column that should be removed from the DDL?

### ReceivedTransactionTypeID / ReceivedTransactionType — Partial Population
- These columns are NULL for all sent transactions (ActionTypeID=1) by design
- For received transactions, ReceivedTransactionTypeID comes from EXW_Wallet.ReceivedTransactions, NOT from Wallet.TransactionsView
- The lookup table is CopyFromLake.WalletDB_Dictionary_ReceivedTransactionTypes (a lake copy, not a direct external table)
- **Question**: Is the CopyFromLake table refreshed on the same cadence as the fact table? Stale dictionary data could cause NULL ReceivedTransactionType for valid IDs.

### AML Enrichment — Sent Path Limited to TransactionTypeId=1
- The SP only joins AML data for sent transactions where `TransactionTypeId = 1` (CustomerMoneyOut) in the SentTransactions lookup (#sent temp table, line 100)
- Other sent types (Redeem=0/8, Conversion=5/6, Payment=7) do NOT get AML enrichment on the sent side
- **Question**: Is this intentional? Redeems and conversions may also have AML validations that are being missed.

## 2. Data Quality Observations

- **TranDateTime vs TranDate**: TranDateTime is populated as `v.TransDate` (line 200), making it identical to TranDate but stored as datetime. The comment says "inessa" added it — may be redundant with TranDate.
- **EtoroFees pre-conversion**: The SP multiplies EtoroFees by FeeExchangeRate before storing (line 139). Downstream consumers may not realize the fee is already converted. Consider adding a raw fee column or documenting this prominently.
- **No UC target**: EXW_FactTransactions has no entry in the generic pipeline mapping. If migration to Unity Catalog is planned, a mapping needs to be created.

## 3. Upstream Wiki Coverage

- **Wallet.TransactionsView wiki** (WalletDB): 22 columns documented, 20 matched to this table as Tier 1 passthroughs or renamed passthroughs
- **Dim_Customer wiki** (DWH_dbo): RealCID inherited as Tier 1 from Customer.CustomerStatic
- **EXW_Wallet.CryptoTypes**: No upstream wiki available — columns sourced from here are Tier 2
- **EXW_Wallet.AmlValidations**: No upstream wiki available — columns sourced from here are Tier 2

## 4. Tier Distribution

| Tier | Count | Percentage |
|------|-------|------------|
| Tier 1 | 22 | 48.9% |
| Tier 2 | 23 | 51.1% |
| Tier 3 | 0 | 0% |
| Tier 4 | 0 | 0% |
| **Total** | **45** | **100%** |

---

*Generated: 2026-04-27 | Object: EXW_dbo.EXW_FactTransactions*
