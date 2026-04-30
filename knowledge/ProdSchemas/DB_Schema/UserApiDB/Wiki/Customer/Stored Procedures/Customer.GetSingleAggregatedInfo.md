# Customer.GetSingleAggregatedInfo

> Single-customer version of GetManyAggregatedInfo - retrieves the complete aggregated profile (83+ columns across basic, account, contact, risk, settings, EV) for one GCID with document classification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: full profile + EV history for single GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetSingleAggregatedInfo is the single-customer equivalent of Customer.GetManyAggregatedInfo. It returns the same comprehensive profile (basic info, account info, contact info, risk info, user settings, EV results) but is optimized for a single GCID parameter instead of a batch IdList. It uses String_agg for document classification (instead of the CROSS APPLY TVF used by the batch version) and uses a variable (@docNames) instead of a temp table.

This procedure returns 2 result sets: the full aggregated profile and the complete EV transaction history.

---

## 2. Business Logic

### 2.1 Copy Block Detection

**What**: Checks BlockedCustomerOperations for OperationTypeID=1 via LEFT JOIN.

**Rules**: ISNULL(bco.OperationTypeID, 0) returns 0 when not blocked, 1 when copy-blocked.

### 2.2 Document Classification

**What**: Uses String_agg of distinct valid DocumentTypeIDs.

**Rules**: Same expiry logic as GetRiskUserInfo - ExpiryDate check or age-based via MaxAgeInMonths.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID to retrieve. |
| 2-83 | (Same as GetManyAggregatedInfo) | - | - | - | CODE-BACKED | All output columns identical to GetManyAggregatedInfo: GCID, RealCID, CID, DemoCID, names, gender, language, birth date, player level, Lei, account info (affiliate, label, type, registration, trade level, currency, closure, manager, guru, funnel, download, referral), contact info (country, email, address, phone, state, IP country, citizenship, POB, building, region, sub-region), risk info (regulation, doc status, phone verified, verification level, GDC check, classified docs, player status/reason/sub-reason, suitability, copy block, EV, KYC state, MiFID, ASIC, Seychelles, designated regulation, trading risk, EID, onboarding risk), settings (privacy, display, share, homepage, opt-out, EV match, bio, strategy, email verified). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | dbo.Real_Customer | JOIN | Core data |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Risk/account data |
| GCID | Customer.CustomerIdentification | LEFT JOIN | DemoCID |
| CID | dbo.Real_ElectronicIdentityCheck | LEFT JOIN | GDC check |
| CID | dbo.BlockedCustomerOperations | LEFT JOIN | Copy block |
| GCID | Ev.CustomerResult | CTE + result set 2 | EV |
| CID | dbo.General_Settings | LEFT JOIN | Settings |
| CID | dbo.Publications | LEFT JOIN | Bio |
| - | dbo.CustomerDocumentToDocumentType | SELECT | Doc classification |
| - | Dictionary.EvProvider | JOIN | EV provider type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Single-customer full profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetSingleAggregatedInfo (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- Customer.CustomerIdentification (table)
+-- dbo.Real_ElectronicIdentityCheck (table)
+-- dbo.BlockedCustomerOperations (table)
+-- Ev.CustomerResult (table)
+-- dbo.General_Settings (table)
+-- dbo.Publications (table)
+-- dbo.CustomerDocumentToDocumentType (table)
+-- dbo.CustomerDocument (table)
+-- dbo.DocumentType (table)
+-- Dictionary.EvProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| (12 tables as listed above) | Tables | Various JOINs and CTEs |

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

### 8.1 Get single aggregated info
```sql
EXEC Customer.GetSingleAggregatedInfo @GCID = 12345
-- Returns 2 result sets
```

### 8.2 Compare with batch version
```sql
-- GetSingleAggregatedInfo: single @GCID param, String_agg for docs
-- GetManyAggregatedInfo: IdList TVP, CROSS APPLY TVF for docs, temp tables
-- Output columns are identical
```

### 8.3 Compare with no-docs version
```sql
-- GetSingleAggregatedInfo: includes document classification
-- GetSingleAggregatedInfoWithoutDocuments: skips doc classification (faster)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 9/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 83 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetSingleAggregatedInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetSingleAggregatedInfo.sql*
