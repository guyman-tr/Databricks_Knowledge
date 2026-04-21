# EXW_dbo.EXW_EthFeeSent_Blockchain — Column Lineage

**Object Type**: Table
**Schema**: EXW_dbo
**Generated**: 2026-04-20
**Pipeline Phase**: 10B

## Table Definition Summary

Date-parameterized ETL table linking ETH blockchain fee transactions from Etherscan (EXW_ETH_FeeData_Blockchain) to wallet users and transaction types. Writer: SP_EXW_EthFeeSent_Blockchain(@d date). Strategy: detect missing dates in target vs source, then DELETE+INSERT for those dates. HASH(GCID), HEAP.

GCIDUnion is a derived resolution: GCID>0 → use GCID directly; GCID=0 (omnibus sender) → resolve receiver via EXW_Wallet.CustomerWalletsView.Address. Country/Regulation enriched via date-range snapshot (Fact_SnapshotCustomer + Dim_Range).

338,404 rows (2021-01-01 to 2026-03-09, active).

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Confidence |
|---|--------|---------------|---------------|-----------|------------|
| 1 | txhash | EXW_dbo.EXW_ETH_FeeData_Blockchain | txhash | Direct passthrough | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 2 | date_time | EXW_dbo.EXW_ETH_FeeData_Blockchain | date_time | Direct passthrough (nvarchar string) | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 3 | Date | EXW_dbo.EXW_ETH_FeeData_Blockchain | date_time | CAST(date_time AS DATE) | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 4 | TranDate | EXW_dbo.EXW_FactTransactions | TranDate | Passthrough via #population JOIN on txhash=BlockchainTransactionId; NULL if tx not found | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 5 | TranDateID | EXW_dbo.EXW_FactTransactions | TranDateID | Passthrough via #population; NULL if tx not found | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 6 | txn_fee_eth | EXW_dbo.EXW_ETH_FeeData_Blockchain | txn_fee_eth | CAST(CAST(txn_fee_eth AS FLOAT) AS MONEY) — two-step cast to handle varchar source values | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 7 | historical_price_eth | EXW_dbo.EXW_ETH_FeeData_Blockchain | historical_price_eth | CAST AS MONEY | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 8 | GCID | EXW_dbo.EXW_FactTransactions | GCID | Direct passthrough; 0 for omnibus-sender transactions | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 9 | RealCID | EXW_dbo.EXW_DimUser | RealCID | JOIN EXW_DimUser ON GCID=GCIDUnion | Tier 1 — Customer.CustomerStatic |
| 10 | BlockchainFees | EXW_dbo.EXW_FactTransactions | BlockchainFees | Direct passthrough | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 11 | contract_address | EXW_dbo.EXW_ETH_FeeData_Blockchain | contract_address | Direct passthrough; non-NULL indicates wallet creation tx | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 12 | GCIDUnion | EXW_dbo.EXW_FactTransactions / EXW_Wallet.CustomerWalletsView | GCID / Gcid | CASE WHEN GCID>0 THEN GCID ELSE CustomerWalletsView.Gcid (via ReciverAddress=Address) | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 13 | CountryID | DWH_dbo.Dim_Country | CountryID | JOIN via Fact_SnapshotCustomer.CountryID + Dim_Range date-range snapshot on TranDateID | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 14 | Country | DWH_dbo.Dim_Country | Name | JOIN via Fact_SnapshotCustomer + Dim_Range; country at TranDate | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 15 | RegulationID | DWH_dbo.Dim_Regulation | DWHRegulationID | JOIN via Fact_SnapshotCustomer.RegulationID | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 16 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Fact_SnapshotCustomer + Dim_Range | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 17 | Activity | EXW_dbo.EXW_FactTransactions | TransactionTypeID + contract_address + method | CASE classification: 0→Coin Transfer, 1→User Send Out, 2→AML Money Back, 4→Funding, 5→Conversion In, 6→Conversion Out, 7→Payment, 9→Staking, contract_address IS NOT NULL OR method=Create Wallet→Wallet Creation, BlockchainTransactionId IS NULL→Not Exist on Wallet | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 18 | UpdateDate | (computed) | — | GETDATE() at SP run time | Tier 2 — SP_EXW_EthFeeSent_Blockchain |
| 19 | method | EXW_dbo.EXW_ETH_FeeData_Blockchain | method | Direct passthrough | Tier 2 — SP_EXW_EthFeeSent_Blockchain |

## Source Objects

| Source Object | Relationship | Notes |
|---------------|-------------|-------|
| EXW_dbo.EXW_ETH_FeeData_Blockchain | Primary source (FROM clause) | Etherscan-sourced blockchain fee records; provides txhash, date_time, txn_fee_eth, historical_price_eth, contract_address, method |
| EXW_dbo.EXW_FactTransactions | LEFT JOIN on txhash=BlockchainTransactionId | Wallet transaction enrichment; filter: ActionTypeID=1, BlockchainCryptoId=2, BlockchainFees>0 |
| EXW_Wallet.CustomerWalletsView | LEFT JOIN on ReciverAddress=Address | Omnibus resolution: receiver GCID when sender GCID=0 |
| EXW_dbo.EXW_DimUser | JOIN on GCIDUnion | RealCID lookup |
| DWH_dbo.Fact_SnapshotCustomer | LEFT JOIN on RealCID | Date-ranged customer snapshot for country/regulation at TranDate |
| DWH_dbo.Dim_Range | JOIN on DateRangeID with TranDateID BETWEEN FromDateID AND ToDateID | Date range resolution for snapshot |
| DWH_dbo.Dim_Country | JOIN on CountryID | Country name and ID |
| DWH_dbo.Dim_Regulation | JOIN on DWHRegulationID | Regulation name |

## UC Lineage

UC Target: `_Not_Migrated`
No UC entity exists for this table. Documentation is for knowledge purposes only.
