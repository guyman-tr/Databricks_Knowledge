# Customer.GDPRIsDepositor

> Classifies a customer for GDPR erasure processing by checking whether they have financial transaction history (deposits or credits), returning UserExecutionTypeID=1 (social details only can be erased) or UserExecutionTypeID=2 (personal and social data can be erased).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to classify) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GDPRIsDepositor is a GDPR erasure classification gate. Before the GDPR service executes a right-to-erasure request, it calls this procedure to determine what scope of data can legally be deleted.

The procedure exists because financial regulations (AML, MiFID II) require eToro to retain transaction records regardless of GDPR erasure requests. GDPR Article 17(3)(e) explicitly exempts data retention required for legal claims - which financial transaction records are. The result is two erasure profiles:

- **UserExecutionTypeID = 1 ("social details")**: Customer has financial history (real deposits or financial credit events). Only social-layer data (social profile, copy trading data, social publications) can be erased. The account, identity fields, and financial records are retained.
- **UserExecutionTypeID = 2 ("personal + social")**: Customer has NO financial history. Both personal PII AND social data can be fully erased. No financial retention obligation applies.

The procedure checks two sources in priority order: Billing.Deposit first (actual payment transactions), then History.Credit (financial credits/cashouts since registration). The History.Credit check is time-bounded to `Occurred >= @Registered` to exclude administrative credits made before the customer's account existed.

Despite the name "IsDepositor", the procedure checks broader financial activity - not just deposits but also cashouts, refunds, chargebacks, and specific compensation payments. Any of these triggers the financial-retention classification.

---

## 2. Business Logic

### 2.1 Three-Stage Financial Activity Classification

**What**: Sequential checks determine whether the customer has any financial transaction history.

**Columns/Parameters Involved**: `@CID`, `Billing.Deposit.PaymentStatusID`, `History.Credit.CreditTypeID`, `History.Credit.CompensationReasonID`, `Customer.Customer.Registered`

**Rules**:
- Stage 1 (Billing.Deposit check): IF any deposit exists with qualifying PaymentStatusID -> return 1 immediately
  - Qualifying statuses: 1=New, 2=Approved, 4=Technical, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 26=RefundAsChargeback
  - All deposit states qualify - even pending or refunded deposits count as financial history
- Stage 2 (History.Credit check): IF any credit event since registration exists with qualifying CreditTypeID or CompensationReasonID -> return 1
  - Qualifying CreditTypeIDs: 1=Deposit, 2=Cashout, 8=Reverse cashout, 9=Cashout Request, 11=Chargeback, 12=Refund, 15=Cashout Fee, 16=Refund As ChargeBack
  - Qualifying CompensationReasonIDs: 7=Deposit Adjustment, 41=Guru cash with CO, 50=Guru cash no CO, 51=Affiliate payment with CO, 52=Affiliate payment no CO
  - Time-bounded: `Occurred >= @Registered` excludes pre-registration administrative entries
- Stage 3 (default): No financial history found -> return 2

**Diagram**:
```
GDPRIsDepositor(@CID)
  |
  +--> Billing.Deposit: ANY deposit with PaymentStatusID IN (1,2,4,5,11,12,13,26)?
  |       YES -> return 1 (social details only)
  |
  +--> History.Credit: ANY credit since Registered with qualifying type?
  |       YES -> return 1 (social details only)
  |
  +--> Default: return 2 (personal + social can be erased)
```

### 2.2 Result Semantics: What Each UserExecutionTypeID Enables

**What**: The returned UserExecutionTypeID controls what the GDPR service is permitted to erase.

**Rules**:
- UserExecutionTypeID = 1: "social details" erasure scope
  - GDPR service MAY erase: social profile, publications, AboutMe, social network connections
  - GDPR service MUST RETAIN: personal PII (name, email, phone - overwritten with Del placeholders per GDPRDeleteUser), financial records, account structure
- UserExecutionTypeID = 2: "personal + social" erasure scope
  - GDPR service MAY erase: all PII and social data
  - Customer.GDPRDeleteUser handles the actual PII overwriting regardless of type
  - Type 2 permits a deeper erasure without financial retention exceptions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to classify. Used to query Billing.Deposit and History.Credit for financial activity, and Customer.Customer for the Registered date. |

**Result set (single row returned):**

| Column | Type | Values | Description |
|--------|------|--------|-------------|
| UserExecutionTypeID | INT | 1 or 2 | GDPR erasure classification. 1 = customer has financial history, only social-layer data can be erased. 2 = no financial history, both personal PII and social data can be fully erased. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Read | Retrieves Registered date to bound the History.Credit check |
| @CID | Billing.Deposit | Read (EXISTS check) | Checks for any deposit with qualifying PaymentStatusID |
| @CID | History.Credit | Read (EXISTS check) | Checks for financial credit events since registration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No callers found in SSDT repo. | - | Called from GDPR erasure service. | |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GDPRIsDepositor (procedure)
|- Customer.Customer (view - Registered date lookup)
|- Billing.Deposit (table - cross-schema financial history check)
+-- History.Credit (table - cross-schema credit history check)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Retrieves Registered date for time-bounding History.Credit check |
| Billing.Deposit | Table | Checks for qualifying deposit history by PaymentStatusID |
| History.Credit | Table | Checks for qualifying credit history by CreditTypeID or CompensationReasonID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called from external GDPR erasure service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Billing.Deposit check precedes History.Credit | Early exit optimization | If deposit found, History.Credit is not checked - short-circuit evaluation |
| Occurred >= @Registered | Time filter | Excludes administrative credits predating customer account creation |
| No transaction, no error handling | Design | Read-only EXISTS checks; any failure propagates to caller |
| All PaymentStatusIDs qualify | Design | Even pending/refunded/chargeback deposits trigger type=1 - any payment interaction counts as financial history |

---

## 8. Sample Queries

### 8.1 Classify a customer for GDPR erasure

```sql
EXEC Customer.GDPRIsDepositor @CID = 12345678
-- Returns: UserExecutionTypeID = 1 (has deposits) or 2 (no deposits)
```

### 8.2 Check deposit history for a customer manually

```sql
SELECT PaymentStatusID, COUNT(*) AS DepositCount
FROM Billing.Deposit WITH (NOLOCK)
WHERE CID = 12345678
  AND PaymentStatusID IN (1, 2, 4, 5, 11, 12, 13, 26)
GROUP BY PaymentStatusID
```

### 8.3 Check credit history for a customer manually

```sql
SELECT hc.CreditTypeID, hc.CompensationReasonID, hc.Occurred, cs.Registered
FROM History.Credit hc WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = hc.CID
WHERE hc.CID = 12345678
  AND hc.Occurred >= cs.Registered
  AND (hc.CreditTypeID IN (1, 2, 8, 9, 11, 12, 15, 16)
    OR hc.CompensationReasonID IN (7, 41, 50, 51, 52))
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GDPRIsDepositor | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GDPRIsDepositor.sql*
