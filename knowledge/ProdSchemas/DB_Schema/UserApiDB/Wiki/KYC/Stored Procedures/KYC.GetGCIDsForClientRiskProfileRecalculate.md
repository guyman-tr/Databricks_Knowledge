# KYC.GetGCIDsForClientRiskProfileRecalculate

> Returns batches of 1000 verified user GCIDs for client risk profile recalculation, paginated by GCID with regulation filtering.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCIDToStart + @RegulationID (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetGCIDsForClientRiskProfileRecalculate returns batches of up to 1000 distinct verified users (VerificationLevelID >= 2) for risk profile recalculation. Unlike the Appropriateness SPs, this one does NOT return answer data - just GCID, CID, VerificationLevelID, and DesignatedRegulationID. Uses Customer.CustomerIdentification instead of Real_Customer for CID mapping.

---

## 2. Business Logic

Fixed batch size of 1000. Paginated by @GCIDToStart. Same regulation filtering as bulk appropriateness SP.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCIDToStart | int (IN) | NO | - | CODE-BACKED | Pagination cursor. |
| 2 | @RegulationID | int (IN) | YES | NULL | CODE-BACKED | Optional regulation filter. NULL = (1,2,4,10). |

Output: GCID, CID, VerificationLevelID, DesignatedRegulationID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CustomerIdentification | SELECT FROM | GCID-CID mapping |
| - | dbo.Real_BackOfficeCustomer | JOIN | Regulation/verification |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetGCIDsForClientRiskProfileRecalculate (procedure)
  +-- Customer.CustomerIdentification (table) [done]
  +-- dbo.Real_BackOfficeCustomer (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | SELECT FROM |
| dbo.Real_BackOfficeCustomer | Synonym | JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 First batch
```sql
EXEC KYC.GetGCIDsForClientRiskProfileRecalculate @GCIDToStart = 0
```

### 8.2 With regulation
```sql
EXEC KYC.GetGCIDsForClientRiskProfileRecalculate @GCIDToStart = 0, @RegulationID = 1
```

### 8.3 Pagination
```sql
EXEC KYC.GetGCIDsForClientRiskProfileRecalculate @GCIDToStart = 100000
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetGCIDsForClientRiskProfileRecalculate | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetGCIDsForClientRiskProfileRecalculate.sql*
