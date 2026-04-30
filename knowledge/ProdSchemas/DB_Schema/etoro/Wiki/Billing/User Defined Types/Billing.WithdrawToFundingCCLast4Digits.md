# Billing.WithdrawToFundingCCLast4Digits

> Table-valued parameter type designed to carry credit card last-4-digits per WTF record; planned for use in `Billing.WithdrawToFundingProcess` but currently commented out and not actively used.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | ID (PRIMARY KEY CLUSTERED, IGNORE_DUP_KEY) |
| **Partition** | N/A |
| **Indexes** | 1 - PRIMARY KEY CLUSTERED on ID |

---

## 1. Business Meaning

`Billing.WithdrawToFundingCCLast4Digits` is a table-valued parameter (TVP) type designed to carry the last 4 digits of the credit card used in a WithdrawToFunding (WTF) operation. Each row links a WTF record ID to its associated credit card's last 4 digits, enabling reconciliation between withdrawal records and the specific card that received the payment.

This type was planned as a parameter for `Billing.WithdrawToFundingProcess` but the parameter is currently commented out in both `WithdrawToFundingProcess.sql` and `WithdrawToFundingProcess_v2.sql`:
```
--@CreditCardLast4 Varchar(4)=Null
--@WithdrawToFundingCCLast4DigitsTbl Billing.WithdrawToFundingCCLast4Digits Readonly
```

The type remains in the schema (not dropped), indicating it may be planned for future activation or is retained for backward compatibility with application code that may still reference it.

---

## 2. Business Logic

### 2.1 Credit Card Verification Association (Planned)

**What**: Links each WTF record to the last 4 digits of the credit card used for the withdrawal payment, intended for card verification and reconciliation.

**Columns/Parameters Involved**: `ID`, `CreditCardLast4`

**Rules**:
- `ID` references `Billing.WithdrawToFunding.ID` - the specific WTF payment leg
- `CreditCardLast4` is 4 characters (varchar(4)) - only the masked, safe portion of the card number
- PRIMARY KEY with IGNORE_DUP_KEY=OFF ensures one row per WTF record in the TVP
- Currently not used in any active stored procedure (both references are commented out)

**Diagram**:
```
PLANNED (commented out):
  WithdrawToFundingProcess(
    @WithdrawToFundingCCLast4DigitsTbl Billing.WithdrawToFundingCCLast4Digits READONLY
  )
  -> Would store CreditCardLast4 on WTF records for card-level reconciliation

CURRENT STATUS: Parameter commented out, type unused
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key referencing `Billing.WithdrawToFunding.ID` - the WTF record this card data belongs to. CLUSTERED PRIMARY KEY ensures one row per WTF record. IGNORE_DUP_KEY=OFF means duplicate inserts will raise an error. |
| 2 | CreditCardLast4 | varchar(4) | NO | - | CODE-BACKED | Last 4 digits of the credit card used for this WTF payment. Fixed width of 4 characters. PCI-safe masked card data (not the full PAN). Collation: Latin1_General_BIN (binary comparison - case-sensitive, exact match). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | Billing.WithdrawToFunding | Implicit | WTF record this credit card data belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawToFundingProcess | @WithdrawToFundingCCLast4DigitsTbl | TVP Parameter (COMMENTED OUT) | Parameter definition exists but is commented out - not currently active |
| Billing.WithdrawToFundingProcess_v2 | @WithdrawToFundingCCLast4DigitsTbl | TVP Parameter (COMMENTED OUT) | Same - parameter commented out in V2 as well |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFundingProcess | Stored Procedure | Parameter COMMENTED OUT - planned but not active |
| Billing.WithdrawToFundingProcess_v2 | Stored Procedure | Parameter COMMENTED OUT - planned but not active |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY CLUSTERED (ID) | PRIMARY KEY | One row per WTF record. IGNORE_DUP_KEY=OFF - duplicate ID inserts will error. |

---

## 8. Sample Queries

### 8.1 Inspect type column definitions

```sql
SELECT c.name, t.name AS type_name, c.max_length, c.is_nullable, c.is_identity
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name = 'WithdrawToFundingCCLast4Digits'
ORDER BY c.column_id
```

### 8.2 View WTF records for credit card withdrawals

```sql
SELECT TOP 20
    wtf.ID,
    wtf.WithdrawID,
    wtf.FundingID,
    w.FundingTypeID,
    wtf.CashoutStatusID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Billing.Withdraw w WITH (NOLOCK) ON w.WithdrawID = wtf.WithdrawID
WHERE w.FundingTypeID = 1  -- CreditCard
ORDER BY wtf.ModificationDate DESC
```

### 8.3 Check if type is referenced in any active object

```sql
SELECT
    OBJECT_NAME(sm.object_id) AS ObjectName,
    OBJECT_SCHEMA_NAME(sm.object_id) AS SchemaName,
    sm.definition
FROM sys.sql_modules sm WITH (NOLOCK)
WHERE sm.definition LIKE '%WithdrawToFundingCCLast4Digits%'
  AND OBJECTPROPERTY(sm.object_id, 'IsProcedure') = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingCCLast4Digits | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.WithdrawToFundingCCLast4Digits.sql*
