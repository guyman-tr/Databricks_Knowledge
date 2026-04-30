# dbo.tblaff_eCostHistory

> Tracks marketing expense (eCost) requests and adjustments per affiliate, recording the financial agreements for marketing cost reimbursements and commission plan adjustments.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | eCostHistoryID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This table records marketing expense (eCost) agreements between the platform and affiliates. An eCost record represents either a marketing cost reimbursement arrangement (the platform agrees to pay the affiliate for marketing expenses) or a commission plan adjustment.

With 13,487 records, each row captures a financial agreement: the total amount, the currency, the date range it covers, who requested it, and who last updated it. These records serve as the parent for individual eCost events in dbo.tblaff_eCost - each eCostHistory record can spawn many granular eCost event rows.

TotalAmount can be negative (e.g., -46.74), indicating a clawback or reversal of a previous marketing expense agreement. The CurrencyID links to Dictionary.Currency via an explicit FK, supporting multi-currency expense tracking (though most records use CurrencyID=1/USD).

---

## 2. Business Logic

### 2.1 eCost vs Commission Plan Adjustment

**What**: Records are classified as either marketing expense reimbursements or commission plan adjustments.

**Columns/Parameters Involved**: `IsCommissionPlanAdjustment`, `TotalAmount`, `MonthlyAmount`

**Rules**:
- IsCommissionPlanAdjustment=0 (default, most records): Standard marketing expense reimbursement
- IsCommissionPlanAdjustment=1: A commission plan adjustment rather than a marketing expense
- TotalAmount: The total agreed amount for the entire period
- MonthlyAmount: The monthly installment amount (NULL when paid as lump sum)
- DateRangeStart/DateRangeEnd define the period the expense covers

### 2.2 Approval Workflow

**What**: eCost requests go through a request and approval workflow.

**Columns/Parameters Involved**: `RequestorID`, `RequestDate`, `LastUpdaterID`, `LastUpdateDate`

**Rules**:
- RequestorID: The admin user who created the expense request
- RequestDate: When the request was submitted
- LastUpdaterID: The admin user who last modified (approved/adjusted) the request
- LastUpdateDate: When the last modification occurred
- The difference between RequestDate and LastUpdateDate indicates approval processing time

---

## 3. Data Overview

