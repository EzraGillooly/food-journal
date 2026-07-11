-- Dev-only: seed pre-confirmed auth users so you can log in without the
-- email-confirmation round trip (Supabase's built-in SMTP is rate-limited).
--
-- HOW TO RUN: Supabase dashboard -> SQL Editor -> paste -> Run.
-- Edit the emails/passwords below first if you like. Safe to re-run: existing
-- emails are skipped.
--
-- This creates TWO accounts on purpose — account B is needed later to prove
-- cross-account RLS isolation (CP-2).
--
-- NOT a migration. Never run against production data.

create extension if not exists pgcrypto;

do $$
declare
  seed record;
  new_id uuid;
begin
  for seed in
    select * from (values
      ('friend@foodjournal.dev',  'journal123'),
      ('tester@foodjournal.dev',  'journal123')
    ) as t(email, password)
  loop
    -- Skip if this email already exists.
    if exists (select 1 from auth.users where email = seed.email) then
      raise notice 'skip %, already exists', seed.email;
      continue;
    end if;

    new_id := gen_random_uuid();

    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      confirmation_token, recovery_token,
      email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000',
      new_id, 'authenticated', 'authenticated', seed.email,
      crypt(seed.password, gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}', '{}',
      '', '', '', ''
    );

    -- GoTrue requires a matching identity row for email/password login.
    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), new_id,
      jsonb_build_object('sub', new_id::text, 'email', seed.email),
      'email', new_id::text,
      now(), now(), now()
    );

    raise notice 'created %', seed.email;
  end loop;
end $$;
