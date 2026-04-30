# Monitoring.C2FUserBreachLimitations

> Compliance monitoring procedure that counts the number of accounts exceeding USD conversion thresholds across daily, monthly, and yearly time windows, used for regulatory limit breach detection.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: TimeFrame + count of accounts exceeding threshold |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

C2FUserBreachLimitations is a compliance monitoring procedure that identifies accounts that have exceeded their crypto-to-fiat conversion limits. It aggregates USD amounts from FiatTransactions by AccountId across three time windows (day, month, year) and counts how many accounts exceed the corresponding threshold. This is essential for regulatory compliance - crypto-to-fiat conversions are subject to value limits per customer.

Used by the monitoring/alerting system to detect limit breaches. When @TimeFrame=1, returns only the daily count. Otherwise, returns all three time frames (day, month, year).

---

## 2. Business Logic

### 2.1 Multi-Window Threshold Monitoring

**What**: Aggregates USD conversion amounts per account and counts breaches across three time windows.

**Columns/Parameters Involved**: `@TimeFrame`, `@ThresholdDay`, `@ThresholdMonth`, `@ThresholdYear`

**Rules**:
- Daily: SUM(UsdAmount) per AccountId WHERE DATEDIFF(HOUR, Occurred, GETUTCDATE()) < 24
- Monthly: SUM(UsdAmount) per AccountId WHERE DATEDIFF(MONTH, Occurred, GETUTCDATE()) < 1
- Yearly: SUM(UsdAmount) per AccountId WHERE DATEDIFF(YEAR, Occurred, GETUTCDATE()) < 1
- Default thresholds: $25,000/day, $250,000/month, $2,500,000/year
- Returns count of accounts exceeding each threshold, not the accounts themselves
- Uses temp table #TableResult to ensure all timeframes appear in output (even with 0 breaches)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrame | int | NO | 1 | VERIFIED | Time window selector. 1 = daily only, any other value = all three windows (day + month + year). |
| 2 | @ThresholdDay | int | NO | 25000 | VERIFIED | Daily USD threshold. Accounts with SUM(UsdAmount) > this value in the last 24 hours are counted as breaches. Default $25,000. |
| 3 | @ThresholdMonth | int | NO | 250000 | VERIFIED | Monthly USD threshold. Default $250,000. |
| 4 | @ThresholdYear | int | NO | 2500000 | VERIFIED | Yearly USD threshold. Default $2,500,000. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | TimeFrame | nvarchar(40) | VERIFIED | 'DAY', 'MONTH', or 'YEAR' |
| 2 | Value | int | VERIFIED | Count of accounts exceeding the threshold for that time frame. 0 if no breaches. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.FiatTransactions | SELECT (FROM) | Aggregates UsdAmount by AccountId across time windows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.C2FUserBreachLimitations (procedure)
└── C2F.FiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.FiatTransactions | Table | FROM - SUM(UsdAmount) GROUP BY AccountId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check daily breaches only
```sql
EXEC Monitoring.C2FUserBreachLimitations @TimeFrame = 1
```

### 8.2 Check all time frames with custom thresholds
```sql
EXEC Monitoring.C2FUserBreachLimitations @TimeFrame = 2, @ThresholdDay = 10000, @ThresholdMonth = 100000, @ThresholdYear = 1000000
```

### 8.3 Manual daily threshold check
```sql
SELECT AccountId, SUM(UsdAmount) AS DailyUsd
FROM C2F.FiatTransactions WITH (NOLOCK)
WHERE DATEDIFF(HOUR, Occurred, GETUTCDATE()) < 24
GROUP BY AccountId
HAVING SUM(UsdAmount) > 25000
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.C2FUserBreachLimitations | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.C2FUserBreachLimitations.sql*
