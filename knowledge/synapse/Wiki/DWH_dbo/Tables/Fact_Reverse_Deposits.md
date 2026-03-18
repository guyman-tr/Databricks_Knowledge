# DWH_dbo.Fact_Reverse_Deposits

> Deposit reversal fact table - 9,904 rows covering refunds, chargebacks, and reversed deposits from 2020-2024. Tracks rollback amounts, reasons (Fraud=86%), and customer financial snapshots at rollback time. Sourced from BackOffice.GetRiskExposureReportPCIVersion. Pipeline stopped June 2024.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | BackOffice.GetRiskExposureReportPCIVersion (SP) via DWH_staging.etoro_BackOffice_GetRiskExposureReportPCIVersion |
| **Refresh** | STOPPED (staging source table dropped; last loaded 2024-06-29; data through 2024-06-28) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

DWH_dbo.Fact_Reverse_Deposits captures every deposit that was subsequently reversed - through refunds, chargebacks, or internal rollback actions. Unlike `Fact_Deposit_Fees` (which records all deposits including approved ones), Fact_Reverse_Deposits focuses exclusively on the 9,904 deposits that experienced some form of reversal event, providing the pre- and post-reversal context for compliance, fraud analysis, and financial reconciliation.

The table name comes from its source: `BackOffice.GetRiskExposureReportPCIVersion`, the eToro risk exposure BackOffice report with PCI-compliant data (no raw card numbers). It enriches each reversal event with the customer's total financial position at that point in time (Balance, TotalDeposits, TotalPnL, etc.) - a snapshot enabling risk exposure assessment.

Key differentiators from Fact_Deposit_Fees:
- Only reversed deposits (refunds, chargebacks, rollbacks) - not all deposits
- Includes `PreviousDepositStatus` to show the status before reversal
- Includes rollback-specific columns: RollbackDate, RollbackAmount, RollbackUSDAmount, RollbackCanceled, ReferenceNumber
- Includes customer financial snapshot: Balance, TotalDeposits, TotalProcessedCashouts, TotalPnL, TotalCompensations, TotalCredits, TotalCommissions

ETL uses proper daily DELETE+INSERT on ModificationDateID range (unlike Fact_Deposit_Fees which has commented-out WHERE). Pipeline stopped June 2024 when staging source was dropped.

---

## 2. Business Logic

### 2.1 Deposit Reversal Status Flow

**What**: Tracks the lifecycle of a deposit that ended in reversal.

**Columns Involved**: `DepositStatus`, `PreviousDepositStatus`, `DepositStatusModificationTime`

**Status Distribution** (live data):
- Refund (6,306 = 63.7%): Customer-initiated or compliance-driven refund
- Chargeback (2,618 = 26.4%): Card issuer reversal
- ChargebackReversal (539 = 5.4%): Chargeback successfully disputed (reversal of the reversal)
- Approved (314 = 3.2%): Currently approved but previously had a rollback event
- ReversedDeposit (121 = 1.2%): Internal reversal
- RefundReversal (6 = 0.06%): Refund itself was reversed

**PreviousDepositStatus**: State before the final DepositStatus transition (e.g., Approved -> Refund).

### 2.2 Rollback Reason Taxonomy

**What**: Classifies why a deposit was reversed.

**Columns Involved**: `RollbackReason`, `RollbackDate`, `RollbackAmount`, `RollbackUSDAmount`, `RollbackCanceled`

**RollbackReason distribution** (live data, 30 distinct values):
```
Fraud:                               8,522 (86.0%) - primary reversal driver
Successful Dispute:                    490 (4.9%)  - customer-won chargeback
Wrong Deposit ID/Amount:               219 (2.2%)  - operational error
Technical/Service/Complaint:           184 (1.9%)  - service failure
Fake Docs:                             145 (1.5%)  - compliance: document fraud
Rollback Adjustment:                    95 (1.0%)  - manual adjustment
Attack:                                 40 (0.4%)  - account takeover/attack
Processor Reimbursement:                33 (0.3%)  - processor-side refund
Deposit deducted - Added to client:     32 (0.3%)  - operational error
Deposit added - Return of Return:       25 (0.3%)  - double-refund correction
Other, Funds not received, Incorrect Currency, CO Logic, etc.
```

`RollbackCanceled`: Indicates if the rollback itself was subsequently cancelled (deposit restored).

### 2.3 Customer Risk Exposure at Rollback Time

**What**: Snapshot of customer financial position at rollback, enabling risk exposure analysis.

**Columns Involved**: `Balance`, `TotalDeposits`, `TotalProcessedCashouts`, `TotalCommissions`, `PIPsInUSD`, `TotalPnL`, `TotalCompensations`, `TotalCredits`

