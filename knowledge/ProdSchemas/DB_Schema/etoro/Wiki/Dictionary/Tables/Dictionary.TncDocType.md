# Dictionary.TncDocType

> Classifies Terms & Conditions document types for regulatory compliance across jurisdictions and product lines.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Row Count** | 18 |
| **Indexes** | 1 (clustered PK, FILLFACTOR 95) |

---

## 1. Business Meaning

### What It Is
Dictionary.TncDocType is a lookup table categorizing the types of Terms & Conditions (TnC) and legal documents that customers must accept. Each entry represents a distinct document category required by various regulations and product lines.

### Why It Exists
eToro operates across multiple jurisdictions (EU/MiFID, ASIC, SEC, etc.) and product lines (CFDs, crypto, stocks), each requiring different legal documents. Customers must accept specific document versions based on their regulation and products. This table provides the canonical list of document categories, enabling the BackOffice TnC management system to track which document type each version belongs to.

### How It Works
The `ID` is stored in `BackOffice.TncDocument` alongside document versions, content, and regulation-specific details. Procedures like `BackOffice.InsertTncDocument` create new versions, while `BackOffice.GetAllLatestTncDocuments` and `BackOffice.GetTncDocument` retrieve the current/specific versions for customer acceptance flows.

---

## 2. Business Logic

### Value Map (Complete — 18 rows)

| ID | Name | Business Meaning |
|----|------|------------------|
| 1 | TnC | Core Terms & Conditions — the main client agreement |
| 2 | Privacy Policy | Data privacy and GDPR compliance document |
| 3 | Cookie Policy | Website cookie usage disclosure |
| 4 | Risk Disclosure | Investment risk warnings (MiFID/regulatory requirement) |
| 5 | Product Disclosure Statement | PDS — Australian ASIC requirement for retail clients |
| 6 | Financial Services Guide | FSG — Australian ASIC requirement |
| 7 | Financial Product Terms | Specific product terms and conditions |
| 8 | SEC Add | US SEC regulatory addendum |
| 9 | Crypto Add | Cryptocurrency-specific terms addendum |
| 10 | Best Execution | Order execution policy (MiFID II requirement) |
| 11 | E-sign Policy | Electronic signature consent |
| 12 | Client Agreements | Consolidated client agreement package |
| 13 | Prove US Agreement | US identity verification (Prove) agreement |
| 14 | Tangany Terms and Conditions | Tangany crypto custody provider terms |
| 15 | Tangany Privacy Policy | Tangany crypto custody privacy policy |
| 16 | DLT Terms and Conditions | Distributed Ledger Technology terms |
| 17 | DLT Privacy Policy | DLT-specific privacy policy |
| 18 | Personal Data Protection Notice | Data protection notice (non-EU jurisdictions) |

### Jurisdiction Mapping
- **EU/MiFID**: IDs 1, 2, 4, 10 (core compliance)
- **Australia (ASIC)**: IDs 5, 6 (PDS + FSG required)
- **US (SEC)**: IDs 8, 11, 13 (SEC addendum + E-sign + Prove)
- **Crypto**: IDs 9, 14, 15, 16, 17 (crypto-specific)
- **Global**: IDs 2, 3, 18 (privacy policies)

---

## 3. Data Overview

| ID | Name | Scenario |
|----|------|----------|
| 1 | TnC | New user must accept main terms before first trade |
| 4 | Risk Disclosure | EU customer receives risk warning about CFD losses |
| 5 | Product Disclosure Statement | Australian user presented PDS before deposit |
| 9 | Crypto Add | User enabling crypto wallet must accept crypto terms |
| 14 | Tangany Terms and Conditions | User accepting Tangany custody for crypto assets |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | — | HIGH | Primary key identifying the document type. Sequential 1-18. Referenced by BackOffice.TncDocument. |
| 2 | Name | varchar(64) | YES | — | HIGH | Document type label. Nullable in DDL but populated for all rows. |

---

## 5. Relationships

### Referenced By (Implicit)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| BackOffice.TncDocument | TncDocTypeID | Implicit FK → ID | Links document versions to their type |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| BackOffice.InsertTncDocument | INSERT (into TncDocument) | Creates new document version with type |
| BackOffice.GetAllLatestTncDocuments | SELECT (JOIN) | Gets latest version of each document type |
| BackOffice.GetTncDocument | SELECT (JOIN) | Retrieves specific document by type and version |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `BackOffice.TncDocument` — stores TncDocTypeID per document version

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_TncDocType | CLUSTERED PK | ID ASC | FILLFACTOR 95 |

---

## 8. Sample Queries

```sql
-- Get all TnC document types
SELECT  ID AS TncDocTypeID,
        Name
FROM    Dictionary.TncDocType WITH (NOLOCK)
ORDER BY ID;

-- Get latest version of each document type
SELECT  dt.Name AS DocumentType,
        td.Version,
        td.CreatedDate
FROM    BackOffice.TncDocument td WITH (NOLOCK)
JOIN    Dictionary.TncDocType dt WITH (NOLOCK)
        ON td.TncDocTypeID = dt.ID
WHERE   td.IsLatest = 1
ORDER BY dt.Name;

-- Find crypto-related document types
SELECT  ID, Name
FROM    Dictionary.TncDocType WITH (NOLOCK)
WHERE   Name LIKE '%Crypto%'
   OR   Name LIKE '%DLT%'
   OR   Name LIKE '%Tangany%';
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TncDocType`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.TncDocType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TncDocType.sql*
