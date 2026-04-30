# Monitoring.GetFiatTransactionsToEstimatedFiatTransactionsLargeDifference

> Rate slippage alert that detects conversions where the actual fiat amount differs from the estimated amount by more than a configurable percentage, indicating significant market movement during execution.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Conversions with large estimated-vs-actual differences |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFiatTransactionsToEstimatedFiatTransactionsLargeDifference identifies conversions where the actual fiat amount (from FiatTransactions) differs significantly from the estimated amount (from EstimatedFiatTransactions). A large difference indicates the exchange rate moved substantially during the conversion pipeline execution (~4 minutes between estimate and actual). This is a pricing risk alert.

Used to monitor for excessive rate slippage that could indicate market volatility, pricing system issues, or exploitation attempts.

---

## 2. Business Logic

### 2.1 Percentage-Based Slippage Detection

**What**: Calculates percentage difference between actual and estimated USD amounts, flags those exceeding threshold.

**Columns/Parameters Involved**: `@AcceptedPercentageDifference`, `@TimeFrameInMinutes`

**Rules**:
- Difference = ABS(ft.UsdAmount - eft.UsdAmount)
- PercentageDifference = (Difference / ft.UsdAmount) * 100
- Filter: PercentageDifference > @AcceptedPercentageDifference (default 5%)
- Time window: DATEDIFF(minute, ft.Occurred, GETUTCDATE()) < @TimeFrameInMinutes (default 60)
- Uses actual (ft.UsdAmount) as denominator for percentage calculation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AcceptedPercentageDifference | float | NO | 5.0 | VERIFIED | Maximum acceptable percentage difference. Conversions exceeding this are returned. Default 5%. |
| 2 | @TimeFrameInMinutes | int | NO | 60 | VERIFIED | Time window for detection. Default 60 minutes. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | ConversionId | bigint | VERIFIED | Conversion with large slippage |
| 2 | UsdAmount | decimal | VERIFIED | Actual USD amount |
| 3 | EstimatedUsdAmount | decimal | VERIFIED | Estimated USD amount |
| 4 | Difference | decimal | VERIFIED | Absolute difference |
| 5 | PercentageDifference | float | VERIFIED | Difference as percentage of actual |
| 6 | Occurred | datetime2 | VERIFIED | FiatTransaction timestamp |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.FiatTransactions | SELECT (FROM) | Actual amounts |
| - | C2F.EstimatedFiatTransactions | LEFT JOIN | Estimated amounts for comparison |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetFiatTransactionsToEstimatedFiatTransactionsLargeDifference (procedure)
├── C2F.FiatTransactions (table)
└── C2F.EstimatedFiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.FiatTransactions | Table | FROM - actual amounts |
| C2F.EstimatedFiatTransactions | Table | LEFT JOIN - estimated amounts |

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

### 8.1 Check for large rate slippage (default 5%)
```sql
EXEC Monitoring.GetFiatTransactionsToEstimatedFiatTransactionsLargeDifference
```

### 8.2 Check with tighter threshold (2%)
```sql
EXEC Monitoring.GetFiatTransactionsToEstimatedFiatTransactionsLargeDifference @AcceptedPercentageDifference = 2.0, @TimeFrameInMinutes = 1440
```

### 8.3 Direct slippage analysis
```sql
SELECT ft.ConversionId, ft.UsdAmount AS Actual, eft.UsdAmount AS Estimated,
       ABS(ft.UsdAmount - eft.UsdAmount) AS Diff,
       (ABS(ft.UsdAmount - eft.UsdAmount) / ft.UsdAmount) * 100 AS PctDiff
FROM C2F.FiatTransactions ft WITH (NOLOCK)
INNER JOIN C2F.EstimatedFiatTransactions eft WITH (NOLOCK) ON ft.ConversionId = eft.ConversionId
ORDER BY PctDiff DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetFiatTransactionsToEstimatedFiatTransactionsLargeDifference | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetFiatTransactionsToEstimatedFiatTransactionsLargeDifference.sql*
