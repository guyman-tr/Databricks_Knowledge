# Customer.GetRiskUserInfoWithoutDocuments

> Performance-optimized variant of GetRiskUserInfo that skips document classification - returns risk profile, copy block, and EV history without document details.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: risk profile (no docs) + EV history |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRiskUserInfoWithoutDocuments is the document-free variant of Customer.GetRiskUserInfo. It returns the same risk/compliance profile (regulation, verification, player status, EV results, regulatory categorizations, copy block) but skips the expensive document classification and expiry checking. This makes it faster for callers that need risk data but not document details.

It uses Customer.CustomerIdentification to resolve CID from GCID (rather than joining Real_Customer directly), then joins Real_Customer and Real_BackOfficeCustomer for the risk data.

---

## 2. Business Logic

### 2.1 Copy Block and EV Results

**What**: Same patterns as GetRiskUserInfo - OUTER APPLY for copy block, CTE for EV with ProviderTypeID=0 filtering.

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
| 5 | DocumentStatusID (output) | int | YES | - | CODE-BACKED | Document status. |
| 6 | PhoneVerifiedID (output) | int | YES | - | CODE-BACKED | Phone verification. |
| 7 | VerificationLevelID (output) | int | YES | - | CODE-BACKED | KYC verification level. |
| 8 | VerifiedBy (output) | varchar | YES | - | CODE-BACKED | Who verified. |
| 9 | VerifiedByProvider (output) | varchar | YES | - | CODE-BACKED | Verification provider. |
| 10 | PlayerStatusID (output) | int | YES | - | CODE-BACKED | Account status. |
| 11 | SuitabilityTestStatusID (output) | int | YES | - | CODE-BACKED | MiFID suitability. |
| 12 | PlayerStatusReasonID (output) | int | YES | - | CODE-BACKED | Status reason. |
| 13 | IsCopyBlocked (output) | int | YES | - | CODE-BACKED | Copy trading block (1 or NULL). |
| 14 | EvProviderId (output) | int | YES | - | CODE-BACKED | Latest identity EV provider. |
| 15 | EvResultsStatus (output) | int | YES | - | CODE-BACKED | Latest identity EV status. |
| 16 | EvMatchStatus (output) | int | YES | - | CODE-BACKED | EV match status. |
| 17 | MifidCategorizationID (output) | int | YES | - | CODE-BACKED | MiFID categorization. |
| 18 | AsicClassificationID (output) | int | YES | - | CODE-BACKED | ASIC classification. |
| 19 | SeychellesCategorizationID (output) | int | YES | - | CODE-BACKED | Seychelles categorization. |
| 20 | DesignatedRegulationID (output) | int | YES | - | CODE-BACKED | Designated regulation. |
| 21 | TradingRiskStatusID (output) | int | YES | - | CODE-BACKED | Trading risk status. |
| 22 | PlayerStatusSubReasonID (output) | int | YES | - | CODE-BACKED | Sub-reason. |
| 23 | PlayerStatusSubReasonComment (output) | nvarchar | YES | - | CODE-BACKED | Sub-reason comment. |
| 24 | EIDStatusID (output) | int | YES | - | CODE-BACKED | Electronic ID status. |
| 25 | OnboardingRiskClassificationID (output) | int | YES | - | CODE-BACKED | Onboarding risk. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerIdentification | SELECT | CID resolution |
| CID | dbo.Real_Customer | JOIN | Customer data |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Risk data |
| GCID | Ev.CustomerResult | CTE + result set 2 | EV history |
| EvProviderId | Dictionary.EvProvider | JOIN | Provider type |
| CID | dbo.BlockedCustomerOperations | OUTER APPLY | Copy block |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Fast risk info without docs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRiskUserInfoWithoutDocuments (procedure)
+-- Customer.CustomerIdentification (table)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- Ev.CustomerResult (table)
+-- Dictionary.EvProvider (table)
+-- dbo.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | SELECT - CID resolution |
| dbo.Real_Customer | Table | JOIN - customer data |
| dbo.Real_BackOfficeCustomer | Table | JOIN - risk data |
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

### 8.1 Get risk info without documents
```sql
EXEC Customer.GetRiskUserInfoWithoutDocuments @gcid = 12345
```

### 8.2 Compare risk SP variants
```sql
-- GetRiskUserInfo: full risk + doc classification + passport/utility split (slowest)
-- GetRiskUserInfoWithoutDocuments: full risk, no docs (faster)
-- GetRiskInfo: Customer schema, no docs (normalized tables)
```

### 8.3 Direct risk query
```sql
SELECT bc.RegulationID, bc.VerificationLevelID, cc.PlayerStatusID, bc.TradingRiskStatusID
FROM dbo.Real_Customer cc WITH (NOLOCK)
JOIN dbo.Real_BackOfficeCustomer bc WITH (NOLOCK) ON cc.CID = bc.CID
WHERE cc.GCID = @gcid
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRiskUserInfoWithoutDocuments | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRiskUserInfoWithoutDocuments.sql*
