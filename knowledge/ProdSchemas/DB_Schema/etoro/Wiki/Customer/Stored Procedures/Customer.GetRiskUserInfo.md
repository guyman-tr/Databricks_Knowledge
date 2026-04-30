# Customer.GetRiskUserInfo

> Returns a comprehensive risk and verification snapshot for a customer by GCID: document status, EV results, player status, copy-block flag, and latest phone verification - used by risk and compliance workflows.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid; returns 2 result sets: main risk snapshot + EV history |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRiskUserInfo is the primary SP for reading a customer's risk/compliance status. It aggregates data from several subsystems - document verification, EV (Electronic Verification), player status, phone verification, and copy block status - into two result sets:

1. **Main risk snapshot**: One row per customer with all current verification and risk fields
2. **EV history**: All historical EV transaction results ordered by date descending

It is called by the BackOffice and risk-management systems whenever a complete risk picture is needed - for example, when reviewing a withdrawal, handling a support ticket, or running a compliance check.

The procedure uses `dbo.Real_Customer` and `Real_BackOfficeCustomer` views (synonyms to cross-DB real-account views) to separate real-money accounts from demo accounts.

**Change history (from DDL comments)**:
- 08/12/2015: Verification block (FogBugz 32499)
- 05/01/2016: Added NOLOCK hints (FogBugz 33274)
- 02/02/2017: Au10tix User Story 2.1 (FogBugz 2872)
- 11/05/2017: Au10tix-related changes (FogBugz 44814)
- 05/09/2017: Added PlayerStatusReasonID (FogBugz 47218)
- 24/10/2017: Updated EvStatusId, reduced CustomerStatic references (FogBugz 49308)
- 10/05/2018: Added MifidCategorizationID (FogBugz 51498)
- 12/06/2018: Added DesignatedRegulationID (FogBugz 51829)
- 12/07/2018: Added TradingRiskStatusID (FogBugz 52152)
- 19/12/2018: UserAPI adjustment for EvService (RD-1774, RD-1785)
- 24/02/2019: PlayerStatus/reasons/sub-reasons reorganization (RD-1752, Ops0451)
- 13/08/2019: Switched to Real_CustomerPhoneVerificationDetails view (Ran Ovadia)
- 19/08/2019: Replaced subqueries with OUTER APPLY for phone verification (Adi)
- 20/08/2019: Fixed phone verification sort - by VerificationDate not ID (Adi)

---

## 2. Business Logic

### 2.1 Classified Document Types

**What**: Retrieves a delimited string of document type codes the customer has submitted.

**Columns/Parameters Involved**: `@docTypes`, `dbo.CustomerClassifiedDocuments(@gcid)`

**Rules**:
- Calls scalar UDF `dbo.CustomerClassifiedDocuments(@gcid)`
- Returns a concatenated string of document type classifications (e.g., passport types, utility bill types)
- Result stored in @docTypes, returned as `ClassifiedDocumentTypes` in output

### 2.2 Document Status Sub-Queries (Utility and Passport)

**What**: Checks whether the customer has valid utility and passport documents, and whether they are expired.

**Columns/Parameters Involved**: `HasUtilityDocument`, `UtilityExpired`, `UtilityDocumentTypeID`, `HasPassportDocument`, `PassportExpired`, `PassportDocumentTypeID`

**Rules**:
- Calls `Customer.GetDocumentDetails @gcid, 'utility'` -> inserts into #utilityDocument
- Calls `Customer.GetDocumentDetails @gcid, 'passport'` -> inserts into #passportDocument
- Each temp table: HasDocument (bit), Expired (bit), DocumentTypeID (int)
- OUTER APPLY TOP 1 retrieves the single row from each temp table (GetDocumentDetails returns one row)

### 2.3 Real Customer Context

**What**: Loads the customer's CID, player status, and related reason codes from the real-account view.

**Columns/Parameters Involved**: `CID`, `GCID`, `PlayerStatusID`, `PlayerStatusReasonID`, `PlayerStatusSubReasonID`, `PlayerStatusSubReasonComment`

**Rules**:
- Queries `dbo.Real_Customer(NoLock)` (cross-DB synonym/view for real accounts)
- Filters WHERE GCID=@gcid
- Stored in #RealCustomer temp table for subsequent JOINs
- Only real accounts are processed; demo accounts are excluded

