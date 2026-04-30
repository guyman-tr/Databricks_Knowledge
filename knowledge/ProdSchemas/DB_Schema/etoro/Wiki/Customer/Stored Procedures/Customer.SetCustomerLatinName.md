# Customer.SetCustomerLatinName

> Batch-upserts Latin-script name and address transliterations for one or more customers via TVP; INSERT on first record, UPDATE on subsequent submissions; sets ModifiedDate=GetUTCDate() on all mutations.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CustomerLatinNameType Customer.CustomerLatinNameType (TVP, READONLY) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetCustomerLatinName` is the write gateway for the Customer.CustomerLatinName table. It accepts a batch of customer Latin-name records as a table-valued parameter and performs a MERGE upsert: new CIDs are inserted, existing CIDs are updated. The ModifiedDate is always set to the current UTC timestamp.

This procedure is called by BackOffice tooling and regulatory/KYC workflows when an operator or automated transliteration tool has produced Latin-script equivalents of a customer's legal name fields (FirstName, LastName, MiddleName, Address, City). The need arises because customers from countries with non-Latin scripts (Russia, Ukraine, UAE, Israel, Greece, etc.) must have ASCII-compatible name records for tax reporting, wire transfer instructions, regulatory submissions, and external system integrations that do not support Unicode.

The TVP input allows bulk processing - multiple customers can be upserted in a single call without requiring individual procedure invocations per CID.

---

## 2. Business Logic

### 2.1 MERGE Upsert via TVP

**What**: A MERGE statement joins the TVP source against Customer.CustomerLatinName on CID. New CIDs are inserted; existing CIDs have all name/address fields replaced.

**Columns/Parameters Involved**: `@CustomerLatinNameType`, `Customer.CustomerLatinName.CID`, `FirstName`, `LastName`, `MiddleName`, `Address`, `City`, `ModifiedDate`

**Rules**:
- `WHEN NOT MATCHED BY TARGET`: INSERT(CID, FirstName, LastName, Address, City, MiddleName, ModifiedDate) VALUES(Source values, GetUTCDate())
- `WHEN MATCHED`: UPDATE SET FirstName, LastName, Address, City, MiddleName = Source values; ModifiedDate = GetUTCDate()
- ModifiedDate is ALWAYS set to current UTC time (not sourced from TVP) - the table has a DEFAULT of getdate() but the MERGE overrides it with GetUTCDate() for UTC consistency.
- NULL fields in the TVP source are stored as NULL (no partial-update / no-op logic). If only one field changed, the caller must supply all fields to avoid overwriting with NULL.
- Idempotent: re-submitting the same CID with the same data re-writes it (no "skip if unchanged" logic).

### 2.2 Error Handling

**What**: Standard PRINT+THROW pattern used throughout the Customer schema.

**Rules**:
- CATCH block prints a diagnostic string including @@ServerName, DB_Name(), Object_Name(@@ProcID), Error_Procedure(), Error_Line(), Error_Message(), Error_Severity(), @@TranCount, and GetUTCDate() timestamp.
- THROW re-raises the original error to the caller after logging.
- No explicit transaction - the MERGE is implicitly atomic for the batch.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CustomerLatinNameType | Customer.CustomerLatinNameType | NO | - | CODE-BACKED | TVP containing the batch of CID + Latin name records to upsert. READONLY. Must include CID, FirstName, LastName, Address, City, MiddleName. NULL fields are stored as NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CustomerLatinNameType | Customer.CustomerLatinNameType | Consumer (TVP type) | User-defined table type defining the TVP schema (CID, FirstName, LastName, Address, City, MiddleName) |
| @CustomerLatinNameType | Customer.CustomerLatinName | MODIFIER (MERGE) | Target of the MERGE: INSERT new CIDs, UPDATE existing CIDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice / KYC tooling | External | Caller | Submits operator-confirmed Latin transliterations for customer legal names |
| Automated transliteration pipelines | External | Caller | Batch-submits algorithmically-converted Latin names for non-Latin script customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetCustomerLatinName (procedure)
+-- Customer.CustomerLatinNameType (user defined type) [TVP parameter type]
+-- Customer.CustomerLatinName (table) [MERGE target - INSERT/UPDATE]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerLatinNameType | User Defined Type (TVP) | Defines the schema of the @CustomerLatinNameType parameter |
| Customer.CustomerLatinName | Table | MERGE target - new rows inserted, existing rows updated |

### 6.2 Objects That Depend On This

No dependents found in Customer schema DDL.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TVP READONLY | Parameter constraint | @CustomerLatinNameType cannot be modified within the procedure |
| MERGE on CID | Key uniqueness | One row per CID in CustomerLatinName; MERGE guarantees upsert semantics |
| ModifiedDate = GetUTCDate() | UTC enforcement | Overrides table DEFAULT (getdate()); all mutation timestamps are stored in UTC |
| No partial update | Design | All 5 name/address fields replaced on UPDATE; caller must supply full row to avoid NULLing out fields |
| No explicit transaction | Design | MERGE is implicitly atomic; no BEGIN/COMMIT wrapping; no rollback behavior on THROW |

---

## 8. Sample Queries

### 8.1 Upsert Latin names for a batch of customers

```sql
DECLARE @LatinNames AS Customer.CustomerLatinNameType;

INSERT INTO @LatinNames(CID, FirstName, LastName, Address, City, MiddleName)
VALUES
    (12345, 'Ivan', 'Petrov', '123 Main St', 'Moscow', NULL),
    (67890, 'Anna', 'Schmidt', '45 Berliner Str', 'Berlin', 'Maria');

EXEC Customer.SetCustomerLatinName @CustomerLatinNameType = @LatinNames;
```

### 8.2 Verify result

```sql
SELECT CID, FirstName, LastName, MiddleName, Address, City, ModifiedDate
FROM Customer.CustomerLatinName WITH (NOLOCK)
WHERE CID IN (12345, 67890)
```

### 8.3 Find recently upserted Latin names

```sql
SELECT TOP 100 CID, FirstName, LastName, ModifiedDate
FROM Customer.CustomerLatinName WITH (NOLOCK)
ORDER BY ModifiedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetCustomerLatinName | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetCustomerLatinName.sql*
