# Saga Schema - WalletDB

| Metric | Value |
|--------|-------|
| **Total Objects** | 34 |
| **Documented** | 34 (100%) |
| **Remaining** | 0 |
| **Last Updated** | 2026-04-15 |
| **Enrichment** | Complete |
| **Schema Overview** | [_schema_overview.md](_schema_overview.md) |
| **Sessions Used** | 3 (Batch 1: tables, Batch 2: SPs, Enrichment) |

## Tables (9)

| Object | Quality | Status |
|--------|---------|--------|
| [Saga.SagaStatusTypes](Tables/Saga.SagaStatusTypes.md) | 9.2 | Done (Batch 1) |
| [Saga.StepStatusTypes](Tables/Saga.StepStatusTypes.md) | 9.2 | Done (Batch 1) |
| [Saga.Subscriptions](Tables/Saga.Subscriptions.md) | 9.0 | Done (Batch 1) |
| [Saga.SagaRuns](Tables/Saga.SagaRuns.md) | 9.4 | Done (Batch 1) |
| [Saga.SagaEvents](Tables/Saga.SagaEvents.md) | 9.0 | Done (Batch 1) |
| [Saga.SagaLeaseTime](Tables/Saga.SagaLeaseTime.md) | 9.4 | Done (Batch 1) |
| [Saga.SagaRunStatuses](Tables/Saga.SagaRunStatuses.md) | 9.2 | Done (Batch 1) |
| [Saga.SagaSteps](Tables/Saga.SagaSteps.md) | 9.4 | Done (Batch 1) |
| [Saga.SagaStepStatuses](Tables/Saga.SagaStepStatuses.md) | 9.2 | Done (Batch 1) |

## Stored Procedures (25)

| Object | Quality | Status |
|--------|---------|--------|
| [Saga.AddSagaEvent](Stored Procedures/Saga.AddSagaEvent.md) | 9.0 | Done (Batch 2) |
| [Saga.AddSubscription](Stored Procedures/Saga.AddSubscription.md) | 9.0 | Done (Batch 2) |
| [Saga.DeleteSubscription](Stored Procedures/Saga.DeleteSubscription.md) | 9.0 | Done (Batch 2) |
| [Saga.GetAllAbandonedSagaRuns](Stored Procedures/Saga.GetAllAbandonedSagaRuns.md) | 9.2 | Done (Batch 2) |
| [Saga.GetAllSagaRunsWithLimitsByStatus](Stored Procedures/Saga.GetAllSagaRunsWithLimitsByStatus.md) | 9.0 | Done (Batch 2) |
| [Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold](Stored Procedures/Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold.md) | 9.0 | Done (Batch 2) |
| [Saga.GetAllSubscriptions](Stored Procedures/Saga.GetAllSubscriptions.md) | 9.0 | Done (Batch 2) |
| [Saga.GetSagaEvents](Stored Procedures/Saga.GetSagaEvents.md) | 9.0 | Done (Batch 2) |
| [Saga.GetSagaRun](Stored Procedures/Saga.GetSagaRun.md) | 9.0 | Done (Batch 2) |
| [Saga.GetSagaRunsByStatus](Stored Procedures/Saga.GetSagaRunsByStatus.md) | 9.0 | Done (Batch 2) |
| [Saga.GetSagaRunsByStatusAndName](Stored Procedures/Saga.GetSagaRunsByStatusAndName.md) | 9.2 | Done (Batch 2) |
| [Saga.GetSagaRunsByStatusAndThreshold](Stored Procedures/Saga.GetSagaRunsByStatusAndThreshold.md) | 9.0 | Done (Batch 2) |
| [Saga.GetSagaRunsForRecovery](Stored Procedures/Saga.GetSagaRunsForRecovery.md) | 9.2 | Done (Batch 2) |
| [Saga.GetSagaRunsWithLimitsByStatus](Stored Procedures/Saga.GetSagaRunsWithLimitsByStatus.md) | 9.0 | Done (Batch 2) |
| [Saga.GetSubscriptionsByTopics](Stored Procedures/Saga.GetSubscriptionsByTopics.md) | 9.0 | Done (Batch 2) |
| [Saga.InsertSagaRunStatus](Stored Procedures/Saga.InsertSagaRunStatus.md) | 9.4 | Done (Batch 2) |
| [Saga.InsertSagaRunWithLeaseTime](Stored Procedures/Saga.InsertSagaRunWithLeaseTime.md) | 9.4 | Done (Batch 2) |
| [Saga.InsertSagaStep](Stored Procedures/Saga.InsertSagaStep.md) | 9.2 | Done (Batch 2) |
| [Saga.InsertSagaStepStatus](Stored Procedures/Saga.InsertSagaStepStatus.md) | 9.2 | Done (Batch 2) |
| [Saga.ReinitiateSaga](Stored Procedures/Saga.ReinitiateSaga.md) | 9.4 | Done (Batch 2) |
| [Saga.TakeSagaRun](Stored Procedures/Saga.TakeSagaRun.md) | 9.2 | Done (Batch 2) |
| [Saga.TryTakeSubscription](Stored Procedures/Saga.TryTakeSubscription.md) | 9.2 | Done (Batch 2) |
| [Saga.UpdateSagaLeaseTime](Stored Procedures/Saga.UpdateSagaLeaseTime.md) | 9.2 | Done (Batch 2) |
| [Saga.UpdateSagaStepResponse](Stored Procedures/Saga.UpdateSagaStepResponse.md) | 9.0 | Done (Batch 2) |
| [Saga.UpdateSubscription](Stored Procedures/Saga.UpdateSubscription.md) | 9.0 | Done (Batch 2) |
