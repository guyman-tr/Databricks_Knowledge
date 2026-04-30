# Billing.GetRejectedWithdrawsByRequestDate

> Backoffice reporting procedure returning rejected withdrawals (CashoutStatusID=7, IsActive=1) whose original request date falls within a given range, enriched with manager name, customer tier, regulation, cashout status, withdrawal type/flow description, and external transaction ID. Sibling of GetRejectedWithdrawsByRejectDate with filter applied to request date instead of reject date.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DateFrom / @DateTo applied to BW.RequestDate; returns one row per active matched Billing.WithdrawRejects record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRejectedWithdrawsByRequestDate` is the request-date-filtered counterpart to `Billing.GetRejectedWithdrawsByRejectDate`. It returns rejected withdrawals where the customer's original withdrawal request was submitted during the specified date window, regardless of when the rejection was recorded.

The distinction is meaningful for customer-facing analysis: this procedure answers "of all withdrawals submitted during this period, which ones ended up being rejected?" - a customer experience and SLA question. The sibling answers "which rejections did the operations team issue during this period?" - an operational throughput question.

Same enrichment as the sibling: manager name, customer tier, regulation, cashout status, withdrawal type/flow description (computed as concatenated string), external transaction ID.

Updated 31 Dec 2024 (Evgeny, MIMOPSA-14499): added `FlowID`, `ExTransactionID`, and computed `WithdrawalType` column. Note: `WithdrawTypeID` was added to `GetRejectedWithdrawsByRejectDate` in the same update but is absent from this procedure's SELECT list - a minor divergence between the two siblings.

---

## 2. Business Logic

### 2.1 Date Filter on Original Request Date

**What**: The primary filter selects withdrawals whose submission timestamp falls within the caller-specified window.

**Columns/Parameters Involved**: `@DateFrom`, `@DateTo`, `BW.RequestDate`, `BWR.IsActive`, `BW.CashoutStatusID`

**Rules**:
- `BW.RequestDate BETWEEN @DateFrom AND @DateTo` - applied to the withdrawal submission timestamp, NOT the rejection date
- `BWR.IsActive = 1` - only the current active rejection per withdrawal is included
- `BW.CashoutStatusID = 7` - only rejected withdrawals
- A withdrawal submitted in March that was rejected in April would appear in a March query of this procedure but NOT in a March query of `GetRejectedWithdrawsByRejectDate`
- Useful for measuring what fraction of a cohort of withdrawal requests eventually became rejected

### 2.2 Cashout Amount, WithdrawalType, Customer Enrichment

**What**: Same calculation logic as `GetRejectedWithdrawsByRejectDate` Sections 2.2-2.4.

**Rules** (inherited, see sibling):
- `CashoutAmount = CAST(BW.Amount + ISNULL(BW.Fee, 0) AS DECIMAL(16,2))`
- `CashoutFee = CAST(BW.Fee AS DECIMAL(16,2))`
- `WithdrawalType`: `CONCAT(DWT.Description, ' - ', DF.Description)` when FlowID is non-null and DF.Description is non-empty; otherwise `DWT.Description` alone
- `Customer Level = LTRIM(RTRIM(DPLV.Name))`
- `Regulation = DCRG.Name` from BackOffice.Customer -> Dictionary.Regulation
- `Case Number = FORMAT(BWR.CaseNumber, 'd8')` (zero-padded 8-digit integer)

### 2.3 Difference from GetRejectedWithdrawsByRejectDate

**What**: Two specific divergences from the sibling procedure:

| Dimension | GetRejectedWithdrawsByRequestDate | GetRejectedWithdrawsByRejectDate |
|-----------|----------------------------------|----------------------------------|
| Date filter column | `BW.RequestDate` | `BWR.RejectDate` |
| WithdrawTypeID column | NOT included in SELECT | Included as `[WithdrawTypeID]` |
| All other columns | Identical | Identical |
| JOIN structure | Identical | Identical |

The missing `WithdrawTypeID` column in this procedure appears to be an oversight in the MIMOPSA-14499 update (31 Dec 2024), which added the column to the sibling but did not apply the same change here.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of the request date window (inclusive). Applied to `Billing.Withdraw.RequestDate`. Typically passed as day start (00:00:00) for daily reports. |
| 2 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of the request date window (inclusive). Applied to `Billing.Withdraw.RequestDate`. Typically passed as day end (23:59:59) for daily reports. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Request Date | DATETIME | YES | - | CODE-BACKED | UTC timestamp when the customer submitted the withdrawal request (`Billing.Withdraw.RequestDate`). The primary filter column for this procedure. |
| 4 | Reject Date | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the rejection was recorded (`Billing.WithdrawRejects.RejectDate`). May fall outside the filter window. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer identifier. |
| 6 | Withdraw ID | INT | NO | - | CODE-BACKED | PK of the withdrawal request (`Billing.Withdraw.WithdrawID`). |
| 7 | Reason | NVARCHAR | NO | - | CODE-BACKED | Human-readable rejection reason from `Dictionary.CashoutRejectReason.RejectReasonName` (e.g., "Alternative Payment method", "Missing Documents", "Risk"). |
| 8 | BackOffice Withdraw Reason | NVARCHAR | YES | - | CODE-BACKED | Operator-selected cashout reason from `Dictionary.CashoutReason.Name` (via `BW.CashoutReasonID`). NULL if no cashout reason recorded. |
| 9 | Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text manager notes from `Billing.WithdrawRejects.Comment`. |
| 10 | Case Number | NVARCHAR | YES | - | CODE-BACKED | CRM case number zero-padded to 8 digits: `FORMAT(CaseNumber, 'd8')`. NULL until linked via `Billing.FollowupEdit`. |
| 11 | Case Date | DATETIME | YES | - | CODE-BACKED | Date of external support case creation. NULL until set by `Billing.FollowupEdit`. |
| 12 | Updated By | NVARCHAR | NO | - | CODE-BACKED | Full name of the rejecting manager: `FirstName + ' ' + LastName`. "0 0" for automated rejections (ManagerID=0). |
| 13 | Cashout Status | NVARCHAR | NO | - | CODE-BACKED | Status name from `Dictionary.CashoutStatus.Name`. All rows show "Rejected" (filter: CashoutStatusID=7). |
| 14 | Approved | BIT/TINYINT | YES | - | CODE-BACKED | `Billing.Withdraw.Approved` flag. Whether the withdrawal was approved before rejection. |
| 15 | Follow Up Date | DATETIME | NO | - | CODE-BACKED | Operations team follow-up deadline from `Billing.WithdrawRejects.FollowupDate`. |
| 16 | RejectID | INT | NO | - | CODE-BACKED | PK of the active rejection record in `Billing.WithdrawRejects`. |
| 17 | CashoutAmount | DECIMAL(16,2) | YES | - | CODE-BACKED | Total withdrawal amount including fee: `CAST(Amount + ISNULL(Fee, 0) AS DECIMAL(16,2))`. In `CurrencyID` currency. |
| 18 | CashoutFee | DECIMAL(16,2) | YES | - | CODE-BACKED | Platform fee component: `CAST(Fee AS DECIMAL(16,2))`. NULL if no fee charged. |
| 19 | Currency | NVARCHAR | NO | - | CODE-BACKED | Withdrawal currency abbreviation from `Dictionary.Currency` (e.g., "USD", "EUR") via `BW.CurrencyID`. |
| 20 | Customer Level | NVARCHAR | YES | - | CODE-BACKED | VIP tier name, whitespace-trimmed: `LTRIM(RTRIM(Dictionary.PlayerLevel.Name))` (e.g., "Bronze", "Silver"). |
| 21 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Regulatory framework name from `Dictionary.Regulation` via `BackOffice.Customer.RegulationID`. NULL if no BackOffice customer record. |
| 22 | FundingID (Request Only) | INT | YES | - | CODE-BACKED | Payment instrument originally requested by the customer (`BW.FundingID`). "Request Only" - the actual payout may use a different funding instrument. FK to `Billing.Funding`. |
| 23 | AMOP Currency | NVARCHAR | YES | - | CODE-BACKED | Account denomination currency abbreviation from `Dictionary.Currency` via `BW.AccountCurrencyID`. May differ from withdrawal currency. NULL if AccountCurrencyID not set. |
| 24 | FlowID | INT | YES | - | CODE-BACKED | Flow sub-type identifier (`BW.FlowID`). FK to `Dictionary.Flow`. NULL for standard withdrawals. Added MIMOPSA-14499 (Dec 2024). |
| 25 | ExTransactionID | NVARCHAR/INT | YES | - | CODE-BACKED | External transaction identifier for cross-system reconciliation (`BW.ExTransactionID`). Added MIMOPSA-14499 (Dec 2024). |
| 26 | WithdrawalType | NVARCHAR | YES | - | CODE-BACKED | Computed withdrawal type description: `CONCAT(DWT.Description, ' - ', DF.Description)` when FlowID is set and DF.Description is non-empty; else `DWT.Description` alone. Added MIMOPSA-14499 (Dec 2024). Note: `WithdrawTypeID` numeric column is absent from this procedure (present in sibling `GetRejectedWithdrawsByRejectDate`). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BWR.WithdrawID | Billing.Withdraw | JOIN (primary) | Core withdrawal request fields |
| BW.WithdrawID | Billing.WithdrawRejects | JOIN | Active rejection record |
| BWR.ManagerID | BackOffice.Manager | INNER JOIN | Manager name |
| BW.CID | Customer.Customer | INNER JOIN | PlayerLevelID for tier |
| BW.CID | BackOffice.Customer | LEFT JOIN | RegulationID |
| BW.WithdrawTypeID | Dictionary.WithdrawType | LEFT JOIN | Withdrawal type description |
| BWR.RejectReasonID | Dictionary.CashoutRejectReason | INNER JOIN | Reject reason name |
| BW.CashoutStatusID | Dictionary.CashoutStatus | INNER JOIN | Status name |
| BW.CashoutReasonID | Dictionary.CashoutReason | LEFT JOIN | BackOffice cashout reason name |
| BW.CurrencyID | Dictionary.Currency (DCUR) | INNER JOIN | Withdrawal currency |
| CCST.PlayerLevelID | Dictionary.PlayerLevel | LEFT JOIN | Tier name |
| BCST.RegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name |
| BW.AccountCurrencyID | Dictionary.Currency (DCUR2) | LEFT JOIN | Account currency (AMOP) |
| BW.FlowID | Dictionary.Flow | LEFT JOIN | Flow description for WithdrawalType |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Backoffice UI / operations tooling | @DateFrom, @DateTo | EXEC | Request-cohort rejection analysis reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRejectedWithdrawsByRequestDate (procedure)
+-- Billing.Withdraw (table)
+-- Billing.WithdrawRejects (table)
+-- BackOffice.Manager (table, cross-schema)
+-- Customer.Customer (table, cross-schema)
+-- BackOffice.Customer (table, cross-schema)
+-- Dictionary.WithdrawType (table)
+-- Dictionary.CashoutRejectReason (table)
+-- Dictionary.CashoutStatus (table)
+-- Dictionary.CashoutReason (table)
+-- Dictionary.Currency x2 (table)
+-- Dictionary.PlayerLevel (table)
+-- Dictionary.Regulation (table)
+-- Dictionary.Flow (table)
```

