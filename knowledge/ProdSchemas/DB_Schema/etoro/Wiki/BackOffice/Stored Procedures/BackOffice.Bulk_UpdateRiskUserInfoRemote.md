# BackOffice.Bulk_UpdateRiskUserInfoRemote

> Applies a batch of risk and compliance field updates to BackOffice.Customer and Customer.CustomerStatic from a pre-populated temp table (#BulkUpdateRiskUserInfo), using GCID-based matching and NULL-preserving updates.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | #BulkUpdateRiskUserInfo.GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the risk and compliance component of the three-procedure bulk update suite. Bulk_UpdateRiskUserInfoRemote handles regulatory and verification fields: the regulatory entity governing the customer (RegulationID), phone verification status, KYC verification level, copy-trading suitability test status, and player status classifications (status, reason, sub-reason).

These fields are central to regulatory compliance - RegulationID and VerificationLevelID have explicit FK constraints on BackOffice.Customer (noted in a code comment: "before adding new fields for update - check if there is FK for this column"). The procedure updates two tables: BackOffice.Customer (via GCID->CID resolution through CustomerStatic) for regulation/KYC fields, and Customer.CustomerStatic directly for player status fields.

DocumentStatusID was previously updated by this procedure but has been commented out - the field is now managed elsewhere.

---

## 2. Business Logic

### 2.1 Dual-Table Risk Field Update

**What**: Updates regulation/verification fields in BackOffice.Customer and player status fields in Customer.CustomerStatic.

**Tables Involved**: `#BulkUpdateRiskUserInfo`, `BackOffice.Customer`, `Customer.CustomerStatic`

**Rules**:
- Reads from temp table `#BulkUpdateRiskUserInfo` (must exist on calling connection)
- No parameters accepted
- **Update 1**: BackOffice.Customer SET RegulationID, PhoneVerifiedID, VerificationLevelID, SuitabilityTestStatusID - joined via Customer.CustomerStatic for GCID->CID resolution
- **Update 2**: Customer.CustomerStatic SET PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID WHERE GCID matches directly
- ISNULL(BulkTable.Value, CurrentValue) - NULL = preserve existing
- FK-constrained columns noted in code: RegulationID (FK), VerificationLevelID (FK), PlayerStatusID (FK), PlayerStatusSubReasonID (FK)
- DocumentStatusID was removed from this procedure (commented out) - managed elsewhere
- No transaction - two sequential UPDATEs; partial update possible if second fails

### 2.2 GCID-to-CID Resolution

**What**: BackOffice.Customer is keyed by CID, not GCID. First UPDATE joins through CustomerStatic.

**Rules**:
- `FROM Customer.CustomerStatic as CC INNER JOIN #BulkUpdateRiskUserInfo as BulkTable ON CC.GCID = BulkTable.GCID WHERE BackOffice.Customer.CID = CC.CID`
- Same pattern as Bulk_UpdateAccountUserInfoRemote

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Temp Table Input (no parameters - reads from #BulkUpdateRiskUserInfo):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | (caller-defined) | NO | - | CODE-BACKED | Global Customer ID used to match rows. Join key for all updates. |
| 2 | RegulatingEntityId | (caller-defined) | YES | - | CODE-BACKED | Maps to BackOffice.Customer.RegulationID (FK). NULL = preserve. The regulatory jurisdiction governing this customer (e.g., CySec, FCA, ASIC). |
| 3 | PhoneVerificationStatus | (caller-defined) | YES | - | CODE-BACKED | Maps to BackOffice.Customer.PhoneVerifiedID. NULL = preserve. Whether the customer's phone number has been verified. |
| 4 | VerificationLevel | (caller-defined) | YES | - | CODE-BACKED | Maps to BackOffice.Customer.VerificationLevelID (FK). NULL = preserve. KYC document verification level achieved by the customer. |
| 5 | CopySuitabilityTestStatus | (caller-defined) | YES | - | CODE-BACKED | Maps to BackOffice.Customer.SuitabilityTestStatusID. NULL = preserve. Status of the customer's copy-trading suitability assessment. |
| 6 | PlayerStatus | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.PlayerStatusID (FK). NULL = preserve. Overall player/customer status classification. |
| 7 | PlayerStatusReason | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.PlayerStatusReasonID. NULL = preserve. Reason code for the current player status. |
| 8 | PlayerStatusSubReason | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.CustomerStatic.PlayerStatusSubReasonID (FK). NULL = preserve. Sub-reason code providing additional detail for the player status. |

**Removed field (commented out in code):**

| 9 | DocumentStatus | - | - | - | CODE-BACKED | Was: BackOffice.Customer.DocumentStatusID. Removed - document status is now managed through other means (e.g., AddDocumentClassification). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| #BulkUpdateRiskUserInfo.GCID | BackOffice.Customer | MODIFIER | Bulk-updates regulation, verification, and suitability fields via GCID->CID resolution |
| #BulkUpdateRiskUserInfo.GCID | Customer.CustomerStatic | MODIFIER | Bulk-updates player status fields directly by GCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestration / sync service | #BulkUpdateRiskUserInfo temp table | Caller | Creates temp table, populates it, then calls this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Bulk_UpdateRiskUserInfoRemote (procedure)
|- #BulkUpdateRiskUserInfo (temp table) [caller must create and populate before EXEC]
|- BackOffice.Customer (table) [UPDATE target - risk/compliance fields]
+-- Customer.CustomerStatic (table) [UPDATE target - player status fields; also used for GCID->CID resolution]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| #BulkUpdateRiskUserInfo | Temp Table | Source data - must exist on calling connection |
| BackOffice.Customer | Table | UPDATE target for RegulationID, PhoneVerifiedID, VerificationLevelID, SuitabilityTestStatusID |
| Customer.CustomerStatic | Table (cross-schema) | UPDATE target for PlayerStatusID/ReasonID/SubReasonID; also used for GCID->CID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External bulk update service | External | Calls after populating #BulkUpdateRiskUserInfo |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No parameters | Design | Reads exclusively from temp table |
| ISNULL preserving pattern | Design | NULL in bulk table = keep existing value |
| FK columns | Referential Integrity | RegulationID, VerificationLevelID, PlayerStatusID, PlayerStatusSubReasonID have FK constraints - invalid values cause FK violations |
| DocumentStatusID removed | Change history | Commented out - document status managed elsewhere |
| No transaction | Design | Two sequential UPDATEs; partial update possible if second fails |
| FK warning comment | Code quality | Developer left comment: "before adding new fields - check if there is FK for this column" |

---

## 8. Sample Queries

### 8.1 Bulk update regulation and verification level

```sql
CREATE TABLE #BulkUpdateRiskUserInfo (
    GCID                        INT,
    RegulatingEntityId          INT,
    PhoneVerificationStatus     INT,
    VerificationLevel           INT,
    CopySuitabilityTestStatus   INT,
    PlayerStatus                INT,
    PlayerStatusReason          INT,
    PlayerStatusSubReason       INT
)

INSERT INTO #BulkUpdateRiskUserInfo (GCID, RegulatingEntityId, VerificationLevel)
VALUES (100001, 1, 3), (100002, 1, 3)  -- set CySec regulation, level 3

EXEC BackOffice.Bulk_UpdateRiskUserInfoRemote

DROP TABLE #BulkUpdateRiskUserInfo
```

### 8.2 Verify updates

```sql
SELECT bc.CID, bc.RegulationID, bc.VerificationLevelID, bc.SuitabilityTestStatusID,
       cs.PlayerStatusID, cs.PlayerStatusReasonID
FROM Customer.CustomerStatic cs WITH (NOLOCK)
JOIN BackOffice.Customer bc WITH (NOLOCK) ON bc.CID = cs.CID
WHERE cs.GCID IN (100001, 100002)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Bulk_UpdateRiskUserInfoRemote | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.Bulk_UpdateRiskUserInfoRemote.sql*
