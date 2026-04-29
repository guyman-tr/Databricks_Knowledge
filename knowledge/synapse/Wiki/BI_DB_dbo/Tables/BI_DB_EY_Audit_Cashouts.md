# BI_DB_dbo.BI_DB_EY_Audit_Cashouts

> Daily EY audit table for cashout, refund, chargeback, and reverse-cashout transactions — 6.8M rows from 2023-01-01 to present. Each row represents one processed withdrawal event enriched with customer regulation, payment method, depot, card type, bank name, and exchange rate metadata. Populated by SP_EY_Audit_Deposit_Cashouts from Fact_CustomerAction (cashout actions) joined with Fact_BillingWithdraw (billing metadata) and Fact_SnapshotCustomer (regulation snapshot).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Row Count** | ~6.8M |
| **Date Range** | 2023-01-01 to present |
| **Production Sources** | DWH_dbo.Fact_CustomerAction (cashout events), DWH_dbo.Fact_BillingWithdraw (billing metadata), DWH_dbo.Fact_SnapshotCustomer (customer regulation), BI_DB_dbo.BI_DB_DepositWithdrawFee (exchange rates) |
| **Writer SP** | SP_EY_Audit_Deposit_Cashouts (Author: Guy Manova, 2023-06-09) |
| **Refresh** | Daily (DELETE + INSERT by DateID, with auto-backfill for missing dates) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not exported to Unity Catalog (no generic pipeline mapping found) |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_EY_Audit_Cashouts` is a daily audit-grade cashout transaction table built for EY (Ernst & Young) regulatory audit requirements. It captures every cashout-related event from the eToro platform — standard cashouts, refunds, chargebacks, and reverse cashouts — enriched with the customer's regulatory jurisdiction, payment method, depot routing, card type, bank name, and exchange rate details at the time of the event.

The table sources its core event data from `DWH_dbo.Fact_CustomerAction` (ActionTypeID IN 8, 11, 12, 13, 37 where WithdrawID IS NOT NULL for refund/chargeback types), billing metadata from `DWH_dbo.Fact_BillingWithdraw` (only processed cashouts with CashoutStatusID_Funding=3), customer regulation from `DWH_dbo.Fact_SnapshotCustomer` (point-in-time regulation via Dim_Range date-range matching), and exchange rate data from `BI_DB_dbo.BI_DB_DepositWithdrawFee`.

The SP uses a DELETE+INSERT pattern by DateID. A 2024-07-03 enhancement added auto-backfill logic: if missing dates are detected between the table's MAX(DateID) and the target date, the SP recursively calls itself for each gap day before processing the current date. This is the cashout counterpart to `BI_DB_EY_Audit_Deposits` — both are populated by the same SP in a single execution.

As of sampling: ~6.8M total rows. In 2025 alone: ~2.2M rows, dominated by standard Cashout (95.3%), with Reverse cashout (4.5%), Refund (0.1%), and Chargeback (0.1%).

---

## 2. Business Logic

### 2.1 ActionType — Transaction Classification

**What**: Each row is classified by ActionType string, derived from the Fact_CustomerAction ActionTypeID.

**Columns Involved**: `ActionType`, mapped from `Fact_CustomerAction.ActionTypeID`

**Rules**:
- `Cashout` — ActionTypeID=8 (standard withdrawal, ~95% of rows)
- `Reverse cashout` — ActionTypeID=37 (cashout reversal, ~4.5%)
- `Refund` — ActionTypeID=12 (deposit refund processed as withdrawal)
- `Chargeback` — ActionTypeID=11 (disputed deposit reversal)
- ActionTypeIDs 11, 12, 13, 37 only appear in the cashout table when `WithdrawID IS NOT NULL`

### 2.2 Payment Metadata Resolution

**What**: Billing metadata (PaymentMethod, Depot, CardType, BankName) is resolved from Fact_BillingWithdraw for the specific WithdrawPaymentID.

**Columns Involved**: `PaymentMethod`, `Depot`, `BankNameAsString`, `CardType`

**Rules**:
- Only Fact_BillingWithdraw rows with `CashoutStatusID_Funding = 3` (Processed) are included
- PaymentMethod is resolved via `Dim_BillingDepot.FundingTypeID → Dim_FundingType.Name` (note: joins through depot, not directly from withdraw)
- BankNameAsString uses COALESCE logic: `CASE WHEN ClientBankNameAsString IS NULL THEN BankNameAsString ELSE ClientBankNameAsString END` from Fact_BillingWithdraw
- CardType from `Dim_CardType.CarTypeName` joined on `Fact_BillingWithdraw.CardTypeIDAsInteger`
- Columns may be NULL/empty when no matching Fact_BillingWithdraw row exists for the WithdrawPaymentID

### 2.3 Customer Regulation Snapshot

**What**: The customer's regulation at the time of the event is resolved from Fact_SnapshotCustomer using point-in-time date-range matching.

**Columns Involved**: `Regulation`, `IsCreditReportValidCB`

**Rules**:
- Fact_SnapshotCustomer is joined via `RealCID` with date-range filtering through `Dim_Range` (`DateID BETWEEN FromDateID AND ToDateID`)
- Regulation is resolved to `Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID`
- IsCreditReportValidCB is a passthrough from the snapshot — 1 if customer eligible for credit report validation

### 2.4 Exchange Rate Data

**What**: BaseExchangeRate and ExchangeFee are sourced from BI_DB_DepositWithdrawFee for the matching withdrawal transaction.

**Columns Involved**: `BaseExchangeRate`, `ExchangeFee`

**Rules**:
- Matched via WithdrawPaymentID to BI_DB_DepositWithdrawFee.TransactionID (after stripping 'W' suffix)
- Only 'Withdraw' TransactionType rows are used
- Stored as varchar(50) despite numeric source — preserves original precision as string

### 2.5 Auto-Backfill Logic

**What**: The SP detects and fills missing date gaps before processing the current date.

**Rules**:
- Compares MAX(DateID) from `BI_DB_EY_Audit_Deposits` against the target @Date
- If gaps exist, recursively calls itself for each missing day in chronological order
- Prevents data gaps in the audit trail from missed ETL runs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP storage (no clustered index). This is appropriate for an audit table that is primarily loaded daily and queried in full-date-range scans. There is no distribution key optimization — all queries require data movement across distributions.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All cashouts for a date | `WHERE DateID = @dateId` |
| Cashouts by regulation | `WHERE Regulation = 'FCA' AND DateID BETWEEN @start AND @end` |
| Refunds and chargebacks only | `WHERE ActionType IN ('Refund', 'Chargeback')` |
| Cashouts for a specific customer | `WHERE RealCID = @cid` |
| Exchange rate analysis | `WHERE BaseExchangeRate IS NOT NULL AND BaseExchangeRate <> ''` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_EY_Audit_Deposits | ON DateID (same date range) | Combined deposit + cashout audit view |
| DWH_dbo.Dim_Customer | ON RealCID | Additional customer attributes beyond ExternalID |

### 3.4 Gotchas

- **BaseExchangeRate and ExchangeFee are varchar(50)**, not numeric — cast before arithmetic operations
- **PaymentMethod may be NULL/empty** when no matching Fact_BillingWithdraw row exists (LEFT JOIN)
- **BankNameAsString may be empty string** (not NULL) — check for both `IS NULL` and `= ''`
- **CardType is NULL/empty for non-card payment methods** (eToroMoney, PayPal, WireTransfer without card)
- **ActionType='Cashout' for ActionTypeID=13** is excluded — ActionTypeID=13 rows only appear when they have a WithdrawID (refund-related)
- **Date range starts 2023-01-01** — no historical data before that date
- **Auto-backfill checks BI_DB_EY_Audit_Deposits** (the deposit table), not this cashout table, for gap detection — a quirk of the SP logic
- **Sibling table**: BI_DB_EY_Audit_Deposits is populated by the same SP in the same execution

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (passthrough or dim-lookup) |
| Tier 2 | Derived from SP ETL code or upstream ETL-computed column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | DateID | int | NO | Business date of the cashout event as integer YYYYMMDD. Derived from SP @Date parameter. Used for daily DELETE+INSERT partitioning. (Tier 2 — SP_EY_Audit_Deposit_Cashouts) |
| 3 | Date | date | NO | Calendar date of the cashout event. Direct passthrough of SP @Date parameter. (Tier 2 — SP_EY_Audit_Deposit_Cashouts) |
| 4 | ExternalID | decimal(38,0) | YES | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | ActionType | varchar(100) | YES | Transaction type: 'Cashout' (ActionTypeID=8), 'Chargeback' (11), 'Refund' (12), 'Reverse cashout' (37). Hardcoded string for cashouts; Dim_ActionType.Name for refund/chargeback types. (Tier 2 — Fact_CustomerAction / Dim_ActionType) |
| 6 | WithdrawID | int | NO | Withdrawal request ID for cashout events. 0 for non-cashout events. (Tier 1 — History.Credit) |
| 7 | WithdrawPaymentID | int | NO | Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL. (Tier 1 — History.Credit) |
| 8 | Occurred | datetime | NO | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 9 | Amount | decimal(11,2) | NO | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). DWH note: in this cashout-specific table, Amount represents the cashout/refund/chargeback amount for ActionTypeIDs 8, 11, 12, 13, 37 sourced from History.Credit via Fact_CustomerAction. (Tier 1 — Trade.PositionTbl) |
| 10 | PaymentMethod | varchar(50) | YES | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Resolved via Dim_BillingDepot.FundingTypeID → Dim_FundingType.Name. NULL when no matching billing withdraw row exists. (Tier 1 — Dictionary.FundingType) |
| 11 | Depot | varchar(50) | YES | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Resolved from Fact_BillingWithdraw.DepotID. NULL when no matching billing withdraw row exists. (Tier 1 — Billing.Depot) |
| 12 | BankNameAsString | nvarchar(max) | YES | Client's bank name from Fact_BillingWithdraw XML-extracted fields. CASE logic: prefers ClientBankNameAsString over BankNameAsString when both available. NULL or empty for non-bank payment methods. (Tier 2 — Fact_BillingWithdraw) |
| 13 | CardType | varchar(50) | YES | Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from Name in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. Resolved from Fact_BillingWithdraw.CardTypeIDAsInteger via Dim_CardType.CarTypeName. NULL for non-card payment methods. (Tier 1 — Dictionary.CardType) |
| 14 | Regulation | varchar(50) | YES | Short code for the customer's regulatory jurisdiction at the time of the event. Values: CySEC, FCA, FSA Seychelles, FinCEN+FINRA, ASIC & GAML, FSRA, BVI, ASIC, MAS, eToroUS, FinCEN. Resolved from Fact_SnapshotCustomer.RegulationID via Dim_Regulation.Name. (Tier 1 — Dictionary.Regulation) |
| 15 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer from PlayerLevelID, AccountTypeID, LabelID, CountryID. Passthrough from point-in-time snapshot. (Tier 1 — Fact_SnapshotCustomer) |
| 16 | BaseExchangeRate | varchar(50) | YES | Base FX rate from state. Passthrough from BI_DB_DepositWithdrawFee, originally sourced from Fact_Cashout_State.BaseExchangeRate. Stored as varchar despite numeric origin. NULL when no matching DepositWithdrawFee row exists. (Tier 1 — BI_DB_DepositWithdrawFee) |
| 17 | ExchangeFee | varchar(50) | YES | Exchange fee from state. Passthrough from BI_DB_DepositWithdrawFee, originally sourced from Fact_Cashout_State.ExchangeFee. Stored as varchar despite numeric origin. NULL when no matching DepositWithdrawFee row exists. (Tier 1 — BI_DB_DepositWithdrawFee) |
| 18 | VerificationCode | varchar(50) | YES | Verification code supplied or received during withdrawal processing. Passthrough from Fact_BillingWithdraw. (Tier 1 — Billing.WithdrawToFunding) |
| 19 | UpdateDate | date | YES | ETL load timestamp. Set to GETDATE() at SP execution time. Not a business date. (Tier 2 — SP_EY_Audit_Deposit_Cashouts) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|---------------|---------------|-----------|
| RealCID | Dim_Customer | RealCID | Passthrough (via Fact_CustomerAction JOIN) |
| DateID | SP parameter | @Date | CAST(CONVERT(VARCHAR(10), @Date, 112) AS INT) |
| Date | SP parameter | @Date | Passthrough |
| ExternalID | Dim_Customer | ExternalID | Passthrough |
| ActionType | Fact_CustomerAction / Dim_ActionType | ActionTypeID / Name | 'Cashout' for ID=8; Dim_ActionType.Name for 11,12,13,37 |
| WithdrawID | Fact_CustomerAction | WithdrawID | Passthrough |
| WithdrawPaymentID | Fact_CustomerAction | WithdrawPaymentID | Passthrough |
| Occurred | Fact_CustomerAction | Occurred | Passthrough |
| Amount | Fact_CustomerAction | Amount | Passthrough |
| PaymentMethod | Dim_FundingType | Name | Dim-lookup via Dim_BillingDepot.FundingTypeID |
| Depot | Dim_BillingDepot | Name | Dim-lookup via Fact_BillingWithdraw.DepotID |
| BankNameAsString | Fact_BillingWithdraw | ClientBankNameAsString / BankNameAsString | COALESCE-style CASE |
| CardType | Dim_CardType | CarTypeName | Dim-lookup via Fact_BillingWithdraw.CardTypeIDAsInteger |
| Regulation | Dim_Regulation | Name | Dim-lookup via Fact_SnapshotCustomer.RegulationID |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough (date-range filtered) |
| BaseExchangeRate | BI_DB_DepositWithdrawFee | BaseExchangeRate | Passthrough via #pips temp table |
| ExchangeFee | BI_DB_DepositWithdrawFee | ExchangeFee | Passthrough via #pips temp table |
| VerificationCode | Fact_BillingWithdraw | VerificationCode | Passthrough |
| UpdateDate | — | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID IN 8,11,12,13,37)
  + DWH_dbo.Fact_BillingWithdraw (CashoutStatusID_Funding=3, ModificationDateID=@DateID)
  + DWH_dbo.Fact_SnapshotCustomer (date-range filtered via Dim_Range)
  + BI_DB_dbo.BI_DB_DepositWithdrawFee (TransactionType='Withdraw')
  + DWH_dbo.Dim_Customer (ExternalID)
  + DWH_dbo.Dim_Regulation (Name)
  + DWH_dbo.Dim_BillingDepot (Name)
  + DWH_dbo.Dim_FundingType (Name)
  + DWH_dbo.Dim_CardType (CarTypeName)
  + DWH_dbo.Dim_ActionType (Name, for refund/chargeback types)
  |
  v [SP_EY_Audit_Deposit_Cashouts @Date]
    1. Auto-backfill: detect gaps from MAX(DateID) in BI_DB_EY_Audit_Deposits → recursive call per gap day
    2. Build #mimo from Fact_CustomerAction (cashout + refund ActionTypeIDs)
    3. Build #pips from BI_DB_DepositWithdrawFee (exchange rate data)
    4. Build #metaCO from Fact_BillingWithdraw + Dim_BillingDepot + Dim_FundingType + Dim_CardType + #pips
    5. Build #COsWithRefunds (UNION: cashout rows + refund/chargeback rows with WithdrawID)
    6. Build #COs: JOIN #COsWithRefunds + Fact_SnapshotCustomer + Dim_Range + Dim_Regulation + #metaCO
    7. Build #COFinal: JOIN #COs + Dim_Customer
    8. DELETE BI_DB_EY_Audit_Cashouts WHERE DateID = @DateID
    9. INSERT into BI_DB_EY_Audit_Cashouts from #COFinal + GETDATE()
  |
  v
BI_DB_dbo.BI_DB_EY_Audit_Cashouts (~6.8M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer identifier |
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | Withdrawal request |
| WithdrawPaymentID | DWH_dbo.Fact_BillingWithdraw | Payment execution leg |

### 6.2 Referenced By (other objects point to this)

No downstream consumers identified — this is a terminal audit/reporting table for EY regulatory audit.

---

## 7. Sample Queries

### 7.1 Daily cashout summary by regulation

```sql
SELECT
    DateID,
    Regulation,
    ActionType,
    COUNT(*) AS TxnCount,
    SUM(Amount) AS TotalAmount
