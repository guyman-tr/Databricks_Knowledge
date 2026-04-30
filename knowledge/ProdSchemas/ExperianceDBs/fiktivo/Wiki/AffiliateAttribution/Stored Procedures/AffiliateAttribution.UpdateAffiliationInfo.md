# AffiliateAttribution.UpdateAffiliationInfo

> Transactional re-attribution procedure that updates the AffiliateID on all Tier-1 commission records (credits, closed positions, registrations) for a customer, effectively transferring the customer from one affiliate to another.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAttribution |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE AffiliateID on 3 commission tables for a CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAttribution.UpdateAffiliationInfo is the core re-attribution procedure that changes which affiliate receives commission for a customer. When business rules determine that a customer should be attributed to a different affiliate (e.g., a re-attribution request approved by operations), this procedure updates the AffiliateID on all three Tier-1 commission record tables: CreditCommission (FTD/deposit commissions), ClosedPositionCommission (revenue share commissions), and RegistrationCommission (registration commissions).

This procedure exists because affiliate attribution errors or business rule changes require retroactive correction of commission assignments. Without it, the wrong affiliate would continue to receive commissions for a customer's activity, and correcting individual records manually across three tables would be error-prone and inconsistent.

Called by the Databricks re-attribution notebook after GetAffiliateInfo confirms eligibility. The procedure runs all three UPDATEs within a single transaction with XACT_ABORT ON, ensuring atomicity - either all commission records are re-attributed or none are. Only Tier-1 (direct affiliate) commissions are affected; sub-affiliate tiers are not modified.

---

## 2. Business Logic

### 2.1 Three-Table Atomic Re-Attribution

**What**: Updates AffiliateID on all Tier-1 commission records for a customer within a single transaction.

**Columns/Parameters Involved**: `@AffiliateID`, `@CID`

**Rules**:
- UPDATE 1: AffiliateCommission.CreditCommission SET AffiliateID = @AffiliateID WHERE Tier=1 AND CID=@CID (via JOIN to Credit table)
- UPDATE 2: AffiliateCommission.ClosedPositionCommission SET AffiliateID = @AffiliateID WHERE Tier=1 AND CID=@CID (via JOIN to ClosedPosition table)
- UPDATE 3: AffiliateCommission.RegistrationCommission SET AffiliateID = @AffiliateID WHERE Tier=1 AND CID=@CID (via JOIN to Registration table)
- All 3 UPDATEs run within BEGIN TRAN / COMMIT with XACT_ABORT ON
- Only Tier=1 records are updated - sub-affiliate tiers (2+) are not affected
- The CID filter is applied via JOIN to the parent table (Credit.CID, ClosedPosition.CID, Registration.CID) since the commission tables don't have CID directly

**Diagram**:
```
Databricks: "Re-attribute CID 12345 to Affiliate 67890"
    |
    | EXEC UpdateAffiliationInfo @AffiliateID=67890, @CID=12345
    v
BEGIN TRAN (XACT_ABORT ON)
    |
    +-- UPDATE CreditCommission SET AffiliateID=67890
    |     WHERE Tier=1 AND Credit.CID=12345
    |
    +-- UPDATE ClosedPositionCommission SET AffiliateID=67890
    |     WHERE Tier=1 AND ClosedPosition.CID=12345
    |
    +-- UPDATE RegistrationCommission SET AffiliateID=67890
    |     WHERE Tier=1 AND Registration.CID=12345
    |
    v
COMMIT (all-or-nothing)
```

### 2.2 Tier-1 Only Scope

**What**: Only direct affiliate (Tier=1) commission records are re-attributed.

**Columns/Parameters Involved**: `Tier` (on commission tables)

