# Wallet.TransactionOutputsType

> Table-valued parameter type used by StoreSentTransaction to insert multiple transaction outputs with fee and source details in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`TransactionOutputsType` is a rich table-valued parameter (TVP) type that represents the full set of outputs from an outbound cryptocurrency transaction. A blockchain transaction can have multiple outputs — each sending a specific amount to a specific address — and this type captures all the information needed to persist those outputs, including fee attribution and source linkage.

This type is the primary input to the `StoreSentTransaction` procedure, which records a completed send transaction and all its outputs in one atomic operation. The inclusion of eToro-specific fee columns (`EtoroFees`, `IsEtoroFee`) and blockchain fee columns (`BlockchainFees`) reflects the platform's need to track the full economic breakdown of each output, while `SourceId` and `SourceIdType` allow outputs to be linked back to the originating business event (e.g., a withdrawal request or a trade settlement).

---

## 2. Business Logic

N/A for table-valued parameter type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| ToAddress | nvarchar(512) | NOT NULL | Blockchain address of the output recipient. |
| Amount | decimal(36,18) | NOT NULL | Amount of cryptocurrency sent to this address. 18 decimal places for full crypto precision. |
| EtoroFees | decimal(36,18) | NOT NULL | eToro platform fee portion attributed to this output. |
| BlockchainFees | decimal(36,18) | NULL | Miner/network fee attributed to this output. NULL if not split per-output. |
| SourceId | bigint | NULL | Foreign key to the originating business event (e.g., withdrawal ID, trade ID). |
| SourceIdType | tinyint | NULL | Discriminator indicating which entity type `SourceId` refers to (e.g., 1 = Withdrawal, 2 = Settlement). |
| IsEtoroFee | bit | NULL | Flag indicating whether this output row represents an eToro fee collection output rather than a customer-directed payment. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- `Wallet.StoreSentTransaction` — the primary consumer; persists the transaction header and all output rows from this TVP in a single atomic insert.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- `Wallet.StoreSentTransaction`

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

- `ToAddress`, `Amount`, and `EtoroFees` are NOT NULL.
- `BlockchainFees`, `SourceId`, `SourceIdType`, and `IsEtoroFee` are nullable, accommodating scenarios where fee attribution is done at the transaction level rather than per-output, or where source linkage is not applicable.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @outputs Wallet.TransactionOutputsType;
INSERT INTO @outputs
    (ToAddress,                                     Amount,            EtoroFees,         BlockchainFees, SourceId, SourceIdType, IsEtoroFee)
VALUES
    (N'1A1zP1eP5QGefi2DMPTfTL5SLmv7Divfna', 0.004800000000000000, 0.000000000000000000, 0.000100000000000000, 88001, 1, 0),
    (N'1eTorFeeAddressXXXXXXXXXXXXXXXXXXX',  0.000100000000000000, 0.000100000000000000, NULL,                 88001, 1, 1);

EXEC Wallet.StoreSentTransaction
    @TxHash  = N'abc123def456',
    @CryptoId = 1,
    @Outputs = @outputs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.TransactionOutputsType | Type: UDT*
