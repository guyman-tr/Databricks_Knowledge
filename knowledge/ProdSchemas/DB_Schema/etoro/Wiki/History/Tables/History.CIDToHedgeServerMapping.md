# History.CIDToHedgeServerMapping

> Point-in-time XML snapshots of the customer-to-hedge-server mapping configuration, archived whenever the mapping changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Occurred - datetime PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CIDToHedgeServerMapping stores historical snapshots of the XML configuration that maps specific customer IDs (CIDs) to designated hedge servers. The live configuration is stored in Maintenance.Feature (FeatureID=9) as an XML document. This history table preserves past states of that mapping, enabling audit of when specific customers were reassigned between hedge servers.

The XML structure is parsed by Internal.GetCustomerToHedgeServer using OPENXML with XPath `/ListCID/CIDToHedgeServerMapping`, extracting `HedgeServerID` and `CID` attributes. Each snapshot row is keyed by the UTC timestamp it was captured (Occurred).

The table is **empty in the current environment** (0 rows). Writer not found in SSDT repo - snapshots are likely created by external tooling or DBA scripts when the Maintenance.Feature FeatureID=9 configuration is updated.

---

## 2. Business Logic

### 2.1 XML Snapshot Structure

**What**: Each row contains the full CID-to-HedgeServer mapping as an XML document at a point in time.

**Columns/Parameters Involved**: `Occurred`, `XMLValue`

**Rules**:
- PK is Occurred (datetime with DEFAULT=getutcdate()) - one snapshot per timestamp
- XMLValue (xml type) - expected format based on Internal.GetCustomerToHedgeServer:
```xml
<ListCID>
  <CIDToHedgeServerMapping>
    <HedgeServerID>1</HedgeServerID>
    <CID>12345678</CID>
  </CIDToHedgeServerMapping>
  <CIDToHedgeServerMapping>
    ...
  </CIDToHedgeServerMapping>
</ListCID>
```

---

## 3. Data Overview

Table is empty in current environment (0 rows). In production, would contain timestamped XML snapshots of customer-to-hedge-server assignments.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Occurred | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when this snapshot was captured. PK. DEFAULT=GETUTCDATE(). One snapshot per timestamp. |
| 2 | XMLValue | xml | NO | - | VERIFIED | Full XML document of the CID-to-HedgeServer mapping at this point in time. Parsed by Internal.GetCustomerToHedgeServer with XPath `/ListCID/CIDToHedgeServerMapping`. Each child node has HedgeServerID and CID elements. Stored on TEXTIMAGE_ON [PRIMARY] filegroup (LOB storage). |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK relationships. The XML content references CIDs and HedgeServerIDs implicitly.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.GetCustomerToHedgeServer | XMLValue | Reader | Parses the XML mapping via OPENXML. Note: this procedure actually reads from Maintenance.Feature FeatureID=9 (live config), not from this history table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CIDToHedgeServerMapping (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No objects depend on this table in the current codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CIDToHedgeServerMapping | CLUSTERED PK | Occurred ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CIDToHedgeServerMapping | PRIMARY KEY CLUSTERED | Occurred |
| DF_CIDToHedgeServerMapping_Occurred | DEFAULT | Occurred = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Get most recent CID-to-HedgeServer mapping snapshot
```sql
SELECT TOP 1 Occurred, XMLValue
FROM History.CIDToHedgeServerMapping WITH (NOLOCK)
ORDER BY Occurred DESC;
```

### 8.2 Parse current mapping from Maintenance.Feature (live source)
```sql
DECLARE @Data XML
SELECT @Data = XMLValue FROM Maintenance.Feature WHERE FeatureID = 9
SELECT HedgeServerID, CID
FROM OPENXML((SELECT @Doc = 1), '/ListCID/CIDToHedgeServerMapping', 1)
-- Use Internal.GetCustomerToHedgeServer instead
EXEC Internal.GetCustomerToHedgeServer;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 8.5/10, Logic: 7.5/10, Relationships: 7.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CIDToHedgeServerMapping | Type: Table | Source: etoro/etoro/History/Tables/History.CIDToHedgeServerMapping.sql*
