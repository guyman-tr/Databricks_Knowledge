# Billing.GetFundingForCustomer

> Returns all funding methods of a specific type registered by a customer, optionally filtered by customer funding status, including full funding details and block/security flags.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer wants to deposit or withdraw using a particular payment method type (e.g., all their credit cards, or all their wire transfer accounts), this procedure retrieves the full details of all matching funding methods registered under that customer. The result includes both the funding's raw data and its block/security status from two perspectives: the funding itself (IsBlocked, IsRefundExcluded) and the customer's specific relationship to it (CustomerFundingStatusID, IsBlocked).

This procedure is typically called by the deposit or withdrawal UI to present the customer's available payment options of a given type, and by back-office tooling to inspect a customer's funding setup.

The optional @CustomerFundingStatusID parameter allows filtering to only active fundings (e.g., StatusID=1 = Active), or to a specific status (pending verification, etc.) - when NULL, all statuses are returned.

---

## 2. Business Logic

### 2.1 Optional Status Filtering

**What**: Allows filtering funding records by the customer's funding status with NULL meaning "all statuses".

**Columns/Parameters Involved**: `@CustomerFundingStatusID`, `CustomerFundingStatusID`

**Rules**:
- `C.CustomerFundingStatusID = ISNULL(@CustomerFundingStatusID, C.CustomerFundingStatusID)` - NULL-safe equality
- When @CustomerFundingStatusID IS NULL: `C.CustomerFundingStatusID = C.CustomerFundingStatusID` is always true (no filter)
- When a specific value is provided: only fundings with that exact status are returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Matched against Billing.CustomerToFunding.CID. |
| 2 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type. Matched against Billing.Funding.FundingTypeID. Lookup: Dictionary.FundingType. Only fundings of this type are returned. |
| 3 | @CustomerFundingStatusID | INT | YES | NULL | CODE-BACKED | Optional filter for customer funding status (e.g., 1=Active, 2=Pending). When NULL, all statuses are returned. Lookup: likely Dictionary or Billing table for CustomerFundingStatus values. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | Primary key of Billing.Funding. Identifies the specific funding method. |
| R2 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type. Same as @FundingTypeID. Lookup: Dictionary.FundingType. |
| R3 | ManagerID | INT | YES | NULL | CODE-BACKED | From Billing.Funding.ManagerID. Back-office user who manages this funding record. |
| R4 | IsFundingBlocked | BIT | YES | NULL | CODE-BACKED | Billing.Funding.IsBlocked aliased as IsFundingBlocked. 1 = the funding method is globally blocked (all customers cannot use it). |
| R5 | BlockedDescription | NVARCHAR | YES | NULL | CODE-BACKED | Billing.Funding.BlockedDescription. Human-readable reason why the funding was blocked. |
| R6 | BlockedAt | DATETIME | YES | NULL | CODE-BACKED | Billing.Funding.BlockedAt. Timestamp when the funding was blocked. NULL if not blocked. |
| R7 | FundingData | XML | YES | NULL | CODE-BACKED | Billing.Funding.FundingData. XML containing the payment method details (card number, IBAN, etc.). |
| R8 | IsRefundExcluded | BIT | YES | NULL | CODE-BACKED | Billing.Funding.IsRefundExcluded. 1 = refunds/withdrawals are excluded for this funding system-wide. |
| R9 | DocumentRequired | BIT | YES | NULL | CODE-BACKED | Billing.Funding.DocumentRequired. 1 = additional documentation is required before this funding can be used. |
| R10 | FundingDataCheckSum | INT | YES | NULL | CODE-BACKED | Billing.Funding.FundingDataCheckSum. Checksum of the funding data for integrity verification. |
| R11 | SecuredCardData | VARBINARY | YES | NULL | CODE-BACKED | Billing.Funding.SecuredCardData. Encrypted/secured card data (PAN, CVV, etc.) stored securely. |
| R12 | Parameter | NVARCHAR | YES | NULL | CODE-BACKED | Billing.Funding.Parameter. Additional funding-type-specific parameters. |
| R13 | FundingHash | VARBINARY | YES | NULL | CODE-BACKED | Billing.Funding.FundingHash. Hash of FundingData used for deduplication (see GetExistingFunding). |
| R14 | CustomerFundingStatusID | INT | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.CustomerFundingStatusID. Customer-specific status for this funding (e.g., 1=Active, 2=Pending). |
| R15 | IsBlocked | BIT | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.IsBlocked. 1 = this customer's use of this funding is blocked (customer-level block, not system-wide). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.CustomerToFunding | JOIN | Customer-specific funding relationship |
| FundingID | Billing.Funding | JOIN | Full funding details |
| @FundingTypeID | Dictionary.FundingType | Lookup (implicit) | FundingTypeID is an FK to Dictionary.FundingType |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment services / back-office | @CID + @FundingTypeID | EXEC | Retrieves customer's funding methods for a given type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingForCustomer (procedure)
├── Billing.CustomerToFunding (table)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | JOIN by CID + FundingTypeID + optional StatusID filter |
| Billing.Funding | Table | JOIN on FundingID for full funding details |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application layer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all active credit card fundings for a customer

```sql
EXEC Billing.GetFundingForCustomer
    @CID = 1234567,
    @FundingTypeID = 1,            -- Credit card
    @CustomerFundingStatusID = 1;  -- Active only
```

### 8.2 Get all fundings of a type regardless of status

```sql
EXEC Billing.GetFundingForCustomer
    @CID = 1234567,
    @FundingTypeID = 2,           -- Wire transfer
    @CustomerFundingStatusID = NULL;
```

### 8.3 Find all blocked wire transfer fundings for a customer

```sql
SELECT ctf.FundingID, f.IsBlocked AS FundingBlocked, ctf.IsBlocked AS CidBlocked
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON ctf.FundingID = f.FundingID
WHERE ctf.CID = 1234567 AND f.FundingTypeID = 2
  AND (f.IsBlocked = 1 OR ctf.IsBlocked = 1);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingForCustomer | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingForCustomer.sql*
