# History.HistoryGetUnifiedbyCID

> Table-valued function that provides unified credit history for a single customer by combining the in-memory recent credit bucket (History.ActiveCreditRecentMemoryBucket) with the full historical archive (History.Credit) - used by BackOffice procedures for customer account lookups.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table-Valued Function (inline multi-statement) |
| **Signature** | `HistoryGetUnifiedbyCID(@CID INT) RETURNS TABLE (@ActiveCreditLocal)` |
| **Author** | Shay Oren, 03/01/2021 - COMOP-1066, COMOP-1083 |
| **Purpose** | Unified credit ledger access per customer: in-memory recent + archive historical |

---

## 1. Business Meaning

`History.HistoryGetUnifiedbyCID` is the BackOffice-facing accessor for a single customer's complete credit history. It merges two data sources into one result set:

1. **`History.ActiveCreditRecentMemoryBucket`** - the memory-optimized (in-memory OLTP) table holding the most recent credit events for active customers. Records are replicated here from History.Credit for fast access. Reading from this table avoids hitting the archive database (EtoroArchive) for recent data.

2. **`History.Credit`** - the full historical credit ledger (78-source UNION ALL over EtoroArchive branches, 2007-present). Contains all credit events.

The function's comment says "Access In memory table History.ActiveCreditRecentMemoryBucket" (Shay Oren, 03/01/2021), indicating it was created specifically to route BackOffice procedures through the in-memory table first. Prior to this, BackOffice procedures accessed `History.Credit` directly (as noted in BackOffice.GetCustomerByCID comment: "Shay Oren, 24/11/2020, Use History.HistoryGetUnifiedbyCID instead of direct access to History.Credit").

**Note on potential duplicates**: The function inserts from both ActiveCreditRecentMemoryBucket AND History.Credit for the same CID. If a credit record exists in both (recent records that appear in both the in-memory bucket and the archive), callers may receive duplicate rows. Callers are expected to handle or tolerate this by using DISTINCT or relying on the fact that the windows don't fully overlap.

---

## 2. Business Logic

### 2.1 Two-Source Credit Merge

**What**: Inserts from two sources into the return table for a single @CID.

**Columns/Parameters Involved**: `@CID`, all 35 columns of the credit ledger schema

**Rules**:
- INSERT 1: `SELECT ... FROM History.ActiveCreditRecentMemoryBucket WHERE CID = @CID`
  - All 35 columns explicitly listed (no `SELECT *`)
  - Returns recent credit events from the memory-optimized table
- INSERT 2: `SELECT ... FROM History.Credit WHERE CID = @CID`
  - Same 35 columns explicitly listed
  - Returns ALL historical credit events from the archive (2007-present)
- The return table uses `COLLATE Latin1_General_BIN` on the Description column
- No deduplication is performed - potential duplicates if records appear in both sources

### 2.2 Memory-Optimized Routing

**What**: By inserting from ActiveCreditRecentMemoryBucket first, the function ensures recent data is served from memory (fast) before querying the archive.

**Rules**:
- `History.ActiveCreditRecentMemoryBucket` is a memory-optimized table - reads are lock-free and extremely fast
- `History.Credit` routes to EtoroArchive (slow linked-server UNION ALL) - accessed second
- For BackOffice.GetCustomerByCID use case: the function is called to get the customer's credit events, where recent events (last 90 days) are most relevant - the memory bucket serves these fastest

---

## 3. Data Overview

Direct query blocked (History.Credit routes to EtoroArchive). Based on the schemas:

| Source | Scope | Row Count Estimate |
|--------|-------|-------------------|
| History.ActiveCreditRecentMemoryBucket | Recent events (last ~90 days) for active customers | Hundreds to thousands per customer |
| History.Credit | All historical events (2007-present) | Thousands to millions per customer |
| Combined | Full history with potential recent duplicates | History.Credit count + overlap |

---

## 4. Elements

### Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @CID | INT | Customer ID. Used as the WHERE filter on both source tables. |

### Return Table Schema

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | CreditID | BIGINT | Credit event identifier |
| 2 | CID | INT | Customer ID |
| 3 | CreditTypeID | TINYINT | Credit event type |
| 4 | PositionID | INT | Related position |
| 5 | ChampionshipID | INT | Related championship |
| 6 | CashoutID | INT | Related cashout |
| 7 | PaymentID | INT | Related payment |
| 8 | WithdrawID | INT | Related withdrawal |
| 9 | DepositID | INT | Related deposit |
| 10 | UpdateID | INT | Related update |
| 11 | CampaignID | INT | Related campaign |
| 12 | BonusTypeID | INT | Bonus type |
| 13 | CompensationReasonID | INT | Compensation reason |
| 14 | ManagerID | INT | Manager performing the action |
| 15 | Credit | MONEY | Credit amount (positive = credit to account) |
| 16 | Payment | MONEY | Payment amount |
| 17 | Description | VARCHAR(255) | COLLATE Latin1_General_BIN | Event description |
| 18 | Occurred | DATETIME | Timestamp of the credit event |
| 19 | WithdrawProcessingID | INT | Related withdraw processing |
| 20 | MirrorID | INT | Related mirror/copy trade |
| 21 | TotalCash | MONEY | Total cash balance after this event |
| 22 | TotalCashChange | MONEY | Change in total cash from this event |
| 23 | BonusCredit | MONEY | Bonus component of the credit |
| 24 | RealizedEquity | MONEY | Realized equity after this event |
| 25 | MirrorCash | DECIMAL(16,8) | Mirror/copy trade cash component |
| 26 | StocksOrderID | INT | Related stocks order |
| 27 | MirrorEquity | MONEY | Mirror equity value |
| 28 | MirrorDividendID | INT | Related mirror dividend |
| 29 | MoveMoneyReasonID | INT | Money movement reason |
| 30 | BSLRealFunds | MONEY | BSL (Buy Stop Limit?) real funds component |
| 31 | OriginalPositionID | INT | Original position for partial closes |
| 32 | SubCreditTypeID | INT | Sub-type for the credit event |
| 33 | DepositRollbackID | INT | Related deposit rollback |
| 34 | InterestMonthlyID | BIGINT | Related monthly interest |

**Note**: 34 columns listed in return table declaration (CreditID through InterestMonthlyID). Full column semantics: see `History.Credit.md` for complete business descriptions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | History.ActiveCreditRecentMemoryBucket | Query (in-memory) | First INSERT source - recent credit events from memory-optimized table |
| @CID | History.Credit | Query (EtoroArchive) | Second INSERT source - full archive credit ledger |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerByCID | Stored Procedure | ACTIVE - CROSS APPLY or equivalent to get customer credit summary |
| BackOffice.GetMyCustomers | Stored Procedure | ACTIVE - CROSS APPLY History.HistoryGetUnifiedbyCID(BI.CID) to enrich customer list |
| BackOffice.GetMirrorHistory | Stored Procedure | COMMENTED OUT - replaced with History.ActiveCreditBucket_VW |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HistoryGetUnifiedbyCID (table-valued function)
|--> History.ActiveCreditRecentMemoryBucket (memory-optimized table)
+--> History.Credit (view -> EtoroArchive UNION ALL)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCreditRecentMemoryBucket | Table (memory-optimized) | INSERT 1 - recent credit events WHERE CID = @CID |
| History.Credit | View (EtoroArchive) | INSERT 2 - all historical credit events WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Active? |
|--------|---------|
| BackOffice.GetCustomerByCID | YES |
| BackOffice.GetMyCustomers | YES |
| BackOffice.GetMirrorHistory | NO - commented out |

---

## 7. Technical Details

### 7.1 Potential Duplicate Rows

Credit events from the last 90 days (or whatever window History.ActiveCreditRecentMemoryBucket covers) will appear in BOTH inserts:
- Insert 1 from ActiveCreditRecentMemoryBucket (recent window)
- Insert 2 from History.Credit (all history including the same recent window)

Callers using this TVF should be aware of this and handle duplicates if needed (GROUP BY CreditID, DISTINCT, etc.).

### 7.2 Table-Valued Function (Multi-Statement)

This is a multi-statement TVF (defines a return TABLE variable and uses INSERTs). Performance characteristic: SQL Server cannot optimize the return table's statistics as well as an inline TVF. For large CID histories, this may be slower than an equivalent inline TVF with a UNION ALL.

---

## 8. Sample Queries

### 8.1 Get all credit events for a customer (as used by BackOffice)

```sql
SELECT
    h.CreditID,
    h.CreditTypeID,
    h.Credit,
    h.Payment,
    h.Occurred,
    h.Description
FROM History.HistoryGetUnifiedbyCID(14866508) h
ORDER BY h.Occurred DESC
```

### 8.2 CROSS APPLY pattern (as used by BackOffice.GetMyCustomers)

```sql
SELECT
    BI.CID,
    HHG.CreditID,
    HHG.CreditTypeID,
    HHG.Credit,
    HHG.Occurred
FROM ##BasicInfo BI
CROSS APPLY History.HistoryGetUnifiedbyCID(BI.CID) HHG
WHERE HHG.CreditTypeID = 1  -- Deposits only
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Related Jira tickets from DDL comments: COMOP-1066, COMOP-1083 (Change Risk default in BO).

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 8.8/10, Logic: 9.0/10, Relationships: 9.2/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - EtoroArchive blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 consumers (2 active, 1 commented-out) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HistoryGetUnifiedbyCID | Type: Table-Valued Function | Source: etoro/etoro/History/Functions/History.HistoryGetUnifiedbyCID.sql*