FROM [BI_DB_dbo].[BI_DB_EY_Audit_Cashouts]
WHERE DateID BETWEEN 20250401 AND 20250430
GROUP BY DateID, Regulation, ActionType
ORDER BY DateID, TotalAmount DESC;
```

### 7.2 Cashouts by payment method for a specific customer

```sql
SELECT
    DateID,
    [Date],
    ActionType,
    Amount,
    PaymentMethod,
    Depot,
    CardType,
    BankNameAsString,
    VerificationCode
FROM [BI_DB_dbo].[BI_DB_EY_Audit_Cashouts]
WHERE RealCID = 12345678
ORDER BY [Date] DESC;
```

### 7.3 Exchange rate analysis for wire transfers

```sql
SELECT
    DateID,
    RealCID,
    Amount,
    CAST(BaseExchangeRate AS numeric(38,8)) AS BaseRate,
    CAST(ExchangeFee AS numeric(38,8)) AS ExFee,
    Regulation
FROM [BI_DB_dbo].[BI_DB_EY_Audit_Cashouts]
WHERE PaymentMethod = 'WireTransfer'
  AND BaseExchangeRate IS NOT NULL
  AND BaseExchangeRate <> ''
  AND DateID >= 20250101
ORDER BY DateID DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (regen harness mode — Jira scan skipped).

---

*Generated: 2026-04-29 | Quality: 9.0/10 | Phases: 12/14*
*Tiers: 11 T1, 8 T2, 0 T3, 0 T4, 0 T5 | Elements: 19/19, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_EY_Audit_Cashouts | Type: Table | Production Source: DWH_dbo.Fact_CustomerAction + Fact_BillingWithdraw + Fact_SnapshotCustomer*
