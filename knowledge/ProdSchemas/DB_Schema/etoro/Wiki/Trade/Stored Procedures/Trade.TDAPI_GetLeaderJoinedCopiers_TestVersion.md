# Trade.TDAPI_GetLeaderJoinedCopiers_TestVersion

> Test variant of TDAPI_GetLeaderJoinedCopiers using the same three-stage pipeline as _After_2025 (#MirrorID -> #MirrorPnl [PnLInCents] -> #PositionData from Trade.Position) but WITHOUT the clustered indexes on the temp tables.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (test copier list variant, three-stage PnL pipeline, no temp table indexes) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a test copy of the `_After_2025` pipeline, used to evaluate the three-stage approach without the performance overhead of creating clustered indexes on temp tables.

The key difference from `_After_2025`: NO `CREATE clustered index` statements on #MirrorID or #MirrorPnl. This tests whether the clustered indexes actually improve performance on the three-stage pipeline.

The same unit inconsistency as _After_2025 applies: PnLInCents from Trade.PnL is stored as NetProfit in #PositionData, then mixed with m.NetProfit (dollars) in the NetProfitPercentage formula.

For full documentation, see: **[Trade.TDAPI_GetLeaderJoinedCopiers_After_2025](Trade.TDAPI_GetLeaderJoinedCopiers_After_2025.md)**

---

## 2. Key Differences from _After_2025

| Aspect | _After_2025 | _TestVersion |
|--------|-------------|-------------|
| Clustered index on #MirrorID | YES (IX_MirrorID) | NOT present |
| Clustered index on #MirrorPnl | YES (IX_MirrorPnl on CID,MirrorID) | NOT present |
| OPTION(RECOMPILE) on #PositionData INSERT | Not present | Not present |
| PnL unit | PnLInCents (same unit issue) | PnLInCents (same unit issue) |
| Everything else | Identical | Identical |

---

## 3-9. All Other Sections

Architecture, parameters, output: See **[Trade.TDAPI_GetLeaderJoinedCopiers_After_2025](Trade.TDAPI_GetLeaderJoinedCopiers_After_2025.md)**

Production baseline: **[Trade.TDAPI_GetLeaderJoinedCopiers](Trade.TDAPI_GetLeaderJoinedCopiers.md)**

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderJoinedCopiers_TestVersion | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_TestVersion.sql*
