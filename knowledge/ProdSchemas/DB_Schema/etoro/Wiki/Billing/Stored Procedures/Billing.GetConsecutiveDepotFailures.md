# Billing.GetConsecutiveDepotFailures

> Detects consecutive deposit failures (declined/technical) per payment depot since the last approval, returning failing deposits that exceed a per-depot threshold. Used by the ProviderRecoveryService to trigger payment processor health alerts.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @json (depot IDs and thresholds) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetConsecutiveDepotFailures` is a payment health monitoring procedure. The `ProviderRecoveryService` calls it to detect when a payment processor (depot) is experiencing consecutive failures — when deposits are consistently declining or failing with technical errors since the last successful approval. When a depot's consecutive failure count exceeds its configured threshold, the service triggers an alert.

The procedure answers: "For each monitored depot, how many distinct users have had a declined/technical deposit since the last approval? Does that count exceed the threshold?"

**Key business rule**: "Consecutive" means failures that occurred AFTER the last approved deposit on that depot within the last 24 hours. An approval resets the streak. If a depot has no approvals in the last 24 hours at all, all failures are considered consecutive.

Created by Dor Izmaylov, 16/05/2023. Granted to `ProviderRecoveryServiceUser`.

Live data context: In the last 30 days, Billing.Deposit had 126,631 approved (status=2), 13,005 declined (status=3), and 2,422 technical failures (status=4).

---

## 2. Business Logic

### 2.1 JSON Input Parameter

**What**: Accepts a JSON array of depot-threshold configurations instead of a relational parameter.

**Columns/Parameters Involved**: `@json`, `DepotID`, `Threshold`

**Rules**:
- `@json` = `NVARCHAR(MAX)` JSON array, each element: `{ "DepotID": N, "Threshold": "N" }`
- Parsed via `OPENJSON(@json) WITH (DepotID INT 'strict $.DepotID', Threshold NVARCHAR(50) '$.Threshold')`
- `strict $.DepotID` - throws error if DepotID is missing in any element
- The caller (ProviderRecoveryService) controls which depots to monitor and what their individual failure thresholds are
- Joined to Billing.Depot to add DepotName and FundingTypeID for result context

### 2.2 Lookback Window and Deposit Range

**What**: Restricts analysis to the last 24 hours and uses DepositID range for efficient scanning.

**Columns/Parameters Involved**: `@MinDepositID`, `@MaxDepositID`, `PaymentDate`

**Rules**:
- `@MinDepositID = MIN(DepositID), @MaxDepositID = MAX(DepositID)` WHERE PaymentDate > GETUTCDATE()-1
- This DepositID range is used as an index-friendly pre-filter: `BD.DepositID >= @MinDepositID AND <= @MaxDepositID`
- Combined with `PaymentDate > GETUTCDATE()-1` in the #BillingDeposit temp table for double filtering
- `OPTION (USE HINT('DISABLE_OPTIMIZER_ROWGOAL'))` on the DepositID range query - prevents the optimizer from stopping early when using rowgoal hints, ensuring it scans all matching rows
- Pre-filters to PaymentStatusIDs IN (2,3,4): Approved, Decline, Technical only (excludes New/Pending intermediate states)

### 2.3 Consecutive Failure Detection via CROSS APPLY

**What**: For each depot, counts distinct users with failures AFTER the last approval using a correlated subquery.

**Columns/Parameters Involved**: `DeclinedCount`, `Threshold`, `PaymentStatusID 2 (Approved) / 3 (Decline) / 4 (Technical)`

**Rules**:
- The "last approved DepositID" anchor: `SELECT TOP(1) DepositID FROM #BillingDeposit WHERE PaymentStatusID=2 AND DepotID=DT.DepotID ... ORDER BY PaymentDate DESC`
- "After the last approval" means: `DepositID > (last approved DepositID)` for that depot
- `DeclinedCount` = number of DISTINCT CIDs with a failed deposit (status 3 or 4) that occurred after the last approval
- If no approval exists in the last 24 hours for a depot: `TOP(1)` returns NULL, so `DepositID > NULL` evaluates to FALSE for all rows, meaning DeclinedCount = all distinct failing CIDs in the window
- `WHERE B.DeclinedCount > DT.Threshold` - only depots exceeding their threshold are returned

### 2.4 Result: Failing Deposits After Last Approval

**What**: Returns detailed rows for failing deposits on depots that exceeded their threshold.

**Columns/Parameters Involved**: All columns in final SELECT

**Rules**:
- Final SELECT joins `#Depot_Threshold` to `#BillingDeposit` to `Dictionary.PaymentStatus`
- Returns one row per DepotID + PaymentDate + CID + PaymentGeneration combination (SELECT DISTINCT on these)
- `MAX(BD.DepositID) as DepositID` - the most recent deposit ID within the group
- Only rows where PaymentStatusID IN (3,4) and DepositID after last approval
- Used by ProviderRecoveryService to identify which specific deposits triggered the alert

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @json | nvarchar(MAX) | NO | - | VERIFIED | JSON array of depot monitoring configurations. Each element: `{"DepotID": N, "Threshold": "N"}`. Parsed with OPENJSON. Caller (ProviderRecoveryService) provides which depots to check and their per-depot failure thresholds. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepotID | int | NO | - | VERIFIED | The failing payment depot. From #Depot_Threshold. References Billing.Depot. |
| 2 | DepotName | varchar | NO | - | VERIFIED | Human-readable depot name. From Billing.Depot.Name. |
| 3 | FundingTypeID | int | NO | - | VERIFIED | Funding method of the depot. From Billing.Depot.FundingTypeID. References Dictionary.FundingType. |
| 4 | DepositID | int | NO | - | VERIFIED | MAX(DepositID) within the group - the most recent failing deposit for this depot/customer/date combination. |
| 5 | PaymentDate | datetime | NO | - | VERIFIED | Date/time of the failing deposit. All rows are within the last 24 hours. |
| 6 | CID | int | NO | - | VERIFIED | Customer ID whose deposit failed. Used in GROUP BY so each customer failure appears separately. |
| 7 | PaymentGeneration | (int/varchar) | YES | - | VERIFIED | Payment generation/version identifier from Billing.Deposit. Used in GROUP BY. |
| 8 | Status | varchar | NO | - | VERIFIED | Human-readable status name from Dictionary.PaymentStatus. Values: "Decline" (3) or "Technical" (4) - only failing statuses returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @json DepotID | Billing.Depot | Read | Joins parsed depot IDs to get DepotName and FundingTypeID. |
| Deposit analysis | Billing.Deposit | Read | Source of all deposit records. Filtered to last 24h + PaymentStatusID IN (2,3,4). |
| Status labels | Dictionary.PaymentStatus | Lookup | Resolves PaymentStatusID to Name. Only status 3 (Decline) and 4 (Technical) in results. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ProviderRecoveryServiceUser (role) | EXECUTE permission | Permission | ProviderRecoveryService monitors payment processor health and triggers alerts. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetConsecutiveDepotFailures (procedure)
├── Billing.Deposit (table) - 24h window analysis
├── Billing.Depot (table) - depot name/type lookup
└── Dictionary.PaymentStatus (table) - status labels
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source. Last 24h deposits filtered by DepotID, PaymentStatusID IN (2,3,4). |
| Billing.Depot | Table | JOIN to get DepotName and FundingTypeID for depots in @json. |
| Dictionary.PaymentStatus | Table | INNER JOIN to get status Name. Only Decline/Technical status rows returned. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ProviderRecoveryServiceUser (role) | Permission | Payment health monitoring and alert triggering |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (creates temporary indexes: `#IX_BillingDeposit` CLUSTERED on `DepotID, PaymentStatusID, PaymentDate, DepositID`).

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check consecutive failures for specific depots
```sql
EXEC Billing.GetConsecutiveDepotFailures @json = N'[
  {"DepotID": 100, "Threshold": "5"},
  {"DepotID": 200, "Threshold": "10"}
]'
-- Returns: depots where DeclinedCount (distinct failing users since last approval) > Threshold
```

### 8.2 Direct failure rate check for a depot in last 24h
```sql
SELECT PaymentStatusID, COUNT(DISTINCT CID) AS DistinctFailingUsers
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepotID = 100
  AND PaymentDate > GETUTCDATE() - 1
  AND PaymentStatusID IN (2, 3, 4)
GROUP BY PaymentStatusID
-- PaymentStatusID 2=Approved, 3=Decline, 4=Technical
```

### 8.3 Find the last approval anchor for a depot
```sql
SELECT TOP 1 DepositID, PaymentDate, CID
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepotID = 100
  AND PaymentStatusID = 2  -- Approved
  AND PaymentDate > GETUTCDATE() - 1
ORDER BY PaymentDate DESC
-- DepositIDs after this = "consecutive failures"
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetConsecutiveDepotFailures | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetConsecutiveDepotFailures.sql*
