# skill-suggestions Databricks App

Simple submission UI for the autonomous skills pipeline.

## Purpose

- Collect **new skill bundles** (`.md` files and/or text context).
- Collect **targeted corrections** for existing skills.
- Keep the searchable target-skill picker disabled for now (`Coming soon`) until app-principal workspace-read access is finalized.
- Collect `Target skill name` directly from the user for correction requests (name-based entry, not id-based).
- Persist requests into `main.de_output.de_output_skills_automation_user_suggestions_agent`.
- Store uploaded markdown files in `/Volumes/main/de_output/skills_automation_user_suggestions_agent_files/<id>/`.

## Prerequisites

1. Apply queue DDL first:
   - `tools/skill_suggestions/ddl.sql`
2. Validate queue table naming/location before deployment:
   - `python tools/skill_suggestions/validate_external_name.py --schema de_output --table-name de_output_skills_automation_user_suggestions_agent --location "abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Skills_Automation/User_Suggestions_Agent/"`
3. Grant app service principal:
   - `SELECT`, `MODIFY` on `main.de_output.de_output_skills_automation_user_suggestions_agent`
   - `READ VOLUME`, `WRITE VOLUME` on `main.de_output.skills_automation_user_suggestions_agent_files`

## Local run

```powershell
cd apps/skill-suggestions
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
streamlit run app.py
```

## Deploy notes

- This is a non-AppKit Streamlit app intended for Databricks Apps.
- `app.yaml` pins the SQL warehouse id via `DATABRICKS_WAREHOUSE_ID`.
- If your workspace uses a different warehouse, override the env value.

## Request contract

Rows inserted with:

- `request_type`: `new_skill` or `correction`
- `status`: always starts at `new`
- `volume_path`: optional path to uploaded markdown payload directory

The `/skills-autoloop` command consumes this contract.
