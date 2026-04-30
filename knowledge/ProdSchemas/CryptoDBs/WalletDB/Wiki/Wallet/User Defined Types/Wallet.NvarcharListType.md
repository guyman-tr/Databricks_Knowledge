# Wallet.NvarcharListType

> Generic table-valued parameter type for passing a list of Unicode strings (typically blockchain addresses) to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`NvarcharListType` is a general-purpose table-valued parameter (TVP) type that carries a set of Unicode string values into stored procedures. In the Wallet domain, the primary use case is passing lists of blockchain wallet addresses, which can be arbitrarily formatted strings from various blockchains. By defining the column as `nvarchar(512)`, the type accommodates addresses from Bitcoin, Ethereum, and other networks, including longer bech32 and contract addresses.

Beyond addresses, this type can serve any stored procedure that needs a set of string values — such as external reference codes, tags, or search terms — making it a flexible addition to the schema's generic collection of list types.

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
| Item | nvarchar(512) | NOT NULL | A single Unicode string value, typically a blockchain address or other string identifier. 512 characters accommodates the longest known blockchain address formats. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures in the `Wallet` schema that accept lists of blockchain addresses or other string values, such as address validation, wallet lookup by address, or transaction filtering procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.NvarcharListType`.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

None beyond the NOT NULL constraint on `Item`.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @addresses Wallet.NvarcharListType;
INSERT INTO @addresses (Item)
VALUES (N'1A1zP1eP5QGefi2DMPTfTL5SLmv7Divfna'),  -- Bitcoin genesis address
       (N'0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe'); -- Ethereum address

-- Pass to a stored procedure
EXEC Wallet.GetWalletsByAddresses @Addresses = @addresses;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.NvarcharListType | Type: UDT*
