# Trade.ReportWrongDataInCustomerMoney

> Data integrity monitor that identifies customers whose RealizedEquity in Customer.CustomerMoney deviates from the calculated actual value (Credit + mirror amounts + position amounts minus pending cashouts), then emails a list of affected users with their CID, username, and copy-provider status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; scans all customers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReportWrongDataInCustomerMoney is a financial data integrity alert that compares each customer's stored RealizedEquity (in Customer.CustomerMoney) against its calculated actual value derived from live Trade.Mirror and Trade.Position data, minus any pending cashout requests. When the deviation is >= $0.01, the customer is flagged as having wrong financial data and included in an HTML alert email sent to operations staff.

This procedure exists because Customer.CustomerMoney.RealizedEquity is a cached/computed value that must stay in sync with the underlying Mirror and Position amounts. If a system error, race condition, or data corruption causes a discrepancy, customers may see incorrect balances in their account, which has regulatory and operational implications. This procedure catches those cases proactively.

Data flow: Called by a scheduled job (no parameters). Sources: Customer.CustomerMoney (cached financials), Trade.Mirror (active mirror amounts), Trade.Position (open position amounts), History.Credit (pending cashout tracking). Five specific CIDs are excluded from checking (hardcoded exclusion list - likely internal/test accounts). If discrepancies are found, sends HTML email to Maintenance.Feature FeatureID=150003. If no discrepancies, early return. Modified 12/12/24 by Ran Ovadia to add UserName column.

---

## 2. Business Logic

### 2.1 RealizedEquity Integrity Formula

**What**: Calculates what RealizedEquity should be and compares it to what's stored in Customer.CustomerMoney.

**Columns/Parameters Involved**: `Credit`, `RealizedEquity`, `ActualMirrorAmount`, `SumOfPositions`, `PendingCashouts`

**Rules**:
- Expected RealizedEquity = Credit + ActualMirrorAmount + SumOfPositions - PendingCashouts
- Mismatch threshold: ABS(expected - stored) >= 0.01 (1 cent or more)
- ActualMirrorAmount = SUM(Trade.Mirror.Amount) per CID (all active mirrors)
- SumOfPositions = SUM(Trade.Position.Amount) per CID (all open positions)
- PendingCashouts (RwithoutA) = SUM of cashout requests (CreditTypeID=9,15) without a corresponding approval (CreditTypeID=2,8) matched by WithdrawID
- WhatIsWrong output: 'RealizedEquity ' (trailing space in source code) when mismatch >= $0.01

**Diagram**:
```
Expected = Credit + SUM(Mirror.Amount) + SUM(Position.Amount) - PendingCashouts
Actual   = CustomerMoney.RealizedEquity

ABS(Expected - Actual) >= $0.01 -> FLAG as wrong data -> EMAIL alert
```

### 2.2 Pending Cashout Calculation (CreditTypeID Logic)

**What**: Pending cashouts (requested but not yet approved) must be subtracted from RealizedEquity calculation because they modify Credit but not yet RealizedEquity.

**Columns/Parameters Involved**: `CreditTypeID`, `WithdrawID`

**Rules**:
- CreditTypeID IN (9,15) = cashout requests (pending)
- CreditTypeID IN (2,8) = cashout approvals (2=approved, 8=reversed)
- Pending = Requests LEFT JOIN Approvals WHERE approval.WithdrawID IS NULL (no matching approval found)
- These represent funds tied up in pending withdrawals that reduce the available realized equity.

### 2.3 Hardcoded Exclusion List

**What**: Five specific CIDs are always excluded from the check.

**Columns/Parameters Involved**: `CID` in @ExcludedUsers

