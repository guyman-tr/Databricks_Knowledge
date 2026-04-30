# Customer.GetManyAggregatedInfoWithoutDocuments

> Variant of GetManyAggregatedInfo that skips the document classification step for better performance - returns the same comprehensive profile data but with an empty ClassifiedDocumentTypes field.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: full profile (no docs) + EV results |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyAggregatedInfoWithoutDocuments is a performance-optimized variant of Customer.GetManyAggregatedInfo. It returns the identical comprehensive customer profile (83 columns across basic, account, contact, risk, and settings data) plus EV results, but skips the expensive CROSS APPLY to dbo.CustomerClassifiedDocumentsTable. Instead, ClassifiedDocumentTypes is always returned as an empty string.

This procedure exists for callers that need the full aggregated profile but do NOT need document classification data. The CustomerClassifiedDocumentsTable TVF can be expensive for large batches, so skipping it improves response time significantly.

The procedure has the same structure as GetManyAggregatedInfo: temp tables with indexes, CTEs for copyBlock and evResult, TRY/CATCH error handling, and two result sets. The only difference is the absence of #customerDocuments population via CROSS APPLY.

---

## 2. Business Logic

### 2.1 Copy Block Detection

**What**: Same as GetManyAggregatedInfo - checks BlockedCustomerOperations with OperationTypeID=1.

**Columns/Parameters Involved**: `IsCopyBlocked`, `BlockedCustomerOperations.OperationTypeID`

**Rules**:
- CTE `copyBlock` uses TOP 1 (slight difference from GetManyAggregatedInfo which has no TOP 1)
- IsCopyBlocked = 1 if blocked, 0 otherwise

### 2.2 Electronic Verification Results

**What**: Same as GetManyAggregatedInfo - second result set with full EV history.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve aggregated info for. |
| 2-83 | (Same as GetManyAggregatedInfo) | - | - | - | CODE-BACKED | All 83 output columns are identical to GetManyAggregatedInfo. See Customer.GetManyAggregatedInfo for full element descriptions. Key difference: ClassifiedDocumentTypes is always empty string ('') instead of populated from the TVF. Also includes OnboardingRiskClassificationID (not in the original GetManyAggregatedInfo). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Real_Customer | JOIN | Core customer data |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Back-office/risk data |
| GCID | Customer.CustomerIdentification | LEFT JOIN | DemoCID |
| CID | dbo.Real_ElectronicIdentityCheck | LEFT JOIN | GDC check ID |
| CID | dbo.BlockedCustomerOperations | LEFT JOIN | Copy block status |
| GCID | Ev.CustomerResult | LEFT JOIN | EV results |
| CID | dbo.General_Settings | LEFT JOIN | Privacy settings |
| CID | dbo.Publications | LEFT JOIN | User bio |
| EvProviderId | Dictionary.EvProvider | LEFT JOIN | EV provider type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Performance-optimized aggregated info retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyAggregatedInfoWithoutDocuments (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- Customer.CustomerIdentification (table)
+-- dbo.Real_ElectronicIdentityCheck (table)
+-- dbo.BlockedCustomerOperations (table)
+-- Ev.CustomerResult (table)
+-- dbo.General_Settings (table)
+-- dbo.Publications (table)
+-- Dictionary.EvProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | INTO #RealCustomer - core data |
| dbo.Real_BackOfficeCustomer | Table | JOIN on CID - risk/account |
| Customer.CustomerIdentification | Table | LEFT JOIN - DemoCID |
| dbo.Real_ElectronicIdentityCheck | Table | LEFT JOIN - GDC check |
| dbo.BlockedCustomerOperations | Table | CTE - copy block |
| Ev.CustomerResult | Table | CTE + result set 2 - EV |
| dbo.General_Settings | Table | LEFT JOIN - settings |
| dbo.Publications | Table | LEFT JOIN - bio |
| Dictionary.EvProvider | Table | LEFT JOIN - EV provider |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error handling | Same error handling as GetManyAggregatedInfo |

---

## 8. Sample Queries

### 8.1 Get aggregated info without documents
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002)
EXEC Customer.GetManyAggregatedInfoWithoutDocuments @ids = @ids
```

### 8.2 Compare with full version
```sql
-- Use this when document classification is not needed
-- Use GetManyAggregatedInfo when ClassifiedDocumentTypes is required
-- This version skips the expensive CustomerClassifiedDocumentsTable TVF call
```

### 8.3 Check performance difference
```sql
-- GetManyAggregatedInfoWithoutDocuments is faster for large batches because
-- it skips the per-customer CROSS APPLY to CustomerClassifiedDocumentsTable
-- The rest of the query plan is identical
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 9/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 83 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyAggregatedInfoWithoutDocuments | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyAggregatedInfoWithoutDocuments.sql*
