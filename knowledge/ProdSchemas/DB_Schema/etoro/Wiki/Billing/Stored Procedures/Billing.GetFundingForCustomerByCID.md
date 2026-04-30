# Billing.GetFundingForCustomerByCID

> Returns all funding methods registered for a customer across all payment types, including full funding details and customer-relationship metadata such as first/last use dates and block reasons.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the broadest funding retrieval operation - it returns ALL funding methods ever registered for a customer, across all payment types (credit cards, wires, Trustly, etc.). Unlike GetFundingForCustomer which filters by FundingTypeID, this procedure provides a comprehensive view of the customer's complete payment method portfolio.

It is used by back-office systems, customer profile pages, and risk/compliance tooling to see every payment method a customer has ever used. The result includes timestamps (Occurred = when the customer-funding link was created, LastUsedDate = most recent transaction date), block flags, and a ReasonID explaining why a funding was blocked.

Notable additions over time: CustomerToFundingIsBlocked column (PAYUA-2518, September 2021), DateCreated (PAYIL-5076, September 2022), and ReasonID for block explanations (PAYIL-5616, November 2022).

---

## 2. Business Logic

### 2.1 Dual Block Perspective

**What**: Returns both system-level and customer-level block flags for each funding.

**Rules**:
- `F.IsBlocked`: System-wide block - no customer can use this funding (global suspension)
- `C.IsBlocked AS CustomerToFundingIsBlocked`: Customer-specific block on this funding
- Both can be true simultaneously; callers must check both
- `C.ReasonID`: Reason code for the customer-level block (added PAYIL-5616)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Matched against Billing.CustomerToFunding.CID. Returns ALL funding types for this customer. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | Primary key of Billing.Funding. |
| R2 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type. Lookup: Dictionary.FundingType. |
| R3 | ManagerID | INT | YES | NULL | CODE-BACKED | Back-office user who manages this funding record. |
| R4 | IsBlocked | BIT | YES | NULL | CODE-BACKED | Billing.Funding.IsBlocked. System-wide block on this funding method. |
| R5 | BlockedDescription | NVARCHAR | YES | NULL | CODE-BACKED | Human-readable block reason at the funding level. |
| R6 | BlockedAt | DATETIME | YES | NULL | CODE-BACKED | Timestamp when the funding was system-blocked. NULL if not blocked. |
| R7 | FundingData | XML | YES | NULL | CODE-BACKED | Full XML payment method details (card number, IBAN, etc.). |
| R8 | IsRefundExcluded | BIT | YES | NULL | CODE-BACKED | Billing.Funding.IsRefundExcluded. 1 = refunds/withdrawals excluded system-wide. |
| R9 | DocumentRequired | BIT | YES | NULL | CODE-BACKED | 1 = documentation required before this funding can be used. |
| R10 | FundingDataCheckSum | INT | YES | NULL | CODE-BACKED | Checksum of FundingData for integrity. |
| R11 | SecuredCardData | VARBINARY | YES | NULL | CODE-BACKED | Encrypted card data (PAN, CVV). Stored securely. |
| R12 | Parameter | NVARCHAR | YES | NULL | CODE-BACKED | Additional funding-type-specific parameters. |
| R13 | FundingHash | VARBINARY | YES | NULL | CODE-BACKED | Hash of FundingData for deduplication. |
| R14 | DateCreated | DATETIME | YES | NULL | CODE-BACKED | Billing.Funding.DateCreated. When this funding method was first created in the system. Added per PAYIL-5076. |
| R15 | CustomerFundingStatusID | INT | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.CustomerFundingStatusID. Customer-specific status for this funding (e.g., Active, Pending verification). |
| R16 | Occurred | DATETIME | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.Occurred. When this customer-to-funding relationship was established (customer first linked to this funding). |
| R17 | LastUsedDate | DATETIME | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.LastUsedDate. Most recent date this funding was used for a transaction by this customer. |
| R18 | CustomerToFundingIsBlocked | BIT | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.IsBlocked aliased. 1 = this specific customer's access to this funding is blocked (customer-level block, separate from system-level IsBlocked). Added PAYUA-2518. |
| R19 | ReasonID | INT | YES | NULL | CODE-BACKED | Billing.CustomerToFunding.ReasonID. Reason code explaining why the customer-level block was applied. Added PAYIL-5616. Lookup: likely a reason code table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.CustomerToFunding | JOIN | Customer's complete funding portfolio |
| FundingID | Billing.Funding | JOIN | All funding details across all types |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office customer profile, risk/compliance | @CID | EXEC | Full funding portfolio view for a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingForCustomerByCID (procedure)
├── Billing.CustomerToFunding (table)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | JOIN on CID; CustomerFundingStatusID, Occurred, LastUsedDate, IsBlocked, ReasonID |
| Billing.Funding | Table | JOIN on FundingID; all funding detail columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from back-office and application services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all fundings for a customer

```sql
EXEC Billing.GetFundingForCustomerByCID @CID = 1234567;
```

### 8.2 Find all blocked fundings for a customer

```sql
SELECT f.FundingID, f.FundingTypeID, f.IsBlocked AS SystemBlocked,
       ctf.IsBlocked AS CustomerBlocked, ctf.ReasonID
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON ctf.FundingID = f.FundingID
WHERE ctf.CID = 1234567
  AND (f.IsBlocked = 1 OR ctf.IsBlocked = 1);
```

### 8.3 Find most recently used funding method for a customer

```sql
SELECT TOP 1 ctf.FundingID, ctf.LastUsedDate, f.FundingTypeID
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON ctf.FundingID = f.FundingID
WHERE ctf.CID = 1234567
ORDER BY ctf.LastUsedDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingForCustomerByCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingForCustomerByCID.sql*
