# Trade.Gain_GetCustomersAnonID

> Maps a list of customer CIDs to their anonymized IDs (GUIDs) from Customer.CustomerStatic for the Gain calculation system's privacy-compliant output.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @customerIds (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure maps eToro customer IDs (CIDs) to their anonymized identifiers (the `ID` column in `Customer.CustomerStatic`, which is a GUID/uniqueidentifier). The Gain service uses this mapping to produce privacy-compliant gain reports where customer identities are anonymized. This is necessary for regulatory compliance (e.g., GDPR) when gain data is shared externally or stored in analytics systems.

---

## 2. Business Logic

### 2.1 CID to Anonymous ID Mapping

**What**: Resolves CIDs to anonymized GUIDs.

**Columns/Parameters Involved**: `CID`, `Customer.CustomerStatic.ID`

**Rules**:
- Input: list of CIDs via TVP
- Output: CID + anonymized ID pairs
- JOIN ensures only valid CIDs (existing in CustomerStatic) are returned
- TVP is materialized to a temp table with NC index on CID for efficient joining

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @customerIds | Trade.CidList (TVP) | NO | - | CODE-BACKED | Table-Valued Parameter containing CIDs to resolve. READONLY. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Customer.CustomerStatic | READER | Maps CID to anonymized ID (GUID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Gain calculation service | EXEC | Caller | Gets anonymized IDs for gain reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_GetCustomersAnonID (procedure)
+-- Customer.CustomerStatic (table)
+-- Trade.CidList (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | JOIN - reads anonymized ID for each CID |
| Trade.CidList | User Defined Type | TVP type for @customerIds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called by external Gain service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Temp table: NC INDEX IX_ID on #Tbl(CID).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get Anonymized IDs for Customers

```sql
DECLARE @cids Trade.CidList
INSERT INTO @cids VALUES (12345), (67890)
EXEC Trade.Gain_GetCustomersAnonID @customerIds = @cids
```

### 8.2 View CustomerStatic ID Format

```sql
SELECT TOP 5 CID, ID FROM Customer.CustomerStatic WITH (NOLOCK)
```

### 8.3 Count Customers with Anonymous IDs

```sql
SELECT COUNT(*) AS Total, COUNT(ID) AS WithAnonID FROM Customer.CustomerStatic WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_GetCustomersAnonID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_GetCustomersAnonID.sql*
