# BackOffice.SetFunnel

> Updates the marketing funnel assignment for a customer in Customer.Customer, associating the account with a specific campaign or acquisition channel funnel.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetFunnel assigns a marketing funnel identifier to a customer account. The FunnelID tracks which marketing campaign, acquisition channel, or onboarding pathway the customer came through - used for campaign attribution, ROI analysis, and segment-specific marketing workflows.

The procedure resides in BackOffice schema despite writing to Customer.Customer, indicating it is called by BackOffice operations when correcting or manually assigning funnel attribution - for example when a customer's original tracking data was lost, when a campaign is retroactively attributed, or when a customer is migrated between marketing segments.

---

## 2. Business Logic

### 2.1 Direct Funnel Assignment

**What**: Simple single-column UPDATE on Customer.Customer.

**Columns/Parameters Involved**: `@CID`, `@FunnelID`

**Rules**:
- UPDATE Customer.Customer SET FunnelID=@FunnelID WHERE CID=@CID
- Returns @@ERROR (0=success, non-zero=SQL error)
- No validation of @FunnelID value against a lookup table in this procedure
- If @CID not found: 0 rows affected, @@ERROR=0, RETURN 0 (silent no-op)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | The customer whose funnel assignment is being updated. Must correspond to a CID in Customer.Customer. No validation - invalid CID results in 0-row no-op. |
| 2 | @FunnelID | INTEGER | NO | - | CODE-BACKED | The marketing funnel to assign. Written to Customer.Customer.FunnelID. FunnelID values correspond to marketing campaigns or acquisition channels tracked in the attribution system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | MODIFIER (UPDATE FunnelID) | Sets the marketing funnel for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice marketing/attribution workflows | - | Caller | Called to assign or correct marketing funnel attribution for a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetFunnel (procedure)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | UPDATE: SET FunnelID=@FunnelID WHERE CID=@CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice marketing attribution | External | Assigns or corrects campaign funnel for customer accounts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Assign a customer to a marketing funnel
```sql
DECLARE @Err INT
EXEC @Err = BackOffice.SetFunnel
    @CID     = 12345678,
    @FunnelID = 42
SELECT @Err AS ErrorCode
```

### 8.2 Find customers in a specific funnel
```sql
SELECT CID, FunnelID
FROM Customer.Customer WITH (NOLOCK)
WHERE FunnelID = 42
ORDER BY CID
```

### 8.3 Count customers by funnel
```sql
SELECT FunnelID, COUNT(*) AS CustomerCount
FROM Customer.Customer WITH (NOLOCK)
WHERE FunnelID IS NOT NULL
GROUP BY FunnelID
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetFunnel | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetFunnel.sql*