| eCostHistoryID | AffiliateID | TotalAmount | CurrencyID | IsCommissionPlanAdjustment | Meaning |
|---|---|---|---|---|---|
| 15774 | 31342 | 806.00 | 1 (USD) | No | Standard marketing expense reimbursement of $806 for affiliate 31342 |
| 15773 | 40571 | 664.77 | 1 (USD) | No | Marketing expense of $664.77 for affiliate 40571 |
| 15772 | 40047 | -46.74 | 1 (USD) | No | Clawback/reversal of $46.74 - a previous marketing expense was partially reversed |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | eCostHistoryID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key. Unique identifier for each eCost agreement/request. NOT FOR REPLICATION. Referenced by dbo.tblaff_PaymentHistory.eCostHistoryID via explicit FK and by dbo.tblaff_eCost.eCostHistoryID (implicit). |
| 2 | AffiliateID | int | YES | - | VERIFIED | The affiliate receiving the marketing expense reimbursement. References dbo.tblaff_Affiliates.AffiliateID (implicit). |
| 3 | RequestDate | datetime | YES | - | VERIFIED | When the eCost request was submitted. |
| 4 | TotalAmount | float | YES | - | VERIFIED | Total agreed marketing expense amount. Can be negative for clawbacks/reversals. Denominated in the currency specified by CurrencyID. |
| 5 | Description | nvarchar(max) | YES | - | CODE-BACKED | Free-text description of the marketing expense or adjustment. Explains what the expense covers. |
| 6 | DateRangeStart | datetime | YES | - | CODE-BACKED | Start date of the period this expense covers. |
| 7 | DateRangeEnd | datetime | YES | - | CODE-BACKED | End date of the period this expense covers. |
| 8 | RequestorID | int | YES | - | VERIFIED | Admin user who created the request. References dbo.tblaff_User.UserID (implicit). |
| 9 | LastUpdateDate | datetime | YES | - | CODE-BACKED | When the record was last modified (approved, adjusted, etc.). |
| 10 | LastUpdaterID | int | YES | - | CODE-BACKED | Admin user who last modified the record. References dbo.tblaff_User.UserID (implicit). |
| 11 | MonthlyAmount | float | YES | - | VERIFIED | Monthly installment amount when the expense is paid in installments rather than lump sum. NULL = lump sum payment. |
| 12 | CurrencyID | int | NO | 1 | VERIFIED | Currency of the expense amount. FK to Dictionary.Currency: 1=USD (default), 2=EUR, 3=GBP, 4=CAD, 5=AUD, 38=RMB. |
| 13 | Comments | nvarchar(max) | YES | - | CODE-BACKED | Additional notes or comments about the expense. Separate from Description for workflow annotations. |
| 14 | IsCommissionPlanAdjustment | bit | NO | 0 | VERIFIED | Classifies the record type. 0=standard marketing expense reimbursement (default), 1=commission plan adjustment. |
| 15 | InvoiceNumber | varchar(50) | YES | - | CODE-BACKED | Invoice reference number for the marketing expense. Used for financial reconciliation with the affiliate's submitted invoices. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Explicit FK | Currency denomination of the expense amount |
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | The affiliate receiving the expense reimbursement |
| RequestorID | dbo.tblaff_User | Implicit FK | Admin who created the request |
| LastUpdaterID | dbo.tblaff_User | Implicit FK | Admin who last modified the request |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_PaymentHistory | eCostHistoryID | Explicit FK | Payment records linked to this expense agreement |
| dbo.tblaff_eCost | eCostHistoryID | Implicit FK | Individual eCost event records spawned from this agreement |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.tblaff_eCostHistory (table)
+-- Dictionary.Currency (table) [explicit FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | Explicit FK on CurrencyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentHistory | Table | Explicit FK on eCostHistoryID |
| dbo.tblaff_eCost | Table | Implicit FK on eCostHistoryID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK__tblaff_eCostHist__1BC8ED34 | CLUSTERED PK | eCostHistoryID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_CurrencyID | FOREIGN KEY | CurrencyID -> Dictionary.Currency(CurrencyID) |
| DF_tblaff_eCostHistory_CurrencyID | DEFAULT | CurrencyID defaults to 1 (USD) |
| DF_tblaff_eCostHistory_IsCommissionPlanAdjustment | DEFAULT | IsCommissionPlanAdjustment defaults to 0 (standard expense) |

---

## 8. Sample Queries

### 8.1 Get recent eCost agreements
```sql
SELECT TOP 10 eCostHistoryID, AffiliateID, TotalAmount, c.CurrencyName, RequestDate, IsCommissionPlanAdjustment
FROM dbo.tblaff_eCostHistory ech WITH (NOLOCK)
JOIN Dictionary.Currency c WITH (NOLOCK) ON ech.CurrencyID = c.CurrencyID
ORDER BY RequestDate DESC
```

### 8.2 Total eCost by affiliate
```sql
SELECT ech.AffiliateID, a.LoginName, SUM(ech.TotalAmount) AS TotalECost, COUNT(*) AS Agreements
FROM dbo.tblaff_eCostHistory ech WITH (NOLOCK)
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON ech.AffiliateID = a.AffiliateID
GROUP BY ech.AffiliateID, a.LoginName
ORDER BY TotalECost DESC
```

### 8.3 Find commission plan adjustments
```sql
SELECT eCostHistoryID, AffiliateID, TotalAmount, Description, RequestDate
FROM dbo.tblaff_eCostHistory WITH (NOLOCK)
WHERE IsCommissionPlanAdjustment = 1
ORDER BY RequestDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_eCostHistory | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_eCostHistory.sql*
