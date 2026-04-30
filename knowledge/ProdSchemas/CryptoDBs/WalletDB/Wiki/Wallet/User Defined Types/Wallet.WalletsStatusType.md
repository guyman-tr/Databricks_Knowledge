# Wallet.WalletsStatusType

> Table-valued parameter type used by AddWalletsStatus to bulk insert wallet pool statuses with optional promotion tag.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`WalletsStatusType` is a table-valued parameter (TVP) type that carries status assignment records for wallets managed within a pool. In the Wallet domain, a wallet pool is a collection of pre-generated wallets that are assigned to customers on demand. Each wallet in the pool has a lifecycle status (e.g., available, assigned, retired) identified by `StatusId`, and may optionally carry a `PromotionTagId` that links it to a marketing or operational promotion.

This type is used by the `AddWalletsStatus` procedure to insert or update the status of multiple pool wallets in a single call. Bulk operations are essential during pool replenishment and wallet lifecycle management events, where hundreds or thousands of wallets may change status simultaneously. The optional `PromotionTagId` allows status transitions to be annotated with a promotion context without requiring a separate pass.

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
| WalletPoolId | bigint | NOT NULL | Surrogate key of the wallet pool entry whose status is being set. |
| StatusId | tinyint | NOT NULL | Status code to assign. References the wallet status lookup table (e.g., 1=Available, 2=Assigned, 3=Retired). |
| PromotionTagId | tinyint | NULL | Optional tag linking this status change to a promotion or campaign. NULL if no promotion applies. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- `Wallet.AddWalletsStatus` — consumes this type to bulk insert or update wallet pool status records.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- `Wallet.AddWalletsStatus`

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

- `WalletPoolId` and `StatusId` are NOT NULL, ensuring that every row identifies a specific pool wallet and the status to assign.
- `PromotionTagId` is nullable, as promotion tagging is optional.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @statuses Wallet.WalletsStatusType;
INSERT INTO @statuses (WalletPoolId, StatusId, PromotionTagId)
VALUES
    (200001, 1, NULL),   -- Available, no promotion
    (200002, 1, 5),      -- Available, promotion tag 5
    (200003, 3, NULL);   -- Retired, no promotion

EXEC Wallet.AddWalletsStatus @WalletStatuses = @statuses;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.WalletsStatusType | Type: UDT*
