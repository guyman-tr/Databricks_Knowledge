# Billing.GetPreferredPayPalAccount

> Resolves the preferred PayPal account for a customer's next deposit: first tries their active PayPal Billing Agreement; if blocked or absent, falls back to the most recent approved PayPal deposit - and auto-deletes blocked billing agreements as a side effect.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 0-1 rows: the preferred PayPal instrument (CID, DepositID, FundingID, PaymentData, BillingAgreementID, PayPalBillingAgreementID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPreferredPayPalAccount` determines which PayPal payment instrument should be pre-selected for a customer's next PayPal deposit. PayPal deposits on eToro can use either a Billing Agreement (a reusable authorization that allows eToro to charge the PayPal account without re-authentication) or a standard approved deposit record. This procedure implements the priority: Billing Agreement first, recent approved deposit as fallback.

The procedure exists to give the deposit setup service (DepositSetupUser) a single call that resolves the preferred PayPal instrument without requiring the service to implement the priority logic or handle blocked instrument cleanup. A critical side effect: if the best Billing Agreement is blocked (either the Funding instrument is blocked or the customer-to-funding link is blocked), the procedure **deletes all PayPal Billing Agreements for that customer** from `Billing.PayPalBillingAgreement` before returning.

Data flows: the deposit setup service calls this at deposit initiation time. The procedure first queries `Billing.PayPalBillingAgreement` for the customer's billing agreement. If found and not blocked, returns it. If blocked, deletes all agreements for the customer and returns empty. If no billing agreement at all, falls back to the most recent approved PayPal deposit from `Billing.Deposit` where neither the Funding instrument nor the CustomerToFunding link is blocked.

---

## 2. Business Logic

### 2.1 Billing Agreement Priority with Block Check

**What**: PayPal Billing Agreements take precedence over deposit history, but blocked agreements are aggressively cleaned up.

**Columns/Parameters Involved**: `ba.IsFundingBlocked`, `CTF.IsBlocked`, `Billing.PayPalBillingAgreement`

**Rules**:
- Step 1: SELECT TOP(1) from PayPalBillingAgreement joined to CustomerToFunding, Funding, and Deposit for the customer
- Step 2: IF any result has `IsFundingBlocked=1 OR IsCTFBlocked=1` -> DELETE ALL PayPalBillingAgreement rows for this CID (not just the blocked one - all of them), and clear the table variable
- This aggressive delete is a security/compliance cleanup - a blocked funding instrument means the customer's PayPal authorization should be fully revoked

### 2.2 Fallback to Most Recent Approved Deposit

**What**: If no valid billing agreement exists (either none found or all deleted due to block), the procedure falls back to finding the most recently used unblocked PayPal funding instrument via deposit history.

**Columns/Parameters Involved**: `Billing.Deposit.PaymentStatusID`, `Billing.Funding.IsBlocked`, `Billing.CustomerToFunding.IsBlocked`

**Rules**:
- Triggered: `IF NOT EXISTS (SELECT * FROM @preferredPayPalAccount)`
- Queries Billing.Deposit for the most recent approved (PaymentStatusID=2) deposit by this customer with FundingTypeID=3 (PayPal) where both Funding.IsBlocked=0 AND CustomerToFunding.IsBlocked=0
- `ORDER BY d.PaymentDate DESC` - most recently used PayPal account
- Returns CID, DepositID, FundingID, PaymentData (no BillingAgreementID/PayPalBillingAgreementID - those are NULL for fallback rows)

**Diagram**:
```
GET preferred PayPal for @CID
          |
          v
  Query PayPalBillingAgreement (TOP 1)
          |
   Found? |
   YES ---+---> Any blocked (Funding or CTF)?
   NO     |         YES -> DELETE ALL agreements for CID
          |               clear table var -> go to fallback
          |         NO  -> return agreement row
          |
  Fallback: Any row in @preferredPayPalAccount?
   NO -> Query Billing.Deposit (TOP 1, PaymentStatusID=2, FundingTypeID=3,
                                Funding.IsBlocked=0, CTF.IsBlocked=0,
                                ORDER BY PaymentDate DESC)
   YES -> return what's there
          |
          v
  SELECT CID, DepositID, FundingID, PaymentData,
         BillingAgreementID, PayPalBillingAgreementID
  FROM @preferredPayPalAccount
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. All queries are scoped to this customer. |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 2 | CID | @CID value | CODE-BACKED | Customer identifier - echoed from the query results. |
| 3 | DepositID | Billing.PayPalBillingAgreement.DepositID or Billing.Deposit.DepositID | CODE-BACKED | The deposit associated with this PayPal instrument. For billing agreements, the deposit that established the agreement. For fallback, the most recent approved PayPal deposit. |
| 4 | FundingID | Billing.PayPalBillingAgreement.FundingID or Billing.Deposit.FundingID | CODE-BACKED | The PayPal funding instrument ID. FK to Billing.Funding (FundingTypeID=3). |
| 5 | PaymentData | Billing.Deposit.PaymentData | CODE-BACKED | XML payment data from the associated deposit. Contains PayPal transaction response data. |
| 6 | BillingAgreementID | Billing.PayPalBillingAgreement.BillingAgreementID | CODE-BACKED | PayPal's external billing agreement token (NVARCHAR 255). NULL for fallback deposit-based results. |
| 7 | PayPalBillingAgreementID | Billing.PayPalBillingAgreement.PayPalBillingAgreementID | CODE-BACKED | Internal eToro billing agreement record ID. NULL for fallback deposit-based results. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.PayPalBillingAgreement.CID | Primary query | Retrieves customer's PayPal billing agreement |
| @CID | Billing.CustomerToFunding.CID | INNER JOIN | Validates the billing agreement's funding instrument link is not blocked |
| (JOIN) | Billing.Funding | INNER JOIN | Checks IsBlocked flag on the funding instrument |
| (JOIN) | Billing.Deposit | INNER JOIN / Fallback source | Used both to retrieve PaymentData for the BA and as fallback payment source |
| (DELETE) | Billing.PayPalBillingAgreement | DELETE (side effect) | Deletes ALL agreements for CID if any blocked instrument is found |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositSetupUser | GRANT EXECUTE | Permission | Deposit setup service calls to determine preferred PayPal instrument before presenting payment options |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPreferredPayPalAccount (procedure)
├── Billing.PayPalBillingAgreement (table)
├── Billing.CustomerToFunding (table)
├── Billing.Funding (table)
└── Billing.Deposit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayPalBillingAgreement | Table | Primary query source; also target of DELETE side effect |
| Billing.CustomerToFunding | Table | INNER JOINed to check CTF.IsBlocked |
| Billing.Funding | Table | INNER JOINed to check Funding.IsBlocked |
| Billing.Deposit | Table | Source of PaymentData; also fallback payment instrument query |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositSetupUser | DB Security Principal | EXECUTE permission - preferred PayPal resolution at deposit setup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**IMPORTANT - Write side effect**: Despite its `Get` prefix, this procedure has a **DELETE side effect**: if the customer's best PayPal billing agreement is found to use a blocked funding instrument, the procedure deletes ALL PayPal billing agreements for that customer from `Billing.PayPalBillingAgreement`. This is intentional cleanup logic but makes this a non-read-only procedure. The caller (DepositSetupUser) must have both SELECT and DELETE permissions on PayPalBillingAgreement.

---

## 8. Sample Queries

### 8.1 Get preferred PayPal account for a customer
```sql
EXEC [Billing].[GetPreferredPayPalAccount] @CID = 12345678
```

### 8.2 Check if a customer has a PayPal billing agreement
```sql
SELECT PayPalBillingAgreementID, BillingAgreementID, FundingID, DepositID
FROM Billing.PayPalBillingAgreement WITH (NOLOCK)
WHERE CID = 12345678
```

### 8.3 Find most recent approved PayPal deposit for a customer (fallback logic equivalent)
```sql
SELECT TOP 1
    d.CID, d.DepositID, d.FundingID, d.PaymentData
FROM Billing.Deposit d WITH (NOLOCK)
INNER JOIN Billing.Funding f WITH (NOLOCK)
    ON d.FundingID = f.FundingID AND f.IsBlocked = 0
INNER JOIN Billing.CustomerToFunding CTF WITH (NOLOCK)
    ON d.FundingID = CTF.FundingID AND CTF.IsBlocked = 0 AND CTF.CID = 12345678
WHERE d.CID = 12345678
  AND d.PaymentStatusID = 2
  AND f.FundingTypeID = 3
ORDER BY d.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPreferredPayPalAccount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPreferredPayPalAccount.sql*
