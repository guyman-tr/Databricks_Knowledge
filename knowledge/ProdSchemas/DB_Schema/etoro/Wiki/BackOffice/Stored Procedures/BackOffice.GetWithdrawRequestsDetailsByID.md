# BackOffice.GetWithdrawRequestsDetailsByID

> Returns full processing details for all funding attempts on a single withdrawal by ID - an enhanced single-record variant of GetWithdrawRequestsDetails with remark history, merchant lookup, and birthdate enrichment.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID (required); returns all WithdrawToFunding rows for that withdrawal, ordered by ModificationDate DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawRequestsDetailsByID` retrieves the complete processing history for a specific withdrawal, identified by `@WithdrawID`. It is the single-record counterpart to `GetWithdrawRequestsDetails` (which queries by date range). The typical use case is a Back Office user opening a specific withdrawal to investigate its processing status, view the remark history, check MID routing, and see all funding attempts.

Compared to `GetWithdrawRequestsDetails`, this procedure adds three capabilities: (1) the `Remark` column from `History.WithdrawToFundingAction` showing the most recent processing remark for each attempt; (2) a more advanced MID resolution via the `BackOffice.GetMerchantDetails` function with fallback to the depot-based lookup; (3) a FundingTypeID=35 path that appends customer birthdate to payment details (used by certain regulated payment methods requiring age verification).

Data flow: Back Office user opens a withdrawal record -> this SP is called with the WithdrawID -> returns all processing attempts with full detail for investigation or approval workflow.

---

## 2. Business Logic

### 2.1 PaymentDetails Field Construction

**What**: Same CASE logic as `GetWithdrawRequestsDetails` plus an additional case for FundingTypeID=35 (regulated payment requiring birthdate).

**Columns/Parameters Involved**: `PaymentDetails`, `FundingTypeID`, `CashoutTypeID`, `FundingData` (XML), `WithdrawData` (XML), `BirthDate`

**Rules**:
- `FundingTypeID = 1` (Credit Card): NULL (Brand column used)
- `FundingTypeID = 2` (Bank Wire): PaymentDetails + BSBNumber + ClientAddress from XML
- `FundingTypeID = 3, CashoutTypeID = 1` (PayPal new money): Email + PayerID from FundingData XML (MIMOPS-5237)
- `FundingTypeID = 3, CashoutTypeID = 2` (PayPal refund): PayerAsString from Deposit XML
- `FundingTypeID = 10` (WebMoney/eWallet): AccountID + PurseID from FundingData XML
- `FundingTypeID = 33` (wallet): GCID + PlatformAccountID + CurrencyBalanceID from WithdrawData XML
- `FundingTypeID = 35` (regulated): PaymentDetails + "; BirthDate: " + customer birth date formatted dd/MM/yyyy. Uses `Customer.Customer.BirthDate` for age verification display.
- All other types: Raw `Billing.Funding.PaymentDetails`

### 2.2 MID Resolution (Enhanced vs GetWithdrawRequestsDetails)

**What**: Uses `BackOffice.GetMerchantDetails` function as primary MID source, falling back to depot-based regulation lookup only when the function returns NULL.

**Columns/Parameters Involved**: `MID Name`, `MID`, `CashoutTypeID`, `DepotID`, `MerchantAccountID`

**Rules**:
- Primary: `BackOffice.GetMerchantDetails(BWTF.MerchantAccountID, 1)` for MID Name; `GetMerchantDetails(BWTF.MerchantAccountID, 0)` for MID value. Returns NULL if `MerchantAccountID` is not set.
- Fallback (when GetMerchantDetails returns NULL): Depot-based lookup (same as GetWithdrawRequestsDetails) for DepotID 18/92 and 35-44.
- Additional (DepotID 92, MIMOPS-2614): checks `Billing.MapMerchantCodeToMid` for a merchant code-to-MID mapping by currency, using `ISNULL(Description, ISNULL(MID, Value))` priority.

### 2.3 Remark History

**What**: Each processing attempt may have remarks entered by Back Office managers. The most recent remark is surfaced here.

**Columns/Parameters Involved**: `Remark`

**Rules**:
- Subquery on `History.WithdrawToFundingAction` filtered by `BW2F_ID = BWTF.ID` (the processing record ID)
- `TOP 1 ... ORDER BY ModificationDate DESC` returns the most recent remark
- NULL if no remarks have been entered for this processing attempt

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | The withdrawal identifier to retrieve processing details for. Filters `Billing.WithdrawToFunding.WithdrawID`. All funding attempts for this withdrawal are returned. |

**Output columns (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Net. Cashout Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | Net amount disbursed on this funding attempt (`Billing.WithdrawToFunding.Amount`), formatted to 2 decimal places. |
| 2 | Exchange Rate | DECIMAL(16,4) | YES | - | CODE-BACKED | Exchange rate applied to convert the withdrawal amount to the processing currency (`Billing.WithdrawToFunding.ExchangeRate`), 4 decimal places. |
| 3 | ProcessCurrencyID | INT | NO | - | CODE-BACKED | Raw currency ID of the processing currency (`Billing.WithdrawToFunding.ProcessCurrencyID`). Unlike `GetWithdrawRequestsDetails`, the name is not resolved here - caller resolves via Dictionary.Currency. |
| 4 | Status | NVARCHAR | NO | - | CODE-BACKED | Human-readable cashout status of this processing attempt (`Dictionary.CashoutStatus.Name` on `WithdrawToFunding.CashoutStatusID`). |
| 5 | Remark | NVARCHAR | YES | - | CODE-BACKED | Most recent remark from `History.WithdrawToFundingAction` for this processing record (TOP 1 by ModificationDate DESC). Entered by Back Office managers during processing review. NULL if no remarks recorded. |
| 6 | FundingTypeID | INT | NO | - | CODE-BACKED | Raw funding type ID from `Billing.Funding.FundingTypeID`. Identifies the payment method (1=Credit Card, 2=Wire, 3=PayPal, 10=WebMoney, 33=wallet, 35=regulated). Unlike `GetWithdrawRequestsDetails`, the name is not resolved. |
| 7 | Request Time | DATETIME | NO | - | CODE-BACKED | Creation timestamp of the funding processing record (`Billing.WithdrawToFunding.CreationDate`). |
| 8 | Brand | NVARCHAR | YES | - | CODE-BACKED | Card brand name (`Dictionary.CardType.Name`) parsed from FundingData XML. Only populated for FundingTypeID=1 (credit card). NULL otherwise. |
| 9 | Depot | NVARCHAR | YES | - | CODE-BACKED | Name of the payment depot/gateway (`Billing.Depot.Name`). NULL if no depot assigned. |
| 10 | PaymentDetails | VARCHAR(MAX) | YES | - | CODE-BACKED | Payment method-specific identifiers for reconciliation. Same logic as GetWithdrawRequestsDetails plus FundingTypeID=35 (appends customer BirthDate). See Section 2.1. |
| 11 | FundingID | INT | NO | - | CODE-BACKED | Primary key of the linked `Billing.Funding` record for this processing attempt. |
| 12 | IsVerified | VARCHAR(3) | NO | - | CODE-BACKED | Whether the customer-funding link is verified: "Yes" if `Billing.CustomerToFunding.IsVerified = 1`, "No" otherwise. |
| 13 | Status Modification Time | DATETIME | NO | - | CODE-BACKED | Timestamp of last status change on this processing record (`Billing.WithdrawToFunding.ModificationDate`). Used for ORDER BY DESC. |
| 14 | Processor Value Date | DATETIME | YES | - | CODE-BACKED | Value date assigned by the payment processor (`Billing.WithdrawToFunding.ProcessorValueDate`). |
| 15 | Processed By | NVARCHAR | YES | - | CODE-BACKED | Full name of the Back Office manager who processed this record. NULL for automated processing. |
| 16 | WithdrawID | INT | NO | - | CODE-BACKED | The parent withdrawal ID (`Billing.WithdrawToFunding.WithdrawID`). Echoes the input parameter. |
| 17 | Withdraw Processing ID | INT | NO | - | CODE-BACKED | Primary key of this specific funding processing record (`Billing.WithdrawToFunding.ID`). |
| 18 | ParentStatusID | INT | NO | - | CODE-BACKED | Cashout status of the parent `Billing.Withdraw` record. Allows detecting discrepancy between parent and child statuses. |
| 19 | CashoutStatusID | INT | NO | - | CODE-BACKED | Cashout status of this specific processing record (`Billing.WithdrawToFunding.CashoutStatusID`). |
| 20 | MID Name | NVARCHAR | YES | - | CODE-BACKED | Merchant ID regulation/agreement name. Primary source: `BackOffice.GetMerchantDetails(MerchantAccountID, 1)`. Fallback: depot-based regulation lookup. NULL if neither resolves. See Section 2.2. |
| 21 | MID | NVARCHAR | YES | - | CODE-BACKED | Merchant ID value for transaction reconciliation. Primary: `BackOffice.GetMerchantDetails(MerchantAccountID, 0)`. Fallback: depot-based lookup. NULL if unresolved. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.WithdrawToFunding | Filter | All processing records for the given withdrawal |
| @WithdrawID | Billing.Withdraw | JOIN | Parent withdrawal for CID and parent status |
| WithdrawToFunding.FundingID | Billing.Funding | JOIN | Payment method data and XML fields |
| WithdrawToFunding.CashoutStatusID | Dictionary.CashoutStatus | Lookup | Status name |
| WithdrawToFunding.DepotID | Billing.Depot | Lookup (LEFT) | Depot name |
| WithdrawToFunding.ManagerID | BackOffice.Manager | Lookup (LEFT) | Manager name |
| Funding.FundingData (XML) | Dictionary.CardType | Lookup (LEFT) | Card brand for type=1 |
| WithdrawToFunding.DepositID | Billing.Deposit | Lookup (LEFT) | PayPal refund and MID data |
| WithdrawToFunding.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | Lookup (LEFT) | MID fallback for depot 18/92 |
| BPMS1.RegulationID | Dictionary.Regulation | Lookup (LEFT) | MID Name fallback |
| Deposit.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | Lookup (LEFT) | MID fallback for depots 35-44 |
| BPMS2.RegulationID | Dictionary.Regulation | Lookup (LEFT) | MID Name fallback |
| BPMS1.Value + Deposit.CurrencyID | Billing.MapMerchantCodeToMid | Lookup (LEFT) | Enhanced MID mapping via merchant code (MIMOPS-2614) |
| WithdrawToFunding.FundingID + Withdraw.CID | Billing.CustomerToFunding | Lookup (LEFT) | IsVerified flag |
| WithdrawToFunding.ID | History.WithdrawToFundingAction | Subquery | Most recent remark |
| Withdraw.CID | Customer.Customer | LEFT JOIN | BirthDate for FundingTypeID=35 |
| MerchantAccountID | BackOffice.GetMerchantDetails | Function call | Primary MID resolution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawRequestsDetailsByID (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Billing.Funding (table)
├── Billing.Depot (table)
├── Billing.Deposit (table)
├── Billing.ProtocolMIDSettings (table) [x2]
├── Billing.MapMerchantCodeToMid (table)
├── Billing.CustomerToFunding (table)
├── Dictionary.CashoutStatus (table)
├── Dictionary.CardType (table)
├── Dictionary.Regulation (table) [x2]
├── BackOffice.Manager (table)
├── Customer.Customer (table)
├── History.WithdrawToFundingAction (table)
└── BackOffice.GetMerchantDetails (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FROM (main); all processing records for @WithdrawID |
| Billing.Withdraw | Table | INNER JOIN on WithdrawID; CID + parent CashoutStatusID |
| Billing.Funding | Table | INNER JOIN on FundingID; FundingTypeID, PaymentDetails, FundingData XML |
| Billing.Depot | Table | LEFT JOIN on DepotID; depot name |
| Billing.Deposit | Table | LEFT JOIN on DepositID; PayPal refund path + MID for depots 35-44 |
| Billing.ProtocolMIDSettings | Table | LEFT JOIN x2; MID value fallback |
| Billing.MapMerchantCodeToMid | Table | LEFT JOIN; enhanced MID mapping by merchant code and currency (MIMOPS-2614) |
| Billing.CustomerToFunding | Table | LEFT JOIN; IsVerified flag |
| Dictionary.CashoutStatus | Table | JOIN on CashoutStatusID; status name |
| Dictionary.CardType | Table | LEFT JOIN via XML; card brand |
| Dictionary.Regulation | Table | LEFT JOIN x2 via ProtocolMIDSettings; MID Name fallback |
| BackOffice.Manager | Table | LEFT JOIN on ManagerID; processor name |
| Customer.Customer | Table | LEFT JOIN on CID; BirthDate for FundingTypeID=35 |
| History.WithdrawToFundingAction | Table | Subquery (TOP 1 by ModificationDate DESC); latest remark |
| BackOffice.GetMerchantDetails | Function | Called x2 with (MerchantAccountID, flag); primary MID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WITH (NOLOCK) | Query hint | All tables use NOLOCK - read-only investigation query |
| OPTION (RECOMPILE) | Query hint | Forces per-execution plan compilation; WithdrawID is always specific so this prevents stale plan reuse |
| ORDER BY ModificationDate DESC | Sort | Most recent processing attempt first |

---

## 8. Sample Queries

### 8.1 Get all processing details for a specific withdrawal

```sql
EXEC [BackOffice].[GetWithdrawRequestsDetailsByID] @WithdrawID = 285760;
```

### 8.2 Check status discrepancy between parent and processing records

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID AS ParentStatus,
    wtf.ID AS ProcessingID,
    wtf.CashoutStatusID AS ProcessingStatus,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding WITH (NOLOCK) wtf
JOIN Billing.Withdraw WITH (NOLOCK) w ON w.WithdrawID = wtf.WithdrawID
WHERE wtf.WithdrawID = 285760
  AND w.CashoutStatusID <> wtf.CashoutStatusID
ORDER BY wtf.ModificationDate DESC;
```

### 8.3 Find latest remark for a processing attempt

```sql
SELECT TOP 1
    BW2F_ID,
    Remark,
    ModificationDate
FROM History.WithdrawToFundingAction WITH (NOLOCK)
WHERE BW2F_ID = 12345
ORDER BY ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 7.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawRequestsDetailsByID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawRequestsDetailsByID.sql*
