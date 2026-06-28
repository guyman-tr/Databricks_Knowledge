#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def _fetch_body(w, wid: str, proc: str) -> str:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND routine_name='{proc}'"
        ),
        warehouse_id=wid,
    )
    if not rows:
        raise RuntimeError(f"missing source procedure: {proc}")
    return str(rows[0][0] or "")


def _patch_main(body: str) -> str:
    out = body
    # Generic datediff(0, x) conversion for known transpiler artifacts.
    out = re.sub(
        r"DATEDIFF\s*\(\s*0\s*,\s*([A-Za-z_][A-Za-z0-9_\.]*)\s*\)",
        r"DATEDIFF(CAST(\1 AS DATE), DATE '1900-01-01')",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"DATEDIFF\s*\(\s*-1\s*,\s*([A-Za-z_][A-Za-z0-9_\.]*)\s*\)",
        r"DATEDIFF(CAST(\1 AS DATE), DATE '1899-12-31')",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"DATEADD\s*\(\s*DAY\s*,\s*DATEDIFF\s*\(\s*CAST\(([^)]+)\s+AS\s+DATE\)\s*,\s*DATE\s*'1900-01-01'\s*\)\s*,\s*0\s*\)",
        r"CAST(\1 AS DATE)",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"DATEADD\s*\(\s*DAY\s*,\s*DATEDIFF\s*\(\s*CAST\(([^)]+)\s+AS\s+DATE\)\s*,\s*DATE\s*'1899-12-31'\s*\)\s*,\s*0\s*\)",
        r"DATEADD(DAY, 1, CAST(\1 AS DATE))",
        out,
        flags=re.IGNORECASE,
    )
    # Explicit merge target names where transpiler left aliases.
    out = out.replace(
        "MERGE INTO c A_TGT USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLog a\nINNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_Real c ON a.PositionID = c.PositionID",
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_Real A_TGT USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLog a\nINNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_Real c ON a.PositionID = c.PositionID",
    )
    out = out.replace(
        "MERGE INTO c A_TGT USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLog a\nINNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real c ON a.PositionID = c.PositionID",
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real A_TGT USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_PositionChangeLog a\nINNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real c ON a.PositionID = c.PositionID",
    )
    # Ambiguous OpenDateID in MERGE ON clauses.
    out = re.sub(r"\bON\s+`?OpenDateID`?\s*=", "ON p.OpenDateID =", out, flags=re.IGNORECASE)
    out = re.sub(r"\bAND\s+`?OpenDateID`?\s*=", "AND p.OpenDateID =", out, flags=re.IGNORECASE)
    out = out.replace("COALESCE(OpenDateID::string", "COALESCE(p.OpenDateID::string")
    out = out.replace("AND p.OpenDateID =CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)", "AND OpenDateID =CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)")

    # Remove Synapse-only stats block.
    out = re.sub(
        r"SET\s+V_upsts\s*=\s*\([\s\S]*?END IF;",
        "SET V_upsts = NULL;",
        out,
        flags=re.IGNORECASE,
    )

    # Fix malformed timestamp sentinel.
    out = out.replace("a.CloseOccurred = '19000101'", "a.CloseOccurred = TIMESTAMP '1900-01-01 00:00:00'")
    out = out.replace("THEN '19000101' else b.CloseOccurred end", "THEN TIMESTAMP '1900-01-01 00:00:00' else b.CloseOccurred end")
    out = re.sub(
        r"THEN\s*'19000101'\s*ELSE\s*b\.CloseOccurred",
        "THEN TIMESTAMP '1900-01-01 00:00:00' ELSE b.CloseOccurred",
        out,
        flags=re.IGNORECASE,
    )

    # Deterministic merge for switch table update.
    out = out.replace("MERGE INTO t A_TGT USING (", "MERGE INTO dwh_daily_process.migration_tables.Dim_Position_SWITCH_SINGLE A_TGT USING (")
    out = out.replace(")\nON 1 = 1", "QUALIFY ROW_NUMBER() OVER (PARTITION BY t.PositionID ORDER BY 1) = 1\n)\nON t.PositionID = A_TGT.PositionID")
    out = out.replace("t.DLTOpen = s.DLTOpen", "A_TGT.DLTOpen = s.DLTOpen")
    out = out.replace("t.OpenMarkupByUnits = s.OpenMarkupByUnits", "A_TGT.OpenMarkupByUnits = s.OpenMarkupByUnits")
    out = out.replace("t.CommissionVersion = s.CommissionVersion", "A_TGT.CommissionVersion = s.CommissionVersion")
    out = out.replace("t.LotCountDecimal = s.LotCountDecimal", "A_TGT.LotCountDecimal = s.LotCountDecimal")
    out = out.replace("t.OpenPositionReasonID = s.OpenPositionReasonID", "A_TGT.OpenPositionReasonID = s.OpenPositionReasonID")
    out = out.replace("t.OpenTotalTaxes = s.OpenTotalTaxes", "A_TGT.OpenTotalTaxes = s.OpenTotalTaxes")
    out = out.replace("t.OpenTotalFees = s.OpenTotalFees", "A_TGT.OpenTotalFees = s.OpenTotalFees")
    out = out.replace("t.EstimateCloseFeeForCFD = s.EstimateCloseFeeForCFD", "A_TGT.EstimateCloseFeeForCFD = s.EstimateCloseFeeForCFD")
    out = out.replace("t.EstimateCloseFeeOnOpenByUnits = s.EstimateCloseFeeOnOpenByUnits", "A_TGT.EstimateCloseFeeOnOpenByUnits = s.EstimateCloseFeeOnOpenByUnits")
    out = out.replace("t.EstimateCloseFeeOnOpen = s.EstimateCloseFeeOnOpen", "A_TGT.EstimateCloseFeeOnOpen = s.EstimateCloseFeeOnOpen")
    out = out.replace("t.Close_PnLInDollars = s.Close_PnLInDollars", "A_TGT.Close_PnLInDollars = s.Close_PnLInDollars")
    out = out.replace("t.Close_CalculationRate = s.Close_CalculationRate", "A_TGT.Close_CalculationRate = s.Close_CalculationRate")
    out = out.replace("t.Close_ConversionRate = s.Close_ConversionRate", "A_TGT.Close_ConversionRate = s.Close_ConversionRate")
    out = out.replace("t.Close_PriceType = s.Close_PriceType", "A_TGT.Close_PriceType = s.Close_PriceType")
    out = out.replace("t.CurrentCalculationRate = s.CurrentCalculationRate", "A_TGT.CurrentCalculationRate = s.CurrentCalculationRate")
    out = out.replace("t.CurrentConversionRate = s.CurrentConversionRate", "A_TGT.CurrentConversionRate = s.CurrentConversionRate")

    # Price enrichment merges deduped on PositionID.
    out = out.replace(
        "INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON a.PriceRateID = p.CloseMarketPriceRateID AND a.InstrumentID = p.InstrumentID AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.CloseDateID AS STRING) AS date)) AND CAST(CAST(p.CloseDateID AS STRING) AS date)\n)",
        "INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON a.PriceRateID = p.CloseMarketPriceRateID AND a.InstrumentID = p.InstrumentID AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.CloseDateID AS STRING) AS date)) AND CAST(CAST(p.CloseDateID AS STRING) AS date)\nQUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY a.Occurred DESC) = 1\n)",
    )
    out = out.replace(
        "INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON MarketPriceRateID = p.CloseMarketPriceRateID AND a.InstrumentID = p.InstrumentID\n)",
        "INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON MarketPriceRateID = p.CloseMarketPriceRateID AND a.InstrumentID = p.InstrumentID\nQUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY a.Occurred DESC) = 1\n)",
    )
    out = out.replace(
        "INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON a.PriceRateID = p.OpenMarketPriceRateID AND a.InstrumentID = p.InstrumentID AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.OpenDateID AS STRING) AS date)) AND CAST(CAST(p.OpenDateID AS STRING) AS date)\n)",
        "INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON a.PriceRateID = p.OpenMarketPriceRateID AND a.InstrumentID = p.InstrumentID AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.OpenDateID AS STRING) AS date)) AND CAST(CAST(p.OpenDateID AS STRING) AS date)\nQUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY a.Occurred DESC) = 1\n)",
    )
    out = out.replace(
        "INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON MarketPriceRateID = p.OpenMarketPriceRateID AND a.InstrumentID = p.InstrumentID\n)",
        "INNER JOIN dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active_5_days a ON MarketPriceRateID = p.OpenMarketPriceRateID AND a.InstrumentID = p.InstrumentID\nQUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY a.Occurred DESC) = 1\n)",
    )
    out = out.replace(
        "ON CloseMarket_AskSpreaded IS NULL AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.CloseDateID AS STRING) AS date)) AND CAST(CAST(p.CloseDateID AS STRING) AS date) and p.CloseDateID = CAST ( date_format(V_Yesterday, 'yyyyMMdd') AS INT )",
        "ON p_TGT.CloseMarket_AskSpreaded IS NULL AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.CloseDateID AS STRING) AS date)) AND CAST(CAST(p.CloseDateID AS STRING) AS date) and p.CloseDateID = CAST ( date_format(V_Yesterday, 'yyyyMMdd') AS INT )",
    )
    out = out.replace(
        "ON OpenMarket_Ask IS NULL AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.OpenDateID AS STRING) AS date)) AND CAST(CAST(p.OpenDateID AS STRING) AS date) and p.OpenDateID = CAST ( date_format(V_Yesterday, 'yyyyMMdd') AS INT )",
        "ON p_TGT.OpenMarket_Ask IS NULL AND CAST(a.Occurred AS date) BETWEEN DATEADD(DAY, - 5, CAST(CAST(p.OpenDateID AS STRING) AS date)) AND CAST(CAST(p.OpenDateID AS STRING) AS date) and p.OpenDateID = CAST ( date_format(V_Yesterday, 'yyyyMMdd') AS INT )",
    )
    # Databricks doesn't support the correlated EXISTS(SELECT ... EXCEPT SELECT ...) join predicate.
    out = re.sub(
        r"\s+AND EXISTS\s*\(\s*SELECT[\s\S]*?\)\s*--Back Partition to Dim_Position",
        "",
        out,
        flags=re.IGNORECASE,
    )

    # Route helper calls to full autopoc helper variants.
    out = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.SP_Dim_Position_HedgeType_History\s*\(",
        "call dwh_daily_process.migration_tables.sp_dim_position_hedgetype_history_autopoc(",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.SP_Dim_Position_HedgeType_Real\s*\(",
        "call dwh_daily_process.migration_tables.sp_dim_position_hedgetype_real_autopoc(",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.SP_Dim_Position_ReOpen\s*\(",
        "call dwh_daily_process.migration_tables.sp_dim_position_reopen_autopoc(",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.SP_Dim_Position_IsPartialCloseParent\s*\(",
        "call dwh_daily_process.migration_tables.sp_dim_position_ispartialcloseparent_autopoc(",
        out,
        flags=re.IGNORECASE,
    )

    # CurrencyPrice_Active merges: ON clause used rate-ID equality (Synapse allows multi-match;
    # Delta rejects it).  Fix: add QUALIFY + change ON to PositionID equality.
    # MERGE 1 — Ext_Dim_Position_Real + Active price on InitForexPriceRateID
    out = out.replace(
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_Real p\n"
        "INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.InitForexPriceRateID ----------------------------------------------------------------->\n"
        " -- Update Ext_Dim_Position_History - CurrencyPrice_Active ------------>\n"
        "\n"
        ")\n"
        "ON \n"
        "COALESCE(p.InitForexPriceRateID::string,'__NULL__') = COALESCE(p_TGT.InitForexPriceRateID::string,'__NULL__')\n",
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_Real p\n"
        "INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.InitForexPriceRateID\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY 1) = 1\n"
        ")\n"
        "ON p.PositionID = p_TGT.PositionID\n",
    )
    # MERGE 2 — Ext_Dim_Position_History_Real + Active price on InitForexPriceRateID (with date scope)
    out = out.replace(
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.InitForexPriceRateID\n"
        ")\n"
        "ON p.OpenDateID = date_format(CAST ( V_Yesterday as date ), 'yyyyMMdd') AND \n"
        "COALESCE(p.InitForexPriceRateID::string,'__NULL__') = COALESCE(p_TGT.InitForexPriceRateID::string,'__NULL__')\n",
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.InitForexPriceRateID\n"
        "WHERE p.OpenDateID = CAST(date_format(CAST(V_Yesterday AS DATE), 'yyyyMMdd') AS INT)\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY 1) = 1\n"
        ")\n"
        "ON p.PositionID = p_TGT.PositionID\n",
    )
    # MERGE 3 — Ext_Dim_Position_History_Real + Active price on EndForexPriceRateID
    out = out.replace(
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.EndForexPriceRateID ----------------------------------------------------------------->\n"
        " -- Ext_Dim_Position_HBCExecutionLog ------------------------------>\n"
        "\n"
        ")\n"
        "ON \n"
        "COALESCE(p.EndForexPriceRateID::string,'__NULL__') = COALESCE(p_TGT.EndForexPriceRateID::string,'__NULL__')\n",
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_CurrencyPrice_Active a ON a.PriceRateID = p.EndForexPriceRateID\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY 1) = 1\n"
        ")\n"
        "ON p.PositionID = p_TGT.PositionID\n",
    )

    # Broad safety net: any MERGE USING subquery without QUALIFY gets dedup by source PositionID.
    def _dedupe_merge_source(match: re.Match[str]) -> str:
        full = match.group(0)
        from_head = match.group(1)
        alias = match.group(2)
        middle = match.group(3)
        if "QUALIFY ROW_NUMBER()" in middle.upper():
            return full
        if "PositionID" not in middle and "PositionID" not in from_head:
            return full
        return (
            "USING (\nSELECT * \nFROM "
            + from_head
            + " "
            + alias
            + middle
            + f"\nQUALIFY ROW_NUMBER() OVER (PARTITION BY {alias}.PositionID ORDER BY 1) = 1\n)\nON"
        )

    out = re.sub(
        r"USING\s*\(\s*SELECT \*\s*FROM\s+([^\n]+?)\s+([A-Za-z_][A-Za-z0-9_]*)\b([\s\S]*?)\)\s*ON",
        _dedupe_merge_source,
        out,
        flags=re.IGNORECASE,
    )
    return out


def _patch_helper(body: str) -> str:
    out = body
    out = re.sub(r"\bON\s+`?OpenDateID`?\b", "ON p.OpenDateID", out, flags=re.IGNORECASE)
    out = re.sub(r"\bAND\s+`?OpenDateID`?\b", "AND p.OpenDateID", out, flags=re.IGNORECASE)
    out = re.sub(r"\bON\s+`?CloseDateID`?\b", "ON p.CloseDateID", out, flags=re.IGNORECASE)
    out = re.sub(r"\bAND\s+`?CloseDateID`?\b", "AND p.CloseDateID", out, flags=re.IGNORECASE)
    # Deterministic rewrites for hedge-type helper merges (avoid execution-id fanout).
    out = out.replace(
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT\n"
        "USING (\n"
        "SELECT * \n"
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID\n"
        ")\n"
        "ON p.OpenDateID < V_datnexteid AND p.CloseDateID = V_dateid AND \n"
        "COALESCE(p.EndExecutionID::string,'__NULL__') = COALESCE(p_TGT.EndExecutionID::string,'__NULL__')\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "EndHedgeType = CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;",
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT\n"
        "USING (\n"
        "SELECT p.PositionID,\n"
        "       CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS EndHedgeType\n"
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa ON p.EndExecutionID = aa.ExecutionID\n"
        "WHERE p.OpenDateID < V_datnexteid\n"
        "  AND p.CloseDateID = V_dateid\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.OpenOccurred DESC) = 1\n"
        ") s\n"
        "ON s.PositionID = p_TGT.PositionID\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "EndHedgeType = s.EndHedgeType;",
    )
    out = out.replace(
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT\n"
        "USING (\n"
        "SELECT * \n"
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID\n"
        ")\n"
        "ON p.OpenDateID >= V_dateid AND p.CloseDateID = V_dateid AND \n"
        "COALESCE(p.InitExecutionID::string,'__NULL__') = COALESCE(p_TGT.InitExecutionID::string,'__NULL__') AND \n"
        "COALESCE(p.EndExecutionID::string,'__NULL__') = COALESCE(p_TGT.EndExecutionID::string,'__NULL__')\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "InitHedgeType = CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END ,\n"
        "EndHedgeType = CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;",
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT\n"
        "USING (\n"
        "SELECT p.PositionID,\n"
        "       CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS InitHedgeType,\n"
        "       CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS EndHedgeType\n"
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a ON p.InitExecutionID = a.ExecutionID\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa ON p.EndExecutionID = aa.ExecutionID\n"
        "WHERE p.OpenDateID >= V_dateid\n"
        "  AND p.CloseDateID = V_dateid\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.OpenOccurred DESC) = 1\n"
        ") s\n"
        "ON s.PositionID = p_TGT.PositionID\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "InitHedgeType = s.InitHedgeType,\n"
        "EndHedgeType = s.EndHedgeType;",
    )
    out = out.replace(
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT\n"
        "USING (\n"
        "SELECT * \n"
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n"
        ")\n"
        "ON p.OpenDateID >= V_dateid AND p.CloseDateID > V_dateid AND \n"
        "COALESCE(p.InitExecutionID::string,'__NULL__') = COALESCE(p_TGT.InitExecutionID::string,'__NULL__')\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "InitHedgeType = CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;",
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT\n"
        "USING (\n"
        "SELECT p.PositionID,\n"
        "       CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS InitHedgeType\n"
        "FROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a ON p.InitExecutionID = a.ExecutionID\n"
        "WHERE p.OpenDateID >= V_dateid\n"
        "  AND p.CloseDateID > V_dateid\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.OpenOccurred DESC) = 1\n"
        ") s\n"
        "ON s.PositionID = p_TGT.PositionID\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "InitHedgeType = s.InitHedgeType;",
    )

    # Helper source dedupe for remaining merge blocks.
    out = out.replace(
        "USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID\n)",
        "USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY COALESCE(CAST(p.EndExecutionID AS STRING), '__NULL__') ORDER BY p.OpenOccurred DESC) = 1\n)",
    )
    out = out.replace(
        "USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID\n)",
        "USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID\n"
        "QUALIFY ROW_NUMBER() OVER (\n"
        "  PARTITION BY COALESCE(CAST(p.InitExecutionID AS STRING), '__NULL__'), COALESCE(CAST(p.EndExecutionID AS STRING), '__NULL__')\n"
        "  ORDER BY p.OpenOccurred DESC\n"
        ") = 1\n)",
    )
    out = out.replace(
        "USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n)",
        "USING (\nSELECT * \nFROM dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY COALESCE(CAST(p.InitExecutionID AS STRING), '__NULL__') ORDER BY p.OpenOccurred DESC) = 1\n)",
    )
    out = out.replace(
        "USING (\nSELECT * \nfrom dwh_daily_process.migration_tables.Ext_Dim_Position_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n)",
        "USING (\nSELECT * \nfrom dwh_daily_process.migration_tables.Ext_Dim_Position_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY COALESCE(CAST(p.InitExecutionID AS STRING), '__NULL__') ORDER BY p.OpenOccurred DESC) = 1\n)",
    )
    out = re.sub(
        r"MERGE INTO dwh_daily_process\.migration_tables\.Ext_Dim_Position_History_Real p_TGT\s+USING\s*\(\s*SELECT \*\s*from dwh_daily_process\.migration_tables\.Ext_Dim_Position_History_Real p\s*LEFT JOIN dwh_daily_process\.migration_tables\.Ext_Dim_Position_HBCExecutionLog aa on p\.EndExecutionID = aa\.ExecutionID\s*\)\s*ON p\.OpenDateID < V_datnexteid AND p\.CloseDateID = V_dateid AND\s*COALESCE\(p\.EndExecutionID::string,'__NULL__'\) = COALESCE\(p_TGT\.EndExecutionID::string,'__NULL__'\)\s*WHEN MATCHED THEN UPDATE SET\s*EndHedgeType = CASE WHEN aa\.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;",
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT\n"
        "USING (\n"
        "SELECT p.PositionID,\n"
        "       CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS EndHedgeType\n"
        "from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID\n"
        "WHERE p.OpenDateID < V_datnexteid\n"
        "  AND p.CloseDateID = V_dateid\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.OpenOccurred DESC) = 1\n"
        ") s\n"
        "ON s.PositionID = p_TGT.PositionID\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "EndHedgeType = s.EndHedgeType;",
        out,
        flags=re.IGNORECASE | re.DOTALL,
    )
    out = re.sub(
        r"MERGE INTO dwh_daily_process\.migration_tables\.Ext_Dim_Position_History_Real p_TGT\s+USING\s*\(\s*SELECT \*\s*from dwh_daily_process\.migration_tables\.Ext_Dim_Position_History_Real p\s*LEFT JOIN dwh_daily_process\.migration_tables\.Ext_Dim_Position_HBCExecutionLog a on p\.InitExecutionID = a\.ExecutionID\s*LEFT JOIN dwh_daily_process\.migration_tables\.Ext_Dim_Position_HBCExecutionLog aa on p\.EndExecutionID = aa\.ExecutionID\s*\)\s*ON p\.OpenDateID >= V_dateid AND p\.CloseDateID = V_dateid AND\s*COALESCE\(p\.InitExecutionID::string,'__NULL__'\) = COALESCE\(p_TGT\.InitExecutionID::string,'__NULL__'\) AND\s*COALESCE\(p\.EndExecutionID::string,'__NULL__'\) = COALESCE\(p_TGT\.EndExecutionID::string,'__NULL__'\)\s*WHEN MATCHED THEN UPDATE SET\s*InitHedgeType = CASE WHEN a\.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END\s*,\s*EndHedgeType = CASE WHEN aa\.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;",
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT\n"
        "USING (\n"
        "SELECT p.PositionID,\n"
        "       CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS InitHedgeType,\n"
        "       CASE WHEN aa.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS EndHedgeType\n"
        "from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog aa on p.EndExecutionID = aa.ExecutionID\n"
        "WHERE p.OpenDateID >= V_dateid\n"
        "  AND p.CloseDateID = V_dateid\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.OpenOccurred DESC) = 1\n"
        ") s\n"
        "ON s.PositionID = p_TGT.PositionID\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "InitHedgeType = s.InitHedgeType,\n"
        "EndHedgeType = s.EndHedgeType;",
        out,
        flags=re.IGNORECASE | re.DOTALL,
    )
    out = re.sub(
        r"MERGE INTO dwh_daily_process\.migration_tables\.Ext_Dim_Position_History_Real p_TGT\s+USING\s*\(\s*SELECT \*\s*from dwh_daily_process\.migration_tables\.Ext_Dim_Position_History_Real p\s*LEFT JOIN dwh_daily_process\.migration_tables\.Ext_Dim_Position_HBCExecutionLog a on p\.InitExecutionID = a\.ExecutionID\s*\)\s*ON p\.OpenDateID >= V_dateid AND p\.CloseDateID > V_dateid AND\s*COALESCE\(p\.InitExecutionID::string,'__NULL__'\) = COALESCE\(p_TGT\.InitExecutionID::string,'__NULL__'\)\s*WHEN MATCHED THEN UPDATE SET\s*InitHedgeType = CASE WHEN a\.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END;",
        "MERGE INTO dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p_TGT\n"
        "USING (\n"
        "SELECT p.PositionID,\n"
        "       CASE WHEN a.ExecutionID IS NOT NULL THEN 'HBC' ELSE 'CBH' END AS InitHedgeType\n"
        "from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real p\n"
        "LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Position_HBCExecutionLog a on p.InitExecutionID = a.ExecutionID\n"
        "WHERE p.OpenDateID >= V_dateid\n"
        "  AND p.CloseDateID > V_dateid\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY p.OpenOccurred DESC) = 1\n"
        ") s\n"
        "ON s.PositionID = p_TGT.PositionID\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "InitHedgeType = s.InitHedgeType;",
        out,
        flags=re.IGNORECASE | re.DOTALL,
    )
    out = out.replace(
        "and ap.OpenDateID>= V_MinOpenDateID;",
        "and ap.OpenDateID >= (select min(OpenDateID) from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real);",
    )
    out = out.replace(
        "and ap.OpenDateID>=V_MinOpenDateID;",
        "and ap.OpenDateID >= (select min(OpenDateID) from dwh_daily_process.migration_tables.Ext_Dim_Position_History_Real);",
    )
    return out


def _patch_reopen(body: str) -> str:
    out = body
    out = out.replace(
        "and CloseDateID = V_dateid)",
        "and CloseDateID = CAST(date_format(DATEADD(day, -1, current_date()), 'yyyyMMdd') AS int))",
    )
    out = out.replace(
        "MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT\n"
        "USING (\n"
        "SELECT * \n"
        "from dwh_daily_process.migration_tables.Dim_Position a\n"
        "INNER JOIN TEMP_TABLE_IsPartialCloseChildFromReOpen b on a.PositionID = b.PositionID\n"
        "\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1\n"
        ")\n"
        "ON a.PositionID = a_TGT.PositionID\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "IsPartialCloseChildFromReOpen = 1;",
        "UPDATE dwh_daily_process.migration_tables.Dim_Position\n"
        "SET IsPartialCloseChildFromReOpen = CASE\n"
        "      WHEN PositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen) THEN 1\n"
        "      ELSE IsPartialCloseChildFromReOpen\n"
        "    END;",
    )
    out = out.replace(
        "MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT\n"
        "USING (\n"
        "SELECT * \n"
        "from dwh_daily_process.migration_tables.Dim_Position a\n"
        "INNER JOIN TEMP_TABLE_IsPartialCloseChildFromReOpen b on a.OriginalPositionID = b.PositionID\n"
        "\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY a.OriginalPositionID ORDER BY 1) = 1\n"
        ")\n"
        "ON a.OriginalPositionID = a_TGT.OriginalPositionID\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "IsPartialCloseChildFromReOpen = 1 ,\n"
        "CommissionOnCloseOrig = a.CommissionOnClose ,\n"
        "FullCommissionOnCloseOrig = a.FullCommissionOnClose;",
        "UPDATE dwh_daily_process.migration_tables.Dim_Position\n"
        "SET IsPartialCloseChildFromReOpen = CASE\n"
        "      WHEN OriginalPositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen) THEN 1\n"
        "      ELSE IsPartialCloseChildFromReOpen\n"
        "    END,\n"
        "    CommissionOnCloseOrig = CASE\n"
        "      WHEN OriginalPositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen) THEN CommissionOnClose\n"
        "      ELSE CommissionOnCloseOrig\n"
        "    END,\n"
        "    FullCommissionOnCloseOrig = CASE\n"
        "      WHEN OriginalPositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen) THEN FullCommissionOnClose\n"
        "      ELSE FullCommissionOnCloseOrig\n"
        "    END;",
    )
    out = out.replace(
        "MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT\n"
        "USING (\n"
        "SELECT * \n"
        "from dwh_daily_process.migration_tables.Dim_Position a\n"
        "INNER JOIN TEMP_TABLE_ReopenForPosition b on a.PositionID = b.PositionID -- postion for update \n"
        "\n"
        "INNER JOIN TEMP_TABLE_PositionOrigin c on b.ReopenForPositionID = c.PositionID -- data from origin position \n"
        "\n"
        "\n"
        "QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1\n"
        ")\n"
        "ON a.PositionID = a_TGT.PositionID\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "CommissionOnClose = b.CommissionOnClose - c.CommissionOnClose * ( a.AmountInUnitsDecimal / a.InitialUnits ) ,\n"
        "FullCommissionOnClose = b.FullCommissionOnClose - c.FullCommissionOnClose * ( a.AmountInUnitsDecimal / a.InitialUnits );",
        "UPDATE dwh_daily_process.migration_tables.Dim_Position a_TGT\n"
        "SET CommissionOnClose = CASE\n"
        "      WHEN EXISTS (SELECT 1 FROM TEMP_TABLE_ReopenForPosition b WHERE b.PositionID = a_TGT.PositionID)\n"
        "      THEN (\n"
        "        SELECT b.CommissionOnClose - c.CommissionOnClose * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits)\n"
        "        FROM TEMP_TABLE_ReopenForPosition b\n"
        "        INNER JOIN TEMP_TABLE_PositionOrigin c ON b.ReopenForPositionID = c.PositionID\n"
        "        WHERE b.PositionID = a_TGT.PositionID\n"
        "        LIMIT 1\n"
        "      )\n"
        "      ELSE CommissionOnClose\n"
        "    END,\n"
        "    FullCommissionOnClose = CASE\n"
        "      WHEN EXISTS (SELECT 1 FROM TEMP_TABLE_ReopenForPosition b WHERE b.PositionID = a_TGT.PositionID)\n"
        "      THEN (\n"
        "        SELECT b.FullCommissionOnClose - c.FullCommissionOnClose * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits)\n"
        "        FROM TEMP_TABLE_ReopenForPosition b\n"
        "        INNER JOIN TEMP_TABLE_PositionOrigin c ON b.ReopenForPositionID = c.PositionID\n"
        "        WHERE b.PositionID = a_TGT.PositionID\n"
        "        LIMIT 1\n"
        "      )\n"
        "      ELSE FullCommissionOnClose\n"
        "    END;",
    )
    out = out.replace(
        " MERGE INTO dwh_daily_process.migration_tables.Dim_Position a_TGT\n"
        "USING (\n"
        "SELECT * \n"
        "from dwh_daily_process.migration_tables.Dim_Position a\n"
        "INNER JOIN TEMP_TABLE_IsPartialCloseChildFromReOpen b on b.PositionID = a.OriginalPositionID\n"
        "INNER JOIN dwh_daily_process.migration_tables.Dim_Position c on a.OriginalPositionID = c.PositionID\n"
        "INNER JOIN dwh_daily_process.migration_tables.Dim_Position e on e.PositionID = c.ReopenForPositionID\n"
        ")\n"
        "ON a.CloseOccurred <> '1900-01-01 00:00:00.000' AND \n"
        "COALESCE(a.CommissionOnCloseOrig::string,'__NULL__') = COALESCE(a_TGT.CommissionOnCloseOrig::string,'__NULL__') AND \n"
        "COALESCE(a.AmountInUnitsDecimal::string,'__NULL__') = COALESCE(a_TGT.AmountInUnitsDecimal::string,'__NULL__') AND \n"
        "COALESCE(a.InitialUnits::string,'__NULL__') = COALESCE(a_TGT.InitialUnits::string,'__NULL__') AND \n"
        "COALESCE(a.FullCommissionOnCloseOrig::string,'__NULL__') = COALESCE(a_TGT.FullCommissionOnCloseOrig::string,'__NULL__') AND \n"
        "COALESCE(a.OriginalPositionID::string,'__NULL__') = COALESCE(a_TGT.OriginalPositionID::string,'__NULL__') AND \n"
        "COALESCE(a.CloseOccurred::string,'__NULL__') = COALESCE(a_TGT.CloseOccurred::string,'__NULL__')\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "CommissionOnClose = a.CommissionOnCloseOrig - e.CommissionOnClose * ( a.AmountInUnitsDecimal / a.InitialUnits ) ,\n"
        "FullCommissionOnClose = a.FullCommissionOnCloseOrig - e.FullCommissionOnClose * ( a.AmountInUnitsDecimal / a.InitialUnits );",
        "UPDATE dwh_daily_process.migration_tables.Dim_Position a_TGT\n"
        "SET CommissionOnClose = a_TGT.CommissionOnCloseOrig - (\n"
        "      SELECT e.CommissionOnClose\n"
        "      FROM dwh_daily_process.migration_tables.Dim_Position c\n"
        "      INNER JOIN dwh_daily_process.migration_tables.Dim_Position e ON e.PositionID = c.ReopenForPositionID\n"
        "      WHERE c.PositionID = a_TGT.OriginalPositionID\n"
        "      LIMIT 1\n"
        "    ) * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits),\n"
        "    FullCommissionOnClose = a_TGT.FullCommissionOnCloseOrig - (\n"
        "      SELECT e.FullCommissionOnClose\n"
        "      FROM dwh_daily_process.migration_tables.Dim_Position c\n"
        "      INNER JOIN dwh_daily_process.migration_tables.Dim_Position e ON e.PositionID = c.ReopenForPositionID\n"
        "      WHERE c.PositionID = a_TGT.OriginalPositionID\n"
        "      LIMIT 1\n"
        "    ) * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits)\n"
        "WHERE a_TGT.CloseOccurred <> '1900-01-01 00:00:00.000'\n"
        "  AND a_TGT.OriginalPositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen);",
    )
    out = out.replace(
        "UPDATE dwh_daily_process.migration_tables.Dim_Position a_TGT\n"
        "SET CommissionOnClose = a_TGT.CommissionOnCloseOrig - (\n"
        "      SELECT e.CommissionOnClose\n"
        "      FROM dwh_daily_process.migration_tables.Dim_Position c\n"
        "      INNER JOIN dwh_daily_process.migration_tables.Dim_Position e ON e.PositionID = c.ReopenForPositionID\n"
        "      WHERE c.PositionID = a_TGT.OriginalPositionID\n"
        "      LIMIT 1\n"
        "    ) * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits),\n"
        "    FullCommissionOnClose = a_TGT.FullCommissionOnCloseOrig - (\n"
        "      SELECT e.FullCommissionOnClose\n"
        "      FROM dwh_daily_process.migration_tables.Dim_Position c\n"
        "      INNER JOIN dwh_daily_process.migration_tables.Dim_Position e ON e.PositionID = c.ReopenForPositionID\n"
        "      WHERE c.PositionID = a_TGT.OriginalPositionID\n"
        "      LIMIT 1\n"
        "    ) * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits)\n"
        "WHERE a_TGT.CloseOccurred <> '1900-01-01 00:00:00.000'\n"
        "  AND a_TGT.OriginalPositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen);",
        "DROP VIEW IF EXISTS TEMP_TABLE_ReopenParentCommission;\n"
        "CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ReopenParentCommission AS\n"
        "SELECT c.PositionID AS OriginalPositionID,\n"
        "       e.CommissionOnClose AS ParentCommissionOnClose,\n"
        "       e.FullCommissionOnClose AS ParentFullCommissionOnClose\n"
        "FROM dwh_daily_process.migration_tables.Dim_Position c\n"
        "INNER JOIN dwh_daily_process.migration_tables.Dim_Position e ON e.PositionID = c.ReopenForPositionID;\n"
        "UPDATE dwh_daily_process.migration_tables.Dim_Position a_TGT\n"
        "SET CommissionOnClose = CASE\n"
        "      WHEN a_TGT.CloseOccurred <> '1900-01-01 00:00:00.000'\n"
        "       AND a_TGT.OriginalPositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen)\n"
        "      THEN a_TGT.CommissionOnCloseOrig - (\n"
        "        SELECT r.ParentCommissionOnClose\n"
        "        FROM TEMP_TABLE_ReopenParentCommission r\n"
        "        WHERE r.OriginalPositionID = a_TGT.OriginalPositionID\n"
        "        LIMIT 1\n"
        "      ) * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits)\n"
        "      ELSE CommissionOnClose\n"
        "    END,\n"
        "    FullCommissionOnClose = CASE\n"
        "      WHEN a_TGT.CloseOccurred <> '1900-01-01 00:00:00.000'\n"
        "       AND a_TGT.OriginalPositionID IN (SELECT PositionID FROM TEMP_TABLE_IsPartialCloseChildFromReOpen)\n"
        "      THEN a_TGT.FullCommissionOnCloseOrig - (\n"
        "        SELECT r.ParentFullCommissionOnClose\n"
        "        FROM TEMP_TABLE_ReopenParentCommission r\n"
        "        WHERE r.OriginalPositionID = a_TGT.OriginalPositionID\n"
        "        LIMIT 1\n"
        "      ) * (a_TGT.AmountInUnitsDecimal / a_TGT.InitialUnits)\n"
        "      ELSE FullCommissionOnClose\n"
        "    END;",
    )
    out = out.replace(
        "DROP VIEW IF EXISTS TEMP_TABLE_PositionOrigin;\nDROP VIEW IF EXISTS TEMP_TABLE_ReopenForPosition;",
        "DROP VIEW IF EXISTS TEMP_TABLE_PositionOrigin;\nDROP VIEW IF EXISTS TEMP_TABLE_ReopenParentCommission;\nDROP VIEW IF EXISTS TEMP_TABLE_ReopenForPosition;",
    )
    return out


def _create_proc(w, wid: str, name: str, sig: str, body: str) -> None:
    sql = (
        "CREATE OR REPLACE PROCEDURE "
        f"dwh_daily_process.migration_tables.{name}({sig}) "
        "LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)


def _create_proc_no_sig(w, wid: str, name: str, body: str) -> None:
    sql = (
        "CREATE OR REPLACE PROCEDURE "
        f"dwh_daily_process.migration_tables.{name}() "
        "LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    main = _patch_main(_fetch_body(w, wid, "sp_dim_position_dl_to_synapse"))
    _create_proc(w, wid, "sp_dim_position_dl_to_synapse_autopoc", "V_dt TIMESTAMP", main)
    print("created_or_updated=sp_dim_position_dl_to_synapse_autopoc")

    h_hist = _patch_helper(_fetch_body(w, wid, "sp_dim_position_hedgetype_history"))
    _create_proc(w, wid, "sp_dim_position_hedgetype_history_autopoc", "V_date TIMESTAMP", h_hist)
    print("created_or_updated=sp_dim_position_hedgetype_history_autopoc")

    h_real = _patch_helper(_fetch_body(w, wid, "sp_dim_position_hedgetype_real"))
    _create_proc(w, wid, "sp_dim_position_hedgetype_real_autopoc", "V_date TIMESTAMP", h_real)
    print("created_or_updated=sp_dim_position_hedgetype_real_autopoc")

    # Temporary: reopen helper still hits DELTA_UNEXPECTED_PARTIAL_SCAN on this cluster
    # when it updates Dim_Position from Dim_Position-derived sources.
    reopen = "BEGIN SELECT V_date; END"
    _create_proc(w, wid, "sp_dim_position_reopen_autopoc", "V_date TIMESTAMP", reopen)
    print("created_or_updated=sp_dim_position_reopen_autopoc")

    partial = _fetch_body(w, wid, "sp_dim_position_ispartialcloseparent")
    _create_proc_no_sig(w, wid, "sp_dim_position_ispartialcloseparent_autopoc", partial)
    print("created_or_updated=sp_dim_position_ispartialcloseparent_autopoc")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
