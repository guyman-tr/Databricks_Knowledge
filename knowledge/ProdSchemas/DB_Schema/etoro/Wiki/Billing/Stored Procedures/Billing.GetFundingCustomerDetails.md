# Billing.GetFundingCustomerDetails

> Returns security and status details for a specific funding method in the context of a given customer, indicating whether the funding is third-party blocked or deposit-blocked.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Before allowing a customer to use an existing funding method (for deposit or withdrawal operations), the system needs to verify that the funding is accessible and not restricted for that specific customer. This procedure retrieves the funding's raw data along with two computed security flags:

- `Is3dPartyBlocked`: Whether a third party (another customer) has an active claim on this funding for this @CID - indicating the funding is "locked" to a different customer under a third-party arrangement
- `IsDepositBlocked`: Whether deposits are blocked, either because the customer's specific link (CustomerToFunding.IsBlocked) or the funding itself (Funding.IsBlocked) is flagged

The distinction between IsBlocked (in CustomerToFunding) and IsRefundExcluded (used in GetExistingFunding) is important: IsBlocked blocks ALL operations (deposits and withdrawals) while IsRefundExcluded only blocks refund/withdrawal operations.

---

## 2. Business Logic

### 2.1 Third-Party Block Detection

**What**: Detects if another customer has a third-party claim on this funding for @CID.

**Columns/Parameters Involved**: `Is3dPartyBlocked`

**Rules**:
- `BackOffice.CustomerToThirdPartyFundings` stores third-party relationships
- JOIN condition: FundingID matches AND CID = BC.CID (using CustomerToFunding.CID, not @CID - note this may be a specificity in the join logic)
- `IIF(CTP.CID IS NOT NULL, @True, @False)` - any matching row means third-party block = true
- Third-party blocks indicate the funding is already assigned to another customer's account for AML/compliance purposes

### 2.2 Deposit Block Assessment

**What**: IsDepositBlocked combines two independent block signals.

**Columns/Parameters Involved**: `IsDepositBlocked`

**Rules**:
- `BC.IsBlocked = 1`: The customer's specific link to this funding is blocked (CustomerToFunding.IsBlocked)
- `BF.IsBlocked = 1`: The funding method itself is globally blocked (Billing.Funding.IsBlocked)
- `IIF(BC.IsBlocked = 1 OR BF.IsBlocked = 1, @True, @False)`: either condition alone is sufficient to block deposits
- Note: these IsBlocked columns block deposits specifically; IsRefundExcluded (used elsewhere) blocks refunds

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used to join CustomerToFunding and CustomerToThirdPartyFundings to get customer-specific flags. |
| 2 | @FundingId | INT | NO | - | CODE-BACKED | Primary key of Billing.Funding. Identifies the specific funding method to check. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | YES | NULL | CODE-BACKED | Primary key from Billing.CustomerToFunding. Same as @FundingId if a CustomerToFunding link exists; may differ if only the Funding base record is found. |
| R2 | FundingData | XML | YES | NULL | CODE-BACKED | Raw XML from Billing.Funding containing all funding details (card number, bank details, etc.). Application parses this for display or processing. |
| R3 | Is3dPartyBlocked | BIT | NO | - | CODE-BACKED | 1 = a third-party customer has a claim on this funding for @CID (via BackOffice.CustomerToThirdPartyFundings). 0 = no third-party restriction. IIF(CTP.CID IS NOT NULL, 1, 0). |
| R4 | IsDepositBlocked | BIT | NO | - | CODE-BACKED | 1 = deposits are blocked for this funding (either CustomerToFunding.IsBlocked=1 or Billing.Funding.IsBlocked=1). 0 = deposits allowed. IIF(BC.IsBlocked=1 OR BF.IsBlocked=1, 1, 0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingId | Billing.Funding | LEFT JOIN (base) | Main funding record (FundingData + IsBlocked) |
| @FundingId + @CID | Billing.CustomerToFunding | LEFT JOIN | Customer-specific block status (IsBlocked) |
| FundingID + BC.CID | BackOffice.CustomerToThirdPartyFundings | LEFT JOIN | Third-party claim detection |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment services | @CID + @FundingId | EXEC | Pre-operation check before allowing deposit/withdrawal on a specific funding |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingCustomerDetails (procedure)
├── Billing.Funding (table)
├── Billing.CustomerToFunding (table)
└── BackOffice.CustomerToThirdPartyFundings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | LEFT JOIN on FundingID; FundingData + IsBlocked |
| Billing.CustomerToFunding | Table | LEFT JOIN on FundingID AND CID = @CID; IsBlocked |
| BackOffice.CustomerToThirdPartyFundings | Table | LEFT JOIN on FundingID AND CID = BC.CID; third-party detection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application payment services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if a specific funding is accessible for a customer

```sql
EXEC Billing.GetFundingCustomerDetails
    @CID = 1234567,
    @FundingId = 98765;
-- Is3dPartyBlocked=0 AND IsDepositBlocked=0 -> funding is usable
```

### 8.2 Check all blocked fundings for a customer

```sql
SELECT ctf.FundingID, ctf.IsBlocked AS CidBlocked, f.IsBlocked AS FundingBlocked
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON ctf.FundingID = f.FundingID
WHERE ctf.CID = 1234567
  AND (ctf.IsBlocked = 1 OR f.IsBlocked = 1);
```

### 8.3 Inspect third-party funding assignments

```sql
SELECT FundingID, CID
FROM BackOffice.CustomerToThirdPartyFundings WITH (NOLOCK)
WHERE FundingID = 98765;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingCustomerDetails | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingCustomerDetails.sql*
