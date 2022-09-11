begin;
select plan(2);

select has_schema('dem_private');
select matches(obj_description('dem_private'::regnamespace, 'pg_namespace'), '.+', 'Schema dem_private has a description');

select finish();
rollback;
