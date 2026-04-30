# Customer.SetSpreadGroup

> Updates a customer's spread group assignment on Customer.Customer, controlling the fee/spread tier the customer's trades are subject to.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to update; @SpreadGroupID - the new spread group |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetSpreadGroup assigns a customer to a specific SpreadGroup, which determines the fee structure and bid/ask spread rates applied to their trades. Different spread groups may represent different customer tiers (e.g., VIP, standard, partner-referred), regulatory regions, or promotional pricing structures. SpreadGroupID in Customer.Customer is read by the trading engine to determine pricing when the customer opens or closes positions.

The procedure exists as a dedicated, simple setter for a single field that is managed by account management and compliance tools. Keeping it as a procedure (rather than direct UPDATE) provides a consistent, auditable interface and allows the trading engine to call it without needing direct table access.

Data flow: called from account management systems, back-office tools, or automated customer tier evaluation processes when a customer's pricing group needs to change. No validation is performed - any integer value is accepted; the procedure simply performs the UPDATE and returns @@ERROR.

---

## 2. Business Logic

### 2.1 Direct SpreadGroup Assignment

**What**: A simple setter with no validation - SpreadGroupID is set to whatever the caller provides.

**Columns/Parameters Involved**: `@SpreadGroupID`

**Rules**:
- UPDATE Customer.Customer SET SpreadGroupID = @SpreadGroupID WHERE CID = @CID
- No validation that @SpreadGroupID exists in any lookup table
- Returns @@ERROR (0 on success, non-zero on SQL error)
- SET NOCOUNT ON suppresses row-count messages

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer identifier. The customer whose SpreadGroupID will be updated in Customer.Customer. |
| 2 | @SpreadGroupID | int | NO | - | CODE-BACKED | The spread group to assign to the customer. Controls the fee/spread tier for all trades. No existence validation performed - caller must ensure the value is valid. Stored in Customer.Customer.SpreadGroupID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Modifier | Updates SpreadGroupID for the specified customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from account management or back-office tools |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetSpreadGroup (procedure)
└── Customer.Customer (view - UPDATE target)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target for SpreadGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN @@ERROR | Return value | Returns 0 on success or the SQL error number on failure |

---

## 8. Sample Queries

### 8.1 Assign a customer to spread group 5
```sql
DECLARE @Err INT;
EXEC @Err = Customer.SetSpreadGroup @CID = 12345, @SpreadGroupID = 5;
SELECT @Err AS ErrorCode;
```

### 8.2 Check current spread group for a customer
```sql
SELECT CID, SpreadGroupID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Find all customers in a specific spread group
```sql
SELECT CID, SpreadGroupID
FROM Customer.Customer WITH (NOLOCK)
WHERE SpreadGroupID = 5
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetSpreadGroup | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetSpreadGroup.sql*
