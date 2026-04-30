# Wallet.GuidListType

> Generic table-valued parameter type for passing a list of GUIDs (typically wallet IDs) to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`GuidListType` is a general-purpose table-valued parameter (TVP) type that carries a set of `uniqueidentifier` (GUID) values into stored procedures. In the Wallet domain, GUIDs are commonly used as natural keys for wallet entities, provider-assigned identifiers, and external references that must be globally unique. This type provides a schema-standard way to pass lists of such identifiers without requiring per-entity custom types.

Procedures that operate on wallets by their GUID-based keys — such as retrieving wallet details, triggering provider sync, or bulk status updates — can accept this type as a parameter and JOIN directly against it, enabling clean set-based processing.

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
| Item | uniqueidentifier | NOT NULL | A single GUID value, typically a wallet ID or other globally unique identifier. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures in the `Wallet` schema that accept lists of GUID-keyed wallet or entity identifiers, such as bulk wallet retrieval or provider synchronization procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.GuidListType`.

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
DECLARE @walletIds Wallet.GuidListType;
INSERT INTO @walletIds (Item)
VALUES ('A1B2C3D4-E5F6-7890-ABCD-EF1234567890'),
       ('B2C3D4E5-F6A7-8901-BCDE-F12345678901');

-- Pass to a stored procedure
EXEC Wallet.GetWalletsByGuids @WalletIds = @walletIds;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.GuidListType | Type: UDT*
