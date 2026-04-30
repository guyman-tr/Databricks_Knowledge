# Trade.GetCustomerDataByGCID

> Retrieves basic customer contact information (CID, username, phone, address) by Global Customer ID, used for customer identification across regional systems.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns customer data filtered by GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure looks up a customer by their Global Customer ID (GCID) and returns basic identification and contact information. GCID is the cross-regional identifier used when the same customer exists in multiple trading regions. This procedure bridges the global identity to the local trading system data.

Data flow: Cross-regional service provides a GCID -> procedure queries Customer.CustomerStatic -> returns CID, username, phone, and concatenated address for customer identification.

---

## 2. Business Logic

### 2.1 Address Concatenation

**What**: Combines Address and City fields into a single formatted address string.

**Columns/Parameters Involved**: `Address`, `City`

**Rules**:
- Uses CONCAT(Address, ', ', City) to produce a readable address
- CONCAT handles NULLs gracefully (returns non-NULL parts only)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Global Customer ID. Cross-regional identifier that may map to multiple CIDs across different trading entities. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Local Customer ID in this trading entity. |
| 2 | UserName | VARCHAR | - | - | CODE-BACKED | Customer's platform username. |
| 3 | Phone | VARCHAR | - | - | CODE-BACKED | Customer's phone number on file. |
| 4 | Address | VARCHAR | - | - | CODE-BACKED | Concatenated address: Address + ', ' + City. From Customer.CustomerStatic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerStatic | Read | Looks up customer by Global Customer ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Cross-Regional Services | EXEC | Caller | Customer identification by global ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomerDataByGCID (procedure)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Source of customer data filtered by GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Cross-Regional Services | External | Customer lookup by global ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- May return multiple rows if GCID maps to multiple CIDs (unusual but possible)

---

## 8. Sample Queries

### 8.1 Execute for a specific GCID

```sql
EXEC Trade.GetCustomerDataByGCID @GCID = 54321;
```

### 8.2 Query customer static directly

```sql
SELECT CID, UserName, Phone, CONCAT(Address, ', ', City) AS FullAddress
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE GCID = 54321;
```

### 8.3 Find customers with multiple CIDs per GCID

```sql
SELECT GCID, COUNT(*) AS CIDCount, STRING_AGG(CAST(CID AS VARCHAR), ', ') AS CIDs
FROM Customer.CustomerStatic WITH (NOLOCK)
GROUP BY GCID
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomerDataByGCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomerDataByGCID.sql*
