# Dictionary.SettlementRestrictions

## 1. Business Meaning

**What it is**: A lookup table defining CopyTrading settlement restriction levels that control whether customers can open REAL (physical stock) and/or CFD positions through CopyTrading. Restrictions are applied by country and regulation to comply with local financial regulations.

**Why it exists**: Different regulatory jurisdictions have different rules about which settlement types are permitted for retail investors. Some countries allow both REAL stock and CFD trading, while others restrict one or both. This table provides the restriction vocabulary used by `Trade.CopyTradeSettlementRestrictions` to enforce these rules per country/regulation/instrument.

**How it works**: The `Trade.CopyTradeSettlementRestrictions` table stores restriction rules keyed by CountryID, RegulationID, InstrumentID, and ExchangeID, with a `RestrictionTypeID` from this table. The `dbo.SSRS_SmartCopyRestrictions` report joins this table to display the human-readable restriction name. When a user initiates a CopyTrading operation, the system checks whether their country/regulation combination has restrictions on the requested settlement type.

---

## 2. Business Logic

### Restriction Levels
| ID | Name | Meaning |
|----|------|---------|
| 0 | REAL and CFD allowed | No restrictions — customer can copy both settlement types |
| 1 | Restricted for REAL | Cannot copy REAL (physical stock) positions — CFD only |
| 2 | Restricted for CFD | Cannot copy CFD positions — REAL only |
| 3 | Restricted for REAL and CFD | Fully restricted — cannot copy any positions |

### Bitwise Pattern
The restriction IDs follow a bitwise pattern: bit 0 = REAL restriction, bit 1 = CFD restriction. This enables efficient bitwise checks in code.

---

## 3. Data Overview

| RestrictionTypeID | Name | Business Meaning |
|-------------------|------|------------------|
| 0 | REAL and CFD allowed | Full CopyTrading access |
| 1 | Restricted for REAL | CFD-only CopyTrading |
| 2 | Restricted for CFD | REAL-only CopyTrading |
| 3 | Restricted for REAL and CFD | CopyTrading blocked entirely |

*4 rows — complete settlement restriction enumeration*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **RestrictionTypeID** | tinyint | NOT NULL | — | Primary key. Restriction level: 0=both allowed, 1=REAL restricted, 2=CFD restricted, 3=both restricted. Follows bitwise pattern (bit 0=REAL, bit 1=CFD). | `MCP` |
| **Name** | varchar(100) | NULL | — | Human-readable restriction description displayed in SmartCopy restriction reports and BackOffice admin views. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| Trade.CopyTradeSettlementRestrictions | RestrictionTypeID | Implicit FK | Per-country/regulation/instrument settlement restrictions |
| dbo.SSRS_SmartCopyRestrictions | RestrictionTypeID | JOIN | SSRS report displaying CopyTrading settlement restrictions |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Trade.CopyTradeSettlementRestrictions` — restriction rule store
- `dbo.SSRS_SmartCopyRestrictions` — restriction reporting

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `RestrictionTypeID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Fill Factor | 95% |
| Row Count | 4 |

---

## 8. Sample Queries

```sql
-- Get all settlement restrictions
SELECT  RestrictionTypeID, Name
FROM    Dictionary.SettlementRestrictions WITH (NOLOCK)
ORDER BY RestrictionTypeID;

-- Count CopyTrading restrictions by type
SELECT  SR.Name, COUNT(*) AS RuleCount
FROM    Trade.CopyTradeSettlementRestrictions CSR WITH (NOLOCK)
JOIN    Dictionary.SettlementRestrictions SR WITH (NOLOCK) ON SR.RestrictionTypeID = CSR.RestrictionTypeID
GROUP BY SR.Name;

-- Find countries restricted for REAL stock CopyTrading
SELECT  DISTINCT C.Name AS Country
FROM    Trade.CopyTradeSettlementRestrictions CSR WITH (NOLOCK)
JOIN    Dictionary.Country C WITH (NOLOCK) ON C.CountryID = CSR.CountryID
WHERE   CSR.RestrictionTypeID IN (1, 3);
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. CopyTrading settlement restrictions are a regulatory compliance feature controlled through the BackOffice SmartCopy configuration.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (4 rows), codebase traced (Trade.CopyTradeSettlementRestrictions + SSRS report), bitwise pattern documented*
