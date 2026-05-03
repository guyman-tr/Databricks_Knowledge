# Cluster 45 brief — `EXW_Wallet.CryptoTypes`

_Size: 97, intra-cluster weight: 594.0_
_Schema mix: {'CopyFromLake': 3, 'CryptoTypes': 1, 'Dictionary': 1, 'EXW_Currency': 2, 'EXW_Dictionary': 4, 'EXW_ECPBank': 1, 'EXW_PaymentReconciliation': 1, 'EXW_SimplexMapping': 1, 'EXW_Wallet': 27, 'EXW_dbo': 29, 'Staking': 3, 'Wallet': 24}_
_Edge sources: {'wiki': 594}_

## Top members (ranked by intra-cluster weight)

- `EXW_Wallet.CryptoTypes` — w 86.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/CryptoTypes.md)
- `Wallet.CryptoTypes` — w 35.0 (no wiki)
- `EXW_Wallet.SentTransactions` — w 34.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/SentTransactions.md)
- `EXW_Wallet.CustomerWalletsView` — w 31.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/CustomerWalletsView.md)
- `EXW_Wallet.ReceivedTransactions` — w 30.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/ReceivedTransactions.md)
- `Wallet.Wallets` — w 27.0 (no wiki)
- `EXW_Wallet.EXW_Price` — w 26.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/EXW_Price.md)
- `EXW_Wallet.Redemptions` — w 25.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/Redemptions.md)
- `EXW_Wallet.Wallets` — w 24.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/Wallets.md)
- `EXW_dbo.EXW_WalletInventory` — w 24.0 [wiki](knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_WalletInventory.md)
- `Wallet.Redemptions` — w 23.0 (no wiki)
- `EXW_dbo.EXW_FactRedeemTransactions` — w 22.0 [wiki](knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_FactRedeemTransactions.md)
- `EXW_dbo.EXW_FactConversions` — w 21.0 [wiki](knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_FactConversions.md)
- `EXW_Wallet.ConversionTransactions` — w 20.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/ConversionTransactions.md)
- `EXW_Wallet.ETL_InstrumentRates_ByHour` — w 20.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/ETL_InstrumentRates_ByHour.md)
- `EXW_dbo.EXW_PaymentReconciliation` — w 20.0 [wiki](knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_PaymentReconciliation.md)
- `Wallet.Conversions` — w 20.0 (no wiki)
- `EXW_Wallet.AmlValidations` — w 19.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/AmlValidations.md)
- `EXW_Wallet.Payments` — w 19.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/Payments.md)
- `EXW_Wallet.Requests` — w 19.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/Requests.md)
- `EXW_Wallet.Conversions` — w 18.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/Conversions.md)
- `Wallet.ReceivedTransactions` — w 18.0 (no wiki)
- `Wallet.WalletPool` — w 18.0 (no wiki)
- `EXW_Wallet.PaymentTransactions` — w 17.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/PaymentTransactions.md)
- `EXW_Wallet.SentTransactionOutputs` — w 17.0 [wiki](knowledge/synapse/Wiki/EXW_Wallet/Tables/SentTransactionOutputs.md)

## Wiki §3.3 Common JOINs (top members)

### `EXW_Wallet.CryptoTypes`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.CryptoMarketRatesMappings | cmrm.CryptoId = ct.CryptoID | Map crypto to market rate symbols |
| EXW_Wallet.CustomerWalletsView | cw.CryptoId = ct.CryptoID | Resolve crypto metadata for customer wallets |
| EXW_Wallet.EXW_Price | ep.CryptoID = ct.CryptoID | Join price data to crypto type details |
| Self-join | ct.BlockchainCryptoId = parent.CryptoID | Resolve ERC-20 token to parent blockchain |

### `EXW_Wallet.SentTransactions`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.SentTransactionOutputs | SentTransactionId = Id | Get output details (amounts, addresses) |
| EXW_Wallet.SentTransactionStatuses | SentTransactionId = Id | Get status history |
| EXW_Wallet.Redemptions | SendRequestCorrelationId = CorrelationId | Link to redemption details |
| EXW_Wallet.Conversions | CorrelationId = CorrelationId | Link to conversion details |
| EXW_Dictionary.TransactionTypes | Id = TransactionTypeId | Resolve transaction type name |
| EXW_Wallet.CryptoTypes | CryptoID = CryptoId | Resolve cryptocurrency name |
| EXW_Wallet.CustomerWalletsView | Id = WalletId | Resolve wallet owner (GCID) |

### `EXW_Wallet.CustomerWalletsView`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.WalletBalances | ON WalletId (via Id) | Get current crypto balances per wallet |
| EXW_Wallet.BlockchainCryptos | ON BlockchainCryptoId = Id | Resolve blockchain name from BlockchainCryptoId |
| EXW_Wallet.CryptoTypes | ON CryptoId = CryptoID | Resolve crypto asset name, symbol, and details |
| EXW_Wallet.TransactionsView | ON Id = WalletId | Link wallet to its send/receive transactions |
| DWH_dbo.Dim_Customer | ON Gcid = GCID | Enrich with customer demographics |

### `EXW_Wallet.ReceivedTransactions`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Dictionary.ReceivedTransactionTypes | ReceivedTransactionTypeId = Id | Resolve transaction type name |
| EXW_Wallet.CryptoTypes | CryptoId = CryptoID | Resolve crypto asset name and metadata |
| EXW_Wallet.SentTransactions | BlockchainTransactionId = BlockchainTransactionId | Match sent-to-received for redeem reconciliation |
| EXW_Wallet.CustomerWalletsView | WalletId = Id | Resolve wallet owner (GCID) |
| EXW_Wallet.ReceivedTransactionStatuses | Id = ReceivedTransactionId | Get transaction status history |

