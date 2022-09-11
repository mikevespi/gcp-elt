begin;
select plan(2);

select has_schema('dem');
select matches(obj_description('dem'::regnamespace, 'pg_namespace'), '.+', 'Schema dem has a description');

select finish();
rollback;
