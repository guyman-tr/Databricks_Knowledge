# Dictionary.NoteType

> Classifies the categories of internal notes that BackOffice staff attach to customer accounts for CRM tracking and operational context.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | NoteTypeID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 NC on Name |

---

## 1. Business Meaning

Dictionary.NoteType categorizes internal notes (free-text annotations) that operations staff attach to customer accounts. Each note type represents a different operational context — general observations, support interactions, telemarketing outreach, or campaign-related communications.

Without this table, customer notes would be uncategorized, making it impossible to filter or search notes by context. Support agents need to quickly find telemarketing notes vs support notes when reviewing a customer's history.

Referenced by History.CustomerNote (NoteTypeID column), written by Maintenance.CustomerNoteAdd procedure, and read through BackOffice.GetCustomerNote view for customer account screens.

---

## 2. Business Logic

### 2.1 Note Categories

**What**: Four categories covering the main customer interaction types.

**Columns/Parameters Involved**: `NoteTypeID`, `Name`

**Rules**:
- General (1): Free-form notes for any purpose — catch-all category
- Support (2): Notes created during customer support interactions (phone, chat, email)
- Telemarketing (3): Notes from outbound sales/engagement calls
- Campaign (4): Notes related to marketing campaigns and promotions

---

## 3. Data Overview

| NoteTypeID | Name | Meaning |
|---|---|---|
| 1 | General | Catch-all category for internal notes not tied to a specific interaction type — used for compliance notes, operational flags, and ad-hoc observations |
| 2 | Support | Notes created during customer service interactions — captures issue summaries, resolutions, and follow-up actions from support tickets |
| 3 | Telemarketing | Notes from outbound customer engagement calls — records call outcomes, customer responses, and scheduled callbacks |
| 4 | Campaign | Notes tied to marketing campaign targeting — records which campaigns a customer was included in and their response |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NoteTypeID | int | NO | - | CODE-BACKED | Unique identifier for the note category: 1=General, 2=Support, 3=Telemarketing, 4=Campaign. Referenced by History.CustomerNote and Maintenance.CustomerNoteAdd. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable category label. Indexed (DCNT_NAME) for fast lookups. Displayed in BackOffice customer note forms and filters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CustomerNote | NoteTypeID | Implicit | Every customer note is classified by this lookup |
| BackOffice.GetCustomerNote | NoteTypeID | View | Joins to resolve note type names for BackOffice display |
| Maintenance.CustomerNoteAdd | @NoteTypeID | Implicit | Note creation procedure requires a note type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CustomerNote | Table | NoteTypeID column |
| BackOffice.GetCustomerNote | View | Joins for note type display |
| Maintenance.CustomerNoteAdd | Stored Procedure | Inserts notes with type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DNTP | CLUSTERED PK | NoteTypeID | - | - | Active |
| DCNT_NAME | NC | Name | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all note types
```sql
SELECT  NoteTypeID,
        Name
FROM    [Dictionary].[NoteType] WITH (NOLOCK)
ORDER BY NoteTypeID;
```

### 8.2 Count customer notes by type
```sql
SELECT  nt.Name AS NoteType,
        COUNT(*) AS NoteCount
FROM    [History].[CustomerNote] cn WITH (NOLOCK)
JOIN    [Dictionary].[NoteType] nt WITH (NOLOCK)
        ON cn.NoteTypeID = nt.NoteTypeID
GROUP BY nt.Name
ORDER BY NoteCount DESC;
```

### 8.3 Find all support notes for a customer
```sql
SELECT  cn.*,
        nt.Name AS NoteType
FROM    [History].[CustomerNote] cn WITH (NOLOCK)
JOIN    [Dictionary].[NoteType] nt WITH (NOLOCK)
        ON cn.NoteTypeID = nt.NoteTypeID
WHERE   cn.CustomerID = 12345
        AND nt.NoteTypeID = 2
ORDER BY cn.NoteID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.NoteType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.NoteType.sql*
