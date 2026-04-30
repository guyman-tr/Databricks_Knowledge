# Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325

> **DEPRECATED / JUNK** - Legacy POI document expiration SP, virtually identical to the active `Compliance.GetPOIDocumentsExpirationPopulation` but with the `@MaxAllowedProcessingRowsPerCycle` parameter removed. Retained for historical reference only.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate, @IsInternal (inputs); CID, GCID (outputs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**DEPRECATED** - This procedure carries the `_JUNKYulia0325` suffix. The active replacement is `Compliance.GetPOIDocumentsExpirationPopulation`.

This is functionally near-identical to the active `GetPOIDocumentsExpirationPopulation` SP, differing only in that the `@MaxAllowedProcessingRowsPerCycle` parameter is **commented out** here (`--@MaxAllowedProcessingRowsPerCycle Int`), while the active SP still declares it (albeit as a dead/unused parameter). The same 15-day window, same filters, same DocumentTypeID=2 (POI), and same stored ExpiryDate logic all apply.

This appears to be the clean version created after removing the batch-size concept, while the active SP version accidentally retained the dead parameter declaration. Both versions are functionally equivalent at runtime.

Same change history: tickets 49112 (2017), RD-630 (2018), RD-10777/16557 (2019).

---

## 2. Business Logic

### 2.1 POI Document Expiry (Same as Active SP)

**What**: Returns customers with expiring POI documents within a 15-day window, using stored ExpiryDate.

**Rules**:
- DocumentTypeID=2 (Proof of Identity)
- ExpiryDate used directly from CDTDT (no computation)
- @EndDate = 15 days from today UTC
- Same customer eligibility filters as `GetPOIDocumentsExpirationPopulation` (VerificationLevelID=3, AccountTypeID exclusions, EvMatchStatus, block status, approved deposit)
- `@MaxAllowedProcessingRowsPerCycle` is COMMENTED OUT - not a parameter of this SP (unlike the active version where it exists but is unused)

See `Compliance.GetPOIDocumentsExpirationPopulation` for full business logic documentation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the expiration window (same as active SP). |
| 2 | @IsInternal | BIT | NO | - | CODE-BACKED | 0 = external customers; 1 = internal employees (PlayerLevelID=4). Same as active SP. |

**Return Result Set** - identical to `Compliance.GetPOIDocumentsExpirationPopulation`. See that SP's documentation for column descriptions.

| # | Column | Description |
|---|--------|-------------|
| R1 | RowNumber | Always 1 - latest expiring POI per customer |
| R2 | GCID | Global Customer ID |
| R3 | CID | eToro customer ID |
| R4-R15 | (same columns) | Identical to active SP - see `Compliance.GetPOIDocumentsExpirationPopulation.md` |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as `Compliance.GetPOIDocumentsExpirationPopulation`:

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | BackOffice.CustomerDocumentToDocumentType | JOIN | Primary source - DocumentTypeID=2, ExpiryDate |
| - | BackOffice.CustomerDocument | JOIN | CID and Obsolete flag |
| - | BackOffice.Customer | JOIN | Eligibility filters |
| - | Customer.Customer | JOIN | Block status, PlayerLevelID; GCID, UserName, Email |
| - | Dictionary.PlayerStatus | Lookup | Blocked status IDs |
| - | Billing.Deposit | EXISTS | Approved deposit check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none) | - | - | No callers found. Deprecated - use active SP instead. |
| Compliance.GetPOIDocumentsExpirationPopulation | - | Active replacement | The active SP version. Functionally identical at runtime; retains the @MaxAllowedProcessingRowsPerCycle dead parameter declaration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325 (procedure - DEPRECATED)
├── BackOffice.CustomerDocumentToDocumentType (table)
├── BackOffice.CustomerDocument (table)
├── BackOffice.Customer (table)
├── Customer.Customer (table)
├── Dictionary.PlayerStatus (table)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

Same as `Compliance.GetPOIDocumentsExpirationPopulation`. See that SP's documentation.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | No dependents. Deprecated. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Same constraints as active SP. Key difference: `@MaxAllowedProcessingRowsPerCycle` is commented out here.

---

## 8. Sample Queries

### 8.1 DO NOT CALL - use the active SP instead

```sql
-- DO NOT USE: Deprecated. Use the active SP:
EXEC [Compliance].[GetPOIDocumentsExpirationPopulation]
    @StartDate = GETUTCDATE(),
    @MaxAllowedProcessingRowsPerCycle = 0,
    @IsInternal = 0;
```

### 8.2 Difference between this and active SP

```sql
-- This SP (JUNK): 2 parameters (@StartDate, @IsInternal)
-- Active SP: 3 parameters (@StartDate, @MaxAllowedProcessingRowsPerCycle [unused], @IsInternal)
-- Runtime behavior: identical
```

### 8.3 Verify both SPs return same results

```sql
-- For verification only - use active SP in production
EXEC [Compliance].[GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325]
    @StartDate = '2026-01-01',
    @IsInternal = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. See `Compliance.GetPOIDocumentsExpirationPopulation` for full context. Same DDL change history applies.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.0/10, Logic: 7.5/10, Relationships: 7.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325 | Type: Stored Procedure (DEPRECATED) | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325.sql*
