# BackOffice.GetRedeemDisplayData

> Returns combined customer profile and redeem approval status data for a set of redeem requests and customers, filtered by approval user group - used to render the redeem review screen in Back Office.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserGroupID + @RedeemIDList + @CIDsList (all required) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetRedeemDisplayData` assembles the display dataset for Back Office redeem (stock/crypto redemption) approval workflows. When a BO agent opens a batch of redeem requests for review, this procedure gathers two complementary data sets: a customer profile enrichment (account balance, verification status, risk status, age, document status) and the redeem-specific approval record (whether it was approved, who approved it, when, and why) - scoped to a specific approval user group.

The procedure exists because redeem requests require multi-level group approval and each approval group needs to see both the full customer context (to make a risk/compliance decision) and their group's specific approval decision. Without this procedure the BO screens would need separate queries for customer data and approval status.

The dual-CTE design separates concerns: the `CIDs` CTE builds a rich customer profile using all relevant lookup joins; the `Redeems` CTE fetches group-specific approval records. A LEFT JOIN combines them so all requested customers appear in the result even if the group has not yet acted on their redeem requests (Redeems columns will be NULL for unapproved records).

---

## 2. Business Logic

### 2.1 Multi-Group Approval Scoping

**What**: Redeem requests go through multiple approval groups (compliance, risk, finance, etc.). Each group has its own approval record in BackOffice.RedeemApproval. This procedure returns only ONE group's view at a time.

**Columns/Parameters Involved**: `@UserGroupID`, `[RedeemID]`, `[Approved]`, `[Approve Time]`, `[ApprovalReason]`, `[Comment]`

**Rules**:
- `BORA.UserGroupID = @UserGroupID` filter ensures only the caller's group approval records appear
- `BORA.RedeemID IN (@RedeemIDList)` limits to the requested redeem batch
- A LEFT JOIN from CIDs to Redeems means customer data always returns; approval columns are NULL if the group has not reviewed yet
- `[Approved]` = 'Yes' (BORA.Approved = 1) or 'NO' (BORA.Approved = 0)

**Diagram**:
```
@UserGroupID = 5 (Compliance group)
  CIDs CTE: customer data for all CIDs in @CIDsList
  Redeems CTE: approval records WHERE UserGroupID = 5 AND RedeemID IN @RedeemIDList
  Result: all customers LEFT JOIN group-5 approvals
  -> Customer with no group-5 approval: shows customer data, NULL approval columns
  -> Customer with group-5 approval: shows customer data + Approved/Reason/Comment
