# dbo.GetCustomerAccountDetails

> Accepts a table-valued parameter of customer IDs and returns each customer's CID, SerialID, and SubSerialID from the Customer.Customer synonym.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Geri Reshef |
| **Created** | 2017-06-13 |

---

## 1. Business Meaning

Certain affiliate platform services (such as the QuesService referenced in the original ticket) need to look up account hierarchy details for a batch of customers -- specifically the SerialID and SubSerialID that identify the customer's account segment within the broader trading platform.

This procedure accepts a table-valued parameter of type CIDs (a user-defined table type containing CID values) and returns the matching account details from Customer.Customer, which is a synonym pointing to the real customer table in the linked trading-platform database.

The batch pattern (TVP instead of scalar input) supports efficient bulk lookups for workflows that process multiple customers in a single call.

---

## 2. Business Logic

### 2.1 Batch CID Lookup

**What**: Returns account hierarchy identifiers for each CID in the supplied batch.

**Columns/Parameters Involved**: `@CIDs`, `Customer.Customer.CID`, `SerialID`, `SubSerialID`

**Rules**:
- Only CIDs that exist in Customer.Customer are returned; unmatched CIDs from the input batch are silently dropped
- The CIDs user-defined table type is passed READONLY; the procedure cannot modify the input
- Customer.Customer is described in comments as a synonym to the "Real" customer table; the actual underlying table resides in the trading-platform database

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @CIDs | IN | dbo.CIDs (READONLY) | (required) | Table-valued parameter containing the list of customer CIDs to look up. Defined by the dbo.CIDs user-defined table type. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| Customer.Customer | SELECT | Synonym to the real customer table in the trading-platform database |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| CID | Customer.Customer | Customer identifier |
| SerialID | Customer.Customer | Top-level account serial identifier in the trading platform |
| SubSerialID | Customer.Customer | Sub-account serial identifier |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCustomerAccountDetails (stored procedure)
+-- dbo.CIDs (user-defined table type) [TVP input]
+-- Customer.Customer (synonym) [SELECT]
    +-- [real customer table in trading-platform database]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.CIDs | User-Defined Table Type | Defines the shape of the TVP input parameter |
| Customer.Customer | Synonym (table) | Source of customer account details |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| QuesService (ticket 45531) | Application Service | Introduced this procedure; calls it to retrieve customer account details for queued customer IDs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- No SET NOCOUNT ON; callers receive rowcount messages
- WITH (NOLOCK) applied to Customer.Customer
- The comment in the source code clarifies that Customer.Customer is a synonym and the underlying table is "Real" (located in the trading-platform database)
- Usage example in source header: DECLARE @Cids AS CIDs; INSERT INTO @Cids VALUES (12345),(123456),(1234567); EXEC GetCustomerAccountDetails @Cids;
- Jira context: ticket 45531 ("[AW] QuesService - new SP dbo.GetCustomerAccountDetails", 2017-06-13, Geri Reshef)

---

## 8. Sample Queries

### 8.1 Look up account details for a batch of customers

```sql
DECLARE @Cids AS dbo.CIDs;
INSERT INTO @Cids VALUES (12345), (123456), (1234567);
EXEC dbo.GetCustomerAccountDetails @CIDs = @Cids;
```

### 8.2 Look up a single customer

```sql
DECLARE @Cids AS dbo.CIDs;
INSERT INTO @Cids VALUES (98765);
EXEC dbo.GetCustomerAccountDetails @CIDs = @Cids;
```

### 8.3 Verify the synonym target

```sql
SELECT * FROM sys.synonyms WHERE name = 'Customer' AND schema_id = SCHEMA_ID('Customer');
```

---

## 9. Atlassian Knowledge Sources

- Ticket 45531 (2017-06-13, Geri Reshef): "[AW] QuesService - new SP dbo.GetCustomerAccountDetails" -- original creation context for this procedure.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10*
*Object: dbo.GetCustomerAccountDetails | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetCustomerAccountDetails.sql*
