-- Preview mint only: store a hash of the guest seat key so a join can be
-- refreshed or released without keeping the raw key. Existing seats may
-- have a null hash and cannot be reclaimed.
alter table belong_guest.stream_call_guest_sessions
  add column if not exists session_hash text;

alter table belong_guest.stream_call_guest_sessions
  drop constraint if exists stream_call_guest_sessions_session_hash_check;

alter table belong_guest.stream_call_guest_sessions
  add constraint stream_call_guest_sessions_session_hash_check
  check (session_hash is null or session_hash ~ '^[a-f0-9]{64}$');

drop function if exists belong_guest.claim_guest(text, text, text, bigint, bigint, integer);

create or replace function belong_guest.claim_guest(
  p_call text,
  p_guest text,
  p_hash text,
  p_session text,
  p_now bigint,
  p_ttl bigint,
  p_limit integer
)
returns jsonb
language plpgsql
set search_path to ''
as $function$
declare
  same_hash text;
  active_count integer;
begin
  if p_session is null or p_session !~ '^[a-f0-9]{64}$' then
    return jsonb_build_object('ok', false, 'reason', 'cap');
  end if;
  perform pg_advisory_xact_lock(hashtextextended('belong_guest:' || p_call, 0));
  select invite_hash into same_hash from belong_guest.stream_call_guest_sessions
   where call_id = p_call and guest_user_id = p_guest and expires_at > p_now;
  if same_hash is not null and same_hash <> p_hash then
    return jsonb_build_object('ok', false, 'reason', 'conflict');
  end if;
  if same_hash is null then
    select count(*) into active_count from belong_guest.stream_call_guest_sessions
     where call_id = p_call and expires_at > p_now;
    if active_count >= p_limit then
      return jsonb_build_object('ok', false, 'reason', 'cap');
    end if;
  end if;
  insert into belong_guest.stream_call_guest_sessions(call_id, guest_user_id, invite_hash, session_hash, expires_at)
  values (p_call, p_guest, p_hash, p_session, p_now + p_ttl)
  on conflict (call_id, guest_user_id)
  do update set invite_hash = excluded.invite_hash,
                session_hash = excluded.session_hash,
                expires_at = excluded.expires_at;
  return jsonb_build_object('ok', true, 'renewed', same_hash is not null,
                            'guestUserId', p_guest, 'expiresAt', p_now + p_ttl);
end
$function$;
