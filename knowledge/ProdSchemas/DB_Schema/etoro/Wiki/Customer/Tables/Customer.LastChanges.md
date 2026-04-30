# Customer.LastChanges

> Single-column audit table tracking the most recent email change date per customer, populated automatically by the Customer.CustomerStatic UPDATE trigger whenever a customer's email address is modified.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK) |
| **Partition** | No (MAIN filegroup, PAGE compression) |
| **Indexes** | 1 (clustered PK, fillfactor=95, PAGE compression) |

---

## 1. Business Meaning

Customer.LastChanges tracks the last time a customer's email address was changed. It is the output of the Customer.CustomerVersionUpdate trigger on Customer.CustomerStatic: whenever the Email column changes for any customer, the trigger performs a MERGE into this table - inserting a new row if the customer has no prior email change record, or updating EmailLastChangeDate if they do.

12,106 rows, with the most recent changes recorded today (2026-03-17), confirming this is actively maintained. This table represents a small subset of the 18.7M customers - only those who have changed their email at least once since this tracking was introduced.

The primary use case is compliance and fraud: knowing when a customer last changed their email enables detection of suspicious patterns (e.g., email change immediately before a large withdrawal), audit trail for customer disputes ("when did they change their email?"), and regulatory reporting.

The table name "LastChanges" (plural) suggests it was designed to eventually track changes to multiple fields, but currently only EmailLastChangeDate is stored.

---

## 2. Business Logic

### 2.1 Trigger-Driven MERGE Upsert

**What**: The CustomerVersionUpdate trigger on Customer.CustomerStatic performs a MERGE into this table when Email changes.

**Columns/Parameters Involved**: `CID`, `EmailLastChangeDate`

**Rules**:
- Trigger fires on any UPDATE to Customer.CustomerStatic
- MERGE condition: IF UPDATE(Email) AND old.Email != new.Email
- WHEN MATCHED (CID exists in LastChanges): UPDATE EmailLastChangeDate = GETUTCDATE()
- WHEN NOT MATCHED BY TARGET: INSERT (CID, EmailLastChangeDate)
- Timestamp is always UTC (GETUTCDATE())
- Only the most recent change is stored per CID - no history of all email changes; for full history see History.Customer

---

## 3. Data Overview

| CID | EmailLastChangeDate | Meaning |
|---|---|---|
| 25463678 | 2026-03-17 11:10 UTC | Recent email change - active customer |
| 25463261 | 2026-03-17 10:08 UTC | Same-day email change |
| 25462119 | 2026-03-17 06:05 UTC | Early morning email change today |

*12,106 total rows. Active daily writes (3+ changes today alone). Covers only ~0.06% of the 18.7M customer base.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID - primary key. One row per customer who has changed their email at least once. |
| 2 | EmailLastChangeDate | datetime | YES | - | VERIFIED | UTC timestamp of the most recent email address change for this customer. Nullable (in case of partial writes). Set by Customer.CustomerVersionUpdate trigger via GETUTCDATE(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer whose email was changed; no FK constraint |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerVersionUpdate (trigger) | CID | MERGE WRITER | Automatically populated on Customer.CustomerStatic UPDATE when Email changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.LastChanges
  <- populated by Customer.CustomerVersionUpdate trigger on Customer.CustomerStatic
```

### 6.1 Objects This Depends On

No FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerVersionUpdate | Trigger | MERGE upsert writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerLastChanges | CLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerLastChanges | PRIMARY KEY | CID must be unique - one row per customer (PAGE compression, MAIN filegroup) |

---

## 8. Sample Queries

### 8.1 Get email change history for a customer

```sql
SELECT CID, EmailLastChangeDate
FROM Customer.LastChanges WITH (NOLOCK)
WHERE CID = 25463678
```

### 8.2 Find customers who changed email recently

```sql
SELECT CID, EmailLastChangeDate
FROM Customer.LastChanges WITH (NOLOCK)
WHERE EmailLastChangeDate >= DATEADD(day, -7, GETUTCDATE())
ORDER BY EmailLastChangeDate DESC
```

### 8.3 Count customers who have ever changed their email

```sql
SELECT COUNT(*) AS CustomersWithEmailChange
FROM Customer.LastChanges WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | Triggers: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.LastChanges | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.LastChanges.sql*
