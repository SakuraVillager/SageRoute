-- Read-only post-deployment checks. Run after setup_collaboration_and_discovery.sql.
-- No user rows, invitation tokens or credentials are returned.
with
required_tables(name) as (values
  ('user_routes'), ('user_route_waypoints'), ('route_members'),
  ('route_invitations'), ('community_posts'), ('community_comments'), ('community_likes')
),
required_rpcs(name, anon_allowed) as (values
  ('sr_create_invite',false), ('sr_invite_info',true), ('sr_accept_invite',false),
  ('sr_my_invitations',false), ('sr_route_sharing',false), ('sr_revoke_invite',false),
  ('sr_remove_member',false), ('sr_replace_waypoints',false), ('sr_create_post',false),
  ('sr_feed',true), ('sr_post',true), ('sr_comments',true), ('sr_add_comment',false),
  ('sr_set_like',false), ('sr_delete_post',false)
),
checks(check_name, passed) as (
  select 'postgres_15_plus', current_setting('server_version_num')::integer >= 150000
  union all
  select 'rls:' || t.name, coalesce(c.relrowsecurity,false)
  from required_tables t left join pg_class c on c.oid=to_regclass('public.' || t.name)
  union all
  select 'route_access_index_security_invoker', coalesce((
    select 'security_invoker=true'=any(c.reloptions)
    from pg_class c where c.oid=to_regclass('public.route_access_index')
  ),false)
  union all
  select 'revision_integer_not_null', exists(
    select 1 from information_schema.columns where table_schema='public'
      and table_name='user_routes' and column_name='revision'
      and data_type='integer' and is_nullable='NO'
  )
  union all
  select 'last_waypoint_transport_nullable', exists(
    select 1 from information_schema.columns where table_schema='public'
      and table_name='user_route_waypoints' and column_name='transport_to_next'
      and is_nullable='YES'
  )
  union all
  select 'revision_trigger_enabled', exists(
    select 1 from pg_trigger t join pg_proc p on p.oid=t.tgfoid
    where t.tgrelid=to_regclass('public.user_routes') and not t.tgisinternal
      and t.tgname='user_routes_touch_updated_at' and t.tgenabled in ('O','A')
      and p.proname='touch_user_routes_updated_at'
  )
  union all
  select 'realtime_user_routes', exists(
    select 1 from pg_publication_tables where pubname='supabase_realtime'
      and schemaname='public' and tablename='user_routes'
  )
  union all
  select 'rpc:' || r.name, count(p.oid)=1 and coalesce(bool_and(
    not p.prosecdef and has_function_privilege('authenticated',p.oid,'EXECUTE')
    and has_function_privilege('anon',p.oid,'EXECUTE')=r.anon_allowed
  ),false)
  from required_rpcs r left join pg_proc p on p.proname=r.name
    and p.pronamespace=(select oid from pg_namespace where nspname='public')
  group by r.name
  union all
  select 'anon_cannot_read:' || t.name, case when c.oid is null then false
    else not has_table_privilege('anon',c.oid,'SELECT') end
  from required_tables t left join pg_class c on c.oid=to_regclass('public.' || t.name)
  where t.name not in ('community_posts','community_comments')
  union all
  select 'public_read:' || t.name, case when c.oid is null then false else
    has_table_privilege('anon',c.oid,'SELECT')
    and has_table_privilege('authenticated',c.oid,'SELECT') end
  from required_tables t left join pg_class c on c.oid=to_regclass('public.' || t.name)
  where t.name in ('community_posts','community_comments')
  union all
  select 'mutations_via_rpc:' || t.name, case when c.oid is null then false else
    not has_table_privilege('authenticated',c.oid,'INSERT')
    and not has_table_privilege('authenticated',c.oid,'UPDATE')
    and not has_table_privilege('authenticated',c.oid,'DELETE') end
  from required_tables t left join pg_class c on c.oid=to_regclass('public.' || t.name)
  where t.name in ('route_members','route_invitations','community_posts','community_comments','community_likes')
  union all
  select 'existing_waypoint_edits_via_rpc', case when to_regclass('public.user_route_waypoints') is null
    then false else not has_table_privilege('authenticated','public.user_route_waypoints','UPDATE')
      and not has_table_privilege('authenticated','public.user_route_waypoints','DELETE') end
  union all
  select 'cannot_transfer_route_ownership', case when to_regclass('public.user_routes') is null
    then false else not has_column_privilege('authenticated','public.user_routes','user_id','UPDATE') end
)
select check_name, passed from checks order by check_name;