### 2.4 Copy Block Detection

**What**: Determines whether the customer is currently blocked from using the Copy/Mirror Trading feature.

**Columns/Parameters Involved**: `@isCurrentlyCopyBlocked`, `IsCopyBlocked`

**Rules**:
- Queries `dbo.BlockedCustomerOperations(NoLock)` WHERE OperationTypeID=1 (copy block)
- Joins to #RealCustomer on CID
- Sets @isCurrentlyCopyBlocked=1 if a block record exists; remains NULL otherwise
- OperationTypeID=1 specifically means copy trading is blocked (not other operation types)

### 2.5 Electronic Verification (EV) Status

**What**: Retrieves the latest EV decision from the primary EV provider.

**Columns/Parameters Involved**: `@EvResultStatus`, `@EvProviderId`, `EvProviderId`, `EvResultsStatus`

**Rules**:
- Queries `Ev.CustomerResult` TOP 1 ORDER BY CustomerEvResultId DESC
- INNER JOINs `Dictionary.EvProvider` WHERE ProviderTypeID=0 (primary EV provider; not supplemental)
- EvStatusId values represent the EV decision (approved, rejected, manual review, etc.)
- Returns only the latest result from the primary provider type

### 2.6 Phone Verification

**What**: Retrieves the latest phone verification status for the customer.

**Columns/Parameters Involved**: `PhoneVerifiedID`

**Rules**:
- OUTER APPLY on `Real_CustomerPhoneVerificationDetails`
- Filters WHERE CID=cc.CID, ORDER BY VerificationDate DESC (bug fix from 20/08/2019 - was incorrectly sorted by ID)
- PhoneVerifiedID: verification result code (0=not verified, other values = verified levels)
- ISNULL(..., 0) applied to return 0 if no record found

### 2.7 Main Result Set (Result Set 1)

**What**: Combines all gathered data into a single comprehensive risk snapshot row.

**Rules**:
- JOINs #RealCustomer, Real_BackOfficeCustomer, Real_ElectronicIdentityCheck (LEFT)
- LEFT JOIN eic is for legacy EIC data (may be NULL for newer accounts)
- Returns one row per customer: all verification IDs, document status, player status, EV results

### 2.8 EV History (Result Set 2)

**What**: Returns all EV transaction history for the customer.

**Columns/Parameters Involved**: `EvStatusId`, `EvProviderId`, `TransactionDate`, `GCID`, `TransactionID`, `VerificationType`

