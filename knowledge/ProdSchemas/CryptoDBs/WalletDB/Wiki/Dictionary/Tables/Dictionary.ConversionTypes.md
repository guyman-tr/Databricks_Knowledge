# Dictionary.ConversionTypes

> Lookup table defining the pricing models for cryptocurrency conversion (swap) operations - whether the source or target amount is fixed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines how the exchange rate is applied during a crypto-to-crypto conversion. When a customer swaps one cryptocurrency for another, they can either fix the amount they send (FixedFrom) or fix the amount they receive (FixedTo). This is a common pattern in cryptocurrency exchange platforms.

The conversion type determines which side of the swap bears the exchange rate variance. This directly affects the customer experience and the platform's hedging strategy during the conversion execution window.

The table is FK-referenced by `Wallet.Conversions` and consumed by conversion transaction functions.

---

## 2. Business Logic

### 2.1 Fixed-Side Pricing Model

**What**: Determines which cryptocurrency amount is guaranteed in a conversion.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `FixedFrom` (1): The source amount is fixed. Customer specifies exactly how much of the source crypto to sell. The received amount of the target crypto varies based on the exchange rate at execution time.
- `FixedTo` (2): The target amount is fixed. Customer specifies exactly how much of the target crypto they want to receive. The deducted amount of the source crypto varies based on the exchange rate.

**Diagram**:
```
FixedFrom (1):  "Sell exactly 1.0 BTC" --> Receive ~15.2 ETH (varies with rate)
FixedTo (2):    "Buy exactly 15.0 ETH" --> Spend ~0.99 BTC (varies with rate)
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | FixedFrom | The source cryptocurrency amount is fixed by the customer. Example: "Convert exactly 1 BTC to ETH" - the customer knows exactly how much BTC they will spend, but the ETH received depends on the rate at execution. Simpler for customers who want to sell a specific amount. |
| 2 | FixedTo | The target cryptocurrency amount is fixed by the customer. Example: "Convert BTC to get exactly 15 ETH" - the customer knows exactly how much ETH they will receive, but the BTC spent depends on the rate. Useful when the customer needs a specific amount of the target asset. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the conversion type. Values: 1=FixedFrom (source amount fixed), 2=FixedTo (target amount fixed). FK target for Wallet.Conversions.ConversionTypeId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Label describing the pricing model. Used in conversion execution logic to determine which side of the swap is guaranteed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.Conversions | ConversionTypeId | FK | Each conversion records which pricing model was used |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Conversions | Table | FK on ConversionTypeId |
| Wallet.GetConversionTransactionList | Function | JOINs for conversion reporting |
| Wallet.GetConversionTransactionListV2 | Function | JOINs for conversion reporting (v2) |
| Wallet.GetConversionTransactionList_temp | Function | JOINs for conversion reporting (temp) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ConversionTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List conversion types
```sql
SELECT Id, Name FROM Dictionary.ConversionTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Conversion distribution by type
```sql
SELECT ct.Name AS ConversionType, COUNT(*) AS Count
FROM Wallet.Conversions c WITH (NOLOCK)
JOIN Dictionary.ConversionTypes ct WITH (NOLOCK) ON c.ConversionTypeId = ct.Id
GROUP BY ct.Name
```

### 8.3 Recent conversions with type and status
```sql
SELECT c.ConversionId, ct.Name AS Type, cs.Name AS Status, c.Created
FROM Wallet.Conversions c WITH (NOLOCK)
JOIN Dictionary.ConversionTypes ct WITH (NOLOCK) ON c.ConversionTypeId = ct.Id
JOIN Dictionary.ConversionStatuses cs WITH (NOLOCK) ON c.ConversionStatusId = cs.Id
ORDER BY c.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ConversionTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ConversionTypes.sql*
