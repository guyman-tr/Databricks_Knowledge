# Billing.GetDepositsByCidWithFundingType

> Returns a paginated, sortable list of deposits for a customer filtered by payment status AND funding type - an extension of GetDepositsByCid that narrows results to a specific payment method category (e.g., only CreditCard or only WireTransfer deposits).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP(@Limit) rows from Billing.Deposit for @CID with @PaymentStatus and @FundingType, sorted dynamically |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositsByCidWithFundingType` is a funding-type-filtered extension of `Billing.GetDepositsByCid`. It adds a sixth parameter `@FundingType` that restricts results to deposits processed through depots of a specific funding type (e.g., CreditCard=1, WireTransfer=2, PayPal=3).

The funding type filter is applied via an INNER JOIN to `Billing.Depot` (the payment gateway registry) on `DepotID`, checking `Depot.FundingTypeID = @FundingType`. This means the filter is at the depot level (payment gateway category), not at the specific payment instrument level (individual card or account).

Like its sibling `GetDepositsByCid`, it returns all 41 columns from `Billing.Deposit` with the same dynamic sort pattern. It is granted to `DepositUser` (deposit processing service account).

---

## 2. Business Logic

### 2.1 Funding-Type-Filtered Deposit Retrieval

**What**: Returns deposits for a customer matching a specific payment status AND processed through a depot of a specific funding type.

**Columns/Parameters Involved**: `@CID`, `@PaymentStatus`, `@FundingType`, `@Limit`

**Rules**:
- `WHERE d.CID = @CID AND d.PaymentStatusID = @PaymentStatus` - same customer and status filter as GetDepositsByCid
- `INNER JOIN Billing.Depot ON depot.DepotID = d.DepotID AND depot.FundingTypeID = @FundingType` - restricts to deposits processed via a depot of the specified type
- Depot.FundingTypeID values: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 17=ACH, etc.
- INNER JOIN means deposits with NULL DepotID or deposits whose depot has a different FundingTypeID are excluded
- `WITH (NOLOCK)` on both tables - dirty reads for performance
- `SELECT TOP (@Limit)` - caller-specified row cap

**Key distinction from GetDepositsByCid**: The funding type comes from `Billing.Depot.FundingTypeID` (the gateway's category), not from `Billing.Funding.FundingTypeID` (the specific payment instrument). In most cases these align, but edge cases may differ.

### 2.2 Dynamic Sorting

**What**: Same 4-way dynamic sort as GetDepositsByCid, supporting DepositID and PaymentDate in Asc/Desc directions.

**Rules**:
- Identical CASE-based ORDER BY pattern to GetDepositsByCid
- Unrecognized @SortColumn/@SortDir combinations yield undefined sort order

**Diagram**:
```
@CID + @PaymentStatus + @FundingType
  |
  +-> Billing.Deposit WHERE CID=@CID AND PaymentStatusID=@PaymentStatus
  |
  INNER JOIN Billing.Depot WHERE DepotID=d.DepotID AND FundingTypeID=@FundingType
  |
  v
