# Apex.SaveConfiguration

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveConfiguration.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2021-12-08  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveConfiguration` creates or updates a key-value configuration entry in the Apex service's runtime configuration store. This allows operational teams and deployment pipelines to set or change service behaviour — feature flags, timeouts, thresholds, endpoint overrides — without a code deployment.

It is called during application initialisation to seed default configuration values if they do not exist, and by operations tooling when tuning service parameters at runtime.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@key` | `varchar(50)` | No | The configuration key name to create or update. |
| `@value` | `varchar(1024)` | No | The configuration value to associate with the key. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Configuration` | `Apex` | SELECT (EXISTS check) + UPDATE or INSERT | Classic IF EXISTS upsert pattern. |

---

## 5. Logic Flow

1. `IF EXISTS (SELECT ID FROM Apex.Configuration WHERE Key = @key)`:
   - **True:** `UPDATE Configuration SET Value = @value WHERE Key = @key`.
   - **False:** `INSERT INTO Configuration (Key, Value) VALUES (@key, @value)`.

Simple upsert with no change-detection — the UPDATE always fires when the key exists, even if the value is identical.

---

## 6. Error Handling

No explicit error handling. Standard SQL Server exception propagation. A `Key` longer than 50 characters or `Value` longer than 1024 characters will raise a string-truncation error.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Configuration` | Table | Configuration store |
| `Apex.GetConfiguration` | Stored Procedure | Companion reader |

---

## 8. Usage Notes

- Key names are case-sensitive (subject to database collation); use a consistent naming convention to prevent accidental duplicate keys with different cases.
- Unlike `SaveAleTopic`, this procedure does not check for value changes before updating — every call to update an existing key will write to the row. For high-frequency updates, consider adding change-detection.
- `Value` is limited to 1024 characters; structured data (JSON, XML) can be stored but must fit within this limit.
- Operations changes to production configuration via this procedure should be logged and reviewed; the changes take effect immediately for any service that reads configuration at request time.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveConfiguration.sql` | Quality Score: 8.5/10*
