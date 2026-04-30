# BackOffice.GetPendingClosureAccountsByLastChangeDate

> Returns accounts that first transitioned into a specific PendingClosureStatus within a date window, keeping only those that progressed through earlier closure stages - a BackOffice tool for managing accounts in the account closure workflow.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PendingClosureStatusID + @FromDate + @ToDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports the account closure workflow in BackOffice, enabling agents to find and manage accounts at a specific stage of the pending closure process. Rather than returning all accounts currently in a closure status, it identifies accounts that **first reached** that status within a specified date range AND had previously progressed through earlier stages - ensuring agents see accounts following the proper closure progression workflow.

Typical use case: "Show me all accounts that entered Pending Closure Stage 2 this week, which had previously been at Stage 1." This enables staged processing - agents handle accounts at each closure stage in order.

**Permission**: No active EXECUTE grants found. Likely used via BOUser or ad-hoc BI queries.

---

## 2. Business Logic

### 2.1 Transition Detection (Entry Into Status)

**What**: Identifies the exact moment each account first entered the target `@PendingClosureStatusID` within the date window.

**Columns/Parameters Involved**: History.Customer.PendingClosureStatusID, History.Customer.ValidFrom, @FromDate, @ToDate

**Rules**:
- Uses `History.Customer` temporal versioning (ValidFrom/ValidTo) to detect status transitions.
- The current history row must have `PendingClosureStatusID = @PendingClosureStatusID` AND its ValidFrom falls within `[@FromDate, @ToDate)`.
- Transition condition: the PRECEDING history row (ValidTo = current ValidFrom) must have EITHER a different PendingClosureStatusID OR no preceding row exists. This captures the exact moment the status CHANGED to the target value, not just any time it was in that status.
- Also filters by current `Customer.Customer.PendingClosureStatusID = @PendingClosureStatusID` - ensures the customer is still in this status today (not just historically).
- `MIN(hc.ValidFrom)` per CID: captures the EARLIEST transition within the window (accounts are inserted once per CID).

### 2.2 Optional Status and Regulation Filters

**What**: Allows filtering the matching accounts by additional criteria.

**Columns/Parameters Involved**: @PlayerStatusIDs, @PlayerStatusReasonIDs, @PlayerStatusSubReasonIDs, @RegulationID, @DesignatedRegulationID

**Rules**:
- TVP filters use the pattern `IN (SELECT ID FROM @TVP) OR COUNT(@TVP) = 0` - empty TVP = no filter.
- `@RegulationID IS NULL OR bc.RegulationID = @RegulationID`: Optional single-regulation filter.
- `@DesignatedRegulationID IS NULL OR bc.DesignatedRegulationID = @DesignatedRegulationID`: Optional designated regulation filter.

### 2.3 Progression Stage Filter (DELETE step)

**What**: Removes accounts that never went through a lower closure stage, ensuring only accounts that properly progressed through earlier stages remain.

**Columns/Parameters Involved**: History.Customer.PendingClosureStatusID (< @PendingClosureStatusID), ValidTo >= @FromDate

**Rules**:
- After building `#PendingAccounts`, DELETEs CIDs where NO history exists showing `PendingClosureStatusID < @PendingClosureStatusID` with `ValidTo >= @FromDate`.
- KEEPS only accounts that had a LOWER PendingClosureStatusID value since @FromDate - meaning they were at an earlier stage and progressed.
- This prevents accounts that "jumped" directly to the requested stage (skipping earlier stages) from appearing in results.

### 2.4 Output Enrichment

**What**: Returns the full account profile with status labels, financial summary, and risk indicators.

**Columns/Parameters Involved**: Many correlated subqueries for label resolution

**Rules**:
- `Has Open Position`: EXISTS check on `Trade.Position` for the CID.
- `Has Open Cashouts`: EXISTS check on `Billing.Withdraw` where `CashoutStatusID NOT IN (3, 4)`. CashoutStatusID 3=Approved, 4=Rejected/Cancelled. Open cashouts = any non-terminal status.
- `Has 3rd Party`: EXISTS check on `BackOffice.CustomerToThirdPartyFundings`.
- `SubReason`: `IIF(PlayerStatusSubReasonID = 0, PlayerStatusSubReasonComment, [Dictionary lookup])` - when SubReasonID=0, uses the free-text comment field instead of dictionary name.
- All status name columns resolved via correlated subqueries to Dictionary tables.
- `Select..`: CAST(0 AS BIT) - a boolean false placeholder for a UI selection checkbox column.
- Ordered by CID DESC (newest accounts first).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PendingClosureStatusID | INT | NO | - | CODE-BACKED | The closure stage to query. Matches Dictionary.PendingClosureStatus.PendingClosureStatusID. Accounts must currently be in this status AND have first entered it in the date window. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of the date window. Accounts that first entered @PendingClosureStatusID on or after this date are included. |
| 3 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of the date window (exclusive). Accounts that first entered @PendingClosureStatusID before this date are included. |
| 4 | @PlayerStatusIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Optional filter by current PlayerStatusID. Empty TVP = all statuses. |
| 5 | @PlayerStatusReasonIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Optional filter by current PlayerStatusReasonID. Empty TVP = all reasons. |
| 6 | @PlayerStatusSubReasonIDs | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Optional filter by current PlayerStatusSubReasonID. Empty TVP = all sub-reasons. |
| 7 | @RegulationID | INT | YES | NULL | CODE-BACKED | Optional filter by regulation (e.g., FCA, CySEC). NULL = all regulations. |
| 8 | @DesignatedRegulationID | INT | YES | NULL | CODE-BACKED | Optional filter by designated (target) regulation. NULL = all. |