**Context**: These represent customer lifetime aggregates at the time of the rollback event, sourced from BackOffice.GetRiskExposureReportPCIVersion. They allow risk teams to assess: "When this deposit was rolled back, what was the customer's total financial exposure to eToro?"

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN-distributed with a CLUSTERED INDEX on `CID ASC`. At 9,904 rows, ROUND_ROBIN provides even distribution. CLUSTERED INDEX on CID supports customer-focused queries efficiently.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Delta (MANAGED), no partitioning. At 9,904 rows, full scan is acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total chargeback exposure by funding method | WHERE DepositStatus = 'Chargeback'; GROUP BY FundingMethod |
| Fraud-driven rollbacks by regulation | WHERE RollbackReason = 'Fraud'; GROUP BY Regulation |
| Date-range reversal analysis | Use ModificationDateID (YYYYMMDD) for efficient filtering |
| Customer net position after rollback | CID, Balance - RollbackUSDAmount |
| ChargebackReversal rate | ChargebackReversal count / Chargeback count |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_Deposit_Fees | ON f.DepositID = rd.DepositID | Cross-reference with full deposit record |
| DWH_dbo.Fact_BillingDeposit (expected) | ON f.DepositID = rd.DepositID | Join to main deposit dimension |
| DWH_dbo.Dim_Affiliate | ON rd.FundingID = ... | Affiliate attribution (no AffiliateID column; use CID) |

### 3.4 Gotchas

- **Pipeline is dead**: Data stops at 2024-06-28 (RollbackDate). Staging table gone.
- **Only reversed deposits**: This table does NOT include all deposits - only those with reversal events. For full deposit view use Fact_Deposit_Fees or Fact_BillingDeposit.
- **ChargebackReversal means won dispute**: A ChargebackReversal row means eToro won the dispute - the chargeback was reversed back. This reduces the net chargeback exposure.
- **RollbackCanceled**: A non-NULL RollbackCanceled indicates the rollback was undone - the deposit was reinstated.
- **Customer financial columns as snapshots**: Balance, TotalDeposits, etc. are point-in-time snapshots from the BackOffice risk exposure report, not calculated from DWH fact data. Do not aggregate these across rows for a customer.
- **ModificationDateID from DepositStatusModificationTime**: Unlike Fact_Deposit_Fees (which uses StatusModificationTime), this table derives ModificationDateID from DepositStatusModificationTime.
- **No AffiliateID column**: Unlike Fact_Deposit_Fees, this table has no AffiliateID. Use CID to join to customer/affiliate data.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Description |
|-------|------|-----|-------------|
| **5 stars** | Tier 5 | `(Tier 5 - domain expert)` | Domain expert confirmed |
| **4 stars** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Upstream production wiki verbatim |
| **3 stars** | Tier 2 | `(Tier 2 - ...)` | Synapse SP code or migration DDL |
| **2 stars** | Tier 3 | `(Tier 3 - ...)` | Live data sampling or DDL structure |
| **1 star** | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred from column name only |

**Identity & Deposit Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. CLUSTERED INDEX key. (Tier 2 - SP_Fact_Reverse_Deposits_DL_To_Synapse passthrough) |
| 2 | DepositID | int | YES | Billing deposit identifier. Links this reversal to the original deposit in Fact_Deposit_Fees and Fact_BillingDeposit. (Tier 2 - SP passthrough) |
| 3 | WhiteLabelID | int | YES | White-label brand integer identifier. Numeric FK to white-label lookup. (Tier 2 - SP passthrough) |
| 4 | OldPaymentID | int | YES | Legacy payment system identifier. [UNVERIFIED] (Tier 4 - inferred) |
| 5 | FundingID | int | YES | Funding method integer identifier (19 types). (Tier 2 - SP passthrough) |

**Deposit Status & Timing:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 6 | DepositStatus | nvarchar(max) | YES | Status at last load. Values (live): Refund(63.7%), Chargeback(26.4%), ChargebackReversal(5.4%), Approved(3.2%), ReversedDeposit(1.2%), RefundReversal(0.1%). (Tier 3 - live data sampling) |
| 7 | PreviousDepositStatus | nvarchar(max) | YES | Deposit status before the final DepositStatus transition. Captures the pre-reversal state. (Tier 2 - SP passthrough) |
| 8 | DepositStatusModificationTime | datetime2(7) | YES | Timestamp of final status change. Source for ModificationDateID derivation. (Tier 2 - SP passthrough) |
| 9 | ModificationDateID | int | YES | ETL date key derived from DepositStatusModificationTime: convert(int, convert(varchar, dateadd(...), 112)). Format: YYYYMMDD. (Tier 2 - SP_Fact_Reverse_Deposits_DL_To_Synapse computed) |
| 10 | DepositTime | datetime2(7) | YES | Original deposit submission timestamp. Range: 2020-05-11 to 2024-06-20. (Tier 2 - SP passthrough) |
| 11 | UpdateDate | datetime | YES | ETL load timestamp (getdate()). Range: 2023-12-25 to 2024-06-29. (Tier 2 - SP computed: getdate()) |

**Rollback-Specific Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 12 | RollbackDate | datetime2(7) | YES | Date the rollback was executed. Range: 2021-05-05 to 2024-06-28. (Tier 2 - SP passthrough) |
| 13 | RollbackAmount | decimal(38,18) | YES | Rollback amount in original deposit currency. (Tier 2 - SP passthrough) |
| 14 | RollbackUSDAmount | decimal(38,18) | YES | Rollback amount converted to USD at rollback-time exchange rate. (Tier 2 - SP passthrough) |
| 15 | RollbackReason | nvarchar(max) | YES | Business reason for rollback. 30 distinct values; Fraud=86%. Full list: Fraud, Successful Dispute, Wrong Deposit ID/Amount, Technical/Service/Complaint, Fake Docs, Rollback Adjustment, Attack, Processor Reimbursement, and 22 others. (Tier 3 - live data distribution) |
| 16 | RollbackCanceled | nvarchar(max) | YES | Non-NULL if rollback was subsequently cancelled (deposit reinstated). (Tier 4 - inferred) |
| 17 | ReferenceNumber | nvarchar(max) | YES | External reference number for chargeback/refund tracking with processor or card scheme. (Tier 4 - inferred) |

**Amount Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 18 | DepositAmount | decimal(38,18) | YES | Original deposit amount in customer currency. (Tier 2 - SP passthrough) |
| 19 | DepositUSDAmount | decimal(38,18) | YES | Original deposit amount in USD at deposit-time rate. Enables USD-normalized analysis. (Tier 2 - SP passthrough) |
| 20 | Currency | nvarchar(max) | YES | Customer's deposit currency. (Tier 2 - SP passthrough) |
| 21 | ExchangeRate | decimal(38,18) | YES | Exchange rate applied at rollback time. (Tier 2 - SP passthrough) |
| 22 | ConversionFee | decimal(38,18) | YES | Fee for currency conversion applied during rollback. (Tier 4 - inferred) |
| 23 | PIPsInUSD | decimal(38,18) | YES | USD value of PIPs fee associated with this deposit. (Tier 2 - SP passthrough) |

**Customer Risk Snapshot (at rollback time):**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 24 | Balance | decimal(38,18) | YES | Customer account balance at rollback time. Point-in-time snapshot from BackOffice risk report. (Tier 2 - SP passthrough) |
| 25 | TotalDeposits | decimal(38,18) | YES | Customer lifetime total deposits at rollback time. (Tier 2 - SP passthrough) |
| 26 | TotalProcessedCashouts | decimal(38,18) | YES | Customer lifetime total processed cashouts at rollback time. (Tier 2 - SP passthrough) |
| 27 | TotalCommissions | decimal(38,18) | YES | Customer total commissions earned/paid at rollback time. (Tier 2 - SP passthrough) |
| 28 | TotalPnL | decimal(38,18) | YES | Customer total profit and loss at rollback time. (Tier 2 - SP passthrough) |
| 29 | TotalCompensations | decimal(38,18) | YES | Customer total compensation credits at rollback time. (Tier 2 - SP passthrough) |
| 30 | TotalCredits | decimal(38,18) | YES | Customer total credit balance at rollback time. (Tier 2 - SP passthrough) |

**Payment Channel Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 31 | FundingMethod | nvarchar(max) | YES | Payment method name (CreditCard, PayPal, etc.). (Tier 2 - SP passthrough) |
| 32 | Brand | nvarchar(max) | YES | Card network brand (Visa, Master Card, etc.). (Tier 2 - SP passthrough) |
| 33 | Depot | nvarchar(max) | YES | Payment gateway/processor name. (Tier 2 - SP passthrough) |
| 34 | MID | nvarchar(max) | YES | Merchant ID for payment processor settlement. (Tier 2 - SP passthrough) |
| 35 | MIDName | nvarchar(max) | YES | Human-readable MID description. (Tier 2 - SP passthrough) |
| 36 | PaymentDetails | nvarchar(max) | YES | Method-specific payment details. (Tier 2 - SP passthrough) |
| 37 | ThreedsParameters | nvarchar(max) | YES | 3D Secure authentication parameters. (Tier 4 - inferred) |
| 38 | ThreedsResponse | nvarchar(max) | YES | 3D Secure authentication result. (Tier 2 - SP passthrough) |

**Customer & Regulatory Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 39 | Regulation | nvarchar(max) | YES | Regulatory jurisdiction for this customer. (Tier 2 - SP passthrough) |
| 40 | WhiteLabel | nvarchar(max) | YES | White-label brand name. (Tier 2 - SP passthrough) |
| 41 | CustomerStatus | nvarchar(max) | YES | Customer account status at rollback time. [UNVERIFIED] (Tier 4 - inferred) |
| 42 | RiskStatus | nvarchar(max) | YES | Risk management status. [UNVERIFIED] (Tier 4 - inferred) |
| 43 | VerificationLevel | nvarchar(max) | YES | Customer KYC/verification level at rollback time. [UNVERIFIED] (Tier 4 - inferred) |
| 44 | CustomerLevel | nvarchar(max) | YES | Customer tier (Silver, Gold, Platinum, etc.). [UNVERIFIED] (Tier 4 - inferred) |
| 45 | CountryByRegIP | nvarchar(max) | YES | Country from registration IP address. (Tier 4 - inferred) |
| 46 | AccountManager | nvarchar(max) | YES | Assigned account manager at rollback time. (Tier 4 - inferred) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| All columns (except ModificationDateID, UpdateDate) | BackOffice.GetRiskExposureReportPCIVersion (SP) | Same name | passthrough |
| ModificationDateID | ETL computation | DepositStatusModificationTime | convert(int, convert(varchar, dateadd(day,datediff(day,0,[DepositStatusModificationTime]),0), 112)) |
| UpdateDate | ETL computation | - | getdate() at SP execution time |

### 5.2 ETL Pipeline

```
BackOffice.GetRiskExposureReportPCIVersion (production SP - risk exposure report)
  -> DWH_staging.etoro_BackOffice_GetRiskExposureReportPCIVersion (materialized staging, NOW GONE)
       -> SP_Fact_Reverse_Deposits_DL_To_Synapse (@dt parameter)
            DELETE WHERE ModificationDateID in @dt range
            INSERT WHERE DepositStatusModificationTime in @dt range
            -> DWH_dbo.Fact_Reverse_Deposits (9,904 rows, frozen at 2024-06-28)
```

| Step | Object | Description |
|------|--------|-------------|
| Source SP | BackOffice.GetRiskExposureReportPCIVersion | Risk exposure report (PCI-safe) |
| Staging | DWH_staging.etoro_BackOffice_GetRiskExposureReportPCIVersion | Materialized staging (no longer exists) |
| ETL SP | DWH_dbo.SP_Fact_Reverse_Deposits_DL_To_Synapse | Daily DELETE+INSERT upsert pattern |
| Target | DWH_dbo.Fact_Reverse_Deposits | 9,904 rows, frozen 2024-06-28 |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | Customer dimension | Implicit FK to customer master |
| DepositID | DWH_dbo.Fact_Deposit_Fees | Links to full deposit record (if DepositID appears in Fact_Deposit_Fees) |
| DepositID | DWH_dbo.Fact_BillingDeposit (expected) | Links to main deposit fact |
| FundingID | Funding type lookup | Numeric FK for payment method |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (none found) | - | No views or SPs reference this table in SSDT repo |

---

## 7. Sample Queries

### 7.1 Rollback reasons breakdown
```sql
SELECT RollbackReason, COUNT(1) AS Cnt, SUM(RollbackUSDAmount) AS TotalUSD
FROM [DWH_dbo].[Fact_Reverse_Deposits]
GROUP BY RollbackReason
ORDER BY Cnt DESC;
```

### 7.2 Chargeback analysis by funding method
```sql
SELECT FundingMethod, COUNT(1) AS Chargebacks, SUM(RollbackUSDAmount) AS TotalChargebackUSD
FROM [DWH_dbo].[Fact_Reverse_Deposits]
WHERE DepositStatus = 'Chargeback'
GROUP BY FundingMethod
ORDER BY TotalChargebackUSD DESC;
```

### 7.3 Customer risk at rollback time
```sql
SELECT
    CID, DepositID, RollbackDate, RollbackUSDAmount,
    RollbackReason, Balance, TotalDeposits, TotalPnL
FROM [DWH_dbo].[Fact_Reverse_Deposits]
WHERE RollbackReason = 'Fraud'
ORDER BY RollbackDate DESC;
```

### 7.4 Date-range query using ModificationDateID
```sql
SELECT CID, DepositStatus, RollbackAmount, RollbackReason
FROM [DWH_dbo].[Fact_Reverse_Deposits]
WHERE ModificationDateID >= 20240101 AND ModificationDateID < 20240701
ORDER BY DepositStatusModificationTime DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP unavailable this session.)

---

*Generated: 2026-03-18 | Quality: 6.5/10 (★★★☆☆) | Phases: 11/14*
*Tiers: 0 T1, 18 T2, 3 T3, 7 T4 [UNVERIFIED], 0 T5 | Elements: 7/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10*
*Object: DWH_dbo.Fact_Reverse_Deposits | Type: Table | Production Source: BackOffice.GetRiskExposureReportPCIVersion (SP) - pipeline stopped 2024-06-29*
