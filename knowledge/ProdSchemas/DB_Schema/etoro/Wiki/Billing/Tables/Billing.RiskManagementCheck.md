# Billing.RiskManagementCheck

> Risk management rejection audit log for legacy Billing.Payment. Each row records that a specific payment (PaymentID) was blocked or flagged for a specific risk reason (RiskManagementStatusID). Multiple rows per payment are possible when a payment triggers multiple risk rules. 7,253 rows. IDENTITY PK NONCLUSTERED (heap) with 2 supporting NC indexes. The only writer is Billing.RiskManagementCheckAdd, called directly from application code (no SP callers in the Billing schema). 69 distinct risk status codes defined in Dictionary.RiskManagementStatus.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RiskManagementCheckID - IDENTITY(1,1) PRIMARY KEY NONCLUSTERED |
| **Row Count** | 7,253 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 NONCLUSTERED PK on RiskManagementCheckID; 2 NONCLUSTERED on PaymentID, RiskManagementStatusID (FILLFACTOR=90) |

---

## 1. Business Meaning

`Billing.RiskManagementCheck` is the risk-gate rejection log for the legacy payment flow. When the application's risk management engine evaluated a payment (in `Billing.Payment`) and determined it should be blocked or flagged, it called `Billing.RiskManagementCheckAdd` to record the specific reason.

**Key characteristics**:
- **No unique constraint on PaymentID**: A single payment can have multiple rows if it fails multiple risk rules (e.g., both CardIsBlocked and OverTheLimit).
- **Application-driven**: `RiskManagementCheckAdd` has no callers within the Billing schema's stored procedures. The risk evaluation logic lives in the application layer (deposit/payment API), which calls this procedure to persist each rejection reason.
- **FK to Payment**: Each check is anchored to a specific PaymentID in `Billing.Payment`.
- **69 risk codes**: `Dictionary.RiskManagementStatus` defines the full vocabulary from simple blocks (CardIsBlocked, OverTheLimit) to sophisticated rules (CreditCardVelocity, SiftWorkFlow, KYC levels, ML, IPConflict).

**Distribution of risk reasons in production** (7,253 rows):
| RiskManagementStatusID | Name | Count | % |
|------------------------|------|-------|---|
| 12 | OverTheLimit | 3,592 | 49.5% |
| 2 | CardIsBlocked | 2,028 | 28.0% |
| 13 | DeclinedTooManyCreditCards | 587 | 8.1% |
| 6 | BlockedPayPalAccount | 444 | 6.1% |
| 10 | DeclinedBlackListCountry | 208 | 2.9% |
| 11 | DeclinedHighRiskDeposit | 186 | 2.6% |
| 3 | BinInBlackList | 151 | 2.1% |
| 4 | MemberLimit | 29 | 0.4% |
| 7 | DeclineBlockedNeteller | 28 | 0.4% |

Nearly half of all checks are `OverTheLimit` (deposit limit exceeded), followed by `CardIsBlocked` (card on blocked list). These are the two most common risk-gate triggers in the legacy payment system.

**Note**: The modern Billing.Deposit flow may have its own risk logging mechanism. This table covers only the Billing.Payment era.

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **RiskManagementCheckID** | int IDENTITY(1,1) | NOT NULL | Auto | - | [CODE-BACKED] Surrogate PK. NOT FOR REPLICATION. NONCLUSTERED PK -> table is a heap. Auto-increment; max observed ~7260. |
| **PaymentID** | int | NOT NULL | - | Billing.Payment(PaymentID) | [CODE-BACKED] The payment that failed the risk check. Explicit FK. NC index BRMC_PAYMENT supports lookup by payment. One payment can have multiple rows (no unique constraint). |
| **RiskManagementStatusID** | int | NOT NULL | - | Dictionary.RiskManagementStatus(RiskManagementStatusID) | [CODE-BACKED] The specific risk rule that triggered. Explicit FK. 69 possible values in Dictionary.RiskManagementStatus. NC index BRMC_RISKMANAGEMENTSTATUS supports status-level reporting. Key values: 2=CardIsBlocked, 3=BinInBlackList, 4=MemberLimit, 6=BlockedPayPalAccount, 10=DeclinedBlackListCountry, 11=DeclinedHighRiskDeposit, 12=OverTheLimit, 13=DeclinedTooManyCreditCards, 32-35=KYCLevel0-3, 47=ML, 48=IPConflict, 67=SiftWorkFlow. |

---

## 3. Dictionary.RiskManagementStatus - Full Value Map

