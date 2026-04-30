# BackOffice.ExpirationHoursCalc

> Calculates a position expiration date/time for a given customer, provider, and label combination using BackOffice.ExpirationHoursMatrix; returns a far-future sentinel date when no config is found or server bypass applies.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExpirationDate (OUTPUT parameter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.ExpirationHoursCalc computes the expiration timestamp for a pending position order. It looks up a configured expiration duration (in hours) from `BackOffice.ExpirationHoursMatrix`, keyed on CID parity (`CID % 2`), the real provider, and the label (white-label partner). The expiration is returned as `GETDATE() + ExpirationHours`.

In practice, the procedure always returns `'3000-01-01'` (a far-future sentinel meaning "never expires") because:
1. Two specific production servers (AMS-QUAD-SQL-1 and AMS-BIG-SQL-1) are hardcoded to bypass the lookup and always return `'3000-01-01'`.
2. `BackOffice.ExpirationHoursMatrix` contains 0 rows - the table is empty - so the lookup always falls through to the default `'3000-01-01'`.

This procedure is effectively inactive/always-bypass in the current production configuration.

---

## 2. Business Logic

### 2.1 Server-Specific Bypass

**What**: Two production servers always skip the lookup and return a far-future sentinel date.

**Columns/Parameters Involved**: `@@SERVERNAME`, `@ExpirationDate`

**Rules**:
- IF @@SERVERNAME IN ('AMS-QUAD-SQL-1', 'AMS-BIG-SQL-1'):
  - SET @ExpirationDate = '3000-01-01'
  - RETURN 0 immediately (no lookup performed).
- These are eToro's primary production DB servers - meaning in production, the full lookup path is never reached.

### 2.2 ExpirationHoursMatrix Lookup

**What**: Looks up expiration hours by CID parity, provider, and label.

**Columns/Parameters Involved**: `@CID`, `@RealProviderID`, `@LabelID`, `BackOffice.ExpirationHoursMatrix`, `@ExpirationDate`

**Rules**:
- SELECT @ExpirationHours = ExpirationHours FROM BackOffice.ExpirationHoursMatrix WHERE CIDParity = @CID % 2 AND RealProviderID = @RealProviderID AND LabelID = @LabelID.
- CID parity (CID % 2) partitions customers into two groups (odd/even) allowing different expiration rules per group.
- IF a row is found: SET @ExpirationDate = DATEADD(hour, @ExpirationHours, GETDATE()).
- IF no row found (including always, since table is empty): SET @ExpirationDate = '3000-01-01'.

**Diagram**:
```
IF @@SERVERNAME IN ('AMS-QUAD-SQL-1', 'AMS-BIG-SQL-1')
  -> @ExpirationDate = '3000-01-01' (RETURN immediately)
ELSE
  -> Lookup ExpirationHoursMatrix WHERE CID%2, RealProviderID, LabelID
  IF found:  @ExpirationDate = DATEADD(hour, ExpirationHours, GETDATE())
  IF not found: @ExpirationDate = '3000-01-01'
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Used as @CID % 2 to determine CID parity group for the matrix lookup. FK to BackOffice.Customer. |
| 2 | @RealProviderID | INT | NO | - | CODE-BACKED | The real (execution) provider for the position. Part of the composite lookup key in ExpirationHoursMatrix. |
| 3 | @LabelID | INT | NO | - | CODE-BACKED | White-label partner ID. Part of the composite lookup key in ExpirationHoursMatrix. |
| 4 | @ExpirationDate | DATETIME | OUTPUT | - | CODE-BACKED | Output: the computed expiration timestamp. Either DATEADD(hour, ExpirationHours, GETDATE()) if a config row is found, or '3000-01-01' as a sentinel "never expires" date. Currently always returns '3000-01-01'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID % 2, @RealProviderID, @LabelID | BackOffice.ExpirationHoursMatrix | Lookup | Composite key lookup for expiration hours config. Table is currently empty. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice permissions layer | GRANT EXEC | Permission | No SQL-layer callers found. Called by order processing logic via app layer. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ExpirationHoursCalc (procedure)
└── BackOffice.ExpirationHoursMatrix (table) - lookup (currently 0 rows)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ExpirationHoursMatrix | Table | SELECT ExpirationHours WHERE CIDParity=@CID%2, RealProviderID, LabelID. Table is empty - lookup always misses. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Order processing / position open flow | External | EXEC - called with OUTPUT @ExpirationDate when creating pending orders |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Server bypass (hardcoded) | Behavior | AMS-QUAD-SQL-1 and AMS-BIG-SQL-1 always return '3000-01-01' without lookup. These are eToro's primary prod servers. |
| Empty config table | Behavior | ExpirationHoursMatrix has 0 rows (PK named "PK_SomeTable" - placeholder). Lookup always misses -> always returns '3000-01-01'. |
| '3000-01-01' sentinel | Convention | Far-future date used to mean "never expires". Callers must handle this sentinel as "no expiration". |
| CID parity design | Architecture | CID % 2 (odd/even) allows different expiration policies for two customer cohorts. Design is sound but never configured. |
| RETURN 0 on server bypass | Behavior | Server bypass exits immediately via RETURN. Subsequent logic (matrix lookup) is skipped entirely on prod. |

---

## 8. Sample Queries

### 8.1 Calculate expiration for a position order
```sql
DECLARE @ExpirationDate DATETIME
EXEC BackOffice.ExpirationHoursCalc
    @CID = 12345,
    @RealProviderID = 7,
    @LabelID = 1,
    @ExpirationDate = @ExpirationDate OUTPUT
SELECT @ExpirationDate AS ExpirationDate
-- Returns: 3000-01-01 00:00:00.000 (always, in current config)
```

### 8.2 Check current ExpirationHoursMatrix config
```sql
SELECT CIDParity, RealProviderID, LabelID, ExpirationHours
FROM BackOffice.ExpirationHoursMatrix WITH (NOLOCK)
ORDER BY CIDParity, RealProviderID, LabelID
-- Returns: 0 rows (table is empty)
```

### 8.3 What the lookup would produce if the table were populated
```sql
-- If CIDParity=1, RealProviderID=7, LabelID=1, ExpirationHours=24 existed:
-- @ExpirationDate = DATEADD(hour, 24, GETDATE()) = tomorrow at current time
SELECT DATEADD(hour, 24, GETDATE()) AS ExampleExpirationDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ExpirationHoursCalc | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ExpirationHoursCalc.sql*
