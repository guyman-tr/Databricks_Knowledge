# Billing.GetFundingRecurringData

> Returns the funding details and credit card 3DS scheme information needed to execute a recurring (scheduled) card payment for a specific customer and funding.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingId + @Cid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Recurring payments (such as scheduled deposits or copy trading auto-invest) require additional card scheme metadata beyond the basic funding record. Specifically, the payment processor needs to know:
1. The full card details from FundingData (card number, expiry, etc.)
2. Whether the card uses 3D Secure (IsThreeDs) - determines authentication flow
3. The card scheme ID (SchemeID) - identifies the card network (Visa/Mastercard/etc.)

This procedure retrieves all three pieces in a single call by joining Billing.Funding with Billing.CreditCardSchemeID. The CreditCardSchemeID join is LEFT JOIN filtered to FundingTypeID=1 (credit cards), so if the funding is not a credit card, SchemeID and IsThreeDs will be NULL - but the funding data is still returned.

The procedure was introduced in May 2021 as part of the recurring investment feature.

---

## 2. Business Logic

### 2.1 Credit Card Scheme Join

**What**: LEFT JOINs CreditCardSchemeID to enrich credit card fundings with 3DS and scheme information.

**Rules**:
- `LEFT JOIN Billing.CreditCardSchemeID ccsi ON F.FundingID = ccsi.FundingID AND ccsi.CID = @Cid AND F.FundingTypeID = 1`
- The `F.FundingTypeID = 1` condition in the JOIN predicate (not WHERE) means: only apply scheme data for credit cards
- Non-credit-card fundings still return their row with NULL SchemeID and IsThreeDs
- CID is part of the join condition - scheme records are customer-specific (same card used by different customers may have different scheme records)
- No status or block filters - returns the funding regardless of block status (caller decides how to handle)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingId | INTEGER | NO | - | CODE-BACKED | Primary key of Billing.Funding. Identifies the specific funding (typically a credit card) for which recurring payment data is needed. |
| 2 | @Cid | INTEGER | NO | - | CODE-BACKED | Customer identifier. Used to scope the CreditCardSchemeID join to this customer's scheme record. Ensures correct scheme data when the same funding is shared across customers. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | Primary key of Billing.Funding. Confirms which funding was retrieved. |
| R2 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type. For recurring payments, typically 1 (credit card). Lookup: Dictionary.FundingType. |
| R3 | FundingData | XML | YES | NULL | CODE-BACKED | Full XML card details (card number, expiry, cardholder name, etc.) needed by the payment processor to charge the card. |
| R4 | SchemeID | INT | YES | NULL | CODE-BACKED | Billing.CreditCardSchemeID.SchemeID. The card network scheme (e.g., 1=Visa, 2=Mastercard). NULL if FundingTypeID != 1 or no scheme record found. Used by the recurring payment processor to route correctly. |
| R5 | IsThreeDs | BIT | YES | NULL | CODE-BACKED | Billing.CreditCardSchemeID.IsThreeDs. 1 = the card requires/supports 3D Secure authentication. NULL if FundingTypeID != 1. Determines whether the recurring charge goes through 3DS flow. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingId | Billing.Funding | Lookup | Primary funding data source |
| @Cid + FundingTypeID=1 | Billing.CreditCardSchemeID | LEFT JOIN | 3DS and scheme enrichment for credit cards |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application recurring investment / scheduled deposit service | @FundingId + @Cid | EXEC | Retrieves card data + 3DS info before processing recurring payment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingRecurringData (procedure)
├── Billing.Funding (table)
└── Billing.CreditCardSchemeID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Primary key lookup by FundingID - returns FundingID, FundingTypeID, FundingData |
| Billing.CreditCardSchemeID | Table | LEFT JOIN by FundingID + CID + FundingTypeID=1 - returns SchemeID, IsThreeDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from recurring payment service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get recurring data for a credit card funding

```sql
EXEC Billing.GetFundingRecurringData
    @FundingId = 123456,
    @Cid = 1234567;
-- Returns: FundingID, FundingTypeID=1, FundingData XML, SchemeID, IsThreeDs
```

### 8.2 Direct equivalent query

```sql
SELECT F.FundingID, F.FundingTypeID, F.FundingData,
       ccsi.SchemeID, ccsi.IsThreeDs
FROM Billing.Funding F WITH (NOLOCK)
LEFT JOIN Billing.CreditCardSchemeID ccsi WITH (NOLOCK)
    ON F.FundingID = ccsi.FundingID AND ccsi.CID = 1234567 AND F.FundingTypeID = 1
WHERE F.FundingID = 123456;
```

### 8.3 Check how many credit card fundings have 3DS enabled for a customer

```sql
SELECT COUNT(*) AS ThreeDsEnabled
FROM Billing.CreditCardSchemeID WITH (NOLOCK)
WHERE CID = 1234567 AND IsThreeDs = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingRecurringData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingRecurringData.sql*
