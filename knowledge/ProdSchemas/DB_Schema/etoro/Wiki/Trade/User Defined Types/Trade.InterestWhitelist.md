# Trade.InterestWhitelist

> A table-valued parameter type for bulk loading customer ID to player-level interest whitelist mappings, used to control which customers qualify for interest payments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID (int) |
| **Partition** | N/A |
| **Indexes** | PRIMARY KEY CLUSTERED on CID |

---

## 1. Business Meaning

Trade.InterestWhitelist is a table-valued parameter (TVP) type that carries customer-to-player-level pairs for the interest whitelist. The whitelist determines which customers are eligible to receive interest on their balances based on player level tiers. Each row maps a CID to an optional PlayerLevelID - the presence of a row indicates whitelist inclusion.

This type exists to support bulk updates of the interest whitelist configuration. Operations such as inserting or refreshing the whitelist from external config require passing many CID-level pairs in a single call rather than per-row round trips.

The application or ETL process builds an InterestWhitelist table and passes it as a READONLY parameter to Trade.InsertInterestWhitelist. The procedure merges the TVP into the persistent Trade.InterestWhitelist table. GetInterestDaily_for_Azure JOINs against the table to filter interest calculations for whitelisted customers.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. CID + PlayerLevelID pairs for whitelist membership configuration; PlayerLevelID can be NULL indicating default or unspecified tier.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - primary account identifier. Each row indicates this customer is whitelisted for interest. |
| 2 | PlayerLevelID | int | YES | - | NAME-INFERRED | Player level tier ID. Optional; when set, restricts interest eligibility to this tier. References player level configuration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID semantically references Customer entities; PlayerLevelID references player level config. There are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertInterestWhitelist | @InterestWhitelist | Parameter (TVP) | Bulk merges whitelist rows into persistent InterestWhitelist table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertInterestWhitelist | Stored Procedure | READONLY parameter for bulk whitelist merge |

---

## 7. Technical Details

### 7.1 Indexes

PRIMARY KEY CLUSTERED on CID. The type is defined with IGNORE_DUP_KEY = OFF.

### 7.2 Constraints

Primary key on CID; no other constraints.

---

## 8. Sample Queries

### 8.1 Declare and populate for bulk whitelist insert

```sql
DECLARE @Whitelist Trade.InterestWhitelist;
INSERT INTO @Whitelist (CID, PlayerLevelID) VALUES (12345, 1), (67890, 2), (11111, NULL);
EXEC Trade.InsertInterestWhitelist @InterestWhitelist = @Whitelist;
```

### 8.2 Load whitelist from config table

```sql
DECLARE @Whitelist Trade.InterestWhitelist;
INSERT INTO @Whitelist (CID, PlayerLevelID)
SELECT CID, PlayerLevelID FROM Staging.InterestWhitelistConfig;
EXEC Trade.InsertInterestWhitelist @InterestWhitelist = @Whitelist;
```

### 8.3 Single customer whitelist

```sql
DECLARE @Whitelist Trade.InterestWhitelist;
INSERT INTO @Whitelist (CID, PlayerLevelID) VALUES (50001, 3);
EXEC Trade.InsertInterestWhitelist @InterestWhitelist = @Whitelist;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 2/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InterestWhitelist | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InterestWhitelist.sql*
