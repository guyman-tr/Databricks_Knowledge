# Billing.CustomerToFunding_Add

> Explicitly inserts a new customer-to-payment-instrument link into `Billing.CustomerToFunding` with caller-specified DepositTypeID and ReasonID; LastUsedDate is always set to GETUTCDATE().

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (composite PK of target table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFunding_Add` is the explicit INSERT writer for `Billing.CustomerToFunding`. It creates a new association between a customer and a payment instrument when the caller needs to specify the exact deposit type and reason code. This is used in flows where the payment method classification matters at link creation time (unlike `CustomerToFunding_Upsert`, which always defaults to DepositTypeID=1 and ReasonID=6).

Created December 2016 by Geri Reshef (ticket 41987, "DB Instant payment phase2"). The procedure does NOT write to `History.ActiveCustomerToFunding` - it relies on the table DEFAULT for `CustomerFundingStatusID` (1 = Active), meaning links created via this procedure start as Active by default.

---

## 2. Business Logic

### 2.1 Direct INSERT with Caller-Specified Classification

**What**: Inserts one row into `Billing.CustomerToFunding` with the caller's DepositTypeID and ReasonID.

**Rules**:
- `LastUsedDate = GetUTCDate()` - always the current UTC time; caller cannot supply a date
- `CustomerFundingStatusID` is NOT supplied -> uses table DEFAULT (1 = Active)
- No OUTPUT clause -> history NOT archived to `History.ActiveCustomerToFunding` on creation
- No duplicate check -> will fail with PK violation if (CID, FundingID) already exists

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID linking to this payment instrument. Composite PK component. References Customer.CustomerStatic. |
| 2 | @FundingID | INT | NO | - | VERIFIED | The payment instrument to link to this customer. Composite PK component. FK to Billing.Funding.FundingID. |
| 3 | @DepositTypeID | INT | NO | - | CODE-BACKED | Classification of this funding link. FK to Billing.DepositType. Common values: 1=Regular, 2=Instant, 3=RecurringDeposit. Written directly (no default). |
| 4 | @ReasonID | INT | NO | - | CODE-BACKED | Reason the link was created. FK to Billing.Reason. Common values: 6=ByUser, other values for system-created links. Written directly (no default). |

**Return value**: None.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CustomerToFunding | Write (INSERT) | Creates new customer-to-payment-instrument link |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment registration service | All params | Caller | Called when a customer adds a payment method requiring specific type/reason classification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CustomerToFunding_Add (procedure)
+-- Billing.CustomerToFunding (table) [INSERT target]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment registration flows | External | Explicit INSERT when DepositTypeID/ReasonID must be specified at creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**No history write**: Unlike all Update procedures in this family, `_Add` does NOT archive to `History.ActiveCustomerToFunding`. The initial INSERT state is not captured in history.

**Status defaults to Active (1)**: The table DEFAULT for `CustomerFundingStatusID` is 1 (Active). Contrast with `CustomerToFunding_Upsert` which explicitly passes `@CustomerFundingStatusID=0` (Deactivated) on INSERT.

---

## 8. Sample Queries

### 8.1 Add a payment instrument link for a customer

```sql
EXEC Billing.CustomerToFunding_Add
    @CID = 24186018,
    @FundingID = 12345,
    @DepositTypeID = 1,  -- Regular
    @ReasonID = 6        -- ByUser
```

### 8.2 Verify the link was created

```sql
SELECT CID, FundingID, DepositTypeID, ReasonID, CustomerFundingStatusID, LastUsedDate
FROM Billing.CustomerToFunding WITH(NOLOCK)
WHERE CID = 24186018 AND FundingID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFunding_Add | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFunding_Add.sql*
