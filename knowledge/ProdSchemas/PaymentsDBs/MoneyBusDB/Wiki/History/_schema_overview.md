# History Schema Overview - MoneyBusDB

## Purpose

The History schema in MoneyBusDB serves two distinct purposes:

1. **Temporal History Tables** (system-managed): `History.MoneyBusTransactions` and `History.MoneyBusWithdrawals` are SQL Server system-versioned temporal history tables. They automatically capture every prior state of transactions and withdrawals in the MoneyBus schema when rows are updated. No application code writes to these tables directly - SQL Server's SYSTEM_VERSIONING mechanism handles all inserts.

2. **API Audit Log** (application-managed): `History.TransactionsLog` is a traditional append-only log table that records encrypted request/response payloads for every external payment provider API call (validate, hold, debit, credit operations).

## Object Summary

| Object | Type | Rows (approx) | Purpose |
|--------|------|---------------|---------|
| History.MoneyBusTransactions | Temporal History Table | ~54M | Prior states of money transfer transactions (hold-debit-credit pipeline) |
| History.MoneyBusWithdrawals | Temporal History Table | ~5.8M | Prior states of withdrawal requests (hold-authorize-payout pipeline) |
| History.TransactionsLog | Audit Log Table | ~91K | Encrypted payment provider API call log |

## Data Flow

```
Application Layer
    |
    v
MoneyBus.TransactionAdd / TransactionUpdate ---[UPDATE triggers]---> History.MoneyBusTransactions
MoneyBus.WithdrawAdd / WithdrawUpdate --------[UPDATE triggers]---> History.MoneyBusWithdrawals
MoneyBus.TransactionLogInsert ----------------[direct INSERT]------> History.TransactionsLog
    |
    v
External Payment Provider (Gatsby Financial Banking API)
```

## Key Characteristics

- **No views or stored procedures** exist in the History schema itself
- **Temporal tables** are queried ad-hoc for audit, reconciliation, and point-in-time analysis
- **TransactionsLog** is written/read by MoneyBus schema procedures (TransactionLogInsert, TransactionLogGet)
- **Encryption**: TransactionsLog stores encrypted payloads; temporal tables store plaintext business data
- **Partitioning**: Only MoneyBusTransactions is partitioned (PS_MonthYear on ValidFrom)
- **Compression**: Both temporal tables use PAGE compression for storage efficiency

## Cross-Schema Dependencies

All History schema objects depend on Dictionary schema lookups for value interpretation:
- Dictionary.AccountTypes (CreditorTypeID, DebitorTypeID, AccountTypeID)
- Dictionary.TransactionStatuses / TransactionStatusReasons
- Dictionary.WithdrawStatuses / WithdrawStatusReasons

These are documented in the [Business Glossary](../_glossary.md).
