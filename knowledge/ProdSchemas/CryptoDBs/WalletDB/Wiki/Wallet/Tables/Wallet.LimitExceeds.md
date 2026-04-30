# Wallet.LimitExceeds

> Audit log of transactions that exceeded a configured limit rule, recording the breach details including requested amount, applicable limit threshold, and whether it was a periodic rolling-total violation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + FK indexes on TransactionTypeId, TimeZoneId |

---

## 1. Business Meaning

This table records every instance where a wallet transaction request breached a configured limit rule from `Wallet.LimitationsDefinitions`. Each row captures the full context of the breach: who attempted it (`Gcid`), what they tried to do (`TransactionTypeId`, `CryptoId`), how much they requested (`RequestAmount`, `RequestAmountUSD`), what the limit was (`CryptoLimitationAmount`), and whether it was a single-transaction or rolling-period violation (`IsPeriodicExceed`). With 5,128 rows, the table reflects the relatively rare but operationally significant events where customers or processes hit configured thresholds.

The table serves compliance, risk, and operations purposes. Compliance teams use it to demonstrate that limit controls are functioning and that oversized transactions are being caught. Risk teams analyse patterns - recurring exceeds from the same Gcid may indicate attempted limit circumvention. Operations teams review hard-limit breaches to decide whether to approve exceptions or investigate.

Rows are created by the limits evaluation service at the point a transaction request is validated, before the transaction is executed. The `CorrelationId` links the exceed record to the originating request in `Wallet.Requests`, enabling the full transaction context to be retrieved. The `USDRate` provides the exchange rate used for USD-normalised comparisons at the time of evaluation.

---

## 2. Business Logic

### 2.1 Single vs Periodic Exceed Classification

**What**: A breach can result from a single transaction being too large, or from the rolling aggregate over a period exceeding the periodic limit.

**Columns/Parameters Involved**: `IsPeriodicExceed`, `PeriodicSentAmount`, `SentSince`, `TimeZoneId`

**Rules**:
- IsPeriodicExceed=0: The individual `RequestAmount` exceeded the single-transaction limit threshold
- IsPeriodicExceed=1: The sum of past transactions (`PeriodicSentAmount`) plus this request crossed the rolling period limit
- `SentSince` captures the start of the rolling window that was evaluated
- `TimeZoneId` records which time zone's day/week/month boundary was used for the period calculation (user's local time zone may determine the reset window)
- When IsPeriodicExceed=1, `PeriodicSentAmount` shows how much had already been sent in the period before this attempt

### 2.2 USD Normalisation

**What**: All amounts are captured in both native crypto and USD-equivalent for consistent cross-asset comparison.

**Columns/Parameters Involved**: `RequestAmount`, `RequestAmountUSD`, `CryptoLimitationAmount`, `USDRate`

**Rules**:
- `RequestAmount` is in the native cryptocurrency unit (e.g., BTC, ETH)
- `RequestAmountUSD` = `RequestAmount` * `USDRate` at evaluation time
- `CryptoLimitationAmount` is the limit threshold in the native crypto unit from the matching LimitationsDefinitions row
- `USDRate` is snapshotted at evaluation time, not recalculated; historical records reflect the rate at the moment of the breach
- Limit rules may be defined in USD terms and converted to crypto at evaluation time; the resulting crypto threshold is stored in CryptoLimitationAmount

---

## 3. Data Overview

