# Dictionary.RequestTypes

> Lookup table classifying the types of wallet operations that can be requested, from wallet creation to staking to crypto-to-position conversions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the types of operations that can be submitted as wallet requests. Every action in the wallet system - creating a wallet, sending crypto, initiating a payment, redeeming, converting, funding, staking, or receiving - is classified using one of these types. The request type determines which processing pipeline handles the operation.

The table is FK-referenced by `Wallet.Requests` which is the central request tracking table for all wallet operations.

---

## 2. Business Logic

### 2.1 Operation Type Classification

**What**: Ten operation types covering all wallet request categories.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `CreateWallet` (0): Create a new blockchain wallet/address for a customer
- `SendTransaction` (1): Send cryptocurrency to an external address (withdrawal)
- `InitiatePayment` (2): Start a fiat payment operation
- `Redeem` (3): Sell/redeem crypto position back to fiat
- `Conversion` (4): Convert one crypto to another (crypto-to-crypto swap)
- `Funding` (5): Fund a wallet from the omnibus/hot wallet
- `Staking` (6): Delegate crypto for staking rewards
- `ConversionToFiat` (7): Convert crypto directly to fiat currency (off-ramp)
- `ReceiveTransaction` (8): Process an incoming crypto deposit
- `ConversionToPosition` (9): Convert crypto into a trading position

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | CreateWallet | Request to create a new blockchain wallet address for a customer. Allocates an address from the pool or generates a new one. First step before any crypto operations. |
| 1 | SendTransaction | Request to send cryptocurrency to an external address. The core withdrawal flow - includes balance checks, AML screening, and blockchain submission. |
| 3 | Redeem | Request to sell a crypto position and convert proceeds to fiat. Involves price execution, position closure, and settlement. |
| 4 | Conversion | Request to swap one cryptocurrency for another. Both legs (sell source, buy target) are managed as a single atomic operation. |
| 9 | ConversionToPosition | Request to convert crypto holdings into a trading position. Newest type (Id=9), supporting the crypto-to-position product feature. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the request type. Values: 0=CreateWallet, 1=SendTransaction, 2=InitiatePayment, 3=Redeem, 4=Conversion, 5=Funding, 6=Staking, 7=ConversionToFiat, 8=ReceiveTransaction, 9=ConversionToPosition. FK target for Wallet.Requests.RequestTypeId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | PascalCase label mapping to application-layer enum. Determines which processing pipeline handles the request. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.Requests | RequestTypeId | FK | Classifies each wallet request by operation type |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FK on RequestTypeId |
| Wallet.GetPeriodicSentAmounts | Stored Procedure | Filters by request type for periodic reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RequestTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all request types
```sql
SELECT Id, Name FROM Dictionary.RequestTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count requests by type
```sql
SELECT rt.Name, COUNT(r.RequestId) AS Count
FROM Dictionary.RequestTypes rt WITH (NOLOCK)
LEFT JOIN Wallet.Requests r WITH (NOLOCK) ON r.RequestTypeId = rt.Id
GROUP BY rt.Name ORDER BY Count DESC
```

### 8.3 Recent requests with type and status
```sql
SELECT r.RequestId, rt.Name AS RequestType, r.Created
FROM Wallet.Requests r WITH (NOLOCK)
JOIN Dictionary.RequestTypes rt WITH (NOLOCK) ON r.RequestTypeId = rt.Id
ORDER BY r.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RequestTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.RequestTypes.sql*
