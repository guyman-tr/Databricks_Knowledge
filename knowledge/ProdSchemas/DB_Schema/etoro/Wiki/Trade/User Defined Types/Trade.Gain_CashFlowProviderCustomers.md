# Trade.Gain_CashFlowProviderCustomers

> TVP for the Gain integration: customer IDs with minimum date for cashflow loading.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.Gain_CashFlowProviderCustomers is a table-valued parameter used by the Gain (cashflow provider) integration. It passes a list of customer IDs together with a minimum date per customer, indicating from when cashflows should be loaded. The type is consumed by Trade.Gain_LoadCashflows via the parameter @customers.

The Gain_ prefix identifies this type as belonging to the external cashflow or payment provider integration. CID references the customer; MinDate is the earliest datetime from which cashflows are to be fetched for that customer. This supports selective, date-bounded cashflow loading rather than full history reloads.

---

## 2. Business Logic

### 2.1 Cashflow Load Scope
**What**: Defines which customers to load cashflows for and the starting date per customer.
**Columns/Parameters Involved**: CID, MinDate.
**Rules**: Both columns NOT NULL. CID references customer; MinDate is the lower bound for cashflow date range. Trade.Gain_LoadCashflows uses this to drive the cashflow load process.

---

## 3. Data Overview
N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements
| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NOT NULL | - | High | Customer ID |
| 2 | MinDate | datetime | NOT NULL | - | High | Earliest date from which to load cashflows |

---

## 5. Relationships
### 5.1 References To
Customer (via CID)
### 5.2 Referenced By
Trade.Gain_LoadCashflows (parameter @customers)

---

## 6. Dependencies
### 6.0 Dependency Chain
This object has no dependencies.
### 6.1 Objects This Depends On
No dependencies.
### 6.2 Objects That Depend On This
Trade.Gain_LoadCashflows

---

## 7. Technical Details
### 7.1 Indexes
None.
### 7.2 Constraints
None.

---

## 8. Sample Queries
### 8.1 Load Cashflows for Single Customer
```sql
DECLARE @customers Trade.Gain_CashFlowProviderCustomers;
INSERT INTO @customers (CID, MinDate)
VALUES (12345, '2025-01-01');
EXEC Trade.Gain_LoadCashflows @customers = @customers;
```
### 8.2 Batch Load for Multiple Customers
```sql
DECLARE @customers Trade.Gain_CashFlowProviderCustomers;
INSERT INTO @customers (CID, MinDate)
VALUES (1001, '2025-01-01'), (1002, '2025-02-15'), (1003, '2025-03-01');
EXEC Trade.Gain_LoadCashflows @customers = @customers;
```
### 8.3 Populate from Staging
```sql
DECLARE @customers Trade.Gain_CashFlowProviderCustomers;
INSERT INTO @customers (CID, MinDate)
SELECT CustomerID, MIN(CashflowDate) FROM #StagingCashflows GROUP BY CustomerID;
EXEC Trade.Gain_LoadCashflows @customers = @customers;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_CashFlowProviderCustomers | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Gain_CashFlowProviderCustomers.sql*
