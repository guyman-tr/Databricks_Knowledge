# Dictionary.GetXMLSchema

> System metadata view listing all custom XML schema collections defined in the database for XSD validation of XML-typed columns.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | View |
| **Key Identifier** | XMLSchema (schema collection name) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetXMLSchema exposes the custom XML schema collections (XSD definitions) registered in the database by querying the system catalog view `sys.xml_schema_collections`. XML schemas are used to validate XML data stored in XML-typed columns — for example, payment configuration parameters, instrument settings, and funding type definitions that use XML storage with XSD-enforced structure.

Without this view, inspecting which XML schemas exist and their full XSD content would require direct sys catalog queries. This view provides a convenient, discoverable interface in the Dictionary schema where other lookup/configuration objects reside.

The view filters out `xml_collection_id = 1`, which is the built-in SQL Server XML schema collection (the default "sys" collection). Only user-defined/application-specific XML schemas are returned.

---

## 2. Business Logic

### 2.1 XML Schema Discovery

**What**: Surfaces user-defined XML schema collections for database introspection and validation verification.

**Columns/Parameters Involved**: `Domain`, `XMLSchema`, `XSD`

**Rules**:
- The view queries `sys.xml_schema_collections` which is a system catalog view — not a user table
- `xml_collection_id = 1` is excluded (built-in SQL Server XML schema)
- The `Domain` column uses `SCHEMA_NAME(SCHEMA_ID)` to resolve the owning SQL schema (e.g., "Dictionary", "Billing")
- The `XSD` column calls `XML_SCHEMA_NAMESPACE()` to retrieve the full XML Schema Definition content — this can be large and may time out on some MCP connections
- XML schemas are typically defined via `CREATE XML SCHEMA COLLECTION` statements and bound to XML columns using `xml(SchemaCollectionName)` syntax

**Diagram**:
```
sys.xml_schema_collections (system catalog)
│
├── xml_collection_id = 1 → EXCLUDED (built-in)
│
└── xml_collection_id > 1 → Dictionary.GetXMLSchema
    ├── Domain     = SCHEMA_NAME(schema_id)  → owning SQL schema
    ├── XMLSchema  = name                     → collection name
    └── XSD        = XML_SCHEMA_NAMESPACE()   → full XSD content
```

---

## 3. Data Overview

N/A — The view queries `sys.xml_schema_collections` which returns system metadata. Results vary by database state and cannot be sampled via MCP due to the XML_SCHEMA_NAMESPACE() function's execution requirements.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Domain | sysname | NO | - | CODE-BACKED | Computed: `SCHEMA_NAME(SCHEMA_ID)`. The SQL Server schema that owns this XML schema collection (e.g., "Dictionary", "Billing", "Trade"). Maps the XML collection to its database schema context. |
| 2 | XMLSchema | sysname | NO | - | CODE-BACKED | Name of the XML schema collection as defined by `CREATE XML SCHEMA COLLECTION`. This is the identifier used when binding XML columns: `xml(Dictionary.SchemaName)`. From sys.xml_schema_collections.name. |
| 3 | XSD | xml | YES | - | CODE-BACKED | Computed: `XML_SCHEMA_NAMESPACE(SCHEMA_NAME(SCHEMA_ID), name)`. The full XML Schema Definition (XSD) content of the collection. Contains element definitions, type restrictions, and validation rules. Can be large for complex schemas. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | sys.xml_schema_collections | System catalog | Source of XML schema metadata — a system view, not a user table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No direct SQL consumers found) | - | - | Used for administrative introspection rather than by application procedures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetXMLSchema (view)
└── sys.xml_schema_collections (system catalog view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| sys.xml_schema_collections | System catalog view | SELECT source for XML schema metadata |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found) | - | Administrative/diagnostic view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all custom XML schemas in the database
```sql
SELECT  Domain, XMLSchema
FROM    Dictionary.GetXMLSchema
```

### 8.2 Find XML schemas in a specific SQL schema
```sql
SELECT  Domain, XMLSchema
FROM    Dictionary.GetXMLSchema
WHERE   Domain = 'Dictionary'
```

### 8.3 Find XML columns that reference a specific schema collection
```sql
SELECT  SCHEMA_NAME(t.schema_id) + '.' + t.name AS TableName,
        c.name AS ColumnName, xsc.name AS XMLSchema
FROM    sys.columns c
JOIN    sys.tables t ON t.object_id = c.object_id
JOIN    sys.xml_schema_collections xsc ON xsc.xml_collection_id = c.xml_collection_id
WHERE   c.xml_collection_id > 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetXMLSchema | Type: View | Source: etoro/etoro/Dictionary/Views/Dictionary.GetXMLSchema.sql*
