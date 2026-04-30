# Billing.RedeemFundingSettings

> Per-funding-type, per-player-level configuration defining how long after a customer's first deposit each payment method's funds must "age" before they count toward the customer's redeemable balance for crypto redemption.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 2 (PK + 1 UNIQUE NCI) |
| **Temporal** | Yes - SYSTEM_VERSIONING ON -> History.RedeemFundingSettings |

---

## 1. Business Meaning

Billing.RedeemFundingSettings controls which of a customer's deposits are eligible to back a crypto redemption, and how long each payment method must wait before its funds qualify. This is the central configuration table for the "redeemable amount" calculation engine.

When a customer requests a crypto redemption, the system must determine how much of their equity is backed by redeemable deposits (as opposed to non-redeemable sources like bonus funds or very recent deposits). The redeemable amount is computed by summing deposits from funding types listed in this table, subject to two time-based constraints:

1. **CancellationTimeInDays**: The deposit must have been made at least this many days after the customer's first-time deposit (FTD). Payment methods with chargeback/reversal risk (credit card, PayPal) have longer waiting periods before their deposits are considered "permanent."

2. **SlidingDaysToIgnore**: Deposits made within the last N days are excluded, regardless of FTD age. This protects against same-day or very recent deposits being redeemed immediately (anti-abuse for ACH and PWMB).

The table is organized by (PlayerLevelID, FundingTypeID) with a unique constraint - one row per combination. All 7 player levels have identical settings in current data, but the schema supports per-tier differentiation.

**125 rows**: 7 player levels x 20 redeemable funding types. All rows are active.

---

## 2. Business Logic

### 2.1 Redeemable Amount Calculation

**What**: GetRedeemValidationData uses this table to compute the "FundingRedeemableAmount" - the portion of all deposits that backs the customer's redeemable balance.

**Columns/Parameters Involved**: `FundingTypeID`, `PlayerLevelID`, `IsActive`, `CancellationTimeInDays`, `SlidingDaysToIgnore`

**Rules**:
- Only funding types listed in this table (with IsActive=1) contribute to the redeemable amount
- A deposit from funding type F counts if: `GETUTCDATE() >= DATEADD(day, CancellationTimeInDays, FTD_Date)`
  - Deposits from CreditCard (FundingTypeID=1) require 30+ days after FTD before they qualify
  - Deposits from WireTransfer (FundingTypeID=2) qualify immediately (CancellationTimeInDays=0)
  - UnionPay/AliPay/WeChat require 120 days (highest risk of reversal)
- A deposit also requires: `Deposit.ModificationDate <= DATEADD(day, -SlidingDaysToIgnore, GETUTCDATE())`
  - ACH and PWMB deposits made within the last 7 days are excluded entirely

**Diagram**:
```
Customer's deposits (Billing.Deposit)
        |
        JOIN Billing.Funding ON FundingID
        |
        JOIN Billing.RedeemFundingSettings ON FundingTypeID = FundingTypeID
                                              AND PlayerLevelID = Customer's PlayerLevel
                                              AND IsActive = 1
        |
        FILTER:  GETUTCDATE() >= FTD_Date + CancellationTimeInDays
        AND      Deposit.ModificationDate <= NOW - SlidingDaysToIgnore
        |
        SUM(Amount * ExchangeRate)
        |
        = FundingRedeemableAmount
```

**CancellationTimeInDays by funding type** (PlayerLevelID=1, representative):
| FundingTypeID | FundingType | CancellationDays | SlidingDaysToIgnore | Reason |
|--------------|-------------|-----------------|---------------------|--------|
| 1 | CreditCard | 30 | 0 | High chargeback risk - must age 30 days |
| 3 | PayPal | 30 | 0 | PayPal disputes window is ~30 days |
| 6 | Neteller | 14 | 0 | E-wallet reversal window |
| 8 | MoneyBookers (Skrill) | 14 | 0 | E-wallet reversal window |
| 22 | UnionPay | 120 | 0 | Very high chargeback risk for Chinese payment method |
| 25 | AliPay | 120 | 0 | Same - Chinese mobile payment |
| 26 | WeChat | 120 | 0 | Same - Chinese mobile payment |
| 29 | ACH | 7 | 7 | US bank transfers: 7-day hold + last 7 days excluded |
| 32 | PWMB | 0 | 7 | Immediate eligibility but last 7 days excluded |
| 2 | WireTransfer | 0 | 0 | Wire is immediate and permanent |
| 2,10,11,28,34-39,42 | Various | 0 | 0 | Immediate eligibility, no sliding window |

