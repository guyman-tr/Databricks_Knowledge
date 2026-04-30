# Billing.GetRedeemFeeExtendedDetails

> Analytics report for completed standard crypto redemptions since a given timestamp: returns per-redemption fee amounts in both units and USD, plus the effective fee as a percentage of the redemption value.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TimeStamp (time-window filter); returns one row per qualifying RedeemID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRedeemFeeExtendedDetails` is a fee analytics report for crypto redemptions. It answers: "For all standard redemptions that completed after a given point in time, what was the fee in units, what was the fee in USD at the actual close price, and what effective percentage did the fee represent?"

The procedure exists to support fee auditing and reporting. The `Billing.Redeem` table stores `RedeemFee` in units (the raw fee quantity), but stakeholders typically need the dollar value and percentage to evaluate whether the fee schedule is producing the expected revenue and whether the fee rates are competitive. This report bridges that gap by computing the monetary value using the actual closing price at the time of settlement.

Data flow: called by operations or analytics teams (referenced in ticket PTL-93, Alexei B.) with a timestamp cutoff. The procedure returns only `RedeemStatusID=8` (TransactionDone - fully settled) and `RedeemTypeID=0` (standard crypto redemption, excluding NFT or special types). OpenRate and CloseRate are derived by dividing the stored USD amounts by the unit count, showing the per-unit price at request time vs close time.

---

## 2. Business Logic

### 2.1 Fee Translation: Units to USD

**What**: `RedeemFee` is stored in the table as a unit quantity (not USD). This report multiplies it by the close rate to express the fee in USD terms.

**Columns/Parameters Involved**: `RedeemFee`, `AmountOnClose`, `Units`

**Rules**:
- `CloseRate = AmountOnClose / Units` - the per-unit USD price at the moment the position was closed
- `RedeemFeeMoney(USD-Actual) = CloseRate * RedeemFee` - the fee in USD, using the actual settlement price (not the request-time price)
- `CalculatedInPercentage(AmountBased) = (RedeemFeeMoney / AmountOnClose) * 100` - the fee as a fraction of the total redemption proceeds, rounded to 2 decimal places, formatted as a VARCHAR percentage string (e.g., "1.50%")
- Division is unchecked - if `Units = 0` or `AmountOnClose = 0`, the query will raise a divide-by-zero error. The filter on `RedeemStatusID=8` (TransactionDone) implies AmountOnClose and Units should always be non-zero for these rows.

### 2.2 Report Scope Filters

**What**: The report is narrowed to a specific status, type, and time window to ensure only meaningful, settled data is analyzed.

**Columns/Parameters Involved**: `@TimeStamp`, `RedeemStatusID`, `RedeemTypeID`, `LastModificationDate`

**Rules**:
- `RedeemStatusID = 8` (TransactionDone): only fully completed redemptions are included. In-progress or failed redemptions are excluded because their fee amounts may be provisional.
- `RedeemTypeID = 0`: standard crypto redemptions only. NFT redemptions and other special types (non-zero RedeemTypeID) are excluded - they may have different fee structures that would skew the analysis.
- `LastModificationDate >= @TimeStamp`: time-window filter. `LastModificationDate` on a TransactionDone record represents the completion timestamp - so the report covers all redemptions that completed on or after the given timestamp.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeStamp | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Only redemptions with `LastModificationDate >= @TimeStamp` are returned. Pass the start of the desired analysis period (e.g., start of month, start of day). |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Customer who submitted the redemption. FK to `Customer.Customer.CID`. |
| 3 | RedeemID | INT | NO | - | CODE-BACKED | Primary key of the redemption record in `Billing.Redeem`. Uniquely identifies this redemption. |
| 4 | InstrumentID | INT | YES | - | CODE-BACKED | Crypto instrument being redeemed (e.g., Bitcoin, Ethereum). FK to `Trade.Instrument`. |
| 5 | Units | DECIMAL | YES | - | CODE-BACKED | Number of crypto units in the redemption request. Used as the divisor for rate calculations. |
| 6 | AmountOnRequest | DECIMAL | YES | - | CODE-BACKED | USD value of the position at the time the customer submitted the redemption request. Divided by Units to give OpenRate. |
| 7 | AmountOnClose | DECIMAL | YES | - | CODE-BACKED | USD value of the position at the time the trading position was actually closed (settlement price). Used as the denominator for the percentage calculation. |
| 8 | OpenRate | DECIMAL | NO | - | CODE-BACKED | Per-unit USD price at request time. Computed: `AmountOnRequest / Units`. Represents the customer's expected price when they submitted the redemption. |
| 9 | CloseRate | DECIMAL | NO | - | CODE-BACKED | Per-unit USD price at settlement (close) time. Computed: `AmountOnClose / Units`. The actual price at which the redemption was executed - may differ from OpenRate due to market movement between request and execution. |
| 10 | RedeemFee(Units) | DECIMAL | YES | - | CODE-BACKED | The redemption fee denominated in crypto units. Source: `Billing.Redeem.RedeemFee`. Stored in units, not USD; multiply by CloseRate to get the USD equivalent. |
| 11 | RedeemFeeMoney(USD-Actual) | DECIMAL | NO | - | CODE-BACKED | The redemption fee in USD, calculated using the actual close price: `CloseRate * RedeemFee`. This is the real monetary cost of the fee to the customer at settlement. |
| 12 | CalculatedInPercentage(AmountBased) | VARCHAR | NO | - | CODE-BACKED | The effective fee rate as a percentage of the total redemption proceeds (AmountOnClose). Computed: `ROUND((RedeemFeeMoney / AmountOnClose) * 100, 2)` formatted as "X.XX%". Allows direct comparison to the fee schedule in `Billing.RedeemFeeSettings.FeeInPercentage`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedeemID | Billing.Redeem | Direct SELECT with WHERE filter | Source of all financial data; filtered to TransactionDone standard redemptions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations / Analytics teams (PTL-93) | @TimeStamp | EXEC | Used for fee revenue analysis and fee schedule validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRedeemFeeExtendedDetails (procedure)
└── Billing.Redeem (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | SELECT with NOLOCK; filtered to RedeemStatusID=8, RedeemTypeID=0, LastModificationDate >= @TimeStamp |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations/Analytics tooling | External | Fee reporting and analysis (PTL-93) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Division risk | Technical | `AmountOnRequest / Units` and `AmountOnClose / Units` - Units must be non-zero; `(RedeemFeeMoney / AmountOnClose)` - AmountOnClose must be non-zero. The RedeemStatusID=8 filter mitigates this in practice |
| Status filter | Business rule | Only RedeemStatusID=8 (TransactionDone) - excludes in-progress, failed, or cancelled redemptions |
| Type filter | Business rule | Only RedeemTypeID=0 (standard) - NFT and special redemption types excluded |
| Percentage format | Technical | Result is CAST to VARCHAR with '%' suffix - returned as string, not DECIMAL |

---

## 8. Sample Queries

### 8.1 Get fee details for redemptions completed in the last 30 days
```sql
EXEC Billing.GetRedeemFeeExtendedDetails
    @TimeStamp = DATEADD(DAY, -30, GETUTCDATE());
```

### 8.2 Get fee details for redemptions completed in a specific month
```sql
EXEC Billing.GetRedeemFeeExtendedDetails
    @TimeStamp = '2026-02-01 00:00:00';
```

### 8.3 Validate fee percentage against configured fee settings
```sql
SELECT
    r.InstrumentID,
    r.RedeemID,
    r.CID,
    r.Units,
    r.AmountOnClose,
    r.RedeemFee,
    (r.AmountOnClose / r.Units) * r.RedeemFee AS FeeInUSD,
    rfs.FeeInPercentage AS ConfiguredFeePercent
FROM Billing.Redeem r WITH (NOLOCK)
INNER JOIN Billing.RedeemFeeSettings rfs WITH (NOLOCK)
    ON rfs.InstrumentID = r.InstrumentID
    AND rfs.RedeemTypeID = 0
WHERE r.RedeemStatusID = 8
  AND r.RedeemTypeID = 0
  AND r.LastModificationDate >= DATEADD(DAY, -7, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PTL-93 (referenced in DDL comment, Alexei B.) | Jira | Initial creation of the procedure for redemption fee extended reporting (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRedeemFeeExtendedDetails | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRedeemFeeExtendedDetails.sql*
