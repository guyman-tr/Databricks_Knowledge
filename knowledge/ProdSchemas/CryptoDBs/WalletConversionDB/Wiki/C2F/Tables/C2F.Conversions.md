# C2F.Conversions

> Central record of every crypto-to-fiat conversion request, storing the customer, source crypto, target fiat, amount, fee, and correlation identity that links to the saga orchestration.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (PK + 3 NC) |

---

## 1. Business Meaning

C2F.Conversions is the central business data table for the crypto-to-fiat conversion system. Each row represents one conversion request initiated by a customer - the intent to sell cryptocurrency and receive fiat currency. It records WHAT is being converted (crypto asset and amount), WHERE the fiat proceeds go (target platform), WHO initiated it (Gcid - Global Customer ID), and the fee applied.

Without this table, there would be no record of conversion requests. Every other C2F table (ConversionStatuses, CryptoTransactions, EstimatedFiatTransactions, FiatTransactions) references back to Conversions as the root entity via ConversionId FK. The CorrelationId column links each conversion to its corresponding Saga.SagaRuns entry, bridging the business data (C2F schema) with the orchestration data (Saga schema).

Conversions are created by `C2F.InsertConversion`, which atomically inserts the conversion, its initial Pending status, and the estimated fiat amounts in a single transaction. All query and reporting procedures (GetConversionAmounts, GetConversionSummary, GetConversionsUsdSum) use this as their primary FROM table.

---

## 2. Business Logic

### 2.1 Conversion Creation with Deduplication

**What**: InsertConversion prevents duplicate conversions using CorrelationId as an idempotency key.

**Columns/Parameters Involved**: `CorrelationId`, `Id`

**Rules**:
- INSERT WHERE NOT EXISTS (SELECT 1 FROM Conversions WHERE CorrelationId = @CorrelationId)
- If CorrelationId already exists, raises error: 'Conversion with CorrelationId already exists'
- Indexed on (Id, CorrelationId) for efficient dedup lookups
- CorrelationId matches Saga.SagaRuns.CorrelationId, providing the bridge between C2F business data and saga orchestration

### 2.2 Target Platform Distribution

**What**: TargetPlatformId determines where fiat proceeds are routed after conversion.

**Columns/Parameters Involved**: `TargetPlatformId`

**Rules**:
- 1 = IbanAccount (77% of conversions) - fiat sent to customer's bank account
- 2 = EtoroPlatform (6%) - fiat credited to eToro trading balance
- 3 = EtoroPosition (17%) - fiat used to open/fund a trading position
- See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target) for full definitions

### 2.3 Crypto and Fiat Asset Identification

**What**: CryptoId and FiatId identify the source crypto asset and target fiat currency.

**Columns/Parameters Involved**: `CryptoId`, `FiatId`

**Rules**:
- CryptoId references crypto asset identifiers (e.g., 4, 64, 107 in live data - likely BTC, ETH, etc.)
- FiatId references fiat currency identifiers (1 and 2 visible - likely USD and EUR)
- These are external reference IDs not backed by Dictionary tables in this database
- The combination determines the conversion rate path (CryptoToFiatRate)

---

## 3. Data Overview