| ID | Name | Category |
|----|------|----------|
| 1 | Success | (non-rejection) |
| 2 | CardIsBlocked | Card rules |
| 3 | BinInBlackList | Card rules |
| 4 | MemberLimit | Deposit limits |
| 5 | FundingTypeLimit | Deposit limits |
| 6 | BlockedPayPalAccount | Account blocks |
| 7 | DeclineBlockedNetellerAccount | Account blocks |
| 8 | DeclinedBlockedMoneyBookersAccount | Account blocks |
| 9 | DeclinedBlockedWebMoneyAccount | Account blocks |
| 10 | DeclinedBlackListCountry | Geography |
| 11 | DeclinedHighRiskDeposit | Risk scoring |
| 12 | OverTheLimit | Deposit limits |
| 13 | DeclinedTooManyCreditCards | Card rules |
| 14-16 | BlockedGiropay/ELV/Direct24Account | Account blocks |
| 17 | MultipleDepositsAggregatedAmount | Velocity |
| 18 | LoginToRegCountryConflict | Geography |
| 19 | BlockedSofortAccount | Account blocks |
| 20 | OverTheLimitSingleDeposit | Deposit limits |
| 21 | BinToRegCountryConflict | Geography |
| 22 | FTDOverDailyLimit | Deposit limits |
| 23 | HighRiskLoginCountry | Geography |
| 24 | BlockedFunding | Account blocks |
| 25 | FraudRequestResponseMismatch | Fraud |
| 26 | CreditCardVelocity | Velocity |
| 27 | UserVelocity | Velocity |
| 28 | First24HVelocity | Velocity |
| 29 | CreditCardBruteForce | Velocity |
| 30 | UserBlockedDeposit | Account blocks |
| 31 | UserNeedUpdateBillingDetails | KYC |
| 32-35 | KYCLevel0/1/2/3 | KYC |
| 36 | LabelPaymentRestriction | Account blocks |
| 37 | KYCLevel3PendingReview | KYC |
| 38 | RafDeclineFundingAlreadyExists | Business rule |
| 39 | UsDepositDecline | Geography |
| 40 | HighRiskFATFCountry | Geography |
| 41 | AsicNoSuitabilityTest | Compliance |
| 43 | PendingVerification | KYC |
| 44 | RestrictedCountryPayPal | Geography |
| 45 | LinkedAccountRestriction | Account blocks |
| 46 | FcaPendingVerification | Compliance |
| 47 | ML | Fraud (Machine Learning) |
| 48 | IPConflict | Fraud |
| 49 | CustomerToFundingViolation | Business rule |
| 50 | FundingTypeVelocity | Velocity |
| 51 | FundingTypeAggregatedAmount | Velocity |
| 52 | InsufficientFundsOrBalanceUnavailable | External |
| 53 | ACHAccessTokenExpired | External |
| 54 | FirstHoursFromFtdVelocity | Velocity |
| 55 | ThreeDsVerificationFail | Authentication |
| 56 | DisabledMOPForFTD | Business rule |
| 57 | BalanceNotAvailable | External |
| 58 | AggressiveTrading | Risk scoring |
| 59 | InsufficientFunds | External |
| 60 | eToroCardVelocity | Velocity |
| 61 | eToroCardAggregatedAmount | Velocity |
| 62 | CreditCardRestriction | Card rules |
| 63 | BinIsPrepaid | Card rules |
| 64 | UserHasAnotherActivePaypalAccount | Account blocks |
| 65 | PaypalAccountAssignedToAnotherUser | Account blocks |
| 66 | UnclearedDeposits | Business rule |
| 67 | SiftWorkFlow | Fraud (Sift Score) |
| 68 | CreditCardExcessiveDeposits | Velocity |
| 69 | BusinessRuleRisk | Business rule |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BRMC | NONCLUSTERED | RiskManagementCheckID ASC | FILLFACTOR=90. NONCLUSTERED -> heap. ON [MAIN]. |
| BRMC_PAYMENT | NONCLUSTERED | PaymentID ASC | FILLFACTOR=90. Primary lookup path: find all risk checks for a given PaymentID. |
| BRMC_RISKMANAGEMENTSTATUS | NONCLUSTERED | RiskManagementStatusID ASC | FILLFACTOR=90. Supports reporting on risk rule frequency. |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.RiskManagementCheckAdd` | Only writer: simple INSERT (PaymentID, RiskManagementStatusID). Called from application code only - no SP callers in Billing schema. |
| `Billing.CustomerRemove` | Deletes RiskManagementCheck rows for a customer (GDPR/data removal) via PaymentID join. |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Payment | Many-to-one | RiskManagementCheck.PaymentID = Payment.PaymentID | Explicit FK. The blocked payment. Multiple risk check rows may exist per payment. |
| Dictionary.RiskManagementStatus | Many-to-one | RiskManagementCheck.RiskManagementStatusID = RiskManagementStatus.RiskManagementStatusID | Explicit FK. 69 risk codes. Defines why the payment was blocked. |

---

*Quality: 9.1/10 | 3 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,5,8,9,11*
