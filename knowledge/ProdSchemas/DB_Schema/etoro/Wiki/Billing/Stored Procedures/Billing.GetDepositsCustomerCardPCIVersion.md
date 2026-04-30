# Billing.GetDepositsCustomerCardPCIVersion

> Returns a richly enriched back-office deposit report for a customer within a date range, including formatted MID/payment details, 3DS authentication parameters, FTD detection, rollback amounts, customer risk/status, and account manager information - the primary deposit review tool for the payments back-office team.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns enriched deposit rows for @CID where ModificationDate BETWEEN @StartDate AND @EndDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositsCustomerCardPCIVersion` is the comprehensive back-office deposit investigation tool. Given a customer CID and date range, it returns a fully enriched deposit report joining 20+ tables and views to produce a single result set with all relevant context a back-office agent needs to review a deposit: payment method, gateway (depot), MID details, 3DS authentication parameters, FTD flag, rollback amounts, customer status/level/risk profile, response codes, and processor information.

The "PCI version" designation distinguishes this from older procedures that returned raw card numbers. This version uses the `Billing.FundingPaymentDetailsForDeposit` view (which provides pre-formatted, PCI-compliant payment details) and constructs masked/formatted payment instrument identifiers instead of raw sensitive data.

**Change history** (from SP header comment):
- 22/04/2019 Adi: Moved most display logic to `Billing.FundingPaymentDetailsForDeposit` view (PCI refactor)
- 12/08/2019 Adi: Added 3DS information (RD-10567)
- 06/09/2020 Ran: Added FundingTypeID=35 (Trustly) - MIMOPS-2100
- 03/01/2021 Shay Oren: Switched from `History.Credit` to `History.ActiveCreditRecentMemoryBucket` (in-memory optimization)
- 21/05/2023 Ran: Added RollbackReason column - MIMOPSA-9421
- 06/01/2025 Merab Ag: Added "Processed By" (agent name) - MIMOPS2-1587

No explicit GRANT EXECUTE found in SSDT permissions files - accessed directly by back-office staff via elevated DB access or a service account not tracked in SSDT.

---

## 2. Business Logic

### 2.1 Credit History Pre-Load (In-Memory Optimization)

**What**: Before the main query, the SP loads the customer's relevant credit history into a table variable `@ActiveCreditLocal` from two sources: the fast in-memory table and the full history archive.

**Columns/Parameters Involved**: `History.ActiveCreditRecentMemoryBucket`, `History.Credit`, `@CID`

**Rules**:
- `INSERT @ActiveCreditLocal SELECT ... FROM History.ActiveCreditRecentMemoryBucket WHERE CreditTypeID IN (1, 11, 12, 16) AND CID = @CID`
- `INSERT @ActiveCreditLocal SELECT ... FROM History.Credit WHERE CreditTypeID IN (1, 11, 12, 16) AND CID = @CID`
- CreditTypeID filter: 1=Deposit credit (used for FTD detection), 11/12/16=Rollback credit types (used for rollback amount calculation)
- This pre-load avoids repeated reads from the large `History.Credit` table during the main query's multiple GROUP BY and JOIN operations

### 2.2 FTD Detection

**What**: Identifies whether each deposit is the customer's first-time deposit.

**Columns/Parameters Involved**: `@ActiveCreditLocal.CreditTypeID=1`, `@ActiveCreditLocal.DepositID`, `IsFTD (output)`

**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY CreditID)` on CreditTypeID=1 records
- FTD row = RN=1 (earliest CreditID among deposit credits)
- `CASE WHEN BDEP.DepositID = ISNULL(FTD.FTD_Deposit, 0) THEN 'YES' ELSE '' END AS IsFTD`
- Output is 'YES' or empty string (not 1/0)

### 2.3 Rollback Amount Calculation

**What**: Computes the total amount rolled back for each deposit, using either the BackOffice rollback tracking record or the last rollback credit.

**Columns/Parameters Involved**: `BackOffice.DepositRollbackTracking`, `@ActiveCreditLocal`, `TotalRollbackAmountInUSD`, `TotalRollbackAmountInCurrency`, `RollbackReason`

**Rules**:
- `OUTER APPLY (SELECT TOP 1 ... FROM BackOffice.DepositRollbackTracking WHERE IsCanceled=0 ORDER BY RollbackID DESC) AS BODRT`
- Rollback amount priority (CASE):
  1. `BODRT.DepositID IS NOT NULL` -> use `BODRT.TotalRollbackAmountInUSD/InCurrency` (from formal rollback tracking)
  2. `PaymentStatusID=2` (approved deposit) -> 0 (no rollback for approved deposits)
  3. Otherwise -> `RLBK.RollbackAmount` (last rollback credit from @ActiveCreditLocal) / ExchangeRate for currency
- `RollbackReason`: from `Dictionary.DepositRollbackTypeReason.Name` via BackOffice.DepositRollbackTracking

### 2.4 MID Resolution (Complex Multi-Path)

**What**: Resolves the Merchant ID (MID) display name and value using funding-type-specific and depot-specific logic.

**Columns/Parameters Involved**: `BPMS.Value`, `BPMS.MerchantAccountID`, `Dictionary.MerchantAccount`, `BackOffice.GetMerchantDetails`, `Billing.GetMerchantDetailsForOneAccountByDepotOnly`, `MIDName (output)`, `MID (output)`

**Rules** (CASE on FundingTypeID and DepotID):
- `FundingTypeID=2 (Wire)` -> MIDName=`BPMS.Description`, MID=`BPMS.Value`
- `DepotID IN (78,79,80,4,75,86)` -> Both from `Billing.GetMerchantDetailsForOneAccountByDepotOnly(DepotID, RegulationID, [name/value flag])`
- All others -> MIDName=`COALESCE(DMA.BODescription, BackOffice.GetMerchantDetails(MerchantAccountID, 1), DR.Name)`, MID=`COALESCE(DMA.Name, BackOffice.GetMerchantDetails(MerchantAccountID, 0), BPMS.Description, BMMC.MID, BPMS.Value)`
- `Dictionary.MerchantAccount (DMA)` takes priority when available via `BDEP.MerchantAccountID`

### 2.5 3DS Authentication Information

**What**: Extracts 3D Secure authentication parameters (CAVV, ECI flag, XID) from the payment trace log.

**Columns/Parameters Involved**: `Billing.Trace.Message` (JSON), `Billing.Trace.TransactionId`, `[3ds parameters] (output)`, `[3ds response] (output)`

**Rules**:
- `OUTER APPLY (SELECT TOP 1 ... FROM Billing.Trace WHERE TransactionId = BDEP.DepositID AND (JSON_VALUE(Message, '$.Cavv') IS NOT NULL OR ...) ORDER BY Created DESC, EventType DESC)`
- EventType=1: `CONCAT('CAVV:', $.Cavv, ', ECI:', $.EciFlag, ', XID:', $.Xid)`
- Other EventType: `CONCAT('CAVV:', $.Payload.Payment.ExtendedData.CAVV, ', ECI:', $.ECIFlag, ', XID:', $.XID)` (nested Payload format)
- `[3ds response]`: from `Dictionary.ThreeDsResponseTypes` via `BDEP.PaymentData.value('/Deposit/ThreeDsResponseType[1]', INT)`

### 2.6 Payment Details by Funding Type

**What**: Constructs a formatted payment details string for display, per funding type.

**Columns/Parameters Involved**: `BFUN.FundingTypeID`, `BDEP.PaymentData` (XML), `BFUN.FundingDetails`, `PaymentDetails (output)`

