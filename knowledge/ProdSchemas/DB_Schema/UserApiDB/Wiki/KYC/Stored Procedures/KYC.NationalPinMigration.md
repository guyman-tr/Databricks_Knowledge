# KYC.NationalPinMigration

> Bulk inserts national PIN values from a TVP into Customer.ExtendedUserField with FieldId=7 (NationalPin) and TypeId=38 (CONCAT).

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NationalPinTmp (input TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.NationalPinMigration is a data migration procedure that bulk-inserts national PIN values into Customer.ExtendedUserField. It takes a dbo.NationalPinTmp TVP and inserts each row with FieldId=7 (NationalPin), TypeId=38 (CONCAT format), and the current UTC timestamp. Used for one-time or batch migration of national PIN data from external sources.

---

## 2. Business Logic

### 2.1 Fixed Field/Type Assignment

**What**: All migrated PINs are assigned FieldId=7 and TypeId=38.

**Rules**:
- FieldId=7 maps to Dictionary.ExtendedUserField "NationalPin"
- TypeId=38 maps to Dictionary.ExtendedUserValueType "CONCAT" (concatenated format)
- LastModified set to GETUTCDATE()

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NationalPinTmp | dbo.NationalPinTmp READONLY (IN) | NO | - | CODE-BACKED | TVP with GCID, Value, CountryID rows to migrate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.ExtendedUserField | INSERT INTO | Bulk insert PIN data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.NationalPinMigration (procedure)
  +-- Customer.ExtendedUserField (table) [done]
  +-- dbo.NationalPinTmp (UDT) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserField | Table | INSERT INTO |
| dbo.NationalPinTmp | UDT | Parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Migrate PINs
```sql
DECLARE @pins dbo.NationalPinTmp
INSERT INTO @pins (GCID, Value, CountryID) VALUES (12345, N'AB123456', 44), (67890, N'CD789012', 61)
EXEC KYC.NationalPinMigration @NationalPinTmp = @pins
```

### 8.2 Verify migration
```sql
SELECT GCID, Value, TypeId, LastModified FROM Customer.ExtendedUserField WITH (NOLOCK)
WHERE FieldId = 7 AND TypeId = 38 ORDER BY LastModified DESC
```

### 8.3 Bulk from source
```sql
DECLARE @pins dbo.NationalPinTmp
INSERT INTO @pins SELECT GCID, PinValue, CountryID FROM SomeSourceTable
EXEC KYC.NationalPinMigration @NationalPinTmp = @pins
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.NationalPinMigration | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.NationalPinMigration.sql*