### `EXW_Wallet.EXW_Price`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.EXW_PriceDaily | InstrumentID + FullDate | Daily aggregated prices (one row/day vs 24 rows/day) |
| EXW_Wallet.CryptoTypes | CryptoID = CryptoTypes.CryptoID | Resolve full crypto metadata |
| EXW_Wallet.CryptoMarketRatesMappings | CryptoID = CryptoMarketRatesMappings.CryptoId | Map to market rates currency symbol |

### `EXW_Wallet.Redemptions`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.CryptoTypes | CryptoTypes.CryptoID = Redemptions.CryptoId | Resolve cryptocurrency name and metadata |
| EXW_Wallet.Requests | Requests.CorrelationId = Redemptions.SendRequestCorrelationId | Get request statuses and timestamps |
| EXW_Wallet.SentTransactions | SentTransactions.CorrelationId = Redemptions.SendRequestCorrelationId | Get blockchain transaction details |
| EXW_dbo.EXW_FactRedeemTransactions | FactRedeemTransactions.RedeemID = Redemptions.Id | Access enriched fact table with sent/received data |

### `EXW_Wallet.Wallets`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.BlockchainCryptos | BlockchainCryptoId = BlockchainCryptos.Id | Resolve crypto name (BTC, ETH, etc.) |
| EXW_Dictionary.WalletTypes | WalletTypeId = WalletTypes.Id | Resolve wallet type name |
| EXW_Wallet.WalletPool | WalletId = WalletPool.WalletId | Get public address and provider info |
| EXW_Wallet.WalletAssets | WalletId = WalletAssets.WalletId | Get asset/crypto allocation details |

### `EXW_dbo.EXW_WalletInventory`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_dbo.EXW_DimUser | `ON EXW_WalletInventory.GCID = EXW_DimUser.GCID` | Enrich with user demographics |
| EXW_dbo.EXW_FactTransactions | `ON EXW_WalletInventory.WalletID = EXW_FactTransactions.WalletID` | Link wallets to their transactions |

### `EXW_dbo.EXW_FactRedeemTransactions`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_dbo.EXW_DimUser | RequestingGcid = GCID | User demographic enrichment |
| EXW_dbo.EXW_FactBalance | RequestingGcid = GCID, CryptoId = CryptoId | Balance at redemption time |

### `EXW_dbo.EXW_FactConversions`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_dbo.EXW_DimUser | `ON EXW_FactConversions.SendingGCID = EXW_DimUser.GCID` | Enrich with user demographics |
| EXW_dbo.EXW_FactTransactions | `ON EXW_FactConversions.ToEtoroSentTXID = EXW_FactTransactions.TranID` | Link swaps to transaction log |

### `EXW_Wallet.ConversionTransactions`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.Conversions | `Conversions.Id = ConversionTransactions.ConversionId` | Get parent conversion details (wallets, amounts, correlation) |
| EXW_Wallet.SentTransactions | Via Conversions.CorrelationId (indirect) | Link to blockchain send records |
| EXW_Wallet.EXW_TransactionsView | Embedded in view CTEs | Unified transaction ledger |

### `EXW_Wallet.ETL_InstrumentRates_ByHour`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Currency.Instruments | InstrumentID = Instruments.Id | Resolve instrument names and currency pairs |
| EXW_Wallet.EXW_Price | InstrumentID + DateHour = DateFrom | Compare hourly aggregates with final price table |

## KPI views in this cluster

## Genie spaces overlapping this cluster

## Out-cluster neighbors (likely bridge candidates)

- `EXW_dbo.EXW_DimUser` — outflow weight 26.0
- `EXW_dbo.EXW_DimUser_Enriched` — outflow weight 6.0
- `DWH_dbo.Dim_Customer` — outflow weight 5.0
- `BI_DB_dbo.BI_DB_W_Tue_Email_for_KYT` — outflow weight 2.0
- `EXW_dbo.EXW_WalletUsers_30_Days` — outflow weight 2.0
- `EXW_dbo.EXW_FinanceReportsBalancesNew` — outflow weight 2.0
- `DWH_dbo.Fact_SnapshotCustomer` — outflow weight 2.0
- `BI_DB_dbo.BI_DB_AML_High_Risk_Wallet` — outflow weight 1.0
- `EXW_dbo.EXW_WalletEntity` — outflow weight 1.0
- `EXW_Wallet.WalletBalances` — outflow weight 1.0
- `EXW_Wallet.TransactionsView` — outflow weight 1.0
- `EXW_dbo.SP_EXW_Fact_Transactions` — outflow weight 1.0
- `EXW_dbo.SP_EXW_Transactions_Monthly` — outflow weight 1.0
- `EXW_dbo.SP_EXW_FactRedeemTransactions` — outflow weight 1.0
- `EXW_dbo.SP_EXW_UserCalculatedBalance` — outflow weight 1.0
- `EXW_dbo.EXW_30DayBalanceExtract` — outflow weight 1.0
- `Customer.CustomerStatic` — outflow weight 1.0
- `CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances` — outflow weight 1.0
- `DWH_dbo.Dim_Instrument` — outflow weight 1.0
- `eMoney_dbo.SP_EXW_FactBalance_EXT` — outflow weight 1.0
