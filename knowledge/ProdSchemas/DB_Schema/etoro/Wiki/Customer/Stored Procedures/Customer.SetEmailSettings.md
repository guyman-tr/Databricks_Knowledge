# Customer.SetEmailSettings

> Upserts a customer's email notification preferences from an XML list of (TemplateID, IsEnabled) pairs, enabling per-template opt-in and opt-out in a single atomic call.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @Changes XML - targets Customer.EmailSettings rows by (CID, TemplateID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetEmailSettings is the write-path for a customer's per-template email notification preferences. It receives an XML payload containing one or more (TemplateID, IsEnabled) pairs and applies them to Customer.EmailSettings via a cursor-based upsert loop. A customer can control whether they receive each of the 7 tracked email templates (IDs: 651-658) independently, and this procedure is the single entry point for persisting those choices.

This procedure exists so that preference changes can be batched - a single API call can update multiple template preferences atomically. Without it, callers would need to issue individual INSERT/UPDATE statements per template, risking partial updates and inconsistency.

Data flow: called from the customer account settings UI (or its backing service) when the user saves notification preferences. For each (TemplateID, IsEnabled) in the XML, the procedure checks whether a Customer.EmailSettings row already exists for that (CID, TemplateID) pair. If yes, it updates IsEnabled. If no, it inserts a new row. The trigger on Customer.EmailSettings (tr_Update_CustomerEmailSettings) ensures DateModified is set accurately on every UPDATE.

---

## 2. Business Logic

### 2.1 XML-Batch Upsert Pattern

**What**: Processes multiple notification preference changes in one call by parsing an XML document and iterating with a cursor.

**Columns/Parameters Involved**: `@Changes`, `@CID`

**Rules**:
- @Changes must be a well-formed XML document with the root /DocumentElement/NotificationUpdates
- Each NotificationUpdates node must contain TemplateID (INT) and IsEnabled (BIT) attributes
- OPENXML with flag 2 (attribute-centric mapping) reads TemplateID and IsEnabled from node attributes
- The cursor iterates all nodes in document order; each iteration upserts one (CID, TemplateID) pair
- All inserts and updates happen within the same session but are NOT wrapped in an explicit transaction - each row is committed individually

**Diagram**:
```
@Changes XML
  └─ /DocumentElement/NotificationUpdates (0..N nodes)
       Each node: TemplateID, IsEnabled
            |
            v
  sp_xml_preparedocument -> @Handle
            |
  OPENXML cursor (flag=2, attribute-centric)
            |
  For each (TemplateID, IsEnabled):
    EXISTS (CID + TemplateID)?
      YES -> UPDATE EmailSettings SET IsEnabled = @IsEnabled
      NO  -> INSERT INTO EmailSettings (CID, TemplateID, IsEnabled)
            |
  sp_xml_removedocument @Handle (cleanup)
```

### 2.2 Conditional Upsert (EXISTS-Check Before DML)

**What**: Avoids primary key violation by checking row existence before deciding INSERT vs UPDATE.

**Columns/Parameters Involved**: `@CID`, `@TemplateID`, `@IsEnabled`

**Rules**:
- IF EXISTS (SELECT 1 FROM EmailSettings WHERE CID=@CID AND TemplateID=@TemplateID) -> UPDATE path
- ELSE -> INSERT path
- This pattern guarantees no duplicate rows for (CID, TemplateID), preserving the composite PK
- On UPDATE: only IsEnabled is changed; CID, TemplateID, and DateModified remain (DateModified is refreshed by the AFTER UPDATE trigger automatically)
- On INSERT: CID, TemplateID, IsEnabled are all set; DateModified is set by the DEFAULT constraint (GETUTCDATE())

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Changes | xml | NO | - | CODE-BACKED | XML document containing one or more NotificationUpdates nodes. Each node must have TemplateID (INT) and IsEnabled (BIT) attributes. Structure: `/DocumentElement/NotificationUpdates[@TemplateID=651][@IsEnabled=0]`. Parsed via OPENXML (flag=2, attribute-centric) into a cursor. All preference changes for the call are batched in this single document. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer identifier. Applied to every row upserted during this call - all (TemplateID, IsEnabled) pairs in @Changes are applied to this single customer. FK to Customer.CustomerStatic(CID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.EmailSettings | Writer + Modifier | Upserts (CID, TemplateID, IsEnabled) rows; the composite PK (CID, TemplateID) is the natural key for email preferences |
| @CID | Customer.CustomerStatic | Implicit | CID must exist in CustomerStatic; no explicit FK check in procedure, enforced at table level |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | Called from customer account settings UI/service when notification preferences are saved; no intra-DB callers found |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetEmailSettings (procedure)
└── Customer.EmailSettings (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.EmailSettings | Table | Target of upsert operations (INSERT + UPDATE per cursor iteration) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| sp_xml_preparedocument / sp_xml_removedocument | XML Handle lifecycle | @Handle must be released via sp_xml_removedocument after cursor is done to free memory; failure to release leaks server memory per call |

---

## 8. Sample Queries

### 8.1 Call with a single opt-out for template 651
```sql
EXEC Customer.SetEmailSettings
    @CID = 12345,
    @Changes = '<DocumentElement>
        <NotificationUpdates TemplateID="651" IsEnabled="0"/>
    </DocumentElement>';
```

### 8.2 Call with multiple template updates in one batch
```sql
EXEC Customer.SetEmailSettings
    @CID = 12345,
    @Changes = '<DocumentElement>
        <NotificationUpdates TemplateID="651" IsEnabled="0"/>
        <NotificationUpdates TemplateID="652" IsEnabled="0"/>
        <NotificationUpdates TemplateID="657" IsEnabled="1"/>
    </DocumentElement>';
```

### 8.3 Verify the resulting preferences after the call
```sql
SELECT
    es.CID,
    es.TemplateID,
    es.IsEnabled,
    es.DateModified
FROM Customer.EmailSettings es WITH (NOLOCK)
WHERE es.CID = 12345
ORDER BY es.TemplateID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetEmailSettings | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetEmailSettings.sql*