TOP(@Limit) deposit rows (all 41 columns from Billing.Deposit)
  -> sorted by @SortColumn/@SortDir
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters deposits to this customer. Maps to Billing.Deposit.CID. |
| 2 | @PaymentStatus | INT | NO | - | CODE-BACKED | Payment status filter. Exact match against Billing.Deposit.PaymentStatusID. Common: 2=Approved, 1=Pending. |
| 3 | @Limit | INT | NO | - | CODE-BACKED | Maximum rows to return. Applied as SELECT TOP (@Limit). |
| 4 | @SortColumn | VARCHAR(20) | NO | - | CODE-BACKED | Column to sort by. Supported: 'DepositID', 'PaymentDate'. |
| 5 | @SortDir | VARCHAR(10) | NO | - | CODE-BACKED | Sort direction. Supported: 'Asc', 'Desc'. |
| 6 | @FundingType | INT | NO | - | CODE-BACKED | Funding type filter. Matched against Billing.Depot.FundingTypeID (gateway category). 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 17=ACH. |
| 7 | DepositID (output) | INT | NO | - | CODE-BACKED | Primary key of the deposit. |
| 8 | CID (output) | INT | NO | - | CODE-BACKED | Internal customer ID. Always equals @CID. |
| 9 | FundingID (output) | INT | NO | - | CODE-BACKED | FK to Billing.Funding - specific payment instrument used. |
| 10 | CurrencyID (output) | INT | NO | - | CODE-BACKED | FK to Dictionary.Currency - currency of the deposit amount. |
| 11 | PaymentStatusID (output) | INT | NO | - | CODE-BACKED | Deposit status. Always equals @PaymentStatus. |
| 12 | ManagerID (output) | INT | YES | - | CODE-BACKED | Back-office agent who last modified this deposit. NULL for system-processed. |
| 13 | RiskManagementStatusID (output) | INT | YES | - | CODE-BACKED | Risk/fraud review status. |
| 14 | Amount (output) | MONEY | NO | - | CODE-BACKED | Deposit amount in deposit currency (dollars). Multiply by ExchangeRate for USD. |
| 15 | ExchangeRate (output) | dbo.dtPrice | YES | - | CODE-BACKED | Exchange rate from deposit currency to USD at processing time. |
| 16 | PaymentDate (output) | DATETIME | NO | - | CODE-BACKED | UTC timestamp of deposit submission. |
| 17 | ModificationDate (output) | DATETIME | YES | - | CODE-BACKED | UTC timestamp of last status change. |
| 18 | TransactionID (output) | VARCHAR | YES | - | CODE-BACKED | Payment gateway transaction reference. |
| 19 | IPAddress (output) | VARCHAR | YES | - | CODE-BACKED | Client IP at deposit time. Fraud detection. |
| 20 | Approved (output) | BIT | YES | - | CODE-BACKED | Legacy approval flag. |
| 21 | Commission (output) | MONEY | YES | - | CODE-BACKED | Commission charged on this deposit. |
| 22 | ClearingHouseEffectiveDate (output) | DATETIME | YES | - | CODE-BACKED | Clearing house settlement date. |
| 23 | OldPaymentID (output) | INT | YES | - | CODE-BACKED | Previous payment record reference for re-attempts. |
| 24 | IsFTD (output) | BIT | NO | - | CODE-BACKED | First-time deposit flag. 1=this is the customer's first approved deposit. |
| 25 | ProcessorValueDate (output) | DATETIME | YES | - | CODE-BACKED | Value date from payment processor. |
| 26 | RefundVerificationCode (output) | VARCHAR | YES | - | CODE-BACKED | Refund authorization verification code. |
| 27 | DepotID (output) | INT | YES | - | CODE-BACKED | FK to Billing.Depot - the gateway used. The JOIN ensures this depot has FundingTypeID=@FundingType. |
| 28 | MatchStatusID (output) | INT | YES | - | CODE-BACKED | Wire transfer reconciliation status. |
| 29 | FunnelID (output) | INT | YES | - | CODE-BACKED | Marketing funnel at deposit time. |
| 30 | Code (output) | VARCHAR | YES | - | CODE-BACKED | Internal deposit classification code. |
| 31 | ExTransactionID (output) | VARCHAR | YES | - | CODE-BACKED | External/gateway transaction ID. |
| 32 | CampaignCodeID (output) | INT | YES | - | CODE-BACKED | Marketing campaign associated with this deposit. |
| 33 | BonusStatusID (output) | INT | YES | - | CODE-BACKED | Status of bonus processing. |
| 34 | BonusAmount (output) | MONEY | YES | - | CODE-BACKED | Bonus credited alongside deposit. |
| 35 | BonusErrorCode (output) | INT | YES | - | CODE-BACKED | Bonus processing error code. |
| 36 | SessionID (output) | VARCHAR | YES | - | CODE-BACKED | Client session at deposit submission. |
| 37 | DepositTypeID (output) | INT | YES | - | CODE-BACKED | Type of deposit (standard, bonus, credit). |
| 38 | StatusReasonID (output) | INT | YES | - | CODE-BACKED | Reason code for current status. |
| 39 | DRStatusID (output) | INT | YES | - | CODE-BACKED | Dispute/chargeback resolution status. |
| 40 | DRDate (output) | DATETIME | YES | - | CODE-BACKED | Date of dispute resolution. |
| 41 | ProtocolMIDSettingsID (output) | INT | YES | - | CODE-BACKED | FK to Billing.DepotMIDSettings - MID configuration used. |
| 42 | ExchangeFee (output) | MONEY | YES | - | CODE-BACKED | Currency exchange fee. |
| 43 | BaseExchangeRate (output) | dbo.dtPrice | YES | - | CODE-BACKED | Base exchange rate before markup. |
| 44 | ProcessRegulationID (output) | INT | YES | - | CODE-BACKED | Regulatory regime for this deposit. |
| 45 | PaymentGeneration (output) | INT | YES | - | CODE-BACKED | Payment processing generation/version. |
| 46 | ExchangeFeePercentage (output) | DECIMAL | YES | - | CODE-BACKED | Exchange fee as percentage of deposit. |
| 47 | PaymentData (output) | XML/VARCHAR | YES | - | CODE-BACKED | Additional payment-method-specific structured data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit.CID | Lookup | Filters to specified customer |
| @PaymentStatus | Billing.Deposit.PaymentStatusID | Filter | Restricts to exact status |
| @FundingType | Billing.Depot.FundingTypeID | Filter | Restricts to deposits via depots of this funding type |
| d.DepotID | Billing.Depot.DepotID | INNER JOIN | Links deposit to its gateway for FundingType filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser | GRANT EXECUTE | Permission | Deposit service uses for funding-type-scoped deposit list queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositsByCidWithFundingType (procedure)
├── Billing.Deposit (table)
└── Billing.Depot (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ NOLOCK - primary source; filtered by CID and PaymentStatusID |
| Billing.Depot | Table | READ NOLOCK - INNER JOIN to filter by FundingTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositUser (deposit service) | DB User | Calls to retrieve funding-type-filtered deposit lists for a customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN on Billing.Depot | Design | Excludes deposits with NULL DepotID or with a depot of a different funding type; callers must be aware that not all deposits match every funding type |
| FundingType via Depot, not Funding | Design | @FundingType filters Depot.FundingTypeID (gateway category), not Funding.FundingTypeID (payment instrument type); these usually align but are not identical |
| Dynamic ORDER BY via CASE | Design | Same 4-way CASE pattern as GetDepositsByCid; unmatched parameters yield undefined sort |
| WITH (NOLOCK) | Read hint | Applied to both Deposit and Depot; dirty reads acceptable for list views |

---

## 8. Sample Queries

### 8.1 Get approved credit card deposits for a customer

```sql
EXEC Billing.GetDepositsByCidWithFundingType
    @CID = 12345,
    @PaymentStatus = 2,
    @Limit = 50,
    @SortColumn = 'PaymentDate',
    @SortDir = 'Desc',
    @FundingType = 1;  -- CreditCard
```

### 8.2 Get approved wire transfer deposits

```sql
EXEC Billing.GetDepositsByCidWithFundingType
    @CID = 12345,
    @PaymentStatus = 2,
    @Limit = 100,
    @SortColumn = 'DepositID',
    @SortDir = 'Asc',
    @FundingType = 2;  -- WireTransfer
```

### 8.3 Inline equivalent

```sql
SELECT TOP 50 d.*
FROM Billing.Deposit d WITH (NOLOCK)
INNER JOIN Billing.Depot depot WITH (NOLOCK) ON depot.DepotID = d.DepotID
WHERE d.CID = 12345
  AND d.PaymentStatusID = 2
  AND depot.FundingTypeID = 1
ORDER BY d.PaymentDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.1/10 (Elements: 9/10, Logic: 6/10, Relationships: 4/10, Sources: 0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 47 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers (DepositUser service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositsByCidWithFundingType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositsByCidWithFundingType.sql*
