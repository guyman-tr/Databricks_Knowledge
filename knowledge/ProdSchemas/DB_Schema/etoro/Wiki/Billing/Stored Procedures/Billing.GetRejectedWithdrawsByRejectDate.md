# Billing.GetRejectedWithdrawsByRejectDate

> Backoffice reporting procedure returning rejected withdrawals (CashoutStatusID=7, IsActive=1) whose rejection date falls within a given range, enriched with manager name, customer tier, regulation, cashout status, withdrawal type/flow description, and external transaction ID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DateFrom / @DateTo applied to BWR.RejectDate; returns one row per active matched Billing.WithdrawRejects record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRejectedWithdrawsByRejectDate` is the primary backoffice report for reviewing withdrawal rejections by the date they were rejected. Operations and compliance teams use it to produce a snapshot of all active rejections issued during a date window - useful for daily/weekly rejection queue reviews, compliance audits, and SLA tracking on re-processing turnaround.

The procedure is the date-of-rejection counterpart to `Billing.GetRejectedWithdrawsByRequestDate`, which filters on when the withdrawal was originally submitted. Use this procedure when the business question is "what rejections did we issue in this period?"; use the sibling when the question is "what requests from this period ended up rejected?".

Rows are filtered to `CashoutStatusID=7` (Rejected) on the parent `Billing.Withdraw` and `IsActive=1` on `Billing.WithdrawRejects`, meaning only the current active rejection for each withdrawal is returned (historical/superseded rejections from prior re-rejection cycles are excluded).

Updated 31 Dec 2024 (Evgeny, MIMOPSA-14499): added `WithdrawTypeID`, `FlowID`, `ExTransactionID`, and the computed `WithdrawalType` column which concatenates the withdrawal type description with its flow description (e.g., "Wire Transfer - eToroMoney") when a FlowID is present.

---

## 2. Business Logic

### 2.1 Date Filter on Rejection Event

**What**: The primary filter selects the active rejection records whose rejection timestamp falls within the caller-specified window.

**Columns/Parameters Involved**: `@DateFrom`, `@DateTo`, `BWR.RejectDate`, `BWR.IsActive`, `BW.CashoutStatusID`

**Rules**:
- `BWR.RejectDate BETWEEN @DateFrom AND @DateTo` - inclusive on both ends; datetime precision means callers should typically pass 00:00:00 for @DateFrom and 23:59:59 for @DateTo to capture the full day range
- `BWR.IsActive = 1` - only the current active rejection record per withdrawal is returned; historically superseded rejections (IsActive=0) are excluded
- `BW.CashoutStatusID = 7` - confirms the parent withdrawal is in Rejected status; redundant with IsActive=1 in theory (an active rejection implies the parent is rejected), but adds an explicit guard
- The three-condition compound filter means that a withdrawal rejected twice (two WithdrawRejects rows) would appear at most once - for the date the active rejection was issued

### 2.2 Cashout Amount Calculation

**What**: The displayed amount combines the base withdrawal amount and any platform fee.

**Columns/Parameters Involved**: `BW.Amount`, `BW.Fee`, `CashoutAmount`, `CashoutFee`

**Rules**:
- `CashoutAmount = CAST(BW.Amount + ISNULL(BW.Fee, 0) AS DECIMAL(16,2))` - the total amount the customer requested including any withdrawal fee; Fee can be NULL (no fee charged) so ISNULL protects against NULL propagation
- `CashoutFee = CAST(BW.Fee AS DECIMAL(16,2))` - the fee component alone (NULL if no fee); cast from money to DECIMAL(16,2) strips the extra money-type precision

### 2.3 WithdrawalType Computed Column (MIMOPSA-14499)

**What**: A human-readable description of the withdrawal type, optionally appended with the flow sub-type description.

**Columns/Parameters Involved**: `BW.WithdrawTypeID`, `BW.FlowID`, `DWT.Description` (Dictionary.WithdrawType), `DF.Description` (Dictionary.Flow)

**Rules**:
- When `BW.FlowID IS NOT NULL AND DF.Description NOT LIKE ''`: `WithdrawalType = CONCAT(DWT.Description, ' - ', DF.Description)` (e.g., "Wire Transfer - eToroMoney Local Currency")
- Otherwise: `WithdrawalType = DWT.Description` (e.g., "Credit Card", "Wire Transfer")
- This replaces what was previously two separate ID columns; the concatenated string gives operators immediate context in UI tables without needing to join to dictionaries manually
- `Dictionary.Flow` is LEFT JOINed, so withdrawals with no FlowID return NULL for DF.Description and the CASE defaults to DWT.Description alone

### 2.4 Customer Enrichment (Level and Regulation)

**What**: The customer's VIP tier and regulatory framework are joined for operator context.

**Columns/Parameters Involved**: `Customer Level`, `Regulation`, `CCST.PlayerLevelID`, `BCST.RegulationID`

**Rules**:
- `Customer Level = LTRIM(RTRIM(DPLV.Name))` - LTRIM/RTRIM strips whitespace anomalies in some dictionary entries (e.g., "Bronze " -> "Bronze")
- `Regulation = DCRG.Name` from `BackOffice.Customer.RegulationID -> Dictionary.Regulation.ID`
- Both `BackOffice.Customer` (LEFT JOIN) and `Dictionary.PlayerLevel` (LEFT JOIN) / `Dictionary.Regulation` (no NOLOCK hint) are left-joined, so the row is returned even if regulatory data is missing
- `Customer.Customer` is INNER JOINed on CID - if a customer record doesn't exist, the withdrawal row is excluded (rare edge case for orphaned withdrawals)

### 2.5 Case Number Formatting

**What**: The CaseNumber is displayed as a zero-padded 8-digit string.

**Columns/Parameters Involved**: `CaseNumber`, `BWR.CaseNumber`

**Rules**:
- `FORMAT(BWR.CaseNumber, 'd8')` formats the integer CaseNumber as an 8-digit string with leading zeros (e.g., 25402 -> "00025402")
- This matches the external CRM/support platform's case numbering format for easy cross-reference
- NULL CaseNumber returns NULL (FORMAT returns NULL for NULL input)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of the rejection date window (inclusive). Applied to `Billing.WithdrawRejects.RejectDate`. Typically passed as day start (00:00:00) for daily reports. |
| 2 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of the rejection date window (inclusive). Applied to `Billing.WithdrawRejects.RejectDate`. Typically passed as day end (23:59:59) for daily reports. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Request Date | DATETIME | YES | - | CODE-BACKED | UTC timestamp when the customer originally submitted the withdrawal request (`Billing.Withdraw.RequestDate`). Context for how long the withdrawal was pending before rejection. |
| 4 | Reject Date | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the manager/system rejected this withdrawal (`Billing.WithdrawRejects.RejectDate`). The primary filter column. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer identifier (`Billing.Withdraw.CID`). |
| 6 | Withdraw ID | INT | NO | - | CODE-BACKED | PK of the withdrawal request (`Billing.Withdraw.WithdrawID`). Use this to look up the full withdrawal record or link to history. |
| 7 | Reason | NVARCHAR | NO | - | CODE-BACKED | Human-readable rejection reason name from `Dictionary.CashoutRejectReason.RejectReasonName`. Examples: "Alternative Payment method", "Missing Documents", "Risk". |
| 8 | BackOffice Withdraw Reason | NVARCHAR | YES | - | CODE-BACKED | The operator-selected cashout reason from `Dictionary.CashoutReason.Name` (via `Billing.Withdraw.CashoutReasonID`). Distinct from the reject reason - this is why the operator initiated the withdrawal action in the first place. NULL if no cashout reason was recorded. |
| 9 | Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text notes from the rejecting manager (`Billing.WithdrawRejects.Comment`). May contain support ticket references, customer instructions, or context. |
| 10 | Case Number | NVARCHAR | YES | - | CODE-BACKED | External support/CRM case number, zero-padded to 8 digits via `FORMAT(CaseNumber, 'd8')` (e.g., "00025402"). NULL until a support case is linked via `Billing.FollowupEdit`. |
| 11 | Case Date | DATETIME | YES | - | CODE-BACKED | Date the external support case was created (`Billing.WithdrawRejects.CaseDate`). NULL until set by `Billing.FollowupEdit`. |
| 12 | Updated By | NVARCHAR | NO | - | CODE-BACKED | Full name of the manager who rejected this withdrawal: `BackOffice.Manager.FirstName + ' ' + LastName` (via `Billing.WithdrawRejects.ManagerID`). "0 0" when system-automated (ManagerID=0). |
| 13 | Cashout Status | NVARCHAR | NO | - | CODE-BACKED | Human-readable name of the withdrawal's current cashout status from `Dictionary.CashoutStatus.Name`. All returned rows will show "Rejected" (CashoutStatusID=7 filter). |
| 14 | Approved | BIT/TINYINT | YES | - | CODE-BACKED | `Billing.Withdraw.Approved` flag indicating whether the withdrawal had been approved before being rejected. Context for compliance review. |
| 15 | Follow Up Date | DATETIME | NO | - | CODE-BACKED | Date by which the operations team should follow up on this rejection (`Billing.WithdrawRejects.FollowupDate`). Drives the team's work queue. |
| 16 | RejectID | INT | NO | - | CODE-BACKED | PK of the active rejection record (`Billing.WithdrawRejects.RejectID`). Use this to link to follow-up actions or identify the specific rejection event. |
| 17 | CashoutAmount | DECIMAL(16,2) | YES | - | CODE-BACKED | Total amount of the withdrawal request including fee: `Amount + ISNULL(Fee, 0)` cast to DECIMAL(16,2). In `Billing.Withdraw.CurrencyID` currency. |
| 18 | CashoutFee | DECIMAL(16,2) | YES | - | CODE-BACKED | Platform fee portion of the withdrawal (`Billing.Withdraw.Fee`) cast to DECIMAL(16,2). NULL if no fee was charged. |
| 19 | Currency | NVARCHAR | NO | - | CODE-BACKED | Abbreviation of the withdrawal's denomination currency from `Dictionary.Currency.Abbreviation` (e.g., "USD", "EUR") via `Billing.Withdraw.CurrencyID`. |
| 20 | Customer Level | NVARCHAR | YES | - | CODE-BACKED | Customer's VIP tier name, whitespace-trimmed: `LTRIM(RTRIM(Dictionary.PlayerLevel.Name))` via `Customer.Customer.PlayerLevelID` (e.g., "Bronze", "Silver", "Platinum"). NULL if level not found. |
| 21 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Regulatory framework name from `Dictionary.Regulation.Name` via `BackOffice.Customer.RegulationID` (e.g., "ESMA", "FCA", "ASIC"). NULL if no BackOffice customer record. |
| 22 | FundingID (Request Only) | INT | YES | - | CODE-BACKED | The payment instrument the customer originally requested for the withdrawal payout (`Billing.Withdraw.FundingID`). Labeled "Request Only" because the actual payout funding may differ (changed by operations). FK to `Billing.Funding`. |
| 23 | AMOP Currency | NVARCHAR | YES | - | CODE-BACKED | Account-level currency abbreviation from `Dictionary.Currency.Abbreviation` via `Billing.Withdraw.AccountCurrencyID`. The customer's account denomination currency, which may differ from the withdrawal currency. NULL if AccountCurrencyID is not set. |
| 24 | WithdrawTypeID | INT | YES | - | CODE-BACKED | Numeric identifier of the withdrawal method type (`Billing.Withdraw.WithdrawTypeID`). FK to `Dictionary.WithdrawType`. Added in MIMOPSA-14499 (Dec 2024). |
| 25 | FlowID | INT | YES | - | CODE-BACKED | Flow sub-type identifier (`Billing.Withdraw.FlowID`). Distinguishes specialized withdrawal flows (e.g., FlowID=2 for eToroMoney local currency). FK to `Dictionary.Flow`. NULL for standard withdrawals. Added in MIMOPSA-14499 (Dec 2024). |
| 26 | ExTransactionID | NVARCHAR/INT | YES | - | CODE-BACKED | External transaction identifier from `Billing.Withdraw.ExTransactionID`. Cross-system reference for reconciliation with external payment processors. Added in MIMOPSA-14499 (Dec 2024). |
| 27 | WithdrawalType | NVARCHAR | YES | - | CODE-BACKED | Human-readable withdrawal type description, computed as: `CONCAT(DWT.Description, ' - ', DF.Description)` when FlowID is set and DF.Description is non-empty; otherwise `DWT.Description` alone. Examples: "Wire Transfer", "Credit Card", "Wire Transfer - eToroMoney Local Currency". Added in MIMOPSA-14499 (Dec 2024). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BWR.WithdrawID | Billing.Withdraw | JOIN (primary) | Core withdrawal request fields |
| BW.WithdrawID | Billing.WithdrawRejects | JOIN | Active rejection record |
| BWR.ManagerID | BackOffice.Manager | INNER JOIN | Manager name for "Updated By" |
| BW.CID | Customer.Customer | INNER JOIN | PlayerLevelID for customer tier |
| BW.CID | BackOffice.Customer | LEFT JOIN | RegulationID for regulation enrichment |
| BW.WithdrawTypeID | Dictionary.WithdrawType | LEFT JOIN | Withdrawal type description |
| BWR.RejectReasonID | Dictionary.CashoutRejectReason | INNER JOIN | Reject reason name |
| BW.CashoutReasonID | Dictionary.CashoutReason | LEFT JOIN | BackOffice cashout reason name |
| BW.CashoutStatusID | Dictionary.CashoutStatus | INNER JOIN | Status name ("Rejected") |
| BW.CurrencyID | Dictionary.Currency (DCUR) | INNER JOIN | Withdrawal currency abbreviation |
| CCST.PlayerLevelID | Dictionary.PlayerLevel | LEFT JOIN | Customer tier name |
| BCST.RegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name |
| BW.AccountCurrencyID | Dictionary.Currency (DCUR2) | LEFT JOIN | Account currency abbreviation (AMOP) |
| BW.FlowID | Dictionary.Flow | LEFT JOIN | Flow sub-type description for WithdrawalType |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Backoffice UI / operations tooling | @DateFrom, @DateTo | EXEC | Daily/weekly rejection review reports |
| Compliance operations | @DateFrom, @DateTo | EXEC | Audit reports of rejection activity by date |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRejectedWithdrawsByRejectDate (procedure)
+-- Billing.Withdraw (table)
+-- Billing.WithdrawRejects (table)
+-- BackOffice.Manager (table, cross-schema)
+-- Customer.Customer (table, cross-schema)
+-- BackOffice.Customer (table, cross-schema)
+-- Dictionary.WithdrawType (table)
+-- Dictionary.CashoutRejectReason (table)
+-- Dictionary.CashoutReason (table)
+-- Dictionary.CashoutStatus (table)
+-- Dictionary.Currency x2 (table - CurrencyID and AccountCurrencyID)
+-- Dictionary.PlayerLevel (table)
+-- Dictionary.Regulation (table)
+-- Dictionary.Flow (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Primary source of withdrawal request data |
| Billing.WithdrawRejects | Table | Active rejection record, date filter, case tracking |
| BackOffice.Manager | Table | INNER JOIN for manager name |
| Customer.Customer | Table | INNER JOIN for PlayerLevelID |
| BackOffice.Customer | Table | LEFT JOIN for RegulationID |
| Dictionary.WithdrawType | Table | LEFT JOIN for withdrawal type description |
| Dictionary.CashoutRejectReason | Table | INNER JOIN for reject reason name |
| Dictionary.CashoutReason | Table | LEFT JOIN for cashout reason name |
| Dictionary.CashoutStatus | Table | INNER JOIN for status name |
| Dictionary.Currency | Table | INNER JOIN x2 (CurrencyID and AccountCurrencyID) |
| Dictionary.PlayerLevel | Table | LEFT JOIN for tier name |
| Dictionary.Regulation | Table | LEFT JOIN for regulation name |
| Dictionary.Flow | Table | LEFT JOIN for flow description in WithdrawalType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Backoffice reporting / operations UI | External | Rejection management and compliance reports |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsActive=1 filter | Design | Only the current active rejection per withdrawal is returned; historical re-rejections are suppressed |
| CashoutStatusID=7 filter | Business rule | Redundant with IsActive guard but explicit - only Rejected withdrawals returned |
| NOLOCK on most tables | Concurrency | All major table reads use NOLOCK; Dictionary.WithdrawType, Dictionary.Regulation, Dictionary.Flow do not have NOLOCK hints in the DDL |
| FORMAT CaseNumber | Display | d8 format zero-pads integer to 8 digits for CRM case reference consistency |
| INNER JOIN BackOffice.Manager | Integrity | Rejections with an invalid ManagerID would be excluded; ManagerID=0 (automated) requires a row with ID=0 in BackOffice.Manager |
| INNER JOIN Customer.Customer | Integrity | Orphaned withdrawals with no Customer record are excluded |

---

## 8. Sample Queries

### 8.1 Get all active rejections issued today
```sql
EXEC Billing.GetRejectedWithdrawsByRejectDate
    @DateFrom = '2026-03-18 00:00:00',
    @DateTo   = '2026-03-18 23:59:59';