### 2.2 ACH Special Handling

**What**: ACH (FundingTypeID=29) has dual time-gating via both CancellationTimeInDays and SlidingDaysToIgnore.

**Rules**:
- CancellationTimeInDays=7: ACH deposits become redeemable only 7 days after FTD
- SlidingDaysToIgnore=7: ACH deposits made within the last 7 days are ALWAYS excluded from the calculation, even if the customer is past the FTD+7 day threshold
- The combined effect: ACH deposits must be (a) made 7+ days after FTD AND (b) older than 7 days from today
- This is the most cautious treatment because ACH transfers can be reversed/charged-back up to 60 days

**Diagram**:
```
ACH deposit made on Day 0
  FTD + 7 days check: deposit is eligible after Day 7 (FTD + 7)
  SlidingDaysToIgnore=7: deposit is excluded if made within last 7 days from today

  Day 0:  deposit made
  Day 1-6: EXCLUDED (less than 7 days old = sliding window)
  Day 7:   EXCLUDED (7 days old = boundary, depends on exact times)
  Day 8+:  ELIGIBLE (if also past FTD+7)
```

---

## 3. Data Overview

| FundingTypeID | FundingType | CancellationTimeInDays | SlidingDaysToIgnore | Risk Classification |
|--------------|-------------|------------------------|---------------------|---------------------|
| 1 | CreditCard | 30 | 0 | High - chargeback window |
| 2 | WireTransfer | 0 | 0 | Low - permanent |
| 3 | PayPal | 30 | 0 | High - dispute window |
| 6 | Neteller | 14 | 0 | Medium - e-wallet reversal |
| 8 | MoneyBookers/Skrill | 14 | 0 | Medium - e-wallet reversal |
| 10 | WebMoney | 0 | 0 | Low |
| 11 | Giropay | 0 | 0 | Low |
| 22 | UnionPay | 120 | 0 | Very High - Chinese payment |
| 25 | AliPay | 120 | 0 | Very High - Chinese payment |
| 26 | WeChat | 120 | 0 | Very High - Chinese payment |
| 28 | OnlineBanking | 0 | 0 | Low |
| 29 | ACH | 7 | 7 | High - US ACH chargeback |
| 32 | PWMB | 0 | 7 | Medium |
| 34 | iDEAL | 0 | 0 | Low |
| 35 | Trustly | 0 | 0 | Low |
| 36 | Przelewy24 | 0 | 0 | Low |
| 37 | POLI | 0 | 0 | Low |
| 38 | OpenBanking | 0 | 0 | Low |
| 39 | Payoneer | 0 | 0 | Low |
| 42 | EtoroOptions | 0 | 0 | Internal |

