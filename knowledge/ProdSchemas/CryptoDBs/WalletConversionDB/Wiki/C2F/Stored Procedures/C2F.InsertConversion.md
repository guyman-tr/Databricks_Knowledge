# C2F.InsertConversion

> Atomically creates a new conversion with its initial Pending status and estimated fiat amounts in a single transaction, serving as the entry point for all crypto-to-fiat conversion operations.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: ConversionId (bigint) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertConversion is the conversion creation procedure - the entry point for initiating a new crypto-to-fiat conversion. It atomically creates three records in a single transaction: the conversion itself (Conversions), its initial Pending status (ConversionStatuses with StatusId=1), and the estimated fiat amounts (EstimatedFiatTransactions). This mirrors the saga creation pattern in InsertSagaRunWithLeaseTime.

This is the most critical write procedure in the C2F schema. Every conversion starts here. The transactional guarantee ensures a conversion is either fully initialized (with all three records) or not created at all. Deduplication by CorrelationId prevents double-submission.

---

## 2. Business Logic

### 2.1 Transactional Three-Table Insert

**What**: Creates Conversions + ConversionStatuses + EstimatedFiatTransactions atomically.

**Columns/Parameters Involved**: All parameters

**Rules**:
1. Validate @Gcid IS NOT NULL (raises error if null)
2. INSERT INTO Conversions WHERE NOT EXISTS (CorrelationId dedup)
3. If SCOPE_IDENTITY is NULL -> error "Conversion already exists"
4. INSERT INTO ConversionStatuses (ConversionId, StatusId=1) - initial Pending
5. INSERT INTO EstimatedFiatTransactions with all rate/amount parameters
6. COMMIT, return @ConversionId
- On error: ROLLBACK if @@trancount=1, COMMIT if >1

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Global Customer ID. Validated NOT NULL with error message. Stored in Conversions.Gcid. |
| 2 | @TargetPlatformId | tinyint | NO | - | VERIFIED | Fiat destination. 1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition. Stored in Conversions.TargetPlatformId. |
| 3 | @CryptoId | int | NO | - | VERIFIED | Crypto asset identifier. Stored in Conversions.CryptoId. |
| 4 | @FiatId | int | NO | - | VERIFIED | Target fiat currency identifier. Stored in Conversions.FiatId. |
| 5 | @CryptoAmount | decimal(36,18) | NO | - | VERIFIED | Crypto quantity to convert. Stored in Conversions.CryptoAmount. |
| 6 | @ConversionFeePercentage | decimal(36,18) | NO | - | VERIFIED | Fee rate (0.1 = 10%). Stored in Conversions.ConversionFeePercentage. |
| 7 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Deduplication key + distributed tracing ID. Used in WHERE NOT EXISTS check. Stored in Conversions.CorrelationId. |
| 8 | @FiatAmount | decimal(36,18) | NO | - | VERIFIED | Estimated fiat amount. Stored in EstimatedFiatTransactions.FiatAmount. |
| 9 | @UsdAmount | decimal(36,18) | NO | - | VERIFIED | Estimated USD equivalent. Stored in EstimatedFiatTransactions.UsdAmount. |
| 10 | @CryptoToUsdRate | decimal(36,18) | NO | - | VERIFIED | Rate snapshot. Stored in EstimatedFiatTransactions.CryptoToUsdRate. |
| 11 | @FiatToUsdRate | decimal(36,18) | NO | - | VERIFIED | Rate snapshot. Stored in EstimatedFiatTransactions.FiatToUsdRate. |
| 12 | @CryptoToFiatRate | decimal(36,18) | NO | - | VERIFIED | Rate snapshot. Stored in EstimatedFiatTransactions.CryptoToFiatRate. |

**Return:** ConversionId (bigint) - the Id of the newly created conversion row.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.Conversions | INSERT target | Creates the conversion record |
| - | C2F.ConversionStatuses | INSERT target | Creates initial Pending status (StatusId=1) |
| - | C2F.EstimatedFiatTransactions | INSERT target | Creates estimated fiat amounts |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
C2F.InsertConversion (procedure)
├── C2F.Conversions (table)
├── C2F.ConversionStatuses (table)
└── C2F.EstimatedFiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | INSERT target + dedup check |
| C2F.ConversionStatuses | Table | INSERT target - initial Pending status |
| C2F.EstimatedFiatTransactions | Table | INSERT target - estimated amounts |

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

### 8.1 Create a new conversion
```sql
EXEC C2F.InsertConversion
    @Gcid = 31036842, @TargetPlatformId = 1, @CryptoId = 4, @FiatId = 1,
    @CryptoAmount = 100.0, @ConversionFeePercentage = 0.1,
    @CorrelationId = NEWID(),
    @FiatAmount = 135.64, @UsdAmount = 135.64,
    @CryptoToUsdRate = 1.3564, @FiatToUsdRate = 1.0, @CryptoToFiatRate = 1.3564
```

### 8.2 Verify conversion was created
```sql
SELECT c.Id, c.Gcid, cs.StatusId, eft.FiatAmount
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN C2F.ConversionStatuses cs WITH (NOLOCK) ON cs.ConversionId = c.Id
INNER JOIN C2F.EstimatedFiatTransactions eft WITH (NOLOCK) ON eft.ConversionId = c.Id
WHERE c.CorrelationId = @CorrelationId
```

### 8.3 Check dedup works
```sql
-- Second call with same CorrelationId should raise error
EXEC C2F.InsertConversion @Gcid = 31036842, @TargetPlatformId = 1, @CryptoId = 4, @FiatId = 1,
    @CryptoAmount = 100.0, @ConversionFeePercentage = 0.1, @CorrelationId = @SameCorrelationId,
    @FiatAmount = 135.64, @UsdAmount = 135.64,
    @CryptoToUsdRate = 1.3564, @FiatToUsdRate = 1.0, @CryptoToFiatRate = 1.3564
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 12 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.InsertConversion | Type: Stored Procedure | Source: WalletConversionDB/C2F/Stored Procedures/C2F.InsertConversion.sql*
