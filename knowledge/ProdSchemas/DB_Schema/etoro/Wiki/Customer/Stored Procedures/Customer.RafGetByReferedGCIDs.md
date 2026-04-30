# Customer.RafGetByReferedGCIDs

> Bulk lookup: given a set of referred customer GCIDs, returns each referred customer's CID/GCID paired with their referring customer's CID/GCID; used by the RAF service to resolve referral chain identities.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReferredGCIDs - TVP of GCIDs to resolve |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RafGetByReferedGCIDs` provides identity resolution for the Refer-a-Friend (RAF) service. Given a batch of referred customer GCIDs (passed as a table-valued parameter), it returns the full CID/GCID pair for each referred customer alongside the CID/GCID of whoever referred them.

The LEFT JOIN on `ReferralID > 0` means the procedure returns all input GCIDs even if no referrer is on record - ReferringCID/ReferringGCID will be NULL for self-registered customers. This avoids silent data loss when the RAF service processes a mixed batch.

Created July 2023 (Noga Rozen, EDGE-2731) as part of the RAF microservice architecture, allowing the service to work with GCIDs (the external identity) while resolving to the CID (the internal identity) needed for compensation writes.

---

## 2. Business Logic

### 2.1 Referred-to-Referrer GCID/CID Mapping

**What**: Resolves a batch of referred GCIDs to their full referral identity pairs.

**Columns/Parameters Involved**: `@ReferredGCIDs` (TVP), `Customer.Customer.GCID`, `Customer.Customer.CID`, `Customer.Customer.ReferralID`

**Rules**:
- Input: `@ReferredGCIDs AS Customer.GCIDs ReadOnly` - TVP containing a set of GCIDs.
- INNER JOIN `Customer.Customer` on GCID to resolve referred CID/GCID.
- LEFT JOIN `Customer.Customer` again (aliased C2) on `C2.CID = C.ReferralID AND C.ReferralID > 0` to resolve the referring party.
- If a referred customer has no referrer (ReferralID = 0 or NULL), ReferringCID and ReferringGCID are NULL.

```
@ReferredGCIDs (TVP)
  -> INNER JOIN Customer.Customer (C) on GCID
       -> LEFT JOIN Customer.Customer (C2) on C.ReferralID = C2.CID (ReferralID > 0)
  -> Returns: ReferredGCID, ReferredCID, ReferringCID (nullable), ReferringGCID (nullable)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferredGCIDs | Customer.GCIDs | NO | - | CODE-BACKED | Table-valued parameter (TVP) of type Customer.GCIDs (BIGINT GCID column). ReadOnly. Contains the set of referred customer GCIDs to resolve. |

**Returned Columns:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | ReferredGCID | Customer.Customer.GCID (C) | Global ID of the referred customer (from input TVP match) |
| 2 | ReferredCID | Customer.Customer.CID (C) | Internal CID of the referred customer |
| 3 | ReferringCID | Customer.Customer.CID (C2) | Internal CID of the referring customer; NULL if no referrer |
| 4 | ReferringGCID | Customer.Customer.GCID (C2) | Global ID of the referring customer; NULL if no referrer |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReferredGCIDs | Customer.GCIDs | Parameter type | TVP type definition |
| C.GCID | Customer.Customer | READ | Resolves GCID -> CID for referred customer |
| C2.CID | Customer.Customer | READ | Resolves ReferralID -> CID/GCID for referring customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RAF microservice | External call | Caller | RAF service calls this to resolve GCIDs before processing compensation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RafGetByReferedGCIDs (procedure)
├── Customer.GCIDs (UDT) [PARAMETER TYPE - TVP definition]
└── Customer.Customer (view) [READ - twice: referred + referring identity]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.GCIDs | User Defined Type | TVP parameter type for @ReferredGCIDs |
| Customer.Customer | View | READ (twice) - maps GCID to CID for referred; maps ReferralID to CID/GCID for referring |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RAF service (external) | Microservice | Calls to resolve referred GCID batches |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ReferralID > 0 guard | Application | LEFT JOIN condition ensures NULL-ID self-referred rows don't match a real customer |
| ReadOnly TVP | Application | @ReferredGCIDs is ReadOnly - cannot be modified within the procedure |

---

## 8. Sample Queries

### 8.1 Test the procedure with specific GCIDs

```sql
-- Declare a test TVP
DECLARE @GCIDs Customer.GCIDs
INSERT INTO @GCIDs VALUES (123456789), (987654321)

EXEC Customer.RafGetByReferedGCIDs @GCIDs
```

### 8.2 Find referral pairs for a batch manually

```sql
SELECT
    C.GCID AS ReferredGCID,
    C.CID  AS ReferredCID,
    C2.CID  AS ReferringCID,
    C2.GCID AS ReferringGCID
FROM Customer.Customer C WITH (NOLOCK)
LEFT JOIN Customer.Customer C2 WITH (NOLOCK)
    ON C2.CID = C.ReferralID AND C.ReferralID > 0
WHERE C.GCID IN (123456789, 987654321)
```

### 8.3 Check customers with no referrer (self-registered)

```sql
SELECT
    C.CID,
    C.GCID,
    C.ReferralID
FROM Customer.Customer C WITH (NOLOCK)
WHERE C.ReferralID = 0 OR C.ReferralID IS NULL
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| EDGE-2731 | Jira | Created July 2023 (Noga Rozen) - new SP to get referring CIDs by referred GCID for RAF microservice |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RafGetByReferedGCIDs | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RafGetByReferedGCIDs.sql*
