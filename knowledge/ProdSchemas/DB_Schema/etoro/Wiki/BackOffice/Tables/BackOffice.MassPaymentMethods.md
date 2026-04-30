# BackOffice.MassPaymentMethods

> 144-row configuration table defining which payment method + currency combinations are eligible for mass/bulk cashout processing, along with the payment depot (processor/acquirer) and default cashout status for each combination. Actively maintained since 2017; credit card is the dominant payment type (89 rows, 61.8%).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [PRIMARY] filegroup, DATA_COMPRESSION=PAGE) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.MassPaymentMethods defines the configuration for mass (bulk) withdrawal processing. When eToro's CashOut Tool batches customer withdrawal requests for automated execution, this table determines which (FundingType, Currency, Depot) combinations are eligible and what cashout status to apply when creating the payments.

A "Depot" is a payment processor or acquirer routing destination (e.g., WireCard, as confirmed by Confluence test documentation). Different acquirers process different payment types in different currencies. This table maps each valid combination to a specific depot.

**Key characteristics**:
- 144 rows, 141 active (IsActive=1), 3 inactive (IsActive=0).
- Credit card (FundingTypeID=1) dominates with 89 rows - the most combinations of currency/depot for card processing.
- CashoutStatusID=2 (InProcess) is the default for 143 rows, meaning mass cashouts queue as "in process" by default.
- CurrencyID spans ~35 currencies - designed for global multi-currency withdrawal operations.
- DepotID is populated for 141/144 rows; 3 rows have NULL DepotID.
- InsertDate range: 2017-03-09 to 2026-02-23 - actively maintained, with recent additions.
- DATA_COMPRESSION=PAGE on the clustered index - indicates the table was expected to grow significantly.
- Not referenced by any stored procedure in the BackOffice SSDT repo; consumed by the application layer (CashOut Tool service or BackOffice UI).

---

## 2. Business Logic

### 2.1 Mass Cashout Method Eligibility

**What**: Defines which payment method + currency combinations are eligible for mass cashout processing via a specific depot.

**Columns Involved**: `FundingTypeID`, `CurrencyID`, `DepotID`, `CashoutStatusID`, `IsActive`

**Rules**:
- The application queries this table to find active configurations (IsActive=1) matching a given funding type and currency.
- The resolved DepotID determines which payment processor/acquirer to route the cashout through.
- CashoutStatusID=2 (InProcess) is applied to the cashout record when created via this method (143 of 144 rows).
- IsActive=0 rows (3) represent disabled configurations - retained for history but not used in processing.
- InsertDate is auto-populated by DEFAULT GETUTCDATE() - no manual date entry required.

---

## 3. Data Overview

144 rows as of 2026-03-17 (141 active, 3 inactive):

**By funding type**:

| FundingTypeID | Name | Rows | Pct |
|--------------|------|------|-----|
| 1 | CreditCard | 89 | 61.8% |
| 3 | PayPal | 13 | 9.0% |
| 28 | OnlineBanking | 12 | 8.3% |
| 8 | MoneyBookers (Skrill) | 7 | 4.9% |
| 35 | Trustly | 7 | 4.9% |
| 6 | Neteller | 4 | 2.8% |
| 33 | eToroMoney | 4 | 2.8% |
| 21 | Yandex | 2 | 1.4% |
| 34 | iDEAL | 1 | 0.7% |
| 29 | ACH | 1 | 0.7% |
| 32 | PWMB | 1 | 0.7% |
| 36 | Przelewy24 | 1 | 0.7% |
| 39 | Payoneer | 1 | 0.7% |
| 42 | EtoroOptions | 1 | 0.7% |

**By cashout status**:

| CashoutStatusID | Name | Rows |
|----------------|------|------|
| 2 | InProcess | 143 |
| 8 | RejectedByProvider | 1 |

**Top currencies by row count**: USD (15), EUR (14), GBP (14), AUD (12), and ~30 more.

