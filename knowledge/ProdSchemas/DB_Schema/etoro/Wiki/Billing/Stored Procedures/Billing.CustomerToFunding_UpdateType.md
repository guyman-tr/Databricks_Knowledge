# Billing.CustomerToFunding_UpdateType

> Updates `DepositTypeID` and `ReasonID` on a customer-funding link; archives prior state to `History.ActiveCustomerToFunding` via OUTPUT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (composite PK) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFunding_UpdateType` reclassifies the deposit type and reason for a customer-funding link without changing any other attributes (status, dates, block flags). It is used when a payment instrument's classification needs to change - for example, when a regular deposit instrument is upgraded to instant, or when the reason for the link is corrected.

Created December 2016 by Geri Reshef (ticket 41987). IsVerified added to history OUTPUT in January 2023 (PAYIL-5743, Shay Oren).

---

## 2. Business Logic

### 2.1 Type/Reason Reclassification

**What**: Updates only `DepositTypeID` and `ReasonID`; all other columns unchanged.

**Rules**:
- `SET DepositTypeID=@DepositTypeID, ReasonID=@ReasonID`
- No NULL-preservation - both columns are always overwritten
- `OUTPUT DELETED.*` -> `History.ActiveCustomerToFunding` archives pre-update state
- `LastUsedDate`, `CustomerFundingStatusID`, block fields: unchanged

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID of the link to update. |
| 2 | @FundingID | INT | NO | - | VERIFIED | Payment instrument ID of the link to update. |
| 3 | @DepositTypeID | INT | NO | - | CODE-BACKED | New deposit type. FK to Billing.DepositType. Values: 1=Regular, 2=Instant, 3=RecurringDeposit. |
| 4 | @ReasonID | INT | NO | - | CODE-BACKED | New reason code. FK to Billing.Reason. Values: 6=ByUser. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CustomerToFunding | Write (UPDATE) | Type/reason reclassification |
| OUTPUT DELETED | History.ActiveCustomerToFunding | Write | Archives prior state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment classification service | All params | Caller | Changes deposit type or reason for a payment instrument |

---

## 6. Dependencies

```
Billing.CustomerToFunding_UpdateType (procedure)
+-- Billing.CustomerToFunding (table) [UPDATE target]
+-- History.ActiveCustomerToFunding (table) [OUTPUT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE target |
| History.ActiveCustomerToFunding | Table | History OUTPUT |

---

## 7. Technical Details

**Scope**: Narrowest update in the family - only DepositTypeID and ReasonID. Use `CustomerToFunding_UpdateRecord` for a combined type+reason+status update in one transaction.

---

## 8. Sample Queries

```sql
EXEC Billing.CustomerToFunding_UpdateType
    @CID = 24186018,
    @FundingID = 12345,
    @DepositTypeID = 2,   -- Instant
    @ReasonID = 6         -- ByUser
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFunding_UpdateType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFunding_UpdateType.sql*
