---

## bronze: MoneyTransfer

db_key: PaymentsDBs/MoneyTransfer
total_deployable: 2
generated: 2
failed: 0
deployed: 0
last_generated: "2026-04-30"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Billing.PostTransferActions](Wiki/Billing/Tables/Billing.PostTransferActions.md) | `main.bi_db.bronze_moneytransfer_billing_posttransferactions` | Generated |
| [Billing.Transfers](Wiki/Billing/Tables/Billing.Transfers.md) | `main.bi_db.bronze_moneytransfer_billing_transfers` | Generated |
