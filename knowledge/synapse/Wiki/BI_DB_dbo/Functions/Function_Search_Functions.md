# Function_Search_Functions

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Utility |
| **UC Target** | `_Not_Migrated` |
| **Author** | — |
| **Output Columns** | 3 (T1: 2, T2: 1) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns a lightweight catalog of inline table-valued functions (`IF`) in the current database: schema name, object name, and SQL Server `type_desc`. Useful for discovery of which TVFs exist without querying metadata manually.

## 2. Parameters

No parameters.

## 3. Source Objects

| Object | Schema |
|--------|--------|
| objects | sys |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | schema_name | sys.objects | SCHEMA_NAME(schema_id) | T2 |
| 2 | function_name | sys.objects.name | Passthrough from sys.objects.name (no upstream wiki) | T1 |
| 3 | function_type | sys.objects.type_desc | Passthrough from sys.objects.type_desc (no upstream wiki) | T1 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
