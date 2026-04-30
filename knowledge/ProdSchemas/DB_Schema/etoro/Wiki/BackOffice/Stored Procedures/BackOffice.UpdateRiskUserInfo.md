# BackOffice.UpdateRiskUserInfo

> Core risk/compliance profile update procedure: writes player status, verification level, regulation, document status, copy-block flag, and MiFID categorization for a customer across Customer.CustomerStatic and BackOffice.Customer, with optional copy-block management and designated regulation async notification.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - routes to CID via Customer.CustomerStatic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateRiskUserInfo` is the primary compliance profile update procedure for a customer. When a back-office risk agent reviews a customer and makes decisions about their verification status, regulation, player status, or copy-trading eligibility, this SP is the single write path for those decisions. It operates across two tables: `Customer.CustomerStatic` (player status and sub-reason) and `BackOffice.Customer` (regulatory, verification, and compliance fields).

The procedure exists as a single entry point because these fields must be updated consistently: a regulation change might accompany a verification level change; blocking copy trading must be synchronized with the `Customer.BlockedCustomerOperations` table rather than just setting a flag. The SP handles all of this coordination internally.

Three distinct actions occur:
1. Update `Customer.CustomerStatic` with player status and reason (always applied, defaulting `PlayerStatusID=1` if not provided).
2. Conditionally manage the copy-block entry in `Customer.BlockedCustomerOperations` by calling `Customer.OperationBlockForCID` or `Customer.OperationUnBlockForCID`.
3. Update `BackOffice.Customer` with the full set of risk/compliance fields.
4. If `@DesignatedRegulationID` is provided, insert an async action (ActionID=12) into `Internal.ActionsToExecute_Registration` to notify the registration system of the regulation routing change.

---

## 2. Business Logic

### 2.1 Player Status Update (Customer.CustomerStatic)

**What**: Sets the customer's trading/player status and the reason for the status change.

**Columns/Parameters Involved**: `@playerStatusId`, `@playerStatusReasonId`, `@PlayerStatusSubReasonID`, `@PlayerStatusSubReasonComment`

**Rules**:
- `PlayerStatusID = ISNULL(@playerStatusId, 1)` - if @playerStatusId is NULL, defaults to 1 (active/normal). Callers should pass the intended status explicitly.
- `PlayerStatusReasonID`, `PlayerStatusSubReasonID`, `PlayerStatusSubReasonComment` are set directly (no ISNULL guard - NULL clears the existing reason).
- Captures the `CID` for use in subsequent BackOffice.Customer update.

### 2.2 Copy-Block Management

**What**: Controls whether the customer is blocked from being copied by other traders, by orchestrating the `Customer.BlockedCustomerOperations` table.

**Columns/Parameters Involved**: `@isCopyBlocked`, `Customer.BlockedCustomerOperations.OperationTypeID=1`

**Rules**:
- `@isCopyBlocked=NULL`: no change to copy-block status.
- `@isCopyBlocked=0`: if currently blocked (OperationTypeID=1 exists), calls `Customer.OperationUnBlockForCID @cid, 1` to remove the block.
- `@isCopyBlocked=1`: if NOT currently blocked, calls `Customer.OperationBlockForCID @cid, 1` to add the block.
- Avoids duplicate inserts/deletes by checking current state first.
- OperationTypeID=1 = copy-trading block.

**Diagram**:
```
@isCopyBlocked=0 AND currently blocked? -> OperationUnBlockForCID(@cid, 1)
@isCopyBlocked=1 AND NOT currently blocked? -> OperationBlockForCID(@cid, 1)
@isCopyBlocked=NULL? -> no action (leave copy-block unchanged)
```

### 2.3 BackOffice.Customer Risk Fields Update

**What**: Updates the full suite of compliance and regulatory fields on BackOffice.Customer.

**Columns/Parameters Involved**: `@regulatingEntityId`, `@documentStatusId`, `@phoneVerificationStatusId`, `@verificationLevelId`, `@suitabilityTestStatusId`, `@isVerified`, `@VerifiedBy`, `@VerifiedByProvider`, `@EvMatchStatus`, `@MifidCategorizationID`, `@DesignatedRegulationID`, `@AsicClassificationID`, `@SeychellesCategorizationID`

**Rules**:
- `RegulationID = ISNULL(@regulatingEntityId, RegulationID)` - only changes if provided.
- `EvMatchStatus = ISNULL(@EvMatchStatus, EvMatchStatus)` - only changes if provided.
- `MifidCategorizationID = ISNULL(@MifidCategorizationID, 1)` - defaults to 1 if not provided.
- `SeychellesCategorizationID = ISNULL(@SeychellesCategorizationID, SeychellesCategorizationID)` - only changes if provided.
- Other fields (`DocumentStatusID`, `PhoneVerifiedID`, `VerificationLevelID`, `SuitabilityTestStatusID`, `Verified`, `VerifiedBy`, `VerifiedByProvider`, `DesignatedRegulationID`, `AsicClassificationID`) are set directly - NULL clears the existing value.

### 2.4 Designated Regulation Async Notification

**What**: When `@DesignatedRegulationID` is provided, triggers an async action in the registration system to process the regulation routing change.

**Columns/Parameters Involved**: `@DesignatedRegulationID`, `@gcid`, `@regulatingEntityId`

**Rules**:
- Only fires when `@DesignatedRegulationID IS NOT NULL`.
- Inserts into `Internal.ActionsToExecute_Registration` with `ActionID=12` and XML payload: `<Root><gcid Value="..."/><regulationID Value="..."/><designatedRegulationID Value="..."/></Root>`.
- This is a separate TRY/CATCH block that raises error 50001 on failure but does not ROLLBACK the main transaction (the DB updates are already committed at this point).
- ActionID=12 likely triggers a downstream registration workflow for regulatory re-routing.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. Primary routing key - used to find the customer in Customer.CustomerStatic and capture their CID for BackOffice.Customer update. |
| 2 | @regulatingEntityId | int | YES | NULL | CODE-BACKED | New RegulationID for this customer (maps to BackOffice.Customer.RegulationID). NULL=leave unchanged. Regulatory jurisdiction (1=CySEC, 2=FCA, 4=ASIC, etc.). Sent in async XML if DesignatedRegulationID also provided. |
| 3 | @documentStatusId | int | YES | NULL | CODE-BACKED | KYC document verification status (maps to BackOffice.Customer.DocumentStatusID). NULL clears existing value. Reflects the current document review outcome. |
| 4 | @phoneVerificationStatusId | int | YES | NULL | CODE-BACKED | Phone verification state (maps to BackOffice.Customer.PhoneVerifiedID). NULL clears existing value. Indicates whether customer's phone has been verified. |
| 5 | @verificationLevelId | int | YES | NULL | CODE-BACKED | Customer verification tier (maps to BackOffice.Customer.VerificationLevelID). NULL clears existing value. Controls what products and withdrawal limits are available. |
| 6 | @playerStatusId | int | YES | NULL | CODE-BACKED | Customer trading/player status (maps to Customer.CustomerStatic.PlayerStatusID). NULL defaults to 1 (active). Controls customer activity level (e.g., 1=active, other values=various restrictions). Written to CustomerStatic, not BackOffice.Customer. |
| 7 | @suitabilityTestStatusId | int | YES | NULL | CODE-BACKED | MiFID/regulatory suitability assessment result (maps to BackOffice.Customer.SuitabilityTestStatusID). NULL clears existing value. Required for certain regulated product access. |
| 8 | @isCopyBlocked | bit | YES | NULL | CODE-BACKED | Whether to block this customer from being copied: 0=unblock, 1=block, NULL=no change. Triggers Customer.OperationBlockForCID or Customer.OperationUnBlockForCID as needed (OperationTypeID=1). Does NOT map directly to a column - it orchestrates BlockedCustomerOperations. |
| 9 | @isVerified | bit | NO | 0 | CODE-BACKED | Whether the customer is verified (maps to BackOffice.Customer.Verified). Directly overwrites existing value. Default=0 means unverified if not passed. |
| 10 | @VerifiedBy | int | YES | NULL | CODE-BACKED | ManagerID of the agent who verified the customer (maps to BackOffice.Customer.VerifiedBy). NULL clears existing value. |
| 11 | @VerifiedByProvider | int | YES | NULL | CODE-BACKED | External verification provider ID (maps to BackOffice.Customer.VerifiedByProvider). NULL clears. Identifies which KYC provider (Au10tix, Onfido, etc.) was used for automated verification. |
| 12 | @playerStatusReasonId | int | YES | NULL | CODE-BACKED | Reason code for the player status change (maps to Customer.CustomerStatic.PlayerStatusReasonID). NULL clears existing reason. From Dictionary.PlayerStatusReason. |
| 13 | @EvMatchStatus | int | YES | NULL | CODE-BACKED | Electronic verification match status (maps to BackOffice.Customer.EvMatchStatus). NULL=leave unchanged. Result of eIDV/EV matching for identity verification. |
| 14 | @MifidCategorizationID | int | NO | 1 | CODE-BACKED | MiFID II customer categorization (maps to BackOffice.Customer.MifidCategorizationID). Default=1 if NULL (Retail). Controls applicable MiFID protections and leverage limits. |
| 15 | @DesignatedRegulationID | int | YES | NULL | CODE-BACKED | Designated regulatory jurisdiction for routing purposes (maps to BackOffice.Customer.DesignatedRegulationID). NULL=leave unchanged. When non-NULL, triggers async ActionID=12 in Internal.ActionsToExecute_Registration. |
| 16 | @PlayerStatusSubReasonID | int | YES | NULL | CODE-BACKED | Sub-reason for the player status change (maps to Customer.CustomerStatic.PlayerStatusSubReasonID). NULL clears. Provides granular reason detail below PlayerStatusReasonID. |
| 17 | @PlayerStatusSubReasonComment | varchar(64) | YES | NULL | CODE-BACKED | Free-text sub-reason comment (maps to Customer.CustomerStatic.PlayerStatusSubReasonComment). NULL clears. Optional agent note accompanying the sub-reason. |
| 18 | @AsicClassificationID | int | YES | NULL | CODE-BACKED | ASIC (Australian) regulatory customer classification (maps to BackOffice.Customer.AsicClassificationID). NULL clears. Relevant for customers regulated under ASIC. |
| 19 | @SeychellesCategorizationID | int | YES | NULL | CODE-BACKED | Seychelles regulatory customer categorization (maps to BackOffice.Customer.SeychellesCategorizationID). NULL=leave unchanged. Relevant for BVI/Seychelles regulated customers. |
| 20 | @RowCount | int | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT parameter. Returns @@RowCount from the BackOffice.Customer UPDATE (number of rows affected). Returns 0 if the GCID maps to a CID not found in BackOffice.Customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | UPDATE target (player status) | Routes by GCID; captures CID |
| @isCopyBlocked | Customer.BlockedCustomerOperations | Lookup + conditional call | Checks copy-block state before Block/Unblock |
| @isCopyBlocked=0 | Customer.OperationUnBlockForCID | EXEC callee | Removes copy-block when unblocking |
| @isCopyBlocked=1 | Customer.OperationBlockForCID | EXEC callee | Adds copy-block when blocking |
| CID (from GCID) | [BackOffice.Customer](../Tables/BackOffice.Customer.md) | UPDATE target (risk fields) | Main compliance profile update |
| @DesignatedRegulationID | Internal.ActionsToExecute_Registration | INSERT (async action) | Triggers registration system for regulation change |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpdateRiskUserInfoRemote | - | Wrapper | Remote version of this procedure |
| No other direct callers found in BackOffice SPs. | - | - | Called from risk management application workflows. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateRiskUserInfo (procedure)
+-- Customer.CustomerStatic (table) [UPDATE: PlayerStatus fields, captures CID]
+-- Customer.BlockedCustomerOperations (table) [SELECT: check copy-block state]
+-- Customer.OperationUnBlockForCID (procedure) [EXEC: when unblocking copy]
+-- Customer.OperationBlockForCID (procedure) [EXEC: when blocking copy]
+-- BackOffice.Customer (table) [UPDATE: risk/compliance fields]
+-- Internal.ActionsToExecute_Registration (table) [INSERT: async DesignatedRegulation action]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | UPDATE: PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID, PlayerStatusSubReasonComment WHERE GCID=@gcid |
| Customer.BlockedCustomerOperations | Table | SELECT: check if CID has OperationTypeID=1 (copy-block) |
| Customer.OperationUnBlockForCID | Procedure | EXEC: removes copy-block (OperationTypeID=1) when @isCopyBlocked=0 |
| Customer.OperationBlockForCID | Procedure | EXEC: adds copy-block (OperationTypeID=1) when @isCopyBlocked=1 |
| [BackOffice.Customer](../Tables/BackOffice.Customer.md) | Table | UPDATE: 13 risk/compliance columns WHERE CID=@cid |
| Internal.ActionsToExecute_Registration | Table | INSERT ActionID=12 with XML when @DesignatedRegulationID provided |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpdateRiskUserInfoRemote | Procedure | Remote wrapper that calls this SP |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- TRY/CATCH with THROW on error in the main update block.
- Separate TRY/CATCH for async registration action insert (RAISERROR 50001 on failure, does not rollback main transaction).

---

## 8. Sample Queries

### 8.1 Set customer verification level and mark as verified

```sql
DECLARE @RowCount INT;
EXEC BackOffice.UpdateRiskUserInfo
    @gcid               = 98765,
    @verificationLevelId = 3,
    @isVerified         = 1,
    @VerifiedBy         = 742,          -- ManagerID of reviewing agent
    @RowCount           = @RowCount OUTPUT;
SELECT @RowCount AS AffectedRows;
```

### 8.2 Block a customer from copy trading with reason

```sql
DECLARE @RowCount INT;
EXEC BackOffice.UpdateRiskUserInfo
    @gcid              = 98765,
    @isCopyBlocked     = 1,
    @playerStatusId    = 5,             -- some restricted status
    @playerStatusReasonId = 3,          -- reason code from Dictionary.PlayerStatusReason
    @RowCount          = @RowCount OUTPUT;
```

### 8.3 Update regulation assignment with designated regulation

```sql
DECLARE @RowCount INT;
EXEC BackOffice.UpdateRiskUserInfo
    @gcid                 = 98765,
    @regulatingEntityId   = 2,          -- FCA
    @DesignatedRegulationID = 2,        -- triggers async ActionID=12
    @RowCount             = @RowCount OUTPUT;
-- Inserts into Internal.ActionsToExecute_Registration with ActionID=12
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callees analyzed (OperationBlockForCID, OperationUnBlockForCID) | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateRiskUserInfo | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateRiskUserInfo.sql*
