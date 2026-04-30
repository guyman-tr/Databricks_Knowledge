# History.CEPListCIDMappings

> Trigger-based delete audit log for CEP.ListCIDMappings - records each customer's removal from a CEP named list, capturing the period (ValidFrom to ValidTo) during which they were a member.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CEPListCIDMappingsID - IDENTITY PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CEPListCIDMappings records the complete membership history of customers removed from CEP named lists. CEP (Complex Event Processing / Conditional Event Processing) is eToro's rules engine that classifies customers into named lists based on criteria like AUM thresholds or entity membership, then applies differentiated treatments (hedging behavior, rule-based actions) based on list membership.

The live table CEP.ListCIDMappings holds current memberships with PK (NamedListID, CID). When a customer is removed from a named list - either directly or via CEP.ArchiveListCIDMapping (which purges a list's members) - the DELETE trigger CEP.ListCidMappingsDelete fires and writes the membership window here:
- **ValidFrom**: when the customer was added to the named list (from the live row)
- **ValidTo**: when they were removed (GETUTCDATE() at delete time)

661 rows covering 2012-2024. Primarily NamedListID 13 ("Dinamic Guru List") with 609 entries, reflecting bulk archival of dynamic guru classification lists.

Note: CEP.ListCIDMappings also has SQL Server SYSTEM_VERSIONING enabled, with temporal history going to History.ListCIDMappings. This table (CEPListCIDMappings) is a SEPARATE, older trigger-based audit mechanism that predates the temporal versioning setup.

---

## 2. Business Logic

### 2.1 Named List Membership Archive

**What**: Records each customer's completed membership window in a CEP named list.

**Columns/Parameters Involved**: `NamedListID`, `CID`, `ValidFrom`, `ValidTo`

**Rules**:
- Written ONLY on DELETE from CEP.ListCIDMappings (trigger CEP.ListCidMappingsDelete)
- ValidFrom is copied from the live row (when customer was added to the list)
- ValidTo = GETUTCDATE() at deletion time
- CEP.ArchiveListCIDMapping previously inserted here directly (commented out as of Sept 2021 per code comment: "Removing the archive as we have temporal") - now only the trigger writes here
- The IDENTITY PK means no deduplication; same (NamedListID, CID) pair can appear multiple times across multiple archival events

### 2.2 Named List ID Reference (observed in data)

| NamedListID | Name | NamedListTypeID | Rows in History |
|-------------|------|----------------|-----------------|
| 1 | Large AUM | 2 (criteria-based) | 52 |
| 13 | Dinamic Guru List | 2 (criteria-based) | 609 |

NamedListID 3 ("eToro BVI", TypeID 1) has a special hedge trigger (TrCEPListCIDMappings_InsDel) that updates Customer.Customer.IsHedged on add/remove, but no rows in this history table.

### 2.3 Dual History Architecture

CEP.ListCIDMappings maintains two audit trails:
1. **Temporal (SYSTEM_VERSIONING)** -> History.ListCIDMappings: captures all changes (INSERT, UPDATE, DELETE) automatically
2. **Trigger-based** -> History.CEPListCIDMappings (this table): captures only DELETE events, with ValidFrom/ValidTo business semantics

---

## 3. Data Overview

| CEPListCIDMappingsID | NamedListID | CID | ValidFrom | ValidTo | Meaning |
|---------------------|------------|-----|-----------|---------|---------|
| 1006 | 1 | 2009343 | 2012-12-02 10:18 | 2024-11-06 11:24 | "Large AUM" customer removed Nov 2024, had been on list since Dec 2012 |
| (1-52 range) | 1 | (various) | 2012-12-02 | 2024-11-06 | Bulk archival of Large AUM list in Nov 2024 |
| (53-661 range) | 13 | (various) | (various) | (various) | Dinamic Guru List membership removals |

Total: 661 rows | Earliest: 2012-12-02 | Latest: 2024-11-06

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CEPListCIDMappingsID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | VERIFIED | Surrogate PK. Auto-incremented, not for replication. No business meaning - used only for row identity. |
| 2 | ValidFrom | datetime | NO | - | VERIFIED | UTC timestamp when the customer was added to the named list in CEP.ListCIDMappings. Copied from the live row at delete time via trigger. Represents the start of the membership window. |
| 3 | ValidTo | datetime | NO | - | VERIFIED | UTC timestamp when the customer was removed from the named list. Set to GETUTCDATE() by the trigger at the moment of deletion. Represents the end of the membership window. |
| 4 | NamedListID | int | NO | - | VERIFIED | ID of the CEP named list from which the customer was removed. FK to CEP.NamedLists. Known values: 1="Large AUM", 13="Dinamic Guru List". |
| 5 | CID | int | NO | - | VERIFIED | Customer ID removed from the named list. Implicit FK to Customer.CustomerStatic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NamedListID | CEP.NamedLists | Implicit | The named list the customer was a member of. |
| CID | Customer.CustomerStatic | Implicit | The customer whose list membership ended. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.ListCidMappingsDelete (trigger on CEP.ListCIDMappings) | NamedListID, CID | Writer | Sole active writer - fires on DELETE from CEP.ListCIDMappings. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEPListCIDMappings (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.ListCidMappingsDelete | Trigger (on CEP.ListCIDMappings) | Writer - captures list member removals |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CEPListCIDMappings | CLUSTERED PK | CEPListCIDMappingsID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CEPListCIDMappings | PRIMARY KEY CLUSTERED | (CEPListCIDMappingsID), DATA_COMPRESSION=PAGE |

---

## 8. Sample Queries

### 8.1 Get full list membership history for a customer
```sql
SELECT h.NamedListID, h.ValidFrom, h.ValidTo,
       DATEDIFF(DAY, h.ValidFrom, h.ValidTo) AS DaysMember
FROM History.CEPListCIDMappings h WITH (NOLOCK)
WHERE h.CID = 12345678
ORDER BY h.ValidTo DESC;
```

### 8.2 Get all customers archived from a named list
```sql
SELECT h.CID, h.ValidFrom, h.ValidTo
FROM History.CEPListCIDMappings h WITH (NOLOCK)
WHERE h.NamedListID = 13
ORDER BY h.ValidTo DESC;
```

### 8.3 Combined current + historical list membership
```sql
-- Current active members
SELECT l.NamedListID, l.CID, l.ValidFrom, NULL AS ValidTo, 'Active' AS Status
FROM CEP.ListCIDMappings l WITH (NOLOCK)
UNION ALL
-- Historical (removed) members
SELECT h.NamedListID, h.CID, h.ValidFrom, h.ValidTo, 'Archived' AS Status
FROM History.CEPListCIDMappings h WITH (NOLOCK)
ORDER BY NamedListID, CID, ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

One Confluence page found: "CEP queries" (ID: 11761090777) - likely contains operational queries for the CEP system. Content not retrieved.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed + 2 triggers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEPListCIDMappings | Type: Table | Source: etoro/etoro/History/Tables/History.CEPListCIDMappings.sql*
