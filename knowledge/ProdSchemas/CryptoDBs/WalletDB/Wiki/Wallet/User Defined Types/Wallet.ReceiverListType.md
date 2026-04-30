# Wallet.ReceiverListType

> Table-valued parameter type for specifying multiple transaction output destinations with their respective amounts.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`ReceiverListType` is a table-valued parameter (TVP) type used to define the set of recipients for a crypto transaction. Each row pairs a blockchain address (the `Address` field) with the amount of cryptocurrency to send to that address. This reflects the multi-output nature of blockchain transactions, where a single outgoing transaction can simultaneously deliver funds to several recipient addresses.

In the Wallet domain, this type is passed to procedures that construct or record send transactions, allowing the application layer to describe the full output set of a transaction in a single structured call. The use of `decimal(36,18)` for `Amount` provides the extreme precision required by cryptocurrencies like Ethereum, which support up to 18 decimal places (wei).

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
| Address | nvarchar(512) | NOT NULL | Blockchain address of the recipient. Supports all address formats across supported networks. |
| Amount | decimal(36,18) | NOT NULL | Amount of cryptocurrency to send to this address. 18 decimal places supports full Ethereum/ERC-20 precision. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures in the `Wallet` schema that handle the construction or recording of outbound crypto transactions, such as send-transaction procedures that accept a list of output receivers.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.ReceiverListType`.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

Both columns carry NOT NULL constraints, ensuring that every output in the TVP has a valid destination address and a non-null amount.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @receivers Wallet.ReceiverListType;
INSERT INTO @receivers (Address, Amount)
VALUES
    (N'1A1zP1eP5QGefi2DMPTfTL5SLmv7Divfna', 0.005000000000000000),
    (N'1BoatSLRHtKNngkdXEeobR76b53LETtpyT',  0.001500000000000000);

-- Pass to a transaction submission procedure
EXEC Wallet.SubmitSendTransaction
    @CryptoId   = 1,
    @Receivers  = @receivers;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.ReceiverListType | Type: UDT*
