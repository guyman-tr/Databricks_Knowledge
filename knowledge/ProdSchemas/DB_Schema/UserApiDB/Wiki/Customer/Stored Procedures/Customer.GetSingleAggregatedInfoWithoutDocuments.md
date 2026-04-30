# Customer.GetSingleAggregatedInfoWithoutDocuments

> Single-customer version of GetManyAggregatedInfoWithoutDocuments - full aggregated profile without document classification for better performance.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: full profile (no docs) + EV history |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetSingleAggregatedInfoWithoutDocuments is the performance-optimized variant of GetSingleAggregatedInfo. It returns the identical 83-column profile plus EV results, but ClassifiedDocumentTypes is always empty string. Uses CTE copyBlock instead of direct LEFT JOIN, and resolves CID via CustomerIdentification before joining Real_Customer.

---

## 2. Business Logic

### 2.1 Copy Block via CTE

**What**: Uses a CTE with TOP 1 pattern for copy block.

**Rules**: CTE copyBlock selects TOP 1 from BlockedCustomerOperations WHERE CID=@CID AND OperationTypeID=1, producing IsCopyBlocked=1 or NULL.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2-83 | (Same as GetSingleAggregatedInfo) | - | - | - | CODE-BACKED | Identical output. ClassifiedDocumentTypes is always empty string. See GetSingleAggregatedInfo/GetManyAggregatedInfo for full descriptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerIdentification | SELECT | CID resolution |
| @GCID | dbo.Real_Customer | JOIN | Core data |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Risk/account |
| CID | dbo.Real_ElectronicIdentityCheck | LEFT JOIN | GDC |
| CID | dbo.BlockedCustomerOperations | CTE | Copy block |
| GCID | Ev.CustomerResult | CTE + result set 2 | EV |
| CID | dbo.General_Settings | LEFT JOIN | Settings |
| CID | dbo.Publications | LEFT JOIN | Bio |
| EvProviderId | Dictionary.EvProvider | JOIN | Provider type |
| GCID | Customer.CustomerIdentification | LEFT JOIN | DemoCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Fast single-customer profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetSingleAggregatedInfoWithoutDocuments (procedure)
+-- Customer.CustomerIdentification (table)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
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
| (9 tables as listed above) | Tables | Various JOINs and CTEs |

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

### 8.1 Get aggregated info without docs
```sql
EXEC Customer.GetSingleAggregatedInfoWithoutDocuments @GCID = 12345
```

### 8.2 Performance comparison
```sql
-- Use GetSingleAggregatedInfoWithoutDocuments when doc classification is not needed
-- Use GetSingleAggregatedInfo when ClassifiedDocumentTypes is required
```

### 8.3 Direct query
```sql
SELECT cc.GCID, cc.CID AS RealCID, bc.RegulationID, bc.VerificationLevelID
FROM dbo.Real_Customer cc WITH (NOLOCK)
JOIN dbo.Real_BackOfficeCustomer bc WITH (NOLOCK) ON cc.CID = bc.CID
WHERE cc.GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 9/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 83 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetSingleAggregatedInfoWithoutDocuments | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetSingleAggregatedInfoWithoutDocuments.sql*
