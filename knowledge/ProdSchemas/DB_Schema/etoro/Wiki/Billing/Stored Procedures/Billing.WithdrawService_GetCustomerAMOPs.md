# Billing.WithdrawService_GetCustomerAMOPs

> Returns the list of Allowed Methods Of Payment (AMOPs) eligible for a customer's next withdrawal - payment instruments that have been previously used for a successful transaction and meet recency and data-quality requirements.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer whose eligible payment methods are returned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawService_GetCustomerAMOPs` answers the question: "Which payment methods can this customer use for their next withdrawal?" AMOP stands for Allowed Method Of Payment. This procedure drives the withdrawal method selector in the customer-facing withdrawal flow - only instruments returned here are presented to the customer as valid withdrawal options.

The procedure exists because "customer has this payment method registered" is not sufficient for a withdrawal. Regulatory requirements, provider rules, and eToro policy add additional constraints: the instrument must have been previously used for a successful transaction (deposit or withdrawal), must have been used recently enough (6 months for credit cards, 12 months for most others), must contain valid non-empty data (non-empty bank account details), must not be an expired credit card, and must not be a third-party-managed funding instrument.

Data flows into the withdrawal service which calls this procedure when a customer initiates a withdrawal. The result set drives the UI dropdown and routing logic. The procedure was created in November 2020 (MIMOPS-2444) and has undergone multiple revisions adding and removing Trustly (FundingTypeID=35) support.

---

## 2. Business Logic

### 2.1 Eligible Funding Type Allowlist

**What**: Only specific payment method types are permitted for withdrawals, defined by a hardcoded FundingTypeID allowlist.

**Columns/Parameters Involved**: `Billing.Funding.FundingTypeID`

**Rules**:
- Allowed types: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 8=MoneyBookers, 22=UnionPay, 28=OnlineBanking, 29=ACH, 32=PWMB, 36=Przelewy24.
- Types NOT allowed (excluded from withdrawals regardless of prior usage): 4=Moneybookers2, 5=LocalBank, 7=WireTransfer2, 9-21=various others, 33=eToroMoney, 34=iDEAL (removed Jan 2021 by Yitzchak), etc.
- Note: FundingTypeID=36 (Przelewy24) is in the main allowlist but NOT included in any recency window rule (Section 2.3), which means it effectively returns no records in practice - this appears to be an incomplete addition.
- FundingID=1 is always excluded (special system funding record).

### 2.2 Prior Transaction Requirement (CIDFundingList CTE)

**What**: A payment method must have been used for a prior successful transaction before it can be used for a withdrawal.

**Columns/Parameters Involved**: `Billing.WithdrawToFunding.CashoutStatusID`, `Billing.Deposit.PaymentStatusID`

**Rules**:
- "Used" means: at least one successful withdrawal via this FundingID (WTF.CashoutStatusID=3 = Processed) OR at least one successful deposit (Deposit.PaymentStatusID=2 = Completed).
- A newly registered payment method that has never been used for any transaction is NOT eligible.
- `CIDFundingList.CID IS NOT NULL` enforces this - the LEFT JOIN result is NULL if no transaction history exists.

**Diagram**:
```
CIDFundingList CTE:
  (WTF WHERE CashoutStatusID=3)    -- successful withdrawal via this FundingID
  UNION
  (Deposit WHERE PaymentStatusID=2) -- successful deposit via this FundingID

Joined to CustomerToFunding + Funding
WHERE CIDFundingList.CID IS NOT NULL  -- must appear in transaction history
```

### 2.3 Recency Windows by Payment Type

**What**: Different payment types have different recency windows; instruments last used too long ago are excluded.

**Columns/Parameters Involved**: `CIDFundingList.DepositDate`, `CIDFundingList.WithdrawDate`, `Billing.Funding.FundingTypeID`

