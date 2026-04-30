# Dictionary.StockHedgeSource

## 1. Business Meaning

**What it is**: A lookup table defining the origin/method by which a stock hedge operation was initiated. Tracks whether the hedge was executed manually by the dealing desk, automatically via the FAPI (Front API) system, or automatically using a closing rate calculation.

**Why it exists**: Stock (REAL asset) hedge operations can be triggered through different channels — manual dealing desk intervention, automated FAPI processing, or automated closing-rate-based execution. Tracking the source helps the dealing desk understand how hedges were created, supports audit trails, and enables analysis of manual vs. automated hedge ratios.

**How it works**: The `History.StocksHedge` table records every stock hedge operation with a `StockHedgeSourceID` from this table. This allows reporting on hedge source distribution, identifying manual interventions, and tracking the automation rate of stock hedge execution.

---

## 2. Business Logic

### Hedge Sources
| ID | Name | Meaning |
|----|------|---------|
| 0 | Unknown | Unclassified hedge source |
| 1 | Manual | Dealing desk manually initiated the hedge operation |
| 2 | Auto FAPI | Hedge automatically triggered via the Front API trading system |
| 3 | Auto Closing Rate | Hedge automatically triggered using the calculated closing rate |

### Automation Spectrum
```
Manual (1) ← [Human intervention] → Auto FAPI (2) → Auto Closing Rate (3)
[Least automated]                                        [Most automated]
```

---

## 3. Data Overview

| StockHedgeSourceID | Name | Business Meaning |
|-------------------|------|------------------|
| 0 | Unknown | Source not tracked |
| 1 | Manual | Dealing desk manual hedge |
| 2 | Auto FAPI | Automated via Front API |
| 3 | Auto Closing Rate | Automated via closing rate |

*4 rows — complete stock hedge source enumeration*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **StockHedgeSourceID** | int | NOT NULL | — | Primary key. Hedge source: 0=Unknown, 1=Manual, 2=Auto FAPI, 3=Auto Closing Rate. | `MCP` |
| **Name** | varchar(50) | NOT NULL | — | Human-readable hedge source label for dealing desk reports and audit trails. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| History.StocksHedge | StockHedgeSourceID | Implicit FK | Each stock hedge operation records its initiation source |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `History.StocksHedge` — stock hedge operation history

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `StockHedgeSourceID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Row Count | 4 |

---

## 8. Sample Queries

```sql
-- Get all hedge sources
SELECT  StockHedgeSourceID, Name
FROM    Dictionary.StockHedgeSource WITH (NOLOCK)
ORDER BY StockHedgeSourceID;

-- Hedge operations by source
SELECT  SHS.Name AS HedgeSource, COUNT(*) AS HedgeCount
FROM    History.StocksHedge SH WITH (NOLOCK)
JOIN    Dictionary.StockHedgeSource SHS WITH (NOLOCK) ON SHS.StockHedgeSourceID = SH.StockHedgeSourceID
GROUP BY SHS.Name
ORDER BY HedgeCount DESC;

-- Manual hedge operations (for audit)
SELECT  SH.HedgeOperationID, SH.InstrumentID, SH.StartHedge, SH.EndHedge,
        SH.Ask, SH.Bid
FROM    History.StocksHedge SH WITH (NOLOCK)
WHERE   SH.StockHedgeSourceID = 1
ORDER BY SH.StartHedge DESC;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Stock hedge source tracking is a dealing desk operational feature for REAL asset hedge management.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.0 — MCP verified (4 rows), codebase traced (1 consumer: History.StocksHedge)*
