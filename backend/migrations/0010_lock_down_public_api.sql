-- 0010 · Turn on Row Level Security for every app table.
--
-- Why: on Supabase, every table in the `public` schema is exposed through Supabase's auto-generated
-- REST/GraphQL API to anyone holding the project's public "anon" key. With RLS enabled and no
-- policies, that API can read and write nothing.
--
-- Our backend is unaffected: it connects as the table owner (`postgres` on Supabase, the master user
-- on RDS), and owners bypass RLS. On plain Postgres / RDS this migration is harmless.
-- New tables in later migrations must also run `ALTER TABLE … ENABLE ROW LEVEL SECURITY`.

DO $$
DECLARE t record;
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.tablename);
  END LOOP;
END $$;

-- Belt and braces: if Supabase's API roles exist, take away their access to our tables and sequences.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated;
    REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;
    REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon, authenticated;
  END IF;
END $$;
