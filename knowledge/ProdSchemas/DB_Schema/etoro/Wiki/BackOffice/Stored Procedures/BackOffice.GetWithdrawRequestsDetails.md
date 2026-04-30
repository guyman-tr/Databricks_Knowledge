# BackOffice.GetWithdrawRequestsDetails

> Returns detailed withdrawal processing records for a date range, including payment method details, exchange rates, MID (Merchant ID) routing, and processing status - used by Back Office for withdrawal management and reporting.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate + @EndDate (required date range); @CID optional customer filter; ordered by ModificationDate DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawRequestsDetails` retrieves the full operational detail of withdrawal processing records within a date range, at the `Billing.WithdrawToFunding` level (not the parent `Billing.Withdraw` level). Each row represents a single funding transfer attempt for a withdrawal - one withdrawal may have multiple funding records if it was processed in stages or retried with different payment methods.

The procedure is the primary data source for the Back Office withdrawal management UI and reporting. It resolves human-readable names for status, funding method, currency, depot, and manager; it constructs a `PaymentDetails` field whose content varies by payment method type (credit card, bank wire, PayPal, WebMoney, etc.); and it resolves Merchant ID (MID) routing information used by the payment team to reconcile transactions.

Data flows as follows: a customer initiates a withdrawal -> `Billing.Withdraw` is created -> one or more `Billing.WithdrawToFunding` processing records are created as the withdrawal moves through payment channels -> this procedure reads those processing records enriched with lookup names, payment details, and MID routing. The optional `@CID` parameter allows filtering to a specific customer for investigation.

A PCI-safe synonym `BackOffice.GetWithdrawRequestsDetailsPCIVersion` references this procedure (or a masked variant) to hide sensitive payment data from non-PCI-cleared users.

---

## 2. Business Logic

### 2.1 PaymentDetails Field Construction

**What**: The `PaymentDetails` output column contains payment-method-specific identifiers needed for reconciliation. Its content is constructed differently for each payment method via a CASE expression.

**Columns/Parameters Involved**: `PaymentDetails`, `FundingTypeID`, `CashoutTypeID`, `FundingData` (XML), `WithdrawData` (XML)

**Rules**:
- `FundingTypeID = 1` (Credit Card): PaymentDetails = NULL; Brand is shown instead via `Dictionary.CardType`
- `FundingTypeID = 2` (Bank Wire): Concatenates `Billing.Funding.PaymentDetails` + BSBNumber (from WithdrawData XML `/Withdraw[1]/BSBNumberAsString[1]`) + ClientAddress (from XML `/Withdraw[1]/ClientAddressAsString[1]`)
- `FundingTypeID = 3, CashoutTypeID = 1` (PayPal new money): Email from `FundingData` XML + "Payer ID: " + PayerID from XML. Updated MIMOPS-5237 to use `Billing.Funding` directly instead of `Billing.FundingPaymentDetailsForWithdraw` view to include the PayerID.
- `FundingTypeID = 3, CashoutTypeID = 2` (PayPal refund): PayerAsString from `Billing.Deposit.PaymentData` XML
- `FundingTypeID = 10` (WebMoney / eWallet): AccountID + PurseID from `FundingData` XML
- `FundingTypeID = 33` (other wallet): CardID + AccountID + GCID from `WithdrawData` XML
- All other types: Raw `Billing.Funding.PaymentDetails`

**Diagram**:
```
FundingTypeID + CashoutTypeID -> PaymentDetails content
  1 (Credit Card)           -> NULL (Brand column used instead)
  2 (Bank Wire)             -> PaymentDetails + BSBNumber + ClientAddress
  3 + CashoutType=1 (PayPal new) -> Email + PayerID (from FundingData XML)
  3 + CashoutType=2 (PayPal refund) -> PayerAsString (from Deposit XML)
  10 (WebMoney)             -> AccountID + PurseID
  33 (wallet)               -> CardID + AccountID + GCID
  other                     -> Funding.PaymentDetails (raw)
