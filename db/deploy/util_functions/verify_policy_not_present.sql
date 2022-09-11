-- Deploy dem:database_functions/verify_policy_not_present to pg

begin;


-- Verifies if a policy exists
create or replace function dem_private.verify_policy_not_present(policy_name text, table_name text)
returns boolean
as
$function$
  declare
    table_oid oid;
    policy_exists boolean;
  begin

    -- Get the table OID
    execute format(
      $$
        select '%s'::regclass::oid
      $$ , table_name) into table_oid;

    -- Determine if policy exists with correct policy name, operation, role and table
    select exists(
      select * from pg_policy
        where polname = policy_name
        and polrelid = table_oid
    ) into policy_exists;

    -- Throw exception if true (necessary for sqitch)
    if (policy_exists = true) then
      raise exception 'Policy % on table % already exists', policy_name, table_name;
    end if;

    -- Else return true
    return true;
  end;
$function$
language 'plpgsql' stable;

comment on function dem_private.verify_policy_not_present(text, text) is
  'A generic function for testing the absence of policies on a table';

commit;
