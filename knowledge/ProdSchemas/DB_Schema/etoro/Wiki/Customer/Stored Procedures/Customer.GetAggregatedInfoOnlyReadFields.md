# Customer.GetAggregatedInfoOnlyReadFields

> Batch KYC document status reader: accepts a list of CIDs or GCIDs, resolves identity, and returns each customer's classified document types, plus utility and passport document presence, expiry state, and document type for each - used by the UserSyncAPI to include KYC status in user data sync operations.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ids (IDIntList TVP of CIDs or GCIDs), @isGcid (lookup mode) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAggregatedInfoOnlyReadFields is a batch KYC document status query procedure. It accepts a list of customer identifiers (either CIDs or GCIDs), resolves them to the canonical (CID, GCID) pair, and returns each customer's KYC verification document state in a normalized form that includes: which document types have been classified, whether the customer has a utility (address proof) document, whether they have a passport/ID document, and expiry state for each.

The procedure exists to serve the UserSyncAPI service (GRANT EXECUTE to `SQL_UserSyncAPI`). When user data is synced externally (e.g., to Salesforce or external compliance systems), the sync payload needs to include KYC document state alongside identity and CRM data. The "OnlyReadFields" in the name signals this is a read-only query (no DML), returning fields safe for external consumers.

The document logic distinguishes two document kinds: "utility" (address proof: newkyc-bill, newkyc-ie-bill) and "passport" (identity proof: newkyc-passport, newkyc-ie-passport, newkyc-idCard, newkyc-ie-idCard, newkyc-visa). The procedure uses BackOffice.CustomerDocument as the source of truth for submitted KYC documents, applying expiry logic using Dictionary.DocumentType.MaxAgeInMonths when ExpiryDate is absent.

---

## 2. Business Logic

### 2.1 Identity Resolution (CID vs GCID Input)

**What**: Resolves the input ID list to (CID, GCID) pairs stored in #usersIDs temp table.

**Columns/Parameters Involved**: `@isGcid`, `@ids`, `Customer.CustomerStatic.CID`, `Customer.CustomerStatic.GCID`

**Rules**:
- @isGcid = 0: JOIN @ids to Customer.CustomerStatic ON cs.CID = i.ID (input is CIDs)
- @isGcid = 1: JOIN @ids to Customer.CustomerStatic ON cs.GCID = i.ID (input is GCIDs)
- #usersIDs populated with (CID, GCID) pairs for all found customers
- Customers not found in CustomerStatic are silently excluded (no error)

### 2.2 Valid Document Types CTE (DocumentTypes)

**What**: Aggregates valid, non-expired document type IDs per customer as a comma-separated list.

**Columns/Parameters Involved**: `BackOffice.CustomerDocument`, `BackOffice.CustomerDocumentToDocumentType`, `Dictionary.DocumentType.MaxAgeInMonths`

**Rules**:
- Joins #usersIDs -> CustomerDocument -> CustomerDocumentToDocumentType -> Dictionary.DocumentType
- Validity filter: `ExpiryDate > GETUTCDATE()` OR `(ExpiryDate IS NULL AND DATEDIFF(MONTH, IssueDate, GETUTCDATE()) <= MaxAgeInMonths)`
  - If explicit ExpiryDate exists: check it's in the future
  - If no ExpiryDate: use MaxAgeInMonths from Dictionary.DocumentType as age cap from IssueDate
- STRING_AGG produces: '1,3,5' style comma-separated list of DocumentTypeIDs

### 2.3 Last Customer Document CTE (LastCustomerDocument)

**What**: Finds the most recent KYC document per customer per kind (utility or passport), with expiry state.

**Columns/Parameters Involved**: `BackOffice.CustomerDocument.Comment`, `BackOffice.CustomerDocumentToDocumentType.ExpiryDate`, `Dictionary.DocumentType.MaxAgeInMonths`

**Rules**:
- WHERE cd.Comment IN ('newkyc-bill', 'newkyc-ie-bill', 'newkyc-passport', 'newkyc-ie-passport', 'newkyc-idCard', 'newkyc-ie-idCard', 'newkyc-visa')
- DocKind derivation:
  - 'utility': Comment = 'newkyc-bill' OR 'newkyc-ie-bill' (address proof documents)
  - 'passport': all other newkyc-* values (identity proof: passport, ID card, visa)
- DocumentTypeID = 6 EXCLUDED: `ISNULL(cdd.DocumentTypeID,1) <> 6` (6 = Rejected - excluded from most-recent calculation)
- Expired flag: `ExpiryDate < GetUtcDate() OR (ExpiryDate IS NULL AND DATEDIFF(MONTH, IssueDate, GETUTCDATE()) > MaxAgeInMonths)`

### 2.4 Final Output Assembly

**What**: Joins all sources to produce the per-customer KYC summary row.

**Rules**:
- One row per CID from #usersIDs
- ExternalID from CustomerStatic (external system mapping key)
- SalesForceContactID, SalesForceAccountID from BackOffice.Customer (Salesforce CRM links)
- ClassifiedDocumentTypes: ISNULL(DocumentTypesList, '') - empty string if no valid documents
- HasUtilityDocument/PassportDocument: CAST(HasDocument as BIT) - 1 if document exists, 0 if not
- UtilityExpired/PassportExpired: CAST(Expired as BIT) - 1 if document is expired, NULL if none
- UtilityDocumentTypeID/PassportDocumentTypeID: DocumentTypeID of the last document of that kind

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | IDIntList READONLY | NO | - | CODE-BACKED | Table-valued parameter (dbo.IDIntList type). Each row has an ID column. Pass CIDs or GCIDs depending on @isGcid. Batch input - multiple customers in one call. |
| 2 | @isGcid | BIT | NO | - | CODE-BACKED | Identity resolution mode. 0 = input IDs are CIDs (join on CustomerStatic.CID). 1 = input IDs are GCIDs (join on CustomerStatic.GCID). |

