# Dictionary.PlayerStatusReasons

> Lookup table defining the 44 reasons why a customer's account status may be changed — from compliance actions (AML, KYC, chargebacks) to user-initiated closures and administrative decisions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerStatusReasonID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 44 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.PlayerStatusReasons provides the top-level reason codes explaining *why* a customer's account status (Dictionary.PlayerStatus) was changed. When an account is blocked, suspended, restricted, or closed, the system records both the new status and the reason for the change. This table provides the first level of categorization — the broad reason category.

These reasons span the full range of account status change triggers: compliance/AML investigations (IDs 6, 10, 11), KYC failures (1, 2, 39), risk flags (4, 7, 14), fraud/chargebacks (5, 23, 24, 30-32), user-initiated actions (3, 21, 22), and administrative decisions (37, 40-43). The reason is stored on Customer.CustomerStatic and flows through to Customer views, BackOffice reporting, and history tracking.

This table works as a hierarchy with Dictionary.PlayerStatusSubReasons — the Reason is the broad category (e.g., "Chargeback"), and the SubReason provides granular detail (e.g., "ACH CHBK", "Credit Card CHBK"). The mapping between valid Reason→SubReason combinations is stored in BackOffice.PlayerStatusReasonToSubReason. Similarly, BackOffice.PlayerStatusToReason maps which Reasons are valid for which PlayerStatus values.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: The major categories of account status change reasons.

**Columns/Parameters Involved**: `PlayerStatusReasonID`, `Name`

**Rules**:
- **None (0)**: Default/no reason — used when status hasn't been explicitly changed with a reason
- **Compliance/AML** (6, 10, 11, 18): Anti-money laundering investigations, account closures, reviews, World Check matches
- **KYC/Verification** (1, 2, 27, 39): Failed document verification, expired documents, pending documents
- **Risk/Fraud** (4, 7, 14, 25, 34, 35): Risk flags, high-risk country, risk checks, abuse, hacked accounts
- **Chargebacks** (5, 23, 24, 30-32): Credit card, ACH, PWMB, Checkout chargebacks and retrievals
- **User-Initiated** (3, 20, 21, 22): Self-service closure, right to be forgotten (GDPR), by-request
- **Payment Issues** (13, 16, 17, 38): Overpayment, PayPal investigation, NOC/NOF/RFI, deposits
- **Administrative** (8, 9, 12, 19, 37, 40-43): Underage, deceased, market abuse, other, CS management, account closure, tax, corporate, gap
- **Account Type** (26, 28, 29, 36): Affiliate accounts, employee accounts, PI (Popular Investor) accounts, partners
- **Regulatory** (33, 41): eToro Money restriction, tax-related

### 2.2 Status-to-Reason Mapping

**What**: How reasons are constrained to specific account statuses.

**Columns/Parameters Involved**: `PlayerStatusReasonID`

**Rules**:
- Not every reason is valid for every status — BackOffice.PlayerStatusToReason defines the valid combinations
- BackOffice.GetPlayerStatusReasonMapping and BackOffice.LoadPlayerStatusReasonMapping load these mappings for the BackOffice UI
- When changing a customer's status via BackOffice.UpdateRiskUserInfo, both @playerStatusReasonId and @PlayerStatusSubReasonID must be provided

---

## 3. Data Overview

| PlayerStatusReasonID | Name | Category | Meaning |
|---|---|---|---|
| 0 | None | Default | No reason specified. Default state when account hasn't had an explicit status change. |
| 1 | Failed Verification | KYC | Customer failed identity document verification process. |
| 2 | Expired Document | KYC | Customer's identity document has expired and needs renewal. |
| 3 | CloseAccountByUser | User-Initiated | Customer requested their own account closure. |
| 4 | Risk | Risk | General risk flag — account flagged by risk assessment. |
| 5 | Chargeback | Financial | Customer's deposit was reversed via chargeback from their bank/card issuer. |
| 6 | AML-Account Closed | Compliance | Account closed due to Anti-Money Laundering investigation. |
| 7 | HRC | Risk | High Risk Country — customer is from a jurisdiction flagged as high-risk. |
| 8 | Underage | Administrative | Customer is under the minimum legal trading age. |
| 9 | Deceased | Administrative | Customer is deceased. Account must be handled per estate procedures. |
| 10 | AML | Compliance | Active AML investigation on the account. |
| 11 | AML review | Compliance | Account under AML review — less severe than full investigation. |
| 12 | Off Market Abuse | Administrative | Customer engaged in off-market manipulation or abuse. |
| 13 | Overpayment | Payment | Excess funds received — deposit exceeds expected amount. |
| 14 | Risk Check | Risk | Account flagged during periodic risk review. |
| 15 | 3rd Party | Risk | Third-party involvement detected (non-account-holder activity). |
| 16 | PayPal Investigation | Payment | PayPal dispute or investigation on the account. |
| 17 | NOC/NOF/RFI | Payment | Notice of Change, Notice of Failure, or Request for Information from bank. |
| 18 | WCH match | Compliance | World Check (sanctions/PEP screening) match found. |
| 19 | Other | Administrative | Catch-all for reasons not fitting other categories. |
| 20 | Right to be forgotten | User-Initiated | GDPR right-to-be-forgotten request. |
| 21 | Self-Service | User-Initiated | Customer used self-service account closure flow. |
| 22 | By request | User-Initiated | Account change requested by the customer through support. |
| 23 | ACH Chargeback | Financial | ACH bank transfer chargeback. |
| 24 | PWMB Chargeback | Financial | eToro Money (PWMB) transaction chargeback. |
| 25 | Abuse | Risk | General account abuse detected. |
| 26 | Affiliate Account | Account Type | Account belongs to an affiliate partner. |
| 27 | Pending Docs | KYC | Customer has outstanding document submissions required. |
| 28 | Employee Account | Account Type | Internal employee account — special handling required. |
| 29 | PI Account | Account Type | Popular Investor account — subject to PI program rules. |
| 30 | CheckoutChargeback | Financial | Chargeback via Checkout.com payment provider. |
| 31 | CheckoutRetrievel | Financial | Retrieval request via Checkout.com (pre-chargeback inquiry). |
| 32 | CheckoutCaptureDecline | Financial | Capture declined by Checkout.com. |
| 33 | eToro Money Restriction | Regulatory | Restriction from eToro Money (PWMB) side. |
| 34 | Abusive Trading | Risk | Customer engaged in abusive trading patterns. |
| 35 | Hacked Account | Risk | Account compromised by unauthorized access. |
| 36 | Partners & PIs | Account Type | Partner or Popular Investor specific restriction. |
| 37 | CS management decision | Administrative | Customer Service management made a status decision. |
| 38 | Deposits | Payment | Deposit-related issue requiring status change. |
| 39 | KYC | KYC | General KYC compliance issue. |
| 40 | Account Closed | Administrative | General account closure (not user-initiated). |
| 41 | Tax | Regulatory | Tax-related restriction or issue (FATCA/CRS). |
| 42 | Corporate | Administrative | Corporate account specific issue. |
| 43 | Gap | Administrative | Gap/discrepancy in account records. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusReasonID | int | NO | - | VERIFIED | Primary key identifying the status change reason. Range 0-43. Referenced by BackOffice.PlayerStatusToReason (FK), BackOffice.PlayerStatusReasonToSubReason (FK), and Customer.CustomerStatic (implicit). Used as parameter in BackOffice.UpdateRiskUserInfo and Billing.UpdateCustomerStatusReason. 0=None (default). |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable reason label. Nullable (unlike most Dictionary tables). Used in BackOffice reporting JOINs, customer history views, and monitoring procedures. Displayed in BackOffice UI when viewing customer status change history. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.PlayerStatusToReason | PlayerStatusReasonID | Explicit FK | Maps which reasons are valid per status |
| BackOffice.PlayerStatusReasonToSubReason | PlayerStatusReasonID | Explicit FK | Maps reasons to their valid sub-reasons |
| Customer.CustomerStatic | PlayerStatusReasonID | Implicit | Stores customer's current status reason |
| History.Customer | PlayerStatusReasonID | Column | Historical snapshot of reason per customer change |
| Customer.Customer | PlayerStatusReasonID | View SELECT | Customer view exposes reason |
| Customer.CustomerSafty | PlayerStatusReasonID | View SELECT | Schema-bound customer view exposes reason |
| Internal.Monitor_CustomerPlayerStatus | - | JOIN | Monitoring procedure resolves reason names |
| BackOffice.GetBlockedCustomers | @PlayerStatusReasonIDs | Parameter/WHERE/JOIN | Filters blocked customers by reason |
| BackOffice.GetPendingClosureAccountsByLastChangeDate | @PlayerStatusReasonIDs | Parameter/WHERE | Filters pending closure by reasons |
| BackOffice.GetClosedAccountsByLastChangeDate | @PlayerStatusReasonIDs | Parameter/WHERE | Filters closed accounts by reasons |
| BackOffice.GetHistoryCustomer | PlayerStatusReasonID | JOIN | History display resolves reason name |
| BackOffice.GetPlayerStatusReasonMapping | - | SELECT/JOIN | Loads reason mapping for BackOffice UI |
| BackOffice.LoadPlayerStatusReasonMapping | - | SELECT/JOIN | Caches reason mappings |
| BackOffice.UpdateRiskUserInfo | @playerStatusReasonId | Parameter UPDATE | Sets customer status reason |
| Billing.UpdateCustomerStatusReason | @PlayerStatusReasonID | Parameter UPDATE | Updates customer status reason |
| Customer.GetCustomerRelationsWithPlayerStatuses | - | JOIN | Resolves reason for customer relations |
| Customer.GetRiskUserInfo | PlayerStatusReasonID | SELECT | Returns current status reason |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PlayerStatusReasons (table)
  └── referenced by BackOffice.PlayerStatusToReason (FK)
  └── referenced by BackOffice.PlayerStatusReasonToSubReason (FK)
  └── stored in Customer.CustomerStatic, History.Customer
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.PlayerStatusToReason | Table | FK — valid status-to-reason mappings |
| BackOffice.PlayerStatusReasonToSubReason | Table | FK — valid reason-to-subreason mappings |
| Customer.CustomerStatic | Table | Stores current status reason |
| History.Customer | Table | Historical status reason snapshots |
| Customer.Customer | View | Exposes PlayerStatusReasonID |
| BackOffice.GetBlockedCustomers | Stored Procedure | Filters by reason IDs |
| BackOffice.UpdateRiskUserInfo | Stored Procedure | Sets status reason |
| Billing.UpdateCustomerStatusReason | Stored Procedure | Updates status reason |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PlayerStatusReasons | CLUSTERED PK | PlayerStatusReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_PlayerStatusReasons | PRIMARY KEY | Unique reason identifier, FILLFACTOR 95, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all status reasons
```sql
SELECT  PlayerStatusReasonID,
        Name
FROM    Dictionary.PlayerStatusReasons WITH (NOLOCK)
ORDER BY PlayerStatusReasonID;
```

### 8.2 Count blocked customers by reason
```sql
SELECT  dsr.Name            AS StatusReason,
        COUNT(*)            AS CustomerCount
FROM    Customer.CustomerStatic cs WITH (NOLOCK)
JOIN    Dictionary.PlayerStatusReasons dsr WITH (NOLOCK)
        ON cs.PlayerStatusReasonID = dsr.PlayerStatusReasonID
WHERE   cs.PlayerStatusReasonID > 0
GROUP BY dsr.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Find valid reason-to-subreason mappings
```sql
SELECT  dsr.Name            AS Reason,
        dss.Name            AS SubReason
FROM    BackOffice.PlayerStatusReasonToSubReason map WITH (NOLOCK)
JOIN    Dictionary.PlayerStatusReasons dsr WITH (NOLOCK)
        ON map.PlayerStatusReasonID = dsr.PlayerStatusReasonID
JOIN    Dictionary.PlayerStatusSubReasons dss WITH (NOLOCK)
        ON map.PlayerStatusSubReasonID = dss.PlayerStatusSubReasonID
ORDER BY dsr.Name, dss.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data (44 reasons) and codebase analysis across BackOffice, Customer, and Billing schemas.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlayerStatusReasons | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PlayerStatusReasons.sql*
