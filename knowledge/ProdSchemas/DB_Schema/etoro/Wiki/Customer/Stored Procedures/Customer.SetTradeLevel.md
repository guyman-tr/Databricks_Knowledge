# Customer.SetTradeLevel

> Updates a customer's trade level (TradeLevelID) on Customer.Customer, controlling which trading features and instruments the customer is permitted to access.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to update; @TradeLevelID - the new trade level |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetTradeLevel assigns a customer to a TradeLevelID, which governs the trading permissions and product access for the customer. Different trade levels may represent regulatory appropriateness assessments (e.g., a customer who passed the appropriateness test can trade leveraged products), product tier access (e.g., stocks-only vs full portfolio), or risk classification bands. TradeLevelID on Customer.Customer is checked by trading and onboarding flows to gate access to specific products.

The procedure exists as the dedicated setter for TradeLevelID. It is typically called from compliance, onboarding, or account management flows when a customer completes or fails an appropriateness questionnaire or changes regulatory status.

Data flow: called from onboarding/compliance services. No validation is performed on @TradeLevelID - the caller must pass a valid value. Returns @@ERROR.

---

## 2. Business Logic

### 2.1 Direct TradeLevelID Assignment

**What**: A simple setter with no validation - TradeLevelID is set to whatever the caller provides.

**Columns/Parameters Involved**: `@TradeLevelID`

**Rules**:
- UPDATE Customer.Customer SET TradeLevelID = @TradeLevelID WHERE CID = @CID
- No validation that @TradeLevelID exists in any lookup table
- Returns @@ERROR (0 on success, non-zero on SQL error)
- SET NOCOUNT ON suppresses row-count messages

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer identifier. The customer whose TradeLevelID will be updated in Customer.Customer. |
| 2 | @TradeLevelID | int | NO | - | CODE-BACKED | Trade level to assign. Controls which trading products and features the customer may access (e.g., leveraged products, appropriateness tier). No existence validation; caller must provide a valid value. Stored in Customer.Customer.TradeLevelID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Modifier | Updates TradeLevelID for the specified customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from onboarding/compliance services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetTradeLevel (procedure)
└── Customer.Customer (view - UPDATE target)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target for TradeLevelID |

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

### 8.1 Update a customer's trade level after passing appropriateness
```sql
DECLARE @Err INT;
EXEC @Err = Customer.SetTradeLevel @CID = 12345, @TradeLevelID = 3;
SELECT @Err AS ErrorCode;
```

### 8.2 Check current trade level for a customer
```sql
SELECT CID, TradeLevelID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Find all customers at a specific trade level
```sql
SELECT CID, TradeLevelID
FROM Customer.Customer WITH (NOLOCK)
WHERE TradeLevelID = 3
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetTradeLevel | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetTradeLevel.sql*
