# Customer.GetDltData

> Retrieves Distributed Ledger Technology (DLT/blockchain) identification data for a customer - DLT ID, status, and last update date.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DltID, DltStatusID, UpdateDate for a GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetDltData retrieves a customer's Distributed Ledger Technology (DLT) identification record. DLT refers to blockchain-based identity data (e.g., crypto wallet addresses or blockchain account IDs) associated with a customer's account. This is relevant for customers who trade cryptocurrencies and need verified blockchain identities.

This procedure exists to support crypto-trading features that require verified DLT identities. The application calls it when displaying or validating a customer's blockchain credentials.

The procedure performs a simple read from Customer.CustomerIdentification, which stores both traditional (DemoCID) and DLT-related identification data for each customer.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-row read by GCID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID to look up DLT data for. |
| 2 | DltID (output) | varchar | YES | - | CODE-BACKED | The customer's Distributed Ledger Technology identifier (blockchain wallet/account ID). From Customer.CustomerIdentification. |
| 3 | DltStatusID (output) | int | YES | - | CODE-BACKED | Current status of the DLT identity. FK to Dictionary.DltStatus. See [DLT Status](_glossary.md#dlt-status). |
| 4 | UpdateDate (output) | datetime | YES | - | CODE-BACKED | When the DLT record was last updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerIdentification | Lookup | Reads DLT fields from the customer identification table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called when retrieving crypto/DLT identity data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetDltData (procedure)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | FROM - reads DltID, DltStatusID, UpdateDate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get DLT data for a customer
```sql
EXEC Customer.GetDltData @GCID = 12345
```

### 8.2 Direct query equivalent
```sql
SELECT DltID, DltStatusID, UpdateDate
FROM Customer.CustomerIdentification WITH (NOLOCK)
WHERE GCID = @GCID
```

### 8.3 Get DLT data with status name
```sql
SELECT ci.DltID, ci.DltStatusID, ds.Name AS DltStatusName, ci.UpdateDate
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
LEFT JOIN Dictionary.DltStatus ds WITH (NOLOCK) ON ci.DltStatusID = ds.DltStatusID
WHERE ci.GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetDltData | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetDltData.sql*