**Rules**:
- Tier=1 represents the direct referral affiliate - the one who originally brought the customer
- Tiers 2+ represent sub-affiliates in the hierarchy who receive a share of the Tier-1 affiliate's commission
- Re-attribution changes WHO the customer is attributed to at the direct level
- Sub-affiliate commissions are derived from the Tier-1 affiliate, so they may need separate recalculation (handled by UpdateEvents triggering re-processing)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int | NO | - | CODE-BACKED | The new affiliate ID to attribute this customer to. All Tier-1 commission records for the CID will have their AffiliateID set to this value. |
| 2 | @CID | bigint | NO | - | CODE-BACKED | The customer ID being re-attributed. Used to find all commission records across CreditCommission (via Credit.CID), ClosedPositionCommission (via ClosedPosition.CID), and RegistrationCommission (via Registration.CID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditCommission | MODIFY (UPDATE) | Updates AffiliateID on Tier-1 credit commission records |
| - | AffiliateCommission.Credit | READ (JOIN) | Joined on CreditID to filter by CID |
| - | AffiliateCommission.ClosedPositionCommission | MODIFY (UPDATE) | Updates AffiliateID on Tier-1 closed position commission records |
| - | AffiliateCommission.ClosedPosition | READ (JOIN) | Joined on ClosedPositionID to filter by CID |
| - | AffiliateCommission.RegistrationCommission | MODIFY (UPDATE) | Updates AffiliateID on Tier-1 registration commission records |
| - | AffiliateCommission.Registration | READ (JOIN) | Joined on RegistrationID to filter by CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Databricks Notebook (external) | - | Caller | Re-attribution workflow step 2: update commission records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAttribution.UpdateAffiliationInfo (procedure)
+-- AffiliateCommission.CreditCommission (table, cross-schema)
+-- AffiliateCommission.Credit (table, cross-schema)
+-- AffiliateCommission.ClosedPositionCommission (table, cross-schema)
+-- AffiliateCommission.ClosedPosition (table, cross-schema)
+-- AffiliateCommission.RegistrationCommission (table, cross-schema)
+-- AffiliateCommission.Registration (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditCommission | Table | UPDATE target - sets AffiliateID for FTD/deposit commissions |
| AffiliateCommission.Credit | Table | JOIN filter - identifies records by CID |
| AffiliateCommission.ClosedPositionCommission | Table | UPDATE target - sets AffiliateID for revenue share commissions |
| AffiliateCommission.ClosedPosition | Table | JOIN filter - identifies records by CID |
| AffiliateCommission.RegistrationCommission | Table | UPDATE target - sets AffiliateID for registration commissions |
| AffiliateCommission.Registration | Table | JOIN filter - identifies records by CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Databricks Notebook (external) | External | Calls after GetAffiliateInfo to perform the re-attribution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XACT_ABORT ON | Transaction Safety | Automatically rolls back the entire transaction on any error - ensures all 3 UPDATEs succeed or none do |
| BEGIN TRAN / COMMIT | Atomicity | All 3 commission table UPDATEs are atomic - prevents partial re-attribution |

---

## 8. Sample Queries

### 8.1 Re-attribute a customer to a new affiliate
```sql
EXEC AffiliateAttribution.UpdateAffiliationInfo @AffiliateID = 67890, @CID = 12345
```

### 8.2 Verify re-attribution was applied (check credit commissions)
```sql
SELECT CC.AffiliateID, CC.Tier, C.CID, C.CreditDate
FROM AffiliateCommission.CreditCommission CC WITH (NOLOCK)
JOIN AffiliateCommission.Credit C WITH (NOLOCK) ON CC.CreditID = C.CreditID
WHERE C.CID = 12345 AND CC.Tier = 1
```

### 8.3 Verify re-attribution across all 3 tables
```sql
SELECT 'Credit' AS Source, CC.AffiliateID, CC.Tier
FROM AffiliateCommission.CreditCommission CC WITH (NOLOCK)
JOIN AffiliateCommission.Credit C WITH (NOLOCK) ON CC.CreditID = C.CreditID
WHERE C.CID = 12345 AND CC.Tier = 1
UNION ALL
SELECT 'ClosedPosition', CPC.AffiliateID, CPC.Tier
FROM AffiliateCommission.ClosedPositionCommission CPC WITH (NOLOCK)
JOIN AffiliateCommission.ClosedPosition CP WITH (NOLOCK) ON CPC.ClosedPositionID = CP.ClosedPositionID
WHERE CP.CID = 12345 AND CPC.Tier = 1
UNION ALL
SELECT 'Registration', RC.AffiliateID, RC.Tier
FROM AffiliateCommission.RegistrationCommission RC WITH (NOLOCK)
JOIN AffiliateCommission.Registration R WITH (NOLOCK) ON RC.RegistrationID = R.RegistrationID
WHERE R.CID = 12345 AND RC.Tier = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-1999 (referenced in SQL comments) | Jira | New SP for Databricks notebook - affiliate re-attribution (Oct 2023, Gil Haba) |
| PART-2440 (referenced in SQL comments) | Jira | Fixed support for new CPA revenue in re-attribution (Jan 2024, Gil Haba) |

No Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 2 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAttribution.UpdateAffiliationInfo | Type: Stored Procedure | Source: fiktivo/AffiliateAttribution/Stored Procedures/AffiliateAttribution.UpdateAffiliationInfo.sql*
