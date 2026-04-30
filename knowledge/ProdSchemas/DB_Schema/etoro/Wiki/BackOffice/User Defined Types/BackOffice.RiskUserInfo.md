# BackOffice.RiskUserInfo

> Table-valued parameter type that defines the schema for bulk-passing customer compliance and risk status fields for batch updates to customer verification and regulatory state.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | GCID (Group Customer ID - row key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.RiskUserInfo` is a Table-Valued Type (TVT) that defines the schema contract for passing a batch of customer compliance and risk status values in bulk update operations. Each row holds the regulatory and KYC compliance state for one customer: regulating entity, document verification status, phone verification status, verification level, player (account) status, copy suitability test status, and status reason.

This type exists to support the bulk remote update pattern used by compliance and risk sync services. The application-side (e.g., a compliance platform or UserAPI integration) computes the updated compliance state for a batch of customers and sends it to the BackOffice database as a typed table parameter, which the SP then uses to apply ISNULL-guarded updates (non-NULL fields update, NULL fields are left unchanged).

Data flows into this type from compliance/UserAPI sync services. The type was formerly used as a formal parameter in `BackOffice.Bulk_UpdateBasicUserInfoRemote` (code comment `--@BulkUpdateTable BackOffice.RiskUserInfo READONLY` shows the historical signature). The current SP implementation uses a temp table `#BulkUpdateBasicUserInfo` instead, but this TVT still defines the intended schema contract and may be used by other procedures or the separate `Bulk_UpdateRiskUserInfoRemote`.

---

## 2. Business Logic

### 2.1 Compliance State Bulk Update Pattern

**What**: A multi-field snapshot of a customer's compliance and risk posture, used as the source of truth for a single atomic bulk update pass.

**Columns/Parameters Involved**: `GCID`, `RegulatingEntityId`, `DocumentStatus`, `PhoneVerificationStatus`, `VerificationLevel`, `PlayerStatus`, `CopySuitabilityTestStatus`, `PlayerStatusReason`

**Rules**:
- GCID is the row key identifying which customer to update (Group Customer ID matching Customer.Customer.GCID).
- All status columns are nullable - NULL means "do not update this field". Non-NULL means "set this field to the given value."
- The consuming SP uses ISNULL guards: `SET Column = ISNULL(BulkTable.Column, ExistingValue)` so partial updates are supported.
- This pattern is consistent with sibling types `BackOffice.AccountUserInfo` and `BackOffice.BasicUserInfo` in the same schema.

**Diagram**:
```
Compliance sync service sends @updates AS BackOffice.RiskUserInfo:
  [(GCID=12345, VerificationLevel=3, DocumentStatus=2, others NULL)]
         |
         v
Consuming SP (Bulk_UpdateRiskUserInfoRemote or equivalent)
  UPDATE Customer/BackOffice tables
  SET VerificationLevel = ISNULL(3, existing) -> SET to 3
      DocumentStatus   = ISNULL(2, existing)  -> SET to 2
      PhoneVerificationStatus = ISNULL(NULL, existing) -> unchanged
      ...
```

---

## 3. Data Overview

N/A for User Defined Type. This is a type definition for transient parameter transport, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | CODE-BACKED | Group Customer ID - the logical key identifying which customer to update. Matches Customer.Customer.GCID. Should be non-NULL in valid usage even though the DDL allows NULL. |
| 2 | RegulatingEntityId | int | YES | - | CODE-BACKED | Identifier of the regulatory entity governing this customer (e.g., CySEC, FCA, ASIC). References Dictionary.Regulation or a similar lookup. NULL = do not update this field. |
| 3 | DocumentStatus | int | YES | - | CODE-BACKED | Customer's document verification status. Likely maps to BackOffice.Customer.DocumentStatusID and Dictionary.DocumentStatus (e.g., 1=Pending, 2=Approved, 3=Rejected). NULL = do not update. |
| 4 | PhoneVerificationStatus | int | YES | - | CODE-BACKED | Customer's phone number verification state. Likely 0=Not verified, 1=Verified. Maps to phone verification fields in Customer.Customer or BackOffice.Customer. NULL = do not update. |
| 5 | VerificationLevel | int | YES | - | CODE-BACKED | KYC verification level achieved by the customer (e.g., 0=Unverified, 1=Email verified, 2=Phone verified, 3=Fully verified). Controls trading capabilities and withdrawal limits. NULL = do not update. |
| 6 | PlayerStatus | int | YES | - | CODE-BACKED | Account/player status code. Maps to Customer.Customer.PlayerStatusID and Dictionary.PlayerStatus (see BackOffice.PlayerStatusToReason for status-to-reason mappings). NULL = do not update. |
| 7 | CopySuitabilityTestStatus | int | YES | - | CODE-BACKED | Result of the customer's copy trading suitability test, required under MiFID II regulations. Values indicate whether the customer passed, failed, or has not yet taken the test. NULL = do not update. |
| 8 | PlayerStatusReason | int | YES | - | CODE-BACKED | Reason code for the current player status. References Dictionary.PlayerStatusReasons (see BackOffice.PlayerStatusToReason for valid status-reason combinations). NULL = do not update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Customer.Customer.GCID | Implicit | Row key for identifying which customer to update |
| RegulatingEntityId | Dictionary.Regulation.ID | Implicit | Regulatory entity assignment |
| DocumentStatus | Dictionary.DocumentStatus.DocumentStatusID | Implicit | Document verification state mapping |
| PlayerStatus | Dictionary.PlayerStatus.PlayerStatusID | Implicit | Account status code mapping |
| PlayerStatusReason | Dictionary.PlayerStatusReasons.PlayerStatusReasonID | Implicit | Status reason mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Bulk_UpdateBasicUserInfoRemote | (historically @BulkUpdateTable) | Schema contract (historical) | Formerly used this type as a formal parameter; current version uses temp table #BulkUpdateBasicUserInfo with same structure |
| BackOffice.Bulk_UpdateRiskUserInfoRemote | (inferred parameter) | Schema contract | Likely the primary current consumer for bulk risk/compliance state updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Bulk_UpdateRiskUserInfoRemote | Stored Procedure | Inferred primary consumer - bulk update of compliance/risk fields for a batch of customers using ISNULL-guarded UPDATE logic |
| BackOffice.Bulk_UpdateBasicUserInfoRemote | Stored Procedure | Historical consumer (commented out) - originally passed as formal parameter, now uses temp table #BulkUpdateBasicUserInfo |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. All columns are nullable with no constraints.

---

## 8. Sample Queries

### 8.1 Update verification level and document status for a batch of customers

```sql
DECLARE @updates BackOffice.RiskUserInfo;

INSERT INTO @updates (GCID, VerificationLevel, DocumentStatus)
VALUES (12345, 3, 2),  -- Fully verified, documents approved
       (67890, 2, 1),  -- Phone verified, documents pending
       (11111, 1, 3);  -- Email verified, documents rejected

-- Execute the bulk update procedure
-- EXEC BackOffice.Bulk_UpdateRiskUserInfoRemote @BulkUpdateTable = @updates;
SELECT * FROM @updates WITH (NOLOCK);
```

### 8.2 Update player status with reason for a compliance action

```sql
DECLARE @updates BackOffice.RiskUserInfo;

INSERT INTO @updates (GCID, PlayerStatus, PlayerStatusReason)
VALUES (99999, 2, 5);  -- Status=2 (e.g., Blocked), Reason=5

SELECT * FROM @updates WITH (NOLOCK);
```

### 8.3 Partial update - only copy suitability test results

```sql
DECLARE @updates BackOffice.RiskUserInfo;

-- Only CopySuitabilityTestStatus updated, all others remain unchanged (NULL)
INSERT INTO @updates (GCID, CopySuitabilityTestStatus)
SELECT GCID, 1  -- 1 = Passed
FROM SomeComplianceSource WITH (NOLOCK)
WHERE TestDate = CAST(GETDATE() AS DATE);

SELECT * FROM @updates WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD: RD-4483 Move Verification Level Elevation from UAPI to Compliance API](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/692125706) | Confluence | Architecture context for verification level elevation flow - confirms VerificationLevel is managed via compliance API |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.RiskUserInfo | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.RiskUserInfo.sql*
