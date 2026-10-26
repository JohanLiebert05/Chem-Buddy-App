-- Apply after all existing migrations. Existing academic records are preserved.
begin;

create or replace function public.protect_profile_role()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    if (TG_OP = 'INSERT' and coalesce(new.role, 'student') <> 'student')
       or (TG_OP = 'UPDATE' and new.role is distinct from old.role) then
      raise exception 'Profile roles can only be changed by a trusted server administrator'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role before insert or update on public.profiles
for each row execute function public.protect_profile_role();

-- Keep old cache rows inaccessible to app clients; the orchestrator no longer uses this cache.
drop policy if exists "Allow public read on cached academic responses" on public.cached_academic_responses;
drop policy if exists "Allow authenticated or service-role write on cached academic responses" on public.cached_academic_responses;
drop policy if exists "Allow update hit_count on cached academic responses" on public.cached_academic_responses;
revoke all on public.cached_academic_responses from anon, authenticated;
grant all on public.cached_academic_responses to service_role;

alter table public.attendance_records drop constraint if exists attendance_records_status_check;
alter table public.attendance_records add constraint attendance_records_status_check
check (status in ('present', 'absent', 'postponed', 'excused'));

-- One atomic request reservation, including concurrent requests. Fail closed if unavailable.
create or replace function public.consume_ai_request(requested_user uuid)
returns boolean language plpgsql security definer set search_path = public as $$
declare consumed integer;
begin
  insert into public.ai_usage(user_id, date, request_count, last_request_at)
  values (requested_user, current_date, 1, now())
  on conflict (user_id, date) do update
    set request_count = ai_usage.request_count + 1, last_request_at = now()
    where ai_usage.request_count < 50
  returning request_count into consumed;
  return consumed is not null;
end;
$$;
revoke all on function public.consume_ai_request(uuid) from public, anon, authenticated;
grant execute on function public.consume_ai_request(uuid) to service_role;
commit;