```

### 2.2 MID (Merchant ID) Resolution

**What**: The Merchant ID identifies which payment processing terminal/agreement handled the transaction. It is resolved via two separate LEFT JOIN paths depending on the depot.

**Columns/Parameters Involved**: `MID Name`, `MID`, `CashoutTypeID`, `DepotID`

**Rules**:
- Only populated when `CashoutTypeID IN (2, 3)` (refund-type cashouts via depot routing)
- `DepotID = 18`: MID Name from `Dictionary.Regulation DR1` via `Billing.ProtocolMIDSettings BPMS1`; MID value from `BPMS1.Value`
- `DepotID IN (35-44)`: MID Name from `Dictionary.Regulation DR2` via `Billing.ProtocolMIDSettings BPMS2`; MID value from `BPMS2.Value` (via the linked `Billing.Deposit.ProtocolMIDSettingsID`)
- NULL for all other CashoutTypeID or DepotID combinations

### 2.3 Date Range Filter + Optional CID

**What**: The procedure's scope is controlled by a mandatory date range and an optional customer filter.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@CID`, `BWIT.ModificationDate`

**Rules**:
- Filter on `Billing.Withdraw.ModificationDate BETWEEN @StartDate AND @EndDate` - uses the PARENT withdraw's modification date, not the processing record's date
- `@CID = NULL` (default): returns all customers in the date range
- `@CID IS NOT NULL`: uses `BWIT.CID = @CID` to filter to one customer
- `OPTION (RECOMPILE)` is applied to prevent parameter-sniffing performance degradation when CID switches between NULL and specific values

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the date range filter. Applied to `Billing.Withdraw.ModificationDate` (the parent withdrawal's last status change date, not the funding record date). |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the date range filter. Applied to `Billing.Withdraw.ModificationDate`. |
| 3 | @CID | INT | YES | NULL | CODE-BACKED | Optional customer ID filter. When NULL (default), returns all customers in the date range. When provided, filters to a single customer's records for investigation or reporting. |

**Output columns (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Net. Cashout Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | The net amount paid out on this funding transfer (`Billing.WithdrawToFunding.Amount`), cast to 2 decimal places. |
| 2 | Exchange Rate | DECIMAL(16,4) | YES | - | CODE-BACKED | The exchange rate applied to convert the withdrawal amount to the processing currency (`Billing.WithdrawToFunding.ExchangeRate`), cast to 4 decimal places. |
| 3 | Currency | NVARCHAR | NO | - | CODE-BACKED | Abbreviation (e.g. "USD", "EUR") of the processing currency (`Dictionary.Currency.Abbreviation` joined on `WithdrawToFunding.ProcessCurrencyID`). |
| 4 | Status | NVARCHAR | NO | - | CODE-BACKED | Human-readable cashout status name for this funding record (`Dictionary.CashoutStatus.Name` joined on `WithdrawToFunding.CashoutStatusID`). E.g. "Approved", "Rejected", "Pending". |
| 5 | Funding Method | NVARCHAR | NO | - | CODE-BACKED | Human-readable name of the payment method type (`Dictionary.FundingType.Name` joined on `Billing.Funding.FundingTypeID`). E.g. "Credit Card", "Wire Transfer", "PayPal". |
| 6 | Request Time | DATETIME | NO | - | CODE-BACKED | Creation timestamp of the funding processing record (`Billing.WithdrawToFunding.CreationDate`). Represents when this specific processing attempt was initiated. |
| 7 | Brand | NVARCHAR | YES | - | CODE-BACKED | Card brand name (e.g. "Visa", "Mastercard") from `Dictionary.CardType.Name`. Only populated when `FundingTypeID = 1` (credit card). NULL for all other payment methods. |
| 8 | Depot | NVARCHAR | YES | - | CODE-BACKED | Name of the payment depot/gateway used (`Billing.Depot.Name` via LEFT JOIN on `WithdrawToFunding.DepotID`). NULL if no depot is assigned. |
| 9 | PaymentDetails | VARCHAR(MAX) | YES | - | CODE-BACKED | Payment method-specific detail string for reconciliation. Content varies by FundingTypeID and CashoutTypeID. See Section 2.1 for full logic. Includes XML-parsed identifiers (BSB, PayerID, AccountID, etc.) concatenated as a display string. |
| 10 | FundingID | INT | NO | - | CODE-BACKED | The identifier of the funding record (`Billing.WithdrawToFunding.FundingID`). Used to link back to the full `Billing.Funding` record for further investigation. |
| 11 | IsVerified | VARCHAR(3) | NO | - | CODE-BACKED | Whether the customer-funding link is verified: "Yes" if `Billing.CustomerToFunding.IsVerified = 1`, "No" otherwise. Indicates whether this funding method has been verified for this customer (e.g. KYC-linked payment method). |
| 12 | Status Modification Time | DATETIME | NO | - | CODE-BACKED | Timestamp when the funding processing record's status last changed (`Billing.WithdrawToFunding.ModificationDate`). Used for ORDER BY DESC sorting. |
| 13 | Processor Value Date | DATETIME | YES | - | CODE-BACKED | The value date assigned by the payment processor (`Billing.WithdrawToFunding.ProcessorValueDate`). Used for settlement date tracking. |
| 14 | Processed By | NVARCHAR | YES | - | CODE-BACKED | Full name of the Back Office manager who processed this record: `BackOffice.Manager.FirstName + ' ' + LastName`. NULL if no manager is assigned (automated processing). |
| 15 | WithdrawID | INT | NO | - | CODE-BACKED | The parent withdrawal identifier (`Billing.WithdrawToFunding.WithdrawID`). Links back to `Billing.Withdraw` for the original withdrawal request details. |
| 16 | Withdraw Processing ID | INT | NO | - | CODE-BACKED | The primary key of the funding processing record (`Billing.WithdrawToFunding.ID`). Unique identifier for this specific processing attempt. |
| 17 | ParentStatusID | INT | NO | - | CODE-BACKED | The cashout status of the parent withdrawal record (`Billing.Withdraw.CashoutStatusID`). Allows comparison between parent and processing-record statuses to detect discrepancies. |
| 18 | CashoutStatusID | INT | NO | - | CODE-BACKED | The cashout status of this specific funding processing record (`Billing.WithdrawToFunding.CashoutStatusID`). May differ from ParentStatusID if a retry is in a different state. |
| 19 | MID Name | NVARCHAR | YES | - | CODE-BACKED | Merchant ID regulation/agreement name. Populated only for refund-type cashouts (CashoutTypeID IN (2,3)) via specific depots. See Section 2.2. NULL otherwise. |
| 20 | MID | NVARCHAR | YES | - | CODE-BACKED | Merchant ID value used for this transaction. Populated only for refund-type cashouts via specific depots (see Section 2.2). Used by the payment team for transaction reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate/@EndDate | Billing.Withdraw.ModificationDate | Filter | Date range applied to parent withdraw modification timestamp |
| @CID | Billing.Withdraw.CID | Filter | Optional customer filter on parent withdrawal |
| (FROM) | Billing.WithdrawToFunding | Direct read | Main data table - one row per funding processing attempt |
| WithdrawToFunding.DepotID | Billing.Depot | Lookup (LEFT) | Resolves depot name |
| WithdrawToFunding.WithdrawID | Billing.Withdraw | JOIN | Parent withdrawal record for status and CID |
| WithdrawToFunding.FundingID | Billing.Funding | JOIN | Payment method details and FundingTypeID |
| Funding.FundingTypeID | Dictionary.FundingType | Lookup | Funding method name |
| WithdrawToFunding.ProcessCurrencyID | Dictionary.Currency | Lookup | Processing currency abbreviation |
| WithdrawToFunding.CashoutStatusID | Dictionary.CashoutStatus | Lookup | Status name |
| WithdrawToFunding.ManagerID | BackOffice.Manager | Lookup (LEFT) | Manager name |
| Funding.FundingData (XML) | Dictionary.CardType | Lookup (LEFT) | Card brand for FundingTypeID=1 |
| WithdrawToFunding.DepositID | Billing.Deposit | Lookup (LEFT) | Original deposit for PayPal refund path |
| (BPMS1) DepotID=18 | Billing.ProtocolMIDSettings | Lookup (LEFT) | MID value for depot 18 |
| BPMS1.RegulationID | Dictionary.Regulation | Lookup (LEFT) | MID name for depot 18 |
| (BPMS2) DepotID 35-44 | Billing.ProtocolMIDSettings | Lookup (LEFT) | MID value for depots 35-44 |
| BPMS2.RegulationID | Dictionary.Regulation | Lookup (LEFT) | MID name for depots 35-44 |
| WithdrawToFunding.FundingID + Withdraw.CID | Billing.CustomerToFunding | Lookup (LEFT) | IsVerified flag for the customer-funding link |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetWithdrawRequestsDetailsPCIVersion | (synonym) | Synonym | PCI-safe alias for this procedure, restricting sensitive payment data for non-PCI users |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawRequestsDetails (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Billing.Funding (table)
├── Billing.Depot (table)
├── Billing.Deposit (table)
├── Billing.ProtocolMIDSettings (table) [x2 - BPMS1 + BPMS2]
├── Billing.CustomerToFunding (table)
├── Dictionary.FundingType (table)
├── Dictionary.Currency (table)
├── Dictionary.CashoutStatus (table)
├── Dictionary.CardType (table)
├── Dictionary.Regulation (table) [x2 - DR1 + DR2]
└── BackOffice.Manager (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FROM (main table); provides all processing record data |
| Billing.Withdraw | Table | INNER JOIN on WithdrawID; provides CID, ModificationDate (date filter), CashoutStatusID |
| Billing.Funding | Table | INNER JOIN on FundingID; provides FundingTypeID, PaymentDetails, FundingData XML |
| Billing.Depot | Table | LEFT JOIN on DepotID; provides depot name |
| Billing.Deposit | Table | LEFT JOIN on DepositID; provides PaymentData XML for PayPal refund path |
| Billing.ProtocolMIDSettings | Table | LEFT JOIN x2 (by WithdrawToFunding and Deposit); provides MID values |
| Billing.CustomerToFunding | Table | LEFT JOIN on FundingID+CID; provides IsVerified flag |
| Dictionary.FundingType | Table | JOIN on FundingTypeID; provides funding method name |
| Dictionary.Currency | Table | JOIN on ProcessCurrencyID; provides currency abbreviation |
| Dictionary.CashoutStatus | Table | JOIN on CashoutStatusID; provides status name |
| Dictionary.CardType | Table | LEFT JOIN via XML parsing of FundingData; provides card brand |
| Dictionary.Regulation | Table | LEFT JOIN x2 via ProtocolMIDSettings; provides MID regulation name |
| BackOffice.Manager | Table | LEFT JOIN on ManagerID; provides processor full name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetWithdrawRequestsDetailsPCIVersion | Synonym | PCI-safe alias exposing this procedure to users without full payment data access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WITH (NOLOCK) | Query hint | All tables use NOLOCK - read-only reporting query, dirty reads acceptable |
| OPTION (RECOMPILE) | Query hint | Forces per-execution plan recompilation to handle parameter sniffing: when @CID is NULL the plan scans broadly; when set it should seek. Without RECOMPILE, a cached plan for one case may degrade the other. |
| ORDER BY BWTF.ModificationDate DESC | Sort | Results ordered with most recently modified processing records first |

---

## 8. Sample Queries

### 8.1 Fetch withdrawal details for a date range

```sql
EXEC [BackOffice].[GetWithdrawRequestsDetails]
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-18';
```

### 8.2 Fetch withdrawal details for a specific customer

```sql
EXEC [BackOffice].[GetWithdrawRequestsDetails]
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-18',
    @CID = 123456;
```

### 8.3 Underlying query - review all funding attempts for a customer's recent withdrawals

```sql
SELECT
    w.WithdrawID,
    wtf.ID AS ProcessingID,
    wtf.CashoutStatusID,
    cs.Name AS StatusName,
    ft.Name AS FundingMethod,
    wtf.Amount,
    w.ModificationDate
FROM Billing.WithdrawToFunding WITH (NOLOCK) wtf
JOIN Billing.Withdraw WITH (NOLOCK) w ON w.WithdrawID = wtf.WithdrawID
JOIN Dictionary.CashoutStatus WITH (NOLOCK) cs ON cs.CashoutStatusID = wtf.CashoutStatusID
JOIN Dictionary.FundingType WITH (NOLOCK) ft ON ft.FundingTypeID = (
    SELECT TOP 1 FundingTypeID FROM Billing.Funding WITH (NOLOCK) WHERE FundingID = wtf.FundingID
)
WHERE w.CID = 123456
  AND w.ModificationDate >= '2026-01-01'
ORDER BY wtf.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawRequestsDetails | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawRequestsDetails.sql*
