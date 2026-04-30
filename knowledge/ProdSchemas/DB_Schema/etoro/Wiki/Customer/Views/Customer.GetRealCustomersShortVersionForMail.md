# Customer.GetRealCustomersShortVersionForMail

> Email marketing data slice for real customers: same 7-column structure as GetDemoCustomersShortVersionForMail but with the CID/DemoCID identity routing inverted - CID holds the actual CID for GCID-less customers, DemoCID is always 0.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRealCustomersShortVersionForMail is the "real customer" counterpart to GetDemoCustomersShortVersionForMail. It provides the same 7-column email marketing dataset (GCID, CID, DemoCID, FirstName, Email, Language, LabelID, LabelName) but with the CID/DemoCID columns inverted: `CID = CASE WHEN GCID <> 0 THEN 0 ELSE CID END` (CID holds the actual CID for legacy no-GCID accounts, 0 for GCID accounts) and `DemoCID = 0` (always zero).

The "Real" in the name refers to the identity routing model (CID-based for real/legacy accounts), not to filtering on IsReal=1 - the view does not filter by IsReal. Like its sibling, it joins Dictionary.Label and Dictionary.Language to resolve names, and uses QUOTENAME(ltrim(rtrim(...)), '"') for double-quoted output.

The two views together provide a complete, non-overlapping way for email systems to address all customers: GCID customers are addressed via GCID in both views; legacy CID-only customers are addressed via DemoCID in the Demo view or via CID in the Real view. Email systems typically consume both views together to build complete send lists.

---

## 2. Business Logic

### 2.1 Real Customer CID Routing Pattern

**What**: Inverse of GetDemoCustomersShortVersionForMail's identity routing.

**Columns/Parameters Involved**: `GCID`, `CID`, `DemoCID`

**Rules**:
- CID: `CASE WHEN CCST.GCID <> 0 THEN 0 ELSE CCST.CID END` -> CID=actual CID when customer has no GCID; CID=0 when GCID exists
- DemoCID: always 0 (literal constant)
- GCID: actual GCID (0 if none)
- Contrast with GetDemoCustomersShortVersionForMail: CID is always 0 there; DemoCID=CID for GCID-less customers
- The two views together provide non-overlapping customer addressing: legacy customers get CID or DemoCID depending on context

---

## 3. Data Overview

N/A for view. Same rows as Customer.Customer; same 7 columns as GetDemoCustomersShortVersionForMail with CID/DemoCID routing inverted.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID. From Customer.Customer. Primary routing key for GCID-linked customers. |
| 2 | CID | int | NO | - | VERIFIED | Actual CID for legacy customers without GCID (GCID=0); 0 for modern GCID-linked customers. Inverse of GetDemoCustomersShortVersionForMail.CID pattern. |
| 3 | DemoCID | int | NO | - | VERIFIED | Always 0. Real customer routing uses CID (not DemoCID). Contrast with GetDemoCustomersShortVersionForMail.DemoCID which holds the actual CID for GCID-less customers. |
| 4 | FirstName | nvarchar | YES | - | VERIFIED | Customer first name wrapped in double-quotes. QUOTENAME(ltrim(rtrim(FirstName)),'"'). |
| 5 | Email | varchar | YES | - | VERIFIED | Email wrapped in double-quotes. QUOTENAME(ltrim(rtrim(Email)),'"'). |
| 6 | Language | nvarchar | YES | - | VERIFIED | Language name from Dictionary.Language, wrapped in double-quotes. Email template language selection. |
| 7 | LabelID | int | NO | - | VERIFIED | Segment label ID. From Customer.Customer. |
| 8 | LabelName | nvarchar | YES | - | VERIFIED | Label name from Dictionary.Label, wrapped in double-quotes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.Customer | FROM (NOLOCK) | Customer identity, GCID, CID, FirstName, Email, LanguageID, LabelID |
| LabelID | Dictionary.Label | INNER JOIN on LabelID | LabelName resolution |
| LanguageID | Dictionary.Language | INNER JOIN on LanguageID | Language name resolution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRealCustomersShortVersionForMail (view)
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
| Customer.Customer | View | FROM NOLOCK |
| Dictionary.Label | Table | INNER JOIN on LabelID |
| Dictionary.Language | Table | INNER JOIN on LanguageID |

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

### 8.1 Get email data for a real customer by GCID
```sql
SELECT GCID, CID, DemoCID, FirstName, Email, [Language], LabelID, LabelName
FROM Customer.GetRealCustomersShortVersionForMail WITH (NOLOCK)
WHERE GCID = 12345678;
```

### 8.2 Real customers without GCID (CID-based routing)
```sql
SELECT CID, DemoCID, FirstName, Email, [Language]
FROM Customer.GetRealCustomersShortVersionForMail WITH (NOLOCK)
WHERE GCID = 0 AND CID > 0
ORDER BY CID;
```

### 8.3 Combined send list (demo + real routing)
```sql
SELECT GCID, CID, DemoCID, FirstName, Email, LabelID, LabelName, 'Demo' AS Source
FROM Customer.GetDemoCustomersShortVersionForMail WITH (NOLOCK)
WHERE LabelID = 1
UNION ALL
SELECT GCID, CID, DemoCID, FirstName, Email, LabelID, LabelName, 'Real' AS Source
FROM Customer.GetRealCustomersShortVersionForMail WITH (NOLOCK)
WHERE LabelID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRealCustomersShortVersionForMail | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetRealCustomersShortVersionForMail.sql*
