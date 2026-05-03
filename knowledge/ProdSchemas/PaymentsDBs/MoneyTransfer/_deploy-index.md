---

## bronze: MoneyTransfer

db_key: PaymentsDBs/MoneyTransfer
total_deployable: 2
generated: 0
failed: 1
deployed: 1
last_generated: "2026-04-30"
last_deploy_batch: 1
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Billing.PostTransferActions](Wiki/Billing/Tables/Billing.PostTransferActions.md) | `main.bi_db.bronze_moneytransfer_billing_posttransferactions` | Deployed (Batch 1) - 2026-05-03 |
| [Billing.Transfers](Wiki/Billing/Tables/Billing.Transfers.md) | `main.bi_db.bronze_moneytransfer_billing_transfers` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `EndTime` cannot be resolved. Di |
