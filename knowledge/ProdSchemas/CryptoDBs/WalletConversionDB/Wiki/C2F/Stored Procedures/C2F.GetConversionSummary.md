# C2F.GetConversionSummary

> Retrieves a complete conversion summary by CorrelationId, joining all related tables to provide a single-row view of the conversion with crypto amounts, fiat amounts, rates, fees, and current status.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Full conversion summary for a CorrelationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetConversionSummary provides a comprehensive single-row view of a conversion by joining all five C2F tables. It returns the conversion header, current status (via correlated subquery), crypto transaction details (amount, fee), fiat transaction details (amount, fee, rate), and the target platform. This is the "detail view" for a single conversion.

Used by the application to display full conversion details and by support/operations to investigate specific conversions.

---

## 2. Business Logic

### 2.1 Full Five-Table Join

**What**: LEFT JOINs all child tables to handle conversions at any stage of completion.

**Columns/Parameters Involved**: `@CorrelationId`

**Rules**:
- FROM Conversions WHERE CorrelationId = @CorrelationId
- LEFT JOIN EstimatedFiatTransactions (always present, but LEFT for safety)
- LEFT JOIN CryptoTransactions (NULL if conversion failed before crypto step)
- LEFT JOIN FiatTransactions (NULL if conversion failed before fiat step)
- Status via correlated subquery on ConversionStatuses (most recent by Id DESC)
- Returns a mix of columns from different tables providing the complete picture

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Identifies the conversion to summarize. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | Id | bigint | VERIFIED | Conversion ID |
| 2 | CorrelationId | uniqueidentifier | VERIFIED | Distributed tracing ID |
| 3 | Occurred | datetime2 | VERIFIED | Conversion creation time |
| 4 | Status | tinyint | VERIFIED | Current status (most recent from ConversionStatuses) |
| 5 | CryptoAmount | decimal | VERIFIED | Crypto amount from CryptoTransactions (NULL if no crypto tx) |
| 6 | BlockchainFee | decimal | VERIFIED | Blockchain network fee (NULL if no crypto tx) |
| 7 | FiatAmount | decimal | VERIFIED | Actual fiat amount from FiatTransactions (NULL if not completed) |
| 8 | ConversionFeeAmount | decimal | VERIFIED | Actual fee from FiatTransactions (NULL if not completed) |
| 9 | ConversionFeePercentage | decimal | VERIFIED | Fee rate from Conversions |
| 10 | CryptoToFiatRate | decimal | VERIFIED | Actual rate from FiatTransactions (NULL if not completed) |
| 11 | TargetPlatformId | tinyint | VERIFIED | Fiat destination type (1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.Conversions | SELECT (FROM) | Primary table |
| - | C2F.ConversionStatuses | SELECT (subquery) | Current status lookup |
| - | C2F.EstimatedFiatTransactions | SELECT (LEFT JOIN) | Estimated amounts |
| - | C2F.CryptoTransactions | SELECT (LEFT JOIN) | Crypto tx details |
| - | C2F.FiatTransactions | SELECT (LEFT JOIN) | Fiat tx details |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
C2F.GetConversionSummary (procedure)
├── C2F.Conversions (table)
├── C2F.ConversionStatuses (table)
├── C2F.EstimatedFiatTransactions (table)
├── C2F.CryptoTransactions (table)
└── C2F.FiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | FROM - filtered by CorrelationId |
| C2F.ConversionStatuses | Table | Subquery - most recent status |
| C2F.EstimatedFiatTransactions | Table | LEFT JOIN |
| C2F.CryptoTransactions | Table | LEFT JOIN - crypto amounts |
| C2F.FiatTransactions | Table | LEFT JOIN - fiat amounts |

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

### 8.1 Get full conversion summary
```sql
EXEC C2F.GetConversionSummary @CorrelationId = 'BD637018-99FC-40AD-A466-773D7274F16C'
```

### 8.2 Equivalent direct query with status name
```sql
SELECT c.Id, c.CorrelationId, ds.Name AS Status, ct.Amount AS CryptoAmount,
       ft.FiatAmount, ft.ConversionFeeAmount, fct.Name AS TargetPlatform
FROM C2F.Conversions c WITH (NOLOCK)
LEFT JOIN C2F.CryptoTransactions ct WITH (NOLOCK) ON ct.ConversionId = c.Id
LEFT JOIN C2F.FiatTransactions ft WITH (NOLOCK) ON ft.ConversionId = c.Id
CROSS APPLY (
    SELECT TOP 1 cs.StatusId FROM C2F.ConversionStatuses cs WITH (NOLOCK)
    WHERE cs.ConversionId = c.Id ORDER BY cs.Id DESC
) latest
INNER JOIN Dictionary.ConversionToFiatStatuses ds WITH (NOLOCK) ON ds.Id = latest.StatusId
INNER JOIN Dictionary.FiatConversionTargets fct WITH (NOLOCK) ON fct.Id = c.TargetPlatformId
WHERE c.CorrelationId = @CorrelationId
```

### 8.3 Count conversions by completion state
```sql
SELECT
    SUM(CASE WHEN ft.Id IS NOT NULL THEN 1 ELSE 0 END) AS WithFiatTx,
    SUM(CASE WHEN ct.Id IS NOT NULL THEN 1 ELSE 0 END) AS WithCryptoTx,
    COUNT(*) AS Total
FROM C2F.Conversions c WITH (NOLOCK)
LEFT JOIN C2F.CryptoTransactions ct WITH (NOLOCK) ON ct.ConversionId = c.Id
LEFT JOIN C2F.FiatTransactions ft WITH (NOLOCK) ON ft.ConversionId = c.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 11 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.GetConversionSummary | Type: Stored Procedure | Source: WalletConversionDB/C2F/Stored Procedures/C2F.GetConversionSummary.sql*
