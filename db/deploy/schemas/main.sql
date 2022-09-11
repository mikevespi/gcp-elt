-- Deploy dem:schema/dem to pg

begin;

create schema dem;
grant usage on schema dem to dem_internal, dem_external, dem_admin, dem_guest;
comment on schema dem is 'The main schema for the dem application.';

commit;
