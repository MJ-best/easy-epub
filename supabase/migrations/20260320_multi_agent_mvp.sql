begin;

create extension if not exists pgcrypto;

create type public.workspace_role as enum ('owner', 'admin', 'member', 'viewer');
create type public.project_status as enum ('draft', 'planning', 'active', 'blocked', 'completed', 'archived');
create type public.agent_kind as enum ('orchestrator', 'pm', 'system_designer', 'flutter', 'qa', 'custom');
create type public.agent_status as enum ('active', 'disabled', 'archived');
create type public.task_status as enum ('pending', 'queued', 'running', 'blocked', 'failed', 'completed', 'canceled');
create type public.task_kind as enum ('plan', 'prd', 'schema', 'ui', 'code', 'qa', 'review', 'custom');
create type public.artifact_kind as enum ('prd', 'schema', 'ui', 'code', 'qa', 'plan', 'report', 'log', 'other');
create type public.artifact_status as enum ('draft', 'partial', 'final', 'superseded', 'failed');
create type public.conversation_kind as enum ('workflow', 'discussion', 'execution_log');
create type public.message_sender_type as enum ('user', 'agent', 'system');
create type public.tool_run_status as enum ('queued', 'running', 'succeeded', 'failed', 'canceled');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.is_workspace_member(target_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.workspace_members wm
    where wm.workspace_id = target_workspace_id
      and wm.user_id = auth.uid()
  );
$$;

create or replace function public.is_workspace_admin(target_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.workspaces w
    where w.id = target_workspace_id
      and w.owner_user_id = auth.uid()
  )
  or exists (
    select 1
    from public.workspace_members wm
    where wm.workspace_id = target_workspace_id
      and wm.user_id = auth.uid()
      and wm.role in ('owner', 'admin')
  );
$$;

create or replace function public.can_view_profile(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select target_user_id = auth.uid()
  or exists (
    select 1
    from public.workspace_members me
    join public.workspace_members them
      on them.workspace_id = me.workspace_id
    where me.user_id = auth.uid()
      and them.user_id = target_user_id
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    user_id,
    email,
    display_name,
    avatar_url
  )
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(coalesce(new.email, 'user@example.com'), '@', 1)
    ),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null,
  avatar_url text,
  headline text,
  preferences jsonb not null default '{}'::jsonb,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_check check (length(trim(display_name)) > 0)
);

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(user_id) on delete restrict,
  name text not null,
  slug text not null,
  description text,
  settings jsonb not null default '{}'::jsonb,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint workspaces_name_check check (length(trim(name)) > 0),
  constraint workspaces_slug_check check (length(trim(slug)) > 0)
);

create unique index if not exists workspaces_slug_key on public.workspaces (lower(slug));
create index if not exists workspaces_owner_user_id_idx on public.workspaces (owner_user_id);

create table if not exists public.workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  role public.workspace_role not null default 'member',
  joined_at timestamptz not null default now(),
  created_by_user_id uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint workspace_members_unique unique (workspace_id, user_id)
);

create index if not exists workspace_members_workspace_id_idx on public.workspace_members (workspace_id);
create index if not exists workspace_members_user_id_idx on public.workspace_members (user_id);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by_user_id uuid not null references public.profiles(user_id) on delete restrict,
  name text not null,
  slug text not null,
  project_goal text not null,
  goal_context jsonb not null default '{}'::jsonb,
  execution_plan jsonb not null default '[]'::jsonb,
  execution_plan_generated_at timestamptz,
  plan_version integer not null default 1,
  status public.project_status not null default 'draft',
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint projects_name_check check (length(trim(name)) > 0),
  constraint projects_slug_check check (length(trim(slug)) > 0),
  constraint projects_goal_check check (length(trim(project_goal)) > 0),
  constraint projects_plan_version_check check (plan_version > 0)
);

create unique index if not exists projects_workspace_slug_key on public.projects (workspace_id, lower(slug));
create index if not exists projects_workspace_id_idx on public.projects (workspace_id);
create index if not exists projects_status_idx on public.projects (workspace_id, status);
create index if not exists projects_created_by_user_id_idx on public.projects (created_by_user_id);

create table if not exists public.agents (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by_user_id uuid not null references public.profiles(user_id) on delete restrict,
  project_id uuid references public.projects(id) on delete cascade,
  kind public.agent_kind not null,
  name text not null,
  description text,
  system_prompt text not null,
  model_hint text,
  temperature numeric(3,2) not null default 0.20,
  status public.agent_status not null default 'active',
  config jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint agents_name_check check (length(trim(name)) > 0),
  constraint agents_prompt_check check (length(trim(system_prompt)) > 0),
  constraint agents_temperature_check check (temperature >= 0 and temperature <= 2)
);

