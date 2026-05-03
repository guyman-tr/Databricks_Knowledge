---

## bronze: MoneyBusDB

db_key: PaymentsDBs/MoneyBusDB
total_deployable: 8
generated: 0
failed: 0
deployed: 8
last_generated: "2026-04-30"
last_deploy_batch: 1
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.AccountTypes](Wiki/Dictionary/Tables/Dictionary.AccountTypes.md) | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TransactionStatusReasons](Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md) | `main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.TransactionStatuses](Wiki/Dictionary/Tables/Dictionary.TransactionStatuses.md) | `main.billing.bronze_moneybusdb_dictionary_transactionstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.WithdrawCancellationSources](Wiki/Dictionary/Tables/Dictionary.WithdrawCancellationSources.md) | `main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.WithdrawStatusReasons](Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md) | `main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.WithdrawStatuses](Wiki/Dictionary/Tables/Dictionary.WithdrawStatuses.md) | `main.billing.bronze_moneybusdb_dictionary_withdrawstatuses` | Deployed (Batch 1) - 2026-05-03 |
| [MoneyBus.Transactions](Wiki/MoneyBus/Tables/MoneyBus.Transactions.md) | `main.billing.bronze_moneybusdb_moneybus_transactions` | Deployed (Batch 1) - 2026-05-03 |
| [MoneyBus.TransferLimits](Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md) | `main.billing.bronze_moneybusdb_moneybus_transferlimits` | Deployed (Batch 1) - 2026-05-03 |