**DepotID**: 141 rows have DepotID, 3 rows have NULL. Date range: 2017-03-09 to 2026-02-23.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-incrementing surrogate key. NOT FOR REPLICATION. CLUSTERED PK. 144 rows currently. |
| 2 | FundingTypeID | int | NO | - | VERIFIED | Payment method type. Implicit FK to Dictionary.FundingType. Values in use: 1=CreditCard (61.8%), 3=PayPal, 6=Neteller, 8=MoneyBookers, 21=Yandex, 28=OnlineBanking, 29=ACH, 32=PWMB, 33=eToroMoney, 34=iDEAL, 35=Trustly, 36=Przelewy24, 39=Payoneer, 42=EtoroOptions. |
| 3 | DepotID | int | YES | NULL | CODE-BACKED | Payment processor/acquirer routing identifier. NULL for 3 rows. Identifies which acquirer (e.g., WireCard) processes the cashout. Not a FK constraint - references an internal routing config or external system. Populated for 141/144 rows. |
| 4 | CurrencyID | int | NO | - | VERIFIED | Withdrawal currency. Implicit FK to Dictionary.Currency. ~35 distinct currency IDs. Top values: 1=USD (15), 2=EUR (14), 3=GBP (14), 5=AUD (12). High-value currencies (444, 452, 453, etc.) suggest crypto or alternative currencies are also included. |
| 5 | CashoutStatusID | int | NO | - | VERIFIED | Default cashout status applied when creating cashouts via this method. Implicit FK to Dictionary.CashoutStatus. Values: 2=InProcess (143 rows, default), 8=RejectedByProvider (1 row - a configuration for a pre-rejected/blocked route). |
| 6 | IsActive | bit | NO | - | VERIFIED | Whether this method configuration is currently active. 1=active (141 rows), 0=disabled (3 rows). Application should filter to IsActive=1 for live processing. |
| 7 | InsertDate | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when this configuration was added. Auto-set by DEFAULT. Range: 2017-03-09 to 2026-02-23. Used for audit trail of configuration changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit FK | Payment method type |
| CurrencyID | Dictionary.Currency | Implicit FK | Withdrawal currency |
| CashoutStatusID | Dictionary.CashoutStatus | Implicit FK | Default cashout processing status |
| DepotID | (payment routing config) | Implicit | Payment processor/acquirer depot |

### 5.2 Referenced By (other objects point to this)

No stored procedures in the BackOffice SSDT repo reference this table. Consumed by the application layer (CashOut Tool service or BackOffice web UI) for mass withdrawal routing decisions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.MassPaymentMethods (config table)
- Implicit FK targets:
  |- Dictionary.FundingType (FundingTypeID)
  |- Dictionary.Currency (CurrencyID)
  |- Dictionary.CashoutStatus (CashoutStatusID)
- No SSDT procedure consumers (application layer only)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | Implicit FK on FundingTypeID |
| Dictionary.Currency | Table | Implicit FK on CurrencyID |
| Dictionary.CashoutStatus | Table | Implicit FK on CashoutStatusID |

### 6.2 Objects That Depend On This

None found in SSDT repo. Consumed by application layer (CashOut Tool service).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_BackOffice_MassPaymentMethods | CLUSTERED PK | ID ASC | Active (FILLFACTOR=95, DATA_COMPRESSION=PAGE, ON [PRIMARY]) |

PAGE compression on a 144-row table indicates expectation of significant growth. FILLFACTOR=95 (dense pages) aligns with sequential IDENTITY inserts.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOffice_MassPaymentMethods | PK | ID uniqueness |
| DF_MassPaymentMethodsInsertDate | DEFAULT | InsertDate = GETUTCDATE() (auto-timestamp on insert) |

No FK constraints on any column. No unique constraint on (FundingTypeID, CurrencyID, DepotID) - multiple configurations per combination are technically allowed.

---

## 8. Sample Queries

### 8.1 Get active mass payment configurations for a given funding type
```sql
SELECT mpm.ID, mpm.FundingTypeID, mpm.DepotID,
       dc.Abbreviation AS Currency,
       cs.Name AS CashoutStatus
FROM BackOffice.MassPaymentMethods mpm WITH (NOLOCK)
JOIN Dictionary.Currency dc WITH (NOLOCK) ON dc.CurrencyID = mpm.CurrencyID
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = mpm.CashoutStatusID
WHERE mpm.FundingTypeID = @FundingTypeID
  AND mpm.IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

Confluence: "CashOutTool Service" describes the mass cashout automation goal: "minimize manual preparation of withdraw payments by implementing system logic that translates withdrawal policy and user data to an automated process." "Test Plan - New CreditCard depot (WireCard Solution)" confirms DepotID refers to payment processor/acquirer routing (e.g., WireCard).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.MassPaymentMethods | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.MassPaymentMethods.sql*
