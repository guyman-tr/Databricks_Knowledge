# Billing.vFunding

> Security-aware projection of Billing.Funding that exposes only administrative and status columns (IsBlocked, DocumentRequired, IsRefundExcluded, FundingTypeID, ManagerID) while omitting all sensitive payment data: FundingData XML, SecuredCardData, FundingHash, FundingDataCheckSum, Parameter, PaymentDetails, KeyVersion, DateCreated.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | FundingID |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.vFunding` answers the question "is this payment instrument blocked, document-required, or refund-excluded?" without exposing any sensitive card or account data. It is a privacy-first projection of `Billing.Funding` that exposes exactly 8 of the ~17 columns - all administrative/status fields - while deliberately omitting:

- `FundingData` (XML, DDM-masked PII: card numbers, account identifiers)
- `FundingDataCheckSum`, `SecuredCardData`, `FundingHash`, `Parameter` (computed columns derived from FundingData)
- `PaymentDetails` (trigger-maintained formatted payment string)
- `DateCreated`, `KeyVersion`

This design allows callers that only need to check instrument status (is it blocked? does it need documents?) to query without receiving PCI-sensitive card data. It also bypasses Dynamic Data Masking (DDM) concerns since `FundingData` is masked by default.

3,524,559 rows. No stored procedure callers found in the SQL codebase - likely consumed by microservices or BI tools via direct SQL access.

---

## 2. Business Logic

### 2.1 Sensitive Data Omission (Privacy-First Design)

**What**: All PCI/PII-sensitive columns are deliberately excluded from the view.

**Columns/Parameters Involved**: (omitted) FundingData, SecuredCardData, FundingHash, FundingDataCheckSum, Parameter, PaymentDetails, KeyVersion, DateCreated

**Rules**:
- `FundingData` (XML, DDM-masked): card/account data omitted entirely
- `SecuredCardData` (computed from FundingData): masked card data omitted
- `FundingHash` (computed from FundingData): de-duplication hash omitted
- `FundingDataCheckSum` (computed from FundingData): checksum omitted
- `Parameter` (computed from FundingData via dbo.F_FundingData): formatted account identifier omitted
- `PaymentDetails` (nvarchar, trigger-maintained): human-readable payment description omitted
- `DateCreated`, `KeyVersion`: metadata omitted
- The view exposes ONLY: FundingID, FundingTypeID, ManagerID, IsBlocked, BlockedDescription, BlockedAt, IsRefundExcluded, DocumentRequired

---

## 3. Data Overview

| FundingID | FundingTypeID | ManagerID | IsBlocked | BlockedDescription | IsRefundExcluded | DocumentRequired | Meaning |
|-----------|--------------|-----------|-----------|-------------------|------------------|-----------------|---------|
| (sample) | 1 (CreditCard) | NULL | 0 | NULL | 0 | 0 | Active unblocked credit card instrument - no documents required |
| (sample) | 2 (WireTransfer) | 1234 | 1 | "Suspected fraud" | 1 | 1 | Blocked wire transfer, refund excluded, documents required |

**Row count**: 3,524,559 (all funding instruments in Billing.Funding)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Unique payment instrument identifier. PK of Billing.Funding. IDENTITY(1000,1). The primary lookup key for this view. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. From Billing.Funding. References Dictionary.FundingType. 1=CreditCard, 2=WireTransfer, 3=PayPal, etc. Identifies the category of payment instrument. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | Assigned manager/agent ID. From Billing.Funding. NULL for most instruments; set when an instrument is manually assigned to a specific manager for review. |
| 4 | IsBlocked | bit | NO | - | CODE-BACKED | 1=this payment instrument is blocked (suspended) and cannot be used for deposits or withdrawals. 0=active/unblocked. Primary status flag for instrument eligibility checks. |
| 5 | BlockedDescription | varchar(255) | YES | - | CODE-BACKED | Reason text for why the instrument was blocked. NULL when IsBlocked=0. Human-readable explanation (e.g., "Suspected fraud", "Customer request", "AML hold"). |
| 6 | BlockedAt | datetime | YES | - | CODE-BACKED | Timestamp when the instrument was blocked. NULL when IsBlocked=0. Enables time-based audit of blocking actions. |
| 7 | IsRefundExcluded | bit | NO | - | CODE-BACKED | 1=this instrument is excluded from the standard refund/chargeback process. 0=eligible for refunds. Used in refund eligibility logic to skip instruments that should not receive returns. |
| 8 | DocumentRequired | bit | NO | - | CODE-BACKED | 1=additional identity documents are required before this instrument can be used for withdrawals. 0=no extra documents needed. Used in KYC/compliance workflows to flag instruments requiring enhanced due diligence. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All 8 columns | Billing.Funding | Source (SELECT 8 of 17 columns, no filter) | Administrative status columns only; all PCI/PII-sensitive columns omitted |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedure callers found in SQL codebase | - | - | Likely consumed by microservices or BI tools via direct SQL |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.vFunding (view)
└── Billing.Funding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | SELECT 8 columns: FundingID, FundingTypeID, ManagerID, IsBlocked, BlockedDescription, BlockedAt, IsRefundExcluded, DocumentRequired. No WHERE filter. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered | - | No stored procedures reference this view in the SSDT repo |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. 3,524,559 rows. Callers should filter on FundingID (clustered PK) or FundingTypeID (non-clustered index in Billing.Funding). The view definition includes `WITH(NOLOCK)` hint on the base table for read consistency.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. All 8 columns are directly from Billing.Funding with no transformations. The view does NOT apply any WHERE filter - all 3,524,559 funding records are returned. The primary purpose is column-level security: omitting FundingData prevents inadvertent access to card/account numbers by callers querying via this view.

---

## 8. Sample Queries

### 8.1 Check if a payment instrument is blocked

```sql
SELECT FundingID, IsBlocked, BlockedDescription, BlockedAt
FROM Billing.vFunding WITH (NOLOCK)
WHERE FundingID = @FundingID
```

### 8.2 Find instruments requiring documents by type

```sql
SELECT FundingTypeID, COUNT(*) AS CountRequiringDocs
FROM Billing.vFunding WITH (NOLOCK)
WHERE DocumentRequired = 1
GROUP BY FundingTypeID
ORDER BY CountRequiringDocs DESC
```

### 8.3 Find blocked instruments with reasons

```sql
SELECT FundingID, FundingTypeID, BlockedDescription, BlockedAt
FROM Billing.vFunding WITH (NOLOCK)
WHERE IsBlocked = 1
ORDER BY BlockedAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.vFunding | Type: View | Source: etoro/etoro/Billing/Views/Billing.vFunding.sql*
