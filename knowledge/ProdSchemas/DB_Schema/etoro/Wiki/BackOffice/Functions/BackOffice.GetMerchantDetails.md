# BackOffice.GetMerchantDetails

> Scalar function returning either the display name or BackOffice description of a payment merchant account, used to resolve merchant identifiers to human-readable labels in deposit and withdrawal reports.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(MAX) - merchant name or BO description |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetMerchantDetails` resolves a merchant account ID to a human-readable label for display in BackOffice financial reports. The caller controls which label to retrieve: passing `@MerchantAccountDetail=0` returns the merchant's short name (Name), while `@MerchantAccountDetail=1` returns the BackOffice-specific display description (BODescription).

This function is a critical component of BackOffice payment reporting. Deposit and withdrawal reports need to display which payment merchant processed each transaction, but the underlying data stores only a numeric MerchantAccountID. This function provides the label lookup, and is called across 9 BackOffice procedures covering all major payment report types: deposits (BillingDepositsPCIVersion), cashouts/withdrawals (GetCashOutRequests, GetProcessedWithdrawPCIVersion, GetWithdrawRequestsDetailsByID), in-process payments (InProcessPaymentsToSendPCIVersion), and risk reports (GetRiskExposureReportPCIVersion).

Created 03/01/2021 as part of MIMOPSA-3037 (Checkout.com MID table update), when the merchant account infrastructure was expanded to support multiple payment providers. The function provides a fallback-safe way to display merchant info in COALESCE chains: when a more specific label is available (e.g., from a depot-specific lookup), GetMerchantDetails is used as a fallback.

---

## 2. Business Logic

### 2.1 Name vs. BODescription Selection

**What**: The caller passes a selector flag (0 or 1) to choose which merchant label to return.

**Columns/Parameters Involved**: `@MerchantAccountId`, `@MerchantAccountDetail`

**Rules**:
- @MerchantAccountDetail=0: Returns Dictionary.MerchantAccount.Name - the short merchant identifier used in MID columns (e.g., "CHECKOUT_GBP", "ADYEN_EUR")
- @MerchantAccountDetail=1: Returns Dictionary.MerchantAccount.BODescription - the longer display description used in "MID Name" columns (e.g., "Checkout.com GBP Account", "Adyen Europe EUR")
- If MerchantAccountID is not found in Dictionary.MerchantAccount: returns NULL (DECLARE @Detail VARCHAR(MAX) defaults to NULL)
- Used in COALESCE/ISNULL chains in callers: `COALESCE(DMA.[BODescription], BackOffice.GetMerchantDetails(BPMS.MerchantAccountID, 1), DR.Name)`

**Diagram**:
```
@MerchantAccountId + @MerchantAccountDetail
            |
            v
Dictionary.MerchantAccount
WHERE MerchantAccountID = @MerchantAccountId
            |
  @MerchantAccountDetail = 0 --> Name (short ID)
  @MerchantAccountDetail = 1 --> BODescription (display name)
            |
            v
VARCHAR(MAX) or NULL if merchant not found
```

### 2.2 Role in Payment Report MID Resolution

**What**: The function is always used as a fallback in a COALESCE/ISNULL chain, never as the sole source of merchant name.

**Columns/Parameters Involved**: `@MerchantAccountId`, `@MerchantAccountDetail`

**Rules**:
- In BillingDepositsPCIVersion: `COALESCE(DMA.[BODescription], BackOffice.GetMerchantDetails(BPMS.MerchantAccountID, 1), DR.Name)` - tries pre-joined DMA first, then this function, then regulation name
- In GetCashOutRequests: `ISNULL(BackOffice.GetMerchantDetails(BWTF.MerchantAccountID, 1), CASE ...)` - function is first fallback
- In GetProcessedWithdrawPCIVersion: called twice per row (once for MIDName with detail=1, once for MID with detail=0), with depot-specific overrides taking priority
- The dual-call pattern (detail=0 and detail=1) provides both the short MID identifier and the display name from a single function with different arguments.

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MerchantAccountId | INT | NO | - | CODE-BACKED | The MerchantAccountID from Dictionary.MerchantAccount identifying the payment merchant to look up. If this ID does not exist in the dictionary, the function returns NULL. |
| 2 | @MerchantAccountDetail | INT | NO | - | CODE-BACKED | Selector for which label to return: 0 = Name (short merchant identifier, used in MID column), 1 = BODescription (full display name, used in MID Name column). Other values are not handled by the CASE and will return NULL. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Detail | VARCHAR(MAX) | YES | NULL | CODE-BACKED | The selected merchant label: Name (when @MerchantAccountDetail=0) or BODescription (when @MerchantAccountDetail=1) from Dictionary.MerchantAccount. Returns NULL if the MerchantAccountID is not found or if @MerchantAccountDetail is not 0 or 1. Callers wrap in ISNULL or COALESCE to handle the NULL case. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MerchantAccountId | Dictionary.MerchantAccount | Lookup | SELECT Name or BODescription WHERE MerchantAccountID = @MerchantAccountId. Source dictionary for all merchant account labels. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.BillingDepositsPCIVersion | MIDName, MID columns | Function call | Called with detail=1 (BODescription) and detail=0 (Name) in COALESCE chains for deposit report MID labeling. |
| BackOffice.BillingDepositsPCIVersion_Old | MIDName, MID columns | Function call | Legacy version of BillingDepositsPCIVersion - same pattern. |
| BackOffice.GetCashOutRequests | MIDName, MID columns | Function call | Used in ISNULL chain for cashout report MID labeling (both detail=1 and detail=0). |
| BackOffice.GetProcessedWithdrawPCIVersion | MIDName, MID columns | Function call | Called twice per row (detail=1 and detail=0) as fallback in withdrawal processing report. |
| BackOffice.GetProcessedWithdrawPCIVersion_Old | MIDName, MID columns | Function call | Legacy version - same pattern. |
| BackOffice.GetRiskExposureReportPCIVersion | MIDName, MID columns | Function call | Risk exposure report - merchant labeling in COALESCE chain. |
| BackOffice.GetRiskExposureReportPCIVersion_Old | MIDName, MID columns | Function call | Legacy version - same pattern. |
| BackOffice.GetWithdrawRequestsDetailsByID | MIDName, MID columns | Function call | Withdrawal detail report - ISNULL chain with merchant label. |
| BackOffice.InProcessPaymentsToSendPCIVersion | MID column | Function call | In-process payment report - merchant MID label. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetMerchantDetails (function)
└── Dictionary.MerchantAccount (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MerchantAccount | Table | SELECT Name or BODescription WHERE MerchantAccountID = @MerchantAccountId. The selector CASE determines which column is returned. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BillingDepositsPCIVersion | Stored Procedure | READER - calls function for MID and MID Name columns in deposit reports. |
| BackOffice.BillingDepositsPCIVersion_Old | Stored Procedure | READER - legacy deposit report version. |
| BackOffice.GetCashOutRequests | Stored Procedure | READER - cashout report MID labeling. |
| BackOffice.GetProcessedWithdrawPCIVersion | Stored Procedure | READER - processed withdrawal report. |
| BackOffice.GetProcessedWithdrawPCIVersion_Old | Stored Procedure | READER - legacy version. |
| BackOffice.GetRiskExposureReportPCIVersion | Stored Procedure | READER - risk report merchant labeling. |
| BackOffice.GetRiskExposureReportPCIVersion_Old | Stored Procedure | READER - legacy version. |
| BackOffice.GetWithdrawRequestsDetailsByID | Stored Procedure | READER - withdrawal detail report. |
| BackOffice.InProcessPaymentsToSendPCIVersion | Stored Procedure | READER - in-process payment report. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Get both name and description for a merchant account

```sql
SELECT
    BackOffice.GetMerchantDetails(5, 0) AS MerchantName,
    BackOffice.GetMerchantDetails(5, 1) AS MerchantBODescription;
```

### 8.2 Resolve merchant IDs for all recent cashout requests

```sql
SELECT TOP 100
    bc.CashoutID,
    bc.Amount / 100.0 AS AmountUSD,
    bc.MerchantAccountID,
    BackOffice.GetMerchantDetails(bc.MerchantAccountID, 0) AS MerchantName,
    BackOffice.GetMerchantDetails(bc.MerchantAccountID, 1) AS MerchantDisplayName
FROM Billing.Cashout bc WITH (NOLOCK)
WHERE bc.MerchantAccountID IS NOT NULL
ORDER BY bc.RequestDate DESC;
```

### 8.3 Alternative using direct dictionary lookup (avoids per-row scalar function overhead)

```sql
SELECT
    bc.CashoutID,
    bc.Amount / 100.0 AS AmountUSD,
    dma.Name AS MerchantName,
    dma.BODescription AS MerchantDisplayName
FROM Billing.Cashout bc WITH (NOLOCK)
LEFT JOIN Dictionary.MerchantAccount dma WITH (NOLOCK)
    ON dma.MerchantAccountID = bc.MerchantAccountID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-3037: DB scripts](https://etoro-jira.atlassian.net/browse/MIMOPSA-3037) | Jira Sub-task | DB scripts task under MIMOPSA-2941 "OPS01347 - Checkout.com - MID table update". Function created 03/01/2021 as part of expanding merchant account infrastructure for Checkout.com integration. Assigned to Shay Oren. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetMerchantDetails | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetMerchantDetails.sql*
