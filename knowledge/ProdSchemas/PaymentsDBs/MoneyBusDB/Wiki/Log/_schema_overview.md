# Log Schema Overview - MoneyBusDB

## Purpose

The Log schema in MoneyBusDB serves as the audit and observability layer for the MoneyBus payment processing system. It captures granular, step-by-step execution logs for transaction and withdrawal pipelines, enabling operational troubleshooting, failure diagnosis, and process transparency.

## Objects

| Object | Type | Description |
|--------|------|-------------|
| [Log.TransactionStep](Tables/Log.TransactionStep.md) | Table | Step-by-step execution log for transaction and withdrawal pipelines. Records each pipeline stage (setup, validate, hold, debit, credit, commit, etc.) with its outcome (Pass/Terminate/Fail), error details, and correlation data. |

## Key Concepts

### Dual Pipeline Logging
The schema logs steps from two distinct execution pipelines that share a single table:
- **Transaction flow** (deposits/internal transfers): Logged by the MoneyBusTransactionsExecuter service. Steps use kebab-case naming (e.g., `setup`, `validate`, `hold-initiate`). Identified by `TransactionTypeID = NULL`.
- **Withdrawal flow**: Logged by the MoneyBusWithdrawExecuter service. Steps use camelCase naming (e.g., `holdInitiate`, `authorizeInitiate`, `payoutFinalize`). Identified by `TransactionTypeID = 2`.

### Step Outcome Model
Three possible outcomes per step:
- **Pass**: Step succeeded, pipeline continues
- **Terminate**: Business validation failure (e.g., insufficient funds) - graceful pipeline stop
- **Fail**: Technical/system error - unexpected pipeline failure requiring investigation

## Data Characteristics

- **Append-only**: Rows are inserted but never updated or deleted
- **High volume**: ~78M+ rows, continuously growing
- **Single writer**: All inserts go through `MoneyBus.TransactionStepAdd`
- **Active since**: April 2023

## Team Ownership

MIMO Core Team (per Confluence service documentation)

## Completion Status

| Metric | Value |
|--------|-------|
| Objects documented | 1/1 (100%) |
| Average quality | 7.8/10 |
| Documentation date | 2026-04-15 |
