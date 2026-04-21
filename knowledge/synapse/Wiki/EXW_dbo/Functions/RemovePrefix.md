# RemovePrefix

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

Extracts the **rightmost segment** of a delimited string by finding the last occurrence of `@Delimiter` and returning everything to its right. Effectively "removes the prefix" — strips all leading segments and the final delimiter, returning only the trailing part.

**Primary use case**: Parsing EXW_Settings `ResourceName` paths to extract the final component. For example, given a ResourceName like `'cryptos/2/allowstakingmode'` with delimiter `'/'`, returns `'allowstakingmode'`.

**Contrast with RemoveSuffix**: RemoveSuffix returns everything before the *first* delimiter; RemovePrefix returns everything after the *last* delimiter.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @Input | VARCHAR(MAX) | The input string to parse |
| @Delimiter | VARCHAR(10) | The delimiter character or string to search for |

## 3. Logic

```sql
SET @Pos = CHARINDEX(@Delimiter, REVERSE(@Input))
-- @Pos is position of last delimiter, counting from the right
IF @Pos > 0
    RETURN RIGHT(@Input, @Pos - 1)
    -- Returns the @Pos-1 rightmost characters (everything after last delimiter)
RETURN @Input
-- If delimiter not found, return input unchanged
```

**Examples**:

| @Input | @Delimiter | Return Value |
|--------|-----------|-------------|
| `'cryptos/2/allowstakingmode'` | `'/'` | `'allowstakingmode'` |
| `'a/b/c'` | `'/'` | `'c'` |
| `'nodots'` | `'/'` | `'nodots'` (delimiter not found) |
| `'a/'` | `'/'` | `''` (empty string — delimiter is last char) |

**Edge cases**:
- If `@Delimiter` appears at the very end of `@Input`, returns empty string (RIGHT with length 0)
- If `@Input` is NULL, behavior depends on SQL Server NULL propagation — returns NULL
- If `@Delimiter` is multi-character, CHARINDEX matches on the full delimiter string

## 4. Source Objects

| Object | Schema | Notes |
|--------|--------|-------|
| *(none — pure string expression)* | — | No table references |

## 5. Return Value

**VARCHAR(MAX)**: The portion of `@Input` to the right of the last occurrence of `@Delimiter`. Returns `@Input` unchanged if `@Delimiter` is not found.

## 6. Change History

No explicit change history found in function SQL header.

---

*Generated: 2026-04-20 | Quality: 9.0/10 | Phases: 8/11*
*Object: EXW_dbo.RemovePrefix | Type: Scalar Function | Source: EXW_dbo/Functions/EXW_dbo.RemovePrefix.sql*
