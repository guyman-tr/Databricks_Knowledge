# BackOffice.InsertWebinarData

> Processes an XML payload of webinar participation events and inserts new unique records into BackOffice.Webinars, skipping duplicates.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WebinarData XML (batch of WebinarMember elements); no return value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`InsertWebinarData` processes a batch of webinar participation records submitted as XML and inserts them into `BackOffice.Webinars`. Each record represents a customer's interaction with a webinar - joining, attending, or another action - tracked by email address, action type, time, and language.

The procedure was built in 2012 to support a webinar marketing feature where eToro hosted educational webinars and tracked participant engagement. The data supports CRM, customer classification, and potentially alert prioritization based on customer activity.

The procedure is idempotent: it checks for an exact duplicate (Email + WebinarActionID + Occurred + LanguageID) before each insert and silently skips any already-existing record. This allows the same batch to be sent multiple times without duplication.

The cursor-based implementation reflects the original 2012 design before set-based XML processing was common. Called by `PROD_BIadmins` for batch imports.

---

## 2. Business Logic

### 2.1 XML Batch Processing with Deduplication

**What**: Iterates through `WebinarMember` nodes in the XML input and inserts each as a new row if not already present.

**Columns/Parameters Involved**: `@WebinarData`, `Email`, `WebinarActionID`, `Occurred`, `LanguageID`

**Rules**:
- XML structure: `/WebinarData/WebinarMember` nodes, each with `Email`, `WebinarActionID`, `Occurred`, `LanguageID` children
- For each member, checks `IF NOT EXISTS (SELECT 1 FROM BackOffice.Webinars WHERE Email=@Email AND WebinarActionID=@WebinarActionID AND Occurred=@Occurred AND LanguageID=@LanguageID)`
- All four fields must match exactly for a record to be considered a duplicate
- Cursor processes records one at a time (legacy implementation)

**Diagram**:
```
@WebinarData XML
  /WebinarData/WebinarMember[1] -> Email, WebinarActionID, Occurred, LanguageID
  /WebinarData/WebinarMember[2] -> ...
  ...
  For each member:
    IF NOT EXISTS in BackOffice.Webinars -> INSERT
    ELSE -> skip (silent, no error)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WebinarData | XML | NO | - | CODE-BACKED | XML payload containing one or more `WebinarMember` elements. Each element must have `Email`, `WebinarActionID`, `Occurred`, and `LanguageID` child nodes. See Section 2.1 for structure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Email | BackOffice.Webinars | Writer + EXISTS check | Inserts new webinar participation records, skipping duplicates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | @WebinarData | Caller | BI admin batch import of webinar data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.InsertWebinarData (procedure)
└── BackOffice.Webinars (table) [EXISTS check + INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Webinars | Table | EXISTS duplicate check + INSERT for new records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | External user group | Batch import of webinar participation data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CURSOR | Implementation | Uses a DECLARE/OPEN/FETCH/CLOSE/DEALLOCATE cursor to iterate XML nodes one at a time |
| IF NOT EXISTS guard | Deduplication | Prevents duplicate inserts on (Email, WebinarActionID, Occurred, LanguageID) |
| WITH (NOLOCK) | Query hint | EXISTS check uses NOLOCK on BackOffice.Webinars |
| No TRY/CATCH | Design | Errors propagate to caller |
| No NOCOUNT | Omission | Row counts returned to caller on each insert |

---

## 8. Sample Queries

### 8.1 Insert webinar data from XML

```sql
DECLARE @xml XML = '
<WebinarData>
    <WebinarMember>
        <Email>customer@example.com</Email>
        <WebinarActionID>1</WebinarActionID>
        <Occurred>2026-03-18 14:00:00</Occurred>
        <LanguageID>1</LanguageID>
    </WebinarMember>
    <WebinarMember>
        <Email>another@example.com</Email>
        <WebinarActionID>2</WebinarActionID>
        <Occurred>2026-03-18 14:30:00</Occurred>
        <LanguageID>4</LanguageID>
    </WebinarMember>
</WebinarData>';

EXEC [BackOffice].[InsertWebinarData] @WebinarData = @xml;
```

### 8.2 Check recent webinar activity

```sql
SELECT TOP 20
    Email,
    WebinarActionID,
    Occurred,
    LanguageID
FROM BackOffice.Webinars WITH (NOLOCK)
ORDER BY Occurred DESC;
```

### 8.3 Find webinar activity by email

```sql
SELECT
    Email,
    WebinarActionID,
    Occurred,
    LanguageID
FROM BackOffice.Webinars WITH (NOLOCK)
WHERE Email = 'customer@example.com'
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 7.5/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: PROD_BIadmins caller | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.InsertWebinarData | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.InsertWebinarData.sql*
