# BI_DB_dbo.BI_DB_LimitedAccountsWithReasonsNEW

> 117,818-row operations/compliance SLA monitoring table listing all blocked/limited customers who logged in within the last 12 months, with their block reason hierarchy (PlayerStatus/Reason/SubReason), block duration, equity, and SLA classification ('IN' within SLA / 'OUT' exceeded). Covers 4 blocked statuses: Block Deposit & Trading (58%), Pending Verification (18%), Deposit Blocked (14%), Trade & MIMO Blocked (10%). AML is the primary block reason (70%). Daily TRUNCATE+INSERT via SP_LimitedAccountsWithReasonsNEW.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Operations -- Blocked Account SLA Monitoring) |
| **Production Source** | DWH dimensions/facts aggregated by SP_LimitedAccountsWithReasonsNEW |
| **Refresh** | Daily TRUNCATE + INSERT (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_LimitedAccountsWithReasonsNEW` is a **compliance/operations SLA monitoring table** that tracks all customers with restricted account statuses who were active in the last 12 months (logged in). Each row represents one blocked customer with their full block reason hierarchy, the date the block was applied, how long it has been active, their equity, and whether the block is within the expected SLA ('IN') or has exceeded it ('OUT').

The table holds 117,818 rows rebuilt daily. The SP:
1. Identifies blocked customers (PlayerStatusID IN 9, 10, 13, 15) who logged in within 12 months
2. Uses LAG() window functions on Fact_SnapshotCustomer to find WHEN each status change occurred
3. Calculates DaysFromBlock as days since the current block was applied
4. Applies two complex SLA rule sets (PlayerStatusGrouping and PendingClosureStatusGrouping) based on ~60 combinations of Status x Reason x SubReason x DaysFromBlock
5. Enriches with equity, country, regulation, player level

### SLA Classification
- **PlayerStatusGrouping**: 'IN' means the block is within the expected resolution SLA (1.6% of rows), 'OUT' means the SLA has been exceeded (98.4%)
- **PendingClosureStatusGrouping**: Separate SLA for accounts that should be moved to pending closure

### Author and History
Created by Izmini Nicolaou (2023-09-21). Changed to MAX player status date by Pavlina Masoura (2024-12-06).

---

## 2. Business Logic

### 2.1 Blocked Status Filter

**What**: Only customers with restricted statuses are included.
**Columns Involved**: PlayerStatus
**Rules**:
- PlayerStatusID = 9 (Trade & MIMO Blocked)
- PlayerStatusID = 10 (Deposit Blocked)
- PlayerStatusID = 13 (Pending Verification)
- PlayerStatusID = 15 (Block Deposit & Trading)
- Must be valid customer (IsValidCustomer=1)
- Must have logged in within last 12 months

### 2.2 Block Duration Tracking

**What**: Determines when the current block was applied using historical snapshot data.
**Columns Involved**: PlayerStatusBlockedTime, PlayerStatusReasonBlockedTime, PlayerStatusSubReasonBlockedTime, PendingClosureTime, DaysFromBlock
**Rules**:
- Uses LAG() on Fact_SnapshotCustomer to detect status transitions
- MAX change date where the current status differs from the previous
- DaysFromBlock = DATEDIFF(DAY, PlayerStatusBlockedTime, GETDATE())

### 2.3 PlayerStatusGrouping SLA Rules

**What**: Complex SLA classification based on ~60 rule combinations.
**Columns Involved**: PlayerStatusGrouping
**Rules**:
- 'IN': Block is within the expected SLA window (varies by reason: 1-118 days)
- 'OUT': Block has exceeded the SLA window
- SLA windows vary by Status x Reason x SubReason x other factors (IsHighRiskCountry, Equity, VerificationLevelID, DesignatedRegulationID)
- Example: AML/HRC blocks have 7-day SLA; Hacked Account has 118-day SLA

### 2.4 Equity Level Classification

**What**: Brackets customer equity for analysis.
**Columns Involved**: Equity_Level
**Rules**:
- 'A:0-5': Equity < $5 (83%)
- 'B:5-50': $5 to $50
- 'C:50-500': $50 to $500
- 'D: 500+': >= $500

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Medium table (118K rows). Full scans are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Blocks exceeding SLA | `WHERE PlayerStatusGrouping = 'OUT'` |
| AML blocks by sub-reason | `WHERE PlayerStatusReason = 'AML' GROUP BY PlayerStatusSubReason` |
| High-equity blocked accounts | `WHERE Equity_Level = 'D: 500+'` |
| FCA-specific blocks | `WHERE DesignatedRegulation = 'FCA'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID | Full customer profile |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID = RealCID | Customer lifecycle dates |

### 3.4 Gotchas

- **98.4% are OUT of SLA**: The vast majority of blocks have exceeded their SLA. This is normal -- most blocked accounts are long-term blocks that are not expected to be resolved quickly
- **Equity from V_Liabilities**: Equity = Liabilities + ActualNWA. Can be negative
- **DesignatedRegulation vs Regulation**: DesignatedRegulation is the regulation the customer was ASSIGNED to (may differ from current RegulationID)
- **SLA rules are hardcoded**: The 60+ SLA rules in the SP are hardcoded CASE statements. Changes to SLA policy require SP modification
- **DaysFromBlock recalculated daily**: Since this is TRUNCATE+INSERT, DaysFromBlock increases by 1 each day for unchanged blocks

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID. One row per blocked customer. FK to Dim_Customer.RealCID. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 2 | DesignatedRegulation | varchar(30) | YES | Designated regulation name. The regulation entity the customer was assigned to (may differ from current). From Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 3 | Regulation | varchar(30) | YES | Current regulation name. From Dim_Regulation.Name via Dim_Customer.RegulationID. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 4 | PlayerStatusBlockedTime | datetime | YES | Date when the current PlayerStatus was applied. Derived via LAG() on Fact_SnapshotCustomer, taking MAX change date. Range: 2015-11-10 to 2026-04-12. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 5 | PlayerStatusReasonBlockedTime | datetime | YES | Date when the current PlayerStatusReason was applied. Derived via LAG() on Fact_SnapshotCustomer. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 6 | PlayerStatusSubReasonBlockedTime | datetime | YES | Date when the current PlayerStatusSubReason was applied. Derived via LAG() on Fact_SnapshotCustomer. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 7 | PendingClosureTime | datetime | YES | Date when the current PendingClosureStatus was applied. NULL if no pending closure status. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 8 | DaysFromBlock | bigint | YES | Days since PlayerStatusBlockedTime. DATEDIFF(DAY, PlayerStatusBlockedTime, GETDATE()). Recalculated daily. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 9 | PlayerStatus | varchar(max) | YES | Player status name. From Dim_PlayerStatus.Name. Values: 'Block Deposit & Trading' (58%), 'Pending Verification' (18%), 'Deposit Blocked' (14%), 'Trade & MIMO Blocked' (10%). (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 10 | PlayerStatusReason | varchar(max) | YES | Block reason. From Dim_PlayerStatusReasons.Name. Top: AML (70%), KYC (21%), Risk (6%). (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 11 | PlayerStatusSubReason | varchar(max) | YES | Block sub-reason. From Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName. Specific compliance trigger (e.g., 'HRC', 'Screening - Sanctions', 'Expired POI/POA'). (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 12 | PendingClosureStatus | varchar(max) | YES | Pending closure status name. From Dim_PendingClosureStatus.PendingClosureStatusName. NULL if not in closure process. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 13 | VerificationLevelID | int | YES | KYC verification level. 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Used in some SLA rules. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW via Dim_Customer) |
| 14 | Equity | money | YES | Customer equity = Liabilities + ActualNWA from V_Liabilities (yesterday's snapshot). In USD. Can be negative. 83% of blocked accounts have < $5 equity. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 15 | IsHighRiskCountry | int | YES | Whether the customer's country is classified as high-risk. 1=high-risk, 0=not. From Dim_Country. Affects SLA rules for some AML sub-reasons. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 16 | PlayerStatusGrouping | varchar(max) | YES | SLA classification for the block. 'IN'=within SLA (1.6%), 'OUT'=exceeded SLA (98.4%). Based on ~60 hardcoded CASE rules combining Status, Reason, SubReason, DaysFromBlock, and other factors. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 17 | PendingClosureStatusGrouping | varchar(max) | YES | SLA classification for pending closure eligibility. 'IN'=eligible for closure, 'OUT'=not yet eligible. Separate rule set from PlayerStatusGrouping; requires PendingClosureStatusID != 1. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 18 | Equity_Level | varchar(max) | YES | Equity bracket. 'A:0-5' (83%), 'B:5-50', 'C:50-500', 'D: 500+'. Based on ISNULL(Equity, 0). (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 19 | Region | varchar(50) | YES | Customer's geographic region. From Dim_Country.Region via Dim_Customer.CountryID. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 20 | Country | varchar(50) | YES | Customer's country name. From Dim_Country.Name via Dim_Customer.CountryID. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 21 | PlayerLevel | varchar(max) | YES | Customer's player level (e.g., Standard, Silver, Gold, Platinum, Diamond, Popular Investor). From Dim_PlayerLevel.Name via Dim_Customer.PlayerLevelID. (Tier 2 -- SP_LimitedAccountsWithReasonsNEW) |
| 22 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted. Set to GETDATE(). (Tier 5 -- SP_LimitedAccountsWithReasonsNEW) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| RealCID | Dim_Customer / BI_DB_CIDFirstDates | RealCID / CID | Filter: blocked + logged in 12mo |
| DesignatedRegulation, Regulation | Dim_Regulation | Name | JOIN on DesignatedRegulationID / RegulationID |
| *BlockedTime columns | Fact_SnapshotCustomer + Dim_Range | DateRangeID | LAG() window → MAX change date |
| DaysFromBlock | Computed | PlayerStatusBlockedTime | DATEDIFF(DAY) |
| PlayerStatus/Reason/SubReason | Dim_PlayerStatus/Reasons/SubReasons | Name columns | JOIN lookups |
| PendingClosureStatus | Dim_PendingClosureStatus | PendingClosureStatusName | JOIN lookup |
| Equity | V_Liabilities | Liabilities + ActualNWA | ISNULL sum |
| PlayerStatusGrouping | Computed | ~60 CASE rules | Status x Reason x SubReason x Days |
| Equity_Level | Computed | Equity | CASE brackets |
| Region, Country | Dim_Country | Region, Name | JOIN lookups |
| PlayerLevel | Dim_PlayerLevel | Name | JOIN lookup |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CIDFirstDates (LastLoggedIn filter: 12 months)
  + DWH_dbo.Dim_Customer (blocked status filter: PlayerStatusID IN 9,10,13,15)
    |-- SP_LimitedAccountsWithReasonsNEW (daily, TRUNCATE+INSERT) ---|
    |   Step 1: #lastlogin = active blocked customers                 |
    |   Step 2: #blockedtime = LAG() on Fact_SnapshotCustomer         |
    |           → when PlayerStatus changed to current                |
    |   Step 3: #blockedtimereason, #subreason, #suggested            |
    |           → when Reason/SubReason/PendingClosure changed        |
    |   Step 4: #aging = DaysFromBlock + dimension lookups + equity   |
    |   Step 5: #details = SLA CASE rules (60+ combinations)         |
    |           → PlayerStatusGrouping (IN/OUT)                       |
    |           → PendingClosureStatusGrouping (IN/OUT)               |
    |   Step 6: Final enrichment (Country, Region, PlayerLevel, etc.) |
    v
BI_DB_dbo.BI_DB_LimitedAccountsWithReasonsNEW (117,818 rows)
  (Not in Generic Pipeline -- _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer profile |
| DesignatedRegulation, Regulation | DWH_dbo.Dim_Regulation | Regulation details |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Status details |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Reason details |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | Sub-reason details |
| Country, Region | DWH_dbo.Dim_Country | Geography |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Player level details |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Blocks Exceeding SLA by Reason

```sql
SELECT PlayerStatusReason, PlayerStatusSubReason,
       COUNT(*) AS blocked_count,
       AVG(DaysFromBlock) AS avg_days
FROM [BI_DB_dbo].[BI_DB_LimitedAccountsWithReasonsNEW]
WHERE PlayerStatusGrouping = 'OUT'
GROUP BY PlayerStatusReason, PlayerStatusSubReason
ORDER BY blocked_count DESC
```

### 7.2 High-Equity Blocked Accounts

```sql
SELECT RealCID, Regulation, PlayerStatus, PlayerStatusReason,
       PlayerStatusSubReason, Equity, DaysFromBlock
FROM [BI_DB_dbo].[BI_DB_LimitedAccountsWithReasonsNEW]
WHERE Equity_Level = 'D: 500+'
ORDER BY Equity DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4, 1 T5 | Elements: 22/22, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_LimitedAccountsWithReasonsNEW | Type: Table | Production Source: DWH dimensions/facts*
