# BackOffice.UpdateRiskUserInfoRemote

> CID-keyed variant of UpdateRiskUserInfo: updates copy-block state, BackOffice.Customer risk/compliance fields (including EIDStatusID and OnboardingRiskClassificationID), and Customer.CustomerStatic player status - all using ISNULL partial-update semantics. No async regulation notification.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid - routes directly by CID (no GCID lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateRiskUserInfoRemote` is the CID-keyed remote-entry counterpart to `BackOffice.UpdateRiskUserInfo`. Where the non-Remote version accepts a GCID and performs a lookup to find the CID, this version accepts the CID directly - intended for callers that already have the resolved CID (e.g., internal services operating within the customer database context).

Compared to the base procedure, this variant:
1. Accepts `@cid` instead of `@gcid` - no CustomerStatic lookup required.
2. Adds two newer parameters: `@EIDStatusID` (eIDV status) and `@OnboardingRiskClassificationID` (onboarding risk tier) - both absent from the non-Remote version.
3. Applies full ISNULL semantics on ALL CustomerStatic fields (PlayerStatusReasonID, SubReason, SubReasonComment are preserved if NULL) - the non-Remote version clears them on NULL.
4. Does NOT trigger the async DesignatedRegulation action in `Internal.ActionsToExecute_Registration` - callers using regulation routing must call the non-Remote version.
5. Returns @@RowCount via RETURN (not OUTPUT parameter) - the count is from the CustomerStatic update.
6. Execution order is reversed: BackOffice.Customer is updated before Customer.CustomerStatic.

The procedure was introduced to support scenarios where a remote service holds the CID directly and needs to push risk field updates without paying the GCID-to-CID resolution cost. Its additional fields (EIDStatusID, OnboardingRiskClassificationID) reflect compliance features added after the original procedure was locked.

---

## 2. Business Logic

### 2.1 Copy-Block Management

**What**: Same pattern as UpdateRiskUserInfo - orchestrates Customer.BlockedCustomerOperations OperationTypeID=1.

**Columns/Parameters Involved**: `@isCopyBlocked`, `Customer.BlockedCustomerOperations.OperationTypeID=1`

**Rules**:
- `@isCopyBlocked=NULL`: no change.
- `@isCopyBlocked=0`: if currently blocked, calls `Customer.OperationUnBlockForCID @cid, 1`.
- `@isCopyBlocked=1`: if NOT currently blocked, calls `Customer.OperationBlockForCID @cid, 1`.
- Avoids duplicate ops by checking current state first.

### 2.2 BackOffice.Customer Risk Fields Update

**What**: Partial update of all risk/compliance fields on BackOffice.Customer, including two fields not present in the non-Remote version.

**Columns/Parameters Involved**: Same 13 fields as UpdateRiskUserInfo, plus `@EIDStatusID` and `@OnboardingRiskClassificationID`.

**Rules**:
- `RegulationID = ISNULL(@regulatingEntityId, RegulationID)` - preserved if NULL.
- `DesignatedRegulationID = ISNULL(@DesignatedRegulationID, DesignatedRegulationID)` - **ISNULL here** (non-Remote sets directly, which clears on NULL).
- `EvMatchStatus = ISNULL(@EvMatchStatus, EvMatchStatus)` - preserved if NULL.
- `MifidCategorizationID = ISNULL(@MifidCategorizationID, 1)` - defaults to 1 (Retail) if NULL.
- `SeychellesCategorizationID = ISNULL(@SeychellesCategorizationID, SeychellesCategorizationID)` - preserved if NULL.
- `EIDStatusID = ISNULL(@EIDStatusID, EIDStatusID)` - preserved if NULL. Not in non-Remote version.
- `OnboardingRiskClassificationID = ISNULL(@OnboardingRiskClassificationID, OnboardingRiskClassificationID)` - preserved if NULL. Not in non-Remote version.
- `DocumentStatusID`, `PhoneVerifiedID`, `VerificationLevelID`, `SuitabilityTestStatusID`, `Verified`, `VerifiedBy`, `VerifiedByProvider` set directly (NULL clears existing value).

### 2.3 Customer.CustomerStatic Player Status Update (Full ISNULL)

**What**: Updates player status fields on Customer.CustomerStatic, using ISNULL for ALL four fields (unlike non-Remote which clears ReasonID/SubReason/Comment on NULL).

**Columns/Parameters Involved**: `@playerStatusId`, `@playerStatusReasonId`, `@PlayerStatusSubReasonID`, `@PlayerStatusSubReasonComment`

**Rules**:
- `PlayerStatusID = ISNULL(@playerStatusId, 1)` - defaults to 1 if NULL (same as non-Remote).
- `PlayerStatusReasonID = ISNULL(@playerStatusReasonId, PlayerStatusReasonID)` - preserved if NULL.
- `PlayerStatusSubReasonID = ISNULL(@PlayerStatusSubReasonID, PlayerStatusSubReasonID)` - preserved if NULL.
- `PlayerStatusSubReasonComment = ISNULL(@PlayerStatusSubReasonComment, PlayerStatusSubReasonComment)` - preserved if NULL.
- Updating by `WHERE CID=@cid` directly (no GCID lookup needed).

**Behavioral difference from non-Remote**: In non-Remote, passing NULL for reason/sub-reason/comment CLEARS the existing value. In this Remote version, NULL preserves the existing value. This means callers that want to clear reason/sub-reason must explicitly pass a cleared value rather than NULL.

### 2.4 Return Value

**What**: Returns @@RowCount from the CustomerStatic UPDATE via RETURN statement.

**Rules**:
- Not an OUTPUT parameter - uses `RETURN @@RowCount`.
- Callers must capture via `EXEC @ret = BackOffice.UpdateRiskUserInfoRemote ...` not `@RowCount OUTPUT`.
- Returns 0 if the CID is not found in CustomerStatic.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int | NO | - | CODE-BACKED | Customer ID. Primary routing key - routes directly to BackOffice.Customer and Customer.CustomerStatic by CID. Contrast with UpdateRiskUserInfo which accepts @gcid and resolves to CID. |
| 2 | @regulatingEntityId | int | YES | NULL | CODE-BACKED | New RegulationID (maps to BackOffice.Customer.RegulationID). NULL=leave unchanged (ISNULL). |
| 3 | @documentStatusId | int | YES | NULL | CODE-BACKED | KYC document verification status (maps to BackOffice.Customer.DocumentStatusID). NULL clears existing value. |
| 4 | @phoneVerificationStatusId | int | YES | NULL | CODE-BACKED | Phone verification state (maps to BackOffice.Customer.PhoneVerifiedID). NULL clears existing value. |
| 5 | @verificationLevelId | int | YES | NULL | CODE-BACKED | Customer verification tier (maps to BackOffice.Customer.VerificationLevelID). NULL clears existing value. |
| 6 | @playerStatusId | int | YES | NULL | CODE-BACKED | Customer trading/player status (maps to Customer.CustomerStatic.PlayerStatusID). NULL defaults to 1 (active). |
| 7 | @suitabilityTestStatusId | int | YES | NULL | CODE-BACKED | MiFID/regulatory suitability assessment result (maps to BackOffice.Customer.SuitabilityTestStatusID). NULL clears existing value. |
| 8 | @isCopyBlocked | bit | YES | NULL | CODE-BACKED | Copy-block control: 0=unblock, 1=block, NULL=no change. Orchestrates Customer.BlockedCustomerOperations (OperationTypeID=1). |
| 9 | @isVerified | bit | NO | 0 | CODE-BACKED | Whether the customer is verified (maps to BackOffice.Customer.Verified). Default 0=unverified. |
| 10 | @VerifiedBy | int | YES | NULL | CODE-BACKED | ManagerID of the verifying agent (maps to BackOffice.Customer.VerifiedBy). NULL clears. |
| 11 | @VerifiedByProvider | int | YES | NULL | CODE-BACKED | External KYC provider ID (maps to BackOffice.Customer.VerifiedByProvider). NULL clears. |
| 12 | @playerStatusReasonId | int | YES | NULL | CODE-BACKED | Reason for player status change (maps to Customer.CustomerStatic.PlayerStatusReasonID). NULL=preserve existing (ISNULL). Differs from non-Remote: NULL clears in non-Remote. |
| 13 | @EvMatchStatus | int | YES | NULL | CODE-BACKED | Electronic verification match status (maps to BackOffice.Customer.EvMatchStatus). NULL=preserve existing (ISNULL). |
| 14 | @MifidCategorizationID | int | NO | 1 | CODE-BACKED | MiFID II categorization (maps to BackOffice.Customer.MifidCategorizationID). Default=1 (Retail) if NULL. |
| 15 | @DesignatedRegulationID | int | YES | NULL | CODE-BACKED | Designated regulatory jurisdiction (maps to BackOffice.Customer.DesignatedRegulationID). NULL=preserve existing (ISNULL). Unlike non-Remote: does NOT trigger async ActionID=12. |
| 16 | @PlayerStatusSubReasonID | int | YES | NULL | CODE-BACKED | Sub-reason for player status change (maps to Customer.CustomerStatic.PlayerStatusSubReasonID). NULL=preserve existing (ISNULL). Differs from non-Remote: NULL clears in non-Remote. |
| 17 | @PlayerStatusSubReasonComment | varchar(64) | YES | NULL | CODE-BACKED | Free-text sub-reason comment (maps to Customer.CustomerStatic.PlayerStatusSubReasonComment). NULL=preserve existing (ISNULL). Differs from non-Remote: NULL clears in non-Remote. |
| 18 | @AsicClassificationID | int | YES | NULL | CODE-BACKED | ASIC (Australian) regulatory classification (maps to BackOffice.Customer.AsicClassificationID). NULL clears. |
| 19 | @SeychellesCategorizationID | int | YES | NULL | CODE-BACKED | Seychelles regulatory categorization (maps to BackOffice.Customer.SeychellesCategorizationID). NULL=preserve existing (ISNULL). |
| 20 | @EIDStatusID | int | YES | NULL | CODE-BACKED | eIDV (Electronic Identity Verification) status (maps to BackOffice.Customer.EIDStatusID). NULL=preserve existing (ISNULL). Not present in UpdateRiskUserInfo - added for remote callers. |
| 21 | @OnboardingRiskClassificationID | int | YES | NULL | CODE-BACKED | Onboarding risk classification tier (maps to BackOffice.Customer.OnboardingRiskClassificationID). NULL=preserve existing (ISNULL). Not present in UpdateRiskUserInfo - added for remote callers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | Customer.BlockedCustomerOperations | Lookup + conditional call | Checks copy-block state before Block/Unblock |
| @isCopyBlocked=0 | Customer.OperationUnBlockForCID | EXEC callee | Removes copy-block when unblocking |
| @isCopyBlocked=1 | Customer.OperationBlockForCID | EXEC callee | Adds copy-block when blocking |
| @cid | [BackOffice.Customer](../Tables/BackOffice.Customer.md) | UPDATE target (risk fields) | Updates 15 risk/compliance columns WHERE CID=@cid |
| @cid | Customer.CustomerStatic | UPDATE target (player status) | Updates PlayerStatus fields WHERE CID=@cid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpdateRiskUserInfo | - | Parallel sibling | GCID-keyed version with async regulation support; this is the CID-keyed version |
| No direct callers found in BackOffice SPs. | - | - | Called from risk management services that resolve CID before calling. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateRiskUserInfoRemote (procedure)
+-- Customer.BlockedCustomerOperations (table) [SELECT: check copy-block state]
+-- Customer.OperationUnBlockForCID (procedure) [EXEC: when unblocking copy]
+-- Customer.OperationBlockForCID (procedure) [EXEC: when blocking copy]
+-- BackOffice.Customer (table) [UPDATE: 15 risk/compliance columns]
+-- Customer.CustomerStatic (table) [UPDATE: PlayerStatus fields]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | SELECT: check if CID has OperationTypeID=1 (copy-block) |
| Customer.OperationUnBlockForCID | Procedure | EXEC: removes copy-block when @isCopyBlocked=0 |
| Customer.OperationBlockForCID | Procedure | EXEC: adds copy-block when @isCopyBlocked=1 |
| [BackOffice.Customer](../Tables/BackOffice.Customer.md) | Table | UPDATE: 15 risk/compliance columns WHERE CID=@cid |
| Customer.CustomerStatic | Table | UPDATE: PlayerStatus, Reason, SubReason, SubReasonComment WHERE CID=@cid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from risk management services holding resolved CIDs. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- TRY/CATCH with THROW on error.
- Returns @@RowCount (from CustomerStatic UPDATE) via RETURN - not an OUTPUT parameter.
- No transaction wrapping - each UPDATE commits independently.

**Key differences from BackOffice.UpdateRiskUserInfo**:
| Feature | UpdateRiskUserInfo | UpdateRiskUserInfoRemote |
|---------|-------------------|--------------------------|
| Key | @gcid (resolves to CID) | @cid (direct) |
| Extra fields | - | @EIDStatusID, @OnboardingRiskClassificationID |
| Async regulation action | Yes (ActionID=12) | No |
| Reason/SubReason/Comment on NULL | Clears (no ISNULL) | Preserves (ISNULL) |
| DesignatedRegulationID on NULL | Clears (no ISNULL) | Preserves (ISNULL) |
| Return mechanism | @RowCount OUTPUT | RETURN @@RowCount |
| Execution order | CustomerStatic first | BackOffice.Customer first |

---

## 8. Sample Queries

### 8.1 Update risk fields for a CID (with EID status)

```sql
DECLARE @ret INT;
EXEC @ret = BackOffice.UpdateRiskUserInfoRemote
    @cid                          = 12345,
    @verificationLevelId          = 3,
    @isVerified                   = 1,
    @VerifiedBy                   = 742,
    @EIDStatusID                  = 2,    -- eIDV matched
    @OnboardingRiskClassificationID = 1;  -- low risk
SELECT @ret AS RowsAffected;
```

### 8.2 Block copy trading via CID

```sql
EXEC BackOffice.UpdateRiskUserInfoRemote
    @cid           = 12345,
    @isCopyBlocked = 1,
    @playerStatusId = 5;
```

### 8.3 Partial field update (NULL fields preserved, not cleared)

```sql
-- Only updates EIDStatusID; all other fields remain unchanged
EXEC BackOffice.UpdateRiskUserInfoRemote
    @cid        = 12345,
    @EIDStatusID = 3;   -- only this field changes; reason/subreason/etc. preserved
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure (same ticket history as UpdateRiskUserInfo: 32499, 2872, 47218, 49308, 51498, 51829, RD-1752, COAIL-2262, COAKVU-3208).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callees analyzed (OperationBlockForCID, OperationUnBlockForCID) | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateRiskUserInfoRemote | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateRiskUserInfoRemote.sql*
