# Business Glossary - WalletConversionDB

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-15 | Terms: 4 lookup-backed, 0 concept-based | Sources: 2 Dictionary tables, 2 Saga lookup tables*

---

## Lookup-Backed Terms

## Conversion To Fiat Status {#conversion-to-fiat-status}

**Definition**: Lifecycle status of a crypto-to-fiat (C2F) conversion operation. Tracks whether a conversion request is still waiting, has succeeded, was rejected by validation, or encountered an error during processing.

**Source Table**: `Dictionary.ConversionToFiatStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | Conversion request has been submitted and is awaiting processing by the conversion pipeline |
| 2 | Failed | Conversion encountered a technical or business error during execution and could not complete |
| 3 | Completed | Conversion fully executed - crypto debited and fiat credited successfully |
| 4 | Rejected | Conversion was rejected before execution, typically due to validation failure (e.g., limit breach, compliance block) |

**Key Characteristics**:
- Terminal states: Completed, Failed, Rejected
- Only Pending conversions are eligible for further processing

**Used By**: C2F.ConversionStatuses, C2F.InsertConversion, C2F.InsertConversionStatus, C2F.GetConversionAmounts, C2F.GetConversionsUsdSum

---

## Fiat Conversion Target {#fiat-conversion-target}

**Definition**: The destination type for fiat proceeds when a crypto-to-fiat conversion completes. Determines where the converted fiat value is routed after the crypto sell operation.

**Source Table**: `Dictionary.FiatConversionTargets`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | IbanAccount | Fiat proceeds are sent to the customer's linked IBAN bank account as a withdrawal |
| 2 | EtoroPlatform | Fiat proceeds are credited to the customer's eToro trading platform balance |
| 3 | EtoroPosition | Fiat proceeds are used to open or fund a position on the eToro trading platform |

**Key Characteristics**:
- IbanAccount triggers an external bank transfer flow
- EtoroPlatform and EtoroPosition keep funds within the eToro ecosystem

**Used By**: C2F.Conversions, C2F.InsertConversion, C2F.GetConversionSummary

---

## Saga Status Type {#saga-status-type}

**Definition**: Lifecycle status of a saga orchestration run. Sagas coordinate multi-step distributed operations (e.g., crypto-to-fiat conversions) and track overall progress through these states.

**Source Table**: `Saga.SagaStatusTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Start | Saga has been initiated and is actively executing its steps in forward direction |
| 2 | Rollback | Saga encountered a failure and is executing compensation (undo) steps in reverse order |
| 3 | Completed | All saga steps finished successfully - the distributed operation is fully committed |
| 4 | Failed | Saga could not complete and rollback also failed or was not possible - requires manual intervention |
| 5 | ForceStop | Saga was manually halted by an operator, bypassing normal completion or rollback flow |

**Key Characteristics**:
- Start and Rollback are active (in-progress) states
- Completed, Failed, ForceStop are terminal states
- Recovery processes target sagas in Start or Rollback states that appear abandoned

**Used By**: *(to be populated as objects are documented)*

---

## Step Status Type {#step-status-type}

**Definition**: Lifecycle status of an individual step within a saga run. Each saga step represents one discrete operation in the distributed transaction sequence.

**Source Table**: `Saga.StepStatusTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Start | Step execution has begun - the operation request has been sent |
| 2 | Failed | Step execution failed - the operation could not complete, may trigger saga rollback |
| 3 | Retry | Step is being retried after a transient failure before escalating to saga-level failure |
| 4 | Done | Step completed successfully - its operation committed and the saga can advance to the next step |
| 5 | Schedule | Step is scheduled for future execution - not yet started, queued in the pipeline |

**Key Characteristics**:
- Start, Retry, Schedule are active (in-progress) states
- Done and Failed are terminal states for a step
- A Failed step typically triggers the saga to enter Rollback status

**Used By**: Saga.SagaRuns, Saga.SagaRunStatuses

---

## Business Concepts

*(No concept entries yet - will be populated as objects are documented)*
