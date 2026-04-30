# Customer.GetExistingCIDS

> Filters a caller-provided XML list of CIDs to return only those that exist in Customer.Customer; used to validate which CIDs from an external batch are active eToro customers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDS (XML list of CIDs to validate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetExistingCIDS takes an XML-encoded list of integer CIDs and returns only those CIDs that exist as active customer records in Customer.Customer. It is a bulk validation utility: callers pass a potentially large list of CIDs and get back only the valid subset.

The procedure is used when an external system has a list of CIDs (from a cache, import, or historical data) and needs to verify which ones correspond to actual eToro accounts before processing them further. The XML input format allows passing large batches in a single stored procedure call without needing a TVP type definition on the caller side.

---

## 2. Business Logic

### 2.1 XML Shredding and Existence Check

**What**: Parses XML CID list, loads into temp table, then inner-joins to Customer.Customer.

**Columns/Parameters Involved**: `@CIDS`, `CID`

**Rules**:
- XML format expected: `<Root><CID>123</CID><CID>456</CID>...</Root>`
- Shredding: @CIDS.nodes('Root/CID') tbl(col) with .value('.', 'INT') extracts each CID value
- Temp table #CIDs holds the parsed values
- INNER JOIN to Customer.Customer: only CIDs existing in both the input XML and Customer.Customer are returned
- Non-existent CIDs (deleted customers, typos) are silently excluded
- No error handling on malformed XML

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDS | XML | NO | - | CODE-BACKED | XML document containing the CIDs to validate. Expected format: `<Root><CID>{int}</CID>...</Root>`. Each `<CID>` element value is parsed as INT. Malformed XML will raise a runtime error. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| CID | Customer.Customer.CID | Integer Customer ID - only CIDs from the input XML that exist in Customer.Customer are returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDS | Customer.Customer | INNER JOIN (existence check) | Validates which CIDs are present in the customer view |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetExistingCIDS (procedure)
└── Customer.Customer (view)
      └── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | INNER JOIN to check CID existence |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XML parsing | Input format | @CIDS must be well-formed XML matching `<Root><CID>int</CID>...</Root>` |
| Temp table #CIDs | Internal | Created per execution, dropped explicitly at end |
| No deduplication | Design | Duplicate CIDs in the input XML could produce duplicate rows in output (INNER JOIN) |

---

## 8. Sample Queries

### 8.1 Check which CIDs from a list exist

```sql
EXEC Customer.GetExistingCIDS @CIDS = '<Root><CID>12345678</CID><CID>23456789</CID><CID>99999999</CID></Root>'
-- Returns only the CIDs that exist in Customer.Customer
```

### 8.2 Build an XML input from a list of CIDs

```sql
DECLARE @xml XML = (
    SELECT CID AS [CID]
    FROM (VALUES (12345678), (23456789), (99999999)) v(CID)
    FOR XML PATH(''), ROOT('Root')
)
EXEC Customer.GetExistingCIDS @CIDS = @xml
```

### 8.3 Direct equivalent without XML

```sql
SELECT CID FROM Customer.Customer WITH (NOLOCK)
WHERE CID IN (12345678, 23456789, 99999999)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetExistingCIDS | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetExistingCIDS.sql*
