# Schema Overview: Saga - WalletConversionDB

> The Saga schema implements the distributed saga orchestration pattern for coordinating multi-step crypto-to-fiat conversion operations with automatic rollback, distributed locking, and full audit trail capabilities.

## Purpose

The Saga schema provides the infrastructure for orchestrating complex, multi-step distributed transactions in the WalletConversionDB. Currently, the only saga type is **CryptoToFiatSaga**, which coordinates the conversion of cryptocurrency holdings into fiat currency through an 11-step pipeline. The schema handles:

- **Orchestration**: Tracking saga runs, their steps, and progression through the pipeline
- **Distributed locking**: Ensuring each saga is processed by exactly one worker instance at a time
- **Fault tolerance**: Automatic recovery of abandoned sagas and rollback of failed operations
- **Audit trail**: Complete status history at both saga and step levels, plus event logging

## Architecture

```
                    +------------------+
                    | SagaStatusTypes  |     Lookup: 5 saga lifecycle states
                    | StepStatusTypes  |     Lookup: 5 step lifecycle states
                    +--------+---------+
                             |
                    +--------v---------+
                    |    SagaRuns      |     Central entity: one row per saga execution
                    |  (17K rows)      |     SagaKey (GUID), SagaName, Status, AdditionalData (JSON)
                    +--+-----+-----+--+
                       |     |     |
          +------------+     |     +------------+
          |                  |                  |
+---------v------+  +--------v-------+  +-------v--------+
| SagaRunStatuses|  |   SagaSteps    |  | SagaLeaseTime  |
| (35K rows)     |  |  (181K rows)   |  | (17K rows)     |
| Status history |  | Pipeline steps |  | Distributed    |
| per saga       |  | with JSON I/O  |  | lease mgmt     |
+----------------+  +-------+--------+  +----------------+
                            |
                    +-------v----------+
                    | SagaStepStatuses |
                    |   (1.16M rows)   |     Step-level status history
                    +------------------+     (avg 6.4 entries per step)

                    +------------------+
                    |   SagaEvents     |     Event log (partitioned, periodically purged)
                    |   (0 rows)       |
                    +------------------+
```

## Key Business Concepts

### CryptoToFiatSaga Pipeline
- 11-step pipeline converting crypto to fiat (100% of saga runs)
- Steps are chained: Step N's Response feeds into Step N+1's Request
- Each step carries JSON request/response payloads with conversion context
- Pipeline includes: validation, crypto locking, rate calculation, conversion execution, fiat crediting, etc.

### Saga Lifecycle (SagaStatusTypes)
- **Start (1)**: Saga initiated, steps executing forward
- **Rollback (2)**: A step failed, compensation steps executing in reverse
- **Completed (3)**: All steps finished (97% of sagas reach this state)
- **Failed (4)**: Rollback also failed, requires manual intervention (0.1%)
- **ForceStop (5)**: Operator-initiated halt

### Distributed Lease Protocol (SagaLeaseTime)
- Each saga has a 5-minute renewable lease
- Worker instances must renew leases periodically via UpdateSagaLeaseTime
- Expired leases can be acquired by other workers via TakeSagaRun
- Abandoned detection: leases not updated in 1+ hour (GetAllAbandonedSagaRuns)

### Step Lifecycle (StepStatusTypes)
- **Schedule (5)** -> **Start (1)** -> **Done (4)** (success path)
- **Start (1)** -> **Failed (2)** -> **Retry (3)** -> **Start (1)** (retry loop)
- Average 6.4 status transitions per step (indicates frequent scheduling/retry patterns)

## Object Summary

| Category | Count | Key Objects |
|----------|-------|-------------|
| **Lookup Tables** | 2 | SagaStatusTypes (5 values), StepStatusTypes (5 values) |
| **Core Tables** | 4 | SagaRuns (17K), SagaSteps (181K), SagaLeaseTime (17K), SagaEvents (0, purged) |
| **History Tables** | 2 | SagaRunStatuses (35K), SagaStepStatuses (1.16M) |
| **Write SPs** | 5 | InsertSagaRunWithLeaseTime, InsertSagaStep, InsertSagaStepStatus, InsertSagaRunStatus, AddSagaEvent |
| **Lease SPs** | 2 | TakeSagaRun, UpdateSagaLeaseTime |
| **Query SPs** | 11 | GetSagaRun, GetSagaRunsByStatus, GetAllAbandonedSagaRuns, etc. |
| **Maintenance SP** | 1 | PurgeTable (partition-based data retention) |

## Data Flow

1. **Create**: `InsertSagaRunWithLeaseTime` creates SagaRuns + SagaRunStatuses + SagaLeaseTime atomically
2. **Execute Steps**: `InsertSagaStep` creates each step, `InsertSagaStepStatus` transitions step statuses
3. **Renew Lease**: `UpdateSagaLeaseTime` keeps the lease alive during processing
4. **Transition Saga**: `InsertSagaRunStatus` moves saga through Start -> Completed/Rollback/Failed
5. **Log Events**: `AddSagaEvent` records notable occurrences for audit
6. **Monitor**: Query SPs filter by status, lease freshness, age thresholds
7. **Recover**: `GetAllAbandonedSagaRuns` + `TakeSagaRun` for stale saga recovery
8. **Purge**: `PurgeTable` truncates old event partitions

## Documentation Quality

| Metric | Value |
|--------|-------|
| **Total Objects** | 27 |
| **Average Quality** | 9.1/10 |
| **Sessions Used** | 2 |
| **Completed** | 2026-04-15 |

---

*Generated: 2026-04-15*
