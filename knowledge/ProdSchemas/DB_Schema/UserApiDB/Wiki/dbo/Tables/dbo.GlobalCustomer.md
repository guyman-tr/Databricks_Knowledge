# dbo.GlobalCustomer

> Master table for generating Global Customer IDs (GCIDs) - the central identity generator for all users in the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | GlobalCID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.GlobalCustomer is the GCID generator table. When a new user registers, a row is inserted here to obtain the next IDENTITY value as their GlobalCID (GCID). This GCID then becomes the primary key across Customer.BasicUserInfo, Customer.ContactUserInfo, Customer.AccountUserInfo, Customer.RiskUserInfo, and all other Customer tables. The UserName and Email are stored here as masked fields for quick lookup without joining Customer tables.

This is one of the most critical tables in the database - it is the root of the user identity system. The IDENTITY property with NOT FOR REPLICATION ensures GCID uniqueness across replicated environments.

---

## 2. Business Logic

No complex multi-column business logic. GCID generator with masked PII.

---

## 3. Data Overview

N/A - transactional table (one row per user ever registered).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GlobalCID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. The Global Customer ID - auto-incrementing, NOT FOR REPLICATION. This is the GCID used across all Customer tables. |
| 2 | UserName | varchar(20) MASKED | NO | - | CODE-BACKED | User's platform handle. Dynamic data masking applied. Duplicated from Customer.BasicUserInfo for quick access. |
| 3 | Email | varchar(50) MASKED | YES | - | CODE-BACKED | User's email. Dynamic data masking applied. Duplicated from Customer.ContactUserInfo for quick access. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.InsertGlobalCustomer | GlobalCID | SP writes | Inserts new GCID |
| All Customer.* tables | GCID | Implicit FK | All Customer tables use GCID from here |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.InsertGlobalCustomer | Stored Procedure | Inserts rows to generate GCIDs |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_GlobalCustomer | CLUSTERED PK | GlobalCID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up by GCID
```sql
SELECT GlobalCID, UserName, Email FROM dbo.GlobalCustomer WITH (NOLOCK) WHERE GlobalCID = @GCID
```

### 8.2 Recent registrations
```sql
SELECT TOP 50 GlobalCID, UserName FROM dbo.GlobalCustomer WITH (NOLOCK) ORDER BY GlobalCID DESC
```

### 8.3 Count total users
```sql
SELECT COUNT(*) AS TotalUsers FROM dbo.GlobalCustomer WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.GlobalCustomer | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.GlobalCustomer.sql*