**Rules**:
- Excluded CIDs: 10132052, 24916605, 29759462, 18031957, 24252438
- These are likely internal, test, or known-exception accounts that legitimately have non-standard balances.
- Exclusion applies at the first scan (#ActualData WHERE CM.CID NOT IN @ExcludedUsers).

### 2.4 IsCopied Flag (Copy Provider Detection)

**What**: Each flagged customer is also marked with whether they are a copy provider (have followers copying their trades).

**Columns/Parameters Involved**: `IsCopied`, `Trade.Mirror.ParentCID`

**Rules**:
- OUTER APPLY (SELECT TOP 1 1 IsCopy FROM Trade.Mirror WHERE AD.CID = M.ParentCID) -> if any mirror has this customer as ParentCID, IsCopied=1.
- IsCopied=1 means this customer has followers; discrepancies for copy providers have higher business impact.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters.

**Output: HTML email if discrepancies found. Columns in email:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | BIGINT | NO | - | CODE-BACKED | Customer ID with wrong financial data. |
| 2 | UserName | nvarchar(50) | YES | - | CODE-BACKED | Customer's username from Customer.Customer. Modified 12/12/24 by Ran Ovadia. If PlayerLevelID=4 (internal), ' (Internal)' suffix is appended. |
| 3 | ColumnsNames | VARCHAR(40) | YES | - | CODE-BACKED | Which column has wrong data. Currently only detects 'RealizedEquity ' (mismatch >= $0.01). |
| 4 | IsCopied | INT | NO | 0 | CODE-BACKED | 1=this customer has followers copying their trades (ParentCID in Trade.Mirror); 0=not a copy provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerMoney | Reader (SELECT) | Source of Credit, RealizedEquity, TotalCash to validate. |
| CID | Trade.Mirror | Reader (SELECT) | Aggregates mirror amounts per CID for expected value calculation. Also checks ParentCID for IsCopied flag. |
| CID | Trade.Position | Reader (SELECT) | Aggregates open position amounts per CID. |
| CID | Customer.Customer | Reader (SELECT) | Resolves CID to UserName and PlayerLevelID for email report. |
| CID | History.Credit | Reader (SELECT) | Reads pending cashouts (CreditTypeID 9,15) and approvals (2,8) for RwithoutA calculation. |
| FeatureID=150003 | Maintenance.Feature | Lookup | Retrieves alert email recipients. |
| (call) | msdb.dbo.sp_send_dbmail | External system call | Sends HTML alert email if discrepancies found. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Typically called by a scheduled SQL Agent job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReportWrongDataInCustomerMoney (procedure)
├── Customer.CustomerMoney (table)
├── Trade.Mirror (table)
├── Trade.Position (table)
├── Customer.Customer (table)
├── History.Credit (table)
├── Maintenance.Feature (table)
└── msdb.dbo.sp_send_dbmail (external system proc)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | Source of Credit, RealizedEquity, TotalCash - the values being validated. |
| Trade.Mirror | Table | Summed by CID for ActualMirrorAmount; checked for IsCopied (ParentCID). |
| Trade.Position | Table | Summed by CID for SumOfPositions. |
| Customer.Customer | Table | Resolves CID to UserName and PlayerLevelID for email report. |
| History.Credit | Table | Source of pending cashout requests and approvals for RwithoutA calculation. |
| Maintenance.Feature | Table | SELECT Value WHERE FeatureID=150003 for alert recipients. |
| msdb.dbo.sp_send_dbmail | System procedure | Sends HTML alert email to ops staff. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReportWrongDataInCustomerMoney_1 | Procedure | Variant of this procedure (batch item #24). |
| Trade.ReportWrongDataInCustomerMoney_New | Procedure | Updated variant (batch item #25). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Note: The procedure creates temporary CLUSTERED indexes on temp tables (#TradeMirror, #TradePosition, #ActualData, #HistoryCredit, #Disc) to optimize the multi-step calculation. These are dropped with the temp tables at session end.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the monitor (alert sent if discrepancies found)

```sql
EXEC Trade.ReportWrongDataInCustomerMoney;
-- Returns nothing if no discrepancies; sends email if deviations >= $0.01 found
```

### 8.2 Manually check a specific CID's financial data integrity

```sql
SELECT
    CM.CID,
    CM.Credit,
    CM.RealizedEquity,
    ISNULL(SUM(M.Amount), 0) AS ActualMirrorAmount,
    ISNULL(SUM(P.Amount), 0) AS SumOfPositions,
    ABS((CM.Credit + ISNULL(SUM(M.Amount), 0) + ISNULL(SUM(P.Amount), 0)) - CM.RealizedEquity) AS Deviation
FROM Customer.CustomerMoney CM WITH (NOLOCK)
LEFT JOIN Trade.Mirror M WITH (NOLOCK) ON M.CID = CM.CID
LEFT JOIN Trade.Position P WITH (NOLOCK) ON P.CID = CM.CID
WHERE CM.CID = 12345
GROUP BY CM.CID, CM.Credit, CM.RealizedEquity;
```

### 8.3 Check current alert recipients

```sql
SELECT CAST(Value AS VARCHAR(500)) AS Recipients
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 150003;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReportWrongDataInCustomerMoney | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReportWrongDataInCustomerMoney.sql*
