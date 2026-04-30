# Dictionary.FiatConversionTargets

> Lookup table defining the three possible fiat destination types for crypto-to-fiat conversions, determining where the converted fiat proceeds are routed after the crypto sell operation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FiatConversionTargets defines where fiat proceeds go when a crypto-to-fiat conversion completes. The three destinations represent fundamentally different customer outcomes: withdrawing to a bank account, crediting their eToro trading balance, or directly funding a trading position. This distinction drives downstream routing logic in the fiat credit step of the conversion pipeline.

Without this table, there would be no canonical definition of target platform types. It serves as the FK target for C2F.Conversions.TargetPlatformId, ensuring every conversion specifies a valid destination.

The table is read-only in normal operations - values are seeded during deployment. The distribution in live data (77% IbanAccount, 17% EtoroPosition, 6% EtoroPlatform) reflects customer preference for bank withdrawals as the primary C2F use case.

---

## 2. Business Logic

### 2.1 Fiat Destination Types

**What**: Three mutually exclusive destinations for fiat proceeds.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- **IbanAccount (1)**: Fiat sent to customer's linked IBAN bank account. Triggers external bank transfer flow. Most common (77% of conversions).
- **EtoroPlatform (2)**: Fiat credited to customer's eToro trading platform balance. Internal transfer only. Least common (6%).
- **EtoroPosition (3)**: Fiat used to open or fund a position on the eToro trading platform. Combines conversion with investment in one flow (17%).
- IbanAccount involves external payment systems and longer settlement times
- EtoroPlatform and EtoroPosition keep funds within the eToro ecosystem (faster, simpler)
- See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target) for glossary entry

---

## 3. Data Overview

| Id | Name | Meaning |
|----|------|---------|
| 1 | IbanAccount | Customer wants to cash out crypto to their bank account. Triggers the external fiat payment flow via the payment system. The Details field in FiatTransactions gets the "C2F..." reference ID for payment tracking. 77% of conversions. |
| 2 | EtoroPlatform | Customer wants crypto proceeds credited to their eToro trading balance. Fastest option - internal ledger transfer. Used when customer plans to reinvest but wants fiat flexibility. 6% of conversions. |
| 3 | EtoroPosition | Customer wants to convert crypto directly into a trading position. Combines conversion + position opening in a single saga flow. Conversion fee may be zero for this path. 17% of conversions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint IDENTITY(1,1) | NO | IDENTITY | VERIFIED | Primary key identifying the fiat destination type. Referenced by C2F.Conversions.TargetPlatformId via explicit FK. Values: 1=IbanAccount, 2=EtoroPlatform, 3=EtoroPosition. See [Fiat Conversion Target](../../_glossary.md#fiat-conversion-target). |
| 2 | Name | varchar(100) | NO | - | VERIFIED | Human-readable label for the target platform. Maps 1:1 with Id values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| C2F.Conversions | TargetPlatformId | Explicit FK | Fiat destination type for each conversion |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | TargetPlatformId FK target |
| C2F.InsertConversion | Stored Procedure | Accepts @TargetPlatformId parameter |
| C2F.GetConversionSummary | Stored Procedure | Returns TargetPlatformId in result set |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatConversionTargets_Id | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FiatConversionTargets_Id | PRIMARY KEY | Identity PK. DATA_COMPRESSION = PAGE. |

---

## 8. Sample Queries

### 8.1 List all fiat conversion targets
```sql
SELECT Id, Name FROM Dictionary.FiatConversionTargets WITH (NOLOCK) ORDER BY Id
```

### 8.2 Conversion count by target platform
```sql
SELECT fct.Id, fct.Name, COUNT(c.Id) AS ConversionCount
FROM Dictionary.FiatConversionTargets fct WITH (NOLOCK)
LEFT JOIN C2F.Conversions c WITH (NOLOCK) ON c.TargetPlatformId = fct.Id
GROUP BY fct.Id, fct.Name
ORDER BY ConversionCount DESC
```

### 8.3 Recent conversions with target platform name
```sql
SELECT TOP 10 c.Id, c.Gcid, fct.Name AS TargetPlatform, c.CryptoAmount, c.Occurred
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN Dictionary.FiatConversionTargets fct WITH (NOLOCK) ON fct.Id = c.TargetPlatformId
ORDER BY c.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FiatConversionTargets | Type: Table | Source: WalletConversionDB/Dictionary/Tables/Dictionary.FiatConversionTargets.sql*