**Rules**:
- FundingTypeID=2 (Wire): IBAN from `PaymentData./Deposit/IBANCodeAsString`
- FundingTypeID=33: CardID + GCID + FundingDetails
- FundingTypeID=34: IBAN from Deposit XML
- FundingTypeID=35 (Trustly): BicCode + IBAN + AccountHolderName
- FundingTypeID=37: AccountSortCode + FirstName + LastName + AccountNumber + BankName
- FundingTypeID=39: PayId + Email + FirstName + MiddleName + LastName
- FundingTypeID=42: ExTransactionID
- All others: `BFUN.FundingDetails` (from the FundingPaymentDetailsForDeposit view)

**Diagram**:
```
@CID + @StartDate + @EndDate
  |
  Step 1: Load @ActiveCreditLocal from ActiveCreditRecentMemoryBucket + History.Credit
          (CreditTypeID IN 1,11,12,16 for @CID)
  |
  Step 2: Main query
          FROM Billing.CustomerToFunding (outer table)
          LEFT JOIN Billing.Deposit ON CID+FundingID
          WHERE BDEP.ModificationDate BETWEEN @StartDate AND @EndDate
          |
          +-> 20+ JOINs for enrichment
          +-> OUTER APPLY: BackOffice.DepositRollbackTracking (last rollback)
          +-> OUTER APPLY: History.DepositAction (last response code)
          +-> OUTER APPLY: Billing.Trace (3DS parameters)
          +-> OUTER APPLY: BackOffice.GetUserRisksByCID (risk statuses)
  |
  Step 3: Outer SELECT WHERE CID=@CID ORDER BY ModificationDate DESC
          -> 40+ formatted display columns
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Applied in outer WHERE (CID=@CID) after date-range filtering. |
| 2 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of date range. Filter: BDEP.ModificationDate >= @StartDate (deposit status modification date). |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of date range. Filter: BDEP.ModificationDate <= @EndDate. |
| 4 | CID (output) | INT | - | - | CODE-BACKED | Customer ID (same as @CID). |
| 5 | Deposit Status (output) | VARCHAR | - | - | CODE-BACKED | Human-readable deposit status name from Dictionary.PaymentStatus. |
| 6 | 3ds response (output) | VARCHAR | - | - | CODE-BACKED | 3D Secure response type name from Dictionary.ThreeDsResponseTypes. |
| 7 | Deposit Risk Status (output) | VARCHAR | - | - | CODE-BACKED | Risk management status name from Dictionary.RiskManagementStatus. |
| 8 | Deposit Amount (output) | DECIMAL(16,2) | - | - | CODE-BACKED | Deposit amount in deposit currency (dollars), formatted to 2dp. |
| 9 | Currency (output) | VARCHAR | - | - | CODE-BACKED | Currency abbreviation from Dictionary.Currency (e.g., 'USD', 'EUR'). |
| 10 | Status Modification Time (output) | DATETIME | - | - | CODE-BACKED | Billing.Deposit.ModificationDate - when the deposit status last changed. Used as sort key and date filter. |
| 11 | Deposit Time (output) | DATETIME | - | - | CODE-BACKED | Billing.Deposit.PaymentDate - when the deposit was submitted. |
| 12 | Deposit $ Amount (output) | DECIMAL(16,2) | - | - | CODE-BACKED | Amount * ExchangeRate rounded to avoid floating point artifacts: `CASE WHEN (Amount*ExRate) % 0.005 = 0 THEN (Amount*ExRate) - 0.001 ELSE (Amount*ExRate) END`. |
| 13 | Funding Method (output) | VARCHAR | - | - | CODE-BACKED | Payment method name from Dictionary.FundingType. |
| 14 | Depot (output) | VARCHAR | - | - | CODE-BACKED | Payment gateway name from Billing.Depot. |
| 15 | FundingID (output) | INT | - | - | CODE-BACKED | Raw FundingID from Billing.Deposit. |
| 16 | ExTransactionID (output) | VARCHAR | - | - | CODE-BACKED | External gateway transaction ID. |
| 17 | Payment Details (output) | NVARCHAR | - | - | CODE-BACKED | Formatted payment instrument details, constructed per FundingTypeID (IBAN, BIC, card metadata, etc.). |
| 18 | OldPaymentID (output) | INT | - | - | CODE-BACKED | Previous payment ID for re-attempts. |
| 19 | DepositID (output) | INT | - | - | CODE-BACKED | Primary key of the deposit. |
| 20 | Country By RegForm (output) | VARCHAR | - | - | CODE-BACKED | Country name from Dictionary.Country based on Customer.Customer.CountryID (registration country, not deposit country). |
| 21 | Risk status (output) | VARCHAR | - | - | CODE-BACKED | Concatenated risk status names from BackOffice.GetUserRisksByCID (all risk flags for the customer). |
| 22 | FTD (output) | VARCHAR | - | - | CODE-BACKED | 'YES' if this deposit is the customer's first-time deposit; '' (empty) otherwise. Derived from CreditTypeID=1 history. |
| 23 | BaseExchangeRate (output) | dbo.dtPrice | - | - | CODE-BACKED | Base exchange rate before markup. |
| 24 | ExchangeRate (output) | DECIMAL(16,4) | - | - | CODE-BACKED | Applied exchange rate for USD conversion. |
| 25 | Customer Status (output) | VARCHAR | - | - | CODE-BACKED | Customer status name from Dictionary.PlayerStatus (trimmed). |
| 26 | Brand (output) | VARCHAR | - | - | CODE-BACKED | Card brand/type name from Dictionary.CardType for credit cards, or empty for others. |
| 27 | Customer Level (output) | VARCHAR | - | - | CODE-BACKED | Player level name from Dictionary.PlayerLevel (e.g., 'Silver', 'Gold', 'Platinum'). |
| 28 | Account Manager (output) | VARCHAR | - | - | CODE-BACKED | First name of the back-office manager assigned to this customer (BackOffice.Manager via BackOffice.Customer.ManagerID). |
| 29 | Total Rollback $ Amount (output) | DECIMAL(16,2) | - | - | CODE-BACKED | Total amount rolled back for this deposit in USD. From BackOffice.DepositRollbackTracking or last rollback credit. 0 for approved deposits. |
| 30 | RollbackReason (output) | VARCHAR | - | - | CODE-BACKED | Reason name for the rollback from Dictionary.DepositRollbackTypeReason. NULL if no rollback. |
| 31 | Total Rollback Amount (output) | DECIMAL(16,2) | - | - | CODE-BACKED | Total rollback amount in deposit currency. |
| 32 | User Name (output) | VARCHAR | - | - | CODE-BACKED | Customer username from Customer.Customer. |
| 33 | Response Code (output) | VARCHAR | - | - | CODE-BACKED | `CAST(ProtocolID AS VARCHAR) + '_' + ResponseCode` from Dictionary.Response via last History.DepositAction. |
| 34 | Transaction Response (output) | VARCHAR | - | - | CODE-BACKED | Response name from Dictionary.Response.ResponseName (last action). |
| 35 | Deposit Value Date (output) | DATETIME | - | - | CODE-BACKED | Processor value date from Billing.Deposit.ProcessorValueDate. |
| 36 | Funnel (output) | VARCHAR | - | - | CODE-BACKED | Funnel name from Dictionary.Funnel. |
| 37 | Deposit Type (output) | VARCHAR | - | - | CODE-BACKED | `CONCAT(DDT.Description, ' - ', DF.Description)` if FlowID exists, else `DDT.Description`. Combines deposit type and flow. |
| 38 | Deposit Type ID (output) | INT | - | - | CODE-BACKED | Raw DepositTypeID from Billing.Deposit. Added MIMOPSA-12252. |
| 39 | MID Name (output) | VARCHAR | - | - | CODE-BACKED | Merchant ID display name. Multi-path resolution: DMA.BODescription -> BackOffice.GetMerchantDetails -> DR.Name. |
| 40 | MID (output) | VARCHAR | - | - | CODE-BACKED | Merchant ID value. Multi-path resolution: DMA.Name -> BackOffice.GetMerchantDetails -> BPMS.Description -> BMMC.MID -> BPMS.Value. |
| 41 | 3ds parameters (output) | VARCHAR | - | - | CODE-BACKED | 3DS authentication parameters (CAVV, ECI, XID) from Billing.Trace JSON message for this deposit. NULL if no 3DS trace found. |
| 42 | Processed By (output) | VARCHAR | - | - | CODE-BACKED | Full name of the back-office agent who processed this deposit (BackOffice.Manager via Billing.Deposit.ManagerID). Added MIMOPS2-1587 (Jan 2025). NULL if processed by system (ManagerID=0). |
| 43 | FlowID (output) | INT | - | - | CODE-BACKED | Flow ID from Billing.Deposit. Used with DepositType. Added MIMOPSA-12252. |
| 44 | Correlation ID (C2F) (output) | NVARCHAR | - | - | CODE-BACKED | For FundingTypeID=27 only: TransactionIdAsString from Deposit.PaymentData XML. C2F = Customer-to-Funding internal tracking. NULL for all other funding types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.CustomerToFunding.CID | Outer drive table | Drives the join to deposits via customer-funding pairs |
| BDEP.FundingID | Billing.FundingPaymentDetailsForDeposit.FundingID | JOIN | PCI-compliant payment details view |
| BDEP.DepotID | Billing.Depot | LEFT JOIN | Gateway name |
| BDEP.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | LEFT JOIN | MID settings |
| BPMS.Value + BDEP.CurrencyID + BPMS.RegulationID | Billing.MapMerchantCodeToMid | LEFT JOIN | MID code lookup |
| BDEP.DepositID | BackOffice.DepositRollbackTracking | OUTER APPLY | Rollback amount |
| BDEP.DepositID | History.DepositAction | OUTER APPLY | Last response code |
| BDEP.DepositID | Billing.Trace | OUTER APPLY | 3DS authentication parameters |
| BDEP.CID | History.ActiveCreditRecentMemoryBucket | Pre-load | FTD + rollback credit history |
| BDEP.CID | History.Credit | Pre-load | Full credit history (supplement to in-memory table) |
| CCST.CID | Customer.Customer | JOIN | Username, PlayerLevelID, PlayerStatusID, CountryID |
| BDEP.CID | BackOffice.Customer | JOIN | ManagerID, RegulationID |
| BDEP.CID | BackOffice.GetUserRisksByCID | OUTER APPLY | Risk statuses |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office payment team | Direct execution | Operational | Primary back-office deposit investigation tool; no SSDT GRANT EXECUTE found |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositsCustomerCardPCIVersion (procedure)
├── Billing.CustomerToFunding (table)
├── Billing.Deposit (table)
├── Billing.FundingPaymentDetailsForDeposit (view - PCI payment details)
├── Billing.ProtocolMIDSettings (table)
├── Billing.MapMerchantCodeToMid (table)
├── Billing.Depot (table)
├── Billing.Trace (table - 3DS logs)
├── Billing.GetMerchantDetailsForOneAccountByDepotOnly (function)
├── BackOffice.DepositRollbackTracking (table)
├── BackOffice.Customer (table)
├── BackOffice.Manager (table)
├── BackOffice.GetMerchantDetails (function)
├── BackOffice.GetUserRisksByCID (function)
├── Customer.Customer (table)
├── History.ActiveCreditRecentMemoryBucket (in-memory table)
├── History.Credit (table)
├── History.DepositAction (table)
├── Dictionary.PaymentStatus (table)
├── Dictionary.Currency (table)
├── Dictionary.FundingType (table)
├── Dictionary.PlayerLevel (table)
├── Dictionary.PlayerStatus (table)
├── Dictionary.Country (table)
├── Dictionary.CardType (table)
├── Dictionary.RiskManagementStatus (table)
├── Dictionary.Regulation (table)
├── Dictionary.Response (table)
├── Dictionary.Funnel (table)
├── Dictionary.DepositType (table)
├── Dictionary.Flow (table)
├── Dictionary.ThreeDsResponseTypes (table)
├── Dictionary.CountryBin (table)
└── Dictionary.MerchantAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | Outer drive table - customer-funding pairs |
| Billing.Deposit | Table | LEFT JOIN via CTF - deposit records in date range |
| Billing.FundingPaymentDetailsForDeposit | View | JOIN - PCI-safe payment instrument details |
| Billing.ProtocolMIDSettings | Table | LEFT JOIN - MID configuration |
| Billing.MapMerchantCodeToMid | Table | LEFT JOIN - MID code-to-name mapping |
| Billing.Depot | Table | LEFT JOIN - gateway name |
| Billing.Trace | Table | OUTER APPLY - 3DS authentication parameters from JSON |
| Billing.GetMerchantDetailsForOneAccountByDepotOnly | Function | Inline call - MID resolution for specific depots |
| BackOffice.DepositRollbackTracking | Table | OUTER APPLY - formal rollback records |
| BackOffice.Customer | Table | JOIN (x2) - manager and regulation |
| BackOffice.Manager | Table | LEFT JOIN (x2) - account manager and processor names |
| BackOffice.GetMerchantDetails | Function | Inline call - fallback MID resolution |
| BackOffice.GetUserRisksByCID | Function | OUTER APPLY - all risk flags for customer |
| Customer.Customer | Table | JOIN - username, level, status, country |
| History.ActiveCreditRecentMemoryBucket | In-Memory Table | Pre-load - recent credit history (fast read) |
| History.Credit | Table | Pre-load - full credit archive (supplement) |
| History.DepositAction | Table | OUTER APPLY - last deposit action/response |
| Dictionary.* (12 tables) | Tables | JOINs - status names, types, funnel, currency, etc. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office payment team | Manual execution | Deposit investigation and review |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Date filter on ModificationDate | Design | Filters by BDEP.ModificationDate (status change time), not PaymentDate (submission time) - important for finding deposits that changed status in a date range |
| @ActiveCreditLocal pre-load | Performance | Loads credit history once into table variable to avoid repeated scans of History.Credit; ActiveCreditRecentMemoryBucket provides fast in-memory access for recent records |
| PCI compliance | Security | No raw card numbers returned; FundingPaymentDetailsForDeposit view provides pre-masked data; older raw-card version (GetDepositsCustomerCardPCIVersionOld) exists but is deprecated |
| No GRANT EXECUTE in SSDT | Access | Not in permissions files; likely accessed by back-office staff with elevated database roles |
| Scalar function calls in SELECT | Performance | `BackOffice.GetMerchantDetails` and `Billing.GetMerchantDetailsForOneAccountByDepotOnly` called row-by-row; can be slow for large date ranges or customers with many deposits |
| CustomerToFunding as drive table | Design | Drives from customer-funding pairs rather than deposits directly; may return rows for funding instruments with no deposits in the date range (NULL via LEFT JOIN) |

---

## 8. Sample Queries

### 8.1 Review deposits for a customer in a date range

```sql
EXEC Billing.GetDepositsCustomerCardPCIVersion
    @CID = 12345,
    @StartDate = '2025-01-01',
    @EndDate = '2025-03-18';
```

### 8.2 Review a specific day's deposits

```sql
EXEC Billing.GetDepositsCustomerCardPCIVersion
    @CID = 54543,
    @StartDate = '20190709',
    @EndDate = '20190910';
-- (Example from SP header comments)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPSA-9421 (May 2023) | Jira (from comment) | Added RollbackReason column to output |
| MIMOPS2-1587 (Jan 2025) | Jira (from comment) | Added "Processed By" agent name column. Assigned to Merab Ag. |
| MIMOPS-2100 (Sep 2020) | Jira (from comment) | Added FundingTypeID=35 (Trustly) support |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 44 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 3 Jira (from code comments) | Procedures: 0 SQL callers | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositsCustomerCardPCIVersion | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositsCustomerCardPCIVersion.sql*
