# Trade.GetGCIDByCID

> Simple lookup that returns GCID (Global Customer ID) for a given CID. Reads from Customer.Customer table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | GCID (single column result) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs a simple CID-to-GCID lookup. CID (Customer ID) is the internal numeric identifier; GCID (Global Customer ID) is the cross-system identifier used for integrations, external APIs, and identity federation. The procedure returns the GCID corresponding to a given CID.

The procedure exists to provide a lightweight way to resolve GCID from CID without querying Customer.Customer directly. Integrations and services that receive CID but need GCID for external calls use this.

Data flow: caller passes @CID, procedure reads Customer.Customer, returns the GCID column. At most one row is returned.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-row lookup by CID. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Primary key of Customer.Customer. Filters to this customer. |
| 2 | GCID | VARCHAR/GUID | NO | - | CODE-BACKED | Output. Global Customer ID. Cross-system identifier used for external integrations and identity federation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.Customer | FROM | Source of GCID by CID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetGCIDByCID (procedure)
+-- Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | FROM - GCID lookup by CID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute for a customer

```sql
EXEC Trade.GetGCIDByCID @CID = 12345;
```

### 8.2 Use result in a variable

```sql
DECLARE @GCID VARCHAR(50);
-- If procedure returns result set, capture via INSERT...EXEC or similar
EXEC Trade.GetGCIDByCID @CID = 12345;
```

### 8.3 Query source table directly

```sql
SELECT GCID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetGCIDByCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetGCIDByCID.sql*
