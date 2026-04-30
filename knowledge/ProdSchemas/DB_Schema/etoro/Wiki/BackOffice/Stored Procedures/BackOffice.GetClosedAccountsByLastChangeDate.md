# BackOffice.GetClosedAccountsByLastChangeDate

> Returns customers whose player status changed within a date range and whose account status matches a given ID, showing financial standing, document status, open positions, 3rd-party funding, and open cashout indicators - the primary closed/pending-closure account report in BackOffice.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AccountStatusID + @FromDate/@ToDate (status change window); optional TVP filters for player status, reason, sub-reason |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetClosedAccountsByLastChangeDate` is the BackOffice report for identifying customers who have recently had a player status change AND match a specified account status. Despite the name suggesting only "closed" accounts, the procedure is parameterized by @AccountStatusID - it can report on any account status value (1=Open, 2=Closed), making it useful for both the closed account report and the pending closure review queue.

The procedure uses a two-pass approach for performance:
1. **First pass**: Finds CIDs where `History.Customer.ValidFrom` is within the date range, the player status changed, and the optional status/reason/sub-reason TVP filters match. Writes results to `#ClosedAccounts` temp table with clustered index.
2. **Second pass**: Enriches the temp table with full customer details (balance, equity, document status, verification level, 3rd party, open cashouts, open positions) via multiple correlated subqueries and scalar subqueries.

**Key business rule**: `History.Customer.ValidFrom` is used (not ValidTo) to find accounts whose status changed during the window. This is the timestamp when the new status version became effective. The output shows `ValidTo` (derived from MAX(ValidTo)) as the "Player Last Status Change Date" - the most recent change.

Created July 2018 (Geri Reshef, ticket 52083) for a pending closure SQL improvement. Updated July 2018 (Ran Ovadia, 52278) and April 2019 (Geri Reshef, RD-3758) to add regulation fields.

---

## 2. Business Logic

### 2.1 Two-Pass Architecture with Temp Table

**What**: First pass identifies matching CIDs into #ClosedAccounts; second pass enriches with details.

**Columns/Parameters Involved**: `#ClosedAccounts (CID, LastPlayerStatusIDChangeDate)`, `History.Customer.ValidFrom`, `History.Customer.ValidTo`

**Rules**:
- First pass: `History.Customer.ValidFrom >= @FromDate AND ValidFrom < @ToDate`.
- Additionally: `History.Customer.PlayerStatusID <> Customer.Customer.PlayerStatusID` - only rows where the historical status differs from the current status (status change events).
- `MAX(ValidTo)` per CID -> LastPlayerStatusIDChangeDate -> the most recent status change endpoint.
- Clustered index on #ClosedAccounts.CID for efficient JOIN in second pass.

### 2.2 TVP Filter Pattern (Empty = All)

**What**: Player status, reason, and sub-reason TVPs use the same empty-means-all pattern.

**Columns/Parameters Involved**: `@PlayerStatusIDs`, `@PlayerStatusReasonIDs`, `@PlayerStatusSubReasonIDs`

**Rules**:
- `cc.PlayerStatusID IN (SELECT ID FROM @PlayerStatusIDs) OR (SELECT COUNT(1) FROM @PlayerStatusIDs) = 0`
- Same for reason and sub-reason TVPs.
- Empty TVPs = no filter on that dimension.

### 2.3 SubReason IIF Logic

**What**: SubReasonID=0 means "free-text comment" (no lookup value).

**Columns/Parameters Involved**: `cc.PlayerStatusSubReasonID`, `cc.PlayerStatusSubReasonComment`

**Rules**:
- `IIF(cc.PlayerStatusSubReasonID=0, cc.PlayerStatusSubReasonComment, (SELECT Name FROM Dictionary.PlayerStatusSubReasons WHERE PlayerStatusSubReasonID=cc.PlayerStatusSubReasonID))` AS SubReason.
- Consistent with GetBlockedCustomers behavior.

### 2.4 Has Open Position Correlated EXISTS

**What**: Checks whether the customer currently has any open trading position.

**Columns/Parameters Involved**: `Trade.Position`, `CID`

**Rules**:
- `(SELECT CASE WHEN EXISTS(SELECT 1 FROM Trade.Position WITH(NoLock) WHERE CID=cc.CID) THEN 'Yes' ELSE 'No' END)` AS [Has Open Position].

### 2.5 Has Open Cashouts Correlated EXISTS

**What**: Checks whether the customer has any withdrawal not in a terminal state.

**Columns/Parameters Involved**: `Billing.Withdraw.CashoutStatusID`

