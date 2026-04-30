# Saga Schema - WalletConversionDB

> Semantic documentation index for the Saga schema.
> Saga implements the distributed saga orchestration pattern for multi-step operations (e.g., crypto-to-fiat conversions).

| Metric | Value |
|--------|-------|
| **Total Objects** | 27 |
| **Documented** | 27 (100%) |
| **Pending** | 0 |
| **Last Updated** | 2026-04-15 |

---

## Tables (8)

| Object | Quality | Status |
|--------|---------|--------|
| [Saga.SagaStatusTypes](Tables/Saga.SagaStatusTypes.md) | 9.0 | Done (Batch 1) |
| [Saga.StepStatusTypes](Tables/Saga.StepStatusTypes.md) | 9.0 | Done (Batch 1) |
| [Saga.SagaEvents](Tables/Saga.SagaEvents.md) | 9.0 | Done (Batch 1) |
| [Saga.SagaLeaseTime](Tables/Saga.SagaLeaseTime.md) | 9.2 | Done (Batch 1) |
| [Saga.SagaRuns](Tables/Saga.SagaRuns.md) | 9.4 | Done (Batch 1) |
| [Saga.SagaRunStatuses](Tables/Saga.SagaRunStatuses.md) | 9.2 | Done (Batch 1) |
| [Saga.SagaSteps](Tables/Saga.SagaSteps.md) | 9.2 | Done (Batch 1) |
| [Saga.SagaStepStatuses](Tables/Saga.SagaStepStatuses.md) | 9.0 | Done (Batch 1) |

## Stored Procedures (19)

| Object | Quality | Status |
|--------|---------|--------|
| [Saga.AddSagaEvent](Stored Procedures/Saga.AddSagaEvent.md) | 9.0 | Done (Batch 1) |
| [Saga.GetSagaEvents](Stored Procedures/Saga.GetSagaEvents.md) | 9.0 | Done (Batch 1) |
| [Saga.PurgeTable](Stored Procedures/Saga.PurgeTable.md) | 9.0 | Done (Batch 1) |
| [Saga.TakeSagaRun](Stored Procedures/Saga.TakeSagaRun.md) | 9.2 | Done (Batch 1) |
| [Saga.UpdateSagaLeaseTime](Stored Procedures/Saga.UpdateSagaLeaseTime.md) | 9.2 | Done (Batch 1) |
| [Saga.GetSagaRun](Stored Procedures/Saga.GetSagaRun.md) | 9.0 | Done (Batch 1) |
| [Saga.GetSagaRunsByStatus](Stored Procedures/Saga.GetSagaRunsByStatus.md) | 9.0 | Done (Batch 1) |
| [Saga.GetSagaRunsByStatusAndName](Stored Procedures/Saga.GetSagaRunsByStatusAndName.md) | 9.0 | Done (Batch 1) |
| [Saga.GetSagaRunsForRecovery](Stored Procedures/Saga.GetSagaRunsForRecovery.md) | 9.0 | Done (Batch 1) |
| [Saga.GetSagaRunsWithLimitsByStatus](Stored Procedures/Saga.GetSagaRunsWithLimitsByStatus.md) | 9.0 | Done (Batch 1) |
| [Saga.InsertSagaRunStatus](Stored Procedures/Saga.InsertSagaRunStatus.md) | 9.2 | Done (Batch 1) |
| [Saga.UpdateSagaStepResponse](Stored Procedures/Saga.UpdateSagaStepResponse.md) | 9.0 | Done (Batch 1) |
| [Saga.GetAllAbandonedSagaRuns](Stored Procedures/Saga.GetAllAbandonedSagaRuns.md) | 9.0 | Done (Batch 1) |
| [Saga.GetAllSagaRunsWithLimitsByStatus](Stored Procedures/Saga.GetAllSagaRunsWithLimitsByStatus.md) | 9.0 | Done (Batch 1) |
| [Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold](Stored Procedures/Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold.md) | 9.0 | Done (Batch 1) |
| [Saga.GetSagaRunsByStatusAndThreshold](Stored Procedures/Saga.GetSagaRunsByStatusAndThreshold.md) | 9.0 | Done (Batch 1) |
| [Saga.InsertSagaRunWithLeaseTime](Stored Procedures/Saga.InsertSagaRunWithLeaseTime.md) | 9.4 | Done (Batch 1) |
| [Saga.InsertSagaStep](Stored Procedures/Saga.InsertSagaStep.md) | 9.4 | Done (Batch 2) |
| [Saga.InsertSagaStepStatus](Stored Procedures/Saga.InsertSagaStepStatus.md) | 9.4 | Done (Batch 2) |