**Output Columns** (SELECT *):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Select.. | BIT | NO | 0 | CODE-BACKED | UI checkbox placeholder (always 0/false). Allows bulk selection in BackOffice grid UI. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer account ID. |
| 3 | UserName | NVARCHAR | YES | - | CODE-BACKED | Customer's username. |
| 4 | Has Open Position | VARCHAR(3) | NO | - | CODE-BACKED | 'Yes' if the customer has any open trade positions; 'No' otherwise. Used to flag accounts that cannot be immediately closed. |
| 5 | Balance | DECIMAL | YES | - | CODE-BACKED | Current cash balance (Customer.Customer.Credit). |
| 6 | Equity | DECIMAL | YES | - | CODE-BACKED | Current realized equity (Customer.Customer.RealizedEquity). |
| 7 | Pending Closure Status | NVARCHAR | YES | - | CODE-BACKED | Display name of the current PendingClosureStatus from Dictionary.PendingClosureStatus. 'No' if no status set. |
| 8 | Customer Status | NVARCHAR | YES | - | CODE-BACKED | Player status name from Dictionary.PlayerStatus (e.g., Active, Blocked, Closed). |
| 9 | Reason | NVARCHAR | YES | - | CODE-BACKED | Player status reason name from Dictionary.PlayerStatusReasons. |
| 10 | SubReason | NVARCHAR | YES | - | CODE-BACKED | Player status sub-reason. If PlayerStatusSubReasonID=0, shows PlayerStatusSubReasonComment (free text); otherwise shows Dictionary.PlayerStatusSubReasons.Name. |
| 11 | Customer Level | NVARCHAR | YES | - | CODE-BACKED | Player level name from Dictionary.PlayerLevel (e.g., Silver, Gold, Platinum). |
| 12 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Regulation name from Dictionary.Regulation for bc.RegulationID. |
| 13 | Designated Regulation | NVARCHAR | YES | - | CODE-BACKED | Designated (target) regulation name from Dictionary.Regulation for bc.DesignatedRegulationID. |
| 14 | Last Pending Closure Change Date | DATETIME | NO | - | CODE-BACKED | The earliest date within the window that this account entered @PendingClosureStatusID. The MIN(ValidFrom) from History.Customer. |
| 15 | Blocked Comment | NVARCHAR | YES | - | CODE-BACKED | Customer.Customer.Comments - any blocking or administrative notes. |
| 16 | Total Deposits | DECIMAL(16,2) | YES | - | CODE-BACKED | Lifetime total deposits from BackOffice.CustomerAllTimeAggregatedData. |
| 17 | Bonus Credit(NWA) | DECIMAL | YES | - | CODE-BACKED | Current bonus credit balance (Non-Withdrawable Amount) from Customer.Customer. |
| 18 | FTD Date | DATETIME | YES | - | CODE-BACKED | First-time deposit success date from BackOffice.CustomerAllTimeAggregatedData. |
| 19 | Document Status | NVARCHAR | YES | - | CODE-BACKED | KYC document status name from Dictionary.DocumentStatus. |
| 20 | Verification Level | NVARCHAR | YES | - | CODE-BACKED | KYC verification level name from Dictionary.VerificationLevel. |
| 21 | Country By Reg. Form | NVARCHAR | YES | - | CODE-BACKED | Customer's country of registration from Dictionary.Country. |
| 22 | Has 3rd Party | VARCHAR(3) | NO | - | CODE-BACKED | 'Yes' if customer has any third-party funding records in BackOffice.CustomerToThirdPartyFundings; 'No' otherwise. |
| 23 | Has Open Cashouts | VARCHAR(3) | NO | - | CODE-BACKED | 'Yes' if customer has any withdrawal (Billing.Withdraw) not in terminal status (CashoutStatusID NOT IN (3=Approved, 4=Cancelled)); 'No' otherwise. |
| 24 | GCID | INT | YES | - | CODE-BACKED | Global Customer ID (cross-platform identifier). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Transition detection | History.Customer | Read (INNER JOIN) | Temporal history for transition point detection |
| Current state | Customer.Customer | Read (INNER JOIN) | Current PendingClosureStatusID, financial metrics, profile |
| BackOffice attributes | BackOffice.Customer | Read (INNER JOIN) | RegulationID, DesignatedRegulationID, DocumentStatusID, VerificationLevelID |
| Financial aggregates | BackOffice.CustomerAllTimeAggregatedData | Read (INNER JOIN) | TotalDeposit, FirstTimeDepositSuccessDate |
| Open positions | Trade.Position | EXISTS check | Has Open Position indicator |
| Open cashouts | Billing.Withdraw | EXISTS check | Has Open Cashouts indicator |
| 3rd party fundings | BackOffice.CustomerToThirdPartyFundings | EXISTS check | Has 3rd Party indicator |
| Status labels | Dictionary.PendingClosureStatus/PlayerStatus/PlayerStatusReasons/PlayerStatusSubReasons/PlayerLevel/DocumentStatus/VerificationLevel/Regulation/Country | Correlated subqueries | All human-readable label columns |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active EXECUTE grants found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetPendingClosureAccountsByLastChangeDate (procedure)
+-- Customer.Customer (table)
+-- History.Customer (table - transition detection)
+-- BackOffice.Customer (table)
+-- BackOffice.CustomerAllTimeAggregatedData (table)
+-- Trade.Position (EXISTS check)
+-- Billing.Withdraw (EXISTS check)
+-- BackOffice.CustomerToThirdPartyFundings (EXISTS check)
+-- 9x Dictionary tables (label resolution)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Current status, financial data, PlayerStatusID/Reason/SubReason |
| History.Customer | Table | Temporal transition detection; ValidFrom/ValidTo versioning |
| BackOffice.Customer | Table | RegulationID, DesignatedRegulationID, DocumentStatusID, VerificationLevelID |
| BackOffice.CustomerAllTimeAggregatedData | Table | Lifetime deposit total and FTD date |
| Trade.Position | Table | Open position existence check |
| Billing.Withdraw | Table | Open cashout existence check |
| BackOffice.CustomerToThirdPartyFundings | Table | Third-party funding existence check |
| Dictionary.PendingClosureStatus | Table | Pending closure status name |
| Dictionary.PlayerStatus | Table | Player status name |
| Dictionary.PlayerStatusReasons | Table | Status reason name |
| Dictionary.PlayerStatusSubReasons | Table | Status sub-reason name |
| Dictionary.PlayerLevel | Table | Customer tier name |
| Dictionary.DocumentStatus | Table | KYC document status name |
| Dictionary.VerificationLevel | Table | KYC verification level name |
| Dictionary.Regulation | Table | Regulation name (used twice: RegulationID and DesignatedRegulationID) |
| Dictionary.Country | Table | Country name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | No EXECUTE grants; used ad-hoc |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table + clustered index | Performance | #PendingAccounts indexed on (CID, PendingClosureStatusIDChangeDate) for efficient DELETE and JOIN |
| Transition detection pattern | Logic | Previous row = ValidTo = current ValidFrom; handles first-ever entry (no prior row) separately |
| DELETE stage filter | Business rule | Keeps only accounts with prior lower-status history since @FromDate |
| TVP empty = no filter | Design | COUNT(@TVP)=0 check enables optional filtering without NULL parameter overloading |
| CashoutStatusID NOT IN (3,4) | Business rule | 3=Approved, 4=Cancelled/Rejected - "open" means non-terminal |

---

## 8. Sample Queries

### 8.1 Get accounts that entered PendingClosureStatus 2 this week

```sql
DECLARE @StatusIds BackOffice.IDs;
DECLARE @ReasonIds BackOffice.IDs;
DECLARE @SubReasonIds BackOffice.IDs;

EXEC BackOffice.GetPendingClosureAccountsByLastChangeDate
    @PendingClosureStatusID = 2,
    @FromDate = '2026-03-11',
    @ToDate = '2026-03-18',
    @PlayerStatusIDs = @StatusIds,
    @PlayerStatusReasonIDs = @ReasonIds,
    @PlayerStatusSubReasonIDs = @SubReasonIds,
    @RegulationID = NULL,
    @DesignatedRegulationID = NULL;
```

### 8.2 View pending closure status values

```sql
SELECT PendingClosureStatusID, PendingClosureStatusName
FROM Dictionary.PendingClosureStatus WITH (NOLOCK)
ORDER BY PendingClosureStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPendingClosureAccountsByLastChangeDate | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPendingClosureAccountsByLastChangeDate.sql*