```

### 2.2 Proof of Identity Validation

**What**: Determines whether a customer currently has a valid, non-expired Proof of Identity document on file.

**Columns/Parameters Involved**: `[ProofofIdentity]`, `BackOffice.CustomerDocument`, `BackOffice.CustomerDocumentToDocumentType`

**Rules**:
- Counts documents where: DocumentTypeID = 2 (Proof of Identity), ExpiryDate > GETUTCDATE() (not expired), Obsolete = 0 (active), DocumentID > 0 (valid)
- Result: 'Yes' if any valid POI exists, 'No' if none
- This is a real-time check - not stored in a flag column - ensuring expired documents are excluded

### 2.3 Age Calculation

**What**: Computes the customer's current age in years from birth date.

**Columns/Parameters Involved**: `[Age]`, `FilteredCustomer.BirthDate`

**Rules**:
- Formula: `(CONVERT(int, CONVERT(char(8), GETDATE(), 112)) - CONVERT(char(8), BirthDate, 112)) / 10000`
- This converts both dates to YYYYMMDD integer format and divides the difference by 10000 to extract whole years
- Age matters for redeem decisions where regulatory minimum-age rules apply
- Added MIMOPS-4070 (09/05/2021)

### 2.4 Risk Status via Function

**What**: Customer risk status is resolved via the `BackOffice.GetUserRisksByCID` table-valued function rather than a direct join.

**Columns/Parameters Involved**: `[RiskStatus]`, `RS.RiskStatusesNames`

**Rules**:
- OUTER APPLY `BackOffice.GetUserRisksByCID(CC.CID)` returns a `RiskStatusesNames` column
- The commented-out JOIN to `Dictionary.RiskStatus` suggests this was previously a simple lookup but was replaced with the multi-value function (implying a customer may have multiple risk statuses concatenated)
- NULL if no risk statuses assigned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserGroupID | INT | NO | - | CODE-BACKED | The approval user group to retrieve approval records for. Each group (compliance, risk, finance, etc.) has its own approval entry in BackOffice.RedeemApproval. Filters the Redeems CTE to show only this group's decisions. |
| 2 | @RedeemIDList | BackOffice.IDs (TABLE TYPE) | NO | - | CODE-BACKED | Table-valued parameter containing the list of RedeemIDs to retrieve approval data for. Must contain at least one ID. Uses BackOffice.IDs UDT (INT ID column). |
| 3 | @CIDsList | BackOffice.IDs (TABLE TYPE) | NO | - | CODE-BACKED | Table-valued parameter containing the list of Customer IDs to retrieve profile data for. The CIDs in this list drive the customer enrichment portion of the result. Uses BackOffice.IDs UDT. |

### Output Columns (CIDs CTE)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Cid | INT | NO | - | CODE-BACKED | Customer ID. Primary key linking the customer profile to their redeem request. |
| 2 | CustomerLevel | NVARCHAR | NO | - | VERIFIED | Customer's player level name (Dictionary.PlayerLevel via Customer.Customer.PlayerLevelID). Indicates account tier - relevant for determining redeem eligibility limits. |
| 3 | Gcid | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Global Customer ID (Customer.Customer.GCID). Cross-system identifier used in eToro's global customer registry. |
| 4 | CustomerStatus | NVARCHAR | NO | - | VERIFIED | Customer's current account status name (Dictionary.PlayerStatus via Customer.Customer.PlayerStatusID). Critical for redeem eligibility - blocked/suspended accounts cannot redeem. |
| 5 | RiskStatus | NVARCHAR | YES | - | CODE-BACKED | Comma-separated or concatenated risk status names assigned to this customer (from BackOffice.GetUserRisksByCID TVF). May include multiple statuses. NULL if no risk flags. |
| 6 | VerificationLevel | NVARCHAR | YES | - | VERIFIED | Customer's KYC verification level name (Dictionary.VerificationLevel via BackOffice.Customer.VerificationLevelID). Values: Level 0, Level 1, Level 2, Level 3. Higher levels indicate more identity verification completed. |
| 7 | TotalDeposit | MONEY | YES | - | CODE-BACKED | Lifetime total deposited amount for this customer (BackOffice.CustomerAllTimeAggregatedData.TotalDeposit). Used to assess customer value in redeem approval decisions. |
| 8 | TotalCashout | MONEY | YES | - | CODE-BACKED | Lifetime total withdrawn/cashed-out amount (BackOffice.CustomerAllTimeAggregatedData.TotalCashout). Combined with TotalDeposit to assess net funding position. |
| 9 | BonusCredit | DECIMAL | YES | - | CODE-BACKED | Outstanding bonus credit balance on the customer's account (Customer.Customer.BonusCredit). Bonus funds are typically not redeemable - shown to BO agent for context. |
| 10 | AccountBalance | DECIMAL | YES | - | CODE-BACKED | Customer's current account credit balance (Customer.Customer.Credit). The free balance available for redemption. |
| 11 | AffiliateID | INT | YES | - | CODE-BACKED | Affiliate serial ID associated with this customer's acquisition (Customer.Customer.SerialID). Used for affiliate attribution context. |
| 12 | TotalLotCount | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime total lot count traded by this customer (BackOffice.CustomerAllTimeAggregatedData.TotalLot, cast to decimal(16,2)). Indicates trading activity level. |
| 13 | RegistrationFormCountry | INT | YES | - | CODE-BACKED | CountryID from the customer's registration form (Customer.Customer.CountryID). Numeric ID - not resolved to country name in this query. |
| 14 | DocumentStatus | NVARCHAR | YES | - | VERIFIED | Current document verification status name (Dictionary.DocumentStatus via BackOffice.Customer.DocumentStatusID). Empty string if no status set. Reflects the overall KYC document state. |
| 15 | ProofofIdentity | VARCHAR(3) | NO | - | VERIFIED | Whether the customer has a valid, non-expired Proof of Identity document (DocumentTypeID=2). 'Yes' = at least one active non-expired POI exists in BackOffice.CustomerDocumentToDocumentType. 'No' = no valid POI. |
| 16 | EvMatchStatus | NVARCHAR | YES | - | CODE-BACKED | Electronic verification (EV) match status name from UserApiDB.Dictionary.EvMatchStatus (via dbo.Dictionary_EvMatchStatus synonym). Reflects the result of automated identity-verification matching. Empty string if not set. |
| 17 | Age | INT | YES | - | VERIFIED | Customer's age in years, calculated at runtime from FilteredCustomer.BirthDate using YYYYMMDD integer arithmetic. Added MIMOPS-4070 for age-gated redeem compliance checks. |

### Output Columns (Redeems CTE - LEFT JOIN, NULL if group has not reviewed)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 18 | RedeemID | INT | YES | - | CODE-BACKED | ID of the redeem request (BackOffice.RedeemApproval.RedeemID). NULL if this approval group has not yet actioned this customer's redeem. |
| 19 | CID | INT | YES | - | CODE-BACKED | Customer ID from the Redeems CTE (BackOffice.RedeemApproval.CID). Duplicate of Cid from CIDs CTE - present because of SELECT * join. |
| 20 | Approved | VARCHAR(3) | YES | - | VERIFIED | Whether this approval group approved the redeem. 'Yes' = BORA.Approved = 1 (approved). 'NO' = BORA.Approved = 0 (rejected/denied). NULL = group has not yet reviewed. |
| 21 | [Approve Time] | DATETIME | YES | - | CODE-BACKED | Timestamp when this approval group took action (BackOffice.RedeemApproval.Occurred). NULL if not yet actioned. |
| 22 | [ApprovalReason] | NVARCHAR | YES | - | VERIFIED | Reason provided for this group's approval decision (Dictionary.RedeemApprovalReason.Name via BORA.RedeemApprovalReasonID). Current values: 1=Other. NULL if not yet actioned. |
| 23 | [Comment] | NVARCHAR | YES | - | CODE-BACKED | Free-text comment entered by the BO agent when approving or denying the redeem (BackOffice.RedeemApproval.Comment). NULL if not yet actioned. |

---

## 5. Relationships

### 5.1 References To (this object reads from)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDsList -> CID | Customer.Customer | JOIN | Customer base profile data |
| @CIDsList -> CID | BackOffice.Customer | JOIN | BO attributes: VerificationLevelID, DocumentStatusID, EvMatchStatus |
| @CIDsList -> CID | BackOffice.CustomerAllTimeAggregatedData | JOIN | Lifetime trading aggregates |
| @CIDsList -> CID | FilteredCustomer (dbo view) | JOIN | Provides BirthDate for age calculation |
| RS | BackOffice.GetUserRisksByCID | OUTER APPLY (TVF) | Multi-value risk status lookup |
| BC.DocumentStatusID | Dictionary.DocumentStatus | LEFT JOIN | Document status name |
| BC.VerificationLevelID | Dictionary.VerificationLevel | JOIN | KYC level name |
| CC.PlayerStatusID | Dictionary.PlayerStatus | JOIN | Account status name |
| CC.PlayerLevelID | Dictionary.PlayerLevel | JOIN | Account level name |
| BCDC/CDDT | BackOffice.CustomerDocument | LEFT JOIN subquery | POI document existence check |
| BCDC/CDDT | BackOffice.CustomerDocumentToDocumentType | LEFT JOIN subquery | POI document type/expiry check |
| BC.EvMatchStatus | dbo.Dictionary_EvMatchStatus (synonym) | LEFT JOIN | EV match status - points to UserApiDB.Dictionary.EvMatchStatus |
| @RedeemIDList + @UserGroupID | BackOffice.RedeemApproval | JOIN | Group-specific approval records |
| BORA.RedeemApprovalReasonID | Dictionary.RedeemApprovalReason | JOIN | Approval reason name |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO application layer) | (direct call) | Application | Called by Back Office redeem review screens to populate group-scoped approval display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetRedeemDisplayData (procedure)
├── Customer.Customer (table)
├── dbo.FilteredCustomer (view)
├── BackOffice.Customer (table)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── BackOffice.CustomerDocument (table)
├── BackOffice.CustomerDocumentToDocumentType (table)
├── BackOffice.RedeemApproval (table)
├── BackOffice.GetUserRisksByCID (TVF)
├── dbo.Dictionary_EvMatchStatus (synonym -> UserApiDB.Dictionary.EvMatchStatus)
├── Dictionary.PlayerStatus (table)
├── Dictionary.PlayerLevel (table)
├── Dictionary.VerificationLevel (table)
├── Dictionary.DocumentStatus (table)
├── Dictionary.RedeemApprovalReason (table)
└── BackOffice.IDs (user defined type - parameter type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Primary customer profile JOIN |
| dbo.FilteredCustomer | View | Provides BirthDate field (dbo-level view of customer data) |
| BackOffice.Customer | Table | BO-specific attributes (VerificationLevelID, DocumentStatusID, EvMatchStatus) |
| BackOffice.CustomerAllTimeAggregatedData | Table | TotalDeposit, TotalCashout, TotalLot |
| BackOffice.CustomerDocument | Table | Subquery for POI document count |
| BackOffice.CustomerDocumentToDocumentType | Table | Document type and expiry for POI check |
| BackOffice.RedeemApproval | Table | Group approval records |
| BackOffice.GetUserRisksByCID | TVF | OUTER APPLY - multi-value risk status |
| BackOffice.IDs | User Defined Type | Table-valued parameter type for @RedeemIDList and @CIDsList |
| dbo.Dictionary_EvMatchStatus | Synonym | EV match status - maps to UserApiDB.Dictionary.EvMatchStatus |
| Dictionary.PlayerStatus | Table | Customer status name |
| Dictionary.PlayerLevel | Table | Customer level name |
| Dictionary.VerificationLevel | Table | KYC verification level name |
| Dictionary.DocumentStatus | Table | Document status name |
| Dictionary.RedeemApprovalReason | Table | Approval reason name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Table-valued parameters | Implementation | Uses BackOffice.IDs UDT (ReadOnly) for @RedeemIDList and @CIDsList - caller must pass TVP, not scalar lists |
| DocumentTypeID = 2 | Logic | POI check is hardcoded to DocumentTypeID = 2. Only Proof of Identity documents count for [ProofofIdentity]. |
| Non-expired POI | Logic | ExpiryDate > GETUTCDATE() ensures expired documents are not counted as valid POI |

---

## 8. Sample Queries

### 8.1 Retrieve display data for a set of redeem requests and customers for user group 1
```sql
-- Create TVP tables (application pattern)
DECLARE @RedeemIDs BackOffice.IDs
DECLARE @CIDs BackOffice.IDs
INSERT INTO @RedeemIDs VALUES (10001), (10002), (10003)
INSERT INTO @CIDs VALUES (123456), (234567), (345678)

