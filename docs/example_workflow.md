# Example Workflow Execution

## Goal Input

```text
Build a production-ready MVP of a multi-agent vibe coding platform using Flutter web-first and Supabase.
The app should turn a single project goal into structured artifacts: execution plan, PRD, schema, UI, code, and QA.
```

## Execution Plan

1. Orchestrator accepts `project_goal` and creates a staged plan.
2. PM produces PRD, feature list, and user flow.
3. System Designer turns requirements into Supabase schema and RLS.
4. Flutter Agent generates the web-first app structure and screen skeletons.
5. QA checks completeness, edge cases, and permission gaps.

## Step-by-Step Agent Tasks

| Step | Agent | Input | Output |
| --- | --- | --- | --- |
| 1 | Orchestrator | `project_goal` | `execution_plan`, `task_graph` |
| 2 | PM | `execution_plan` | `prd`, `feature_list`, `acceptance_criteria` |
| 3 | System Designer | `prd` | `schema`, `rls_policy_spec`, `entity_relationship_map` |
| 4 | Flutter Agent | `prd`, `schema` | `ui_spec`, `code_plan`, `flutter_skeleton` |
| 5 | QA | all prior artifacts | `qa_report`, `risk_register`, `open_issues` |

## Artifact Set

- `execution_plan`: ordered workflow with dependencies and owners
- `prd`: MVP scope, non-goals, acceptance criteria
- `schema`: Supabase tables, relations, RLS
- `ui_spec`: login, dashboard, project list, project detail, artifacts, settings
- `code_plan`: Flutter feature-based file structure and routing plan
- `qa_report`: missing cases and pass/fail summary

## Example Output Shape

### Orchestrator

```json
{
  "plan_id": "plan_001",
  "next_agent": "pm",
  "stages": [
    { "id": "product_definition", "owner": "pm", "depends_on": ["intake"], "deliverables": ["prd"] },
    { "id": "system_design", "owner": "system_designer", "depends_on": ["product_definition"], "deliverables": ["schema"] },
    { "id": "ui_and_code", "owner": "flutter", "depends_on": ["system_design"], "deliverables": ["ui_spec", "code_plan"] },
    { "id": "validation", "owner": "qa", "depends_on": ["ui_and_code"], "deliverables": ["qa_report"] }
  ]
}
```

### PM

```json
{
  "product_summary": "Workflow-first platform that transforms a goal into structured engineering artifacts.",
  "mvp_scope": ["Google login", "workspace/project management", "multi-agent workflow", "artifact viewer"],
  "non_goals": ["freeform chat product", "plugin marketplace", "long-term memory"],
  "acceptance_criteria": ["A logged-in user can create a project from a goal", "The orchestrator can dispatch all 5 agents", "Each stage stores artifacts"]
}
```

### System Designer

```json
{
  "entities": ["profiles", "workspaces", "workspace_members", "projects", "agents", "tasks", "artifacts"],
  "rls_model": ["default deny", "workspace-scoped read access", "owner or member write access"],
  "indexes": ["projects(workspace_id, created_at)", "tasks(project_id, status)", "artifacts(project_id, artifact_type)"]
}
```

### Flutter Agent

```json
{
  "app_structure": [
    "lib/core",
    "lib/features/auth",
    "lib/features/workspace",
    "lib/features/projects",
    "lib/features/agents",
    "lib/features/artifacts",
    "lib/features/settings"
  ],
  "screens": ["login", "dashboard", "project list", "project detail", "artifact viewer", "settings"]
}
```

### QA

```json
{
  "pass_fail": "pass_with_notes",
  "issues": ["Need duplicate task execution guard", "Need OAuth redirect failure handling"],
  "missing_cases": ["empty project_goal", "partial artifact generation", "RLS permission violations"]
}
```

## Operating Rule

The orchestrator owns sequencing only. PM, System Designer, Flutter, and QA each own one artifact layer and must not overlap.
