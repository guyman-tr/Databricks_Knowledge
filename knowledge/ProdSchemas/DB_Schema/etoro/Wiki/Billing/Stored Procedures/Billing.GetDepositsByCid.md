# Billing.GetDepositsByCid

> Returns a paginated, sortable list of deposits for a customer filtered by payment status - a flexible deposit query used by the deposit service for customer deposit history views.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP(@Limit) rows from Billing.Deposit for @CID with @PaymentStatus, sorted dynamically |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositsByCid` is a flexible deposit list query used by the deposit service to retrieve deposits for a specific customer filtered to a single payment status. It supports dynamic sorting by either DepositID or PaymentDate in ascending or descending order, and limits the result set to a caller-specified row count.

This SP returns all columns from `Billing.Deposit` (41 columns) without any joins - it is a raw deposit data retrieval for internal service use (not a display-formatted view like `GetDepositHistoryByDate`). The caller is responsible for resolving foreign key values (FundingTypeID, CurrencyID, etc.) from the raw IDs returned.

Granted to `DepositUser` (deposit processing service account).

---

## 2. Business Logic

### 2.1 Status-Filtered Deposit Retrieval

**What**: Returns all deposits for a customer that match an exact payment status, up to a configurable row limit.

**Columns/Parameters Involved**: `@CID`, `@PaymentStatus`, `@Limit`

**Rules**:
- `WHERE CID = @CID AND PaymentStatusID = @PaymentStatus` - exact status match; caller must pass the numeric status ID
- `SELECT TOP (@Limit)` - limits result set to caller-specified count; no default (caller must always provide)
- `WITH (NOLOCK)` - dirty read for performance; stale reads are acceptable for deposit list views
- Common caller usage: `@PaymentStatus=2` for approved deposits, `@PaymentStatus=1` for pending

### 2.2 Dynamic Sorting

**What**: Supports flexible sort by two columns (DepositID, PaymentDate) in two directions (Asc, Desc) via runtime CASE expressions.

**Columns/Parameters Involved**: `@SortColumn VARCHAR(20)`, `@SortDir VARCHAR(10)`

**Rules**:
- 4 CASE expressions in ORDER BY: `DepositID ASC`, `DepositID DESC`, `PaymentDate ASC`, `PaymentDate DESC`
- Only one CASE resolves to a non-NULL value per execution (based on @SortColumn + @SortDir match)
- If neither parameter matches a supported combination, all CASE expressions return NULL and the ORDER BY has no deterministic effect (undefined sort order)
- No OPTION(RECOMPILE): unlike GetDepositHistoryByDate, this SP allows plan caching (the dynamic sort does not change the data volume as dramatically as a conditional filter would)

**Diagram**:
```
@SortColumn + @SortDir
  |
  +-- 'DepositID' + 'Asc'    -> ORDER BY DepositID ASC
  +-- 'DepositID' + 'Desc'   -> ORDER BY DepositID DESC
  +-- 'PaymentDate' + 'Asc'  -> ORDER BY PaymentDate ASC
  +-- 'PaymentDate' + 'Desc' -> ORDER BY PaymentDate DESC
  +-- (any other combo)      -> undefined sort order
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters deposits to this customer. Maps to Billing.Deposit.CID. |
| 2 | @PaymentStatus | INT | NO | - | CODE-BACKED | Payment status filter. Exact match against Billing.Deposit.PaymentStatusID. Common values: 1=Pending, 2=Approved, 3=Declined, 35=DeclineByRRE. |
| 3 | @Limit | INT | NO | - | CODE-BACKED | Maximum rows to return. Applied as SELECT TOP (@Limit). No server-side default - caller must always specify. |
| 4 | @SortColumn | VARCHAR(20) | NO | - | CODE-BACKED | Column to sort by. Supported values: 'DepositID', 'PaymentDate'. Any other value results in undefined sort order. |
| 5 | @SortDir | VARCHAR(10) | NO | - | CODE-BACKED | Sort direction. Supported values: 'Asc', 'Desc'. Case-sensitive match in CASE expressions. |
| 6 | DepositID (output) | INT | NO | - | CODE-BACKED | Primary key of the deposit. |
| 7 | CID (output) | INT | NO | - | CODE-BACKED | Internal customer ID. Always equals @CID. |
| 8 | FundingID (output) | INT | NO | - | CODE-BACKED | FK to Billing.Funding - the payment instrument used. Join to Billing.Funding for FundingTypeID. |
| 9 | CurrencyID (output) | INT | NO | - | CODE-BACKED | FK to Dictionary.Currency. Currency of the deposit amount. |
| 10 | PaymentStatusID (output) | INT | NO | - | CODE-BACKED | Deposit status. Always equals @PaymentStatus (filter column). 1=Pending, 2=Approved, 3=Declined. |
| 11 | ManagerID (output) | INT | YES | - | CODE-BACKED | ID of the back-office agent who last modified this deposit. NULL for system-processed deposits. |
| 12 | RiskManagementStatusID (output) | INT | YES | - | CODE-BACKED | Risk management review status. FK to Dictionary table. Used by fraud/risk workflows. |
| 13 | Amount (output) | MONEY | NO | - | CODE-BACKED | Deposit amount in deposit currency (dollars, not cents). Multiply by ExchangeRate for USD equivalent. |
| 14 | ExchangeRate (output) | dbo.dtPrice | YES | - | CODE-BACKED | Exchange rate from deposit currency to USD at processing time. |
| 15 | PaymentDate (output) | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the deposit record was created/submitted. |
| 16 | ModificationDate (output) | DATETIME | YES | - | CODE-BACKED | UTC timestamp of last status change. Used in GetDepositApprovedDate for approval timestamp. |
| 17 | TransactionID (output) | VARCHAR | YES | - | CODE-BACKED | Payment gateway transaction reference ID. |
| 18 | IPAddress (output) | VARCHAR | YES | - | CODE-BACKED | Client IP address at deposit submission time. Used for fraud detection. |
| 19 | Approved (output) | BIT | YES | - | CODE-BACKED | Legacy approval flag. Largely superseded by PaymentStatusID=2. |
| 20 | Commission (output) | MONEY | YES | - | CODE-BACKED | Commission amount charged on this deposit. |
| 21 | ClearingHouseEffectiveDate (output) | DATETIME | YES | - | CODE-BACKED | Date the clearing house processes the transaction. Used for wire transfer settlement. |
| 22 | OldPaymentID (output) | INT | YES | - | CODE-BACKED | Reference to the previous payment record if this is a re-attempt or modification. |
| 23 | IsFTD (output) | BIT | NO | - | CODE-BACKED | First-time deposit flag. 1 = this is the customer's first approved deposit. |
| 24 | ProcessorValueDate (output) | DATETIME | YES | - | CODE-BACKED | Value date reported by the payment processor. |
| 25 | RefundVerificationCode (output) | VARCHAR | YES | - | CODE-BACKED | Code used to verify refund eligibility/authorization. |
| 26 | DepotID (output) | INT | YES | - | CODE-BACKED | FK to Billing.Depot - the payment gateway/depot that processed this deposit. |
| 27 | MatchStatusID (output) | INT | YES | - | CODE-BACKED | Wire transfer matching status. Used to track reconciliation of wire deposits. |
| 28 | FunnelID (output) | INT | YES | - | CODE-BACKED | Marketing funnel identifier at deposit time. Used for conversion attribution. |
| 29 | Code (output) | VARCHAR | YES | - | CODE-BACKED | Internal deposit classification code. |
| 30 | ExTransactionID (output) | VARCHAR | YES | - | CODE-BACKED | External/gateway transaction ID. Used for idempotency in GetDepositByExTransactionID. |
| 31 | CampaignCodeID (output) | INT | YES | - | CODE-BACKED | FK to campaign registry. Marketing campaign associated with this deposit. |
| 32 | BonusStatusID (output) | INT | YES | - | CODE-BACKED | Status of bonus processing for this deposit. |
| 33 | BonusAmount (output) | MONEY | YES | - | CODE-BACKED | Bonus amount credited alongside this deposit. |
| 34 | BonusErrorCode (output) | INT | YES | - | CODE-BACKED | Error code if bonus processing failed. |
| 35 | SessionID (output) | VARCHAR | YES | - | CODE-BACKED | Client session ID at deposit submission time. |
| 36 | DepositTypeID (output) | INT | YES | - | CODE-BACKED | Type of deposit (e.g., standard, bonus, credit). |
| 37 | StatusReasonID (output) | INT | YES | - | CODE-BACKED | Reason code for the current status (e.g., decline reason). |
| 38 | DRStatusID (output) | INT | YES | - | CODE-BACKED | Dispute/chargeback resolution status ID. |
| 39 | DRDate (output) | DATETIME | YES | - | CODE-BACKED | Date of dispute/chargeback resolution. |
| 40 | ProtocolMIDSettingsID (output) | INT | YES | - | CODE-BACKED | FK to Billing.DepotMIDSettings - the MID (Merchant ID) configuration used for this deposit. |
| 41 | ExchangeFee (output) | MONEY | YES | - | CODE-BACKED | Fee charged for currency exchange at deposit time. |
| 42 | BaseExchangeRate (output) | dbo.dtPrice | YES | - | CODE-BACKED | Base exchange rate before markup/fee. Used with ExchangeFee to reconstruct full FX cost. |
| 43 | ProcessRegulationID (output) | INT | YES | - | CODE-BACKED | Regulatory regime under which this deposit was processed (e.g., MiFID, ASIC). |
| 44 | PaymentGeneration (output) | INT | YES | - | CODE-BACKED | Payment processing generation/version. Used for legacy system routing. |
| 45 | ExchangeFeePercentage (output) | DECIMAL | YES | - | CODE-BACKED | Exchange fee as a percentage of the deposit amount. |
| 46 | PaymentData (output) | XML/VARCHAR | YES | - | CODE-BACKED | Additional payment-method-specific data in structured format. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit.CID | Lookup | Filters to specified customer's deposits |
| @PaymentStatus | Billing.Deposit.PaymentStatusID | Filter | Restricts to single payment status |
| FundingID (output) | Billing.Funding.FundingID | Implicit FK | Caller must join to resolve payment instrument details |
| CurrencyID (output) | Dictionary.Currency.CurrencyID | Implicit FK | Caller must join to resolve currency name/abbreviation |
| DepotID (output) | Billing.Depot.DepotID | Implicit FK | Caller must join to resolve gateway details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser | GRANT EXECUTE | Permission | Deposit processing service uses for customer deposit list queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositsByCid (procedure)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ NOLOCK - primary source; filtered by CID and PaymentStatusID, sorted and limited |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositUser (deposit service) | DB User | Calls to retrieve customer deposit lists by status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic ORDER BY via CASE | Design | Uses 4 CASE expressions to implement runtime sort selection; unmatched @SortColumn/@SortDir yields undefined order |
| No OPTION(RECOMPILE) | Design | Plan caching allowed; dynamic sort does not cause parameter sniffing issues as dramatically as conditional filters |
| WITH (NOLOCK) | Read hint | Allows dirty reads; acceptable for deposit list display use cases |
| No default for @Limit | Contract | Caller must always provide a row limit; no server-side default defined |

---

## 8. Sample Queries

### 8.1 Get approved deposits for a customer, newest first

```sql
EXEC Billing.GetDepositsByCid
    @CID = 12345,
    @PaymentStatus = 2,
    @Limit = 50,
    @SortColumn = 'PaymentDate',
    @SortDir = 'Desc';
```

### 8.2 Get pending deposits sorted by DepositID ascending

```sql
EXEC Billing.GetDepositsByCid
    @CID = 12345,
    @PaymentStatus = 1,
    @Limit = 100,
    @SortColumn = 'DepositID',
    @SortDir = 'Asc';
```

### 8.3 Inline equivalent for approved deposits

```sql
SELECT TOP 50 *
FROM Billing.Deposit WITH (NOLOCK)
WHERE CID = 12345
  AND PaymentStatusID = 2
ORDER BY PaymentDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 9/10, Logic: 6/10, Relationships: 4/10, Sources: 0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 46 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers (DepositUser service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositsByCid | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositsByCid.sql*
