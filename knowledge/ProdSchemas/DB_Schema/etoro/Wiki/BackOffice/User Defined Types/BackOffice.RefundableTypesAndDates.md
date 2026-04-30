# BackOffice.RefundableTypesAndDates

> Table-valued parameter type that pairs a funding ID with a minimum activity date, used to specify which specific funding records are eligible for refund during cashout processing.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | FundingID (CLUSTERED PK, IGNORE_DUP_KEY=OFF) |
| **Partition** | N/A |
| **Indexes** | 1 (CLUSTERED PK on FundingID ASC) |

---

## 1. Business Meaning

`BackOffice.RefundableTypesAndDates` is a Table-Valued Type (TVT) that specifies individual funding records (by `FundingID`) alongside a minimum activity date cutoff for refund eligibility. Unlike its sibling `BackOffice.PaymentTypesAndActivityPeriod` (which filters by funding TYPE), this type filters by specific funding INSTANCE - allowing the caller to define per-funding-record refundability with an activity date boundary.

This type exists to support the cashout refund calculation flow, where the determination of which specific deposit funding records are eligible for refund is controlled by the calling application. The application maintains business rules about when a funding source can be refunded (e.g., only if last used within N months) and passes those rules as funding-specific entries.

Data flows into this type from the cashout processing application. Earlier versions of `BackOffice.GetCashActivities` accepted this type directly (as seen in the procedure's in-code example comments: `declare @RefundablePaymentTypesAndDates BackOffice.RefundableTypesAndDates`). The current version uses `BackOffice.PaymentTypesAndActivityPeriod` for both payable and refundable logic, suggesting this type may have been superseded or is used by other procedures not yet identified.

---

## 2. Business Logic

### 2.1 Funding-Specific Refund Eligibility Window

**What**: Combines a specific funding instance ID with a date threshold to control which individual funding records are refundable.

**Columns/Parameters Involved**: `FundingID`, `MinActivityDate`

**Rules**:
- `FundingID` is the PK of `Billing.Funding` - it identifies a specific funding instrument (a particular credit card, bank account, or eWallet instance belonging to a customer).
- `MinActivityDate` is the cutoff: only deposit activity with a PaymentDate AFTER this date for this specific funding makes it eligible.
- CLUSTERED PK on FundingID enforces uniqueness - each funding record can appear only once in the eligibility list.
- IGNORE_DUP_KEY=OFF: duplicate FundingID inserts raise an error (caller must provide distinct IDs).
- NULL `MinActivityDate` means the funding is eligible regardless of transaction age.

**Diagram**:
```
Caller passes specific fundingID eligibility:
  [(FundingID=12345, MinActivityDate='2024-06-01'),  <- CC ending 4567, active since Jun 2024
   (FundingID=67890, MinActivityDate=NULL)]          <- Bank account, no date restriction
         |
         v
Consuming procedure checks:
  - Is this deposit's FundingID in the eligibility list?
  - Is the deposit's PaymentDate > FundingID's MinActivityDate?
  -> If both YES: funding is refundable
```

---

## 3. Data Overview

N/A for User Defined Type. This is a transient parameter container, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Primary key of a specific funding instrument in Billing.Funding (a customer's credit card, bank account, or eWallet instance). The CLUSTERED PK ensures each funding record appears at most once in the refundable list. NOT NULL. |
| 2 | MinActivityDate | datetime | YES | - | CODE-BACKED | The earliest deposit activity date threshold for this specific funding to be considered refundable. Only deposits with PaymentDate > MinActivityDate for this FundingID qualify. NULL means no date restriction - the funding is always eligible regardless of when it was last used. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID | Billing.Funding.FundingID | Implicit | Identifies the specific funding instrument (card, bank account, eWallet) for which refund eligibility is defined |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCashActivities | @RefundablePaymentTypesAndDates (historical) | Schema contract (historical) | Older SP signature used this type; current version uses BackOffice.PaymentTypesAndActivityPeriod for both payable and refundable parameters |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCashActivities | Stored Procedure | Referenced in in-code example comments as the original type for @RefundablePaymentTypesAndDates. Current SP signature uses BackOffice.PaymentTypesAndActivityPeriod instead - this type may still be in use by other procedures or versions not yet identified. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | FundingID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IGNORE_DUP_KEY = OFF | Index option | Duplicate FundingID values raise a primary key violation - caller must deduplicate. |

---

## 8. Sample Queries

### 8.1 Pass specific eligible fundings for refund processing

```sql
DECLARE @refundable BackOffice.RefundableTypesAndDates;

INSERT INTO @refundable (FundingID, MinActivityDate)
VALUES (12345, '2024-01-01'),  -- Only eligible if used after Jan 2024
       (67890, NULL);           -- Always eligible

SELECT * FROM @refundable WITH (NOLOCK);
```

### 8.2 Build from customer's funding history

```sql
DECLARE @refundable BackOffice.RefundableTypesAndDates;

INSERT INTO @refundable (FundingID, MinActivityDate)
SELECT DISTINCT bf.FundingID, DATEADD(MONTH, -12, GETDATE()) AS MinActivityDate
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
JOIN Billing.Funding bf WITH (NOLOCK) ON bf.FundingID = ctf.FundingID
WHERE ctf.CID = 123456
  AND ctf.CustomerFundingStatusID = 1; -- Active fundings only

SELECT * FROM @refundable WITH (NOLOCK);
```

### 8.3 Inspect refundable funding details

```sql
DECLARE @refundable BackOffice.RefundableTypesAndDates;

INSERT INTO @refundable VALUES (12345, '2024-06-01'), (67890, NULL);

SELECT r.FundingID,
       r.MinActivityDate,
       bf.FundingTypeID,
       bf.FundingData
FROM @refundable r WITH (NOLOCK)
JOIN Billing.Funding bf WITH (NOLOCK) ON bf.FundingID = r.FundingID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.RefundableTypesAndDates | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.RefundableTypesAndDates.sql*
