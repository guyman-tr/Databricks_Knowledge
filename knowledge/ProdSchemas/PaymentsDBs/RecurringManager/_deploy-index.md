---

## bronze: RecurringManager

db_key: PaymentsDBs/RecurringManager
total_deployable: 7
generated: 7
failed: 0
deployed: 0
last_generated: "2026-04-30"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [Dictionary.Frequency](Wiki/Dictionary/Tables/Dictionary.Frequency.md) | `main.billing.bronze_recurringmanager_dictionary_frequency` | Generated |
| [Dictionary.PlanStatus](Wiki/Dictionary/Tables/Dictionary.PlanStatus.md) | `main.billing.bronze_recurringmanager_dictionary_planstatus` | Generated |
| [Recurring.Payment](Wiki/Recurring/Tables/Recurring.Payment.md) | `main.billing.bronze_recurringmanager_recurring_payment` | Generated |
| [Recurring.PaymentExecution](Wiki/Recurring/Tables/Recurring.PaymentExecution.md) | `main.billing.bronze_recurringmanager_recurring_paymentexecution` | Generated |
| [Recurring.PaymentExecutionDepositResult](Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md) | `main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult` | Generated |
| [Scheduler.Execution](Wiki/Scheduler/Tables/Scheduler.Execution.md) | `main.billing.bronze_recurringmanager_scheduler_execution` | Generated |
| [Scheduler.Plan](Wiki/Scheduler/Tables/Scheduler.Plan.md) | `main.billing.bronze_recurringmanager_scheduler_plan` | Generated |
