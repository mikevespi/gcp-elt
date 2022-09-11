-- Deploy dem:schema/dem_private to pg

begin;

create schema dem_private;
grant usage on schema dem_private to dem_internal, dem_external, dem_admin;
comment on schema dem_private is 'The private schema for the demo application. It contains utility functions which should not be available directly through the API.';

commit;
