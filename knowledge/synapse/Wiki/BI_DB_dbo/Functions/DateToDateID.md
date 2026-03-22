# DateToDateID

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (Scalar) |
| **Domain** | Utility |
| **UC Target** | `_Not_Migrated` |
| **Author** | Not stated in header (comment block is legacy IP text) |
| **Output Columns** | N/A — scalar **BIGINT** return |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Converts a `datetime` value into an integer **DateID** in `YYYYMMDD` form (via `FORMAT` to string then `CAST` to integer-compatible type). Used across BI logic for consistent date keys aligned with warehouse `DateID` columns.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @date | datetime | Calendar timestamp to convert to DateID |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| *(none — expression only)* | — |

## 4. Output Columns

*Scalar function — returns a single **BIGINT** value: `CAST(FORMAT(CAST(@date AS DATE), 'yyyyMMdd') AS INT)` (DateID). Tier: **T2** (date normalization and formatting).*

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2015-07-28 | Yael Hamo | Comment references IP parsing (unrelated to current body); PATINDEX guard for bad IP addresses |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
