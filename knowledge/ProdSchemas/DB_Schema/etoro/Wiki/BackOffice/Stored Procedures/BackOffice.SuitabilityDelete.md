# BackOffice.SuitabilityDelete

> Removes a customer from the BackOffice.Suitability whitelist, revoking their regulatory approval to trade complex financial instruments.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to remove from the whitelist |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SuitabilityDelete is the revocation entry point for the customer suitability compliance system. When a customer's suitability approval needs to be withdrawn - whether due to reassessment failure, a regulatory review, or customer request - a BackOffice compliance officer calls this procedure to remove the customer from the whitelist.

BackOffice.Suitability is a pure membership table: presence grants access to complex instruments, absence denies it. Removing a CID immediately revokes that access. The paired procedure, BackOffice.SuitabilityAdd, restores approval.

Like SuitabilityAdd, this procedure was introduced in October 2013 (author: elik, FB case 19119). The bulk risk update workflow (Bulk_UpdateRiskUserInfoRemote) also calls this procedure when a batch KYC update indicates a customer has failed or had their suitability reset.

---

## 2. Business Logic

### 2.1 Simple Whitelist Removal

**What**: Deletes the customer's CID from the suitability whitelist.

**Columns/Parameters Involved**: `@CID`

**Rules**:
- DELETE FROM BackOffice.Suitability WHERE CID=@CID
- No return value or error code (SET NOCOUNT ON)
- If @CID not found in Suitability: 0 rows affected, silent no-op (idempotent)
- No transaction wrapping - atomic single-row delete

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | The customer whose suitability approval is being revoked. Deletes the matching row from BackOffice.Suitability. If the CID is not present, the operation is a silent no-op (idempotent). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Suitability | WRITER (DELETE) | Removes the customer from the regulatory suitability whitelist |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice compliance/KYC workflows | - | Caller | Called when a customer fails reassessment or has suitability revoked |
| Bulk_UpdateRiskUserInfoRemote | SuitabilityTestStatusID | Caller | Calls this procedure when bulk KYC update payload indicates suitability failure or reset |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SuitabilityDelete (procedure)
└── BackOffice.Suitability (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Suitability | Table | DELETE WHERE CID=@CID - removes the customer from the whitelist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SuitabilityAdd | Stored Procedure | Paired inverse - adds what this procedure removes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Revoke suitability approval for a customer
```sql
EXEC BackOffice.SuitabilityDelete @CID = 12345678
```

### 8.2 Verify removal
```sql
SELECT COUNT(*) AS StillPresent
FROM BackOffice.Suitability WITH (NOLOCK)
WHERE CID = 12345678
-- Should return 0 after SuitabilityDelete
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SuitabilityDelete | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SuitabilityDelete.sql*
