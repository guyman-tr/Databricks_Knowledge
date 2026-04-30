# Wallet.RedemptionIds

> Table-valued parameter type for passing a list of redemption IDs to stored procedures for bulk status updates.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`RedemptionIds` is a table-valued parameter (TVP) type used to supply a set of redemption record identifiers to stored procedures. In the Wallet domain, a redemption represents a customer request to convert or withdraw cryptocurrency — for example, cashing out crypto to fiat. Each redemption is assigned a `bigint` surrogate key (`Id`) that uniquely identifies the redemption record.

This type is used primarily by bulk status update procedures, which need to mark multiple redemptions as processed, failed, or completed in a single operation. Passing all affected IDs as a TVP avoids row-by-row processing and reduces round-trips between the application and database layers, which is important when processing large batches of redemptions during settlement runs.

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
| Id | bigint | NOT NULL | Surrogate primary key of a redemption record. Matches the `Id` column on the redemption storage table. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures in the `Wallet` schema that perform bulk status updates on redemption records, such as procedures that mark a batch of redemptions as settled or failed.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.RedemptionIds`.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

None beyond the NOT NULL constraint on `Id`.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @redemptions Wallet.RedemptionIds;
INSERT INTO @redemptions (Id) VALUES (5000001), (5000002), (5000003);

-- Pass to a bulk status update procedure
EXEC Wallet.UpdateRedemptionStatusBulk
    @RedemptionIds = @redemptions,
    @StatusId      = 3; -- e.g. Completed
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.RedemptionIds | Type: UDT*
