// A real PostgreSQL engine (WASM), with mocked auth identities and no live data.
// npm install --prefix build/sql-validation --no-audit --no-fund @electric-sql/pglite@0.5.10
import { PGlite } from '../build/sql-validation/node_modules/@electric-sql/pglite/dist/index.js';
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';

const db = new PGlite();
const owner = '10000000-0000-0000-0000-000000000001';
const editor = '10000000-0000-0000-0000-000000000002';
const viewer = '10000000-0000-0000-0000-000000000003';
const outsider = '10000000-0000-0000-0000-000000000004';
const route = '20000000-0000-0000-0000-000000000001';
await db.exec(`create role anon; create role authenticated; create schema auth;
  create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz,raw_user_meta_data jsonb);
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
  grant usage on schema auth to anon,authenticated; grant execute on function auth.uid() to anon,authenticated;`);
for (const [id,name] of [[owner,'owner'],[editor,'editor'],[viewer,'viewer'],[outsider,'outsider']]) {
  await db.query('insert into auth.users values($1,$2,now(),$3)',[id,`${name}@example.com`,{nickname:name}]);
}
await db.exec(await readFile('supabase/migrations/20260919_create_user_routes.sql','utf8'));
await db.exec(await readFile('supabase/setup_collaboration_and_discovery.sql','utf8'));
// Applying the setup again must not duplicate policies or lose any records.
await db.exec(await readFile('supabase/setup_collaboration_and_discovery.sql','utf8'));
const metadataChecks = (await db.query(await readFile('supabase/check_collaboration_and_discovery.sql','utf8'))).rows;
assert.ok(metadataChecks.length >= 40);
for (const check of metadataChecks) {
  // The isolated engine intentionally has no Supabase Realtime publication.
  assert.equal(check.passed, check.check_name !== 'realtime_user_routes', check.check_name);
}
await db.query('insert into public.user_routes(id,user_id,title,date_range) values($1,$2,$3,$4)',
  [route,owner,'Shared Hangzhou','PRIVATE DATE']);
async function actor(id) {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id ?? '']);
  await db.exec(id ? 'set role authenticated' : 'set role anon');
}
async function scalar(sql,params=[]) { return Object.values((await db.query(sql,params)).rows[0])[0]; }
async function denied(fn,pattern) { await assert.rejects(fn,pattern); }
await actor(owner);
const editInvite=await scalar("select public.sr_create_invite($1,'editor','editor@example.com')",[route]);
assert.equal(editInvite.token.length,64);
await actor(outsider);
assert.equal(await scalar('select count(*) from public.user_routes'),0);
await denied(()=>db.query('select public.sr_accept_invite($1)',[editInvite.token]),/email_mismatch/);
await denied(()=>db.query("select public.sr_create_invite($1,'editor')",[route]),/not_authorized/);
await actor(editor);
assert.equal((await scalar('select public.sr_my_invitations()')).length,1);
assert.equal(await scalar('select public.sr_accept_invite(null,$1)',[editInvite.id]),route);
assert.equal(await scalar('select public.sr_accept_invite($1)',[editInvite.token]),route);
assert.equal(await scalar('select count(*) from public.route_access_index'),1);
assert.equal(await scalar('select access_role from public.route_access_index'),'editor');
const points=[{name:'West Lake',latitude:30.25,longitude:120.14,transport_to_next:'walking'},
  {name:'Tower',latitude:30.26,longitude:120.15}];
