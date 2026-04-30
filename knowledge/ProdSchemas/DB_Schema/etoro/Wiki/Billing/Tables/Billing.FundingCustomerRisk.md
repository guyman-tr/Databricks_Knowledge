# Billing.FundingCustomerRisk

> Per-customer-per-funding risk flag table. Each row tags a specific customer's use of a specific payment instrument with a risk classification (e.g., name conflict, velocity breach). A customer-funding pair can carry multiple risk labels simultaneously. Currently used exclusively for DepositNameConflict detection.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CID, FundingID, RiskStatusID) - COMPOSITE PRIMARY KEY CLUSTERED |
| **Row Count** | ~1,259 rows |
| **Partition** | N/A - filegroup PRIMARY |
| **Indexes** | 1 CLUSTERED composite PK (FILLFACTOR=95) |

---

## 1. Business Meaning

`Billing.FundingCustomerRisk` records risk flags on specific customer-payment-method combinations. While `Billing.FundingCustomerRisk` is structured to hold any of the 90 risk statuses from `Dictionary.RiskStatus`, live data shows only RiskStatusID=7 (DepositNameConflict) is currently used.

The primary use case: when a customer deposits using a payment method where the cardholder/account name conflicts with the customer's registered name, a DepositNameConflict flag is created. The procedure `Billing.NameConflictShouldNotify` checks this table to determine whether a notification was already sent for the conflict (avoiding duplicate notifications).

This table is NOT the primary risk management audit log (that role belongs to Billing.Deposit.RiskManagementStatusID and Billing.RiskManagementCheck). It is a lightweight tag-set on customer-funding pairs for risk alerting.

Date range: 2024-12-23 to 2026-01-18. Only 1,259 rows in 14 months - low-volume, targeted usage.

---

## 2. Business Logic

### 2.1 Flag Registration - Deduplication-Safe Insert

**Procedure**: `Billing.FundingCustomerRisk_Add(@CID, @FundingID, @RiskStatusID)`

**Pattern**: INSERT ... EXCEPT SELECT (idempotent insert - silently skips if flag already exists):
```sql
INSERT INTO Billing.FundingCustomerRisk (CID, FundingID, RiskStatusID)
SELECT @CID, @FundingID, @RiskStatusID
EXCEPT
SELECT CID, FundingID, RiskStatusID FROM Billing.FundingCustomerRisk
WHERE CID = @CID AND FundingID = @FundingID AND RiskStatusID = @RiskStatusID
```

This ensures calling the add procedure twice for the same (CID, FundingID, RiskStatus) is safe; no duplicates and no errors.

### 2.2 Deposit-Sourced Risk Flagging

**Procedure**: `Billing.FundingCustomerRisk_AddByDeposit(@CID, @DepositID, @RiskStatusID)`

Resolves FundingID from Billing.Deposit.DepositID, then calls `FundingCustomerRisk_Add`. Used when a deposit event triggers a risk flag.

### 2.3 Withdraw-Sourced Risk Flagging

**Procedure**: `Billing.FundingCustomerRisk_AddByWithdraw(@CID, @WithdrawID, @RiskStatusID)` *(inferred)*

Mirror of `_AddByDeposit` for the withdrawal path.

### 2.4 Notification Guard - NameConflict

**Procedure**: `Billing.NameConflictShouldNotify(@CID, @FundingID, @WasNotified OUT)`

Checks for existence of RiskStatusID=7 row for the (CID, FundingID) pair:
- Row exists -> `@WasNotified = 1` -> caller skips duplicate notification
- No row -> `@WasNotified = 0` -> caller proceeds to send notification

**Current state**: All 1,259 rows are RiskStatusID=7 (DepositNameConflict). All have AlertFlag=true (the default). No rows use any other RiskStatus from the 90 available.

### 2.5 Risk Status Taxonomy (Dictionary.RiskStatus)

The full lookup has 90 entries across 19 categories. Active entries most relevant to payment instrument risk:

