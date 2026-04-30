# Customer.GetFinancialDataByCIDs

> Batch-retrieves balance (Credit) and realized equity for a list of CIDs using the Trade.CidList TVP; used by the trading execution layer to check customer financial state.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDs (Trade.CidList TVP - batch of CIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetFinancialDataByCIDs retrieves the financial snapshot (balance and equity) for a batch of customers in a single query. It accepts a table-valued parameter of type Trade.CidList (defined in the Trade schema) and returns Credit (account balance) and RealizedEquity for each matching CID.

The procedure is designed for the trading execution layer, which needs to check customer financial state for multiple CIDs simultaneously (e.g., during batch position processing, margin checks, or trade validations). Using a TVP avoids the N+1 query problem of looking up each customer individually.

The use of Trade.CidList (not a Customer schema type) indicates this was built to integrate with the Trade schema's execution flow, where CID lists are a common pattern.

---

## 2. Business Logic

### 2.1 Batch Credit and Equity Retrieval

**What**: Efficient set-based retrieval of financial state for multiple customers.

**Columns/Parameters Involved**: `@CIDs`, `Credit`, `RealizedEquity`, `CID`

**Rules**:
- INNER JOIN between Customer.Customer and @CIDs TVP on CID
- DISTINCT: removes duplicate rows if Customer.Customer could return multiple rows per CID (defensive)
- Credit: current account balance from Customer.Customer
- RealizedEquity: computed column from Customer.Customer (balance + open position PnL, calculated in the view)
- CIDs not found in Customer.Customer are silently excluded

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | Trade.CidList | NO | - | CODE-BACKED | Table-valued parameter (READONLY) from the Trade schema. Contains CID values to look up. Defined in the Trade schema as a UDT with a CID column. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| Credit | Customer.Customer.Credit | Customer's current account balance (the cash portion, excluding unrealized PnL). Stored in cents or dollars depending on currency. |
| RealizedEquity | Customer.Customer.RealizedEquity | Customer's total account value including open position PnL. Computed column in Customer.Customer view. |
| CID | Customer.Customer.CID | Customer ID - links the financial data back to the input CID list. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDs | Trade.CidList | TVP type definition | Input type from Trade schema |
| CID | Customer.Customer | INNER JOIN (read) | Source of Credit and RealizedEquity |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (called by Trade/execution services).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetFinancialDataByCIDs (procedure)
├── Trade.CidList (user defined type - cross-schema)
└── Customer.Customer (view)
      └── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CidList | User Defined Type | TVP parameter type (cross-schema) |
| Customer.Customer | View | Source of Credit and RealizedEquity fields |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READONLY TVP | Parameter | @CIDs cannot be modified within the procedure |
| DISTINCT | Deduplication | Defensive against possible view row duplication |
| Cross-schema TVP | Dependency | Requires EXECUTE permission on Trade.CidList type |

---

## 8. Sample Queries

### 8.1 Get financial data for a batch of customers

```sql
DECLARE @cids Trade.CidList
INSERT INTO @cids VALUES (12345678), (23456789)
EXEC Customer.GetFinancialDataByCIDs @CIDs = @cids
```

### 8.2 Direct query equivalent

```sql
SELECT DISTINCT Credit, RealizedEquity, CID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID IN (12345678, 23456789)
```

### 8.3 Check Credit and RealizedEquity for a customer

```sql
SELECT Credit, RealizedEquity, CID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 6/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetFinancialDataByCIDs | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetFinancialDataByCIDs.sql*
