-- Deploy dem:tables/dem_user to pg

begin;
create table dem.dem_user
(
  id integer primary key generated always as identity,
  uuid uuid, -- not null, *Add back in when sessions added*
  given_name varchar(1000),
  family_name varchar(1000),
  email_address varchar(1000)
);

select dem_private.upsert_timestamp_columns('dem', 'dem_user');

create unique index dem_user_uuid on dem.dem_user(uuid);
create unique index dem_user_email_address on dem.dem_user(email_address);

do
$grant$
begin

-- Grant dem_internal permissions
perform dem_private.grant_permissions('select', 'dem_user', 'dem_internal');
perform dem_private.grant_permissions('insert', 'dem_user', 'dem_internal');
perform dem_private.grant_permissions('update', 'dem_user', 'dem_internal',
  ARRAY['given_name', 'family_name', 'email_address', 'created_at', 'created_by', 'updated_at', 'updated_by', 'archived_at', 'archived_by']);

-- Grant dem_external permissions
perform dem_private.grant_permissions('select', 'dem_user', 'dem_external');
perform dem_private.grant_permissions('insert', 'dem_user', 'dem_external');
perform dem_private.grant_permissions('update', 'dem_user', 'dem_external',
  ARRAY['given_name', 'family_name', 'email_address', 'created_at', 'created_by', 'updated_at', 'updated_by', 'archived_at', 'archived_by']);

-- Grant dem_admin permissions
perform dem_private.grant_permissions('select', 'dem_user', 'dem_admin');
perform dem_private.grant_permissions('insert', 'dem_user', 'dem_admin');
perform dem_private.grant_permissions('update', 'dem_user', 'dem_admin',
  ARRAY['given_name', 'family_name', 'email_address', 'created_at', 'created_by', 'updated_at', 'updated_by', 'archived_at', 'archived_by']);


-- Grant dem_guest permissions
perform dem_private.grant_permissions('select', 'dem_user', 'dem_guest');

end
$grant$;

-- Enable row-level security
alter table dem.dem_user enable row level security;

do
$policy$
begin
-- dem_admin RLS
perform dem_private.upsert_policy('dem_admin_select_dem_user', 'dem_user', 'select', 'dem_admin', 'true');
perform dem_private.upsert_policy('dem_admin_insert_dem_user', 'dem_user', 'insert', 'dem_admin', 'true');
perform dem_private.upsert_policy('dem_admin_update_dem_user', 'dem_user', 'update', 'dem_admin', 'true');



-- dem_internal RLS: can see all users, but can only modify its own record
perform dem_private.upsert_policy('dem_internal_select_dem_user', 'dem_user', 'select', 'dem_internal', 'true');
perform dem_private.upsert_policy('dem_internal_insert_dem_user', 'dem_user', 'insert', 'dem_internal', 'true'); -- switch final true to uuid=(select sub from cif.session()) once sessions added
perform dem_private.upsert_policy('dem_internal_update_dem_user', 'dem_user', 'update', 'dem_internal', 'true'); -- switch final true to uuid=(select sub from cif.session()) once sessions added

-- dem_external RLS: can see all users, but can only modify its own record
perform dem_private.upsert_policy('dem_external_select_dem_user', 'dem_user', 'select', 'dem_external', 'true');
perform dem_private.upsert_policy('dem_external_insert_dem_user', 'dem_user', 'insert', 'dem_external', 'true'); -- switch final true to uuid=(select sub from cif.session()) once sessions added
perform dem_private.upsert_policy('dem_external_update_dem_user', 'dem_user', 'update', 'dem_external', 'true'); -- switch final true to uuid=(select sub from cif.session()) once sessions added


-- dem_guest RLS: can only see its own (empty) record
perform dem_private.upsert_policy('dem_guest_select_dem_user', 'dem_user', 'select', 'dem_guest', 'true'); -- switch final true to uuid=(select sub from cif.session()) once sessions added

end
$policy$;

comment on table dem.dem_user is 'Table containing information about the application''s users ';
comment on column dem.dem_user.id is 'Unique ID for the user';
comment on column dem.dem_user.uuid is 'Universally Unique ID for the user, defined by the single sign-on provider';
comment on column dem.dem_user.given_name is 'User''s first name';
comment on column dem.dem_user.family_name is 'User''s last name';
comment on column dem.dem_user.email_address is 'User''s email address';

commit;
