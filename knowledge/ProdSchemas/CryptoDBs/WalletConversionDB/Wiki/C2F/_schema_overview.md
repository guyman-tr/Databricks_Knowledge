# Schema Overview: C2F - WalletConversionDB

> The C2F (Crypto-to-Fiat) schema stores the business data for crypto-to-fiat conversion operations, tracking conversion requests, their lifecycle statuses, blockchain transactions, estimated and actual fiat amounts, and exchange rates.

## Purpose

The C2F schema records the business-level data for every crypto-to-fiat conversion. While the Saga schema handles orchestration (step coordination, leases, recovery), the C2F schema stores WHAT was converted, HOW MUCH, at WHAT RATE, and WHERE the fiat went. These two schemas work together: the Saga.SagaRuns.CorrelationId matches C2F.Conversions.CorrelationId, bridging orchestration state with business data.

## Architecture

```
                    +-------------------+
                    | C2F.Conversions   |     Root entity: one per conversion request
                    | (17K rows)        |     Customer, crypto, fiat, fee, correlation
                    +--+--+--+--+------+
                       |  |  |  |
          +------------+  |  |  +------------+
          |               |  |               |
+---------v-------+ +----v---v-----+ +-------v--------+
| ConversionStat. | | CryptoTrans. | | FiatTransact.  |
| (34K rows)      | | (16K rows)   | | (14K rows)     |
| Status history  | | Blockchain   | | Actual fiat    |
| Pending->Done   | | tx proof     | | amounts + fees |
+-----------------+ +--------------+ +--------+-------+
                                              |
                    +-------------------------+
                    |
          +---------v----------+
          | EstimatedFiatTrans |
          | (17K rows)         |     Pre-execution rate quotes
          | 1:1 with Convers.  |     (created atomically with conversion)
          +--------------------+
```

## Data Flow (Conversion Pipeline)

1. **Create** (`InsertConversion`): Conversion + initial Pending status + estimated fiat amounts (3 tables, 1 transaction)
2. **Crypto Transfer** (`InsertCryptoTransaction`): Records the blockchain transaction hash and amount
3. **Fiat Credit** (`InsertFiatTransaction`): Records actual fiat amount, locked rates, account, reference ID
4. **Status Transition** (`InsertConversionStatus`): Marks conversion as Completed or Failed
5. **Reference ID** (`GenerateUniqueClientLoadReferenceId`): Generates "C2F" + 8-digit unique reference for fiat payments

## Key Business Concepts

### Estimated vs Actual Amounts
- **EstimatedFiatTransactions**: Rate quote at conversion creation time (always present, 1:1)
- **FiatTransactions**: Actual amounts at execution time (only for completed conversions, 80%)
- Query SPs use `CASE WHEN ft.UsdAmount IS NULL THEN eft.UsdAmount ELSE ft.UsdAmount` pattern

### Target Platforms (Dictionary.FiatConversionTargets)
- **IbanAccount** (77%): Fiat sent to customer's bank account
- **EtoroPosition** (17%): Fiat used to open/fund a trading position
- **EtoroPlatform** (6%): Fiat credited to eToro trading balance

### Conversion Lifecycle (Dictionary.ConversionToFiatStatuses)
- **Pending** (1): Conversion initiated, pipeline executing
- **Completed** (3): All steps succeeded, fiat credited (94.6%)
- **Failed** (2): Pipeline error, typically "Crypto Transaction Failed" (5.4%)
- **Rejected** (4): Pre-execution validation failure (0% in live data)

### Cross-Schema Bridge
- C2F.Conversions.CorrelationId = Saga.SagaRuns.CorrelationId
- C2F stores business data, Saga stores orchestration state
- Row counts align: 17,039 conversions ~ 17,042 saga runs

## Object Summary

| Category | Count | Key Objects |
|----------|-------|-------------|
| **Core Table** | 1 | Conversions (17K) - root entity |
| **Transaction Tables** | 3 | CryptoTransactions (16K), EstimatedFiatTransactions (17K), FiatTransactions (14K) |
| **Status Table** | 1 | ConversionStatuses (34K) - lifecycle history |
| **Write SPs** | 5 | InsertConversion, InsertConversionStatus, InsertCryptoTransaction, InsertFiatTransaction, GenerateUniqueClientLoadReferenceId |
| **Query SPs** | 3 | GetConversionAmounts, GetConversionSummary, GetConversionsUsdSum |

## Documentation Quality

| Metric | Value |
|--------|-------|
| **Total Objects** | 13 |
| **Average Quality** | 9.1/10 |
| **Sessions Used** | 1 |
| **Completed** | 2026-04-15 |

---

*Generated: 2026-04-15*