All rows identical across all 7 player levels (no VIP tier differentiation in current data).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key, auto-incremented. Not a business key - (PlayerLevelID, FundingTypeID) is the meaningful uniqueness pair. |
| 2 | PlayerLevelID | INT | NO | - | CODE-BACKED | Customer VIP tier for this configuration row. Part of the UNIQUE constraint. No DDL FK constraint. Values: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. GetRedeemValidationData filters by the calling customer's PlayerLevelID: `RS.PlayerLevelID = (SELECT PlayerLevelID FROM Customer.Customer WHERE CID = @CID)`. All levels currently have identical settings. |
| 3 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method for which this row defines redeemable aging rules. Part of the UNIQUE constraint. Implicit FK to Dictionary.FundingType(FundingTypeID) - no DDL constraint. 20 distinct funding types configured. Only funding types in this table (IsActive=1) contribute deposits toward the redeemable amount calculation. |
| 4 | CancellationTimeInDays | INT | NO | - | CODE-BACKED | Number of days after the customer's First Time Deposit (FTD) that must elapse before deposits from this funding type count toward the redeemable balance. Range: 0 (immediate) to 120 (4 months for UnionPay/AliPay/WeChat). Applied in GetRedeemValidationData as: `GETUTCDATE() >= DATEADD(dd, RS.CancellationTimeInDays, @FTDDate)`. Higher values indicate higher chargeback/reversal risk for the payment method. |
| 5 | IsActive | BIT | NO | - | CODE-BACKED | Whether this funding type is currently considered redeemable. All 125 current rows are active (IsActive=1). Setting to 0 would exclude all deposits from that funding type from the redeemable calculation without deleting the configuration. No DEFAULT defined in DDL - must be set explicitly on INSERT. |
| 6 | TimeStamp | DATETIME | YES | - | CODE-BACKED | Application-managed timestamp indicating when this configuration row was created or last materially changed. NULL allowed. In practice values span 2019-03-03 (original rows) through 2026-03-10 (recent updates). Not automatically maintained - set by calling application. |
| 7 | SlidingDaysToIgnore | INT | NO | 0 | CODE-BACKED | Number of days to exclude from the lookback window for recent deposits. A deposit made within the last SlidingDaysToIgnore days will NOT count toward the redeemable amount, even if it passes the CancellationTimeInDays check. Default=0 (no sliding exclusion). Currently non-zero only for ACH(29)=7 and PWMB(32)=7. Applied as: `BD.ModificationDate <= DATEADD(dd, -1 * RS.SlidingDaysToIgnore, GETUTCDATE())`. |
| 8 | Trace | (computed) | YES | - | CODE-BACKED | Computed column emitting JSON session context: `{"HostName": "...","AppName": "...","SUserName": "...","SPID": "...","DBName": "...","ObjectName": "..."}`. Populated from SQL Server built-in functions. Not persisted - computed on read. Used for operational diagnostics to identify which application last touched the row. |
| 9 | ValidFrom | DATETIME2(7) | NO | (system) | CODE-BACKED | Temporal period start - UTC timestamp when this version of the row became current. Set automatically by SQL Server on INSERT/UPDATE. |
| 10 | ValidTo | DATETIME2(7) | NO | (system) | CODE-BACKED | Temporal period end - UTC timestamp when this version expired. 9999-12-31 for all current rows. Rows moved to History.RedeemFundingSettings on UPDATE/DELETE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerLevelID | Dictionary.PlayerLevel | Implicit FK (no DDL constraint) | Links each row to the VIP tier it configures. |
| FundingTypeID | Dictionary.FundingType | Implicit FK (no DDL constraint) | Links each row to the payment method it configures. IsRedeemable flag on FundingType is used in the secondary funding redeemable calculation (DFT.IsRedeemable=1). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetRedeemValidationData | FundingTypeID, PlayerLevelID, IsActive, CancellationTimeInDays, SlidingDaysToIgnore | READER | Primary consumer - JOINs Billing.Funding ON FundingTypeID to compute the customer's FundingRedeemableAmount. Called for every redemption validation. |
| Billing.GetRedeemNFTValidationData | FundingTypeID, PlayerLevelID | READER | NFT redemption variant - same logic for redeemable deposit calculation |
| History.RedeemFundingSettings | - | TEMPORAL HISTORY | Receives superseded row versions on UPDATE |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemFundingSettings (table)
|- Dictionary.PlayerLevel (implicit - no DDL FK)
|- Dictionary.FundingType (implicit - no DDL FK)
└-- History.RedeemFundingSettings (temporal history, auto-managed)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PlayerLevel | Table | Implicit FK - PlayerLevelID values expected to match |
| Dictionary.FundingType | Table | Implicit FK - FundingTypeID values must be valid funding types |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetRedeemValidationData | Stored Procedure | READER - computes FundingRedeemableAmount for redemption eligibility |
| Billing.GetRedeemNFTValidationData | Stored Procedure | READER - NFT redemption eligibility check |
| History.RedeemFundingSettings | History Table | TEMPORAL - receives superseded row versions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingRedeemFundingSettings_TPL | CLUSTERED PK | ID ASC | - | - | Active |
| UNQ_BillingRedeemFundingSettings_TPL | NONCLUSTERED UNIQUE | PlayerLevelID ASC, FundingTypeID ASC, CancellationTimeInDays ASC, IsActive ASC, TimeStamp ASC | - | - | Active |

Note: The UNIQUE constraint covers 5 columns including CancellationTimeInDays, IsActive, and TimeStamp. This is an unusual composite uniqueness definition - it allows multiple rows with the same (PlayerLevelID, FundingTypeID) if other columns differ. In practice all rows are unique on (PlayerLevelID, FundingTypeID) alone.

