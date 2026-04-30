# Dictionary.CashoutRejectReason

> Lookup table defining the 28 reasons for rejecting a cashout (withdrawal) request — from missing documents and wrong payment details to risk flags, bonus abuse, and unclaimed payments.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RejectReasonID (TINYINT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 28 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CashoutRejectReason classifies why a withdrawal request was rejected or flagged. When a cashout is denied — whether by automated checks or manual operator review — a RejectReasonID is recorded in Billing.WithdrawRejects (explicit FK). This provides compliance teams and customer support with structured data about rejection patterns and enables customers to understand what action is needed to resolve the rejection.

The table contains two generations of reasons: the original operational set (IDs 0-10) focuses on internal processing reasons (wrong details, missing docs, risk, management approval), while the newer set (IDs 11-27) includes customer-facing ticket categories (alternative payment method, CO issues, withdrawal fees, NWA inquiries). The **IsInDisplay** flag distinguishes which reasons should appear in customer-facing interfaces — only 7 of 28 have IsInDisplay=1, while most are NULL (hidden from customers).

The table is primarily consumed by Billing.WithdrawReject (which records the rejection) and the rejection reporting procedures Billing.GetRejectedWithdrawsByRequestDate and Billing.GetRejectedWithdrawsByRejectDate (which JOIN to display the rejection reason name).

---

## 2. Business Logic

### 2.1 Rejection Reason Categories

**What**: The major categories of withdrawal rejection reasons.

**Columns/Parameters Involved**: `RejectReasonID`, `RejectReasonName`, `IsInDisplay`

**Rules**:
- **Documentation (1, 2, 19, 20)**: Missing documents, missing payment information, missing/incorrect details, missing docs. Customer must provide additional information.
- **Payment Method (0, 3, 11)**: Wrong details on method of payment, missing alternative MOP, alternative payment method suggestion. Routing issues.
- **Compliance/Risk (5, 6, 7, 8, 9)**: Denied, bonus abuse, risk, off market abuse, management approval required. Escalation to compliance team.
- **Unclaimed/Failed (4, 24)**: Payment unclaimed by recipient, unclaimed/denied payment. PSP-level failure.
- **Customer Service (12, 13, 14, 15, 16, 17, 18, 21, 22, 23, 25, 26)**: Cancel/change request, cannot withdraw, cashier limitations, CO issues, eToro fees, funds not received, less funds, NWA inquiries, other, status inquiry, withdrawal fees, withdrawal other.
- **Special (10, 27)**: Other (catch-all), deceased client.
- **Customer-Visible** (IsInDisplay=1): IDs 11, 15, 19, 23, 24, 26, 27 — shown in customer-facing UI

**Diagram**:
```
Rejection Flow:
  Withdrawal Request ──► Review (auto or manual)
       │
       ├── APPROVED ──► Processing
       │
       └── REJECTED ──► RejectReasonID recorded
                  │
                  ├── IsInDisplay=1 ──► Customer sees reason
                  └── IsInDisplay=NULL ──► Internal-only reason
```

---

## 3. Data Overview

| RejectReasonID | RejectReasonName | IsInDisplay | Meaning |
|---|---|---|---|
| 0 | Wrong Details MOP | NULL | Payment method details are incorrect. Customer must update their method of payment information. |
| 1 | Missing Documents | NULL | Required verification documents not provided. Customer must submit ID/proof of address. |
| 2 | Missing Payment Information | NULL | Incomplete payment details — bank account, card number, or routing information missing. |
| 3 | Missing Alternative MOP | NULL | Customer needs to provide an alternative payment method for the withdrawal. |
| 4 | Unclaimed | NULL | Payment was sent but not claimed by the recipient within the allowed timeframe. |
| 5 | Denied | NULL | Withdrawal explicitly denied — typically compliance or management decision. |
| 6 | Bonus Abuse | NULL | Withdrawal rejected due to detected abuse of bonus/promotional terms. |
| 7 | Risk | NULL | Risk team flagged the withdrawal. Under investigation or blocked. |
| 8 | Off Market Abuse | NULL | Withdrawal blocked due to off-market trading manipulation. |
| 9 | Management Approval | NULL | Withdrawal requires explicit management approval before processing. |
| 10 | Other | NULL | Catch-all for rejections not fitting other categories. |
| 11 | Alternative Payment method | YES | Customer advised to use a different payment method (customer-visible). |
| 15 | CO Issues | YES | Cashout operational issues requiring customer action (customer-visible). |
| 19 | Missing/incorrect payment information/Extra docs | YES | Combined reason for payment info or document issues (customer-visible). |
| 23 | Status of withdrawal | YES | Customer inquiry about withdrawal status (customer-visible). |
| 24 | Unclaimed /denied payment | YES | Payment unclaimed or denied by receiving institution (customer-visible). |
| 26 | Withdrawal - Other | YES | General withdrawal issue (customer-visible). |
| 27 | Deceased client | YES | Withdrawal handling for deceased customer — estate procedures required (customer-visible). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RejectReasonID | tinyint | NO | - | VERIFIED | Primary key identifying the rejection reason. Range 0-27. Referenced by Billing.WithdrawRejects (explicit FK). Written by Billing.WithdrawReject procedure. TINYINT type limits to 256 possible values. Note: column named RejectReasonID (not CashoutRejectReasonID) — differs from naming pattern of parent table name. |
| 2 | RejectReasonName | varchar(200) | YES | - | VERIFIED | Human-readable rejection description. Nullable. Longer varchar(200) allows detailed descriptions (vs typical 50). Joined in rejection reports as display label. Some values are customer-facing when IsInDisplay=1. |
| 3 | IsInDisplay | bit | YES | - | VERIFIED | Whether this reason is displayed in customer-facing interfaces. 1=visible to customers, NULL=internal-only. Only 7 of 28 reasons are customer-visible (IDs 11, 15, 19, 23, 24, 26, 27). Controls which reasons appear in self-service withdrawal status screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawRejects | RejectReasonID | Explicit FK | Records each withdrawal rejection with its reason |
| Billing.WithdrawReject | @RejectReasonID | Parameter INSERT | Creates rejection record |
| Billing.GetRejectedWithdrawsByRequestDate | RejectReasonID | JOIN | Rejection report by request date |
| Billing.GetRejectedWithdrawsByRejectDate | RejectReasonID | JOIN | Rejection report by reject date |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CashoutRejectReason (table)
  └── referenced by Billing.WithdrawRejects (FK)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawRejects | Table | FK on RejectReasonID |
| Billing.WithdrawReject | Stored Procedure | Creates rejection with reason |
| Billing.GetRejectedWithdrawsByRequestDate | Stored Procedure | JOINs for reason name |
| Billing.GetRejectedWithdrawsByRejectDate | Stored Procedure | JOINs for reason name |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.CashoutRejectReason | CLUSTERED PK | RejectReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary.CashoutRejectReason | PRIMARY KEY | Unique rejection reason identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all rejection reasons
```sql
SELECT  RejectReasonID,
        RejectReasonName,
        IsInDisplay
FROM    Dictionary.CashoutRejectReason WITH (NOLOCK)
ORDER BY RejectReasonID;
```

### 8.2 List customer-visible rejection reasons
```sql
SELECT  RejectReasonID,
        RejectReasonName
FROM    Dictionary.CashoutRejectReason WITH (NOLOCK)
WHERE   IsInDisplay = 1
ORDER BY RejectReasonID;
```

### 8.3 Count rejections by reason
```sql
SELECT  dcrr.RejectReasonName   AS Reason,
        COUNT(*)                AS RejectionCount
FROM    Billing.WithdrawRejects wr WITH (NOLOCK)
JOIN    Dictionary.CashoutRejectReason dcrr WITH (NOLOCK)
        ON wr.RejectReasonID = dcrr.RejectReasonID
GROUP BY dcrr.RejectReasonName
ORDER BY RejectionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data (28 reasons, 7 customer-visible) and codebase analysis of Billing withdrawal rejection procedures.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CashoutRejectReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CashoutRejectReason.sql*
