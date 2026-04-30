# C2F.EstimatedFiatTransactions

> Captures the estimated fiat amounts and exchange rates at the time of conversion creation, serving as the pre-execution price quote before actual rates are locked.

| Property | Value |
|----------|-------|
| **Schema** | C2F |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + 1 NC on ConversionId) |

---

## 1. Business Meaning

C2F.EstimatedFiatTransactions stores the estimated fiat value of a conversion at the time the request was created. This represents the "price quote" shown to the customer before the actual conversion executes - the expected amount they will receive based on current exchange rates. The actual fiat amount (which may differ due to rate movements during execution) is recorded separately in C2F.FiatTransactions.

Every conversion has exactly one estimated fiat transaction (17,039 rows = 17,039 conversions, 1:1). This is because it's created atomically with the conversion by `C2F.InsertConversion` in the same transaction.

Used by GetConversionAmounts and GetConversionsUsdSum as a fallback when the actual FiatTransaction doesn't exist yet (conversion still in progress). The CASE pattern `WHEN ft.UsdAmount IS NULL THEN eft.UsdAmount ELSE ft.UsdAmount` prefers actual over estimated.

---

## 2. Business Logic

### 2.1 Estimated vs Actual Rate Pattern

**What**: Stores the rate snapshot at conversion creation, before the actual blockchain execution potentially changes rates.

**Columns/Parameters Involved**: `CryptoToUsdRate`, `FiatToUsdRate`, `CryptoToFiatRate`, `FiatAmount`, `UsdAmount`

**Rules**:
- CryptoToFiatRate = CryptoToUsdRate / FiatToUsdRate (cross-rate derivation)
- When FiatId=1 (USD): FiatToUsdRate=1.0, FiatAmount=UsdAmount, CryptoToFiatRate=CryptoToUsdRate
- When FiatId=2 (non-USD): FiatToUsdRate>1.0 (e.g., 1.179 for EUR), amounts differ
- UsdAmount is always present as a normalization for limit calculations (GetConversionsUsdSum)
- Estimated amounts may differ from actual FiatTransactions amounts due to rate movement during execution

---

## 3. Data Overview

| Id | ConversionId | FiatAmount | UsdAmount | CryptoToFiatRate | FiatToUsdRate | Meaning |
|----|-------------|------------|-----------|------------------|---------------|---------|
| 17039 | 17039 | 135.64 | 135.64 | 1.3564 | 1.0 | USD conversion - fiat and USD amounts identical. 100 crypto units at rate 1.3564 = $135.64 estimated. |
| 17037 | 17037 | 155.80 | 183.69 | 70.56 | 1.179 | Non-USD conversion (EUR). FiatAmount in EUR, UsdAmount in USD equivalent. Rate conversion path: crypto -> USD -> EUR. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | ConversionId | bigint | NO | - | VERIFIED | FK to C2F.Conversions.Id. 1:1 relationship - every conversion gets exactly one estimated fiat record. Created atomically by InsertConversion. |
| 3 | FiatAmount | decimal(36,18) | NO | - | VERIFIED | Estimated fiat amount the customer will receive, in the target fiat currency (determined by Conversions.FiatId). Calculated as CryptoAmount * CryptoToFiatRate (approximately, with fee adjustments). |
| 4 | UsdAmount | decimal(36,18) | NO | - | VERIFIED | Estimated USD equivalent of the fiat amount. Used as the normalization currency for regulatory limit calculations (GetConversionsUsdSum). When FiatId=1 (USD), equals FiatAmount. |
| 5 | CryptoToUsdRate | decimal(36,18) | NO | - | VERIFIED | Exchange rate from the source crypto asset to USD at conversion creation time. The primary pricing rate. |
| 6 | FiatToUsdRate | decimal(36,18) | NO | - | VERIFIED | Exchange rate from the target fiat currency to USD. When target is USD, this is 1.0. Used to derive the cross-rate: CryptoToFiatRate = CryptoToUsdRate / FiatToUsdRate. |
| 7 | CryptoToFiatRate | decimal(36,18) | NO | - | VERIFIED | Direct exchange rate from source crypto to target fiat. This is the rate shown to the customer. Derived from CryptoToUsdRate / FiatToUsdRate. |
| 8 | Occurred | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when the estimate was recorded. Matches Conversions.Occurred since both are created in the same transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConversionId | C2F.Conversions | Explicit FK | Links estimate to parent conversion (1:1) |

### 5.2 Referenced By (other objects point to this)

No other tables reference this table directly. Multiple SPs JOIN to it.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| C2F.InsertConversion | Stored Procedure | WRITER - creates estimate atomically with conversion |
| C2F.GetConversionAmounts | Stored Procedure | READER - INNER JOIN for estimated USD amounts |
| C2F.GetConversionSummary | Stored Procedure | READER - LEFT JOIN (not directly used in SELECT but JOINed) |
| C2F.GetConversionsUsdSum | Stored Procedure | READER - INNER JOIN for USD sum fallback |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EstimatedFiatTransactions_Id | CLUSTERED | Id ASC | - | - | Active |
| IX_EstimatedFiatTransactions_ConversionId | NC | ConversionId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EstimatedFiatTransactions_Id | PRIMARY KEY | Identity PK |
| FK_C2F_EstimatedFiatTransactions_ConversionId_C2F_Conversions_Id | FOREIGN KEY | ConversionId -> C2F.Conversions.Id |
| Conversion_EstimatedFiatTransactions_Occurred | DEFAULT | GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Compare estimated vs actual fiat amounts
```sql
SELECT c.Id, eft.FiatAmount AS Estimated, ft.FiatAmount AS Actual,
       ft.FiatAmount - eft.FiatAmount AS Difference
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN C2F.EstimatedFiatTransactions eft WITH (NOLOCK) ON eft.ConversionId = c.Id
LEFT JOIN C2F.FiatTransactions ft WITH (NOLOCK) ON ft.ConversionId = c.Id
WHERE ft.Id IS NOT NULL
ORDER BY c.Id DESC
```

### 8.2 Get estimated rates for a conversion
```sql
SELECT eft.CryptoToUsdRate, eft.FiatToUsdRate, eft.CryptoToFiatRate, eft.FiatAmount, eft.UsdAmount
FROM C2F.EstimatedFiatTransactions eft WITH (NOLOCK)
WHERE eft.ConversionId = @ConversionId
```

### 8.3 Best available USD amount (actual if available, else estimated)
```sql
SELECT c.Id,
       CASE WHEN ft.UsdAmount IS NULL THEN eft.UsdAmount ELSE ft.UsdAmount END AS BestUsdAmount
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN C2F.EstimatedFiatTransactions eft WITH (NOLOCK) ON eft.ConversionId = c.Id
LEFT JOIN C2F.FiatTransactions ft WITH (NOLOCK) ON ft.ConversionId = c.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: C2F.EstimatedFiatTransactions | Type: Table | Source: WalletConversionDB/C2F/Tables/C2F.EstimatedFiatTransactions.sql*
