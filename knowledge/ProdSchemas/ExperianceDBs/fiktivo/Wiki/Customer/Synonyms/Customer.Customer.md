# Customer.Customer

> Synonym that provides local access to the eToro platform's Customer.Customer table via the AO-REAL-DB-ROR linked server, enabling the fiktivo affiliate database to resolve customer details without cross-database references in every query.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Synonym |
| **Key Identifier** | Points to [AO-REAL-DB-ROR].[etoro].[Customer].[Customer] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.Customer is a synonym (database alias) that provides transparent access to the Customer.Customer table on the eToro trading platform's main database. The actual table resides on a separate SQL Server instance accessed via the AO-REAL-DB-ROR linked server. This synonym allows stored procedures in the fiktivo affiliate database to reference customer data using the simple name `Customer.Customer` instead of the fully qualified four-part name `[AO-REAL-DB-ROR].[etoro].[Customer].[Customer]`.

This synonym exists because the affiliate system frequently needs customer information (customer details, account data) that is owned by the eToro trading platform and stored in a separate database on a separate server. Without this synonym, every query needing customer data would require the verbose linked server syntax, making code harder to read and maintain. If the linked server name or target database changes, only the synonym definition needs updating - not every consuming procedure.

The synonym is consumed by reporting and lookup procedures in the fiktivo database, including dbo.SSRS_ICMarketsNetRevenue and dbo.GetCustomerAccountDetails, which need to join affiliate commission data with customer details from the eToro platform.

---

## 2. Business Logic

### 2.1 Linked Server Abstraction

**What**: Abstracts the four-part linked server reference behind a two-part local name.

**Columns/Parameters Involved**: N/A (synonym is a name alias)

**Rules**:
- Target: [AO-REAL-DB-ROR].[etoro].[Customer].[Customer]
- AO-REAL-DB-ROR = linked server name (read-only replica of the eToro production database)
- etoro = target database name on the linked server
- Customer = target schema
- Customer = target table name
- The synonym is fully transparent - any SELECT, JOIN, or subquery using Customer.Customer is redirected to the linked server
- Performance consideration: queries through this synonym involve distributed queries across the linked server connection

---

## 3. Data Overview

N/A for synonym. The underlying table resides on the remote server and contains customer account records from the eToro trading platform.

---

## 4. Elements

N/A for synonym. The synonym inherits all columns from the target table [AO-REAL-DB-ROR].[etoro].[Customer].[Customer]. Key columns likely include CID (customer ID), account details, registration information, and status fields, but the exact schema is defined on the remote server.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (synonym - no own elements) | - | - | - | - | Inherits schema from [AO-REAL-DB-ROR].[etoro].[Customer].[Customer]. Commonly referenced columns: CID (customer identifier used across the affiliate system). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | [AO-REAL-DB-ROR].[etoro].[Customer].[Customer] | Synonym Target | Points to the customer table on the eToro platform's database via linked server |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.SSRS_ICMarketsNetRevenue | - | READ (JOIN) | Joins customer data for IC Markets net revenue reporting |
| dbo.GetCustomerAccountDetails | - | READ | Retrieves customer account details for the affiliate system |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Customer (synonym)
+-- [AO-REAL-DB-ROR].[etoro].[Customer].[Customer] (remote table via linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB-ROR].[etoro].[Customer].[Customer] | Remote Table (Linked Server) | Synonym target - all queries are redirected here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.SSRS_ICMarketsNetRevenue | Stored Procedure | Reads customer data for reporting |
| dbo.GetCustomerAccountDetails | Stored Procedure | Reads customer account details |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym. Indexes exist on the remote target table.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Linked Server Dependency | Infrastructure | Requires AO-REAL-DB-ROR linked server to be configured and accessible |

---

## 8. Sample Queries

### 8.1 Basic customer lookup via synonym
```sql
SELECT TOP 5 *
FROM Customer.Customer WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name
FROM sys.synonyms
WHERE schema_id = SCHEMA_ID('Customer') AND name = 'Customer'
```

### 8.3 Check linked server connectivity
```sql
EXEC sp_testlinkedserver N'AO-REAL-DB-ROR'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 consumers identified | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.Customer | Type: Synonym | Source: fiktivo/Customer/Synonyms/Customer.Customer.sql*
