# dbo.tblaff_PaymentHistory

> Central payment ledger recording every affiliate commission payout batch, with detailed per-tier breakdowns across all 8 commission types, multi-level approval workflow, and currency support.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | PaymentID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 5 active |

---

## 1. Business Meaning

dbo.tblaff_PaymentHistory is the central payment ledger of the affiliate system. Each row represents a complete commission payout batch for one affiliate for one payment period. The table stores detailed per-tier breakdowns across all 8 commission types (CPA, Sales, Registrations, Leads, Clicks, CopyTraders, FirstPositions, eCost), a multi-level approval workflow (Manager -> VP Marketing -> Finance -> Finance Manager), and the final payment amount.

Without this table, the affiliate system would have no historical record of what was paid, when, by whom, and through what approval chain. It is the audit backbone for all affiliate payments.

Data is created by the `PaymentHistory_Insert` procedure when payment batches are generated. Multiple payment-related procedures (GetPayments, GetPaymentById, GetPaymentsForAffiliate, ReadECostHistoryRecords) read from this table. The table has FKs to Dictionary.PaymentRowStatus (payment processing state: 1=Pending, 2=Partially Approved, 4=Approved, 8=Processed, 16=Rejected) and dbo.tblaff_eCostHistory. Triggers enforce AffiliateID references tblaff_Affiliates. Contains ~18.8K payment records with 99.9% in Pending status (1) and 4 in Processed status (8).

---

## 2. Business Logic

### 2.1 Multi-Level Approval Workflow

**What**: Payments progress through up to 4 approval levels before processing.

**Columns/Parameters Involved**: `ManagerApproved`, `VPMarketingApproved`, `FinanceApproved`, `FinanceManagerApproved`, `Approved`, `PaymentRowStatusID`

**Rules**:
- `ManagerApproved`: First-level approval by account manager
- `VPMarketingApproved`: Second-level by VP Marketing (required for payments above VPMarketingAmount threshold from tblaff_Administrative4)
- `FinanceApproved`: Third-level by finance team
- `FinanceManagerApproved`: Fourth-level by finance manager (required for payments above FinanceManagerAmount threshold)
- `Approved`: Final aggregate approval flag
- `PaymentRowStatusID`: State machine - 1=Pending, 2=Partially Approved, 4=Approved, 8=Processed, 16=Rejected (see Dictionary.PaymentRowStatus)
- `RequestedBy` / `ApprovedBy`: Track the users who initiated and approved the payment

**Diagram**:
```
[PaymentHistory_Insert] --> Status=1 (Pending)
      |
      v
[Manager Approves] --> ManagerApproved=1
      |
      v
[VP Marketing Approves (if amount > threshold)] --> VPMarketingApproved=1
      |
      v
[Finance Approves] --> FinanceApproved=1
      |
      v
[Finance Manager Approves (if amount > threshold)] --> FinanceManagerApproved=1
      |
      v
[Approved=1, Status=4] --> [Processed, Status=8]
```

### 2.2 Per-Tier Commission Breakdown

**What**: Each payment row contains detailed counts and commission amounts for all 5 tiers across 8 commission types.

**Columns/Parameters Involved**: `Tier1CPA` through `Tier5CPA`, `Tier1CPACommission` through `Tier5CPACommission`, and equivalent for Sales, Registrations, Leads, Clicks, CopyTraders, FirstPositions, plus `Tier1eCostCommission`

**Rules**:
- 5 tiers x 8 commission types = 80 tier columns (40 counts + 40 amounts)
- Counts: How many events of each type at each tier (e.g., Tier1CPA = number of CPA events for the direct affiliate)
- Commissions: Total commission amount for each type at each tier
- `PaymentAmount` = sum of all tier commissions + PaymentAdjustment
- `PaymentAdjustment`: Manual adjustment (positive or negative) applied by finance

### 2.3 Payment Currency and eCost Linkage

**What**: Payments can be made in different currencies and linked to eCost history.

**Columns/Parameters Involved**: `CurrencyID`, `AmountInCurrency`, `eCostHistoryID`, `PaymentDetailsID`

**Rules**:
- `CurrencyID` defaults to 1 (USD) - references Dictionary.Currency
- `AmountInCurrency` stores the payment amount in the affiliate's preferred currency
- `eCostHistoryID` links to tblaff_eCostHistory for eCost reconciliation (explicit FK)
- `PaymentDetailsID` links to the affiliate's payment method
- `PaymentDetailsOnApprove` captures a snapshot of payment details at approval time

---

## 3. Data Overview

| PaymentID | AffiliateID | PaymentAmount | PaymentRowStatusID | PaymentPeriod | Approved | Meaning |
|---|---|---|---|---|---|---|
| 20263 | 61597 | 600 | 1 (Pending) | 2026-02-01 | false | $600 payment batch for affiliate 61597 for Feb 2026 period. All approval levels are false - awaiting manager review. |
| 20262 | 61596 | 200 | 1 (Pending) | 2026-02-01 | false | $200 payment for affiliate 61596. Same period, same pending status. CurrencyID=1 (USD). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentID | int IDENTITY | NO | - | VERIFIED | Auto-incrementing primary key. NOT FOR REPLICATION. Referenced by all _Commissions tables' PaymentID column and tblaff_Files.PaymentID. |
| 2 | AffiliateID | int | YES | 0 | VERIFIED | The affiliate receiving this payment. Trigger enforces RI against tblaff_Affiliates. |
| 3 | PaymentDate | datetime | YES | getdate() | VERIFIED | When the payment record was created. |
| 4 | PaymentAmount | float | YES | 0 | VERIFIED | Total payment amount: sum of all tier commissions + adjustment. |
| 5 | PaymentAdjustment | float | YES | - | CODE-BACKED | Manual adjustment amount applied by finance. Positive = bonus, negative = deduction. |
| 6 | PaymentDescription | nvarchar(20) | YES | - | NAME-INFERRED | Short description/label for this payment. |
| 7-16 | Tier1CPA through Tier5CPA | int | NO | 0 | VERIFIED | Count of CPA events per tier included in this payment batch. |
| 17-26 | Tier1CPACommission through Tier5CPACommission | float | NO | 0 | VERIFIED | CPA commission amount per tier. |
| 27-36 | Tier1Sales through Tier5Sales | int | NO | 0 | VERIFIED | Count of sales events per tier. |
| 37-46 | Tier1SalesCommission through Tier5SalesCommission | float | NO | 0 | VERIFIED | Sales commission amount per tier. |
| 47-56 | Tier1Registrations through Tier5Registrations | int | NO | 0 | VERIFIED | Count of registration events per tier. |
| 57-66 | Tier1RegistrationsCommission through Tier5RegistrationsCommission | float | NO | 0 | VERIFIED | Registration commission amount per tier. |
| 67-76 | Tier1Leads through Tier5Leads, Tier1LeadsCommission through Tier5LeadsCommission | int/float | NO | 0 | VERIFIED | Lead counts and commission amounts per tier. |
| 77-86 | Tier1Clicks through Tier5Clicks, Tier1ClicksCommission through Tier5ClicksCommission | int/float | NO | 0 | VERIFIED | Click counts and commission amounts per tier. |
| 87 | PaymentRange | nvarchar(25) | YES | - | NAME-INFERRED | Date range label for this payment period. |
| 88 | Comment | nvarchar(max) | YES | - | CODE-BACKED | Free-text comment from finance/approver. |
| 89 | ManagerApproved | bit | NO | 0 | VERIFIED | First-level approval by account manager. |
| 90 | Approved | bit | NO | 0 | VERIFIED | Final aggregate approval flag. |
| 91 | ApprovalDate | datetime | YES | - | CODE-BACKED | When the final approval was granted. |
| 92 | RequestedBy | int | NO | 1 | CODE-BACKED | Admin user ID who created/requested this payment. |
| 93 | ApprovedBy | int | NO | 1 | CODE-BACKED | Admin user ID who gave final approval. |
| 94 | VPMarketingApproved | bit | NO | 0 | VERIFIED | Second-level VP Marketing approval. |
| 95 | CurrencyID | int | NO | 1 | VERIFIED | Payment currency. Default 1 = USD. References Dictionary.Currency. |
| 96 | LastApprovalDate | datetime | YES | - | CODE-BACKED | Timestamp of the most recent approval step. |
| 97 | Tier1eCostCommission | float | NO | 0 | VERIFIED | eCost commission amount (Tier 1 only - no multi-tier for eCost in this summary). |
| 98 | PaymentDetailsID | bigint | NO | 1 | CODE-BACKED | References the affiliate's payment method/bank details. |
| 99 | PaymentDetailsOnApprove | varchar(max) | YES | - | CODE-BACKED | Snapshot of payment details captured at approval time for audit. |
| 100 | PaymentMethodOnApprove | int | YES | 0 | CODE-BACKED | Payment method code captured at approval time. |
| 101-110 | Tier1CopyTraders through Tier5CopyTraders, Tier1CopyTradersCommission through Tier5CopyTradersCommission | int/float | NO | 0 | VERIFIED | CopyTrader event counts and commission amounts per tier. |
| 111-120 | Tier1FirstPositions through Tier5FirstPositions, Tier1FirstPositionsCommission through Tier5FirstPositionsCommission | int/float | NO | 0 | VERIFIED | FirstPosition event counts and commission amounts per tier. |
| 121 | PaymentRowStatusID | int | NO | 1 | VERIFIED | Payment processing status. FK to Dictionary.PaymentRowStatus: 1=Pending, 2=Partially Approved, 4=Approved, 8=Processed, 16=Rejected. See [Payment Row Status](../../_glossary.md#payment-row-status). |
| 122 | eCostHistoryID | int | YES | - | VERIFIED | References tblaff_eCostHistory.eCostHistoryID (explicit FK). Links this payment to an eCost reconciliation record. NULL when no eCost linkage. |
| 123 | FinanceApproved | bit | NO | 0 | VERIFIED | Third-level finance team approval. |
| 124 | PaymentPeriod | date | YES | - | VERIFIED | The payment period this batch covers (first day of month). E.g., 2026-02-01 = February 2026 commissions. |
| 125 | PaymentGroupCode | uniqueidentifier | YES | - | CODE-BACKED | GUID grouping related payment rows into a single batch for bulk processing. |
| 126 | AmountInCurrency | decimal(18,2) | YES | - | CODE-BACKED | Payment amount converted to the affiliate's preferred currency (per CurrencyID). |
| 127 | ReferenceNumber | nvarchar(50) | YES | - | CODE-BACKED | External payment reference number (bank transfer reference, wire confirmation, etc.). |
| 128 | RowVersion | timestamp | NO | - | VERIFIED | Optimistic concurrency control. Auto-incrementing binary value used to detect concurrent updates. |
| 129 | FinanceManagerApproved | bit | NO | 0 | VERIFIED | Fourth-level finance manager approval for high-value payments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentRowStatusID | Dictionary.PaymentRowStatus | FK (explicit) | Payment processing state (Pending/Approved/Processed/Rejected) |
| eCostHistoryID | dbo.tblaff_eCostHistory | FK (explicit) | eCost reconciliation linkage |
| AffiliateID | dbo.tblaff_Affiliates | Implicit (trigger) | The affiliate being paid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Files | PaymentID | Implicit | Payment document attachments |
| dbo.PaymentHistory_Insert | INSERT | Procedure (WRITER) | Creates payment records |
| dbo.GetPayments | SELECT | Procedure (READER) | Lists payments with status |
| dbo.GetPaymentById | SELECT | Procedure (READER) | Gets single payment details |
| dbo.GetPaymentsForAffiliate | SELECT | Procedure (READER) | Affiliate-specific payments |
| dbo.ReadECostHistoryRecords | SELECT | Procedure (READER) | eCost history with payment |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Files | Table | Stores payment document attachments |
| dbo.PaymentHistory_Insert | Stored Procedure | WRITER |
| dbo.GetPayments | Stored Procedure | READER |
| dbo.GetPaymentById | Stored Procedure | READER |
| dbo.GetPaymentsForAffiliate | Stored Procedure | READER |
| dbo.ReadECostHistoryRecords | Stored Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_PaymentHistory_PK | NC PK | PaymentID ASC | - | - | Active (fill 90%) |
| Idx_tblaff_PaymentHistory | CLUSTERED | PaymentPeriod, PaymentID | - | - | Active (fill 90%, PAGE) |
| AffiliateID | NC | AffiliateID | - | - | Active (fill 90%) |
| IX_eCostHistoryID | NC | eCostHistoryID DESC | - | - | Active (fill 90%) |
| PaymentDate | NC | PaymentDate | - | - | Active (fill 90%) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PaymentRowStatus | FOREIGN KEY | PaymentRowStatusID -> Dictionary.PaymentRowStatus |
| FK_eCostHistory | FOREIGN KEY | eCostHistoryID -> dbo.tblaff_eCostHistory |
| DF_tblaff_PaymentHistory_PaymentRowStatusID | DEFAULT | 1 - Pending status |
| DF_tblaff_PaymentHistory_CurrencyID_1 | DEFAULT | 1 - USD |
| DF_tblaff_PaymentHistory_Approved | DEFAULT | 0 - Not approved |
| DF_tblaff_PaymentHistory_ManagerApproved_1 | DEFAULT | 0 |
| DF_tblaff_PaymentHistory_VPMarketingApproved | DEFAULT | 0 |
| DF_tblaff_PaymentHistory_FinanceApproved | DEFAULT | 0 |
| DF_tblaff_PaymentHistory_FinanceManagerApproved | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Pending payments awaiting approval
```sql
SELECT PaymentID, AffiliateID, PaymentAmount, PaymentPeriod,
       ManagerApproved, VPMarketingApproved, FinanceApproved, FinanceManagerApproved
FROM dbo.tblaff_PaymentHistory WITH (NOLOCK)
WHERE PaymentRowStatusID = 1
ORDER BY PaymentAmount DESC
```

### 8.2 Payment with status name
```sql
SELECT ph.PaymentID, ph.AffiliateID, ph.PaymentAmount, ph.PaymentPeriod,
       prs.StatusName, ph.ApprovalDate
FROM dbo.tblaff_PaymentHistory ph WITH (NOLOCK)
JOIN Dictionary.PaymentRowStatus prs WITH (NOLOCK) ON ph.PaymentRowStatusID = prs.PaymentRowStatusID
ORDER BY ph.PaymentID DESC
```

### 8.3 Commission breakdown for a payment
```sql
SELECT PaymentID,
       Tier1CPACommission + Tier2CPACommission + Tier3CPACommission + Tier4CPACommission + Tier5CPACommission AS TotalCPA,
       Tier1SalesCommission + Tier2SalesCommission + Tier3SalesCommission + Tier4SalesCommission + Tier5SalesCommission AS TotalSales,
       Tier1RegistrationsCommission + Tier2RegistrationsCommission + Tier3RegistrationsCommission + Tier4RegistrationsCommission + Tier5RegistrationsCommission AS TotalRegistrations,
       Tier1eCostCommission AS TotaleCost,
       PaymentAmount, PaymentAdjustment
FROM dbo.tblaff_PaymentHistory WITH (NOLOCK)
WHERE PaymentID = @PaymentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 9.2/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 18 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_PaymentHistory | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_PaymentHistory.sql*
