# Billing.GetNumberOfDepositsPerTimeAndCID

> Returns the count of deposits made by a customer within a rolling time window, filtered by funding type and a caller-supplied list of payment statuses - used for deposit velocity and fraud checks at the cashier layer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row: COUNT(*) AS NumberOfDeposits |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetNumberOfDepositsPerTimeAndCID` answers a single question: "How many times has this customer deposited via a given payment method type, in the last N hours, where the deposit ended in one of these statuses?" The result is a deposit velocity count used by the payment validation layer before allowing a new deposit to proceed.

The procedure exists to enforce deposit frequency limits and detect abuse patterns. Without it, the system could not efficiently ask "has this customer already tried to deposit 5 times via credit card in the last 24 hours?" at the moment of a new deposit attempt. It serves as the primary data-layer gate for velocity-based fraud rules.

Data flows as follows: the `PaymentsValidationUser` service (cashier/deposit validation) calls this procedure during pre-deposit risk checks, passing the customer's CID, a time window, the funding type being used, and a comma-separated list of relevant statuses to count. The procedure queries `Billing.Deposit` joined to `Billing.Funding` and returns the count. The caller then applies its own threshold logic.

---

## 2. Business Logic

### 2.1 CSV Status ID Parsing (Inline String Split)

**What**: @PaymentStatusIDs is a comma-separated string of status IDs because SQL Server 2008-era code predated table-valued parameters for this use case. The procedure manually splits the string into a temp table before using it in an IN() filter.

**Columns/Parameters Involved**: `@PaymentStatusIDs`, temp table `#IDs`

**Rules**:
- The input string must be comma-delimited (e.g., `"2,5,13"`)
- The procedure appends a trailing comma if absent, then iterates with CHARINDEX/SUBSTRING to extract each number
- IDs are inserted as INT into `#IDs` and used in `PaymentStatusID IN (SELECT ID FROM #IDs)`
- Caller controls which statuses count toward velocity - allows different rules for Approved-only vs Approved+Pending checks

**Diagram**:
```
@PaymentStatusIDs = "2,5,13"
          |
          v
  Append trailing comma -> "2,5,13,"
          |
  WHILE CHARINDEX(',', ...) > 1
    INSERT INTO #IDs: 2, then 5, then 13
          |
          v
  SELECT COUNT(*) ... WHERE PaymentStatusID IN (SELECT ID FROM #IDs)
```

### 2.2 Rolling Time Window (UTC)

**What**: The lookback window is computed from GETUTCDATE(), not GETDATE(), ensuring time-zone-consistent velocity checks regardless of server locale.

**Columns/Parameters Involved**: `@NumberOfHours`, `Billing.Deposit.PaymentDate`

