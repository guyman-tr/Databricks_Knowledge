---

## bronze: RecurringManager

db_key: PaymentsDBs/RecurringManager
total_deployable: 7
generated: 0
failed: 3
deployed: 4
last_generated: "2026-04-30"
last_deploy_batch: 1
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.Frequency](Wiki/Dictionary/Tables/Dictionary.Frequency.md) | `main.billing.bronze_recurringmanager_dictionary_frequency` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PlanStatus](Wiki/Dictionary/Tables/Dictionary.PlanStatus.md) | `main.billing.bronze_recurringmanager_dictionary_planstatus` | Deployed (Batch 1) - 2026-05-03 |
| [Recurring.Payment](Wiki/Recurring/Tables/Recurring.Payment.md) | `main.billing.bronze_recurringmanager_recurring_payment` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `SysEndTime` cannot be resolved. |
| [Recurring.PaymentExecution](Wiki/Recurring/Tables/Recurring.PaymentExecution.md) | `main.billing.bronze_recurringmanager_recurring_paymentexecution` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `SysEndTime` cannot be resolved. |
| [Recurring.PaymentExecutionDepositResult](Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md) | `main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `SysEndTime` cannot be resolved. |
| [Scheduler.Execution](Wiki/Scheduler/Tables/Scheduler.Execution.md) | `main.billing.bronze_recurringmanager_scheduler_execution` | Deployed (Batch 1) - 2026-05-03 |
| [Scheduler.Plan](Wiki/Scheduler/Tables/Scheduler.Plan.md) | `main.billing.bronze_recurringmanager_scheduler_plan` | Deployed (Batch 1) - 2026-05-03 |
