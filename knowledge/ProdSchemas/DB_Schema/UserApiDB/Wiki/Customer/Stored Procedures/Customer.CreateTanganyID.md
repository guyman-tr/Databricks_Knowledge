# Customer.CreateTanganyID

> Creates a new Tangany crypto custody wallet ID for a user, or returns the existing one if already provisioned.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (input param), returns TanganyID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.CreateTanganyID provisions a Tangany crypto custody wallet for a user. If the user already has a TanganyID, it returns the existing one (idempotent). If not, it generates a new GUID, sets TanganyStatusID to 1 (Pending), and returns the new ID. Validates that the user exists first, raising an error if GCID is not found.

---

## 2. Business Logic

### 2.1 Idempotent Wallet Provisioning

**What**: Creates wallet only if one doesn't exist; returns existing otherwise.

**Columns/Parameters Involved**: `@GCID`, `TanganyID`, `TanganyStatusID`

**Rules**:
- If GCID not found -> RAISERROR 'User does not exist'
- If TanganyID already exists -> SELECT existing TanganyID and RETURN
- If TanganyID is NULL -> generate NEWID(), UPDATE with TanganyStatusID=1 (Pending), return new ID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID of the user to provision a Tangany wallet for. |
| 2 | TanganyID | uniqueidentifier (OUT) | NO | - | CODE-BACKED | Result set: the Tangany wallet GUID (new or existing). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CustomerIdentification | SELECT/UPDATE | Reads and writes TanganyID, TanganyStatusID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CreateTanganyID (procedure)
  +-- Customer.CustomerIdentification (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | SELECT + UPDATE |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Provision a wallet
```sql
EXEC Customer.CreateTanganyID @GCID = 12345
```

### 8.2 Idempotent call
```sql
-- Second call returns same TanganyID
EXEC Customer.CreateTanganyID @GCID = 12345
EXEC Customer.CreateTanganyID @GCID = 12345
```

### 8.3 Error case
```sql
-- Will raise error if GCID doesn't exist
EXEC Customer.CreateTanganyID @GCID = 999999999
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.CreateTanganyID | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.CreateTanganyID.sql*