**Rules**:
- Threshold = `DATEADD(HOUR, 0 - @NumberOfHours, GETUTCDATE())`
- Default window is 24 hours (`@NumberOfHours INT = 24`)
- Caller can override for tighter (e.g., 1-hour) or wider (e.g., 72-hour) windows
- `PaymentDate` in `Billing.Deposit` is the submission timestamp; see `Billing.Deposit` for full lifecycle

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Filters `Billing.Deposit.CID` to a single customer. Matches the eToro customer account (same CID used across all Billing/Customer schemas). |
| 2 | @NumberOfHours | INT | NO | 24 | CODE-BACKED | Rolling lookback window in hours. Deposits with `PaymentDate >= DATEADD(HOUR, 0-@NumberOfHours, GETUTCDATE())` are counted. Default 24 = past 24 hours. Caller sets to 1, 6, 24, 72 etc. depending on the velocity rule being evaluated. |
| 3 | @FundingType | INT | NO | - | CODE-BACKED | Funding type identifier. Filters `Billing.Funding.FundingTypeID` - ensures only deposits made via the specific payment method type (e.g., credit card, bank transfer) are counted. Refers to Dictionary.FundingType values. |
| 4 | @PaymentStatusIDs | varchar(100) | NO | - | CODE-BACKED | Comma-separated list of `PaymentStatusID` values to include in the count (e.g., `"2,5,13"`). The procedure parses this string into temp table `#IDs` and uses it as an IN() filter on `Billing.Deposit.PaymentStatusID`. Caller controls which statuses qualify - e.g., "count only approved deposits" vs "count all non-declined attempts". See `Dictionary.PaymentStatus` for full value map. |
| 5 | NumberOfDeposits (return) | INT | - | - | CODE-BACKED | Output: COUNT(*) of `Billing.Deposit` rows matching all supplied filters. Scalar count returned as a single-column, single-row result set. Caller applies threshold logic (e.g., if > 5 then block). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit.CID | Lookup | Filters deposit records to the specified customer |
| @FundingType | Billing.Funding.FundingTypeID | Lookup | Filters funding instrument records to the specified payment method type |
| @PaymentStatusIDs | Billing.Deposit.PaymentStatusID | Lookup | IN() filter on deposit payment status; values from Dictionary.PaymentStatus |
| @NumberOfHours | Billing.Deposit.PaymentDate | Filter | Rolling time window applied to the deposit submission timestamp |
| (JOIN) | Billing.Funding | JOIN | Joined via Billing.Deposit.FundingID = Billing.Funding.FundingID to apply the funding type filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PaymentsValidationUser | GRANT EXECUTE | Permission | The payments validation service (cashier layer) has EXECUTE permission - this is the primary caller for pre-deposit velocity checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetNumberOfDepositsPerTimeAndCID (procedure)
├── Billing.Deposit (table)
└── Billing.Funding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source; COUNT(*) across rows filtered by CID, PaymentDate window, PaymentStatusID list |
| Billing.Funding | Table | JOINed via FundingID to apply the FundingTypeID filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PaymentsValidationUser | DB Security Principal | EXECUTE permission granted - cashier/payment validation service calls this for deposit velocity checks |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Key execution note**: Performance depends on indexes on `Billing.Deposit` covering `(CID, PaymentDate, PaymentStatusID, FundingID)`. The temp table `#IDs` is a legacy string-split approach; modern callers could pass a table-valued parameter instead, but no such refactor has been done.

---

## 8. Sample Queries

### 8.1 Count approved credit card deposits in the last 24 hours for a customer
```sql
-- PaymentStatusID 2 = Approved, FundingTypeID 1 = Credit Card
EXEC [Billing].[GetNumberOfDepositsPerTimeAndCID]
    @CID = 12345678,
    @NumberOfHours = 24,
    @FundingType = 1,
    @PaymentStatusIDs = '2,'
```

### 8.2 Count all non-declined deposit attempts (any status) in the last 6 hours
```sql
-- Example: status IDs 1=New, 2=Approved, 5=InProcess, 13=Pending
EXEC [Billing].[GetNumberOfDepositsPerTimeAndCID]
    @CID = 12345678,
    @NumberOfHours = 6,
    @FundingType = 1,
    @PaymentStatusIDs = '1,2,5,13,'
```

### 8.3 Check deposit velocity to understand the underlying data
```sql
-- Inspect the raw deposits that would be counted for a given customer + window
SELECT
    BD.DepositID,
    BD.PaymentDate,
    BD.PaymentStatusID,
    BF.FundingTypeID,
    BD.Amount,
    BD.CurrencyID
FROM Billing.Deposit BD WITH (NOLOCK)
INNER JOIN Billing.Funding BF WITH (NOLOCK)
    ON BD.FundingID = BF.FundingID
WHERE BD.CID = 12345678
  AND BD.PaymentDate >= DATEADD(HOUR, -24, GETUTCDATE())
  AND BD.PaymentStatusID IN (2, 5, 13)
  AND BF.FundingTypeID = 1
ORDER BY BD.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetNumberOfDepositsPerTimeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetNumberOfDepositsPerTimeAndCID.sql*
