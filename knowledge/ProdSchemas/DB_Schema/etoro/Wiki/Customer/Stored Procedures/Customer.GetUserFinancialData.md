# Customer.GetUserFinancialData

> Returns the Credit balance and RealizedEquity for a single customer from the Customer view, providing a lightweight financial snapshot by CID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID -> Credit, RealizedEquity from Customer.Customer view |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUserFinancialData retrieves the two core financial balance fields - Credit and RealizedEquity - for a customer identified by CID. These fields come from the Customer.Customer view (which surfaces Customer.CustomerMoney data). The procedure provides a lightweight, focused financial lookup for services that need only these two values without the full 86-column Customer record.

Called by BI administrators (PROD_BIadmins permission), this procedure is used in reporting and analytics contexts to pull the credit and realized equity balance for a specific customer - for example, for individual account analysis, support investigations, or BI dashboards.

Data flows: Customer.CustomerMoney stores Credit and RealizedEquity. These are surfaced via the Customer.Customer view (LEFT JOIN of CustomerStatic + CustomerMoney). Various SetBalance procedures update RealizedEquity when positions open/close, and CreditEdit updates Credit. Both fields can be NULL if a CustomerMoney row does not exist for the CID (rare in practice).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Internal eToro Customer ID. Applied as WHERE CID = @CID in the Customer.Customer view query. |

**Output columns** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Credit | money | YES | - | VERIFIED | The customer's current credit (bonus/promotional credit) balance from Customer.CustomerMoney, surfaced via Customer.Customer view. Credit is deposited by CreditEdit and consumed by trading activity. NULL if no CustomerMoney row exists for the CID (rare). See Customer.CustomerMoney.Credit. |
| 2 | RealizedEquity | money | YES | - | VERIFIED | The customer's realized account equity from Customer.CustomerMoney, representing the net settled balance (deposits minus withdrawals plus realized P&L). Updated by SetBalance procedures on position close, deposit, withdrawal, and fee events. NULL if no CustomerMoney row exists. See Customer.CustomerMoney.RealizedEquity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Reader (SELECT via view) | Point lookup by CID against the unified customer view; Credit and RealizedEquity originate from Customer.CustomerMoney |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | BI administrators use this for financial data lookups and reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUserFinancialData (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT source - filtered by CID, returns Credit and RealizedEquity (from CustomerMoney side of the view) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Service account | BI reporting - financial balance lookups per customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: no SET NOCOUNT ON and no BEGIN...END block in this procedure - minimal boilerplate pattern.

---

## 8. Sample Queries

### 8.1 Get financial data for a customer
```sql
EXEC Customer.GetUserFinancialData @CID = 12345678;
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT Credit, RealizedEquity
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678;
```

### 8.3 Trace to base table for the same data
```sql
SELECT cm.Credit, cm.RealizedEquity
FROM Customer.CustomerMoney cm WITH (NOLOCK)
WHERE cm.CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetUserFinancialData | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetUserFinancialData.sql*
