---

## bronze: MoneyBusDB

db_key: PaymentsDBs/MoneyBusDB
total_deployable: 8
generated: 8
failed: 0
deployed: 0
last_generated: "2026-04-30"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.AccountTypes](Wiki/Dictionary/Tables/Dictionary.AccountTypes.md) | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | Generated |
| [Dictionary.TransactionStatusReasons](Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md) | `main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons` | Generated |
| [Dictionary.TransactionStatuses](Wiki/Dictionary/Tables/Dictionary.TransactionStatuses.md) | `main.billing.bronze_moneybusdb_dictionary_transactionstatuses` | Generated |
| [Dictionary.WithdrawCancellationSources](Wiki/Dictionary/Tables/Dictionary.WithdrawCancellationSources.md) | `main.billing.bronze_moneybusdb_dictionary_withdrawcancellationsources` | Generated |
| [Dictionary.WithdrawStatusReasons](Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md) | `main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons` | Generated |
| [Dictionary.WithdrawStatuses](Wiki/Dictionary/Tables/Dictionary.WithdrawStatuses.md) | `main.billing.bronze_moneybusdb_dictionary_withdrawstatuses` | Generated |
| [MoneyBus.Transactions](Wiki/MoneyBus/Tables/MoneyBus.Transactions.md) | `main.billing.bronze_moneybusdb_moneybus_transactions` | Generated |
| [MoneyBus.TransferLimits](Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md) | `main.billing.bronze_moneybusdb_moneybus_transferlimits` | Generated |
