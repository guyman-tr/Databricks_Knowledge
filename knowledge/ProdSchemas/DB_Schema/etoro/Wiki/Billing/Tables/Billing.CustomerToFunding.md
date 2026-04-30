# Billing.CustomerToFunding

> Customer-to-payment-instrument junction table. Each row represents one customer's relationship with one registered payment method (FundingID), recording when it was first linked, last used, its per-customer activation status, and whether it is blocked or excluded from refunds. Every customer's "saved payment methods" list is derived from this table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CID, FundingID) - COMPOSITE PRIMARY KEY CLUSTERED |
| **Row Count** | ~9,260,947 rows |
| **Partition** | N/A - filegroup PRIMARY; DATA_COMPRESSION = PAGE |
| **Indexes** | 1 CLUSTERED composite PK; 1 NC index on FundingID |

---

## 1. Business Meaning

`Billing.CustomerToFunding` is the association registry between eToro customers and their saved payment instruments. While `Billing.Funding` holds the payment method data globally (shared across customers who happen to use the same card/account), `Billing.CustomerToFunding` records *which customer* is linked to *which funding*, when that link was established, how it was classified (deposit type, reason), and the current per-customer status of that instrument.

Key business roles:
- **Saved Payment Methods**: The application queries this table (joined to `Billing.Funding`) to show a customer their saved cards, wallets, and bank accounts.
- **Activation/Deactivation**: A payment method can be active (CustomerFundingStatusID=1) or deactivated (=0) for a specific customer independently of whether the underlying Billing.Funding record is globally blocked.
- **Refund Eligibility**: `IsRefundExcluded=1` prevents this funding from being used as a refund destination for this customer, regardless of global funding state.
- **Compliance Blocking**: `IsBlocked` mirrors the Billing.Funding block state at the per-customer level and is updated atomically via `Billing.FundingBlock`.
- **Audit History**: Every update is written to `History.ActiveCustomerToFunding` via OUTPUT clauses in all mutating procedures.

Date range: 2017-01-01 to present (current). 9.26M customer-funding links as of March 2026.

---

## 2. Business Logic

### 2.1 Payment Method Registration - Upsert Pattern

**What**: When a customer uses or adds a payment method, the system creates or updates the CustomerToFunding link.

**Primary procedure**: `Billing.CustomerToFunding_Upsert` (MERGE-based)
- If row (CID, FundingID) does NOT exist -> INSERT with CustomerFundingStatusID=0, DepositTypeID=1 (Regular), ReasonID=6 (ByUser)
- If row exists -> UPDATE LastUsedDate = GETUTCDATE() only (status/type not changed)

**Secondary procedure**: `Billing.CustomerToFunding_Add`
- Explicit INSERT; used for cases requiring explicit DepositTypeID/ReasonID
- Relies on table DEFAULT for CustomerFundingStatusID (1 = Active)

**Note on status default mismatch**: The table DEFAULT for CustomerFundingStatusID is `(1)` (Active), but `CustomerToFunding_Upsert` passes `@CustomerFundingStatusID = 0` on INSERT. This means: links created via `_Add` start as Active; links created via `_Upsert` start as Deactivated and must be explicitly activated via `_UpdateStatus`.

### 2.2 CustomerFundingStatusID State Machine

**Distribution**: 0=4,668,046 (50.4%), 1=4,582,490 (49.5%), 2=2,397, 3=2,922, 4=5,092

| StatusID | Label | Setter | Meaning |
|----------|-------|--------|---------|
| 0 | Deactivated | `Billing.DeactivateFunding`, `Billing.DeactivateCustomerCreditCard` | Payment method is inactive for this customer; not shown in saved payment methods |
| 1 | Active | `Billing.CustomerToFunding_UpdateStatus`, table DEFAULT | Payment method is active; shown in saved payment methods; eligible for deposits |
| 2 | Unknown | Unknown - inferred as intermediate state | NAME-INFERRED: possibly a pending/verification state |
| 3 | RemovedFromDeposit | `Billing.CustomerToFunding_UpdateStatus` | Method exists in history but is filtered out from deposit flows when `@FilterRemovedFromDeposit=1` |
| 4 | Extended-Active | `Billing.CustomerToFunding_UpdateStatus` (PAYUSOLA-6470, Mar 2023) | Added in PAYUSOLA-6470; treated as "visible" alongside status 1 and 3 in `GetCustomerLastFundingByFundingType`; exact business semantics per ticket |

**Active for payment lookup**: Statuses 1, 3, 4 are returned by `GetCustomerLastFundingByFundingType`. Only status=1 is returned by `GetSavedCreditCards`, `GetFundingIDByAccountDetailsPWMB`, and `GetRecurringEligibility`.

### 2.3 Blocking Logic

**What**: When a payment instrument is blocked, both `Billing.Funding` and all associated `Billing.CustomerToFunding` rows are updated atomically.