EXEC [BackOffice].[GetRedeemDisplayData]
    @UserGroupID = 1,
    @RedeemIDList = @RedeemIDs,
    @CIDsList = @CIDs
```

### 8.2 Check current VerificationLevel and DocumentStatus for redeem candidates
```sql
SELECT BC.CID, VL.Name AS VerificationLevel, DCDS.DocumentStatusName AS DocumentStatus
FROM BackOffice.Customer BC WITH (NOLOCK)
JOIN Dictionary.VerificationLevel VL WITH (NOLOCK) ON BC.VerificationLevelID = VL.ID
LEFT JOIN Dictionary.DocumentStatus DCDS WITH (NOLOCK) ON BC.DocumentStatusID = DCDS.DocumentStatusID
WHERE BC.CID IN (123456, 234567, 345678)
```

### 8.3 Find all approval group decisions for a specific redeem request
```sql
SELECT RA.RedeemID, RA.UserGroupID, RA.Approved,
       RA.Occurred AS ApproveTime, DAR.Name AS Reason, RA.Comment
FROM BackOffice.RedeemApproval RA WITH (NOLOCK)
JOIN Dictionary.RedeemApprovalReason DAR WITH (NOLOCK)
  ON DAR.RedeemApprovalReasonID = RA.RedeemApprovalReasonID
WHERE RA.RedeemID = 10001
ORDER BY RA.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPS-4070](https://etoro-jira.atlassian.net/browse/MIMOPS-4070) | Jira | Added Age calculation from BirthDate for regulatory age-gating on redeem decisions (09/05/2021) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.9/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetRedeemDisplayData | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetRedeemDisplayData.sql*
