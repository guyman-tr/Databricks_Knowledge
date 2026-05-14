# DWH_dbo.Fact_Cashout_Rollback

> Fact table recording cashout (withdrawal) rollback events — each row is a reversed payment leg where funds were returned to the customer's eToro balance after a processed withdrawal was rolled back.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `Billing.CashoutRollbackTracking` (via `Billing.GetRollbackedPaymentOrdersReport` SP) |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Fact_Cashout_Rollback` captures every withdrawal rollback event on the eToro platform. When a processed withdrawal (cashout) needs to be reversed — due to a returned bank transfer, a chargeback, a payment system error, or a manual operation — a rollback is recorded in the production `Billing.CashoutRollbackTracking` table. This DWH fact table denormalizes the rollback event with withdrawal details, payment instrument metadata, and merchant routing information into a single analytical row.

The data originates from the production stored procedure `Billing.GetRollbackedPaymentOrdersReport`, which joins `Billing.CashoutRollbackTracking` with 15+ tables including `Billing.WithdrawToFunding` (payment leg details), `Billing.Withdraw` (withdrawal request), `Dictionary.Currency`, `Dictionary.FundingType`, `Dictionary.CardType`, `Billing.Depot`, and `Dictionary.Regulation`. A DWH wrapper procedure `DWH.Billing_GetRollbackedPaymentOrdersReport` strips spaces from column names and feeds the result to the data lake via ADF/Generic Pipeline. Source: `Billing.CashoutRollbackTracking` (see upstream wiki: Billing/Tables/Billing.CashoutRollbackTracking.md).

The ETL procedure `DWH_dbo.SP_Fact_Cashout_Rollback_DL_To_Synapse` loads data via a daily delete-insert pattern keyed on `ModificationDateID`. It accepts a `@dt` date parameter, deletes all rows for that date, and re-inserts from the staging table `DWH_staging.etoro_Billing_GetRollbackedPaymentOrdersReport` filtered on `StatusModificationTime`. The only ETL-computed columns are `ModificationDateID` (integer date key from `StatusModificationTime`) and `UpdateDate` (GETDATE()).

---

## 2. Business Logic

### 2.1 Partial Rollback Tracking

**What**: Each row represents one rollback event — a reversal of a processed payment leg. Multiple rollback events can occur for the same withdrawal (e.g., partial reversals, corrections).

**Columns Involved**: `RollbackAmount`, `RollbackUSDAmount`, `ExchangeRate`, `RollbackReason`, `WithdrawprocessingID`

**Rules**:
- `RollbackAmount` is the incremental amount reversed in the original transaction currency for this specific event
- `RollbackUSDAmount` is the same amount converted to USD. Negative values indicate a rollback correction (reversal of a previous rollback)
- Multiple rows can share the same `WithdrawprocessingID` (same payment leg rolled back multiple times)
- `RollbackReason` encodes the cause: 0=default/unknown, 1=standard rollback, 3=dominant reason (83% of events), 4=correction events

**Diagram**:
```
Withdrawal (WithdrawID)
  +--> PaymentLeg (WithdrawprocessingID)
         Row1: RollbackUSDAmount=+875  (partial rollback)
         Row2: RollbackUSDAmount=-875  (correction — reversal of Row1)
         Row3: RollbackUSDAmount=+100  (new partial rollback)
```

### 2.2 Exchange Rate at Rollback Time

**What**: The exchange rate captured is the rate applicable at the time of rollback, which may differ from the original withdrawal exchange rate.

**Columns Involved**: `ExchangeRate`, `RollbackAmount`, `RollbackUSDAmount`, `Currency`

**Rules**:
- `ExchangeRate` is passed by the rollback initiator at the time of the rollback event
- `Currency` is the processing currency abbreviation from `Dictionary.Currency`, resolved via the payment leg's `ProcessCurrencyID`
- The relationship `RollbackAmount × ExchangeRate ≈ RollbackUSDAmount` holds (subject to rounding)
- `FeeInPIPs` records the exchange fee from the original payment leg (not from the rollback)

### 2.3 Payment Routing and Merchant Identification

**What**: Each rollback row captures the full payment routing context — which gateway (Depot), merchant (MID/MIDName), and payment method (FundingMethod) were involved.

**Columns Involved**: `Depot`, `MID`, `MIDName`, `FundingMethod`, `Brand`, `Regulation`, `PaymentDetails`

**Rules**:
- `MIDName` and `MID` are resolved via complex business logic that varies by DepotID range and FundingTypeID — the production SP uses a multi-branch CASE statement with calls to `GetMerchantDetails` and `GetMerchantDetailsForOneAccountByDepotOnly`
- `PaymentDetails` is extracted from XML payment data and varies by payment method: bank transfers include BSB + address, PayPal includes email, eToroMoney includes AccountID + PurseID, Trustly includes IBAN + BIC
- `Regulation` is the customer's regulatory jurisdiction (e.g., CySEC, FCA, ASIC), resolved from `BackOffice.Customer.RegulationID`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `CID ASC`. ROUND_ROBIN means data is evenly distributed across all distributions without regard to any column value — this is suitable for a relatively small fact table without dominant join patterns. Always include `CID` in WHERE clauses for optimal index seek performance. For date-range queries, filter on `ModificationDateID` (integer YYYYMMDD format) rather than `StatusModificationTime` for cleaner partition-like filtering.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All rollback events for a customer | `WHERE CID = @cid ORDER BY StatusModificationTime DESC` — uses clustered index |
| Rollback volume by date range | `WHERE ModificationDateID BETWEEN @start AND @end` — use integer date keys |
| Total rollback amount per withdrawal | `GROUP BY WithdrawID, SUM(RollbackUSDAmount)` — nets out corrections |
| Rollbacks by payment method | `GROUP BY FundingMethod` — pre-resolved human-readable name |
| Rollbacks by regulation | `WHERE Regulation = 'CySEC'` — pre-resolved regulation name |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_Cashout_State | ON CID and WithdrawID | Correlate rollbacks with original cashout processing events |
| DWH_dbo.Fact_BillingWithdraw | ON WithdrawID | Join to the full withdrawal request fact for additional context |
| DWH_dbo.Dim_Customer | ON CID | Resolve customer demographics, regulation, label |
| DWH_dbo.Dim_Currency | ON Currency | Join for additional currency attributes if needed |

### 3.4 Gotchas

- **RollbackUSDAmount can be negative** — negative values are rollback corrections (reversal of a previous rollback). Always SUM to get net rollback amounts, never COUNT or take MAX.
- **PaymentStatusID is always 2** in production data — this reflects the "InProcess" state at the time of rollback recording. It does NOT indicate the current payment status. Use `PaymentOrderStatus` for the actual cashout lifecycle status.
- **PaymentOrderStatus uses CashoutStatus codes, not PaymentStatus codes** — values come from `History.WithdrawToFundingAction.CashoutStatusID`: 3=Processed, 16=Reversed, 17=Partially Reversed. The production SP filters `CashoutStatusID IN (3, 17, 16)`.
- **No primary key** — this table has no unique constraint. The clustered index on CID is for query performance, not uniqueness.
- **ModificationDateID is the ETL partition key** — the delete-insert ETL pattern uses this column. Always filter on it for date-range queries to match the ETL grain.
- **MIDName/MID resolution is complex** — these columns are computed via depot-specific CASE logic in the production SP. Values may be NULL when no merchant routing is applicable.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag | `[UNVERIFIED]`? |
|-------|-------|-----|-----------------|
| 5 stars | Tier 5 (domain expert / glossary) | `(Tier 5 — domain expert)` | No |
| 4 stars | Tier 1 (upstream wiki verbatim) | `(Tier 1 — upstream wiki, {source})` | No |
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — ...)` | No |
| 2 stars | Tier 3 (live data / sampling) + Tier 3b (DDL structure) | `(Tier 3 — ...)` | No |
| 1.5 stars | Tier 4-Atlassian (Confluence/Jira) | `(Tier 4 — Confluence/Jira, {source})` | No |
| 1 star | Tier 4-Inferred (column name guessing) | `[UNVERIFIED] (Tier 4 — inferred)` | **Yes** |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID of the account whose withdrawal is being rolled back. Not passed directly by the caller — derived inside AddCashoutRollbackTrackingRecord by querying Billing.Withdraw for the given WithdrawID. Implicit FK to Customer.CustomerStatic(CID). DWH note: clustered index key for Synapse query performance. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 2 | WithdrawprocessingID | int | YES | Surrogate primary key of the payment execution leg in `Billing.WithdrawToFunding`. Identifies which specific payment leg (card/bank/wallet payout attempt) was rolled back. Implicit FK to Billing.WithdrawToFunding(ID). DWH note: renamed from `WithdrawToFunding.ID` via the production SP alias `[Withdraw processing ID]`. (Tier 1 — upstream wiki, Billing.WithdrawToFunding) |
| 3 | WithdrawID | int | YES | The parent withdrawal request ID (Billing.Withdraw.WithdrawID). Never NULL in practice. Implicit FK to Billing.Withdraw. Enables grouping rollback events by withdrawal in reconciliation queries. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 4 | ProcessTime | datetime2(7) | YES | Value date from the payment processor — when funds are considered available on the processor side. Set for wire/ACH payouts; NULL for instant payment methods. DWH note: renamed from `WithdrawToFunding.ProcessorValueDate`. (Tier 1 — upstream wiki, Billing.WithdrawToFunding) |
| 5 | NetAmount | decimal(38,18) | YES | Refund amount expressed in the original deposit's currency. May differ from NetUSDAmount when exchange rates changed between deposit and refund. ISNULL(0) applied — zero when NULL in source. DWH note: renamed from `WithdrawToFunding.RefundAmountInDepositCurrency`. (Tier 1 — upstream wiki, Billing.WithdrawToFunding) |
| 6 | Currency | nvarchar(max) | YES | Currency abbreviation (e.g., USD, EUR, GBP) of the payment processing currency. Resolved from `Dictionary.Currency.Abbreviation` via `WithdrawToFunding.ProcessCurrencyID` JOIN in the production SP. (Tier 2 — SP code, Billing.GetRollbackedPaymentOrdersReport) |
| 7 | NetUSDAmount | decimal(38,18) | YES | Payout amount in the processing currency (despite the "USD" suffix, this is actually in ProcessCurrencyID currency). MONEY type in source, CAST to decimal(16,2). ISNULL(0) applied. DWH note: renamed from `WithdrawToFunding.Amount`. (Tier 1 — upstream wiki, Billing.WithdrawToFunding) |
| 8 | RollbackDate | datetime2(7) | YES | Date/time when the rollback event occurred (as reported by the caller via @RollbackDate). Distinct from the record creation date — allows back-dating when recording a rollback that was initiated at a different time. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 9 | RollbackAmount | decimal(38,18) | YES | The incremental amount in the original transaction currency for this rollback event. Parallel to RollbackUSDAmount. DWH note: renamed from `CashoutRollbackTracking.RollbackAmountInCurrency`. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 10 | ExchangeRate | decimal(38,18) | YES | Exchange rate between the rollback currency and USD applicable at the time of this rollback event. Passed by the caller, distinct from the original withdrawal exchange rate. ISNULL(1) + CAST to decimal(16,4) applied in the production SP. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 11 | FeeInPIPs | int | YES | Exchange fee in provider-specific integer units from the original payment leg. DWH note: renamed from `WithdrawToFunding.ExchangeFee`. Not a rollback-specific fee — it reflects the fee structure of the original withdrawal, carried forward for context. (Tier 1 — upstream wiki, Billing.WithdrawToFunding) |
| 12 | RollbackUSDAmount | decimal(38,18) | YES | The incremental amount (in USD) reversed in this specific rollback event. Negative values indicate a rollback correction (reversal of a previous rollback). SUM this column grouped by WithdrawID to compute net rollback totals. DWH note: renamed from `CashoutRollbackTracking.RollbackAmountInUSD`. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 13 | ReferenceNumber | nvarchar(max) | YES | Optional external reference number for the rollback transaction (e.g., payment provider reference for the refund). NULL when no external reference is available. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 14 | RollbackReason | int | YES | Reason code for the rollback. Maps to @RollbackType parameter in AddCashoutRollbackTrackingRecord. No Dictionary lookup table exists. Observed values: 0=default/unknown, 1=standard rollback, 3=dominant reason (83% of events), 4=correction events. DWH note: renamed from `CashoutRollbackTracking.RollbackReasonID`. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 15 | PaymentStatusID | int | YES | Status of the rollback at time of recording. Always 2 (InProcess) across all production rows — set from @CashoutStatusID parameter. Uses Dictionary.PaymentStatus: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 16 | FundingMethod | nvarchar(max) | YES | Payment method type name resolved from `Dictionary.FundingType.Name` via `Billing.FundingPaymentDetailsForWithdraw.FundingTypeID`. Examples: credit card, bank transfer, PayPal, eToroMoney. (Tier 2 — SP code, Billing.GetRollbackedPaymentOrdersReport) |
| 17 | Brand | nvarchar(max) | YES | Card brand name resolved from `Dictionary.CardType.Name` via XML-parsed `CardTypeID` from `Billing.FundingPaymentDetailsForWithdraw.FundingData`. Examples: Visa, Mastercard. NULL for non-card payment methods (bank transfers, PayPal, etc.). (Tier 2 — SP code, Billing.GetRollbackedPaymentOrdersReport) |
| 18 | PaymentDetails | nvarchar(max) | YES | Payment-specific details extracted from XML data, varying by payment method. Bank transfers (FundingTypeID=2): BSB number + client address. PayPal cashouts (FundingTypeID=3, CashoutTypeID=1): email. eToroMoney (FundingTypeID=10): AccountID + PurseID. Trustly (FundingTypeID=33): GCID, PlatformAccountID, IBAN, BIC, SortCode. Skrill (FundingTypeID=35): details + BirthDate. PayID (FundingTypeID=39): PayId + Email. Otherwise: standard payment details string. (Tier 2 — SP code, Billing.GetRollbackedPaymentOrdersReport) |
| 19 | FundingID | int | YES | The payment instrument to which the withdrawal was being sent. References `Billing.Funding` implicitly (no explicit FK). Identifies the specific card, bank account, or wallet used for this payment leg. (Tier 1 — upstream wiki, Billing.WithdrawToFunding) |
| 20 | Depot | nvarchar(max) | YES | Acquirer or payment gateway configuration name used for this payment leg. Resolved from `Billing.Depot.Name` via `WithdrawToFunding.DepotID`. Identifies which payment processor handled the original withdrawal (e.g., specific bank integration, card processor). (Tier 2 — SP code, Billing.GetRollbackedPaymentOrdersReport) |
| 21 | VerificationCode | nvarchar(max) | YES | Verification code supplied or received during withdrawal processing. Used to validate the payout authorization. Same pattern as Billing.Deposit.RefundVerificationCode. (Tier 1 — upstream wiki, Billing.WithdrawToFunding) |
| 22 | Regulation | nvarchar(max) | YES | Regulatory jurisdiction under which the customer operates, resolved from `Dictionary.Regulation.Name` via `BackOffice.Customer.RegulationID`. Examples: CySEC, FCA, ASIC, FinCEN, FSA Seychelles, MAS, FSRA. (Tier 2 — SP code, Billing.GetRollbackedPaymentOrdersReport) |
| 23 | MIDName | nvarchar(max) | YES | Merchant Identifier Name — the human-readable name of the merchant account used for payment routing. Resolved via complex DepotID-specific CASE logic: for DepotIDs 35-43 uses deposit-side ProtocolMIDSettings regulation name; for DepotIDs 1,24,25,26,78,79,80,4,75,86 uses `GetMerchantDetailsForOneAccountByDepotOnly`; for bank transfers uses ProtocolMIDSettings description; otherwise falls back through `GetMerchantDetails` and regulation names. (Tier 2 — SP code, Billing.GetRollbackedPaymentOrdersReport) |
| 24 | MID | nvarchar(max) | YES | Merchant Identifier value — the technical MID code used for payment routing. Resolved via similar DepotID-specific CASE logic as MIDName but returns the MID value. Falls through ProtocolMIDSettings value, `GetMerchantDetailsForOneAccountByDepotOnly`, `GetMerchantDetails`, BPMS descriptions, and `MapMerchantCodeToMid`. (Tier 2 — SP code, Billing.GetRollbackedPaymentOrdersReport) |
| 25 | PaymentOrderStatus | int | YES | Cashout status of the payment order from `History.WithdrawToFundingAction.CashoutStatusID` at the time of the rollback action. Uses Dictionary.CashoutStatus values: 3=Processed, 16=Reversed, 17=Partially Reversed. The production SP filters to only include rows where CashoutStatusID IN (3, 16, 17). (Tier 2 — SP code, Billing.GetRollbackedPaymentOrdersReport) |
| 26 | StatusModificationTime | datetime2(7) | YES | UTC timestamp when the rollback tracking record was last modified. Set to GETUTCDATE() at INSERT in production. DWH note: renamed from `CashoutRollbackTracking.ModificationDate`; serves as the ETL watermark — `ModificationDateID` is derived from this column. (Tier 1 — upstream wiki, Billing.CashoutRollbackTracking) |
| 27 | ModificationDateID | int | YES | ETL partition key — integer date derived from StatusModificationTime via `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, StatusModificationTime), 0), 112))`. Format: YYYYMMDD (e.g., 20230721). Used for incremental delete-insert ETL pattern and date-range filtering. (Tier 2 — SP code, SP_Fact_Cashout_Rollback_DL_To_Synapse) |
| 28 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last loaded by the ETL pipeline. Set to GETDATE() on each reload by the Synapse ETL SP. (Tier 2 — SP code, SP_Fact_Cashout_Rollback_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Billing.Withdraw | CID | Passthrough (via CashoutRollbackTracking → Withdraw lookup) |
| WithdrawprocessingID | Billing.WithdrawToFunding | ID | Rename |
| WithdrawID | Billing.Withdraw | WithdrawID | Passthrough |
| ProcessTime | Billing.WithdrawToFunding | ProcessorValueDate | Rename |
| NetAmount | Billing.WithdrawToFunding | RefundAmountInDepositCurrency | Rename + ISNULL(0) |
| Currency | Dictionary.Currency | Abbreviation | JOIN-enriched (via ProcessCurrencyID) |
| NetUSDAmount | Billing.WithdrawToFunding | Amount | Rename + CAST + ISNULL(0) |
| RollbackDate | Billing.CashoutRollbackTracking | RollbackDate | Passthrough |
| RollbackAmount | Billing.CashoutRollbackTracking | RollbackAmountInCurrency | Rename |
| ExchangeRate | Billing.CashoutRollbackTracking | ExchangeRate | CAST + ISNULL(1) |
| FeeInPIPs | Billing.WithdrawToFunding | ExchangeFee | Rename |
| RollbackUSDAmount | Billing.CashoutRollbackTracking | RollbackAmountInUSD | Rename |
| ReferenceNumber | Billing.CashoutRollbackTracking | ReferenceNumber | Passthrough |
| RollbackReason | Billing.CashoutRollbackTracking | RollbackReasonID | Rename |
| PaymentStatusID | Billing.CashoutRollbackTracking | PaymentStatusID | Passthrough |
| FundingMethod | Dictionary.FundingType | Name | JOIN-enriched |
| Brand | Dictionary.CardType | Name | JOIN-enriched (XML-parsed CardTypeID) |
| PaymentDetails | Multiple tables | Various XML fields | ETL-computed (complex CASE) |
| FundingID | Billing.WithdrawToFunding | FundingID | Passthrough |
| Depot | Billing.Depot | Name | JOIN-enriched |
| VerificationCode | Billing.WithdrawToFunding | VerificationCode | Passthrough |
| Regulation | Dictionary.Regulation | Name | JOIN-enriched (via BackOffice.Customer) |
| MIDName | Multiple tables | Various | ETL-computed (complex CASE) |
| MID | Multiple tables | Various | ETL-computed (complex CASE) |
| PaymentOrderStatus | History.WithdrawToFundingAction | CashoutStatusID | Rename + JOIN-enriched |
| StatusModificationTime | Billing.CashoutRollbackTracking | ModificationDate | Rename |
| ModificationDateID | — | — | ETL-computed (integer date from StatusModificationTime) |
| UpdateDate | — | — | ETL-computed (GETDATE()) |

Full production documentation: see upstream wiki Billing/Tables/Billing.CashoutRollbackTracking.md and Billing/Tables/Billing.WithdrawToFunding.md (source configured in dwh-semantic-doc-config.json).

### 5.2 ETL Pipeline

```
Billing.CashoutRollbackTracking + 15 tables → Billing.GetRollbackedPaymentOrdersReport (prod SP)
  → DWH.Billing_GetRollbackedPaymentOrdersReport (DWH wrapper, strips column spaces)
    → ADF/Generic Pipeline (lake export)
      → DWH_staging.etoro_Billing_GetRollbackedPaymentOrdersReport (staging)
        → SP_Fact_Cashout_Rollback_DL_To_Synapse (ETL SP, daily delete-insert)
          → DWH_dbo.Fact_Cashout_Rollback
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Billing.CashoutRollbackTracking | Primary source: rollback audit trail on production SQL Server (etoroDB-REAL) |
| Report SP | Billing.GetRollbackedPaymentOrdersReport | Production SP that JOINs 15+ tables to denormalize rollback + withdrawal + payment details |
| DWH Wrapper | DWH.Billing_GetRollbackedPaymentOrdersReport | Strips spaces from column names for ADF compatibility; created 29/7/23 by Ran Ovadia |
| Lake | ADF/Generic Pipeline | Daily export to data lake |
| Staging | DWH_staging.etoro_Billing_GetRollbackedPaymentOrdersReport | Raw import from lake |
| ETL | DWH_dbo.SP_Fact_Cashout_Rollback_DL_To_Synapse | Delete-insert by ModificationDateID. Adds ModificationDateID + UpdateDate |
| Target | DWH_dbo.Fact_Cashout_Rollback | ROUND_ROBIN, CLUSTERED INDEX on CID |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer / DWH_dbo.CustomerStatic | Customer whose withdrawal was rolled back |
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | Parent withdrawal request |
| WithdrawprocessingID | (no DWH dim — maps to Billing.WithdrawToFunding.ID in production) | Specific payment execution leg |
| FundingID | (no DWH dim — maps to Billing.Funding in production) | Payment instrument used |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Rollback recording status (always 2=InProcess) |
| PaymentOrderStatus | DWH_dbo.Dim_CashoutStatus | Cashout lifecycle state: 3=Processed, 16=Reversed, 17=Partially Reversed |
| RollbackReason | (no DWH dim — no Dictionary table exists) | Rollback reason code: 0=unknown, 1=standard, 3=dominant, 4=correction |
| ModificationDateID | DWH_dbo.Dim_Date (via V_Dim_Date) | Date dimension join key (YYYYMMDD integer) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Fact_Cashout_Rollback_DL_To_Synapse | (all columns) | WRITER — sole ETL procedure that loads this table via daily delete-insert |

---

## 7. Sample Queries

### 7.1 Total rollback volume by customer for a date range
```sql
SELECT  CID,
        COUNT(*)                    AS RollbackCount,
        SUM(RollbackUSDAmount)      AS NetRollbackUSD,
        MIN(RollbackDate)           AS FirstRollback,
        MAX(RollbackDate)           AS LastRollback
FROM    [DWH_dbo].[Fact_Cashout_Rollback]
WHERE   ModificationDateID BETWEEN 20250101 AND 20250331
GROUP BY CID
ORDER BY NetRollbackUSD DESC;
```

### 7.2 Rollback events by regulation and payment method
```sql
SELECT  Regulation,
        FundingMethod,
        COUNT(*)                    AS EventCount,
        SUM(RollbackUSDAmount)      AS TotalRollbackUSD
FROM    [DWH_dbo].[Fact_Cashout_Rollback]
WHERE   ModificationDateID >= 20250101
GROUP BY Regulation, FundingMethod
ORDER BY TotalRollbackUSD DESC;
```

### 7.3 Rollback details with customer context
```sql
SELECT  fcr.CID,
        dc.FirstName,
        dc.LastName,
        fcr.WithdrawID,
        fcr.RollbackDate,
        fcr.RollbackUSDAmount,
        fcr.RollbackReason,
        fcr.FundingMethod,
        fcr.Depot,
        fcr.Regulation,
        cs.Name                     AS PaymentOrderStatusName
FROM    [DWH_dbo].[Fact_Cashout_Rollback] fcr
JOIN    [DWH_dbo].[Dim_Customer] dc
        ON fcr.CID = dc.CID
LEFT JOIN [DWH_dbo].[Dim_CashoutStatus] cs
        ON fcr.PaymentOrderStatus = cs.CashoutStatusID
WHERE   fcr.ModificationDateID >= 20250301
ORDER BY fcr.RollbackDate DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Cashout Redesign](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12676694026/Cashout+Redesign) | Confluence | Architecture overview: cashout-service may split into microservices; payment-order-service handles rolling back payment orders and generating rollback reports |
| [Add Rollback Modal to Processed cashouts report](https://etoro-jira.atlassian.net/wiki/spaces/OG/pages/11898650816/Add+Rollback+Modal+to+Processed+cashouts+report) | Confluence | UX flow: Backoffice → Accounting → Cashouts → Processed Cashouts → right-click → Rollback Withdraw. Updates withdrawal status and account balance in one transaction |
| [USA Risk Refunds Procedure](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/11879514396/USA+Risk+Refunds+Procedure) | Confluence | Refund workflow: rollback fields include Status, Amount, RollbackDate, ReferenceNumber. Total deposit amount minus net cashout amount determines refund |
| [CO Rollback - Move transaction to DB](https://etoro-jira.atlassian.net/browse/QARD-59302) | Jira | QA test case: validates rollback cashout workflow in Processed Cashouts screen |
| [CO Cancel Rollback](https://etoro-jira.atlassian.net/browse/QARD-66215) | Jira | QA test case: cancel rollback functionality for rows with "Reversed Withdraw" status |

---

*Generated: 2026-03-18 | Quality: 9.2/10 (★★★★★) | Phases: 10/14*
*Tiers: 17 T1, 11 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 10/10*
*Object: DWH_dbo.Fact_Cashout_Rollback | Type: Table | Production Source: Billing.CashoutRollbackTracking (etoro)*
