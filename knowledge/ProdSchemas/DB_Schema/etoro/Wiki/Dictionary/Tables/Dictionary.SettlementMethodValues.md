# Dictionary.SettlementMethodValues

## 1. Business Meaning

**What it is**: A lookup table defining the settlement method for futures contracts. Determines whether a futures position is settled by cash payment or physical delivery of the underlying asset at expiration.

**Why it exists**: Futures contracts can settle in two fundamentally different ways: cash settlement (the standard for index futures and most retail trading) or physical delivery (where the actual commodity or asset changes hands). This table provides the classification used when onboarding new futures instruments.

**How it works**: During instrument onboarding via `Trade.CheckValidInstruments`, the `@SettlementMethod` parameter is validated against this table. If the instrument is a future (`@IsFuture = 1`) and the settlement method value doesn't exist in this table, the procedure throws an error and rejects the instrument. Valid settlement methods are stored in `Trade.FuturesMetaData`.

---

## 2. Business Logic

### Settlement Methods
| ID | Value | Meaning |
|----|-------|---------|
| 0 | Cash | Cash settlement — P&L settled in currency at expiration. Standard for CFD futures, index futures. |
| 1 | Physical | Physical delivery — underlying asset delivered at expiration. Rare in retail trading context. |

### Validation Rule
Only futures instruments (`IsFuture = 1`) require a settlement method. For non-futures instruments, this field is not applicable.

---

## 3. Data Overview

| ID | Value | Business Meaning |
|----|-------|------------------|
| 0 | Cash | Cash-settled futures (P&L in currency) |
| 1 | Physical | Physically-delivered futures |

*2 rows — binary settlement method classification*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **ID** | tinyint | NOT NULL | — | Primary key. Settlement method: 0=Cash, 1=Physical. | `MCP` |
| **Value** | varchar(50) | NOT NULL | — | Human-readable settlement method label. Used in validation error messages and instrument configuration. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | Column | Relationship | Business Meaning |
|-------------------|--------|--------------|------------------|
| Trade.CheckValidInstruments | @SettlementMethod | Validation EXISTS check | Validates futures settlement method during instrument onboarding |
| Trade.FuturesMetaData | SettlementMethod | Implicit FK | Stores the settlement method per futures instrument |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Trade.CheckValidInstruments` — futures instrument validation
- `Trade.FuturesMetaData` — futures configuration store

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `ID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | DICTIONARY |
| Row Count | 2 |

---

## 8. Sample Queries

```sql
-- Get all settlement methods
SELECT  ID, Value
FROM    Dictionary.SettlementMethodValues WITH (NOLOCK)
ORDER BY ID;

-- Check which futures use physical delivery
SELECT  FM.InstrumentID, C.Name AS InstrumentName, SM.Value AS SettlementMethod
FROM    Trade.FuturesMetaData FM WITH (NOLOCK)
JOIN    Dictionary.Currency C WITH (NOLOCK) ON C.CurrencyID = FM.InstrumentID
JOIN    Dictionary.SettlementMethodValues SM WITH (NOLOCK) ON SM.ID = FM.SettlementMethod
WHERE   FM.SettlementMethod = 1;

-- Validate a settlement method value
SELECT  CASE WHEN EXISTS (SELECT 1 FROM Dictionary.SettlementMethodValues WHERE ID = 0)
             THEN 'Valid' ELSE 'Invalid' END AS ValidationResult;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Settlement method classification is a standard futures trading concept.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (2 rows), codebase traced (Trade.CheckValidInstruments validation logic extracted)*