(Same dependency set as `Billing.GetRejectedWithdrawsByRejectDate`.)

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Primary source; RequestDate is the filter column |
| Billing.WithdrawRejects | Table | Active rejection record |
| BackOffice.Manager | Table | INNER JOIN for manager name |
| Customer.Customer | Table | INNER JOIN for PlayerLevelID |
| BackOffice.Customer | Table | LEFT JOIN for RegulationID |
| Dictionary.WithdrawType | Table | LEFT JOIN for withdrawal type description |
| Dictionary.CashoutRejectReason | Table | INNER JOIN for reject reason name |
| Dictionary.CashoutStatus | Table | INNER JOIN for status name |
| Dictionary.CashoutReason | Table | LEFT JOIN for cashout reason name |
| Dictionary.Currency | Table | INNER JOIN x2 (CurrencyID + AccountCurrencyID) |
| Dictionary.PlayerLevel | Table | LEFT JOIN for tier name |
| Dictionary.Regulation | Table | LEFT JOIN for regulation name |
| Dictionary.Flow | Table | LEFT JOIN for flow description in WithdrawalType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Backoffice reporting / operations UI | External | Rejection analysis cohorted by original request date |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsActive=1 filter | Design | Only current active rejection per withdrawal; superseded rejections excluded |
| CashoutStatusID=7 filter | Business rule | Only Rejected withdrawals |
| Missing WithdrawTypeID | DDL gap | Not included in SELECT list; present in sibling GetRejectedWithdrawsByRejectDate. Likely an oversight in MIMOPSA-14499 update (Dec 2024) |
| NOLOCK on most tables | Concurrency | Same NOLOCK pattern as sibling; Dictionary.WithdrawType, Dictionary.Regulation, Dictionary.Flow lack explicit NOLOCK hints |
| INNER JOIN Customer.Customer | Integrity | Orphaned withdrawals with no customer record are excluded |

---

## 8. Sample Queries

### 8.1 Get all rejections for withdrawals submitted this month
```sql
EXEC Billing.GetRejectedWithdrawsByRequestDate
    @DateFrom = '2026-03-01 00:00:00',
    @DateTo   = '2026-03-31 23:59:59';
```

### 8.2 Compare request-date vs reject-date views for a period
```sql
-- Request-date view: "what requests in Q1 got rejected?"
EXEC Billing.GetRejectedWithdrawsByRequestDate
    @DateFrom = '2026-01-01', @DateTo = '2026-03-31';

-- Reject-date view: "what did operations reject in Q1?"
EXEC Billing.GetRejectedWithdrawsByRejectDate
    @DateFrom = '2026-01-01', @DateTo = '2026-03-31';
-- Note: results may overlap but are not identical - a Q4 request rejected in Q1 appears
-- in the second query but not the first.
```

### 8.3 Manual equivalent - rejected withdrawals by request month
```sql
SELECT
    YEAR(BW.RequestDate) AS ReqYear,
    MONTH(BW.RequestDate) AS ReqMonth,
    COUNT(*) AS RejectedCount,
    SUM(BW.Amount) AS TotalAmount
FROM Billing.Withdraw BW WITH (NOLOCK)
JOIN Billing.WithdrawRejects BWR WITH (NOLOCK) ON BWR.WithdrawID = BW.WithdrawID
WHERE BW.CashoutStatusID = 7
  AND BWR.IsActive = 1
GROUP BY YEAR(BW.RequestDate), MONTH(BW.RequestDate)
ORDER BY ReqYear DESC, ReqMonth DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPSA-14499 (referenced in DDL comment, Evgeny, 31/12/2024) | Jira | Added FlowID, ExTransactionID, and WithdrawalType to both GetRejectedWithdraws procedures; WithdrawTypeID added to RejectDate sibling but not this procedure (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRejectedWithdrawsByRequestDate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRejectedWithdrawsByRequestDate.sql*
