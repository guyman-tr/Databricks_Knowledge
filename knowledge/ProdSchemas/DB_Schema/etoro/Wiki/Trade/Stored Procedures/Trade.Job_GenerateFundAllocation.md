# Trade.Job_GenerateFundAllocation

> Maintenance job that ensures every fund account (AccountTypeID=9) has a Trade.Fund master record and a continuous chain of Trade.FundInterval rows extending into the future.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - operates on all fund accounts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.Job_GenerateFundAllocation is a housekeeping job procedure that bridges the gap between a customer account being classified as a fund (AccountTypeID=9 in BackOffice.Customer) and that fund having the operational records it needs in Trade.Fund and Trade.FundInterval. When a new fund account is created in BackOffice but no Trade.Fund row yet exists, this procedure auto-creates the fund master record. It then ensures that at least one FundInterval row exists whose PlannedEnd is in the future, creating new intervals as needed.

This job exists because fund accounts are first registered via the customer/backoffice system, but the trading system needs a Trade.Fund and Trade.FundInterval record to operate. Without these records, CopyFund allocation and rebalancing procedures cannot function. This procedure is the bootstrap mechanism that keeps all fund accounts fully provisioned.

Data flows as follows: the procedure is called as a standalone scheduled job (no callers found in the Trade schema). It reads BackOffice.Customer JOIN Customer.Customer WHERE AccountTypeID=9 to identify all fund owner CIDs. For each CID, it checks Trade.Fund for an existing record; if absent, INSERTs a new one sourcing FundName from Customer.CustomerStatic.UserName. It then checks Trade.FundInterval for at least one row for that FundID; if absent, creates the first interval from the owner's Registered date. Finally, it loops creating additional FundInterval rows until the chain extends past the current date.

---

## 2. Business Logic

### 2.1 Fund Bootstrap on First Encounter

**What**: Auto-creation of Trade.Fund when a fund account exists but has no fund record.

**Columns/Parameters Involved**: `BackOffice.Customer.AccountTypeID`, `Trade.Fund.FundOwnerID`, `Trade.Fund.FundAccountID`

**Rules**:
- If no Trade.Fund row exists for a CID (AccountTypeID=9), a new fund is created with hardcoded defaults: IsPublic=1, MinCopyAmount=5000, RefreshIntervalMonths=1, FundType=3 (Market).
- FundAccountID and FundOwnerID are both set to the owner's CID (same account owns and manages the fund on initial creation).
- FundName is taken from Customer.CustomerStatic.UserName for the owning CID.
- CreateDate is set to the customer's Registered date; LastUpdateDate to GETDATE().

**Diagram**:
```
BackOffice.Customer (AccountTypeID=9)
    |
    v CID not in Trade.Fund?
    |
    +--> INSERT Trade.Fund (FundName=UserName, FundAccountID=CID,
    |    FundOwnerID=CID, IsPublic=1, MinCopyAmount=5000,
    |    RefreshIntervalMonths=1, FundType=3/Market)
    |
    v FundID = SCOPE_IDENTITY()
```

### 2.2 FundInterval Chain Maintenance

**What**: Ensures every fund always has a FundInterval row whose PlannedEnd is beyond today.

**Columns/Parameters Involved**: `Trade.FundInterval.PlannedEnd`, `Trade.FundInterval.FundIntervalType`, `Trade.Fund.RefreshIntervalMonths`

**Rules**:
- If no FundInterval exists for the fund, inserts the first interval: PlannedStart=ActualStart=Registered date, PlannedEnd = start + RefreshIntervalMonths months (formatted to first of month).
- Loops: while no row exists with PlannedEnd > GETDATE(), finds max(PlannedEnd) and inserts a new interval starting from that date.
- All auto-created intervals use FundIntervalType=2 (Real) - no backtesting intervals are ever created by this job.
- PlannedEnd is computed as: `CAST(FORMAT(DATEADD(month, @Interval, @Date), 'yyyy-MM-01') AS datetime)` - always snapped to the first of the month.

**Diagram**:
```
Trade.FundInterval chain for one fund (RefreshIntervalMonths=1):
  Interval 1: PlannedStart=2020-01-15, PlannedEnd=2020-02-01
  Interval 2: PlannedStart=2020-02-01, PlannedEnd=2020-03-01
  ...
  Interval N: PlannedStart=2026-03-01, PlannedEnd=2026-04-01  <-- extends past today
```

### 2.3 Cursor-Style WHILE Loop with Temp Table

**What**: The procedure processes all fund accounts one at a time using a delete-as-you-go pattern.

**Columns/Parameters Involved**: `#Funds.CID`, `#Funds.Registered`

**Rules**:
- All fund owner CIDs are loaded into #Funds at the start.
- Each iteration processes one CID (SELECT TOP 1 ORDER BY CID), then DELETEs it from #Funds.
- The outer WHILE loop exits when #Funds is empty.
- PRINT statements emit progress messages (FundOwnerID, FundID, @Date) for SQL Agent job log monitoring.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | This procedure takes no input parameters. It operates on the entire set of fund accounts (AccountTypeID=9) at execution time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountTypeID=9 filter | BackOffice.Customer | Lookup/Read | Identifies fund owner CIDs by AccountTypeID. Only customers with AccountTypeID=9 are processed. |
| CID JOIN | Customer.Customer | JOIN/Read | Validates the CID exists in Customer schema; retrieves Registered date from BackOffice.Customer. |
| FundOwnerID match | Trade.Fund | Read/Write | Checks if a fund master record exists for the owner CID; creates one if absent. |
| FundID match | Trade.FundInterval | Read/Write | Checks interval coverage; creates Real intervals until PlannedEnd extends past today. |
| CID lookup | Customer.CustomerStatic | Read | Retrieves UserName to use as FundName during initial fund creation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Fund | Business logic | Referenced | Trade.Fund.Business Meaning documents this procedure as the primary writer that bootstraps fund records. |
| Trade.FundInterval | Business logic | Referenced | Trade.FundInterval.Business Meaning documents this procedure as the creator of Real (type=2) intervals. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Job_GenerateFundAllocation (procedure)
├── BackOffice.Customer (table)
├── Customer.Customer (table)
├── Customer.CustomerStatic (table)
├── Trade.Fund (table)
└── Trade.FundInterval (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FROM with NOLOCK; filters AccountTypeID=9 to identify fund owners; reads CID and Registered |
| Customer.Customer | Table | INNER JOINed to BackOffice.Customer ON CID to validate customer existence |
| Customer.CustomerStatic | Table | SELECT with NOLOCK; reads UserName for use as FundName on fund creation |
| Trade.Fund | Table | SELECTed to check if fund exists; INSERTed into if no record for FundOwnerID |
| Trade.FundInterval | Table | SELECTed to check interval coverage; INSERTed into to create new intervals |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Scheduled SQL Agent Job) | External | Called by SQL Server Agent job on a schedule to ensure all fund accounts are provisioned; no SP callers found in Trade schema |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check which fund accounts are missing Trade.Fund records (what the job would create)

```sql
SELECT BC.CID, BC.Registered, CS.UserName
FROM BackOffice.Customer AS BC WITH (NOLOCK)
INNER JOIN Customer.Customer AS CC WITH (NOLOCK) ON CC.CID = BC.CID
LEFT JOIN Trade.Fund AS F WITH (NOLOCK) ON F.FundOwnerID = BC.CID
INNER JOIN Customer.CustomerStatic AS CS WITH (NOLOCK) ON CS.CID = BC.CID
WHERE BC.AccountTypeID = 9
  AND F.FundID IS NULL;
```

### 8.2 Check funds whose interval chain does not extend past today (what the job would extend)

```sql
SELECT F.FundID, F.FundOwnerID, F.FundName, MAX(FI.PlannedEnd) AS MaxPlannedEnd
FROM Trade.Fund AS F WITH (NOLOCK)
LEFT JOIN Trade.FundInterval AS FI WITH (NOLOCK) ON FI.FundID = F.FundID
GROUP BY F.FundID, F.FundOwnerID, F.FundName
HAVING MAX(FI.PlannedEnd) IS NULL
    OR MAX(FI.PlannedEnd) < GETDATE();
```

### 8.3 View fund interval chain for a specific fund, showing type and date coverage

```sql
SELECT FI.FundIntervalID, FI.FundID, F.FundName,
       FI.FundIntervalType,
       FI.PlannedStart, FI.PlannedEnd,
       FI.ActualStart, FI.ActualEnd,
       FI.CreateDate
FROM Trade.FundInterval AS FI WITH (NOLOCK)
INNER JOIN Trade.Fund AS F WITH (NOLOCK) ON F.FundID = FI.FundID
WHERE FI.FundID = <FundID>
ORDER BY FI.PlannedStart;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.Job_GenerateFundAllocation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Job_GenerateFundAllocation.sql*
