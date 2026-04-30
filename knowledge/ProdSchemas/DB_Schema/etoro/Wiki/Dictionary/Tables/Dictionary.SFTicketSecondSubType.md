# Dictionary.SFTicketSecondSubType

## 1. Business Meaning

**What it is**: A lookup table defining second-level sub-type classifications for Salesforce support tickets. Provides granular categorization beneath the primary ticket sub-type for customer service workflows.

**Why it exists**: eToro's customer service team uses Salesforce for ticket management. Tickets are classified hierarchically: Type → SubType → SecondSubType. This table provides the most granular level, allowing specific issue identification (e.g., "Denied PayPal" under the "Denied" payment sub-type, or "Negative Balance" under a general category).

**How it works**: Each second sub-type belongs to a parent `SFTicketSubTypeID` and has an `IsInDisplay` flag controlling visibility in the support agent UI. Entries with `IsInDisplay = 1` appear in dropdown menus; NULL/false entries are hidden (likely deprecated or internal-only classifications).

---

## 2. Business Logic

### Category Groups (by SFTicketSubTypeID)
**SubTypeID 11 — Account Issues**:
- Active Client, Account Liquidation

**SubTypeID 15 — Financial Operations**:
- Double Payment/Overpayment, Logins, Returned CO, Trading Strategy, Negative Balance

**SubTypeID 19 — Payment Verification Issues**:
- 3rd party MOP provided, Invalid wire details, Proof of e-wallet ownership, Restricted bank, Wire Country mismatch, Payment query, Wrong Online Banking details

**SubTypeID 24 — Denied Withdrawals (by payment method)**:
- Denied ACH, CUP, NETELLER, Online Banking, PayPal, PWMB, Skrill, WebMoney, Wire, Trustly, P24, iDeal, Unclaimed PayPal

### Display Control
~20 of 27 entries are visible (`IsInDisplay = 1`). Hidden entries (NULL) represent deprecated payment methods or internal-only categories.

---

## 3. Data Overview

| ID | Name | SubTypeID | IsInDisplay | Business Meaning |
|----|------|-----------|-------------|------------------|
| 1 | Double Payment/Overpayment | 15 | Yes | Duplicate deposit investigation |
| 6 | 3d party MOP provided | 19 | Yes | Third-party payment method flagged |
| 18 | Denied PayPal | 24 | Yes | PayPal withdrawal denied |
| 26 | Negative Balance | 15 | Yes | Account negative balance issue |
| 31 | Account Liquidation | 11 | Yes | Account liquidation ticket |

*27 rows — Salesforce ticket granular classifications*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **SFTicketSecondSubTypeID** | int | NOT NULL | — | Primary key. Second sub-type identifier. Range: 1-31 (with gaps at 3, 7, 11, 13). | `MCP` |
| **Name** | varchar(255) | NOT NULL | — | Human-readable description of the ticket second sub-type. Displayed in Salesforce ticket classification dropdowns. | `MCP` |
| **SFTicketSubTypeID** | int | NOT NULL | — | Parent sub-type ID grouping related second sub-types. Values observed: 11 (Account), 15 (Financial), 19 (Payment Verification), 24 (Denied Withdrawal). | `MCP` |
| **IsInDisplay** | bit | NULL | — | Visibility flag for support agent UI. 1 = shown in dropdown, NULL = hidden (deprecated or internal). ~20 of 27 are visible. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
| Referenced Table | FK Column | Relationship | Business Meaning |
|-----------------|-----------|--------------|------------------|
| (SFTicketSubType) | SFTicketSubTypeID | Implicit FK (no DDL constraint) | Parent ticket sub-type classification |

### Referenced By (other objects point to this table)
*No direct SQL consumers found in SSDT — consumed primarily by Salesforce integration layer.*

---

## 6. Dependencies

### Depends On
- Salesforce ticket sub-type hierarchy (implicit)

### Depended On By
- Salesforce integration layer (application-level consumer)

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `SFTicketSecondSubTypeID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None (no DDL constraint to parent) |
| Constraints | None |
| Filegroup | DICTIONARY |
| Row Count | 27 |

---

## 8. Sample Queries

```sql
-- Get all visible second sub-types
SELECT  SFTicketSecondSubTypeID, Name, SFTicketSubTypeID
FROM    Dictionary.SFTicketSecondSubType WITH (NOLOCK)
WHERE   IsInDisplay = 1
ORDER BY SFTicketSubTypeID, Name;

-- Count entries by parent sub-type
SELECT  SFTicketSubTypeID, COUNT(*) AS SubTypeCount,
        SUM(CASE WHEN IsInDisplay = 1 THEN 1 ELSE 0 END) AS VisibleCount
FROM    Dictionary.SFTicketSecondSubType WITH (NOLOCK)
GROUP BY SFTicketSubTypeID;

-- Find all denied withdrawal sub-types
SELECT  SFTicketSecondSubTypeID, Name, IsInDisplay
FROM    Dictionary.SFTicketSecondSubType WITH (NOLOCK)
WHERE   SFTicketSubTypeID = 24
ORDER BY Name;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Salesforce ticket classifications are managed through the CRM integration layer.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.0 — MCP verified (27 rows), parent grouping analyzed, display visibility mapped*
