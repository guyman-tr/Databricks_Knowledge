# Billing.WithdrawToFundingUpdateWithDrawData

> Directly sets the WithdrawData XML field on a WithdrawToFunding leg by ID; no validation, no history, no return value.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID INT - the Billing.WithdrawToFunding.ID to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure overwrites the `WithdrawData` XML field on a WithdrawToFunding leg. `WithdrawData` carries provider-specific payment enrichment data in XML format - it may contain bank account details, routing metadata, provider references, or other structured payment data required by the downstream processor.

The procedure is the simplest possible update wrapper: a single UPDATE with no guards, no history, and no return value. It is appropriate for cases where the XML data needs to be refreshed (e.g., enriched with additional fields from a provider response, or corrected after initial creation) without requiring a full re-processing cycle.

Unlike `WithdrawToFundingUpdate` (which also writes `WithdrawData` alongside other fields and logs history), this procedure isolates the XML update to a targeted, lightweight call.

---

## 2. Business Logic

### 2.1 Direct WithdrawData XML Update

**What**: Replaces the XML payment data on the WTF leg.

**Rules**:
- `UPDATE Billing.WithdrawToFunding SET WithdrawData=@WithdrawData WHERE ID=@ID`
- No existence check, status guard, or history
- No return value, no @@ROWCOUNT (unlike SP #18 and #19 which return row count)
- NULL is a valid value - clears the WithdrawData

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID`. No existence validation; silent no-op if not found. |
| 2 | @WithdrawData | xml | YES | - | CODE-BACKED | Input parameter. XML document with provider-specific payment routing or enrichment data. Replaces any existing value. NULL clears the field. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE) | Billing.WithdrawToFunding | Write | Direct UPDATE of WithdrawData field |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code.

---

## 6. Dependencies

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Direct UPDATE target for WithdrawData (xml) |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by application code.

---

## 7. Technical Details

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the update

```sql
EXEC Billing.WithdrawToFundingUpdateWithDrawData
    @ID          = 12345,
    @WithdrawData = N'<PaymentData><BankRef>REF-XYZ</BankRef><IBAN>DE89...</IBAN></PaymentData>';
```

### 8.2 Clear the data

```sql
EXEC Billing.WithdrawToFundingUpdateWithDrawData
    @ID          = 12345,
    @WithdrawData = NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 7.8/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingUpdateWithDrawData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingUpdateWithDrawData.sql*
