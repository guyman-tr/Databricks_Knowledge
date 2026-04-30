# BackOffice.GetUnapprovedWithdrawRequests

> Returns pending withdrawal requests awaiting approval for a specific user group - the primary Back Office withdrawal approval queue, showing per-withdrawal customer enrichment, AML flags, and approval state.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserGroupID (required); returns Billing.Withdraw rows with Approved != 1 AND CashoutStatusID IN (1,2) AND Amount >= @Amount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetUnapprovedWithdrawRequests` is the Back Office withdrawal approval queue procedure. It returns all pending withdrawal requests that have not yet been approved, filtered by withdrawal amount threshold and optionally by white label. The result set is the primary data source for the BO withdrawal approval UI - each row represents one pending withdrawal, enriched with the customer's financial profile, risk flags, KYC status, and the requesting user group's approval state for that withdrawal.

The `@UserGroupID` parameter controls which approval group's perspective is shown: the `BackOffice.WithdrawApproval` JOIN uses the UserGroupID to show whether THIS group has already acted on each withdrawal. A special case: when `@UserGroupID = 4` (affiliate group), only IsAffiliate=1 customers are included.

The ACT Customer flag identifies customers who have received a specific compensation credit (CreditTypeID=6, CompensationReasonID=18) - this is the Active Customer Treatment (ACT) program marker, retrieved from `History.ActiveCreditRecentMemoryBucket` (an in-memory table) for performance.

The MoneyLaundering column (output label: [Low Trading Ratio]) checks the Billing.WithdrawToRiskManagementStatus linked to a 'ML' (Money Laundering) risk flag.

---

## 2. Business Logic

### 2.1 Withdrawal Eligibility Filter

**What**: Restricts output to pending withdrawals in the approval queue.

**Columns/Parameters Involved**: `BWIT.Approved`, `BWIT.CashoutStatusID`, `BWIT.Amount`, `@Amount`

**Rules**:
- `Approved != 1` - not yet globally approved
- `CashoutStatusID BETWEEN 1 AND 2` - CashoutStatus 1=Pending, 2=InProcess (active queue states)
- `Amount >= @Amount` - minimum withdrawal amount filter; pass 0 to return all amounts

### 2.2 User Group Approval State

**What**: Shows whether the requesting user group has already acted on each withdrawal.

**Columns/Parameters Involved**: `@UserGroupID`, `BackOffice.WithdrawApproval`, `[Approved]`, `[Approve Time]`, `[Approval Reason]`, `[Comment]`, `[Manager]`

**Rules**:
- LEFT JOIN BackOffice.WithdrawApproval ON WithdrawID AND UserGroupID = @UserGroupID
- [Approved] = 'YES' if Approved=1 for this group, 'NO' otherwise
- [Approve Time]: Occurred timestamp from WithdrawApproval
- [Approval Reason]: Dictionary.WithdrawApprovalReason.Name
- [Manager]: Manager FirstName + LastName who submitted this group's decision
- A withdrawal can appear here even if the user group has already approved it (it's still in the queue until globally approved)

### 2.3 Affiliate-Only Filter (UserGroupID=4)

**What**: When the requesting group is the affiliate approval group, only show affiliate customers.

**Columns/Parameters Involved**: `@UserGroupID`, `BackOffice.Customer.IsAffiliate`

**Rules**:
- If @UserGroupID = 4: appends `AND BCST.IsAffiliate = 1` to dynamic WHERE clause
- All other UserGroupIDs: no IsAffiliate filter applied
- Affiliates have a different approval workflow managed by the affiliate team

### 2.4 ACT Customer Flag

**What**: Identifies customers enrolled in the Active Customer Treatment (ACT) compensation program.

**Columns/Parameters Involved**: `[ACT Customer]`, `History.ActiveCreditRecentMemoryBucket`, `CreditTypeID=6`, `CompensationReasonID=18`

**Rules**:
- Queries `History.ActiveCreditRecentMemoryBucket` (in-memory performance table) for CreditTypeID=6 AND CompensationReasonID=18
- If the customer's CID has at least one such credit, [ACT Customer] = 'YES'; else 'NO'
- ACT = Active Customer Treatment - a retention program giving compensation credits to active traders
- The in-memory table replaced a direct History.Credit query (commented out in DDL) for performance (added Shay Oren 03/01/2021)

### 2.5 Money Laundering / Low Trading Ratio Flag

**What**: Flags withdrawals associated with a Money Laundering AML risk flag.

**Columns/Parameters Involved**: `[Low Trading Ratio]` (output column, internally named MoneyLaundering), `Dictionary.RiskManagementStatus.Name LIKE 'ML'`, `Billing.WithdrawToRiskManagementStatus.IsTriggered`

**Rules**:
- LEFT JOIN Billing.WithdrawToRiskManagementStatus + Dictionary.RiskManagementStatus
- If RiskManagementStatus.Name LIKE 'ML' AND IsTriggered=1 -> 'YES'
- If RiskManagementStatus.Name LIKE 'ML' AND IsTriggered=0 -> 'NO'
- Otherwise (non-ML status or no risk status) -> NULL
- Output column label is [Low Trading Ratio] despite internal variable name MoneyLaundering

### 2.6 Proof of Identity Check

**What**: Indicates whether the customer has a non-expired, non-obsolete proof of identity document.

**Columns/Parameters Involved**: `[Proof of Identity]`, `BackOffice.CustomerDocument`, `BackOffice.CustomerDocumentToDocumentType.DocumentTypeID=2`

**Rules**:
- Subquery counts documents WHERE DocumentTypeID=2 (Proof of Identity type), Obsolete=0, DocumentID>0, ExpiryDate > GETUTCDATE()
- If count > 0 -> 'YES'; else -> 'NO'
- Inline subquery, not a TVF call

### 2.7 NWA (Net Withdrawable Amount)

**What**: The customer's current Non-Withdrawable Amount / bonus credit balance.

**Columns/Parameters Involved**: `NWA`, `Customer.Customer.BonusCredit`

**Rules**:
- NWA = ISNULL(CCST.BonusCredit, 0) cast to DECIMAL(16,2)
- This is the amount the customer cannot withdraw because it came from bonus/credit (must be traded before withdrawal)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserGroupID | INTEGER | NO | - | CODE-BACKED | ID of the BackOffice approval user group viewing the queue. Controls which group's approval state is shown via WithdrawApproval JOIN. UserGroupID=4 additionally filters to affiliate customers only. Required. |
| 2 | @Amount | MONEY | NO | - | CODE-BACKED | Minimum withdrawal amount filter. Only returns withdrawals with Amount >= @Amount. Pass 0 to return all pending withdrawals. Required. |
| 3 | @WhiteLabels | VARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-separated white label IDs. NULL = all labels. When not NULL, appends WHERE WithdrawData.WhiteLabelID IN (STRING_SPLIT values). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | [...] | BIGINT | NO | - | CODE-BACKED | Row number (ROW_NUMBER() OVER ORDER BY WithdrawID ASC). Used for UI pagination. |
| 2 | Approve | BIT | NO | - | CODE-BACKED | Always CAST(0 AS BIT) - a placeholder checkbox column for the BO UI approval action. |
| 3 | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal request (Billing.Withdraw.WithdrawID). |
| 4 | Cashout Status | NVARCHAR | YES | - | CODE-BACKED | Status label of the withdrawal (Dictionary.CashoutStatus.Name via CashoutStatusID). Always 1 or 2 due to filter. |
| 5 | BackOffice Withdraw Reason | NVARCHAR | NO | - | CODE-BACKED | Internal BO reason for the withdrawal (Dictionary.CashoutReason.Name via CashoutReasonID). ISNULL -> empty string. |
| 6 | Request Time | DATETIME | YES | - | CODE-BACKED | When the customer submitted the withdrawal request (Billing.Withdraw.RequestDate). |
| 7 | CID | INT | NO | - | CODE-BACKED | Customer ID of the withdrawal requester (Billing.Withdraw.CID). |
| 8 | Customer Level | NVARCHAR | YES | - | CODE-BACKED | Customer tier (Dictionary.PlayerLevel.Name, trimmed). |
| 9 | Customer Status | NVARCHAR | YES | - | CODE-BACKED | Account status (Dictionary.PlayerStatus.Name via PlayerStatusID). |
| 10 | Risk Status | NVARCHAR | NO | - | CODE-BACKED | Comma-separated active risk flag names (BackOffice.GetUserRisksByCID OUTER APPLY). ISNULL -> empty string. |
| 11 | Amount | DECIMAL(16,2) | NO | - | CODE-BACKED | Withdrawal amount in account currency (Billing.Withdraw.Amount). |
| 12 | Funding Method | NVARCHAR | YES | - | CODE-BACKED | Payment method for the withdrawal (Dictionary.FundingType.Name via FundingTypeID). |
| 13 | Low Trading Ratio | VARCHAR(3) | YES | - | VERIFIED | AML money laundering risk flag: 'YES' if ML risk triggered, 'NO' if ML risk present but not triggered, NULL if no ML risk flag. Internal variable named MoneyLaundering; output label [Low Trading Ratio]. |
| 14 | Approved | VARCHAR(3) | YES | - | CODE-BACKED | Whether this user group has approved this withdrawal: 'YES' or 'NO' (from BackOffice.WithdrawApproval for this UserGroupID). |
| 15 | Approve Time | DATETIME | YES | - | CODE-BACKED | When this user group submitted their approval decision (BackOffice.WithdrawApproval.Occurred). NULL if not yet acted. |
| 16 | Approval Reason | NVARCHAR | YES | - | CODE-BACKED | Reason code for this group's approval decision (Dictionary.WithdrawApprovalReason.Name). NULL if not yet acted or no reason given. |
| 17 | Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text comment from this group's approval action (BackOffice.WithdrawApproval.Comment). |
| 18 | Verification Level | NVARCHAR | YES | - | CODE-BACKED | KYC verification level (Dictionary.VerificationLevel.Name via BackOffice.Customer.VerificationLevelID). |
| 19 | Total Cashouts | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's all-time total processed cashout amount (BackOffice.CustomerAllTimeAggregatedData.TotalCashout). |
| 20 | Account Balance | DECIMAL | YES | - | CODE-BACKED | Customer's current account balance (Customer.Customer.Credit). |
| 21 | Total Deposits | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's all-time total deposited amount (BackOffice.CustomerAllTimeAggregatedData.TotalDeposit). |
| 22 | NWA | DECIMAL(16,2) | NO | - | CODE-BACKED | Non-Withdrawable Amount - the customer's bonus/credit balance that must be traded before withdrawal (Customer.Customer.BonusCredit). 0 if null. |
| 23 | Credit Deduction | MONEY | YES | - | CODE-BACKED | Suggested bonus credit deduction amount for this withdrawal (Billing.Withdraw.SuggestedBonusDeductionAmount). |
| 24 | ACT Customer | VARCHAR(3) | YES | - | VERIFIED | Whether the customer is in the Active Customer Treatment program: 'YES' or 'NO'. Determined by presence of CreditTypeID=6 + CompensationReasonID=18 in History.ActiveCreditRecentMemoryBucket. |
| 25 | AffiliateID | INT | YES | - | CODE-BACKED | Customer's affiliate/serial ID (Customer.Customer.SerialID). Used to link to affiliate partner. |
| 26 | Total Lot Count | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's all-time total trading volume in lots (BackOffice.CustomerAllTimeAggregatedData.TotalLot). |
| 27 | Registration Form Country | NVARCHAR | YES | - | CODE-BACKED | Country from customer's registration form (Dictionary.Country.Name via Customer.Customer.CountryID). |
| 28 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Customer's regulatory jurisdiction (Dictionary.Regulation.Name via BackOffice.Customer.RegulationID). |
| 29 | Proof of Identity | VARCHAR(3) | YES | - | CODE-BACKED | Whether customer has a valid, non-expired proof of identity document: 'YES' or 'NO'. DocumentTypeID=2, Obsolete=0, ExpiryDate > now. |
| 30 | EvMatchStatus | NVARCHAR | NO | - | CODE-BACKED | Identity verification match result (Dictionary_EvMatchStatus.Name via BackOffice.Customer.EvMatchStatus). ISNULL -> empty string. |
| 31 | Document Status | NVARCHAR | NO | - | CODE-BACKED | Overall document verification status (Dictionary.DocumentStatus.Name via BackOffice.Customer.DocumentStatusID). ISNULL -> empty string. |
| 32 | Client Withdraw Reason | NVARCHAR | NO | - | CODE-BACKED | Reason provided by the customer for withdrawing (Dictionary.ClientWithdrawReason.Name via Billing.Withdraw.ClientWithdrawReasonID). ISNULL -> empty string. |
| 33 | Client Withdraw Reason Comment | NVARCHAR | NO | - | CODE-BACKED | Free-text comment from customer about reason for withdrawal (Billing.Withdraw.ClientWithdrawReasonComment). ISNULL -> empty string. |
| 34 | Designated Regulation | NVARCHAR | YES | - | CODE-BACKED | Customer's designated regulatory jurisdiction (Dictionary.Regulation.Name via BackOffice.Customer.DesignatedRegulationID). Used for dual-regulation customers. |
| 35 | Docs Ok | VARCHAR(4) | NO | - | CODE-BACKED | Always 'docs' - a static placeholder column for BO UI document link rendering. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BWIT.WithdrawID | Billing.Withdraw | Read (driving) | Pending withdrawal records |
| BWIT.CID | Customer.Customer | JOIN | Customer balance, country, SerialID, BonusCredit |
| BCST.CID | BackOffice.Customer | JOIN | BO profile: manager, regulation, verification, document status |
| BCAT.CID | BackOffice.CustomerAllTimeAggregatedData | JOIN | Financial aggregates |
| BWAP.WithdrawID + UserGroupID | BackOffice.WithdrawApproval | LEFT JOIN | This group's approval state |
| BWTRMS.WithdrawID | Billing.WithdrawToRiskManagementStatus | LEFT JOIN | AML/ML risk flag |
| BCST.CID | BackOffice.GetUserRisksByCID | OUTER APPLY | Risk flag names |
| BCDC.CID | BackOffice.CustomerDocument | LEFT JOIN (subquery) | Proof of identity count |
| BDOC.DocumentID | BackOffice.CustomerDocumentToDocumentType | LEFT JOIN (subquery) | DocumentTypeID=2 filter |
| CID | History.ActiveCreditRecentMemoryBucket | Table variable (pre-loaded) | ACT program membership |
| Dictionary.* (multiple) | Lookup tables | LEFT JOIN | Status/method/reason names |
| dbo.Dictionary_EvMatchStatus | Synonym | LEFT JOIN | EvMatchStatus name |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO withdrawal approval UI) | @UserGroupID | Application | Primary queue for BO withdrawal approvers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUnapprovedWithdrawRequests (procedure)
├── Billing.Withdraw (table) - driving
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── BackOffice.WithdrawApproval (table) - group approval state
├── BackOffice.Manager (table)
├── BackOffice.CustomerDocument (table) - POI subquery
├── BackOffice.CustomerDocumentToDocumentType (table) - POI subquery
├── History.ActiveCreditRecentMemoryBucket (table) - ACT program (in-memory)
├── Billing.WithdrawToRiskManagementStatus (table) - AML flag
├── Dictionary.RiskManagementStatus (table)
├── Dictionary.* (multiple lookup tables)
├── dbo.Dictionary_EvMatchStatus (synonym -> UserApiDB.Dictionary.EvMatchStatus)
├── BackOffice.GetUserRisksByCID (TVF - OUTER APPLY)
└── (dynamic SQL via sp_executesql)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Driving - pending withdrawal queue (Approved!=1, CashoutStatusID 1-2, Amount >= @Amount) |
| Customer.Customer | Table | JOIN - balance, country, SerialID, BonusCredit |
| BackOffice.Customer | Table | JOIN - BO profile fields |
| BackOffice.CustomerAllTimeAggregatedData | Table | JOIN - financial aggregates |
| BackOffice.WithdrawApproval | Table | LEFT JOIN on UserGroupID - group approval state |
| BackOffice.Manager | Table | LEFT JOIN - approver name |
| BackOffice.CustomerDocument | Table | Subquery - POI document count |
| BackOffice.CustomerDocumentToDocumentType | Table | Subquery - DocumentTypeID=2 filter |
| History.ActiveCreditRecentMemoryBucket | Table | Bulk pre-loaded into @ACTCustomersMemory for ACT flag |
| Billing.WithdrawToRiskManagementStatus | Table | LEFT JOIN - ML risk flag |
| Dictionary.* (multiple) | Tables | Lookup names |
| dbo.Dictionary_EvMatchStatus | Synonym | EvMatchStatus name |
| BackOffice.GetUserRisksByCID | TVF | OUTER APPLY - risk flag names |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO withdrawal approval application. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Implementation | Uses sp_executesql with CTE + main SELECT. The ACT pre-load, CTE definition, and main SELECT are all in the dynamic string. @WhiteLabels appended as WHERE clause after main SELECT. |
| In-memory table performance | Implementation | History.ActiveCreditRecentMemoryBucket replaced a direct History.Credit query (commented out) for ACT flag detection - performance optimization (Shay Oren Jan 2021). |
| UserGroupID=4 affiliate filter | Logic | Only when @UserGroupID=4 is IsAffiliate=1 filter applied. Other groups see all customer types. |
| MoneyLaundering / Low Trading Ratio label | Implementation | Internal CTE column named MoneyLaundering is projected as [Low Trading Ratio] in the outer SELECT. These are the same field. |
| Approved column vs global approval | Logic | [Approved] reflects only THIS UserGroupID's approval decision, not the global Billing.Withdraw.Approved flag. A withdrawal can have [Approved]='YES' for this group but still appear in the queue because another group hasn't approved. |

---

## 8. Sample Queries

### 8.1 Get pending withdrawal queue for user group 1, all amounts
```sql
EXEC [BackOffice].[GetUnapprovedWithdrawRequests]
    @UserGroupID = 1,
    @Amount = 0,
    @WhiteLabels = NULL
```

### 8.2 Get affiliate withdrawals over $500 for group 4
```sql
EXEC [BackOffice].[GetUnapprovedWithdrawRequests]
    @UserGroupID = 4,
    @Amount = 500,
    @WhiteLabels = NULL
-- Note: Only returns IsAffiliate=1 customers due to UserGroupID=4 special case
```

### 8.3 Get pending withdrawals for specific white labels
```sql
EXEC [BackOffice].[GetUnapprovedWithdrawRequests]
    @UserGroupID = 1,
    @Amount = 0,
    @WhiteLabels = '1,2'
```

### 8.4 Direct count of pending withdrawals in queue
```sql
SELECT COUNT(*) AS PendingCount,
       SUM(Amount) AS TotalPendingAmount
FROM Billing.Withdraw WITH (NOLOCK)
WHERE Approved != 1
  AND CashoutStatusID BETWEEN 1 AND 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.9/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUnapprovedWithdrawRequests | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetUnapprovedWithdrawRequests.sql*
