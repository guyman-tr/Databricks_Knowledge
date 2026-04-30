# Billing.FinancialDiscrepancy

> Financial discrepancy audit log for the billing domain; captures detected inconsistencies (duplicated deposits/cashouts, wrong exchange rates, balance mismatches, 3DS unauthorized transactions, etc.) with type, direction, financial gap amount, and description.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY PK CLUSTERED |
| **Partition** | MAIN filegroup (PAGE compression) |
| **Indexes** | 1 (PK on ID) |

---

## 1. Business Meaning

`Billing.FinancialDiscrepancy` is the audit table for financial inconsistencies detected in billing operations. When automated reconciliation jobs or manual investigations identify a discrepancy - such as a duplicate deposit, a wrong exchange rate applied during processing, a 3DS unauthorized charge, or a customer balance mismatch - a record is inserted here to log the incident.

The table currently holds 0 rows (possibly this is a non-production environment or the table is written to by application code not in the SSDT repo). No stored procedures in the Billing schema reference this table - it is written to and read from entirely by application-layer code.

The discrepancy types (Dictionary.FinancialDiscrepancyType) cover 17 categories:
- **Deposit errors**: Duplicated Deposit, EtoroMoney Transfer Deposit Discrepancy, 3DS Not Authorized Transaction
- **Cashout errors**: Duplicated Cashouts, Wrong Withdraw Request Fees
- **Exchange rate errors**: Wrong Base Exchange Rate during Deposit/Cashout Processing, Override Exchange Rate or PIPS, Mismatch Deposit/Cashout PIPS
- **Fee errors**: Wrong Conversion Fees, Wrong Redeem Conversion Fees
- **Balance errors**: Update Customer Balance Discrepancy, Customer Balance Recovery, Duplicated FTD
- **Security**: Credit Card Data Leakage
- **Test**: Test-2 (ID=17)

The direction (Dictionary.FinancialDiscrepancyDirection) currently has only 1 value: "Missing funds on eToro Account Balance" - indicating the gap direction from eToro's perspective.

---

## 2. Business Logic

### 2.1 Discrepancy Type Classification

**What**: Each record is categorized by DiscrepancyTypeID to enable filtering and reporting by incident type.

**Columns/Parameters Involved**: `DiscrepancyTypeID`, `FinancialGap`, `HasFinancialImpact`

**Rules**:
```
DiscrepancyTypeID -> Dictionary.FinancialDiscrepancyType:
  1  = Duplicated Deposit              (double-charge or duplicate deposit record)
  2  = Update Customer Balance Discrepancy (balance update went wrong)
  3  = Customer Balance Recovery       (recovery/correction of a balance issue)
  4  = Duplicated Cashouts             (cashout processed twice)
  5  = Duplicated FTD                  (first-time deposit flag set incorrectly/twice)
  6  = 3DS Not Authorized Transaction  (3DS auth required but transaction processed without)
  7  = Wrong Base Exchange Rate during Deposit Processing
  8  = Wrong Base Exchange Rate during Cashout Processing
  9  = Override Exchange Rate or PIPS during Processing
  10 = Mismatch Deposit PIPS & Business Settings
  11 = Mismatch Cashout PIPS & Business Settings
  12 = Wrong Conversion Fees
  13 = EtoroMoney Transfer Deposit Discrepancy
  14 = Wrong Redeem Conversion Fees
  15 = Wrong Withdraw Request Fees     (typo in source: "Wirhdraw")
  16 = Credit Card Data Leakage
  17 = Test - 2 (test entry)
```

### 2.2 Financial Impact Assessment

**What**: HasFinancialImpact and FinancialGap together quantify whether the discrepancy resulted in an actual monetary loss/gain.

**Columns/Parameters Involved**: `HasFinancialImpact`, `FinancialGap`, `FinancialDiscrepancyDirectionID`

**Rules**:
```
HasFinancialImpact = 1: The discrepancy caused a real financial difference
  -> FinancialGap (decimal 18,8): The magnitude of the gap in USD
  -> FinancialDiscrepancyDirectionID: Direction of the gap
       1 = "Missing funds on eToro Account Balance"
         (eToro's books show less than expected)

HasFinancialImpact = 0: The discrepancy was detected but no monetary gap resulted
  -> FinancialGap may be NULL
  -> FinancialDiscrepancyDirectionID may be NULL
```

### 2.3 Operation Reference

**What**: OperationID links each discrepancy to the specific billing operation that caused it.

**Columns/Parameters Involved**: `OperationID`, `CreditTypeID`

**Rules**:
- OperationID is an integer reference to the originating operation (DepositID, CashoutID, etc.) - the type is disambiguated by DiscrepancyTypeID or CreditTypeID.
- CreditTypeID identifies whether the operation was a deposit, cashout, or other credit type.
- No FK constraints on OperationID or CreditTypeID - they are implicit references.

---

## 3. Data Overview

Table is empty (0 rows). No sample data available.

When active, a row would represent: "DiscrepancyTypeID=1 (Duplicated Deposit) for OperationID=9876543 (DepositID), FinancialGap=150.00000000 USD, FinancialDiscrepancyDirectionID=1 (Missing funds on eToro Account Balance), detected on 2025-01-15."

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | auto | VERIFIED | Surrogate PK. Auto-incremented discrepancy record identifier. |
| 2 | DiscrepancyTypeID | int | NO | - | VERIFIED | Type of financial discrepancy. FK to Dictionary.FinancialDiscrepancyType(ID). 17 types covering duplicate transactions, wrong exchange rates, balance mismatches, conversion fee errors, 3DS issues, and data leakage. |
| 3 | CreditTypeID | int | NO | - | CODE-BACKED | Credit type of the originating operation (e.g., deposit, cashout, redeem). Likely references Dictionary.FundingType or a similar credit type table. No FK constraint. Used to disambiguate the type of OperationID. |
| 4 | OperationID | int | NO | - | CODE-BACKED | ID of the specific billing operation that triggered the discrepancy (e.g., DepositID, CashoutID, RedeemID). Implicit reference - no FK constraint. Combined with CreditTypeID, identifies the exact transaction that caused the discrepancy. |
| 5 | HasFinancialImpact | bit | NO | - | VERIFIED | Whether this discrepancy resulted in a real monetary gap. 1=financial impact detected (FinancialGap will be set), 0=discrepancy detected but no monetary consequence. |
| 6 | FinancialGap | decimal(18,8) | YES | - | VERIFIED | The monetary size of the discrepancy in USD. High precision (8 decimal places) to capture fractional amounts from currency conversion. NULL when HasFinancialImpact=0. |
| 7 | FinancialDiscrepancyDirectionID | int | YES | - | VERIFIED | Direction of the financial gap. FK to Dictionary.FinancialDiscrepancyDirection(ID). Currently only 1 value: "Missing funds on eToro Account Balance". NULL when HasFinancialImpact=0. |
| 8 | Description | nvarchar(max) | NO | - | CODE-BACKED | Free-text description of the discrepancy. Written by the detection system or manual investigator. Contains diagnostic details about what was expected vs. what was found. Stored in TEXTIMAGE_ON [MAIN] due to max length. |
| 9 | CreatedDate | datetime | NO | - | VERIFIED | When this discrepancy record was created (detection timestamp). Set by the inserting process. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DiscrepancyTypeID | Dictionary.FinancialDiscrepancyType | FK (explicit) | Category of financial discrepancy |
| FinancialDiscrepancyDirectionID | Dictionary.FinancialDiscrepancyDirection | FK (explicit) | Direction of the financial gap |
| OperationID | Billing.Deposit / Billing.Cashout / etc. | Implicit | The operation that caused the discrepancy (type determined by DiscrepancyTypeID/CreditTypeID) |

### 5.2 Referenced By (other objects point to this)

No stored procedures in the SSDT repo reference this table. Written and read by application-layer code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FinancialDiscrepancy (table)
|- Dictionary.FinancialDiscrepancyType (table)      [FK: DiscrepancyTypeID]
|- Dictionary.FinancialDiscrepancyDirection (table) [FK: FinancialDiscrepancyDirectionID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FinancialDiscrepancyType | Table | FK target - discrepancy classification (17 types) |
| Dictionary.FinancialDiscrepancyDirection | Table | FK target - direction of financial gap (1 type: Missing funds) |

### 6.2 Objects That Depend On This

No stored procedure dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FinancialDiscrepancy | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR 95, DATA_COMPRESSION=PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FinancialDiscrepancy | PRIMARY KEY CLUSTERED | ID - unique discrepancy record |
| FK_FinancialDiscrepancy_DiscrepancyTypeID | FOREIGN KEY | DiscrepancyTypeID must exist in Dictionary.FinancialDiscrepancyType |
| FK_FinancialDiscrepancy_FinancialDiscrepancyDirectionID | FOREIGN KEY | FinancialDiscrepancyDirectionID must exist in Dictionary.FinancialDiscrepancyDirection |

### 7.3 Storage Notes

- PAGE compression on the PK - reduces storage for the Description (nvarchar max) field.
- TEXTIMAGE_ON [MAIN] - LOB (nvarchar max) columns stored on MAIN filegroup.

---

## 8. Sample Queries

### 8.1 Get all discrepancies by type
```sql
SELECT  FD.ID,
        FDT.Name            AS DiscrepancyType,
        FD.OperationID,
        FD.HasFinancialImpact,
        FD.FinancialGap,
        FD.CreatedDate,
        LEFT(FD.Description, 200)   AS DescriptionPreview
FROM    Billing.FinancialDiscrepancy FD WITH (NOLOCK)
INNER JOIN Dictionary.FinancialDiscrepancyType FDT WITH (NOLOCK)
        ON FD.DiscrepancyTypeID = FDT.ID
ORDER BY FD.CreatedDate DESC;
```

### 8.2 Financial impact summary by discrepancy type
```sql
SELECT  FDT.Name            AS DiscrepancyType,
        COUNT(*)            AS IncidentCount,
        SUM(FD.FinancialGap)    AS TotalGap
FROM    Billing.FinancialDiscrepancy FD WITH (NOLOCK)
INNER JOIN Dictionary.FinancialDiscrepancyType FDT WITH (NOLOCK)
        ON FD.DiscrepancyTypeID = FDT.ID
WHERE   FD.HasFinancialImpact = 1
GROUP BY FDT.Name
ORDER BY TotalGap DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FinancialDiscrepancy | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FinancialDiscrepancy.sql*
