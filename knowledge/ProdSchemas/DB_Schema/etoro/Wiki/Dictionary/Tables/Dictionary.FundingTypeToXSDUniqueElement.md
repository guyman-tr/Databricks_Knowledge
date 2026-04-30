# Dictionary.FundingTypeToXSDUniqueElement

> Many-to-many mapping table linking payment funding types to their unique XML element paths — defines which XSD field uniquely identifies a payment method within each funding type's XML data structure.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FundingTypeID + XSDUniqueElementID (composite NONCLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK + XSDUniqueElementID NC) |

---

## 1. Business Meaning

Dictionary.FundingTypeToXSDUniqueElement maps each payment funding type (credit card, PayPal, wire transfer, etc.) to the specific XML element path that uniquely identifies a payment method within that funding type's data structure. This is used by the billing system's uniqueness validation — when a customer adds a new payment method, the system needs to know which XML field to check for duplicates.

This table exists because eToro stores payment method details as XML in Billing.Funding. Different funding types have different unique identifiers: credit cards are uniquely identified by their card number, PayPal accounts by email address, and bank accounts by account ID. This mapping tells the Internal.CheckUniqueFundingXMLValue function which XPath to extract when checking for duplicate payment methods.

The table links two Dictionary tables: Dictionary.FundingType (the payment method category) and Dictionary.XSDUniqueElement (the XPath + data type for the unique field). It is consumed by the Internal.CheckUniqueFundingXMLValue function which validates XML uniqueness during payment method registration.

---

## 2. Business Logic

### 2.1 Payment Method Uniqueness by Funding Type

**What**: Each funding type has a designated XML field that uniquely identifies a payment method, preventing duplicate registrations.

**Columns/Parameters Involved**: `FundingTypeID`, `XSDUniqueElementID`

**Rules**:
- FundingTypeID 1 (Credit Card) → XSD element 1: /Funding[1]/CardNumberAsString[1] (VARCHAR) — unique by card number
- FundingTypeID 3 (PayPal) → XSD element 2: /Funding[1]/EmailAsString[1] (VARCHAR) — unique by email
- FundingTypeID 6, 7 (bank transfer types) → XSD element 3: /Funding[1]/AccountIDAsInteger[1] (INTEGER) — unique by account ID
- FundingTypeID 8 → XSD element 2: /Funding[1]/EmailAsString[1] (VARCHAR) — unique by email
- When a customer registers a payment method, the system extracts the value at the mapped XPath from the XML and checks for duplicates

**Diagram**:
```
Funding Type              XSD Unique Element          Meaning
──────────────           ──────────────────          ─────────
Credit Card (1)    ──►   CardNumberAsString (1)      Unique by card number
PayPal (3)         ──►   EmailAsString (2)           Unique by email
Bank Type A (6)    ──►   AccountIDAsInteger (3)      Unique by account ID
Bank Type B (7)    ──►   AccountIDAsInteger (3)      Unique by account ID
Type 8             ──►   EmailAsString (2)           Unique by email
```

---

## 3. Data Overview

| FundingTypeID | XSDUniqueElementID | XPath | Meaning |
|---|---|---|---|
| 1 | 1 | /Funding[1]/CardNumberAsString[1] | Credit card payment methods are uniquely identified by the card number stored as a string in the XML. Prevents duplicate card registrations for the same customer. |
| 3 | 2 | /Funding[1]/EmailAsString[1] | PayPal (and similar email-based) payment methods are uniquely identified by email address. Two accounts with the same email would be treated as duplicates. |
| 6 | 3 | /Funding[1]/AccountIDAsInteger[1] | Bank transfer payment methods are uniquely identified by account ID. Prevents duplicate bank account registrations. |
| 7 | 3 | /Funding[1]/AccountIDAsInteger[1] | Another bank transfer type sharing the same account ID uniqueness path. Multiple funding types can map to the same XSD element. |
| 8 | 2 | /Funding[1]/EmailAsString[1] | Email-based funding type sharing the same email uniqueness path as PayPal. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | VERIFIED | FK to Dictionary.FundingType identifying the payment method category (1=Credit Card, 3=PayPal, 6/7=Bank transfer types, 8=email-based type). Part of composite PK. Determines which payment method category this uniqueness mapping applies to. |
| 2 | XSDUniqueElementID | int | NO | - | VERIFIED | FK to Dictionary.XSDUniqueElement identifying the XPath and data type of the unique field within the funding XML. Part of composite PK. Maps to XPath expressions like /Funding[1]/CardNumberAsString[1] that the system extracts to check for duplicates. (Dictionary.XSDUniqueElement) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| XSDUniqueElementID | Dictionary.XSDUniqueElement | FK | References the XPath definition and data type for the unique field |
| FundingTypeID | Dictionary.FundingType | Implicit Lookup | References the payment method category |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.CheckUniqueFundingXMLValue | FundingTypeID, XSDUniqueElementID | Read (JOIN) | Function reads this mapping to determine which XPath to extract for uniqueness validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (FK to XSDUniqueElement is a simple lookup).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.XSDUniqueElement | Table | FK — provides the XPath and data type definition |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.CheckUniqueFundingXMLValue | Function | JOINs to resolve which XPath to check for each funding type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DF2X | NC PK | FundingTypeID ASC, XSDUniqueElementID ASC | - | - | Active |
| DF2X_PATH | NONCLUSTERED | XSDUniqueElementID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DF2X | PRIMARY KEY | Composite unique key — each funding type + XSD element pair is unique |
| FK_DXSD_DDF2X | FOREIGN KEY | XSDUniqueElementID → Dictionary.XSDUniqueElement.XSDUniqueElementID |

---

## 8. Sample Queries

### 8.1 List all funding type to XSD element mappings
```sql
SELECT  f.FundingTypeID,
        f.XSDUniqueElementID,
        x.Path,
        x.ElementType
FROM    [Dictionary].[FundingTypeToXSDUniqueElement] f WITH (NOLOCK)
JOIN    [Dictionary].[XSDUniqueElement] x WITH (NOLOCK)
        ON f.XSDUniqueElementID = x.XSDUniqueElementID
ORDER BY f.FundingTypeID;
```

### 8.2 Find the uniqueness XPath for a specific funding type
```sql
SELECT  x.Path          AS UniqueXPath,
        x.ElementType   AS DataType
FROM    [Dictionary].[FundingTypeToXSDUniqueElement] f WITH (NOLOCK)
JOIN    [Dictionary].[XSDUniqueElement] x WITH (NOLOCK)
        ON f.XSDUniqueElementID = x.XSDUniqueElementID
WHERE   f.FundingTypeID = @FundingTypeID;
```

### 8.3 Find all funding types sharing the same unique element
```sql
SELECT  f.FundingTypeID,
        x.Path          AS SharedUniqueXPath
FROM    [Dictionary].[FundingTypeToXSDUniqueElement] f WITH (NOLOCK)
JOIN    [Dictionary].[XSDUniqueElement] x WITH (NOLOCK)
        ON f.XSDUniqueElementID = x.XSDUniqueElementID
WHERE   f.XSDUniqueElementID = @XSDUniqueElementID
ORDER BY f.FundingTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FundingTypeToXSDUniqueElement | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FundingTypeToXSDUniqueElement.sql*
