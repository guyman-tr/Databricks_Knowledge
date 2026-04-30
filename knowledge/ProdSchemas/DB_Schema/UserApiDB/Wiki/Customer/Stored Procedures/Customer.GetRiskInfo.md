# Customer.GetRiskInfo

> Retrieves risk and compliance data for a single customer from Customer.RiskUserInfo (normalized table) with EV results - the Customer schema version of risk info retrieval.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: risk profile + EV history |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRiskInfo retrieves risk and compliance data for a single customer from the normalized Customer.RiskUserInfo table (rather than the legacy dbo views). It returns regulation, document status, verification level, player status, EV results, and regulatory categorizations (MiFID, ASIC, Seychelles).

Unlike GetRiskUserInfo (which reads from dbo.Real_Customer + Real_BackOfficeCustomer and includes document classification), this procedure reads from Customer.RiskUserInfo and Customer.CustomerIdentification - the newer normalized schema. It returns two result sets: the risk profile and the full EV transaction history.

The EV result CTE filters for ProviderTypeID=0 (identity verification providers only, not document providers) to get the most recent verification.

---

## 2. Business Logic

### 2.1 EV Provider Type Filtering

**What**: The latest EV result CTE only considers ProviderTypeID=0 providers.

**Columns/Parameters Involved**: `EvProviderId`, `ProviderTypeID`, `EvStatusId`

**Rules**:
- CTE evResult: TOP 1 from Ev.CustomerResult WHERE ProviderTypeID=0 ORDER BY CustomerEvResultId DESC
- ProviderTypeID=0 = identity verification providers (e.g., Au10tix)
- Other provider types (document verification, etc.) are excluded from the inline EV status
- Second result set returns ALL EV records regardless of provider type

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID (echoed). |
| 3 | RealCID (output) | int | YES | - | CODE-BACKED | Real account CID from CustomerIdentification. |
| 4 | RegulationID (output) | int | YES | - | CODE-BACKED | Primary regulation. From RiskUserInfo. |
| 5 | DocumentStatusID (output) | int | YES | - | CODE-BACKED | Document verification status. |
| 6 | PhoneVerifiedID (output) | int | YES | - | CODE-BACKED | Phone verification status. |
| 7 | VerificationLevelID (output) | int | YES | - | CODE-BACKED | KYC verification level. |
| 8 | VerifiedBy (output) | varchar | YES | - | CODE-BACKED | Who verified the customer. |
| 9 | VerifiedByProvider (output) | varchar | YES | - | CODE-BACKED | Verification provider name. |
| 10 | PlayerStatusID (output) | int | YES | - | CODE-BACKED | Account lifecycle status. |
| 11 | SuitabilityTestStatusID (output) | int | YES | - | CODE-BACKED | MiFID suitability test status. |
| 12 | PlayerStatusReasonID (output) | int | YES | - | CODE-BACKED | Reason for current player status. |
| 13 | EvProviderId (output) | int | YES | - | CODE-BACKED | Latest identity EV provider (ProviderTypeID=0 only). |
| 14 | EvResultsStatus (output) | int | YES | - | CODE-BACKED | Latest identity EV status. |
| 15 | EvMatchStatus (output) | int | YES | - | CODE-BACKED | EV match status. |
| 16 | MifidCategorizationID (output) | int | YES | - | CODE-BACKED | MiFID client categorization. |
| 17 | AsicClassificationID (output) | int | YES | - | CODE-BACKED | ASIC classification. |
| 18 | DesignatedRegulationID (output) | int | YES | - | CODE-BACKED | Designated regulation override. |
| 19 | PlayerStatusSubReasonID (output) | int | YES | - | CODE-BACKED | Status sub-reason. |
| 20 | PlayerStatusSubReasonComment (output) | nvarchar | YES | - | CODE-BACKED | Sub-reason comment. |
| 21 | SeychellesCategorizationID (output) | int | YES | - | CODE-BACKED | Seychelles regulation categorization. |
| 22 | TradingRiskStatusID (output) | int | YES | - | CODE-BACKED | Trading risk assessment status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.RiskUserInfo | FROM | Normalized risk data |
| GCID | Customer.CustomerIdentification | JOIN | CID resolution |
| GCID | Ev.CustomerResult | CTE + result set 2 | EV history |
| EvProviderId | Dictionary.EvProvider | JOIN | Provider type filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Single-customer risk info |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRiskInfo (procedure)
+-- Customer.RiskUserInfo (table)
+-- Customer.CustomerIdentification (table)
+-- Ev.CustomerResult (table)
+-- Dictionary.EvProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskUserInfo | Table | FROM - risk data |
| Customer.CustomerIdentification | Table | JOIN - CID |
| Ev.CustomerResult | Table | CTE + result set 2 |
| Dictionary.EvProvider | Table | JOIN - provider type |

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

### 8.1 Get risk info
```sql
EXEC Customer.GetRiskInfo @gcid = 12345
-- Returns 2 result sets: risk profile + EV history
```

### 8.2 Direct risk query
```sql
SELECT ri.GCID, ri.RegulationID, ri.VerificationLevelID, ri.PlayerStatusID,
       ri.MifidCategorizationID, ri.TradingRiskStatusID
FROM Customer.RiskUserInfo ri WITH (NOLOCK)
WHERE ri.GCID = @gcid
```

### 8.3 Compare with legacy
```sql
-- GetRiskInfo: Customer.RiskUserInfo (normalized, no docs)
-- GetRiskUserInfo: dbo.Real_Customer + Real_BackOfficeCustomer (legacy, with doc classification)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRiskInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRiskInfo.sql*
