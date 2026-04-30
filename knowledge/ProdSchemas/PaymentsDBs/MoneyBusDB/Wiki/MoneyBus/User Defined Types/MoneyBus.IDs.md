# MoneyBus.IDs

> Table-valued parameter type used to pass a list of bigint identifiers to stored procedures for batch lookup operations.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | ID (BIGINT) - single-column table type |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.IDs is a table-valued parameter type that enables batch operations across the MoneyBus payment system. It defines a simple single-column structure for passing a collection of bigint identifiers from application code into stored procedures as a single parameter, replacing the need for comma-delimited ID strings or multiple individual calls.

This type exists to support efficient batch retrieval of withdrawal records. Without it, fetching multiple withdrawals by ID would require either dynamic SQL with an IN clause built from a string, or N individual procedure calls - both of which are less performant and harder to parameterize safely.

The application services (specifically the withdraw execution microservices `prod-mbwithdrawex-msi-ne` and `prod-mbwithdrawex-msi-we`) populate this type with withdrawal IDs and pass it to the WithdrawGetList and WithdrawGetListV2 procedures to retrieve multiple withdrawal records in a single round-trip.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple container type for passing ID collections.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | The identifier value to look up. When used with WithdrawGetList/WithdrawGetListV2, this corresponds to MoneyBus.Withdrawals.ID. The NOT NULL constraint prevents accidental null entries in the batch which would cause unexpected result set behavior in IN/JOIN operations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a generic ID container - the semantic meaning of the IDs depends on which procedure consumes it.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.WithdrawGetList | @Ids parameter | Parameter Type | Accepts a batch of withdrawal IDs to retrieve multiple withdrawal records in one call |
| MoneyBus.WithdrawGetListV2 | @Ids parameter | Parameter Type | Accepts a batch of withdrawal IDs for the V2 paginated/filtered retrieval procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawGetList | Stored Procedure | @Ids READONLY parameter - filters Withdrawals by ID list |
| MoneyBus.WithdrawGetListV2 | Stored Procedure | @Ids READONLY parameter - filters Withdrawals by ID list with paging |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (inline) | NOT NULL | ID column is NOT NULL - prevents null entries in the batch which would cause unexpected JOIN/IN behavior |

---

## 8. Sample Queries

### 8.1 Declare and populate the type for testing
```sql
DECLARE @Ids MoneyBus.IDs;
INSERT INTO @Ids (ID) VALUES (1001), (1002), (1003);
EXEC MoneyBus.WithdrawGetList @Ids = @Ids;
```

### 8.2 Use with WithdrawGetListV2 for filtered retrieval
```sql
DECLARE @Ids MoneyBus.IDs;
INSERT INTO @Ids (ID) VALUES (5001), (5002);
EXEC MoneyBus.WithdrawGetListV2 @Ids = @Ids, @StatusID = 1, @Top = 50;
```

### 8.3 Populate from a query result
```sql
DECLARE @Ids MoneyBus.IDs;
INSERT INTO @Ids (ID)
SELECT ID FROM MoneyBus.Withdrawals WITH (NOLOCK)
WHERE GCID = 12345 AND StatusID = 1;
EXEC MoneyBus.WithdrawGetList @Ids = @Ids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/2*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.IDs | Type: User Defined Type | Source: MoneyBusDB/MoneyBus/User Defined Types/MoneyBus.IDs.sql*