**Rules**:
- `CASE WHEN EXISTS(SELECT TOP 1 * FROM Billing.Withdraw BW WHERE BW.CID=cc.CID AND BW.CashoutStatusID NOT IN (3, 4)) THEN 'Yes' ELSE 'No' END` AS [Has Open Cashouts].
- CashoutStatusID=3=Processed, 4=Canceled -> terminal states.
- Any other status (Pending, InProcess, Rejected, etc.) means open cashout exists.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountStatusID | INT | NO | - | CODE-BACKED | Account status to filter. 1=Open, 2=Closed. Filters Customer.Customer.AccountStatusID. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of status change window (inclusive). Filters History.Customer.ValidFrom >= @FromDate. |
| 3 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of status change window (exclusive). Filters History.Customer.ValidFrom < @ToDate. |
| 4 | @PlayerStatusIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Optional player status IDs filter. Empty = all statuses. |
| 5 | @PlayerStatusReasonIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Optional player status reason IDs filter. Empty = all reasons. |
| 6 | @PlayerStatusSubReasonIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Optional player status sub-reason IDs filter. Empty = all sub-reasons. |
| 7 | Select.. | BIT | NO | 0 | CODE-BACKED | Always CAST(0 AS BIT). UI grid checkbox placeholder. |
| 8 | CID | INT | NO | - | CODE-BACKED | Customer Identifier. Ordered DESC in results. |
| 9 | UserName | NVARCHAR | YES | - | CODE-BACKED | Customer login. From Customer.Customer.UserName. |
| 10 | Has Open Position | VARCHAR | NO | - | CODE-BACKED | 'Yes' if any Trade.Position exists for this CID; 'No' otherwise. |
| 11 | Balance | MONEY | YES | - | CODE-BACKED | Current credit/balance. From Customer.Customer.Credit. |
| 12 | Equity | MONEY | YES | - | CODE-BACKED | Realized equity. From Customer.Customer.RealizedEquity. |
| 13 | Pending Closure Status | NVARCHAR | YES | - | CODE-BACKED | Pending closure state. ISNULL(PendingClosureStatusName, 'No'). Scalar subquery from Dictionary.PendingClosureStatus. |
| 14 | Customer Status | NVARCHAR | YES | - | CODE-BACKED | Current player status name. Scalar subquery from Dictionary.PlayerStatus. |
| 15 | Reason | NVARCHAR | YES | - | CODE-BACKED | Player status reason name. Scalar subquery from Dictionary.PlayerStatusReasons. |
| 16 | SubReason | NVARCHAR | YES | - | CODE-BACKED | Sub-reason: free-text comment if SubReasonID=0; otherwise Dictionary.PlayerStatusSubReasons.Name. |
| 17 | Player Last Status Change Date | DATETIME | YES | - | CODE-BACKED | Most recent player status change date. MAX(ValidTo) from #ClosedAccounts.LastPlayerStatusIDChangeDate. |
| 18 | Blocked Comment | NVARCHAR | YES | - | CODE-BACKED | BackOffice comment on the customer. From Customer.Customer.Comments. |
| 19 | Total Deposits | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime total deposits. CAST from BackOffice.CustomerAllTimeAggregatedData.TotalDeposit. |
| 20 | Bonus Credit (NWA) | MONEY | YES | - | CODE-BACKED | Non-Withdrawable Amount bonus credit. From Customer.Customer.BonusCredit. |
| 21 | FTD Date | DATETIME | YES | - | CODE-BACKED | First time deposit success date. From BackOffice.CustomerAllTimeAggregatedData.FirstTimeDepositSuccessDate. |
| 22 | Document Status | NVARCHAR | YES | - | CODE-BACKED | KYC document review status. Scalar subquery from Dictionary.DocumentStatus.DocumentStatusName via BackOffice.Customer.DocumentStatusID. |
| 23 | Verification Level | NVARCHAR | YES | - | CODE-BACKED | KYC verification level. Scalar subquery from Dictionary.VerificationLevel.Name via BackOffice.Customer.VerificationLevelID. |
| 24 | Country By Reg. Form | NVARCHAR | YES | - | CODE-BACKED | Registration country. Scalar subquery from Dictionary.Country.Name via Customer.Customer.CountryID. |
| 25 | Has 3rd Party | VARCHAR | NO | - | CODE-BACKED | 'Yes' if any BackOffice.CustomerToThirdPartyFundings record exists for this CID; 'No' otherwise. |
| 26 | As Has Open Cashouts | VARCHAR | NO | - | CODE-BACKED | 'Yes' if any Billing.Withdraw with CashoutStatusID NOT IN (3=Processed, 4=Canceled) exists; 'No' otherwise. Note: column alias has "As" prefix (likely legacy typo in alias definition). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AccountStatusID / CID | Customer.Customer | Primary source + filter | Customers with matching AccountStatusID. |
| CID | History.Customer | Player status change history | ValidFrom date range filter; MAX(ValidTo) for last change date. |
| CID | BackOffice.CustomerAllTimeAggregatedData | INNER JOIN | TotalDeposit, FirstTimeDepositSuccessDate. |
| CID | BackOffice.Customer | INNER JOIN | DocumentStatusID, VerificationLevelID. |
| PlayerStatusID | Dictionary.PlayerStatus | Scalar subquery | Status name. |
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons | Scalar subquery | Reason name. |
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | Scalar subquery (IIF) | Sub-reason name. |
| PendingClosureStatusID | Dictionary.PendingClosureStatus | Scalar subquery | Pending closure status name. |
| DocumentStatusID | Dictionary.DocumentStatus | Scalar subquery | Document status name. |
| VerificationLevelID | Dictionary.VerificationLevel | Scalar subquery | Verification level name. |
| CountryID | Dictionary.Country | Scalar subquery | Registration country. |
| CID | Trade.Position | EXISTS check | Has open position flag. |
| CID | BackOffice.CustomerToThirdPartyFundings | EXISTS check | Has 3rd party flag. |
| CID | Billing.Withdraw | EXISTS check | Has open cashouts flag. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BackOffice account closure management screen. No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetClosedAccountsByLastChangeDate (procedure)
├── Customer.Customer (table) [cross-schema]
├── History.Customer (table) [cross-schema]
├── BackOffice.CustomerAllTimeAggregatedData (view)
├── BackOffice.Customer (table)
├── BackOffice.IDs (UDT TVP)
├── Dictionary.PlayerStatus (table) [cross-schema, scalar subquery]
├── Dictionary.PlayerStatusReasons (table) [cross-schema, scalar subquery]
├── Dictionary.PlayerStatusSubReasons (table) [cross-schema, IIF subquery]
├── Dictionary.PendingClosureStatus (table) [cross-schema, scalar subquery]
├── Dictionary.DocumentStatus (table) [cross-schema, scalar subquery]
├── Dictionary.VerificationLevel (table) [cross-schema, scalar subquery]
├── Dictionary.Country (table) [cross-schema, scalar subquery]
├── Trade.Position (table) [cross-schema, EXISTS]
├── BackOffice.CustomerToThirdPartyFundings (table) [EXISTS]
└── Billing.Withdraw (table) [cross-schema, EXISTS]
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BackOffice account management screen. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Creates temp table #ClosedAccounts with clustered index on CID. Multiple correlated scalar subqueries per row for dictionary lookups - these are single-row lookups on indexed primary keys and execute efficiently.