| RiskStatusID | Name | RiskCategoryID | Notes |
|---|---|---|---|
| 2 | OverTheLimit | 1 | Amount threshold exceeded |
| 3 | FTDOverDailyLimit | 1 | First deposit over daily limit |
| 4 | TooManyCreditCards | 2 | Velocity - too many cards |
| 6 | BinToRegCountryConflict | 3 | BIN country vs registration country mismatch |
| **7** | **DepositNameConflict** | **3** | **Only value in live data - cardholder name vs customer name** |
| 28 | Name Conflict | 3 | Generic name conflict |
| 38 | OverTheLimitSingleDeposit | 1 | Single deposit over threshold |
| 39 | CreditCardVelocity | 2 | CC usage frequency |
| 40 | UserVelocity | 2 | User deposit frequency |
| 42 | CreditCardBruteForce | 7 | Repeated failed card attempts |
| 63 | BinInBlackList | 7 | BIN number in fraud blacklist |
| 64 | Suspicious Deposit Pattern | 7 | Pattern detection alert |
| 69 | RafDeclineFundingAlreadyExists | 7 | Referral abuse - declined funding reuse |
| 81 | WithdrawNameConflict | 16 | Withdrawal name conflict |
| 87 | WithdrawCountryConflict | 3 | Withdrawal country conflict |

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **CID** | int | NOT NULL | - | Customer.CustomerStatic(CID) | [CODE-BACKED] Customer ID; part of composite PK. Identifies the customer carrying this risk flag. |
| **FundingID** | int | NOT NULL | - | Billing.Funding(FundingID) | [CODE-BACKED] Payment instrument ID; part of composite PK. Identifies the specific payment method flagged. |
| **RiskStatusID** | int | NOT NULL | - | Dictionary.RiskStatus(RiskStatusID) | [CODE-BACKED] Risk classification. Part of composite PK. Currently always 7 (DepositNameConflict) in all 1,259 live rows. See 2.5 for full taxonomy. |
| **Occurred** | datetime | NOT NULL | GETUTCDATE() | - | [CODE-BACKED] UTC timestamp when this risk flag was created. Range: 2024-12-23 to 2026-01-18. |
| **AlertFlag** | bit | NULL | (1) | - | [CODE-BACKED] Whether an alert was/should be sent for this risk event. All 1,259 rows are true. Default is 1. Used as a notification marker. |
| **Modified** | datetime | NULL | - | - | [NAME-INFERRED] UTC timestamp of last modification to this risk record. Not set by current add procedures (always NULL in practice). |
| **ManagerID** | int | NULL | - | BackOffice.Manager(ManagerID) [implicit] | [NAME-INFERRED] ID of BO manager who reviewed/created this risk flag. Not set by current add procedures (always NULL in automated inserts). |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BillingFundingCustomerRisk | CLUSTERED | (CID ASC, FundingID ASC, RiskStatusID ASC) | FILLFACTOR=95. Supports fast lookup by customer and funding. |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.FundingCustomerRisk_Add` | Idempotent INSERT: adds (CID, FundingID, RiskStatusID) if not already present |
| `Billing.FundingCustomerRisk_AddByDeposit` | Resolves FundingID from DepositID, then calls `_Add` |
| `Billing.FundingCustomerRisk_AddByWithdraw` | Resolves FundingID from WithdrawID, then calls `_Add` |
| `Billing.FundingCustomerRisk_OccurredCheck` | Checks whether a risk flag exists/was recently created |
| `Billing.NameConflictShouldNotify` | Returns whether a DepositNameConflict (RiskStatusID=7) notification was already sent for (CID, FundingID) |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Funding | Many-to-one | FundingCustomerRisk.FundingID = Funding.FundingID | Explicit FK. The payment instrument carrying the risk flag. |
| Customer.CustomerStatic | Many-to-one | FundingCustomerRisk.CID = CustomerStatic.CID | Explicit FK. The customer. |
| Dictionary.RiskStatus | Many-to-one | FundingCustomerRisk.RiskStatusID = RiskStatus.RiskStatusID | Explicit FK. Risk classification lookup. |
| Billing.Deposit | Reference | AddByDeposit resolves FundingID via Deposit.DepositID | Indirect input source for flag creation. |

---

*Quality: 9.0/10 | 5 CODE-BACKED, 2 NAME-INFERRED | Phases: 1,2,3,4,5,8,9,11*