**Procedure**: `Billing.FundingBlock`
- Updates `Billing.Funding.IsBlocked`, `BlockedDescription`, `BlockedAt`, `ManagerID`
- Updates ALL `Billing.CustomerToFunding` rows for that FundingID: sets `IsBlocked`, `IsRefundExcluded`, `ManagerID`, `BlockedAt`, `BlockedDescription`, `BlockManagerID`
- Both updates are in a single transaction
- Guard: FundingID=1 is protected from blocking (system/default funding record)
- OUTPUT of CTF rows goes to `History.ActiveCustomerToFunding`

**Current state**: All 9.26M active rows have `IsBlocked=false` (confirmed via distribution query). The CTF-level block flag mirrors the Billing.Funding block state.

### 2.4 Refund Exclusion

**Column**: `IsRefundExcluded BIT NOT NULL DEFAULT 0`

**What**: Marks whether this funding is excluded from use as a refund destination for this customer.

**Distribution**: 150,844 rows (1.6%) are refund-excluded. All 9.26M have `IsBlocked=false`.

**Where used**: `Billing.GetCustomerLastFundingByFundingType` filters with `@FilterWithdrawBlocked = 1` -> requires `cidIsRefundExcluded = 0 AND sysIsRefundExcluded = 0`.

### 2.5 Deposit Type Classification

**Column**: `DepositTypeID INT NULL FK -> Dictionary.DepositType`

**What**: Classifies the type of deposit this funding was last used for when it was registered/linked.

| DepositTypeID | Label | Description | ApplyFtd | Count |
|---------------|-------|-------------|----------|-------|
| 1 | Regular | Regular payment | Yes | 9,249,444 (99.88%) |
| 2 | CvvFree | Payment without CVV | Yes | 10,768 (0.12%) |
| 3 | Recurring | Recurring payment | Yes | 705 (0.008%) |
| NULL | - | Not set | - | 30 (0.0003%) |

### 2.6 Reason Classification

**Column**: `ReasonID INT NULL FK -> Dictionary.DepositTypeReason`

**What**: Records the reason/outcome when this funding was last registered for this customer.

| ReasonID | Reason | Count |
|----------|--------|-------|
| 6 | ByUser | 9,234,335 (99.71%) |
| 1 | FtdApproved | 20,138 (0.22%) |
| 8 | NameConflict | 2,847 (0.03%) |
| 2 | Declined | 1,902 (0.02%) |
| 3 | CvvRefused | 1,637 (0.02%) |
| 4 | CountryRestriction | 58 (0.0006%) |
| NULL | Not set | 30 (0.0003%) |

The dominant reason (99.71%) is `ByUser` (ReasonID=6) - self-service registrations.

### 2.7 Audit History

All mutations to `Billing.CustomerToFunding` are captured in `History.ActiveCustomerToFunding` via OUTPUT clauses. The pattern is used in:
- `CustomerToFunding_UpdateStatus` - status/refund-exclusion changes
- `CustomerToFunding_Upsert` - UPDATE leg (LastUsedDate changes)
- `CustomerToFunding_UpdateRecord` - full record updates
- `CustomerToFunding_UpdateType` - type/reason changes
- `FundingBlock` / `BlockCurrentMeanOfPayment` - blocking events
- `DeactivateFunding` / `DeactivateCustomerCreditCard` - deactivation events

