# Saga Schema Overview - WalletDB

> The Saga schema implements a distributed transaction (saga) pattern for orchestrating multi-step wallet operations that span multiple services, with built-in support for step-by-step execution, lease-based distributed locking, status tracking, and HA recovery.

*Completed: 2026-04-15 | Objects: 34 (9 tables, 25 stored procedures) | Sessions: 3 (Plan+Execute tables, Plan+Execute SPs, Enrichment)*

---

## Architecture

The Saga schema provides the persistence layer for a saga orchestrator framework. It coordinates complex wallet operations (crypto receives, travel rule messaging, staking) as sequences of steps that can be retried, rolled back, and recovered across service restarts.

### Core Design Patterns

1. **Saga Pattern**: Multi-step distributed transactions with compensating rollback actions
2. **Lease-Based Distributed Locking**: Prevents concurrent processing of the same saga across service pods
3. **Event Sourcing (partial)**: Status history tables provide an immutable audit trail of every state transition
4. **Pub/Sub Subscriptions**: Topic-based message routing with lease expiration for dynamic subscription management

---

## Entity Relationship Diagram

```
Saga.SagaStatusTypes (lookup)          Saga.StepStatusTypes (lookup)
  1=Start, 2=Rollback,                  1=Start, 2=Failed,
  3=Completed, 4=Failed,                3=Retry, 4=Done,
  5=ForceStop                            5=Schedule
       |                                      |
       v                                      v
Saga.SagaRuns ----1:N----> Saga.SagaSteps ----1:N----> Saga.SagaStepStatuses
  (102K rows)     |          (935K rows)                  (2.86M rows)
       |          |
       |          +--1:N----> Saga.SagaRunStatuses (208K rows)
       |
       +--1:1----> Saga.SagaLeaseTime (102K rows)
       |             (distributed locking)
       +--1:N----> Saga.SagaEvents (0 rows - optional event log)


Saga.Subscriptions (standalone - 0 rows)
  (topic-based pub/sub subscription management)
```

---

## Table Summary

| Table | Purpose | Rows | Key Relationship |
|-------|---------|------|-----------------|
| **SagaStatusTypes** | Lookup: saga lifecycle states (Start/Rollback/Completed/Failed/ForceStop) | 5 | Referenced by SagaRuns, SagaRunStatuses |
| **StepStatusTypes** | Lookup: step execution states (Start/Failed/Retry/Done/Schedule) | 5 | Referenced by SagaSteps, SagaStepStatuses |
| **SagaRuns** | Master record for each saga execution | 102K | Central entity - all other tables reference this |
| **SagaLeaseTime** | Distributed lease/lock per saga (1:1 with SagaRuns) | 102K | Enables HA recovery and prevents concurrent processing |
| **SagaRunStatuses** | Immutable history of saga state transitions | 208K | ~2 entries per saga (Start + terminal) |
| **SagaSteps** | Individual step execution records with request/response | 935K | ~9 steps per saga on average |
| **SagaStepStatuses** | Immutable history of step state transitions | 2.86M | ~3 entries per step (Schedule + Start + Done) |
| **SagaEvents** | Optional operational event log | 0 | Linked via SagaKey |
| **Subscriptions** | Topic-based message subscription management | 0 | Standalone - not linked to saga runs |

---

## Stored Procedure Categories

### Writers (saga creation)
| Procedure | What It Does |
|-----------|-------------|
| **InsertSagaRunWithLeaseTime** | Atomically creates saga run + initial status + lease in one transaction |
| **InsertSagaStep** | Creates a step record + initial step status with duplicate prevention |
| **AddSagaEvent** | Logs an operational event for a saga run |
| **AddSubscription** | Registers a new message subscription |

### Modifiers (state transitions)
| Procedure | What It Does |
|-----------|-------------|
| **InsertSagaRunStatus** | Transitions saga status via atomic UPDATE + OUTPUT INTO history |
| **InsertSagaStepStatus** | Transitions step status via atomic UPDATE + OUTPUT INTO history |
| **UpdateSagaStepResponse** | Updates a step's Response column after execution |
| **TakeSagaRun** | Claims an expired saga lease (distributed lock acquisition) |
| **UpdateSagaLeaseTime** | Renews saga lease with owner validation (heartbeat) |
| **ReinitiateSaga** | Creates a fresh saga run from a failed saga's data (manual retry) |
| **DeleteSubscription** | Soft-deletes a subscription (IsDeleted=1) |
| **UpdateSubscription** | Renews subscription lease (heartbeat) |
| **TryTakeSubscription** | Atomically claims an expired subscription |

### Readers (monitoring and recovery)
| Procedure | What It Does |
|-----------|-------------|
| **GetSagaRun** | Retrieves single saga with all steps by SagaKey |
| **GetSagaRunsByStatus** | All sagas by status (unbounded) |
| **GetSagaRunsByStatusAndName** | Non-terminal sagas by type with limit |
| **GetSagaRunsByStatusAndThreshold** | Slow sagas by type + age + active lease |
| **GetSagaRunsForRecovery** | Start/Rollback sagas by type (HA recovery) |
| **GetSagaRunsWithLimitsByStatus** | Sagas by status + type with limit |
| **GetAllAbandonedSagaRuns** | Sagas stuck in Start with expired leases (>1 hour) |
| **GetAllSagaRunsWithLimitsByStatus** | Active-lease sagas by status with limit |
| **GetAllSagaRunsWithLimitsByStatusAndThreshold** | Active-lease slow sagas with limit |
| **GetSagaEvents** | All events for a saga by SagaKey |
| **GetAllSubscriptions** | Active expired subscriptions |
| **GetSubscriptionsByTopics** | Subscriptions by topic + routing |

---

## Saga Types in Production

| SagaName | Volume | Purpose |
|----------|--------|---------|
| ExternalReceiveTransactionSaga | 91% (93K runs) | Crypto receive: travel rule + AML + balance credit (11 steps) |
| TravelRuleMessageReceiveSentSaga | 4% (4.1K) | Outbound travel rule messaging |
| TravelRuleMessageReceiveAckSaga | 3% (2.6K) | Travel rule acknowledgment handling |
| saga_staking | 2% (2.2K) | Crypto staking operations |

---

## Saga Lifecycle Flow

```
1. Application calls InsertSagaRunWithLeaseTime
   -> Creates: SagaRuns (status=Start) + SagaRunStatuses + SagaLeaseTime

2. For each step in the pipeline:
   a. InsertSagaStep (creates step record + initial status)
   b. [Step executes externally]
   c. UpdateSagaStepResponse (stores result)
   d. InsertSagaStepStatus (marks Done/Failed/Retry/Schedule)

3. Saga coordinator periodically calls UpdateSagaLeaseTime (heartbeat)

4. On success: InsertSagaRunStatus (status=Completed)
   On failure: InsertSagaRunStatus (status=Rollback, then Failed)

5. HA Recovery: GetSagaRunsForRecovery -> TakeSagaRun -> resume from last step
   Manual Retry: ReinitiateSaga -> creates fresh saga run from failed saga's data
```

---

## Key Metrics

- **96%** of sagas complete successfully (status=Completed)
- **4%** fail permanently (status=Failed, after rollback)
- **~1 minute** average saga duration (ExternalReceiveTransactionSaga)
- **5-minute** default lease duration (300,000ms)
- **1-hour** abandonment threshold for recovery scanning
- **Data span**: June 2021 to present (~5 years)

---

## Atlassian Knowledge Sources

| Source | Key Knowledge |
|--------|--------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Saga factory pattern with shared "lego block" steps. ExternalReceiveTransactionSaga (11 steps) and AutoC2PSagaFactory (17 steps). HA recovery via SQL-based lease management per saga type. |

---

## Glossary Terms Used

- [Saga Status Type](../_glossary.md#saga-status-type) - 5 saga lifecycle states
- [Step Status Type](../_glossary.md#step-status-type) - 5 step execution states
