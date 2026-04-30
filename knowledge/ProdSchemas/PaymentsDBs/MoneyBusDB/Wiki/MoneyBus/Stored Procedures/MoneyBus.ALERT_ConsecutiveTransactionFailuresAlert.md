# MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert

> Monitoring procedure that detects consecutive transaction failures exceeding configurable thresholds per creditor/debitor type pair, returning details of all failed transactions since the last success for alerting.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns alert result set of transactions exceeding failure thresholds |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert is an operational monitoring procedure that detects when consecutive transaction failures for a specific creditor/debitor type combination exceed a configurable threshold. It is designed to be called by an alerting system (e.g., Splunk, monitoring cron) to trigger notifications when payment channels start failing repeatedly.

The procedure accepts a JSON array of threshold configurations (one per creditor/debitor type pair) and scans the last 24 hours of transactions. For each configured pair, it finds the most recent success and counts how many subsequent non-success transactions exist. If the count exceeds the threshold, those failing transactions are returned in the result set with their details resolved against Dictionary.AccountTypes and Dictionary.TransactionStatuses.

---

## 2. Business Logic

### 2.1 Consecutive Failure Detection

**What**: Identifies payment channels where failures have been stacking up since the last successful transaction.

**Columns/Parameters Involved**: `@json`, `StatusID`, `CreditorTypeID`, `DebitorTypeID`

**Rules**:
- Input JSON format: `[{"CreditorTypeID": 1, "DebitorTypeID": 3, "Threshold": 10}, ...]`
- Scans only the last 24 hours of transactions (DATEADD(DD,-1,GETUTCDATE()))
- StatusID = 2 (Success) is the "last known good" marker
- Counts all transactions after the last success per type pair
- Returns transaction details only when UnsuccessCount > Threshold
- Resolves account type names via Dictionary.AccountTypes for human-readable alerts

**Diagram**:
```
Last 24h Transactions for (Creditor=1, Debitor=3):
  [Success] [Fail] [Fail] [Fail] [Fail] [Fail] ... [Fail]
       ^                                                 ^
  LastSuccess                                    UnsuccessCount = N
  
If N > Threshold -> Return all N failed transactions as alert
```

### 2.2 Per-Channel Threshold Configuration

**What**: Each creditor/debitor type pair can have its own failure threshold.

**Columns/Parameters Involved**: `@json` (CreditorTypeID, DebitorTypeID, Threshold)

**Rules**:
- Different payment channels may have different tolerance levels
- High-volume channels (Trading->IBAN) may need a higher threshold before alerting
- Low-volume channels may alert on fewer consecutive failures
- The JSON input allows the alerting system to dynamically configure thresholds

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @json | nvarchar(max) | NO | - | CODE-BACKED | JSON array of threshold configurations. Each object has: CreditorTypeID (int), DebitorTypeID (int), Threshold (int). Parsed via OPENJSON with strict typing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT from) | MoneyBus.Transactions | Reader | Scans last 24h of transactions for failure patterns |
| (JOIN) | Dictionary.AccountTypes | Lookup | Resolves CreditorTypeID and DebitorTypeID to human-readable names |
| (JOIN) | Dictionary.TransactionStatuses | Lookup | Resolves StatusID to status name for alert display |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert (procedure)
├── MoneyBus.Transactions (table) [SELECT FROM - last 24h scan]
├── Dictionary.AccountTypes (table) [JOIN - name resolution]
└── Dictionary.TransactionStatuses (table) [JOIN - name resolution]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | SELECT FROM - scans last 24h for failure patterns |
| Dictionary.AccountTypes | Table | JOIN - resolves creditor/debitor type names |
| Dictionary.TransactionStatuses | Table | JOIN - resolves status names |

### 6.2 Objects That Depend On This

No dependents found. Called by external monitoring systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check for failures on Trading<->IBAN channels
```sql
EXEC MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert
    @json = '[{"CreditorTypeID":1,"DebitorTypeID":3,"Threshold":10},{"CreditorTypeID":3,"DebitorTypeID":1,"Threshold":10}]';
```

### 8.2 Check all channels with different thresholds
```sql
EXEC MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert
    @json = '[{"CreditorTypeID":1,"DebitorTypeID":3,"Threshold":5},{"CreditorTypeID":3,"DebitorTypeID":1,"Threshold":5},{"CreditorTypeID":1,"DebitorTypeID":2,"Threshold":3},{"CreditorTypeID":2,"DebitorTypeID":1,"Threshold":3}]';
```

### 8.3 Low threshold for testing
```sql
EXEC MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert
    @json = '[{"CreditorTypeID":1,"DebitorTypeID":3,"Threshold":1}]';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert.sql*