Index options: FILLFACTOR=95.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingRedeemFundingSettings_TPL | PRIMARY KEY CLUSTERED | ID must be unique |
| UNQ_BillingRedeemFundingSettings_TPL | UNIQUE NONCLUSTERED | (PlayerLevelID, FundingTypeID, CancellationTimeInDays, IsActive, TimeStamp) must be unique |
| DF_BillingRedeemFundingSettings_TPL_SlidingDaysToIgnore | DEFAULT | SlidingDaysToIgnore defaults to 0 on INSERT |

### 7.3 Temporal Configuration

| Property | Value |
|----------|-------|
| System Versioning | ON |
| History Table | History.RedeemFundingSettings |
| Period Start | ValidFrom (DATETIME2(7)) |
| Period End | ValidTo (DATETIME2(7)) |

---

## 8. Sample Queries

### 8.1 Get full funding type eligibility matrix for redemption

```sql
SELECT
    rfs.PlayerLevelID,
    pl.Name AS PlayerLevel,
    rfs.FundingTypeID,
    ft.Name AS FundingTypeName,
    rfs.CancellationTimeInDays,
    rfs.SlidingDaysToIgnore,
    rfs.IsActive,
    CASE
        WHEN rfs.CancellationTimeInDays = 0 AND rfs.SlidingDaysToIgnore = 0 THEN 'Immediate'
        WHEN rfs.CancellationTimeInDays <= 14 THEN 'Short wait'
        WHEN rfs.CancellationTimeInDays <= 30 THEN 'Month wait'
        ELSE 'Long wait (120+ days)'
    END AS WaitCategory
FROM [Billing].[RedeemFundingSettings] rfs WITH (NOLOCK)
INNER JOIN [Dictionary].[PlayerLevel] pl WITH (NOLOCK) ON pl.PlayerLevelID = rfs.PlayerLevelID
INNER JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON ft.FundingTypeID = rfs.FundingTypeID
ORDER BY rfs.PlayerLevelID, rfs.CancellationTimeInDays DESC, ft.Name
```

### 8.2 Simulate redeemable deposit calculation for a customer

```sql
DECLARE @CID INT = 12345
DECLARE @FTDDate DATETIME = (SELECT ModificationDate FROM Billing.Deposit WHERE IsFTD = 1 AND CID = @CID)

SELECT
    ft.Name AS FundingType,
    BD.Amount,
    BD.ExchangeRate,
    BD.Amount * BD.ExchangeRate AS USD_Amount,
    RS.CancellationTimeInDays,
    RS.SlidingDaysToIgnore,
    DATEADD(dd, RS.CancellationTimeInDays, @FTDDate) AS EligibleAfter,
    BD.ModificationDate AS DepositDate,
    CASE WHEN GETUTCDATE() >= DATEADD(dd, RS.CancellationTimeInDays, @FTDDate)
              AND BD.ModificationDate <= DATEADD(dd, -1 * RS.SlidingDaysToIgnore, GETUTCDATE())
         THEN 'REDEEMABLE' ELSE 'NOT YET' END AS Status
FROM [Billing].[Deposit] BD WITH (NOLOCK)
INNER JOIN [Billing].[Funding] BF WITH (NOLOCK) ON BD.FundingID = BF.FundingID
INNER JOIN [Billing].[RedeemFundingSettings] RS WITH (NOLOCK)
    ON BF.FundingTypeID = RS.FundingTypeID
    AND RS.PlayerLevelID = (SELECT PlayerLevelID FROM Customer.Customer WITH (NOLOCK) WHERE CID = @CID)
    AND RS.IsActive = 1
INNER JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON ft.FundingTypeID = BF.FundingTypeID
WHERE BD.CID = @CID AND BD.PaymentStatusID = 2
ORDER BY BD.ModificationDate DESC
```

### 8.3 View configuration change history for a funding type

```sql
-- See history of ACH (FundingTypeID=29) settings across time
SELECT
    rfs.PlayerLevelID,
    rfs.FundingTypeID,
    rfs.CancellationTimeInDays,
    rfs.SlidingDaysToIgnore,
    rfs.IsActive,
    rfs.ValidFrom,
    rfs.ValidTo
FROM [Billing].[RedeemFundingSettings]
FOR SYSTEM_TIME ALL
WHERE FundingTypeID = 29
ORDER BY PlayerLevelID, ValidFrom
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources directly reference this specific table. The redeemable amount calculation context is described through the Billing.Redeem and GetRedeemValidationData documentation.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.RedeemFundingSettings | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.RedeemFundingSettings.sql*
