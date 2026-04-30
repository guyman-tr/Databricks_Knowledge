# Customer.GetManyRiskUserInfo

> Retrieves risk and compliance data for multiple customers - regulation, document status, verification level, classified documents, copy block status, and EV results.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns risk info rows for a GCID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyRiskUserInfo is a batch reader for risk and compliance data. It retrieves the subset of customer data relevant to KYC/AML compliance: regulation, document status, phone verification, verification level, classified document types, player status, suitability test status, copy block status, and electronic verification results.

This procedure serves compliance dashboards and batch risk assessment operations. It aggregates data from Real_Customer, Real_BackOfficeCustomer, Real_ElectronicIdentityCheck, BlockedCustomerOperations, Ev.CustomerResult, and Dictionary.EvProvider.

---

## 2. Business Logic

### 2.1 Copy Block and EV Result Detection

**What**: Same patterns as GetManyAggregatedInfo - CTE for copy block (OperationTypeID=1) and CTE for latest EV result.

**Columns/Parameters Involved**: `IsCopyBlocked`, `EvStatusId`, `EvProviderId`, `EvProviderTypeId`

**Rules**:
- Copy block CTE checks BlockedCustomerOperations for OperationTypeID=1
- EV result CTE picks TOP 1 from Ev.CustomerResult ordered by CustomerEvResultId DESC
- EV provider type resolved via Dictionary.EvProvider

### 2.2 Document Classification

**What**: Uses dbo.CustomerClassifiedDocuments scalar function to build a comma-separated document types string.

**Columns/Parameters Involved**: `ClassifiedDocumentTypes`

**Rules**:
- Stored in #customerDocuments temp table
- Different from GetManyAggregatedInfo which uses the TVF version

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve risk info for. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | RegulationID (output) | int | YES | - | CODE-BACKED | Primary regulation. FK to Dictionary.Regulation. |
| 4 | DocumentStatusID (output) | int | YES | - | CODE-BACKED | Document verification status. |
| 5 | PhoneVerifiedID (output) | int | YES | - | CODE-BACKED | Phone verification status. |
| 6 | VerificationLevelID (output) | int | YES | - | CODE-BACKED | KYC verification level. |
| 7 | ClassifiedDocumentTypes (output) | varchar(500) | YES | - | CODE-BACKED | Comma-separated classified document type codes. |
| 8 | PlayerStatusID (output) | int | YES | - | CODE-BACKED | Account lifecycle status. |
| 9 | SuitabilityTestStatusID (output) | int | YES | - | CODE-BACKED | MiFID suitability test status. |
| 10 | IsCopyBlocked (output) | int | NO | 0 | CODE-BACKED | 1 if blocked from copy trading, 0 otherwise. |
| 11 | EvProviderId (output) | int | YES | - | CODE-BACKED | Latest EV provider ID. |
| 12 | EvStatusId (output) | int | YES | - | CODE-BACKED | Latest EV status. |
| 13 | EvProviderTypeId (output) | int | YES | - | CODE-BACKED | EV provider type from Dictionary.EvProvider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Real_Customer | JOIN | Core customer data |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Risk/compliance data |
| CID | dbo.Real_ElectronicIdentityCheck | LEFT JOIN | GDC check |
| CID | dbo.BlockedCustomerOperations | LEFT JOIN | Copy block |
| GCID | Ev.CustomerResult | LEFT JOIN | EV results |
| EvProviderId | Dictionary.EvProvider | LEFT JOIN | Provider type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch risk data retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyRiskUserInfo (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- dbo.Real_ElectronicIdentityCheck (table)
+-- dbo.BlockedCustomerOperations (table)
+-- Ev.CustomerResult (table)
+-- Dictionary.EvProvider (table)
+-- dbo.CustomerClassifiedDocuments (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | JOIN - core data |
| dbo.Real_BackOfficeCustomer | Table | JOIN - risk data |
| dbo.Real_ElectronicIdentityCheck | Table | LEFT JOIN - GDC |
| dbo.BlockedCustomerOperations | Table | CTE - copy block |
| Ev.CustomerResult | Table | CTE - EV results |
| Dictionary.EvProvider | Table | LEFT JOIN - provider type |
| dbo.CustomerClassifiedDocuments | Function | SELECT - document classification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get risk info for multiple customers
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002)
EXEC Customer.GetManyRiskUserInfo @ids = @ids
```

### 8.2 Direct query for verification level
```sql
SELECT cc.GCID, bc.RegulationID, bc.VerificationLevelID, cc.PlayerStatusID
FROM dbo.Real_BackOfficeCustomer bc WITH (NOLOCK)
JOIN dbo.Real_Customer cc WITH (NOLOCK) ON cc.CID = bc.CID
WHERE cc.GCID IN (SELECT Id FROM @ids)
```

### 8.3 Check copy block status
```sql
SELECT cc.GCID, 1 AS IsCopyBlocked
FROM dbo.Real_Customer cc WITH (NOLOCK)
JOIN dbo.BlockedCustomerOperations bco WITH (NOLOCK) ON bco.CID = cc.CID
WHERE cc.GCID = @GCID AND bco.OperationTypeID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyRiskUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyRiskUserInfo.sql*