assert.equal(await scalar('select public.sr_replace_waypoints($1,0,$2)',[route,points]),1);
await denied(()=>db.query('select public.sr_replace_waypoints($1,0,$2)',[route,points]),/route_conflict/);
await denied(()=>db.query('select public.sr_replace_waypoints($1,1,$2)',[route,[{name:'Bad',latitude:333,longitude:120}]]),/invalid_waypoints/);
assert.equal(await scalar('select count(*) from public.user_route_waypoints'),2);
assert.equal(await scalar('select revision from public.user_routes'),1);
await denied(()=>db.query('update public.user_routes set user_id=$1 where id=$2',[editor,route]),/permission denied/);
assert.equal((await db.query('delete from public.user_routes where id=$1 returning id',[route])).rows.length,0);
await denied(()=>db.query("select public.sr_create_post('Not mine',$1)",[route]),/only_owner_can_publish/);
await actor(owner);
const readInvite=await scalar("select public.sr_create_invite($1,'viewer')",[route]);
const post=await scalar("select public.sr_create_post('A lake walk',$1)",[route]);
await actor(viewer);
await scalar('select public.sr_accept_invite($1)',[readInvite.token]);
assert.equal(await scalar('select access_role from public.route_access_index'),'viewer');
await denied(()=>db.query('select public.sr_replace_waypoints($1,1,$2)',[route,points]),/not_authorized/);
await scalar('select public.sr_set_like($1,true)',[post]);
await scalar('select public.sr_set_like($1,true)',[post]);
await scalar("select public.sr_add_comment($1,'Nice route')",[post]);
await actor(null);
const publicPost=await scalar('select public.sr_post($1)',[post]);
assert.equal(publicPost.like_count,1);
assert.equal(publicPost.comment_count,1);
assert.equal(publicPost.route_snapshot.waypoints.length,2);
assert.equal(publicPost.route_snapshot.date_range,undefined);
assert.equal(publicPost.route_snapshot.user_id,undefined);
assert.equal((await scalar('select public.sr_comments($1)',[post])).length,1);
await denied(()=>db.query('select * from public.user_routes'),/permission denied/);
await denied(()=>db.query('select * from public.route_invitations'),/permission denied/);
await denied(()=>db.query("select public.sr_create_post('Guest post')"),/permission denied/);
const preview=await scalar('select public.sr_invite_info($1)',[readInvite.token]);
assert.equal(preview.title,'Shared Hangzhou');
assert.equal(preview.invited_email,undefined);
assert.equal(preview.token,undefined);
await actor(owner);
await scalar('select public.sr_replace_waypoints($1,1,$2)',[route,[points[0]]]);
assert.equal((await scalar('select public.sr_post($1)',[post])).route_snapshot.waypoints.length,2);
await scalar('select public.sr_revoke_invite($1)',[readInvite.id]);
await scalar('select public.sr_remove_member($1,$2)',[route,editor]);
await actor(editor);
assert.equal(await scalar('select count(*) from public.user_routes'),0);
await denied(()=>db.query('select public.sr_replace_waypoints($1,2,$2)',[route,points]),/not_authorized/);
await actor(outsider);
await denied(()=>db.query('select public.sr_accept_invite($1)',[readInvite.token]),/invite_revoked/);
await denied(()=>db.query('select public.sr_delete_post($1)',[post]),/not_authorized/);
await actor(owner);
await scalar('select public.sr_delete_post($1)',[post]);
assert.equal((await scalar('select public.sr_feed()')).length,0);
// Existing viewers can accept a new editor invitation without being duplicated.
const upgrade=await scalar("select public.sr_create_invite($1,'editor')",[route]);
await actor(viewer);
await scalar('select public.sr_accept_invite($1)',[upgrade.token]);
assert.equal(await scalar('select access_role from public.route_access_index'),'editor');
await denied(()=>db.query('select public.sr_accept_invite(null,$1)',[upgrade.id]),/not_authorized/);
await denied(()=>db.query('select public.sr_remove_member($1,$2)',[route,owner]),/not_authorized/);
await db.exec('reset role');
await db.query("update public.route_invitations set expires_at=now()-interval '1 second' where id=$1",[upgrade.id]);
await actor(outsider);
await denied(()=>db.query('select public.sr_accept_invite($1)',[upgrade.token]),/invite_expired/);
await actor(null);
assert.equal((await scalar('select public.sr_invite_info($1)',[upgrade.token])).available,false);
await db.close();
console.log('PostgreSQL checks passed: invites, RLS, member listing, roles, atomic edits, conflicts, public snapshots and community interactions.');
