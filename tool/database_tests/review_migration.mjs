import { PGlite } from "@electric-sql/pglite";
import { readFile } from "node:fs/promises";
import assert from "node:assert/strict";

const db = new PGlite();
const user = "00000000-0000-4000-8000-000000000001";
await db.exec("create role anon; create role authenticated; create role service_role bypassrls; create schema auth;");
await db.exec([
  "create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;",
  "create function auth.role() returns text language sql stable as $$select current_setting('request.jwt.claim.role',true)$$;",
  "create table public.profiles(id uuid primary key, role text default 'student', full_name text);",
  "create table public.ai_usage(user_id uuid, date date, request_count integer, last_request_at timestamptz, unique(user_id,date));",
  "create table public.attendance_records(id uuid, status text check(status in ('present','absent','postponed')));",
  "create table public.cached_academic_responses(id integer, response_payload jsonb);",
  "alter table public.profiles enable row level security;",
  "create policy own_profiles on public.profiles for all using(id=auth.uid()) with check(id=auth.uid());",
  "grant usage on schema public,auth to authenticated,anon,service_role;",
  "grant all on public.profiles,public.attendance_records,public.cached_academic_responses to authenticated;",
].join("\n"));
await db.query("select set_config('request.jwt.claim.sub',$1,false)", [user]);
await db.query("select set_config('request.jwt.claim.role','authenticated',false)");
await db.query("insert into profiles(id,role,full_name) values($1,'student','Original student')", [user]);
await db.exec("insert into cached_academic_responses values(1,'{}')");
const migration = await readFile(new URL("../../supabase/migrations/20261025_review_hardening.sql", import.meta.url), "utf8");
await db.exec(migration);
await db.exec(migration); // Safe to reapply.
await db.exec("set role authenticated");
await db.query("update profiles set full_name='Updated student' where id=$1", [user]);
await assert.rejects(db.query("update profiles set role='admin' where id=$1", [user]), /Profile roles/);
await assert.rejects(db.query("insert into profiles(id,role) values($1,'admin')", [user]), /Profile roles|row-level security/);
await assert.rejects(db.query("select * from cached_academic_responses"), /permission denied/);
await assert.rejects(db.query("select consume_ai_request($1)", [user]), /permission denied/);
await db.exec("insert into attendance_records(status) values('excused')");
await db.exec("reset role");
assert.equal((await db.query("select full_name from profiles where id=$1", [user])).rows[0].full_name, "Updated student");
assert.equal((await db.query("select count(*)::int n from cached_academic_responses")).rows[0].n, 1);
for (let i=0; i<50; i++) {
  assert.equal((await db.query("select consume_ai_request($1) allowed", [user])).rows[0].allowed, true);
}
assert.equal((await db.query("select consume_ai_request($1) allowed", [user])).rows[0].allowed, false);
await db.query("select set_config('request.jwt.claim.role','service_role',false)");
await db.query("update profiles set role='admin' where id=$1", [user]);
assert.equal((await db.query("select role from profiles where id=$1", [user])).rows[0].role, "admin");
await db.close();
console.log("Database regressions passed: role guards, cache isolation, quota, OD, idempotence and preserved rows.");