**IsVerified column**: Added PAYIL-5743 (Jan 2023). Currently only 7 rows (4+3) have `IsVerified=true`, suggesting this feature is not yet widely used.

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **CID** | int | NOT NULL | - | Customer.CustomerStatic(CID) | [CODE-BACKED] Customer ID; part of composite PK. Identifies the eToro customer who registered this payment method. |
| **FundingID** | int | NOT NULL | - | Billing.Funding(FundingID) | [CODE-BACKED] Payment instrument ID; part of composite PK. References the global Billing.Funding record for this payment method. |
| **Occurred** | datetime | NULL | GETUTCDATE() | - | [CODE-BACKED] UTC timestamp when this customer first linked this funding. Defaults to current time on INSERT. Range: 2017-01-01 to present. |
| **DepositTypeID** | int | NULL | - | Dictionary.DepositType(DepositTypeID) | [CODE-BACKED] Type of deposit this funding was last used for. 1=Regular (99.88%), 2=CvvFree (0.12%), 3=Recurring (0.008%). See 2.5 for full map. |
| **ReasonID** | int | NULL | - | Dictionary.DepositTypeReason(ReasonID) | [CODE-BACKED] Reason code for last registration event. 6=ByUser (99.71%), 1=FtdApproved (0.22%). See 2.6 for full map. |
| **LastUsedDate** | datetime | NOT NULL | GETUTCDATE() | - | [CODE-BACKED] UTC timestamp of last usage. Updated by CustomerToFunding_Upsert on each subsequent deposit attempt. Range: 2017-01-01 to present. |
| **CustomerFundingStatusID** | int | NOT NULL | (1) | - | [CODE-BACKED] Per-customer activation status of this payment method. 0=Deactivated (50.4%), 1=Active (49.5%), 3=RemovedFromDeposit (0.03%), 4=ExtendedActive/PAYUSOLA-6470 (0.05%), 2=Unknown (0.03%). See 2.2 for full state machine. |
| **IsBlocked** | bit | NOT NULL | (0) | - | [CODE-BACKED] Whether this customer's use of this funding is blocked. Set atomically with Billing.Funding.IsBlocked via Billing.FundingBlock. All 9.26M active rows are NOT blocked. |
| **IsRefundExcluded** | bit | NOT NULL | (0) | - | [CODE-BACKED] Whether this funding is excluded from refund payouts for this customer. 1.6% of rows are refund-excluded. Checked by GetCustomerLastFundingByFundingType with @FilterWithdrawBlocked=1. |
| **ManagerID** | int | NULL | - | BackOffice.Manager(ManagerID) [implicit] | [CODE-BACKED] ID of BO manager who last blocked/updated this record. NULL when the funding block mirrors the system-level block. Copied from Billing.Funding.ManagerID during FundingBlock. |
| **BlockedAt** | datetime | NULL | - | - | [CODE-BACKED] UTC timestamp when this record was blocked. Set by FundingBlock/BlockCurrentMeanOfPayment. NULL when not blocked. |
| **BlockedDescription** | varchar(255) | NULL | - | - | [CODE-BACKED] Human-readable reason for blocking. Set by FundingBlock procedure. Mirrors Billing.Funding.BlockedDescription. |
| **IsVerified** | bit | NOT NULL | (0) | - | [CODE-BACKED] Verification flag added PAYIL-5743 (Jan 2023). Only 7 rows are true; feature is sparse. Included in all History.ActiveCustomerToFunding OUTPUT clauses. |
| **BlockManagerID** | int | NULL | - | BackOffice.Manager(ManagerID) [implicit] | [CODE-BACKED] ID of the BO manager who issued the block command. Distinct from ManagerID; added to FundingBlock procedure (PAYIL-5724, Jan 2023). |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_Billing_CustomerToFunding | CLUSTERED | (CID ASC, FundingID ASC) | FILLFACTOR=90; DATA_COMPRESSION=PAGE; Primary lookup by customer |
| IX_BillingCustomerToFunding | NONCLUSTERED | FundingID ASC | FILLFACTOR=95; DATA_COMPRESSION=PAGE; Supports lookups by FundingID (e.g., when blocking all customers for a funding) |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.CustomerToFunding_Upsert` | MERGE-based add-or-touch: INSERT with status=0 if new, UPDATE LastUsedDate if existing |
| `Billing.CustomerToFunding_Add` | Explicit INSERT with specified DepositTypeID/ReasonID; status defaults to 1 (Active) |
| `Billing.CustomerToFunding_UpdateStatus` | Updates CustomerFundingStatusID and optionally IsRefundExcluded/LastUsedDate |
| `Billing.CustomerToFunding_UpdateRecord` | Full update of DepositTypeID, ReasonID, CustomerFundingStatusID with history capture |
| `Billing.CustomerToFunding_UpdateType` | Updates only DepositTypeID and ReasonID |
| `Billing.DeactivateFunding` | Sets CustomerFundingStatusID=0 for one (CID, FundingID) |
| `Billing.DeactivateCustomerCreditCard` | Sets status=0 for all credit cards (FundingTypeID=1) for a customer |
| `Billing.FundingBlock` | Atomically blocks Billing.Funding + all CustomerToFunding rows for a FundingID |
| `Billing.GetFundingForCustomer` | Returns fundings for a customer filtered by FundingTypeID and optional status |
| `Billing.GetSavedCreditCards` | Returns saved credit cards; filters CustomerFundingStatusID=1 only |
| `Billing.GetCustomerLastFundingByFundingType` | Returns last-used fundings for customer; includes status 1, 3, 4 |
| `Billing.GetRecurringEligibility` | Checks recurring payment eligibility; marks IsVisible=1 for status=1 |
| `Billing.GetFundingCustomerDetails` | Returns customer+funding details joined through this table |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Funding | Many-to-one | CustomerToFunding.FundingID = Funding.FundingID | Explicit FK. The global payment instrument record. |
| Customer.CustomerStatic | Many-to-one | CustomerToFunding.CID = CustomerStatic.CID | Explicit FK. The customer who owns this payment method link. |
| Dictionary.DepositType | Many-to-one | CustomerToFunding.DepositTypeID = DepositType.DepositTypeID | Explicit FK. |
| Dictionary.DepositTypeReason | Many-to-one | CustomerToFunding.ReasonID = DepositTypeReason.ReasonID | Explicit FK. |
| History.ActiveCustomerToFunding | Parent | OUTPUT INTO | All mutations captured in history table via OUTPUT clauses |
| Billing.Deposit | Reference | Deposit.FundingID -> Funding.FundingID -> CustomerToFunding.FundingID | Indirect: `BlockCurrentMeanOfPayment` only blocks if FundingID was used in a deposit |

---

*Quality: 9.1/10 | 13 CODE-BACKED, 2 NAME-INFERRED | Phases: 1,2,3,4,5,6,8,9,11*
