# Customer.GetDemoCustomersShortVersionForMail

> Email marketing data slice for demo customers: 7 columns combining GCID, masked CID (DemoCID pattern), first name, email, language name, label ID, and label name - used by bulk email systems to send campaigns to demo account holders.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetDemoCustomersShortVersionForMail provides the minimal dataset needed by email marketing systems (historically StrongMail, SilverPop) to send bulk emails to demo customers. It joins Customer.Customer with Dictionary.Label and Dictionary.Language to resolve the label and language names, and formats the output columns with QUOTENAME(..., '"') for direct use in email template systems that expect double-quoted CSV-style values.

The view uses a GCID-first identity model. The `CID` column is always 0 (not the real CID). The `DemoCID` column holds the actual CID only when the customer has no GCID (`CASE WHEN GCID <> 0 THEN 0 ELSE CID END`). This pattern separates "GCID-identified customers" (modern accounts with cross-product identity) from "CID-only customers" (older accounts without GCID), allowing the email system to route by GCID for modern customers and by CID for legacy ones.

The view does NOT filter on IsReal or PlayerStatusID - it returns all customers. The "Demo" in the name refers to the routing model (CID=0, DemoCID=CID when no GCID), not to IsReal=0 filtering. Compare with GetRealCustomersShortVersionForMail which uses the opposite CID/DemoCID logic.

---

## 2. Business Logic

### 2.1 GCID-vs-CID Identity Routing for Email

**What**: The view implements a dual-identity routing pattern that separates GCID-linked customers from CID-only customers.

**Columns/Parameters Involved**: `GCID`, `CID`, `DemoCID`

**Rules**:
- CID column: always 0 (demo pattern - email system should use GCID or DemoCID, not CID directly)
- DemoCID: `CASE WHEN CCST.GCID <> 0 THEN 0 ELSE CCST.CID END` -> DemoCID=CID when GCID=0 (no GCID); DemoCID=0 when GCID exists
- GCID: always the actual GCID (0 if none exists)
- Email system logic: if GCID != 0, use GCID for routing; if GCID=0, use DemoCID for routing; CID is always 0

**Contrast with GetRealCustomersShortVersionForMail**:
- Real: `CID = CASE WHEN GCID <> 0 THEN 0 ELSE CID END`, DemoCID=0 (CID is 0 for GCID customers, actual CID for no-GCID)
- Demo: `CID=0` (always), `DemoCID = CASE WHEN GCID <> 0 THEN 0 ELSE CID END`

---

## 3. Data Overview

N/A for view - data comes from Customer.Customer. The view returns one row per customer (all customers, unfiltered on IsReal or status).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID. From Customer.Customer. Primary routing key for modern GCID-linked customers. 0 for legacy customers without GCID. |
| 2 | CID | int | NO | - | VERIFIED | Always 0 (literal constant). Email marketing systems should use GCID or DemoCID for customer identification, not this column. |
| 3 | DemoCID | int | NO | - | VERIFIED | Actual CID when customer has no GCID (GCID=0), otherwise 0. Used to route emails for legacy accounts that predate the GCID system. |
| 4 | FirstName | nvarchar | YES | - | VERIFIED | Customer's first name wrapped in double-quotes via QUOTENAME(ltrim(rtrim(FirstName)),'"'). Ready for direct use in email template merge fields. NULL when customer has no first name. |
| 5 | Email | varchar | YES | - | VERIFIED | Customer's email wrapped in double-quotes via QUOTENAME(ltrim(rtrim(Email)),'"'). Trimmed and quoted for safe email system injection. |
| 6 | Language | nvarchar | YES | - | VERIFIED | Language name (e.g., "English", "German") from Dictionary.Language.Name, wrapped in double-quotes. Used by email system to select the correct template language variant. |
| 7 | LabelID | int | NO | - | VERIFIED | Internal segment label ID. From Customer.Customer. FK to Dictionary.Label. Used by email system for segment-based campaign targeting. |
| 8 | LabelName | nvarchar | YES | - | VERIFIED | Label name from Dictionary.Label.Name, wrapped in double-quotes. Human-readable segment name for email campaign configuration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.Customer | FROM (NOLOCK) | Customer identity, GCID, CID, FirstName, Email, LanguageID, LabelID |
| LabelID | Dictionary.Label | INNER JOIN on LabelID | Resolves LabelID to LabelName |
| LanguageID | Dictionary.Language | INNER JOIN on LanguageID | Resolves LanguageID to Language name |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetDemoCustomersShortVersionForMail (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
├── Dictionary.Label (table)
└── Dictionary.Language (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM NOLOCK - customer identity and classification |
| Dictionary.Label | Table | INNER JOIN on LabelID - label name resolution |
| Dictionary.Language | Table | INNER JOIN on LanguageID - language name resolution |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None. No SCHEMABINDING declared.

---

## 8. Sample Queries

### 8.1 Get email campaign data for a specific customer
```sql
SELECT GCID, CID, DemoCID, FirstName, Email, [Language], LabelID, LabelName
FROM Customer.GetDemoCustomersShortVersionForMail WITH (NOLOCK)
WHERE GCID = 12345678;
```

### 8.2 Get email list for a specific label (segment)
```sql
SELECT GCID, DemoCID, FirstName, Email, [Language]
FROM Customer.GetDemoCustomersShortVersionForMail WITH (NOLOCK)
WHERE LabelID = 26
ORDER BY GCID;
```

### 8.3 Compare Demo vs Real version CID routing pattern
```sql
-- Demo: CID always 0, DemoCID = CID when no GCID
SELECT TOP 5 GCID, CID, DemoCID, FirstName, Email
FROM Customer.GetDemoCustomersShortVersionForMail WITH (NOLOCK)
UNION ALL
-- Real: CID = actual CID when no GCID, DemoCID always 0
SELECT TOP 5 GCID, CID, DemoCID, FirstName, Email
FROM Customer.GetRealCustomersShortVersionForMail WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetDemoCustomersShortVersionForMail | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetDemoCustomersShortVersionForMail.sql*