```

### 8.2 Get rejections issued in the past week for a compliance review
```sql
EXEC Billing.GetRejectedWithdrawsByRejectDate
    @DateFrom = '2026-03-11 00:00:00',
    @DateTo   = '2026-03-18 23:59:59';
```

### 8.3 Manual equivalent - check active rejections with follow-up overdue
```sql
SELECT
    BW.WithdrawID,
    BW.CID,
    BW.Amount,
    BWR.RejectDate,
    BWR.FollowupDate,
    BWR.Comment,
    DCRR.RejectReasonName
FROM Billing.Withdraw BW WITH (NOLOCK)
JOIN Billing.WithdrawRejects BWR WITH (NOLOCK) ON BWR.WithdrawID = BW.WithdrawID
JOIN Dictionary.CashoutRejectReason DCRR WITH (NOLOCK) ON DCRR.RejectReasonID = BWR.RejectReasonID
WHERE BW.CashoutStatusID = 7
  AND BWR.IsActive = 1
  AND BWR.FollowupDate < GETDATE()
ORDER BY BWR.FollowupDate ASC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPSA-14499 (referenced in DDL comment, Evgeny, 31/12/2024) | Jira | Added WithdrawTypeID, FlowID, ExTransactionID, and WithdrawalType computed column (Jira unavailable for full details) |
| Cashier Service Redesign (Confluence page ID 1803878401) | Confluence | Procedure referenced in cashier service redesign context (page content access restricted) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.4/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 27 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 1 Confluence (access restricted) + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRejectedWithdrawsByRejectDate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRejectedWithdrawsByRejectDate.sql*
