# dbo.NationalPinTmp (UDT)

> Table-valued parameter type for passing national PIN data (GCID + value + country) during PIN migration or batch operations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | GCID (PK CLUSTERED) |
| **Partition** | N/A |
| **Indexes** | Clustered PK on GCID |

---

## 1. Business Meaning

dbo.NationalPinTmp carries national PIN data for batch operations, particularly the KYC.NationalPinMigration procedure. Each row represents one user's national PIN value with country context. The clustered PK on GCID ensures one PIN per user and enables efficient JOINs.

---

## 2. Business Logic

No complex business logic. Data transport type with PK constraint.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID. One PIN per user. |
| 2 | Value | nvarchar(128) | YES | - | CODE-BACKED | The national PIN value. |
| 3 | CountryID | int | YES | - | CODE-BACKED | Country context for the PIN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.NationalPinMigration | Parameter | Parameter Type | TVP for PIN migration batch |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.NationalPinMigration | Stored Procedure | READONLY parameter |

---

## 7. Technical Details

### 7.1 Indexes

Clustered PK on GCID (IGNORE_DUP_KEY = OFF).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY CLUSTERED | GCID - one PIN per user |

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @pins dbo.NationalPinTmp
INSERT INTO @pins (GCID, Value, CountryID) VALUES (12345, N'AB123456', 44)
```

### 8.2 Use with migration SP
```sql
DECLARE @pins dbo.NationalPinTmp
INSERT INTO @pins SELECT GCID, Value, CountryID FROM SomeSource
EXEC KYC.NationalPinMigration @Pins = @pins
```

### 8.3 Inspect
```sql
DECLARE @p dbo.NationalPinTmp
INSERT INTO @p VALUES (1, N'PIN1', 44), (2, N'PIN2', 61)
SELECT * FROM @p
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: dbo.NationalPinTmp | Type: User Defined Type | Source: UserApiDB/UserApiDB/dbo/User Defined Types/dbo.NationalPinTmp.sql*
