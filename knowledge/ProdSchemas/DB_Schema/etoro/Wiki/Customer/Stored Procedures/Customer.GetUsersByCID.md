# Customer.GetUsersByCID

> Accepts an XML list of CIDs and returns UserName, Email, GCID, and CID for all matching customers from the Customer view - a bulk identity lookup using XML input.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDSXML (XML list of CIDs) -> UserName, Email, GCID, CID from Customer.Customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUsersByCID retrieves the core identity fields (UserName, Email, GCID, CID) for a batch of customers supplied as an XML list of CIDs. The XML is parsed into a temp table (#IDs), which is then JOINed against the Customer.Customer view to produce the result set. This pattern allows a single procedure call to look up multiple customers at once, avoiding N+1 SP calls.

Used by BI administrators (PROD_BIadmins), this procedure is typically used in reporting, compliance, or operational queries where a list of internal CIDs is already known (e.g., from a BI query result, a support ticket list, or an alert) and the corresponding usernames, emails, and GCIDs are needed to complete the picture.

Data flows: The caller constructs an XML document in the format `<Root><CID>123</CID><CID>456</CID></Root>`. The procedure uses XQuery `.nodes()` to shred the XML into individual integer values in a temp table #IDs. The INNER JOIN to Customer.Customer then retrieves the four identity columns for each matched CID. CIDs in the input that do not exist in Customer.Customer are silently dropped (INNER JOIN behavior).

---

## 2. Business Logic

### 2.1 XML Shredding Pattern

**What**: The procedure uses SQL Server's XML nodes() method to parse a CID list from an XML document into a temp table, enabling efficient set-based joining.

**Columns/Parameters Involved**: `@CIDSXML`, `#IDs.ID`

**Rules**:
- Input XML format: `<Root><CID>{int}</CID><CID>{int}</CID>...</Root>`
- `@CIDSXML.nodes('Root/CID') tbl(col)` navigates to each `<CID>` element under `<Root>`
- `.value('.','int')` extracts the text content of each `<CID>` node as an integer
- Results are inserted INTO #IDs temp table with column ID (INT)
- No duplicate removal: if the same CID appears twice in the XML, it will appear twice in #IDs and generate duplicate output rows (no DISTINCT in the final SELECT)
- Invalid CID values (non-integer content) would cause a conversion error at the `.value()` step

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDSXML | xml | NO | - | CODE-BACKED | XML document containing the list of CIDs to look up. Expected format: `<Root><CID>123</CID><CID>456</CID></Root>`. Each `<CID>` element must contain an integer CID value. The number of CIDs in the list is unbounded but should be reasonable for performance (large lists generate large temp tables). |

**Output columns** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserName | varchar | NO | - | VERIFIED | Customer's public platform username. From Customer.Customer view (Customer.CustomerStatic source). The primary human-readable identifier for the customer. |
| 2 | Email | varchar | YES | - | VERIFIED | Customer's registered email address. PII field from Customer.CustomerStatic via Customer.Customer view. Masked by Dynamic Data Masking for unauthorized DB users. Used to identify or contact customers in BI/operational workflows. |
| 3 | GCID | int | YES | - | VERIFIED | Group Customer ID - the cross-product customer identifier from Customer.CustomerStatic. May be NULL for very old accounts predating GCID introduction. Used to link results to external systems and cross-product identities. |
| 4 | CID | int | NO | - | VERIFIED | Internal eToro Customer ID from Customer.Customer view. Echoed from the matched record - matches the input CID values. Used to confirm which input CIDs were found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Parsed CIDs (INNER JOIN) | Customer.Customer | Reader (SELECT) | Batch lookup of identity fields for all supplied CIDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | BI administrators use this for bulk customer identity resolution in reporting and operational workflows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUsersByCID (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | INNER JOIN source for batch CID lookup - returns UserName, Email, GCID, CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Service account | Bulk customer identity lookups for BI and operational reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Note: #IDs temp table has no index - for large CID lists, performance depends on the INNER JOIN optimizer choosing an efficient strategy (hash join or nested loop against the Customer.Customer view).

### 7.2 Constraints

N/A for stored procedure. Note: no SET NOCOUNT ON and no BEGIN...END in this procedure.

---

## 8. Sample Queries

### 8.1 Look up identity data for a list of CIDs via XML
```sql
DECLARE @xml XML = '<Root><CID>12345678</CID><CID>23456789</CID><CID>34567890</CID></Root>';
EXEC Customer.GetUsersByCID @CIDSXML = @xml;
```

### 8.2 Construct XML from a result set for use as input
```sql
-- Build XML from a list of CIDs stored in a table variable
DECLARE @cids TABLE (CID INT);
INSERT @cids VALUES (12345678), (23456789);

DECLARE @xml XML = (
    SELECT CID
    FROM @cids
    FOR XML PATH(''), ROOT('Root'), ELEMENTS
);
EXEC Customer.GetUsersByCID @CIDSXML = @xml;
```

### 8.3 Direct equivalent query for debugging with a small list
```sql
SELECT UserName, Email, GCID, CID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID IN (12345678, 23456789, 34567890);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetUsersByCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetUsersByCID.sql*
