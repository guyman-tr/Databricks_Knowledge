# BackOffice.GetUserDocumentStatus

> Returns the document verification status ID for a customer identified by GCID - a minimal lookup used by systems needing to check KYC document completeness by global ID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (required); returns BackOffice.Customer.DocumentStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetUserDocumentStatus` is a lightweight lookup that returns the `DocumentStatusID` for a customer identified by their GCID (Global Customer ID). It bridges the GCID-based identity system (used by authentication and cross-system services) to the BackOffice document status, allowing callers that only know a GCID to retrieve the customer's KYC document verification state without knowing the internal CID.

The raw integer `DocumentStatusID` is returned without joining to Dictionary.DocumentStatus for the name - the caller is expected to interpret the ID or do their own lookup.

---

## 2. Business Logic

### 2.1 GCID to DocumentStatusID Lookup

**What**: Returns the document verification status for a customer found by GCID.

**Columns/Parameters Involved**: `@gcid`, `Customer.Customer.GCID`, `BackOffice.Customer.DocumentStatusID`

**Rules**:
- JOIN Customer.Customer ON CID to resolve GCID -> CID -> BackOffice.Customer
- WHERE Customer.Customer.GCID = @gcid
- Returns DocumentStatusID (raw integer) from BackOffice.Customer
- No join to Dictionary.DocumentStatus - returns ID not name

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Global Customer ID (GCID) to look up document status for. Note: the parameter is typed INT but GCID is typically a UNIQUEIDENTIFIER - this procedure may only work for numeric GCIDs or there may be an implicit conversion. Required. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentStatusID | INT | YES | - | CODE-BACKED | Numeric document verification status (BackOffice.Customer.DocumentStatusID). Raw ID - join Dictionary.DocumentStatus for name. Common values include statuses like NotUploaded, Pending, Approved, Rejected. NULL if no BackOffice.Customer record found. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| cc.GCID = @gcid | Customer.Customer | Read (WHERE filter) | GCID resolution |
| bc.CID = cc.CID | BackOffice.Customer | JOIN | DocumentStatusID source |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Cross-system callers) | @gcid | Application | Called by systems that have GCID but need document status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUserDocumentStatus (procedure)
├── BackOffice.Customer (table)
└── Customer.Customer (table) - GCID bridge
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | DocumentStatusID source |
| Customer.Customer | Table | JOIN to resolve GCID -> CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by application services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @gcid INT type | Implementation | GCID in Customer.Customer is UNIQUEIDENTIFIER but parameter is INT. This procedure likely uses a numeric GCID variant or there is an implicit conversion. Callers should verify the correct GCID format before calling. |
| No WITH(NOLOCK) omission | Implementation | BackOffice.Customer uses WITH(NOLOCK); Customer.Customer uses WITH(NOLOCK) - both dirty read allowed for this lightweight status check. |

---

## 8. Sample Queries

### 8.1 Get document status by GCID
```sql
EXEC BackOffice.[GetUserDocumentStatus] @gcid = 12345
```

### 8.2 Get document status name (with dictionary join)
```sql
SELECT bc.DocumentStatusID, dd.DocumentStatusName
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = bc.CID
LEFT JOIN Dictionary.DocumentStatus dd WITH (NOLOCK) ON dd.DocumentStatusID = bc.DocumentStatusID
WHERE cc.GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 7.5/10, Logic: 7.5/10, Relationships: 7.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUserDocumentStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetUserDocumentStatus.sql*
