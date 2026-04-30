# Dictionary.XSDUniqueElement

> Lookup table defining the XPath paths and data types of unique XML elements within payment funding data — used to identify and validate specific fields (card number, email, account ID) when checking for duplicate or unique funding records.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | XSDUniqueElementID (INT, manually assigned) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 (1 NC PK + 1 unique NC on Path) |

---

## 1. Business Meaning

Dictionary.XSDUniqueElement defines the specific XML elements within payment funding data that serve as uniqueness identifiers. Payment method data is stored as XML documents (XSD-validated), and this table maps which elements within those documents can uniquely identify a funding source — a credit card number, an email address, or an account ID. The system uses these paths to detect duplicate payment methods and prevent fraud.

Without this table, the payment uniqueness validation system would not know which fields within the XML funding data should be treated as unique identifiers. A customer adding a new payment method must have its key fields checked against existing records — this table tells the system which XML paths to extract and compare.

The table is referenced by Dictionary.FundingTypeToXSDUniqueElement (which maps which unique elements apply to each funding type) and consumed by Internal.CheckUniqueFundingXMLValue (the function that performs the actual uniqueness check by extracting values at these XPath paths from the XML data and comparing them).

---

## 2. Business Logic

### 2.1 XML Element Uniqueness Identification

**What**: Three key fields within payment XML data serve as uniqueness identifiers for duplicate detection.

**Columns/Parameters Involved**: `XSDUniqueElementID`, `Path`, `ElementType`

**Rules**:
- ID 1 — `/Funding[1]/CardNumberAsString[1]` (VARCHAR(MAX)) — the credit/debit card number stored as a string. Used to detect if the same card is registered under multiple accounts or already exists for this customer
- ID 2 — `/Funding[1]/EmailAsString[1]` (VARCHAR(MAX)) — the email address associated with the payment method (e.g., PayPal email). Used to detect duplicate e-wallet registrations
- ID 3 — `/Funding[1]/AccountIDAsInteger[1]` (INTEGER) — a numeric account identifier (e.g., bank account number, payment provider account ID). Used for bank transfer and other account-based payment methods
- Internal.CheckUniqueFundingXMLValue uses XPath `.value('path', 'type')` to extract the value from the XML column at the specified path and compare it against existing records
- Dictionary.FundingTypeToXSDUniqueElement determines which unique elements apply to each funding type (cards use CardNumber, PayPal uses Email, etc.)

**Diagram**:
```
Uniqueness Check Flow:
  Customer adds payment method
       │
       ▼
  Read FundingTypeToXSDUniqueElement
  → Which XML paths are unique for this funding type?
       │
       ├─ Card payment: Path = /Funding[1]/CardNumberAsString[1]
       ├─ PayPal:       Path = /Funding[1]/EmailAsString[1]
       └─ Bank:         Path = /Funding[1]/AccountIDAsInteger[1]
       │
       ▼
  Internal.CheckUniqueFundingXMLValue
  → Extract value at XPath from new XML
  → Compare against existing funding records
  → Duplicate found? Block or warn
```

---

## 3. Data Overview

| XSDUniqueElementID | Path | ElementType | Meaning |
|---|---|---|---|
| 1 | /Funding[1]/CardNumberAsString[1] | VARCHAR(MAX) | XPath to the credit/debit card number within the funding XML. When a customer adds a card, this path is used to extract the card number and check if it's already registered — preventing duplicate card registrations and cross-account card fraud. |
| 2 | /Funding[1]/EmailAsString[1] | VARCHAR(MAX) | XPath to the email address within the funding XML. Used for e-wallet payment methods (PayPal, Skrill) where the email uniquely identifies the account. Prevents the same e-wallet from being linked to multiple platform accounts. |
| 3 | /Funding[1]/AccountIDAsInteger[1] | INTEGER | XPath to a numeric account identifier within the funding XML. Used for bank accounts and other ID-based payment methods. Prevents duplicate bank account registrations across customer accounts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | XSDUniqueElementID | int | NO | - | CODE-BACKED | Unique identifier for the XML element definition: 1=CardNumber, 2=Email, 3=AccountID. Referenced by Dictionary.FundingTypeToXSDUniqueElement (mapping which elements apply to each funding type) and Internal.CheckUniqueFundingXMLValue (the uniqueness check function). |
| 2 | Path | varchar(50) | NO | - | CODE-BACKED | XPath expression pointing to the element within the funding XML document (e.g., `/Funding[1]/CardNumberAsString[1]`). Used in SQL Server's `.value()` XML method to extract the element's value for comparison. Unique constraint (DXSD_PATH) prevents duplicate path definitions. |
| 3 | ElementType | varchar(50) | NO | - | CODE-BACKED | SQL Server data type used when extracting the value via XPath `.value('path', 'type')`. VARCHAR(MAX) for string elements (card numbers, emails), INTEGER for numeric elements (account IDs). Determines the comparison semantics (string vs numeric matching). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.FundingTypeToXSDUniqueElement | XSDUniqueElementID | FK/Implicit | Maps which unique XML elements apply to each funding type |
| Internal.CheckUniqueFundingXMLValue | XSDUniqueElementID | Reader | Uses the Path and ElementType to perform XML-based uniqueness validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.XSDUniqueElement (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingTypeToXSDUniqueElement | Table | FK mapping — which unique elements per funding type |
| Internal.CheckUniqueFundingXMLValue | Function | Reads Path + ElementType for XML value extraction and comparison |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DXSD | NC (PK) | XSDUniqueElementID ASC | - | - | Active |
| DXSD_PATH | NC UNIQUE | Path ASC | - | - | Active |

Note: The PK is NONCLUSTERED, making this a heap with two nonclustered indexes. Unusual but acceptable for a 3-row lookup table.

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all unique element definitions
```sql
SELECT  XSDUniqueElementID,
        Path,
        ElementType
FROM    [Dictionary].[XSDUniqueElement] WITH (NOLOCK)
ORDER BY XSDUniqueElementID;
```

### 8.2 Show which funding types use which unique elements
```sql
SELECT  fte.FundingTypeID,
        xe.Path AS UniqueElementPath,
        xe.ElementType
FROM    [Dictionary].[FundingTypeToXSDUniqueElement] fte WITH (NOLOCK)
JOIN    [Dictionary].[XSDUniqueElement] xe WITH (NOLOCK)
        ON xe.XSDUniqueElementID = fte.XSDUniqueElementID
ORDER BY fte.FundingTypeID, xe.XSDUniqueElementID;
```

### 8.3 Map element IDs to their business purpose
```sql
SELECT  XSDUniqueElementID,
        Path,
        CASE XSDUniqueElementID
            WHEN 1 THEN 'Card number uniqueness'
            WHEN 2 THEN 'E-wallet email uniqueness'
            WHEN 3 THEN 'Bank account ID uniqueness'
        END AS BusinessPurpose
FROM    [Dictionary].[XSDUniqueElement] WITH (NOLOCK)
ORDER BY XSDUniqueElementID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.XSDUniqueElement | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.XSDUniqueElement.sql*
