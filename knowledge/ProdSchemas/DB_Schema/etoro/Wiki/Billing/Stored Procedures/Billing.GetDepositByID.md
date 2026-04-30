# Billing.GetDepositByID

> Returns the complete deposit record for a single DepositID, including all financial, routing, status, and metadata fields, enriched with FundingTypeID (from Billing.Funding) and ProtocolID (from Billing.Depot).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row keyed by DepositID, 47 columns |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositByID` is the primary full-detail deposit retrieval procedure. It returns virtually all columns from `Billing.Deposit` plus two enrichment columns derived from JOINs: `FundingTypeID` (from `Billing.Funding`, identifying the payment method type) and `ProtocolID` (from `Billing.Depot`, identifying the gateway protocol). This is the "fat read" of a deposit record, used when a calling service needs the complete picture of a deposit transaction.

Used by three service accounts: `DepositUser` (deposit processing service), `RoutingUser` (routing/payment routing service), and `AlertServiceUser_Etoro` (the alert/notification service). Each uses the full deposit data for different purposes: deposit processing needs financial and status fields, routing needs depot/MID/protocol info, and the alert service may need customer and status context for notification decisions.

The absence of `WITH (NOLOCK)` indicates the procedure reads committed data, appropriate for contexts where consistency matters (e.g., before performing status updates or routing decisions based on the deposit state).

---

## 2. Business Logic

### 2.1 Full-Detail Deposit Projection with Enrichment JOINs

**What**: The procedure joins three tables to produce a comprehensive view of a deposit including its payment method type and gateway protocol, without requiring the caller to do multiple round trips.

**Columns/Parameters Involved**: `@DepositID`, `FundingTypeID` (from Billing.Funding), `ProtocolID` (from Billing.Depot)

**Rules**:
- `INNER JOIN Billing.Funding ON FundingID` - guaranteed to exist (Billing.Deposit.FundingID is NOT NULL and FK-constrained); adds `FundingTypeID` to identify credit card vs. bank transfer vs. e-wallet
- `LEFT JOIN Billing.Depot ON DepotID` - optional; `DepotID` is nullable in some deposits; adds `ProtocolID` (NULL if depot not assigned)
- Returns `Amount` as-stored MONEY (dollars), unlike `Billing.GetDeposit` which multiplies by 100 for cents
- No `WITH (NOLOCK)` - reads committed data; appropriate for routing and processing decisions

### 2.2 Amount is in DOLLARS (not cents)

**What**: Unlike `Billing.GetDeposit` which converts to cents (x100), this procedure returns `Amount` in its stored MONEY format (dollars).

**Columns/Parameters Involved**: `Amount`

**Rules**:
- `Billing.GetDeposit` returns `CAST(Amount*100 AS INTEGER)` = cents for SecurePay
- `Billing.GetDepositByID` returns `Amount` directly = dollars as MONEY
- Callers (DepositUser, RoutingUser) work with dollars directly

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | Primary key of the deposit to retrieve. Maps to Billing.Deposit.DepositID (IDENTITY PK). |
| 2 | DepositID | INT | NO | - | CODE-BACKED | Primary key auto-incremented deposit identifier. IDENTITY(1,1). Referenced by History.Deposit, History.DepositAction, and all deposit-centric SPs. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID. FK to Customer.CustomerStatic. Identifies which eToro customer made the deposit. |
| 4 | FundingID | INT | NO | - | CODE-BACKED | Payment instrument used. FK to Billing.Funding. Identifies the specific card, bank account, or e-wallet record. |
| 5 | CurrencyID | INT | NO | - | CODE-BACKED | Currency of the deposit. FK to Dictionary.Currency (1=USD, 2=EUR, 3=GBP, etc.). Validated against Billing.DepotToCurrency at insert time. |
| 6 | PaymentStatusID | INT | NO | - | CODE-BACKED | Deposit processing status. FK to Dictionary.PaymentStatus. Key values: 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. See Billing.Deposit Section 2.1 for full state machine. |
| 7 | ManagerID | INT | YES | - | CODE-BACKED | Operations manager who last modified the deposit. 0=system/automated. FK to BackOffice.Manager. |
| 8 | RiskManagementStatusID | INT | YES | - | CODE-BACKED | Risk management pre-check result. FK to Dictionary.RiskManagementStatus. NULL=no risk check recorded. Values: 1=Success, 2=CardIsBlocked, 3=BinInBlackList, 4=MemberLimit, 5=FundingTypeLimit, 10=DeclinedBlackListCountry, 11=DeclinedHighRiskDeposit, 67=SiftWorkFlow, 69=BusinessRuleRisk, and 60+ more codes. |
| 9 | Amount | MONEY | NO | - | CODE-BACKED | Deposit amount in the deposit currency (CurrencyID). Stored in DOLLARS (MONEY type). Note: this differs from Billing.GetDeposit which returns Amount*100 as integer cents for the SecurePay integration. |
| 10 | ExchangeRate | dbo.dtPrice | YES | - | CODE-BACKED | Exchange rate from deposit currency to USD applied at processing time. Cannot be 0. Used in DepositProcess to compute USD credit: `Amount * ExchangeRate * 100` (cents). 1.0 for USD deposits. |
| 11 | PaymentDate | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the deposit record was created (deposit submission time, not approval time). |
| 12 | ModificationDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp of the most recent modification to this deposit record. Updated on every status change. |
| 13 | TransactionID | CHAR(6) | NO | - | CODE-BACKED | Short internal 6-character transaction reference (uppercase hex from GUID substring). Unique per customer. Not the external provider transaction ID (that is ExTransactionID). |
| 14 | IPAddress | NUMERIC(18,0) | YES | - | CODE-BACKED | Customer's IP address at deposit time, stored as 32-bit integer (IPv4 encoding). Used for geographic fraud detection. NULL for some backend-initiated deposits. |
| 15 | Approved | BIT | YES | - | CODE-BACKED | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Retained for backward compatibility. |
| 16 | Commission | MONEY | NO | - | NAME-INFERRED | Commission amount on this deposit. Defaults to 0. Not set by standard DepositAdd path; may be populated by commission-based flows or back-office. |
| 17 | PaymentData | XML | YES | - | CODE-BACKED | Provider-specific payment response XML. Schema varies by FundingType (validated via CLR.ParseXML against 'Deposit'+FundingType.Name schema). Contains auth codes, AVS results, provider transaction IDs, wire references, etc. |
| 18 | ClearingHouseEffectiveDate | DATETIME | YES | - | CODE-BACKED | Value date assigned by the clearing house (when funds are settled by the clearing institution). Set for wire/ACH deposits; NULL for instant payments. |
| 19 | OldPaymentID | INT | YES | - | NAME-INFERRED | Reference to a legacy system payment record. Used during historical data migration (PaymentStatusID=27=MigratedToDepositTable). NULL for all modern deposits. |
| 20 | IsFTD | BIT | NO | - | CODE-BACKED | Whether this was the customer's first-ever approved deposit (First Time Deposit). Set by DepositProcess if no prior IsFTD=1 exists for the CID AND DepositType.ApplyFtd=true. Drives marketing attribution (AppsFlyer, Pixel, RabbitMQ events). |
| 21 | ProcessorValueDate | DATETIME | YES | - | CODE-BACKED | Value date provided by the payment processor (when funds are credited on processor side). Mandatory for offline/wire deposits. NULL for instant deposits. |
| 22 | RefundVerificationCode | VARCHAR(50) | YES | - | NAME-INFERRED | Verification code for refund operations. Set by DepositUpdateRefundDetails. NULL for non-refunded deposits. |
| 23 | DepotID | INT | YES | - | CODE-BACKED | Routing depot used for this deposit. References Billing.Depot (acquirer/gateway configuration). Validated at insert via Billing.DepotToCurrency. NULL for some legacy deposits. |
| 24 | MatchStatusID | TINYINT | NO | - | CODE-BACKED | PSP reconciliation match status. 0=Unmatched (default, 99.9999%), 3=Matched (deposit matched to provider settlement record via PSPMatchToEtoro). |
| 25 | FunnelID | INT | YES | - | CODE-BACKED | Marketing funnel identifier for this deposit. FK to Dictionary.Funnel. Tracks which acquisition funnel the customer came through at deposit time. |
| 26 | Code | VARCHAR(50) | YES | - | NAME-INFERRED | Provider-specific code or reference (e.g., confirmation code, voucher code). Distinct from TransactionID (internal) and ExTransactionID (provider). NULL for most deposits. |
| 27 | ExTransactionID | VARCHAR(50) | YES | - | CODE-BACKED | Payment provider's external transaction ID. Set during DepositProcess. Used for provider-side reconciliation. Also accessible via Billing.GetDepositByExTransactionID. |
| 28 | CampaignCodeID | INT | YES | - | CODE-BACKED | Campaign associated with this deposit at the time of deposit. FK to BackOffice.Campaign. Links deposit revenue to acquisition campaigns for marketing ROI. NULL=no campaign. |
| 29 | BonusStatusID | INT | YES | - | CODE-BACKED | Status of any promotional bonus tied to this deposit. FK to Dictionary.BonusStatus. 0=New/no bonus, 1=Approved, 2=Declined, 3=Reverted. |
| 30 | BonusAmount | MONEY | YES | - | CODE-BACKED | Bonus amount credited or attempted with this deposit. NULL when no bonus applies. |
| 31 | BonusErrorCode | INT | YES | - | NAME-INFERRED | Error code from bonus processing system when bonus is declined. NULL when bonus succeeds or is not attempted. |
| 32 | SessionID | BIGINT | YES | - | CODE-BACKED | Application session ID at time of deposit. Passed from the cashier application session context. NULL for backend/non-browser deposits. |
| 33 | DepositTypeID | INT | YES | - | CODE-BACKED | Deposit type. FK to Dictionary.DepositType. Values: NULL=legacy, 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer (cannot be FTD), 5=RecurringInvestment. |
| 34 | StatusReasonID | INT | NO | - | CODE-BACKED | Additional reason sub-classification for the current payment status. 0=no specific reason. Provides granular decline/approval sub-reasons beyond PaymentStatusID. Updated by UpdateDepositStatusReasonID. |
| 35 | DRStatusID | INT | NO | - | CODE-BACKED | Delayed Revenue pipeline processing status. 0=Not processed (default, 94.5%), 1=DR Processed (4.5%), 3=DR In Progress, 2=DR Error. Used for regulatory revenue recognition reporting. |
| 36 | DRDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp when DR processing completed. NULL when DRStatusID=0. |
| 37 | ProtocolMIDSettingsID | INT | NO | - | CODE-BACKED | Merchant ID (MID) configuration profile used for this deposit. References Billing.ProtocolMIDSettings. 0=no specific MID assigned. Determines merchant account / acquirer config for this transaction. |
| 38 | ExchangeFee | INT | YES | - | CODE-BACKED | Exchange fee charged for currency conversion (basis points or provider-specific integer encoding). Complemented by ExchangeFeeInUSD and ExchangeFeePercentage. |
| 39 | BaseExchangeRate | dbo.dtPrice | YES | - | CODE-BACKED | Reference exchange rate before fee markup. Enables fee spread calculation: `ExchangeRate - BaseExchangeRate = spread charged to customer`. Used in BI deposit reports. |
| 40 | PaymentGeneration | INT | NO | - | CODE-BACKED | Payment processing infrastructure generation. 0=legacy (7.7%), 1=current generation (92%). Distinguishes deposits processed through new vs. legacy payment service. |
| 41 | ProcessRegulationID | INT | YES | - | CODE-BACKED | Regulatory entity that processed this deposit. 1=Cyprus/EU (~63%), 2=UK/FCA (~16%), 4=Australia (~2.5%), plus others. Determines applicable regulatory rules (leverage, reporting). |
| 42 | MerchantAccountID | INT | YES | - | CODE-BACKED | Merchant account legal entity used for regulatory routing. References Billing.MerchantAccountRouting. NULL=legacy/auto-routed. Populated by GetMerchantValuesByDeposit. |
| 43 | IsSetBalanceCompleted | BIT | YES | - | CODE-BACKED | Whether the SetBalance (account credit) operation triggered by this deposit has completed. Used to detect and recover from incomplete deposit processing flows. |
| 44 | RoutingReasonID | INT | YES | - | CODE-BACKED | Reason code for the routing decision (why this specific depot/MID was chosen). Values: 0-8; 31% NULL for legacy records. Values: 3=most common, 1=second. Used in routing analytics. |
| 45 | ExchangeFeeInUSD | MONEY | YES | - | CODE-BACKED | Exchange fee amount expressed in USD. Added PAYIL-8913/8926 for reconciliation and reporting. Enables direct fee comparison across currencies. |
| 46 | ExchangeFeePercentage | DECIMAL | YES | - | CODE-BACKED | Exchange fee as a percentage of the deposit amount. Added PAYIL-8913/8926. Enables percentage-based fee reporting alongside absolute USD fee. |
| 47 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type for this deposit's funding instrument. Joined from Billing.Funding.FundingTypeID ON FundingID. Values: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 17=ACH, etc. (from Dictionary.FundingType). |
| 48 | ProtocolID | INT | YES | - | CODE-BACKED | Gateway protocol used for processing. Joined from Billing.Depot.ProtocolID via LEFT JOIN on DepotID. NULL if DepotID is NULL on this deposit. Identifies the specific payment protocol/gateway integration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit.DepositID | Lookup | Primary key lookup - retrieves one full deposit row |
| FundingID | Billing.Funding.FundingID | INNER JOIN | Enriches result with FundingTypeID |
| DepotID | Billing.Depot.DepotID | LEFT JOIN | Enriches result with ProtocolID; nullable deposit may have no depot |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser | GRANT EXECUTE | Permission | Deposit processing service |
| RoutingUser | GRANT EXECUTE | Permission | Routing/payment routing service - uses routing fields (DepotID, ProtocolID, MerchantAccountID) |
| AlertServiceUser_Etoro | GRANT EXECUTE | Permission | Alert/notification service - uses customer and status fields for notification decisions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositByID (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
└── Billing.Depot (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ (committed) - primary source for all 46 deposit columns |
| Billing.Funding | Table | READ - INNER JOIN on FundingID to add FundingTypeID |
| Billing.Depot | Table | READ - LEFT JOIN on DepotID to add ProtocolID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositUser (deposit service) | DB User | Full deposit read for processing decisions |
| RoutingUser (routing service) | DB User | Reads routing/protocol/merchant fields for routing logic |
| AlertServiceUser_Etoro (alert service) | DB User | Reads deposit status and customer data for alert generation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No WITH (NOLOCK) | Design | Reads committed data - ensures consistency for routing and status-dependent decisions |
| INNER JOIN Billing.Funding | Constraint | Every deposit must have a valid FundingID (FK enforced); no deposits without a registered payment instrument |
| LEFT JOIN Billing.Depot | Design | Depot is nullable on deposit; LEFT JOIN ensures deposits without a depot are still returned |
| Amount in DOLLARS | Unit | Returns MONEY type directly (not x100 cents like Billing.GetDeposit) |

---

## 8. Sample Queries

### 8.1 Get full deposit details by ID

```sql
EXEC Billing.GetDepositByID @DepositID = 987654;
```

### 8.2 Inline equivalent with FundingTypeID and ProtocolID

```sql
SELECT
    d.DepositID, d.CID, d.FundingID, d.CurrencyID, d.PaymentStatusID,
    d.Amount, d.ExchangeRate, d.PaymentDate, d.ModificationDate,
    d.IsFTD, d.DepotID, d.ProtocolMIDSettingsID, d.ProcessRegulationID,
    f.FundingTypeID,
    dp.ProtocolID
FROM Billing.Deposit d WITH (NOLOCK)
INNER JOIN Billing.Funding f WITH (NOLOCK) ON d.FundingID = f.FundingID
LEFT JOIN Billing.Depot dp WITH (NOLOCK) ON d.DepotID = dp.DepotID
WHERE d.DepositID = 987654;
```

### 8.3 Get deposits with status labels and funding type names

```sql
SELECT
    d.DepositID,
    d.CID,
    d.Amount,
    ps.PaymentStatus,
    ft.FundingType
FROM Billing.Deposit d WITH (NOLOCK)
INNER JOIN Billing.Funding f WITH (NOLOCK) ON d.FundingID = f.FundingID
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK) ON f.FundingTypeID = ft.FundingTypeID
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON d.PaymentStatusID = ps.PaymentStatusID
WHERE d.DepositID = 987654;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Routing Service](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1101889655) | Confluence | Routing service architecture; confirms RoutingUser uses this SP to read routing-relevant deposit fields |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.9/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 45 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers (3 service accounts) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositByID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositByID.sql*
