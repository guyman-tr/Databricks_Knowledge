# Trade.TDAPI_GetLeaderJoinedCopiers_OLD

> Old version of TDAPI_GetLeaderJoinedCopiers using the pre-2025 PositionTbl+PositionTreeInfo+PnL pipeline with PartitionCol access and OPTION(RECOMPILE). Identical to _ForDebugB4_2025 except this version includes OPTION(RECOMPILE) on the #PositionData INSERT.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (old copier list, PositionTbl+TreeInfo+PnL+OPTION RECOMPILE) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the "OLD" variant of the copier list procedure, representing the original production code before the 2025 refactor. It uses the pre-2025 architecture:

1. `#PositionData` loaded from `Trade.PositionTbl JOIN Trade.PositionTreeInfo JOIN Trade.PnL` (PartitionCol access, StatusID=1 filter)
2. `OPTION(RECOMPILE)` on the #PositionData INSERT
3. `PnL.PnLInDollars` stored as `NetProfit` in #PositionData (correct dollar unit)

The only difference from `_ForDebugB4_2025` is that this version includes `OPTION(RECOMPILE)` on the INSERT.

For full documentation, see: **[Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025](Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025.md)**

The production current baseline is: **[Trade.TDAPI_GetLeaderJoinedCopiers](Trade.TDAPI_GetLeaderJoinedCopiers.md)**

---

## 2. Key Difference from _ForDebugB4_2025

| Aspect | _ForDebugB4_2025 | _OLD |
|--------|-----------------|------|
| OPTION(RECOMPILE) on INSERT | NOT present | YES - included |
| Everything else | Identical | Identical |

Both use: PositionTbl + PositionTreeInfo + PnL(PartitionCol=PositionID%50), StatusID=1 filter, PnLInDollars (correct unit).

---

## 3-9. All Other Sections

Architecture: See **[Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025](Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025.md)**

Parameters and output: Identical to all other TDAPI_GetLeaderJoinedCopiers variants. See **[Trade.TDAPI_GetLeaderJoinedCopiers](Trade.TDAPI_GetLeaderJoinedCopiers.md)**

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderJoinedCopiers_OLD | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_OLD.sql*
