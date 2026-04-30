# BackOffice.UpdateUserDocumentStatus

> Focused single-field update: sets DocumentStatusID on BackOffice.Customer for a customer identified by GCID, returning the rows affected count.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - routes via Customer.Customer JOIN to BackOffice.Customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateUserDocumentStatus` is a minimal, single-purpose SP for updating a customer's KYC document verification status. It accepts a GCID and a document status ID, and writes only the `DocumentStatusID` field on `BackOffice.Customer`.

The SP exists as a dedicated thin wrapper rather than requiring callers to use the full `BackOffice.UpdateRiskUserInfo` (20 parameters) when only the document status needs to change. It is likely called from compliance automation or document processing workflows that have determined a verification outcome and need to record it without touching other risk fields.

The GCID routing uses a JOIN through `Customer.Customer` (the view over CustomerStatic), which resolves GCID to CID in-query.

---

## 2. Business Logic

### 2.1 Single-Field DocumentStatus Update

**What**: Updates only `BackOffice.Customer.DocumentStatusID` for the given GCID.

**Columns/Parameters Involved**: `@gcid`, `@documentStatusId`, `BackOffice.Customer.DocumentStatusID`

**Rules**:
- No ISNULL guard - @documentStatusId is applied directly, including NULL (which would clear the existing value).
- Routing: `BackOffice.Customer bc JOIN Customer.Customer cc ON bc.CID = cc.CID WHERE cc.GCID = @gcid`.
- Returns the rows affected count via `SELECT @rowAffected AS RowsAffected` (not an OUTPUT parameter).
- Returns 0 rows affected if GCID is not found in Customer.Customer.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. Used to identify the customer via JOIN Customer.Customer WHERE GCID=@gcid. Routes to BackOffice.Customer.CID. |
| 2 | @documentStatusId | int | NO | - | CODE-BACKED | New KYC document verification status (maps to BackOffice.Customer.DocumentStatusID). Set directly - NULL would clear the existing value. Reflects the outcome of the document review process. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.Customer | JOIN source (GCID lookup) | Resolves GCID to CID for BackOffice.Customer update |
| @documentStatusId | [BackOffice.Customer](../Tables/BackOffice.Customer.md) | UPDATE target | Sets DocumentStatusID WHERE CID from GCID JOIN |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from document processing workflows and compliance automation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateUserDocumentStatus (procedure)
+-- Customer.Customer (view) [JOIN: GCID -> CID bridge]
+-- BackOffice.Customer (table) [UPDATE target: DocumentStatusID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | JOIN ON bc.CID = cc.CID WHERE cc.GCID = @gcid (GCID resolution) |
| [BackOffice.Customer](../Tables/BackOffice.Customer.md) | Table | UPDATE target - sets DocumentStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from document processing and compliance services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No TRY/CATCH, no transaction. Uses simple UPDATE ... FROM ... JOIN pattern.

---

## 8. Sample Queries

### 8.1 Set document status to approved for a customer

```sql
EXEC BackOffice.UpdateUserDocumentStatus
    @gcid            = 98765,
    @documentStatusId = 3;  -- e.g., 3 = Approved
-- Returns: RowsAffected = 1 (if GCID found)
```

### 8.2 Check DocumentStatusID values available

```sql
SELECT DocumentStatusID, Name
FROM Dictionary.DocumentStatus WITH (NOLOCK)
ORDER BY DocumentStatusID;
```

### 8.3 Verify the update

```sql
SELECT bc.DocumentStatusID
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON bc.CID = cc.CID
WHERE cc.GCID = 98765;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateUserDocumentStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateUserDocumentStatus.sql*
