# Trade.GetTotalCash

> Scalar function that returns the TotalCash value from Customer.Customer for a given customer ID (CID). Used for balance and ratio calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Return value (MONEY) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetTotalCash returns the customer's TotalCash—the available cash balance in the customer's account. TotalCash is the primary balance field in Customer.Customer that represents funds available for trading, withdrawals, or copy-trading allocation. This function provides a simple encapsulation of the lookup pattern used across the trading and billing subsystems.

This function exists because multiple procedures need the customer's current cash balance for calculations. Trade.GetEstimatedTreeUnitsByCIDMotiJUNK uses it to compute allocation ratios (Amount / GetTotalCash(CID)) for copy-trade trees. Without it, each caller would repeat the Customer.Customer lookup. Note: Trade.GetTotalCash_View was historically a wrapper that called this function but was later refactored to select TotalCash directly from Customer.Customer—so the view no longer invokes the function.

Data flows: Callers pass @CID. The function selects TotalCash FROM Customer.Customer WHERE CID = @CID and returns it. Returns NULL if no row exists for the CID.

---

## 2. Business Logic

### 2.1 Single-Row Lookup

**What**: Returns the TotalCash column for the matching customer. No aggregation.

**Columns/Parameters Involved**: `@CID`, `TotalCash`

**Rules**:
- One row per CID in Customer.Customer (CID is PK). The function returns that single row's TotalCash.
- If the CID does not exist, the result is NULL (no row returned from subquery).
- TotalCash represents available cash balance in account currency. See Customer.Customer documentation for how TotalCash is maintained.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID (Customer.Customer.CID). The account whose TotalCash is requested. |
| 2 | (return) | money | YES | - | CODE-BACKED | TotalCash from Customer.Customer for the given CID. Available cash balance in account currency. NULL if CID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Implicit | CID used in WHERE to select TotalCash. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetEstimatedTreeUnitsByCIDMotiJUNK | @TotalCash / Ratio | Reader | Uses GetTotalCash(m.CID) to compute Amount/TotalCash ratio for copy-trade trees. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTotalCash (function)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | FROM — SELECT TotalCash WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetEstimatedTreeUnitsByCIDMotiJUNK | Procedure | Calls to compute copy-trade allocation ratios |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get cash balance for a customer
```sql
SELECT Trade.GetTotalCash(12345678) AS TotalCash;
```

### 8.2 Use in ratio calculation (mirroring GetEstimatedTreeUnitsByCIDMotiJUNK)
```sql
SELECT m.CID,
       m.Amount,
       Trade.GetTotalCash(m.CID) AS TotalCash,
       CASE WHEN Trade.GetTotalCash(m.CID) > 0
            THEN CONVERT(DECIMAL(16,4), m.Amount / Trade.GetTotalCash(m.CID))
            ELSE NULL
       END AS Ratio
FROM   Trade.Mirror m WITH (NOLOCK)
WHERE  m.MirrorID = 1;
```

### 8.3 List customers with cash balance
```sql
SELECT c.CID,
       c.UserName,
       Trade.GetTotalCash(c.CID) AS TotalCash
FROM   Customer.Customer c WITH (NOLOCK)
WHERE  c.CID IN (SELECT TOP 10 CID FROM Customer.Customer WITH (NOLOCK))
ORDER BY Trade.GetTotalCash(c.CID) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetTotalCash | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetTotalCash.sql*
