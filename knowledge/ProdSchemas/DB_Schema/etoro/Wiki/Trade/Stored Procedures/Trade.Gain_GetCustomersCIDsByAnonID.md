# Trade.Gain_GetCustomersCIDsByAnonID

> Reverse maps a list of anonymized IDs (GUIDs) back to customer CIDs from Customer.CustomerStatic for the Gain calculation system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @customerIds (TVP of GUIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the reverse of `Trade.Gain_GetCustomersAnonID`. Given a list of anonymized GUIDs, it resolves them back to eToro CIDs. The Gain service uses this when it receives anonymized customer identifiers and needs to look up their actual trading data (positions, credits) which is keyed by CID.

---

## 2. Business Logic

### 2.1 Anonymous ID to CID Reverse Mapping

**What**: Resolves anonymized GUIDs back to CIDs.

**Columns/Parameters Involved**: `ID` (GUID), `CID`

**Rules**:
- Input: list of anonymized IDs (GUIDs) via TVP typed as Trade.Gain_GuidList
- Output: CID + anonymized ID pairs
- JOIN on Customer.CustomerStatic.ID ensures only valid GUIDs are returned
- TVP materialized to temp table with NC index on ID for efficient joining

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @customerIds | Trade.Gain_GuidList (TVP) | NO | - | CODE-BACKED | Table-Valued Parameter containing anonymized IDs (GUIDs) to resolve to CIDs. READONLY. Contains a single column `ID` (uniqueidentifier). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Customer.CustomerStatic | READER | Reverse maps GUID to CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Gain calculation service | EXEC | Caller | Resolves anonymized IDs to CIDs for data lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_GetCustomersCIDsByAnonID (procedure)
+-- Customer.CustomerStatic (table)
+-- Trade.Gain_GuidList (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | JOIN on ID - resolves GUID to CID |
| Trade.Gain_GuidList | User Defined Type | TVP type for @customerIds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called by external Gain service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Temp table: NC INDEX IX_ID on #Tbl(ID).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Resolve GUIDs to CIDs

```sql
DECLARE @guids Trade.Gain_GuidList
INSERT INTO @guids VALUES ('A1B2C3D4-E5F6-7890-ABCD-EF1234567890')
EXEC Trade.Gain_GetCustomersCIDsByAnonID @customerIds = @guids
```

### 8.2 Find Customer by Anonymized ID

```sql
SELECT CID, ID FROM Customer.CustomerStatic WITH (NOLOCK) WHERE ID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
```

### 8.3 View GuidList Type Definition

```sql
SELECT * FROM sys.table_types WHERE name = 'Gain_GuidList' AND schema_id = SCHEMA_ID('Trade')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_GetCustomersCIDsByAnonID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_GetCustomersCIDsByAnonID.sql*