| Id | Gcid | TargetPlatformId | CryptoId | FiatId | CryptoAmount | ConversionFeePercentage | Meaning |
|----|------|------------------|----------|--------|--------------|------------------------|---------|
| 17039 | 31036842 | 3 (EtoroPosition) | 4 | 1 | 100 | 0 | Customer converting 100 units of crypto #4 to fiat #1, routing to a trading position. Zero fee (possibly a promotion or internal transfer). |
| 17037 | 42001277 | 1 (IbanAccount) | 64 | 2 | 2.208021 | 0.1 | Customer converting ~2.2 units of crypto #64 to fiat #2, sending to bank account. Standard 10% conversion fee. |
| 17036 | 40307380 | 1 (IbanAccount) | 107 | 2 | 158.191059 | 0.1 | Larger conversion of ~158 units of crypto #107 to fiat #2, with 10% fee. CorrelationId matches a saga run documented in the Saga schema. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | VERIFIED | Auto-incrementing surrogate primary key. Referenced by all child tables (ConversionStatuses, CryptoTransactions, EstimatedFiatTransactions, FiatTransactions) via ConversionId FK. |
| 2 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID identifying the customer who initiated the conversion. Validated NOT NULL by InsertConversion (raises error if null). Indexed for customer-scoped queries (GetConversionAmounts, GetConversionsUsdSum). |
| 3 | TargetPlatformId | tinyint | NO | - | VERIFIED | Fiat destination type. FK to Dictionary.FiatConversionTargets. Values: 1=IbanAccount (77%), 2=EtoroPlatform (6%), 3=EtoroPosition (17%). See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target). Determines the downstream routing of fiat proceeds. |
| 4 | CryptoId | int | NO | - | CODE-BACKED | Crypto asset identifier (external reference). Identifies which cryptocurrency is being sold. Values observed: 4, 64, 107 (likely mapped to assets like BTC, ETH, etc. in an external system). |
| 5 | FiatId | int | NO | - | CODE-BACKED | Fiat currency identifier (external reference). Identifies which fiat currency the customer receives. Values observed: 1, 2 (likely USD, EUR). |
| 6 | CryptoAmount | decimal(36,18) | NO | - | VERIFIED | Quantity of cryptocurrency being converted. High precision (18 decimals) to handle fractional crypto amounts. This is the gross amount before fees. |
| 7 | ConversionFeePercentage | decimal(36,18) | NO | - | VERIFIED | Fee rate applied to the conversion as a decimal fraction (0.1 = 10%). Used to calculate ConversionFeeAmount in FiatTransactions. Zero fee observed for some EtoroPosition conversions. |
| 8 | CorrelationId | uniqueidentifier | NO | - | VERIFIED | Distributed tracing correlation ID linking this conversion to its Saga.SagaRuns orchestration entry and all cross-service operations. Used as the deduplication key by InsertConversion. Indexed with Id for lookups. All SPs identify conversions by CorrelationId rather than Id. |
| 9 | Occurred | datetime2(7) | NO | GETUTCDATE() | VERIFIED | UTC timestamp when the conversion was created. Default constraint provides automatic timestamping. Indexed DESC for recency queries. Used by time-windowed queries (GetConversionAmounts, GetConversionsUsdSum) via @FromDateTime filter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TargetPlatformId | Dictionary.FiatConversionTargets | Explicit FK | Fiat destination type (IbanAccount, EtoroPlatform, EtoroPosition) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| C2F.ConversionStatuses | ConversionId | Explicit FK | Status history for each conversion |
| C2F.CryptoTransactions | ConversionId | Explicit FK | Blockchain transaction for the crypto side |
| C2F.EstimatedFiatTransactions | ConversionId | Explicit FK | Estimated fiat amounts at conversion time |
| C2F.FiatTransactions | ConversionId | Explicit FK | Actual fiat transaction details |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| C2F.ConversionStatuses | Table | ConversionId FK |
| C2F.CryptoTransactions | Table | ConversionId FK |
| C2F.EstimatedFiatTransactions | Table | ConversionId FK |
| C2F.FiatTransactions | Table | ConversionId FK |
| C2F.InsertConversion | Stored Procedure | WRITER - creates conversion rows |
| C2F.InsertConversionStatus | Stored Procedure | READER - looks up by CorrelationId |
| C2F.InsertCryptoTransaction | Stored Procedure | READER - looks up by CorrelationId |
| C2F.InsertFiatTransaction | Stored Procedure | READER - looks up by CorrelationId |
| C2F.GetConversionAmounts | Stored Procedure | READER - primary FROM table |
| C2F.GetConversionSummary | Stored Procedure | READER - primary FROM table |
| C2F.GetConversionsUsdSum | Stored Procedure | READER - primary FROM table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_C2F_Conversions_Id | CLUSTERED | Id ASC | - | - | Active |
| IX_Conversions_CorrelationId | NC | Id ASC, CorrelationId ASC | - | - | Active |
| IX_Conversions_Gcid | NC | Gcid ASC | - | - | Active |
| IX_Conversions_Occurred | NC | Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_C2F_Conversions_Id | PRIMARY KEY | Identity PK. DATA_COMPRESSION = PAGE. |
| FK_C2F_Conversions_TargetPlatformId_Dictionary_FiatConversionTargets_Id | FOREIGN KEY | TargetPlatformId -> Dictionary.FiatConversionTargets.Id |
| C2F_Conversions_Occurred | DEFAULT | GETUTCDATE() - automatic timestamp on insert |

---

## 8. Sample Queries

### 8.1 Get a conversion by CorrelationId
```sql
SELECT c.Id, c.Gcid, c.TargetPlatformId, c.CryptoId, c.FiatId, c.CryptoAmount, c.ConversionFeePercentage, c.Occurred
FROM C2F.Conversions c WITH (NOLOCK)
WHERE c.CorrelationId = @CorrelationId
```

### 8.2 Get recent conversions for a customer
```sql
SELECT c.Id, fct.Name AS TargetPlatform, c.CryptoId, c.FiatId, c.CryptoAmount, c.Occurred
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN Dictionary.FiatConversionTargets fct WITH (NOLOCK) ON fct.Id = c.TargetPlatformId
WHERE c.Gcid = @Gcid
ORDER BY c.Occurred DESC
```

### 8.3 Conversion volume by target platform
```sql
SELECT fct.Name AS TargetPlatform, COUNT(*) AS ConversionCount, SUM(c.CryptoAmount) AS TotalCryptoAmount
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN Dictionary.FiatConversionTargets fct WITH (NOLOCK) ON fct.Id = c.TargetPlatformId
GROUP BY fct.Name
ORDER BY ConversionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.Conversions | Type: Table | Source: WalletConversionDB/C2F/Tables/C2F.Conversions.sql*