| Id | Gcid | CryptoId | TransactionTypeId | RequestAmount | CryptoLimitationAmount | IsPeriodicExceed | Occurred | Meaning |
|---|---|---|---|---|---|---|---|---|
| 5128 | 22314500 | 1 (BTC) | 2 (Send) | 2.50000000 | 1.00000000 | 0 | 2026-04-14 11:30 | Customer attempted to send 2.5 BTC; single-transaction max is 1 BTC - hard breach |
| 5127 | 18900012 | 3 (ETH) | 2 (Send) | 15.00 | 50.00 | 1 | 2026-04-14 10:15 | ETH periodic limit breach - customer's 30-day rolling send total exceeded threshold |
| 5100 | 31450228 | 5 (XRP) | 1 (Buy) | 10000 | 5000 | 0 | 2026-04-13 14:22 | XRP single-buy exceeded maximum allowed per transaction |
| 4950 | 27001100 | 1 (BTC) | 3 (Withdraw) | 0.00005 | 0.0001 | 0 | 2026-04-12 09:00 | BTC withdrawal below minimum threshold - dust transaction blocked |
| 4800 | 19500077 | 3 (ETH) | 2 (Send) | 8.00 | 50.00 | 1 | 2026-04-10 16:44 | Another periodic ETH exceed - same customer hit weekly rolling cap |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Request correlation ID of the transaction that triggered the breach. Links to Wallet.Requests.CorrelationId for full transaction context. |
| 3 | Gcid | bigint | YES | - | CODE-BACKED | Global Customer ID of the customer whose transaction breached a limit. Used to identify repeat offenders or investigate specific customer behaviour. |
| 4 | CryptoId | int | YES | - | CODE-BACKED | Cryptocurrency involved in the breaching transaction. Implicit reference to Wallet.CryptoTypes. |
| 5 | TransactionTypeId | tinyint | YES | - | VERIFIED | Type of transaction that was limited (e.g., Send, Receive, Buy, Withdraw). FK to Dict.TransactionTypes. |
| 6 | RequestAmount | decimal / numeric | YES | - | CODE-BACKED | The amount in native crypto units that was requested in the transaction. The value that was compared against the limit threshold. |
| 7 | RequestAmountUSD | decimal / numeric | YES | - | CODE-BACKED | USD equivalent of the RequestAmount at the time of evaluation, using the USDRate snapshot. Enables cross-asset reporting. |
| 8 | CryptoLimitationAmount | decimal / numeric | YES | - | CODE-BACKED | The limit threshold in native crypto units that was breached, sourced from the matching LimitationsDefinitions row. |
| 9 | USDRate | decimal / numeric | YES | - | CODE-BACKED | Snapshot of the USD exchange rate for the cryptocurrency at the moment of limit evaluation. Used to compute RequestAmountUSD. |
| 10 | IsPeriodicExceed | bit | YES | - | VERIFIED | 0=single-transaction limit breach, 1=rolling-period aggregate limit breach. Determines whether PeriodicSentAmount and SentSince are meaningful. |
| 11 | PeriodicSentAmount | decimal / numeric | YES | - | CODE-BACKED | Total amount already sent in the rolling period before this transaction was attempted. Populated only when IsPeriodicExceed=1. |
| 12 | SentSince | datetime2(7) | YES | - | CODE-BACKED | Start of the rolling window used for periodic limit evaluation. Populated only when IsPeriodicExceed=1. |
| 13 | TimeZoneId | int | YES | - | VERIFIED | Time zone used to determine the period boundary (e.g., customer's local day). FK to Dict.TimeZones. Relevant for daily/weekly periodic limits. |
| 14 | Occurred | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp of when the limit breach was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionTypeId | Dict.TransactionTypes | FK | Identifies the type of transaction that was blocked or alerted |
| TimeZoneId | Dict.TimeZones | FK | Time zone for periodic window boundary calculation |
| CryptoId | Wallet.CryptoTypes | Implicit | Identifies the cryptocurrency involved |
| CorrelationId | Wallet.Requests | Implicit (via CorrelationId) | Links to the originating transaction request |

### 5.2 Referenced By (other objects point to this)

This object has no known referencing objects.

---

## 6. Dependencies

### 6.0 Dependency Chain

Wallet.LimitationsDefinitions → (evaluation logic) → Wallet.LimitExceeds
Dict.TransactionTypes → Wallet.LimitExceeds
Dict.TimeZones → Wallet.LimitExceeds

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dict.TransactionTypes | Table | FK target for TransactionTypeId |
| Dict.TimeZones | Table | FK target for TimeZoneId |
| Wallet.LimitationsDefinitions | Table | Source of limit rules that generate exceed records |
| Wallet.CryptoTypes | Table | Implicit lookup for CryptoId |

### 6.2 Objects That Depend On This

No known dependents.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LimitExceeds | CLUSTERED PK | Id ASC | - | - | Active |
| FK index on TransactionTypeId | NC | TransactionTypeId ASC | - | - | Active |
| FK index on TimeZoneId | NC | TimeZoneId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_LimitExceeds_TransactionTypeId | FK | TransactionTypeId -> Dict.TransactionTypes.Id |
| FK_LimitExceeds_TimeZoneId | FK | TimeZoneId -> Dict.TimeZones.Id |

---

## 8. Sample Queries

### 8.1 Recent limit breaches for a specific customer
```sql
SELECT le.Id, le.CryptoId, le.TransactionTypeId,
       le.RequestAmount, le.CryptoLimitationAmount,
       le.IsPeriodicExceed, le.Occurred
FROM Wallet.LimitExceeds le WITH (NOLOCK)
WHERE le.Gcid = 22314500
ORDER BY le.Occurred DESC
```

### 8.2 Breach volume by crypto and type over the last 30 days
```sql
SELECT le.CryptoId, le.TransactionTypeId,
       le.IsPeriodicExceed,
       COUNT(*) AS BreachCount
FROM Wallet.LimitExceeds le WITH (NOLOCK)
WHERE le.Occurred >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY le.CryptoId, le.TransactionTypeId, le.IsPeriodicExceed
ORDER BY BreachCount DESC
```

### 8.3 Trace breach back to originating request
```sql
SELECT le.Id AS ExceedId, le.Gcid, le.RequestAmount,
       le.CryptoLimitationAmount, le.Occurred AS ExceedOccurred,
       le.CorrelationId
FROM Wallet.LimitExceeds le WITH (NOLOCK)
WHERE le.CorrelationId = 'A1B2C3D4-0000-0000-0000-000000000000'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.LimitExceeds | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.LimitExceeds.sql*
