# Customer.GetRiskUserInfo

> Comprehensive single-customer risk info from legacy dbo tables - includes document classification, document expiry details (passport + utility), copy block status, and full EV history.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: full risk profile + EV history |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRiskUserInfo is the most detailed single-customer risk procedure. It returns a comprehensive risk/compliance profile including regulation, verification status, classified document types, document expiry details for both passport AND utility documents, copy trading block status, EV results, and all regulatory categorizations. This is used by compliance dashboards and KYC review screens.

Unlike GetRiskInfo (Customer schema, no docs), this procedure reads from the legacy dbo tables and performs full document classification with expiry checking. It uses String_agg for classified document types, CTEs for document details and EV results, and OUTER APPLY for copy block and per-document-kind expiry data.

---

## 2. Business Logic

### 2.1 Document Classification and Expiry

**What**: Classifies customer documents into valid/expired, split by passport vs utility kind.

**Columns/Parameters Involved**: `ClassifiedDocumentTypes`, `HasUtilityDocument`, `UtilityExpired`, `HasPassportDocument`, `PassportExpired`

**Rules**:
- ClassifiedDocumentTypes: String_agg of distinct valid DocumentTypeIDs (not expired)
- Document expiry: ExpiryDate < UTC OR (ExpiryDate IS NULL AND age > MaxAgeInMonths)
- Documents split into 'utility' (bill/bankstatement/govdoc) vs 'passport' (passport/idCard/driverLicence/residencepermit)
- DocumentTypeID=6 (Rejected) excluded
- Expanded comment tags vs older SPs: includes 'otherDoc-bankstatement', 'newkyc-govdoc', 'newkyc-driverLicence', 'newkyc-residencepermit-*', 'newkyc-idCard-frontSide/backSide'

### 2.2 Copy Block Detection

**What**: OUTER APPLY for copy block using TOP 1 pattern.

**Rules**:
- OUTER APPLY: SELECT TOP 1 OperationTypeID FROM BlockedCustomerOperations WHERE CID=cc.CID AND OperationTypeID=1
- Returns OperationTypeID directly (1 or NULL) rather than ISNULL(,0) pattern

### 2.3 EV Provider Type Filtering

**What**: Same as GetRiskInfo - latest EV from ProviderTypeID=0 only.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | RealCID (output) | int | NO | - | CODE-BACKED | Real account CID. |
| 4 | RegulationID (output) | int | YES | - | CODE-BACKED | Primary regulation. |
| 5 | DocumentStatusID (output) | int | YES | - | CODE-BACKED | Document verification status. |
| 6 | PhoneVerifiedID (output) | int | YES | - | CODE-BACKED | Phone verification status. |
| 7 | VerificationLevelID (output) | int | YES | - | CODE-BACKED | KYC verification level. |
| 8 | VerifiedBy (output) | varchar | YES | - | CODE-BACKED | Who verified. |
| 9 | VerifiedByProvider (output) | varchar | YES | - | CODE-BACKED | Verification provider. |
| 10 | ClassifiedDocumentTypes (output) | nvarchar(500) | YES | - | CODE-BACKED | Comma-separated valid document type IDs (String_agg). |
| 11 | PlayerStatusID (output) | int | YES | - | CODE-BACKED | Account lifecycle status. |
| 12 | SuitabilityTestStatusID (output) | int | YES | - | CODE-BACKED | MiFID suitability test. |
| 13 | PlayerStatusReasonID (output) | int | YES | - | CODE-BACKED | Status reason. |
| 14 | IsCopyBlocked (output) | int | YES | - | CODE-BACKED | 1 if copy trading blocked (OperationTypeID=1), NULL otherwise. |
| 15 | EvProviderId (output) | int | YES | - | CODE-BACKED | Latest identity EV provider. |
| 16 | EvResultsStatus (output) | int | YES | - | CODE-BACKED | Latest identity EV status. |
| 17 | HasUtilityDocument (output) | bit | NO | 0 | CODE-BACKED | 1 if utility bill document exists, 0 otherwise. |
| 18 | UtilityExpired (output) | bit | YES | - | CODE-BACKED | 1 if utility document is expired, NULL if valid or missing. |
| 19 | UtilityDocumentTypeID (output) | int | YES | - | CODE-BACKED | Document type of utility document. |
| 20 | HasPassportDocument (output) | bit | NO | 0 | CODE-BACKED | 1 if passport/ID document exists. |
| 21 | PassportExpired (output) | bit | YES | - | CODE-BACKED | 1 if passport is expired. |
| 22 | PassportDocumentTypeID (output) | int | YES | - | CODE-BACKED | Document type of passport. |
| 23 | EvMatchStatus (output) | int | YES | - | CODE-BACKED | EV match status. |
| 24 | MifidCategorizationID (output) | int | YES | - | CODE-BACKED | MiFID categorization. |
| 25 | AsicClassificationID (output) | int | YES | - | CODE-BACKED | ASIC classification. |
| 26 | SeychellesCategorizationID (output) | int | YES | - | CODE-BACKED | Seychelles categorization. |
| 27 | DesignatedRegulationID (output) | int | YES | - | CODE-BACKED | Designated regulation. |
| 28 | TradingRiskStatusID (output) | int | YES | - | CODE-BACKED | Trading risk status. |
| 29 | PlayerStatusSubReasonID (output) | int | YES | - | CODE-BACKED | Status sub-reason. |
| 30 | PlayerStatusSubReasonComment (output) | nvarchar | YES | - | CODE-BACKED | Sub-reason comment. |
| 31 | EIDStatusID (output) | int | YES | - | CODE-BACKED | Electronic ID status. |
| 32 | OnboardingRiskClassificationID (output) | int | YES | - | CODE-BACKED | Onboarding risk classification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | JOIN | Core customer data |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Risk/compliance data |
| CID | dbo.CustomerDocument | CTE | Document classification |
| DocumentID | dbo.CustomerDocumentToDocumentType | CTE | Document types/expiry |
| DocumentTypeID | dbo.DocumentType | CTE | Max age rules |
| GCID | Ev.CustomerResult | CTE + result set 2 | EV history |
| EvProviderId | Dictionary.EvProvider | JOIN | Provider type |
| CID | dbo.BlockedCustomerOperations | OUTER APPLY | Copy block |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | KYC review and compliance dashboards |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRiskUserInfo (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- dbo.CustomerDocument (table)
+-- dbo.CustomerDocumentToDocumentType (table)
+-- dbo.DocumentType (table)
+-- Ev.CustomerResult (table)
+-- Dictionary.EvProvider (table)
+-- dbo.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | JOIN - core customer |
| dbo.Real_BackOfficeCustomer | Table | JOIN - risk data |
| dbo.CustomerDocument | Table | CTE - documents |
| dbo.CustomerDocumentToDocumentType | Table | CTE - doc types |
| dbo.DocumentType | Table | CTE - max age |
| Ev.CustomerResult | Table | CTE + result set 2 |
| Dictionary.EvProvider | Table | JOIN - provider type |
| dbo.BlockedCustomerOperations | Table | OUTER APPLY - copy block |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error handling | Standard error logging and re-throw |

---

## 8. Sample Queries

### 8.1 Get full risk user info
```sql
EXEC Customer.GetRiskUserInfo @gcid = 12345
-- Returns 2 result sets: risk profile (with docs) + EV history
```

### 8.2 Check document status directly
```sql
SELECT DISTINCT dt.DocumentTypeID
FROM dbo.CustomerDocumentToDocumentType cdd WITH (NOLOCK)
JOIN dbo.CustomerDocument cd WITH (NOLOCK) ON cd.DocumentID = cdd.DocumentID
JOIN dbo.DocumentType dt WITH (NOLOCK) ON cdd.DocumentTypeID = dt.DocumentTypeID
JOIN dbo.Real_Customer rc WITH (NOLOCK) ON rc.CID = cd.CID
WHERE rc.GCID = @gcid
    AND (cdd.ExpiryDate > GETUTCDATE()
         OR (cdd.ExpiryDate IS NULL AND DATEDIFF(MONTH, cdd.IssueDate, GETUTCDATE()) <= dt.MaxAgeInMonths))
```

### 8.3 Compare with Customer schema version
```sql
-- GetRiskUserInfo: legacy dbo tables + full document classification + passport/utility split
-- GetRiskInfo: Customer.RiskUserInfo (normalized, no document details)
-- GetRiskUserInfoWithoutDocuments: legacy dbo tables but no document classification
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 32 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRiskUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRiskUserInfo.sql*
