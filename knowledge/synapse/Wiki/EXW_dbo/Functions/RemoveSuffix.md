# RemoveSuffix

## Properties

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Function (Scalar) |
| **Domain** | String Utility |
| **UC Target** | `_Not_Migrated` |
| **Return Type** | VARCHAR(MAX) |
| **Generated** | 2026-04-20 |

## 1. Business Meaning

Extracts the **leftmost segment** of a delimited string by finding the first occurrence of `@Delimiter` and returning everything to its left. Effectively "removes the suffix" — strips the delimiter and all trailing segments, returning only the leading part.

**Primary use case**: Parsing EXW_Settings `ResourceName` paths to extract the leading component. For example, given a ResourceName like `'cryptos/2/allowstakingmode'` with delimiter `'/'`, returns `'cryptos'`.

**Contrast with RemovePrefix**: RemovePrefix returns everything after the *last* delimiter; RemoveSuffix returns everything before the *first* delimiter.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @Input | VARCHAR(MAX) | The input string to parse |
| @Delimiter | VARCHAR(10) | The delimiter character or string to search for |

## 3. Logic

```sql
SET @Pos = CHARINDEX(@Delimiter, @Input)
-- @Pos is position of first delimiter, counting from the left
IF @Pos > 0
    RETURN LEFT(@Input, @Pos - 1)
    -- Returns the @Pos-1 leftmost characters (everything before first delimiter)
RETURN @Input
-- If delimiter not found, return input unchanged
```

**Examples**:

| @Input | @Delimiter | Return Value |
|--------|-----------|-------------|
| `'cryptos/2/allowstakingmode'` | `'/'` | `'cryptos'` |
| `'a/b/c'` | `'/'` | `'a'` |
| `'nodots'` | `'/'` | `'nodots'` (delimiter not found) |
| `'/trailing'` | `'/'` | `''` (empty string — delimiter is first char) |

**Edge cases**:
- If `@Delimiter` appears at the very start of `@Input`, returns empty string
- If `@Input` is NULL, returns NULL (SQL Server NULL propagation)
- If `@Delimiter` is multi-character, CHARINDEX matches on the full delimiter string

## 4. Source Objects

| Object | Schema | Notes |
|--------|--------|-------|
| *(none — pure string expression)* | — | No table references |

## 5. Return Value

**VARCHAR(MAX)**: The portion of `@Input` to the left of the first occurrence of `@Delimiter`. Returns `@Input` unchanged if `@Delimiter` is not found.

## 6. Change History

No explicit change history found in function SQL header.

---

*Generated: 2026-04-20 | Quality: 9.0/10 | Phases: 8/11*
*Object: EXW_dbo.RemoveSuffix | Type: Scalar Function | Source: EXW_dbo/Functions/EXW_dbo.RemoveSuffix.sql*
