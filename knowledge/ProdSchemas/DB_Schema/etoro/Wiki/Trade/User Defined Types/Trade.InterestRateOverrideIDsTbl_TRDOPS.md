# Trade.InterestRateOverrideIDsTbl_TRDOPS

> TVP type for passing a list of interest rate override IDs to delete or process in TRDOPS context.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | Id (int) |
| **Partition** | N/A |
| **Indexes** | 1: PK on Id |

---

## 1. Business Meaning

This type carries a simple list of IDs that identify interest rate override records. It models the domain concept of "which overrides to act on" - typically for deletion or batch processing. The single column Id and clustered primary key ensure unique IDs per row.

The type exists to support Trade.DeleteInterestRateOverride_TRDOPS, which deletes interest rate overrides by the provided IDs. Admin or config services populate the TVP when removing obsolete overrides or cleaning up after migrations.

Services populate the TVP with the IDs to delete, pass it to the procedure, and the procedure uses it in a JOIN or IN clause to target the records for deletion.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple ID list for bulk delete operations.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Interest rate override record ID; references the override table's primary key |

---

## 5. Relationships

### 5.1 References To (this object points to)

Id semantically references the interest rate override table (exact table name from procedure logic). There is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DeleteInterestRateOverride_TRDOPS | @InterestRateOverrideIDs | Parameter (TVP) | Identifies which interest rate override records to delete |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DeleteInterestRateOverride_TRDOPS | Stored Procedure | READONLY parameter for bulk delete of interest rate overrides |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Description |
|------------|------|--------------|-------------|
| PK (default) | Clustered | (Id) | Primary key; IGNORE_DUP_KEY = OFF |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Delete single override
```sql
DECLARE @IDs Trade.InterestRateOverrideIDsTbl_TRDOPS;
INSERT INTO @IDs (Id) VALUES (101);
EXEC Trade.DeleteInterestRateOverride_TRDOPS @InterestRateOverrideIDs = @IDs;
```

### 8.2 Delete multiple overrides
```sql
DECLARE @IDs Trade.InterestRateOverrideIDsTbl_TRDOPS;
INSERT INTO @IDs (Id) VALUES (101), (102), (103);
EXEC Trade.DeleteInterestRateOverride_TRDOPS @InterestRateOverrideIDs = @IDs;
```

### 8.3 Delete from source table
```sql
DECLARE @IDs Trade.InterestRateOverrideIDsTbl_TRDOPS;
INSERT INTO @IDs (Id)
SELECT Id FROM SomeOverrideTable WHERE ExpiredDate < GETDATE();
EXEC Trade.DeleteInterestRateOverride_TRDOPS @InterestRateOverrideIDs = @IDs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InterestRateOverrideIDsTbl_TRDOPS | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InterestRateOverrideIDsTbl_TRDOPS.sql*
