# Apex.GCIDs

> Table-valued parameter type used to pass a batch of Global Customer IDs (GCIDs) to stored procedures for bulk operations.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | User Defined Type |
| **Key Identifier** | GCID (INT, NOT NULL) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GCIDs is a table-valued parameter (TVP) type that allows callers to pass a list of Global Customer IDs to stored procedures in a single parameter. This enables bulk operations on multiple users without requiring repeated procedure calls or dynamic SQL with comma-separated ID lists.

This type exists to support batch retrieval patterns in the Apex brokerage account integration. When the trading platform needs data for multiple users at once (e.g., bulk sync, bulk status checks), it packages the GCID list into this type and passes it to the relevant procedure.

The calling application constructs a DataTable or equivalent in-memory structure, populates it with GCID values, and passes it as a READONLY parameter to stored procedures. The procedure then JOINs against this TVP to filter results to only the requested users.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple single-column TVP used for parameterized batch filtering.

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter type, not a persisted table. Its contents are transient and exist only during procedure execution.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID - the platform-wide unique identifier for a user/customer. Used as the primary key or foreign key in most Apex tables (ApexData, State, UserData, Options, etc.). Each value identifies one customer whose data should be included in the bulk operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a standalone type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.GetTradingUsersDataList | @gcids | Parameter Type | Procedure accepts this TVP to retrieve trading user data for a batch of customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.GetTradingUsersDataList | Stored Procedure | Accepts as READONLY parameter @gcids for bulk user data retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (inline) | NOT NULL | GCID column is NOT NULL - every entry must have a valid customer ID |

---

## 8. Sample Queries

### 8.1 Declare and populate the TVP for testing

```sql
DECLARE @gcids Apex.GCIDs;
INSERT INTO @gcids (GCID) VALUES (12345), (67890), (11111);
SELECT * FROM @gcids;
```

### 8.2 Use with GetTradingUsersDataList procedure

```sql
DECLARE @gcids Apex.GCIDs;
INSERT INTO @gcids (GCID) VALUES (12345), (67890);
EXEC Apex.GetTradingUsersDataList @gcids = @gcids;
```

### 8.3 JOIN pattern typically used inside procedures

```sql
DECLARE @gcids Apex.GCIDs;
INSERT INTO @gcids (GCID) VALUES (12345), (67890);
SELECT ud.GCID, ud.FirstName, ud.LastName, ad.ApexID, ad.StatusID
FROM @gcids g
INNER JOIN Apex.UserData ud WITH (NOLOCK) ON ud.GCID = g.GCID
INNER JOIN Apex.ApexData ad WITH (NOLOCK) ON ad.GCID = ud.GCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GCIDs | Type: User Defined Type | Source: USABroker/Apex/User Defined Types/Apex.GCIDs.sql*