create unique index if not exists agents_workspace_kind_key on public.agents (workspace_id, kind);
create index if not exists agents_workspace_id_idx on public.agents (workspace_id);
create index if not exists agents_project_id_idx on public.agents (project_id);

create table if not exists public.agent_skills (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by_user_id uuid not null references public.profiles(user_id) on delete restrict,
  agent_id uuid not null references public.agents(id) on delete cascade,
  skill_key text not null,
  name text not null,
  description text,
  instruction text not null,
  input_schema jsonb not null default '{}'::jsonb,
  output_schema jsonb not null default '{}'::jsonb,
  is_required boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint agent_skills_name_check check (length(trim(name)) > 0),
  constraint agent_skills_key_check check (length(trim(skill_key)) > 0),
  constraint agent_skills_instruction_check check (length(trim(instruction)) > 0),
  constraint agent_skills_unique unique (agent_id, skill_key)
);

create index if not exists agent_skills_workspace_id_idx on public.agent_skills (workspace_id);
create index if not exists agent_skills_agent_id_idx on public.agent_skills (agent_id);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by_user_id uuid not null references public.profiles(user_id) on delete restrict,
  project_id uuid not null references public.projects(id) on delete cascade,
  kind public.conversation_kind not null default 'workflow',
  title text,
  summary text,
  context jsonb not null default '{}'::jsonb,
  latest_message_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists conversations_workspace_id_idx on public.conversations (workspace_id);
create index if not exists conversations_project_id_idx on public.conversations (project_id);
create index if not exists conversations_latest_message_at_idx on public.conversations (workspace_id, latest_message_at desc);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by_user_id uuid not null references public.profiles(user_id) on delete restrict,
  project_id uuid not null references public.projects(id) on delete cascade,
  conversation_id uuid references public.conversations(id) on delete set null,
  parent_task_id uuid references public.tasks(id) on delete set null,
  assigned_agent_id uuid references public.agents(id) on delete set null,
  kind public.task_kind not null,
  title text not null,
  instruction text not null,
  step_index integer not null default 0,
  priority integer not null default 0,
  status public.task_status not null default 'pending',
  dedupe_key text not null,
  input_payload jsonb not null default '{}'::jsonb,
  output_payload jsonb not null default '{}'::jsonb,
  is_partial boolean not null default false,
  partial_reason text,
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tasks_title_check check (length(trim(title)) > 0),
  constraint tasks_instruction_check check (length(trim(instruction)) > 0),
  constraint tasks_step_index_check check (step_index >= 0),
  constraint tasks_priority_check check (priority between -10 and 10),
  constraint tasks_dedupe_unique unique (project_id, dedupe_key)
);

create index if not exists tasks_workspace_id_idx on public.tasks (workspace_id);
create index if not exists tasks_project_id_idx on public.tasks (project_id);
create index if not exists tasks_conversation_id_idx on public.tasks (conversation_id);
create index if not exists tasks_assigned_agent_id_idx on public.tasks (assigned_agent_id);
create index if not exists tasks_status_idx on public.tasks (workspace_id, status, created_at desc);
create index if not exists tasks_dedupe_key_idx on public.tasks (project_id, dedupe_key);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by_user_id uuid references public.profiles(user_id) on delete set null,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete set null,
  agent_id uuid references public.agents(id) on delete set null,
  sender_type public.message_sender_type not null default 'system',
  content text not null default '',
  content_json jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  is_error boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint messages_content_check check (length(trim(content)) > 0 or content_json <> '{}'::jsonb)
);

create index if not exists messages_workspace_id_idx on public.messages (workspace_id);
create index if not exists messages_conversation_id_idx on public.messages (conversation_id, created_at asc);
create index if not exists messages_task_id_idx on public.messages (task_id);
create index if not exists messages_agent_id_idx on public.messages (agent_id);

create table if not exists public.artifacts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by_user_id uuid not null references public.profiles(user_id) on delete restrict,
  project_id uuid not null references public.projects(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete set null,
  conversation_id uuid references public.conversations(id) on delete set null,
  agent_id uuid references public.agents(id) on delete set null,
  parent_artifact_id uuid references public.artifacts(id) on delete set null,
  kind public.artifact_kind not null,
  title text not null,
  version integer not null default 1,
  status public.artifact_status not null default 'draft',
  storage_path text,
  mime_type text not null default 'text/markdown',
  content_text text,
  content_json jsonb not null default '{}'::jsonb,
  is_partial boolean not null default false,
  partial_reason text,
  generated_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint artifacts_title_check check (length(trim(title)) > 0),
  constraint artifacts_version_check check (version > 0),
  constraint artifacts_version_unique unique (project_id, kind, version)
);

create index if not exists artifacts_workspace_id_idx on public.artifacts (workspace_id);
create index if not exists artifacts_project_id_idx on public.artifacts (project_id);
create index if not exists artifacts_task_id_idx on public.artifacts (task_id);
create index if not exists artifacts_status_idx on public.artifacts (workspace_id, status, created_at desc);
create index if not exists artifacts_kind_version_idx on public.artifacts (project_id, kind, version desc);

create table if not exists public.tool_runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by_user_id uuid references public.profiles(user_id) on delete set null,
  project_id uuid not null references public.projects(id) on delete cascade,
  task_id uuid not null references public.tasks(id) on delete cascade,
  conversation_id uuid references public.conversations(id) on delete set null,
  agent_id uuid references public.agents(id) on delete set null,
  tool_name text not null,
  tool_version text,
  status public.tool_run_status not null default 'queued',
  request_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb not null default '{}'::jsonb,
  error_message text,
  started_at timestamptz,
  finished_at timestamptz,
  duration_ms integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tool_runs_tool_name_check check (length(trim(tool_name)) > 0),
  constraint tool_runs_duration_check check (duration_ms is null or duration_ms >= 0)
);

create index if not exists tool_runs_workspace_id_idx on public.tool_runs (workspace_id);
create index if not exists tool_runs_project_id_idx on public.tool_runs (project_id);
create index if not exists tool_runs_task_id_idx on public.tool_runs (task_id);
create index if not exists tool_runs_status_idx on public.tool_runs (workspace_id, status, created_at desc);

create or replace function public.set_task_dedupe_key()
returns trigger
language plpgsql
as $$
begin
  if new.dedupe_key is null or length(trim(new.dedupe_key)) = 0 then
    new.dedupe_key := encode(
      digest(
        concat_ws(
          '|',
          new.project_id::text,
          coalesce(new.parent_task_id::text, ''),
          coalesce(new.assigned_agent_id::text, ''),
          coalesce(new.kind::text, ''),
          coalesce(new.step_index::text, ''),
          coalesce(new.title, ''),
          coalesce(new.instruction, ''),
          coalesce(new.input_payload::text, '')
        ),
        'sha256'
      ),
      'hex'
    );
  end if;

  return new;
end;
$$;

create or replace function public.touch_conversation_latest_message()
returns trigger
language plpgsql
as $$
begin
  update public.conversations
  set latest_message_at = greatest(coalesce(latest_message_at, new.created_at), new.created_at),
      updated_at = now()
  where id = new.conversation_id;

  return new;
end;
$$;

create or replace function public.create_workspace_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.workspace_members (
    workspace_id,
    user_id,
    role,
    created_by_user_id
  )
  values (
    new.id,
    new.owner_user_id,
    'owner',
    new.owner_user_id
  )
  on conflict (workspace_id, user_id) do update
    set role = 'owner',
        updated_at = now();

  return new;
end;
$$;

create trigger handle_new_user_after_insert
after insert on auth.users
for each row
execute function public.handle_new_user();

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger workspaces_set_updated_at
before update on public.workspaces
for each row
execute function public.set_updated_at();

create trigger workspaces_create_owner_membership
after insert on public.workspaces
for each row
execute function public.create_workspace_owner_membership();

create trigger workspace_members_set_updated_at
before update on public.workspace_members
for each row
execute function public.set_updated_at();

create trigger projects_set_updated_at
before update on public.projects
for each row
execute function public.set_updated_at();

create trigger agents_set_updated_at
before update on public.agents
for each row
execute function public.set_updated_at();

create trigger agent_skills_set_updated_at
before update on public.agent_skills
for each row
execute function public.set_updated_at();

create trigger conversations_set_updated_at
before update on public.conversations
for each row
execute function public.set_updated_at();

create trigger tasks_set_updated_at
before update on public.tasks
for each row
execute function public.set_updated_at();

create trigger tasks_set_dedupe_key
before insert on public.tasks
for each row
execute function public.set_task_dedupe_key();

create trigger messages_set_updated_at
before update on public.messages
for each row
execute function public.set_updated_at();

create trigger messages_update_conversation_timestamp
after insert on public.messages
for each row
execute function public.touch_conversation_latest_message();

create trigger artifacts_set_updated_at
before update on public.artifacts
for each row
execute function public.set_updated_at();

create trigger tool_runs_set_updated_at
before update on public.tool_runs
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.projects enable row level security;
alter table public.agents enable row level security;
alter table public.agent_skills enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.tasks enable row level security;
alter table public.artifacts enable row level security;
alter table public.tool_runs enable row level security;

create policy profiles_select_own_or_workspace on public.profiles
for select
to authenticated
using (public.can_view_profile(user_id));

create policy profiles_insert_self on public.profiles
for insert
to authenticated
with check (user_id = auth.uid());

create policy profiles_update_self on public.profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy workspaces_select_member on public.workspaces
for select
to authenticated
using (public.is_workspace_member(id));

create policy workspaces_insert_owner on public.workspaces
for insert
to authenticated
with check (owner_user_id = auth.uid());

create policy workspaces_update_owner on public.workspaces
for update
to authenticated
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

create policy workspaces_delete_owner on public.workspaces
for delete
to authenticated
using (owner_user_id = auth.uid());

create policy workspace_members_select_scoped on public.workspace_members
for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy workspace_members_insert_admin on public.workspace_members
for insert
to authenticated
with check (public.is_workspace_admin(workspace_id));

create policy workspace_members_update_admin on public.workspace_members
for update
to authenticated
using (public.is_workspace_admin(workspace_id) and role <> 'owner')
with check (public.is_workspace_admin(workspace_id) and role <> 'owner');

create policy workspace_members_delete_admin on public.workspace_members
for delete
to authenticated
using (public.is_workspace_admin(workspace_id) and role <> 'owner');

create policy projects_select_member on public.projects
for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy projects_insert_member on public.projects
for insert
to authenticated
with check (public.is_workspace_member(workspace_id) and created_by_user_id = auth.uid());

create policy projects_update_owner_or_creator on public.projects
for update
to authenticated
using (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid())
with check (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid());

create policy projects_delete_owner_or_creator on public.projects
for delete
to authenticated
using (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid());

create policy agents_select_member on public.agents
for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy agents_insert_admin on public.agents
for insert
to authenticated
with check (public.is_workspace_admin(workspace_id) and created_by_user_id = auth.uid());

create policy agents_update_admin on public.agents
for update
to authenticated
using (public.is_workspace_admin(workspace_id))
with check (public.is_workspace_admin(workspace_id));

create policy agents_delete_admin on public.agents
for delete
to authenticated
using (public.is_workspace_admin(workspace_id));

create policy agent_skills_select_member on public.agent_skills
for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy agent_skills_insert_admin on public.agent_skills
for insert
to authenticated
with check (public.is_workspace_admin(workspace_id) and created_by_user_id = auth.uid());

create policy agent_skills_update_admin on public.agent_skills
for update
to authenticated
using (public.is_workspace_admin(workspace_id))
with check (public.is_workspace_admin(workspace_id));

create policy agent_skills_delete_admin on public.agent_skills
for delete
to authenticated
using (public.is_workspace_admin(workspace_id));

create policy conversations_select_member on public.conversations
for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy conversations_insert_member on public.conversations
for insert
to authenticated
with check (public.is_workspace_member(workspace_id) and created_by_user_id = auth.uid());

create policy conversations_update_creator_or_admin on public.conversations
for update
to authenticated
using (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid())
with check (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid());

create policy conversations_delete_creator_or_admin on public.conversations
for delete
to authenticated
using (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid());

create policy messages_select_member on public.messages
for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy messages_insert_member on public.messages
for insert
to authenticated
with check (public.is_workspace_member(workspace_id) and created_by_user_id = auth.uid());

create policy messages_update_creator_or_admin on public.messages
for update
to authenticated
using (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid())
with check (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid());

create policy messages_delete_creator_or_admin on public.messages
for delete
to authenticated
using (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid());

create policy tasks_select_member on public.tasks
for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy tasks_insert_member on public.tasks
for insert
to authenticated
with check (public.is_workspace_member(workspace_id) and created_by_user_id = auth.uid());

create policy tasks_update_member_or_admin on public.tasks
for update
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

create policy tasks_delete_admin_or_creator on public.tasks
for delete
to authenticated
using (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid());

create policy artifacts_select_member on public.artifacts
for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy artifacts_insert_member on public.artifacts
for insert
to authenticated
with check (public.is_workspace_member(workspace_id) and created_by_user_id = auth.uid());

create policy artifacts_update_creator_or_admin on public.artifacts
for update
to authenticated
using (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid())
with check (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid());

create policy artifacts_delete_creator_or_admin on public.artifacts
for delete
to authenticated
using (public.is_workspace_admin(workspace_id) or created_by_user_id = auth.uid());

create policy tool_runs_select_member on public.tool_runs
for select
to authenticated
using (public.is_workspace_member(workspace_id));

create policy tool_runs_insert_member on public.tool_runs
for insert
to authenticated
with check (public.is_workspace_member(workspace_id) and created_by_user_id = auth.uid());

create policy tool_runs_update_admin on public.tool_runs
for update
to authenticated
using (public.is_workspace_admin(workspace_id))
with check (public.is_workspace_admin(workspace_id));

create policy tool_runs_delete_admin on public.tool_runs
for delete
to authenticated
using (public.is_workspace_admin(workspace_id));

commit;
