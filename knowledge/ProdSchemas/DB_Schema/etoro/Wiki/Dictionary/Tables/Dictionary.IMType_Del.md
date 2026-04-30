# Dictionary.IMType_Del

> Deprecated lookup table defining five legacy instant messaging platform types — Windows Live Messenger, Yahoo!, Google Talk, Skype, and ICQ — from an earlier era when eToro collected IM contact details during registration.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | IMTypeID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK + unique on Name) |

---

## 1. Business Meaning

Dictionary.IMType_Del is a deprecated table that defined the types of instant messaging platforms available for customer contact preferences. In eToro's early years, the registration and profile management system allowed customers to provide their IM contact details (Windows Live Messenger, Yahoo! Messenger, Google Talk, Skype, ICQ). This data was used by customer support and sales teams to contact customers through their preferred IM platform.

This table exists as a historical artifact. The "_Del" suffix indicates it has been logically deleted/deprecated. The IM platforms listed are largely defunct (Windows Live Messenger, Yahoo! Messenger, Google Talk, ICQ) or have evolved beyond simple IM functionality (Skype). Modern customer communication uses different channels.

The table is referenced by deprecated BackOffice procedures (CustomerIMDetailAdd_Del, CustomerIMDetailRemove_Del, CustomerIMDetailUpdate_Del, CustomerIMVerify_Del) and the deprecated BackOffice.CustomerToIMType_Del mapping table.

---

## 2. Business Logic

### 2.1 Legacy IM Platform Registry

**What**: Five IM platforms from the 2008-2012 era that were offered as customer contact channels.

**Columns/Parameters Involved**: `IMTypeID`, `Name`

**Rules**:
- All five platforms are legacy/deprecated — no new IM details are collected
- The "_Del" suffix on the table and all related objects indicates the entire IM subsystem has been retired
- Historical data may still exist in BackOffice.CustomerToIMType_Del for compliance/audit purposes
- The unique index on Name ensures no duplicate platform entries

---

## 3. Data Overview

| IMTypeID | Name | Meaning |
|---|---|---|
| 1 | Windows Live Messenger | Microsoft's IM platform (2005-2013). Was one of the most popular IM platforms during eToro's early years. Service was discontinued and users migrated to Skype. |
| 2 | Yahoo! Messenger | Yahoo's IM platform (1998-2018). Popular in the US and Southeast Asia. Service discontinued in 2018. |
| 3 | Google Talk | Google's IM platform (2005-2017). Evolved into Google Hangouts, then Google Chat. |
| 4 | Skype | Microsoft's VoIP/IM platform (2003-present). The only platform still operational, though less commonly used for business contact today. |
| 5 | ICQ | Early IM platform (1996-present). Very popular in Israel and Russia. Still operational but with minimal user base compared to its peak. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IMTypeID | int | NO | - | VERIFIED | Primary key identifying the IM platform. 1=Windows Live Messenger, 2=Yahoo! Messenger, 3=Google Talk, 4=Skype, 5=ICQ. Used in the deprecated customer IM contact system. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable name of the IM platform. Constrained by unique index (DIMT_NAME). Was displayed in customer profile forms and BackOffice customer detail screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerToIMType_Del | IMTypeID | Implicit FK | Deprecated mapping of customers to their IM platform preferences |
| BackOffice.CustomerIMDetailAdd_Del | IMTypeID | Parameter | Deprecated procedure for adding customer IM details |
| BackOffice.CustomerIMDetailRemove_Del | IMTypeID | Parameter | Deprecated procedure for removing customer IM details |
| BackOffice.CustomerIMDetailUpdate_Del | IMTypeID | Parameter | Deprecated procedure for updating customer IM details |
| BackOffice.CustomerIMVerify_Del | IMTypeID | Parameter | Deprecated procedure for verifying customer IM details |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToIMType_Del | Table | References IMTypeID for customer IM mapping |
| BackOffice.CustomerIMDetailAdd_Del | Stored Procedure | Uses IMTypeID to add IM contact details |
| BackOffice.CustomerIMDetailRemove_Del | Stored Procedure | Uses IMTypeID to remove IM contact details |
| BackOffice.CustomerIMDetailUpdate_Del | Stored Procedure | Uses IMTypeID to update IM contact details |
| BackOffice.CustomerIMVerify_Del | Stored Procedure | Uses IMTypeID for IM verification |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DIMT | CLUSTERED PK | IMTypeID ASC | - | - | Active |
| DIMT_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DIMT | PRIMARY KEY | Unique IM platform identifier |
| DIMT_NAME | UNIQUE | No duplicate platform names allowed |

---

## 8. Sample Queries

### 8.1 List all IM types
```sql
SELECT  IMTypeID,
        Name
FROM    [Dictionary].[IMType_Del] WITH (NOLOCK)
ORDER BY IMTypeID;
```

### 8.2 Check for remaining customer IM associations
```sql
SELECT  im.Name AS IMPlatform,
        COUNT(*) AS CustomerCount
FROM    [BackOffice].[CustomerToIMType_Del] cim WITH (NOLOCK)
JOIN    [Dictionary].[IMType_Del] im WITH (NOLOCK)
        ON cim.IMTypeID = im.IMTypeID
GROUP BY im.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Identify deprecated IM objects
```sql
SELECT  'Dictionary.IMType_Del' AS ObjectName, 'Table' AS ObjectType
UNION ALL
SELECT  'BackOffice.CustomerToIMType_Del', 'Table'
UNION ALL
SELECT  'BackOffice.CustomerIMDetailAdd_Del', 'Procedure'
UNION ALL
SELECT  'BackOffice.CustomerIMDetailRemove_Del', 'Procedure';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.IMType_Del | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.IMType_Del.sql*
