# Billing.DeleteDefaultAmount

> Removes a deposit UI default amount configuration entry for a specific payment method and currency combination from Billing.FundingTypeDefaultAmount.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeID + @CurrencyID identify the row to delete |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DeleteDefaultAmount` removes a configuration entry from `Billing.FundingTypeDefaultAmount` for a given payment method type and account currency combination. When removed, the deposit form will no longer show a pre-filled default amount for that specific payment method / currency pair.

`Billing.FundingTypeDefaultAmount` stores the suggested deposit amounts shown in the eToro deposit UI (e.g., 1000 GBP pre-filled for credit card deposits from a GBP account). This procedure is the administrative delete operation for that configuration table, used when a default amount is no longer needed - for example, when a payment method is deprecated for a specific currency, or when the configuration is being refreshed.

The procedure performs a direct DELETE with no prior validation (no check if the row exists). If the row doesn't exist, the DELETE silently affects 0 rows.

---

## 2. Business Logic

### 2.1 Configuration Entry Deletion

**What**: Direct DELETE on the unique natural key (FundingTypeID, CurrencyID) of the configuration table.

**Columns/Parameters Involved**: `@FundingTypeID`, `@CurrencyID`

**Rules**:
- No validation - if the row doesn't exist, 0 rows are deleted without error
- No audit trail - configuration changes are not tracked in a history table for this table
- Paired with `Billing.AddFundingTypeDefaultAmount` (insert) for configuration management

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type whose default amount configuration is being removed. Matches FundingTypeID in Billing.FundingTypeDefaultAmount and Dictionary.FundingType (e.g., 1=Credit Card, 29=ACH). |
| 2 | @CurrencyID | INT | NO | - | CODE-BACKED | Account currency whose default deposit amount for this payment method is being removed. Matches CurrencyID in Billing.FundingTypeDefaultAmount and Dictionary.Currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID + @CurrencyID | Billing.FundingTypeDefaultAmount | Delete | Removes the matching row from the deposit UI default amount configuration table. See [Billing.FundingTypeDefaultAmount](../Tables/Billing.FundingTypeDefaultAmount.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used by payment configuration admin tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DeleteDefaultAmount (procedure)
└── Billing.FundingTypeDefaultAmount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDefaultAmount | Table | DELETE target - removes the row matching the FundingTypeID + CurrencyID natural key |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment configuration admin | External | Calls this procedure to remove obsolete or incorrect deposit default amount settings |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Remove the ACH default amount for USD accounts

```sql
EXEC Billing.DeleteDefaultAmount
    @FundingTypeID = 29,  -- ACH
    @CurrencyID = 1;      -- USD
```

### 8.2 Check current default amounts before deleting

```sql
SELECT fda.ID,
       fda.FundingTypeID,
       fda.CurrencyID,
       fda.Amount,
       ft.Name AS FundingTypeName,
       c.Abbreviation AS CurrencyCode
FROM Billing.FundingTypeDefaultAmount fda WITH (NOLOCK)
    JOIN Dictionary.FundingType ft WITH (NOLOCK)
        ON fda.FundingTypeID = ft.FundingTypeID
    JOIN Dictionary.Currency c WITH (NOLOCK)
        ON fda.CurrencyID = c.CurrencyID
WHERE fda.FundingTypeID = 29;
```

### 8.3 Delete all default amounts for a deprecated payment method

```sql
-- Note: procedure only deletes one FundingTypeID+CurrencyID combination at a time
-- To remove all configurations for a payment method, call once per currency
EXEC Billing.DeleteDefaultAmount @FundingTypeID = 99, @CurrencyID = 1;  -- USD
EXEC Billing.DeleteDefaultAmount @FundingTypeID = 99, @CurrencyID = 2;  -- EUR
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DeleteDefaultAmount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DeleteDefaultAmount.sql*
