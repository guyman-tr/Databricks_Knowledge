# Billing.WithdrawToFundingUpdateProtocolMidSettingsID

> Directly sets ProtocolMIDSettingsID on a WithdrawToFunding leg by ID; no validation, no history; returns @@ROWCOUNT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID INT - the Billing.WithdrawToFunding.ID to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure sets the `ProtocolMIDSettingsID` on a WithdrawToFunding leg. `ProtocolMIDSettingsID` identifies the specific Merchant ID (MID) configuration used to route the payment to the payment processor - the combination of protocol, mid string, and processor-specific settings defined in `Billing.ProtocolMIDSettings`.

The procedure is a minimal direct-UPDATE wrapper: no existence check, no status guard, no history logging. This is intentional for MID assignment - it is a routing metadata operation that must be callable at any stage and should not introduce transaction overhead. The `SELECT @@ROWCOUNT` return allows callers to detect silent failures (no matching ID).

`ProtocolMIDSettingsID` on `Billing.WithdrawToFunding` corresponds to the actual MID resolved by the payment routing engine - it translates the `Mid` string parameter (from `WithdrawToFundingProcess`) into a structured FK reference. This procedure is the update path for that field when re-routing is needed.

Created September 2020 by Elrom Behar.

---

## 2. Business Logic

### 2.1 Direct ProtocolMIDSettingsID Update

**What**: Sets the MID settings record for the payment routing on this WTF leg.

**Rules**:
- `UPDATE Billing.WithdrawToFunding SET ProtocolMIDSettingsID=@ProtocolMidSettingsID WHERE ID=@ID`
- No guards - works on any status, non-existent ID silently returns @@ROWCOUNT=0
- `SELECT @@ROWCOUNT` returned as a result set (1 = updated, 0 = ID not found)
- `@ProtocolMidSettingsID=0` default may indicate "no specific MID" or reset

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID` to update. No existence validation. |
| 2 | @ProtocolMidSettingsID | int | YES | 0 | CODE-BACKED | Input parameter. FK to `Billing.ProtocolMIDSettings`. Identifies the MID configuration for routing. 0 = default/none. |
| 3 | (result) | int | NO | - | CODE-BACKED | Output result set. `@@ROWCOUNT` - number of rows updated. 1 = success; 0 = ID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE) | Billing.WithdrawToFunding | Write | Direct UPDATE of ProtocolMIDSettingsID field |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingUpdateProtocolMidSettingsID (procedure)
+-- Billing.WithdrawToFunding (table) -- UPDATE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Direct UPDATE target for ProtocolMIDSettingsID |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by application code.

---

## 7. Technical Details

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the update

```sql
EXEC Billing.WithdrawToFundingUpdateProtocolMidSettingsID
    @ID                  = 12345,
    @ProtocolMidSettingsID = 7;
-- Returns 1 if updated, 0 if ID not found
```

### 8.2 Verify the assignment

```sql
SELECT ID, ProtocolMIDSettingsID, ModificationDate
FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE ID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingUpdateProtocolMidSettingsID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingUpdateProtocolMidSettingsID.sql*
