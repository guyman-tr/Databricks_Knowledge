# Apex.GetConfiguration

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetConfiguration.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2021-12-08  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetConfiguration` retrieves a named configuration value from the Apex service's key-value configuration store. It is used by application services to read runtime-tunable settings — such as feature flags, thresholds, timeout values, or integration endpoint overrides — without requiring a code deployment.

The configuration table acts as an operational knob panel: any string value can be stored and retrieved by key. This procedure is typically called at service startup or on each request where a configuration-dependent decision must be made.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@key` | `varchar(50)` | No | The configuration key to look up (case-sensitive equality match). |

---

## 3. Result Sets

**Result Set 1 – Configuration Entry**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `ID` | `Apex.Configuration` | Surrogate primary key of the configuration record. |
| `Key` | `Apex.Configuration` | The configuration key name (echoed for confirmation). |
| `Value` | `Apex.Configuration` | The configuration value associated with the key (up to 1024 characters). |

Returns 0 rows if the key does not exist in the configuration store.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Configuration` | `Apex` | SELECT | Simple point-query by `Key` column. No locking hints. |

---

## 5. Logic Flow

1. Executes a single `SELECT` from `Apex.Configuration`.
2. Filters with `WHERE [Key] = @key` (exact string match).
3. Returns `ID`, `Key`, `Value`.

No joins, aggregates, or conditional logic. This is a simple configuration dictionary lookup.

---

## 6. Error Handling

No explicit error handling. A missing key returns an empty result set rather than an error. Calling code is responsible for interpreting an empty result as "use the default value."

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Configuration` | Table | Only data source |
| `Apex.SaveConfiguration` | Stored Procedure | Companion writer; creates or updates the key-value pair read here |

---

## 8. Usage Notes

- The `Value` column is typed `varchar(1024)` — callers must parse numeric, boolean, or structured values from the string representation.
- No `NOLOCK` hint is present; this is intentional to ensure callers always read committed configuration values.
- If the key is absent, the calling service should fall back to a compiled-in default and optionally create the key via `Apex.SaveConfiguration` with the default value.
- Key names are case-sensitive due to the database collation; standardise on a naming convention (e.g., PascalCase) to avoid lookup failures.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetConfiguration.sql` | Quality Score: 8.5/10*