**Result set (one row per resolved customer):**

| Column | Type | Description |
|--------|------|-------------|
| CID | INT | Customer's CID (internal trading account ID) |
| GCID | INT | Customer's GCID (Group Customer ID - cross-product key) |
| ExternalID | - | From Customer.CustomerStatic; external system identifier |
| SalesForceContactID | - | From BackOffice.Customer; Salesforce Contact record ID |
| SalesForceAccountID | - | From BackOffice.Customer; Salesforce Account record ID |
| ClassifiedDocumentTypes | VARCHAR | Comma-separated list of valid DocumentTypeIDs. Empty string if none. |
| HasUtilityDocument | BIT | 1 if customer has a valid newkyc-bill or newkyc-ie-bill document, 0 if not |
| UtilityExpired | BIT | 1 if the last utility document is expired, NULL if no utility document exists |
| UtilityDocumentTypeID | INT | DocumentTypeID of the most recent utility document; NULL if none |
| HasPassportDocument | BIT | 1 if customer has a valid passport/ID document, 0 if not |
| PassportExpired | BIT | 1 if the last passport/ID document is expired, NULL if none |
| PassportDocumentTypeID | INT | DocumentTypeID of the most recent passport/ID document; NULL if none |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | Customer.CustomerStatic | Read | Identity resolution: CID->GCID or GCID->CID lookup |
| @CID | BackOffice.CustomerDocument | Read | KYC document submission records |
| DocumentID | BackOffice.CustomerDocumentToDocumentType | Read | Document-to-type mapping with expiry |
| DocumentTypeID | Dictionary.DocumentType | Read | MaxAgeInMonths for age-based expiry check |
| @CID | BackOffice.Customer | Read | SalesForce IDs (SalesForceContactID, SalesForceAccountID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_UserSyncAPI (service role) | GRANT EXECUTE | Caller | User data sync service; includes KYC doc state in sync payloads |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAggregatedInfoOnlyReadFields (procedure)
|- Customer.CustomerStatic (table - identity resolution)
|- BackOffice.CustomerDocument (table - cross-schema, KYC submissions)
|- BackOffice.CustomerDocumentToDocumentType (table - cross-schema, document type mapping)
|- Dictionary.DocumentType (table - cross-schema, MaxAgeInMonths expiry rule)
+-- BackOffice.Customer (table - cross-schema, Salesforce ID fields)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | ID resolution: CID<->GCID lookup per @isGcid mode |
| BackOffice.CustomerDocument | Table | KYC document submissions per customer |
| BackOffice.CustomerDocumentToDocumentType | Table | Maps documents to type IDs; provides ExpiryDate and IssueDate |
| Dictionary.DocumentType | Table | MaxAgeInMonths for age-based expiry when ExpiryDate is absent |
| BackOffice.Customer | Table | SalesForceContactID and SalesForceAccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_UserSyncAPI service | External service | Reads KYC doc status for user sync operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @isGcid BIT | Input mode | Controls whether @ids contains CIDs or GCIDs - wrong mode silently returns no rows for unmatched IDs |
| DocumentTypeID = 6 excluded | Business rule | Rejected documents (type 6) excluded from LastCustomerDocument calculation |
| DocKind derived from Comment | Design | Comment field (newkyc-bill, newkyc-passport, etc.) used as document classification key |
| OUTER APPLY for doc status | Design | Returns NULL columns (not 0) if no document of that kind exists - callers must handle NULL vs 0 for HasDocument |
| ExpiryDate IS NULL -> MaxAgeInMonths | Expiry logic | Documents without explicit expiry use type-specific MaxAgeInMonths from GETUTCDATE as the age baseline |

---

## 8. Sample Queries

### 8.1 Get KYC status for a batch of customers by CID

```sql
DECLARE @ids IDIntList
INSERT @ids (ID) VALUES (12345678), (23456789), (34567890)

EXEC Customer.GetAggregatedInfoOnlyReadFields
    @ids = @ids,
    @isGcid = 0
```

### 8.2 Get KYC status for a batch by GCID

```sql
DECLARE @ids IDIntList
INSERT @ids (ID) VALUES (9876543), (8765432)

EXEC Customer.GetAggregatedInfoOnlyReadFields
    @ids = @ids,
    @isGcid = 1
```

### 8.3 Check raw document records for a customer

```sql
SELECT cd.DocumentID, cd.Comment, cdd.DocumentTypeID, cdd.ExpiryDate, cdd.IssueDate
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
JOIN BackOffice.CustomerDocumentToDocumentType cdd WITH (NOLOCK) ON cdd.DocumentID = cd.DocumentID
WHERE cd.CID = 12345678
  AND cd.Comment LIKE 'newkyc-%'
ORDER BY cd.DocumentID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetAggregatedInfoOnlyReadFields | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetAggregatedInfoOnlyReadFields.sql*