### 7.2 Constraints

No SET NOCOUNT ON. No explicit NOLOCK on temp table reads. NOLOCK on all base table reads. ORDER BY CID DESC. Multiple scalar subqueries instead of JOINs for dictionary lookups - consistent with the style used throughout BackOffice SPs for readability. Result: 26 columns total.

---

## 8. Sample Queries

### 8.1 Get closed accounts (AccountStatusID=2) in January 2026
```sql
DECLARE @StatusIDs BackOffice.IDs;
DECLARE @ReasonIDs BackOffice.IDs;
DECLARE @SubReasonIDs BackOffice.IDs;
EXEC BackOffice.GetClosedAccountsByLastChangeDate
    @AccountStatusID = 2,
    @FromDate = '2026-01-01',
    @ToDate = '2026-02-01',
    @PlayerStatusIDs = @StatusIDs,
    @PlayerStatusReasonIDs = @ReasonIDs,
    @PlayerStatusSubReasonIDs = @SubReasonIDs;
```

### 8.2 Get pending closure accounts (AccountStatusID=1) filtered by specific player status
```sql
DECLARE @StatusIDs BackOffice.IDs;
INSERT @StatusIDs VALUES (5);  -- Pending Closure status ID
DECLARE @ReasonIDs BackOffice.IDs;
DECLARE @SubReasonIDs BackOffice.IDs;
EXEC BackOffice.GetClosedAccountsByLastChangeDate
    @AccountStatusID = 1,
    @FromDate = '2026-03-01',
    @ToDate = '2026-03-17',
    @PlayerStatusIDs = @StatusIDs,
    @PlayerStatusReasonIDs = @ReasonIDs,
    @PlayerStatusSubReasonIDs = @SubReasonIDs;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Ticket 52083 | Jira | Pending closure accounts SQL query improvement - original creation July 2018 (Geri Reshef). |
| Ticket 52278 | Jira | GetClosedAccountsByLastChangeDate - July 2018 update (Ran Ovadia). |
| RD-3758 / OPS0617 | Jira | Added playerStatusReason, regulation and designated regulation to BO reports - April 2019 (Geri Reshef). |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 3 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetClosedAccountsByLastChangeDate | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetClosedAccountsByLastChangeDate.sql*
