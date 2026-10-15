-- Apply after the existing user_routes migrations. No user content is seeded.
begin;
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated;

alter table public.user_routes add column if not exists revision integer not null default 0;

create table if not exists public.route_members (
  route_id uuid not null references public.user_routes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('editor','viewer')),
  joined_at timestamptz not null default now(),
  primary key (route_id,user_id)
);
create index if not exists route_members_user_idx on public.route_members(user_id,route_id);
create table if not exists public.route_invitations (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.user_routes(id) on delete cascade,
  invited_by uuid not null references auth.users(id) on delete cascade,
  token text not null unique default replace(gen_random_uuid()::text || gen_random_uuid()::text,'-',''),
  role text not null check (role in ('editor','viewer')),
  invited_email text,
  expires_at timestamptz not null default now() + interval '7 days',
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists route_invites_route_idx on public.route_invitations(route_id);
create index if not exists route_invites_email_idx on public.route_invitations(lower(invited_email))
  where invited_email is not null and revoked_at is null;

-- The helper derives identity from the JWT, never from a caller-provided user ID.
-- Kept outside the exposed schema to avoid recursive membership RLS.
create or replace function private.sr_route_role(p_route_id uuid) returns text
language sql stable security definer set search_path = '' as $$
  select case when r.user_id = (select auth.uid()) then 'owner'
    else (select m.role from public.route_members m
      where m.route_id=r.id and m.user_id=(select auth.uid())) end
  from public.user_routes r where r.id=p_route_id and (select auth.uid()) is not null
$$;
create or replace function private.sr_display_name(p_user_id uuid) returns text
language sql stable security definer set search_path = '' as $$
  select coalesce(nullif(left(trim(u.raw_user_meta_data->>'nickname'),40),''),'旅行者')
  from auth.users u where u.id=p_user_id
$$;

alter table public.route_members enable row level security;
alter table public.route_invitations enable row level security;
revoke all on public.route_members, public.route_invitations from anon, authenticated;
grant select on public.route_members to authenticated;
drop policy if exists sr_members_read on public.route_members;
create policy sr_members_read on public.route_members for select to authenticated
  using (private.sr_route_role(route_id) is not null);

drop policy if exists "Users manage own routes" on public.user_routes;
drop policy if exists "Users manage own waypoints" on public.user_route_waypoints;
alter table public.user_routes enable row level security;
alter table public.user_route_waypoints enable row level security;
drop policy if exists sr_routes_read on public.user_routes;
create policy sr_routes_read on public.user_routes for select to authenticated
  using (private.sr_route_role(id) is not null);
drop policy if exists sr_routes_create on public.user_routes;
create policy sr_routes_create on public.user_routes for insert to authenticated
  with check (user_id=(select auth.uid()));
drop policy if exists sr_routes_update on public.user_routes;
create policy sr_routes_update on public.user_routes for update to authenticated
  using (private.sr_route_role(id) in ('owner','editor'))
  with check (private.sr_route_role(id) in ('owner','editor'));
drop policy if exists sr_routes_delete on public.user_routes;
create policy sr_routes_delete on public.user_routes for delete to authenticated
  using (user_id=(select auth.uid()));
drop policy if exists sr_waypoints_read on public.user_route_waypoints;
create policy sr_waypoints_read on public.user_route_waypoints for select to authenticated
  using (private.sr_route_role(route_id) is not null);
-- Writes to existing waypoints are only available through the transactional RPC.
drop policy if exists sr_waypoints_create on public.user_route_waypoints;
create policy sr_waypoints_create on public.user_route_waypoints for insert to authenticated
  with check (private.sr_route_role(route_id)='owner');
revoke all on public.user_routes, public.user_route_waypoints from anon;
grant select,insert,delete on public.user_routes to authenticated;
revoke update on public.user_routes from authenticated;
grant update(title,date_range,duration,distance,figure_id,figure_name,route_snapshot)
  on public.user_routes to authenticated;
grant select,insert on public.user_route_waypoints to authenticated;
revoke update,delete on public.user_route_waypoints from authenticated;

create or replace view public.route_access_index with (security_invoker=true) as
  select r.*, private.sr_route_role(r.id) as access_role,
    1+(select count(*) from public.route_members m where m.route_id=r.id) as member_count
  from public.user_routes r;
grant select on public.route_access_index to authenticated;
revoke all on public.route_access_index from anon;

create or replace function public.touch_user_routes_updated_at() returns trigger
language plpgsql set search_path = '' as $$ begin
  new.updated_at=now(); new.revision=old.revision+1; return new;
end $$;

create or replace function private.sr_create_invite(p_route_id uuid,p_role text,p_email text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare invitation public.route_invitations; begin
  if (select auth.uid()) is null or private.sr_route_role(p_route_id) is distinct from 'owner'
    then raise exception 'not_authorized' using errcode='42501'; end if;
  if p_role not in ('editor','viewer') then raise exception 'invalid_role'; end if;
  if p_email is not null and (length(trim(p_email))>254 or position('@' in p_email)<2)
    then raise exception 'invalid_email'; end if;
  insert into public.route_invitations(route_id,invited_by,role,invited_email)
    values(p_route_id,auth.uid(),p_role,nullif(lower(trim(p_email)),'')) returning * into invitation;
  return to_jsonb(invitation);
end $$;
create or replace function private.sr_invite_info(p_token text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('id',i.id,'route_id',r.id,'title',r.title,'role',i.role,
    'owner_name',private.sr_display_name(r.user_id),'expires_at',i.expires_at,
    'available',i.revoked_at is null and i.expires_at>now(),
    'email_bound',i.invited_email is not null)
  from public.route_invitations i join public.user_routes r on r.id=i.route_id where i.token=p_token
$$;
create or replace function private.sr_accept_invite(p_token text,p_invite_id uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare invitation public.route_invitations; verified_email text; begin
  if (select auth.uid()) is null then raise exception 'not_authorized' using errcode='42501'; end if;
  select * into invitation from public.route_invitations i
    where (p_token is not null and i.token=p_token) or (p_token is null and i.id=p_invite_id)
    for update;
  if not found then raise exception 'invite_not_found'; end if;
  if invitation.revoked_at is not null then raise exception 'invite_revoked'; end if;
  if invitation.expires_at<=now() then raise exception 'invite_expired'; end if;
  select lower(u.email) into verified_email from auth.users u
    where u.id=auth.uid() and u.email_confirmed_at is not null;
  if invitation.invited_email is not null and invitation.invited_email is distinct from verified_email
    then raise exception 'email_mismatch' using errcode='42501'; end if;
  -- Invitations addressed by ID are only accepted from the recipient inbox.
  if p_token is null and invitation.invited_email is null
    then raise exception 'not_authorized' using errcode='42501'; end if;
  if private.sr_route_role(invitation.route_id)='owner' then return invitation.route_id; end if;
  insert into public.route_members(route_id,user_id,role)
    values(invitation.route_id,auth.uid(),invitation.role)
    on conflict(route_id,user_id) do update set role=case
      when route_members.role='editor' or excluded.role='editor' then 'editor' else 'viewer' end;
  return invitation.route_id;
end $$;
create or replace function private.sr_my_invitations() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(item order by item->>'created_at' desc),'[]'::jsonb) from (
    select jsonb_build_object('id',i.id,'route_id',r.id,'title',r.title,'role',i.role,
      'owner_name',private.sr_display_name(r.user_id),'created_at',i.created_at,
      'expires_at',i.expires_at) as item
    from public.route_invitations i join public.user_routes r on r.id=i.route_id
    join auth.users u on lower(u.email)=i.invited_email and u.id=(select auth.uid())
    where u.email_confirmed_at is not null and i.revoked_at is null and i.expires_at>now()
      and private.sr_route_role(r.id) is null
  ) pending
$$;
create or replace function private.sr_route_sharing(p_route_id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$ begin
  if private.sr_route_role(p_route_id) is null then raise exception 'not_authorized' using errcode='42501'; end if;
  return jsonb_build_object(
    'members', (select coalesce(jsonb_agg(jsonb_build_object('user_id',m.user_id,
      'name',private.sr_display_name(m.user_id),'role',m.role)),'[]'::jsonb)
      from public.route_members m where m.route_id=p_route_id),
    'invitations',case when private.sr_route_role(p_route_id)='owner' then
      (select coalesce(jsonb_agg(jsonb_build_object('id',i.id,'role',i.role,
        'invited_email',i.invited_email,'expires_at',i.expires_at)),'[]'::jsonb)
        from public.route_invitations i where i.route_id=p_route_id and i.revoked_at is null and i.expires_at>now())
      else '[]'::jsonb end);
end $$;
create or replace function private.sr_revoke_invite(p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare target_route uuid; begin
  select route_id into target_route from public.route_invitations where id=p_id;
  if private.sr_route_role(target_route) is distinct from 'owner'
    then raise exception 'not_authorized' using errcode='42501'; end if;
  update public.route_invitations set revoked_at=now() where id=p_id;
end $$;
create or replace function private.sr_remove_member(p_route_id uuid,p_user_id uuid) returns void
language plpgsql security definer set search_path = '' as $$ begin
  if (select auth.uid()) is null or (private.sr_route_role(p_route_id) is distinct from 'owner'
      and p_user_id<>(select auth.uid())) then raise exception 'not_authorized' using errcode='42501'; end if;
  delete from public.route_members where route_id=p_route_id and user_id=p_user_id;
end $$;

create or replace function private.sr_replace_waypoints(p_route_id uuid,p_expected_revision integer,p_waypoints jsonb)
returns integer language plpgsql security definer set search_path = '' as $$
declare current_revision integer; new_revision integer; begin
  if (select auth.uid()) is null or coalesce(private.sr_route_role(p_route_id),'') not in ('owner','editor')
    then raise exception 'not_authorized' using errcode='42501'; end if;
  select revision into current_revision from public.user_routes where id=p_route_id for update;
  if current_revision is distinct from p_expected_revision then raise exception 'route_conflict' using errcode='40001'; end if;
  if jsonb_typeof(p_waypoints) is distinct from 'array' or jsonb_array_length(p_waypoints)>200
    then raise exception 'invalid_waypoints'; end if;
  delete from public.user_route_waypoints where route_id=p_route_id;
  insert into public.user_route_waypoints(route_id,sort_order,name,latitude,longitude,
    location_id,visit_duration_min,categories,transport_to_next)
    select p_route_id,(n-1)::integer,item->>'name',(item->>'latitude')::double precision,
      (item->>'longitude')::double precision,(item->>'location_id')::bigint,
      (item->>'visit_duration_min')::integer,item->>'categories',
      case when n=jsonb_array_length(p_waypoints) then null else item->>'transport_to_next' end
    from jsonb_array_elements(p_waypoints) with ordinality as places(item,n);
  if exists(select 1 from public.user_route_waypoints w where w.route_id=p_route_id
      and (w.latitude not between -90 and 90 or w.longitude not between -180 and 180
        or (w.latitude=0 and w.longitude=0) or length(trim(w.name))=0))
    then raise exception 'invalid_waypoints'; end if;
  update public.user_routes set updated_at=now() where id=p_route_id returning revision into new_revision;
  return new_revision;
end $$;

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 2000),
  route_snapshot jsonb,
  created_at timestamptz not null default now()
);
create index if not exists community_posts_created_idx on public.community_posts(created_at desc,id);
create index if not exists community_posts_author_idx on public.community_posts(author_id);
create table if not exists public.community_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 500),
  created_at timestamptz not null default now()
);
create index if not exists community_comments_post_idx on public.community_comments(post_id,created_at);
create index if not exists community_comments_author_idx on public.community_comments(author_id);
create table if not exists public.community_likes (
  post_id uuid not null references public.community_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  primary key(post_id,user_id)
);
create index if not exists community_likes_user_idx on public.community_likes(user_id);
alter table public.community_posts enable row level security;
alter table public.community_comments enable row level security;
alter table public.community_likes enable row level security;
revoke all on public.community_posts,public.community_comments,public.community_likes from anon,authenticated;
grant select on public.community_posts,public.community_comments to anon,authenticated;
drop policy if exists sr_posts_read on public.community_posts;
create policy sr_posts_read on public.community_posts for select to anon,authenticated using(true);
drop policy if exists sr_comments_read on public.community_comments;
create policy sr_comments_read on public.community_comments for select to anon,authenticated using(true);
-- Mutations use checked private functions behind invoker wrappers below.
create or replace function private.sr_create_post(p_body text,p_route_id uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare snapshot jsonb; post_id uuid; begin
  if (select auth.uid()) is null then raise exception 'not_authorized' using errcode='42501'; end if;
  if p_route_id is not null then
    if private.sr_route_role(p_route_id) is distinct from 'owner'
      then raise exception 'only_owner_can_publish' using errcode='42501'; end if;
    select jsonb_build_object('title',r.title,'figure_id',r.figure_id,'figure_name',r.figure_name,
      'duration',r.duration,'distance',r.distance,'waypoints',
      (select coalesce(jsonb_agg(jsonb_build_object('name',w.name,'latitude',w.latitude,
        'longitude',w.longitude,'visit_duration_min',w.visit_duration_min,'categories',w.categories,
        'transport_to_next',w.transport_to_next) order by w.sort_order),'[]'::jsonb)
       from public.user_route_waypoints w where w.route_id=r.id)) into snapshot
      from public.user_routes r where r.id=p_route_id;
  end if;
  insert into public.community_posts(author_id,body,route_snapshot)
    values(auth.uid(),trim(p_body),snapshot) returning id into post_id;
  return post_id;
end $$;
create or replace function private.sr_post_json(p public.community_posts) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('id',p.id,'author_id',p.author_id,
    'author_name',private.sr_display_name(p.author_id),'body',p.body,
    'route_snapshot',p.route_snapshot,'created_at',p.created_at,
    'like_count',(select count(*) from public.community_likes l where l.post_id=p.id),
    'comment_count',(select count(*) from public.community_comments c where c.post_id=p.id),
    'liked',exists(select 1 from public.community_likes l where l.post_id=p.id and l.user_id=(select auth.uid())))
$$;
create or replace function private.sr_feed(p_before timestamptz,p_limit integer,p_kind text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(private.sr_post_json(p) order by p.created_at desc,p.id),'[]'::jsonb)
  from (select * from public.community_posts where (p_before is null or created_at<p_before)
    and (p_kind is null or (p_kind='route' and route_snapshot is not null)
      or (p_kind='note' and route_snapshot is null))
    order by created_at desc,id limit greatest(1,least(coalesce(p_limit,20),50))) p
$$;
create or replace function private.sr_post(p_id uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select private.sr_post_json(p) from public.community_posts p where id=p_id
$$;
create or replace function private.sr_comments(p_post_id uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('id',c.id,'author_id',c.author_id,
    'author_name',private.sr_display_name(c.author_id),'body',c.body,'created_at',c.created_at)
    order by c.created_at),'[]'::jsonb)
  from (select * from public.community_comments where post_id=p_post_id order by created_at desc limit 100) c
$$;
create or replace function private.sr_add_comment(p_post_id uuid,p_body text) returns uuid
language plpgsql security definer set search_path = '' as $$ declare new_id uuid; begin
  if (select auth.uid()) is null then raise exception 'not_authorized' using errcode='42501'; end if;
  insert into public.community_comments(post_id,author_id,body) values(p_post_id,auth.uid(),trim(p_body)) returning id into new_id;
  return new_id;
end $$;
create or replace function private.sr_set_like(p_post_id uuid,p_liked boolean) returns void
language plpgsql security definer set search_path = '' as $$ begin
  if (select auth.uid()) is null then raise exception 'not_authorized' using errcode='42501'; end if;
  if p_liked then insert into public.community_likes(post_id,user_id) values(p_post_id,auth.uid()) on conflict do nothing;
  else delete from public.community_likes where post_id=p_post_id and user_id=auth.uid(); end if;
end $$;
create or replace function private.sr_delete_post(p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$ begin
  if (select auth.uid()) is null then raise exception 'not_authorized' using errcode='42501'; end if;
  delete from public.community_posts where id=p_id and author_id=auth.uid();
  if not found then raise exception 'not_authorized' using errcode='42501'; end if;
end $$;

-- Exposed RPCs are invoker wrappers; all privileged implementations are private
-- and check caller identity/ownership before reading or modifying private rows.
create or replace function public.sr_create_invite(p_route_id uuid,p_role text,p_email text default null) returns jsonb
language sql security invoker set search_path='' as $$ select private.sr_create_invite(p_route_id,p_role,p_email) $$;
create or replace function public.sr_invite_info(p_token text) returns jsonb
language sql stable security invoker set search_path='' as $$ select private.sr_invite_info(p_token) $$;
create or replace function public.sr_accept_invite(p_token text default null,p_invite_id uuid default null) returns uuid
language sql security invoker set search_path='' as $$ select private.sr_accept_invite(p_token,p_invite_id) $$;
create or replace function public.sr_my_invitations() returns jsonb
language sql stable security invoker set search_path='' as $$ select private.sr_my_invitations() $$;
create or replace function public.sr_route_sharing(p_route_id uuid) returns jsonb
language sql stable security invoker set search_path='' as $$ select private.sr_route_sharing(p_route_id) $$;
create or replace function public.sr_revoke_invite(p_id uuid) returns void
language sql security invoker set search_path='' as $$ select private.sr_revoke_invite(p_id) $$;
create or replace function public.sr_remove_member(p_route_id uuid,p_user_id uuid) returns void
language sql security invoker set search_path='' as $$ select private.sr_remove_member(p_route_id,p_user_id) $$;
create or replace function public.sr_replace_waypoints(p_route_id uuid,p_expected_revision integer,p_waypoints jsonb) returns integer
language sql security invoker set search_path='' as $$ select private.sr_replace_waypoints(p_route_id,p_expected_revision,p_waypoints) $$;
create or replace function public.sr_create_post(p_body text,p_route_id uuid default null) returns uuid
language sql security invoker set search_path='' as $$ select private.sr_create_post(p_body,p_route_id) $$;
create or replace function public.sr_feed(p_before timestamptz default null,p_limit integer default 20,p_kind text default null) returns jsonb
language sql stable security invoker set search_path='' as $$ select private.sr_feed(p_before,p_limit,p_kind) $$;
create or replace function public.sr_post(p_id uuid) returns jsonb
language sql stable security invoker set search_path='' as $$ select private.sr_post(p_id) $$;
create or replace function public.sr_comments(p_post_id uuid) returns jsonb
language sql stable security invoker set search_path='' as $$ select private.sr_comments(p_post_id) $$;
create or replace function public.sr_add_comment(p_post_id uuid,p_body text) returns uuid
language sql security invoker set search_path='' as $$ select private.sr_add_comment(p_post_id,p_body) $$;
create or replace function public.sr_set_like(p_post_id uuid,p_liked boolean) returns void
language sql security invoker set search_path='' as $$ select private.sr_set_like(p_post_id,p_liked) $$;
create or replace function public.sr_delete_post(p_id uuid) returns void
language sql security invoker set search_path='' as $$ select private.sr_delete_post(p_id) $$;

do $$ declare f record; begin
  for f in select p.oid::regprocedure as signature,n.nspname,p.proname from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('private','public') and p.proname like 'sr\_%' escape '\'
  loop
    execute format('revoke all on function %s from public,anon,authenticated',f.signature);
    if f.proname in ('sr_invite_info','sr_feed','sr_post','sr_comments') then
      execute format('grant execute on function %s to anon,authenticated',f.signature);
    elsif f.proname not in ('sr_display_name','sr_post_json') then
      execute format('grant execute on function %s to authenticated',f.signature);
    end if;
  end loop;
end $$;

-- Realtime publishes only parent revisions; clients re-fetch through RLS.
do $$ begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') and not exists
    (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='user_routes') then
    alter publication supabase_realtime add table public.user_routes;
  end if;
end $$;
notify pgrst,'reload schema';
commit;