**Rules**:
- **Credit Card (FundingTypeID=1)**: Must have been used within the last **6 months** (deposit OR withdrawal).
- **PayPal (3), WireTransfer (2), Neteller (6), MoneyBookers (8), ACH (29), PWMB (32)**: Must have a deposit within the last **12 months**.
- **UnionPay (22) and OnlineBanking (28)**: Must have been used for at least one withdrawal (no deposit recency requirement - these are withdrawal-only instruments; `DepositDate IS NULL AND WithdrawDate IS NOT NULL`).
- **Przelewy24 (36)**: No matching recency rule - effectively always excluded (incomplete implementation).

### 2.4 Data Quality Exclusions

**What**: Payment instruments with missing or invalid data are excluded even if otherwise eligible.

**Columns/Parameters Involved**: `Billing.Funding.FundingData` (XML)

**Rules**:
- FundingTypeID IN (22, 28) [UnionPay/OnlineBanking]: excluded if `BankAccountAsString` is empty or whitespace.
- FundingTypeID=35 [Trustly]: excluded if both `IBANCodeAsString` AND `AccountIDAsString` are empty.
- FundingTypeID=3 [PayPal]: excluded if the PayPal email matches the pattern `{username}@etoro.com` (internal eToro accounts, not customer PayPal accounts).
- FundingTypeID=1 [Credit Card]: excluded if the card is expired. Expiry is parsed from `ExpirationDateAsString` (format MMYY as 4 chars); card is excluded if `DATEADD(Month, 1, expiry_date) < GETUTCDATE()`.

### 2.5 Third-Party Funding Exclusion

**What**: Funding instruments managed by third parties (identified in BackOffice.CustomerToThirdPartyFundings) are excluded.

**Columns/Parameters Involved**: `BackOffice.CustomerToThirdPartyFundings.FundingID`

**Rules**:
- LEFT JOIN to `BackOffice.CustomerToThirdPartyFundings` on CID + FundingID.
- `BCTTPF.CID IS NULL` means no third-party record exists -> include.
- Any funding that appears in CustomerToThirdPartyFundings is excluded (managed externally).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Used to filter CustomerToFunding, Customer.Customer, and the CIDFundingList CTE. Returns all eligible AMOPs for this customer. |

**Result Set Columns**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | FundingID | INT | The eligible payment instrument ID from `Billing.Funding`. |
| 2 | FundingTypeID | INT | Payment method type: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 8=MoneyBookers, 22=UnionPay, 28=OnlineBanking, 29=ACH, 32=PWMB, 36=Przelewy24. |
| 3 | FundingData | NVARCHAR(MAX) | The full XML payment method data from `Billing.Funding.FundingData`, cast to NVARCHAR. Subject to DDM masking for non-privileged callers. |
| 4 | PaymentDate | DATETIME | `Billing.CustomerToFunding.LastUsedDate` - the last date this instrument was used by the customer. Used for sorting (newest first within each type). |

**Result ordering**: ORDER BY FundingTypeID ASC, PaymentDate DESC.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | JOIN | Validates CID and reads UserName for internal PayPal exclusion check. |
| @CID | Billing.CustomerToFunding | JOIN (anchor) | Gets all payment instruments registered for this customer. |
| FundingID | Billing.Funding | JOIN | Gets instrument type, data, and refund-excluded flag. |
| @CID | Billing.WithdrawToFunding | CTE (prior usage) | Successful withdrawals (CashoutStatusID=3) contribute to prior-usage check. |
| @CID | Billing.Deposit | CTE (prior usage) | Successful deposits (PaymentStatusID=2) contribute to prior-usage check. |
| FundingID | BackOffice.CustomerToThirdPartyFundings | LEFT JOIN (exclusion) | Third-party managed instruments are excluded. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawService (application) | - | Caller | Withdrawal service calls this to populate the list of eligible payment methods for a customer's withdrawal request. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetCustomerAMOPs (procedure)
├── Billing.WithdrawToFunding (table) - CTE: prior successful withdrawals
├── Billing.Withdraw (table) - CTE: join for CID
├── Billing.Deposit (table) - CTE: prior successful deposits
├── Billing.CustomerToFunding (table) - registered instruments for CID
├── Billing.Funding (table) - instrument data and type
├── Customer.Customer (table) - CID validation + username for PayPal check
└── BackOffice.CustomerToThirdPartyFundings (table) - third-party exclusion
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | CTE: successful withdrawals (CashoutStatusID=3) = prior usage evidence |
| Billing.Withdraw | Table | CTE: JOIN to get CID from WithdrawToFunding |
| Billing.Deposit | Table | CTE: successful deposits (PaymentStatusID=2) = prior usage evidence |
| Billing.CustomerToFunding | Table | JOIN: registered payment instruments for @CID, LastUsedDate, IsRefundExcluded |
| Billing.Funding | Table | JOIN: FundingTypeID, FundingData, IsRefundExcluded |
| Customer.Customer | Table | JOIN: CID validation; UserName for PayPal email exclusion |
| BackOffice.CustomerToThirdPartyFundings | Table | LEFT JOIN: third-party funding exclusion |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No DB-layer dependents found | - | Called from withdrawal service application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingType allowlist | Filter | Only FundingTypeIDs 1,2,3,6,8,22,28,29,32,36 are eligible |
| IsRefundExcluded check | Filter | Both Funding.IsRefundExcluded=0 AND CustomerToFunding.IsRefundExcluded=0 required |
| Prior usage requirement | Filter | Must appear in CIDFundingList (at least one successful deposit or withdrawal) |
| Recency windows | Filter | 6 months for CC, 12 months for most, withdrawal-only for UnionPay/OnlineBanking |
| Data quality checks | Filter | Non-empty bank account, valid IBAN/AccountID, non-expired CC, non-internal PayPal |
| Third-party exclusion | Filter | BackOffice.CustomerToThirdPartyFundings records are excluded |

---

## 8. Sample Queries

### 8.1 Get all eligible withdrawal methods for a customer

```sql
EXEC Billing.WithdrawService_GetCustomerAMOPs @CID = 12345;
```

### 8.2 Check what payment methods a customer has and why some may be excluded

```sql
SELECT
    ctf.FundingID,
    f.FundingTypeID,
    ft.Name AS FundingTypeName,
    ctf.IsRefundExcluded AS CTF_RefundExcluded,
    f.IsRefundExcluded AS F_RefundExcluded,
    ctf.LastUsedDate,
    f.IsBlocked,
    CASE WHEN f.FundingTypeID NOT IN (1,2,3,6,8,22,28,29,32,36) THEN 'Type not in allowlist'
         WHEN ctf.IsRefundExcluded = 1 OR f.IsRefundExcluded = 1 THEN 'RefundExcluded'
         WHEN f.FundingID = 1 THEN 'System FundingID excluded'
         ELSE 'In allowlist - check prior usage and recency'
    END AS ExclusionReason
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON f.FundingID = ctf.FundingID
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = f.FundingTypeID
WHERE ctf.CID = 12345
ORDER BY f.FundingTypeID, ctf.LastUsedDate DESC;
```

### 8.3 Find customers with the most eligible AMOPs

```sql
SELECT TOP 20
    ctf.CID,
    COUNT(DISTINCT f.FundingTypeID) AS DistinctFundingTypes,
    COUNT(*) AS TotalEligibleAMOPs
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON ctf.FundingID = f.FundingID
WHERE f.FundingTypeID IN (1,2,3,6,8,22,28,29,32,36)
  AND ctf.IsRefundExcluded = 0
  AND f.IsRefundExcluded = 0
GROUP BY ctf.CID
ORDER BY TotalEligibleAMOPs DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 10/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Live data: FundingType lookup queried | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetCustomerAMOPs | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetCustomerAMOPs.sql*
