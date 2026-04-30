# Monitoring.C2FUserBreachLimitations_temp

> Temporary variant of the compliance breach detection procedure with lower default thresholds, used for testing or stricter monitoring scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: TimeFrame + count of accounts exceeding threshold |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

C2FUserBreachLimitations_temp is a temporary/testing variant of the main breach limitations procedure. It has lower default thresholds ($6,000/$60,000/$250,000 vs $25,000/$250,000/$2,500,000) and a slightly different output format for the daily-only path (returns count + TimeFrame directly without the LEFT JOIN to #TableResult). The "_temp" suffix suggests this is a testing or staging version.

The core logic is identical to C2FUserBreachLimitations: aggregate FiatTransactions.UsdAmount by AccountId and count accounts exceeding thresholds.

---

## 2. Business Logic

### 2.1 Lower Default Thresholds

**What**: Same logic as C2FUserBreachLimitations but with stricter default limits.

**Columns/Parameters Involved**: `@ThresholdDay`, `@ThresholdMonth`, `@ThresholdYear`

**Rules**:
- Day: $6,000 (vs $25,000 in main procedure)
- Month: $60,000 (vs $250,000 in main procedure)
- Year: $250,000 (vs $2,500,000 in main procedure)
- Daily-only path (@TimeFrame=1): returns Value + TimeFrame directly (no temp table JOIN)
- Full path: returns Value + TimeFrame for all three windows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrame | int | NO | 1 | VERIFIED | Time window selector. 1 = daily only, other = all three. |
| 2 | @ThresholdDay | int | NO | 6000 | VERIFIED | Daily USD threshold. Default $6,000 (lower than main procedure). |
| 3 | @ThresholdMonth | int | NO | 60000 | VERIFIED | Monthly USD threshold. Default $60,000. |
| 4 | @ThresholdYear | int | NO | 250000 | VERIFIED | Yearly USD threshold. Default $250,000. |

**Return Columns:** Same as C2FUserBreachLimitations (Value, TimeFrame).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.FiatTransactions | SELECT (FROM) | Aggregates UsdAmount by AccountId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.C2FUserBreachLimitations_temp (procedure)
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

### 8.1 Check daily breaches with lower thresholds
```sql
EXEC Monitoring.C2FUserBreachLimitations_temp @TimeFrame = 1
```

### 8.2 Check all time frames
```sql
EXEC Monitoring.C2FUserBreachLimitations_temp @TimeFrame = 2
```

### 8.3 Compare with main procedure
```sql
-- Main procedure (higher thresholds)
EXEC Monitoring.C2FUserBreachLimitations @TimeFrame = 2
-- Temp procedure (lower thresholds - more breaches expected)
EXEC Monitoring.C2FUserBreachLimitations_temp @TimeFrame = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.C2FUserBreachLimitations_temp | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.C2FUserBreachLimitations_temp.sql*