**Rules**:
- `SELECT ... FROM Ev.CustomerResult WHERE GCID=@gcid ORDER BY TransactionDate DESC`
- No provider filter (returns all providers, unlike the TOP 1 query in 2.5)
- No row limit - returns complete history

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Input: Group Customer ID of the customer to retrieve risk info for. |
| **Result Set 1 - Main Risk Snapshot** | | | | | | |
| 2 | GCID | int | NO | - | CODE-BACKED | Group Customer ID (from #RealCustomer). |
| 3 | RealCID | int | NO | - | CODE-BACKED | Internal CID of the real-money account (alias for cc.CID). |
| 4 | RegulationID | int | YES | - | CODE-BACKED | Regulatory jurisdiction ID from BackOffice.Customer (BackOffice.RegulationID). |
| 5 | DocumentStatusID | int | YES | - | CODE-BACKED | Document verification status from BackOffice.Customer. Indicates whether submitted documents have been reviewed. |
| 6 | PhoneVerifiedID | int | NO | 0 | CODE-BACKED | Phone verification result. 0 = not verified; other values = verified. From Real_CustomerPhoneVerificationDetails, latest by VerificationDate. |
| 7 | VerificationLevelID | int | YES | - | CODE-BACKED | Overall verification level from BackOffice.Customer. Higher = more verified. |
| 8 | VerifiedBy | varchar | YES | - | CODE-BACKED | Identity of the verifier (agent ID or system name) from BackOffice.Customer. |
| 9 | VerifiedByProvider | varchar | YES | - | CODE-BACKED | EV provider that performed automated verification from BackOffice.Customer. |
| 10 | ClassifiedDocumentTypes | nvarchar(500) | YES | - | CODE-BACKED | Delimited string of document type classifications. From scalar UDF dbo.CustomerClassifiedDocuments(@gcid). |
| 11 | PlayerStatusID | int | YES | - | CODE-BACKED | Customer's current operational status (active, suspended, blocked, etc.). From Customer.CustomerStatic via Real_Customer. |
| 12 | SuitabilityTestStatusID | int | YES | - | CODE-BACKED | MiFID II suitability assessment status from BackOffice.Customer. Added OPS0419. |
| 13 | PlayerStatusReasonID | int | YES | - | CODE-BACKED | Reason code for current PlayerStatus. From Customer.CustomerStatic via Real_Customer. |
| 14 | IsCopyBlocked | bit | YES | NULL | CODE-BACKED | 1 if customer is blocked from copy/mirror trading (OperationTypeID=1 in BlockedCustomerOperations); NULL if not blocked. |
| 15 | EvProviderId | int | YES | NULL | CODE-BACKED | ID of the EV provider that issued the latest primary EV result. From Ev.CustomerResult. |
| 16 | EvResultsStatus | int | YES | NULL | CODE-BACKED | Latest EV decision status code from the primary EV provider. From Ev.CustomerResult.EvStatusId. |
| 17 | HasUtilityDocument | bit | YES | - | CODE-BACKED | 1 if a utility bill document exists for the customer. From Customer.GetDocumentDetails. |
| 18 | UtilityExpired | bit | YES | - | CODE-BACKED | 1 if the utility document is expired. From Customer.GetDocumentDetails. |
| 19 | UtilityDocumentTypeID | int | YES | - | CODE-BACKED | Document type ID of the utility document. From Customer.GetDocumentDetails. |
| 20 | HasPassportDocument | bit | YES | - | CODE-BACKED | 1 if a passport/ID document exists for the customer. From Customer.GetDocumentDetails. |
| 21 | PassportExpired | bit | YES | - | CODE-BACKED | 1 if the passport document is expired. From Customer.GetDocumentDetails. |
| 22 | PassportDocumentTypeID | int | YES | - | CODE-BACKED | Document type ID of the passport document. From Customer.GetDocumentDetails. |
| 23 | EvMatchStatus | int | YES | - | CODE-BACKED | EV name/address match status from BackOffice.Customer. |
| 24 | MifidCategorizationID | int | YES | - | CODE-BACKED | MiFID II customer categorization (Retail, Professional, Eligible Counterparty). From BackOffice.Customer. Added FogBugz 51498. |
| 25 | DesignatedRegulationID | int | YES | - | CODE-BACKED | Designated regulatory jurisdiction from BackOffice.Customer. May differ from RegulationID for cross-regulation accounts. Added FogBugz 51829. |
| 26 | TradingRiskStatusID | int | YES | - | CODE-BACKED | Trading risk classification from BackOffice.Customer. Added FogBugz 52152. |
| 27 | PlayerStatusSubReasonID | int | YES | - | CODE-BACKED | Sub-reason code for PlayerStatus. From Customer.CustomerStatic. Added RD-1752/Ops0451. |
| 28 | PlayerStatusSubReasonComment | nvarchar | YES | - | CODE-BACKED | Free-text comment explaining the PlayerStatus sub-reason. From Customer.CustomerStatic. |
| **Result Set 2 - EV History** | | | | | | |
| 29 | EvStatusId | int | NO | - | CODE-BACKED | EV decision result code for this transaction. |
| 30 | EvProviderId | int | NO | - | CODE-BACKED | EV provider that processed this transaction. |
| 31 | TransactionDate | datetime | YES | - | CODE-BACKED | Date and time of the EV transaction. Used for ORDER BY (descending). |
| 32 | GCID | int | NO | - | CODE-BACKED | Group Customer ID (echoed from input). |
| 33 | TransactionID | varchar | YES | - | CODE-BACKED | External transaction reference ID from the EV provider. |
| 34 | VerificationType | int | YES | - | CODE-BACKED | Type of verification performed (identity, address, etc.). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | FROM + WHERE GCID | Real-account customer status view |
| CID | dbo.Real_BackOfficeCustomer | JOIN | BackOffice risk fields |
| CID | dbo.Real_ElectronicIdentityCheck | LEFT JOIN | Legacy identity check data |
| CID | dbo.BlockedCustomerOperations | WHERE OperationTypeID=1 | Copy-block detection |
| @gcid | Ev.CustomerResult | WHERE GCID | EV results (both snapshot and history) |
| EvProviderId | Dictionary.EvProvider | INNER JOIN ProviderTypeID=0 | Filters to primary EV provider |
| @gcid | dbo.CustomerClassifiedDocuments | Scalar UDF call | Document type classification string |
| @gcid | Customer.GetDocumentDetails | EXEC (SP call) x2 | Document existence and expiry (utility, passport) |
| CID | Real_CustomerPhoneVerificationDetails | OUTER APPLY | Latest phone verification result |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRiskUserInfo (procedure)
|-- dbo.Real_Customer (view/synonym)
|-- dbo.Real_BackOfficeCustomer (view/synonym)
|-- dbo.Real_ElectronicIdentityCheck (view/synonym)
|-- dbo.BlockedCustomerOperations (view/synonym)
|-- dbo.Real_CustomerPhoneVerificationDetails (view/synonym)
|-- dbo.CustomerClassifiedDocuments (scalar UDF)
|-- Customer.GetDocumentDetails (procedure - not in SSDT)
|-- Ev.CustomerResult (table - cross-schema)
`-- Dictionary.EvProvider (table - cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | View/Synonym | FROM - customer CID, player status fields by GCID |
| dbo.Real_BackOfficeCustomer | View/Synonym | JOIN - RegulationID, DocumentStatusID, VerificationLevel, EV/MiFID fields |
| dbo.Real_ElectronicIdentityCheck | View/Synonym | LEFT JOIN - legacy identity check data |
| dbo.BlockedCustomerOperations | View/Synonym | WHERE OperationTypeID=1 - copy block detection |
| dbo.Real_CustomerPhoneVerificationDetails | View/Synonym | OUTER APPLY - latest phone verification |
| dbo.CustomerClassifiedDocuments | Scalar UDF | Called with @gcid - classified document type string |
| Customer.GetDocumentDetails | Procedure | EXEC x2 - document existence checks (utility, passport) |
| Ev.CustomerResult | Table | WHERE GCID - EV result snapshot and history |
| Dictionary.EvProvider | Table | INNER JOIN ProviderTypeID=0 - primary EV provider filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with THROW | Error handling | Prints server/DB/procedure context on error then re-throws |
| Real accounts only | Scope | Uses Real_Customer/Real_BackOfficeCustomer views - demo accounts excluded |
| ProviderTypeID=0 for EV snapshot | Filter | Only primary EV provider in snapshot; all providers in history result set |
| Phone sort fix | Bug history | Prior to 20/08/2019 was sorted by ID not VerificationDate - historical IDs may not match date order |
| IsCopyBlocked NULL vs 0 | Semantics | Returns NULL for not-blocked (not 0). Callers must handle IS NULL vs = 0. |

---

## 8. Sample Queries

### 8.1 Get full risk snapshot for a customer
```sql
EXEC Customer.GetRiskUserInfo @gcid = 1983785;
-- Returns 2 result sets: main risk row + EV history
```

### 8.2 Check if a customer is copy-blocked
```sql
-- From result set 1: IsCopyBlocked column
-- NULL = not copy-blocked; 1 = blocked
```

### 8.3 Check EV status meaning
```sql
-- EvResultsStatus values come from Dictionary.EvProvider and Ev subsystem
-- Positive values typically = approved; specific codes depend on EV provider
-- See Ev.CustomerResult table documentation for status codes
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| FogBugz 32499 | Work item | Verification block feature (08/12/2015) |
| FogBugz 44814 | Work item | Au10tix EV provider integration changes |
| FogBugz 51498 | Work item | MiFID II categorization added |
| FogBugz 51829 | Work item | DesignatedRegulationID added |
| FogBugz 52152 | Work item | TradingRiskStatusID added |
| Ops0451 / RD-1752 | Work item | PlayerStatus/reasons/sub-reasons redesign (24/02/2019) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 33 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Work items: 6 from DDL comments | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRiskUserInfo | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetRiskUserInfo.sql*
