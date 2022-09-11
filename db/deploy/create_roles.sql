-- Deploy dem:create_roles to pg

begin;

-- The create roles affects the database globally. Cannot drop the roles once created.
do
$do$
begin

  if not exists (
    select true
    from   pg_catalog.pg_roles
    where  rolname = 'dem_internal') then

    create role dem_internal;
  end if;

  if not exists (
    select true
    from   pg_catalog.pg_roles
    where  rolname = 'dem_external') then

    create role dem_external;
  end if;

  if not exists (
    select true
    from   pg_catalog.pg_roles
    where  rolname = 'dem_admin') then

    create role dem_admin;
  end if;

  if not exists (
    select true
    from   pg_catalog.pg_roles
    where  rolname = 'dem_guest') then

    create role dem_guest;
  end if;

  if not exists (
    select true
    from   pg_catalog.pg_roles
    where  rolname = 'demapp') then

    create user demapp;
  end if;

  grant dem_admin, dem_internal, dem_external, dem_guest to demapp;
  execute format('grant create, connect on database %I to demapp', current_database());

end
$do$;

commit;
