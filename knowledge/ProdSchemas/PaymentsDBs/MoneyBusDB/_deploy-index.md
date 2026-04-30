---

## bronze: MoneyBusDB

db_key: PaymentsDBs/MoneyBusDB
total_deployable: 2
generated: 2
failed: 0
deployed: 0
last_generated: "2026-04-30"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.AccountTypes](Wiki/Dictionary/Tables/Dictionary.AccountTypes.md) | `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | Generated |
| [MoneyBus.Transactions](Wiki/MoneyBus/Tables/MoneyBus.Transactions.md) | `main.billing.bronze_moneybusdb_moneybus_transactions` | Generated |
