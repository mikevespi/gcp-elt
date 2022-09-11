begin;

select plan(5);

select has_function('dem_private', 'read_only_user_policies', 'function dem_private.read_only_user_policies exists');
create role test_role;

select dem_private.read_only_user_policies('test_role');

select is(
  (select dem_private.verify_policy('select', 'test_role_select_dem_user', 'dem_user', 'test_role')),
  true,
  'test_role_select_dem_user policy is created'
);

select throws_like(
  $$select dem_private.verify_policy('insert', 'test_role_insert_dem_user', 'dem_user', 'test_role')$$,
  'Policy % does not exist',
  'test_role_insert_dem_user policy is not created'
);

select throws_like(
  $$select dem_private.verify_policy('update', 'test_role_update_dem_user', 'dem_user', 'test_role')$$,
  'Policy % does not exist',
  'test_role_update_dem_user policy is not created'
);

select throws_like(
  $$select dem_private.verify_policy('delete', 'test_delete_select_dem_user', 'dem_user', 'test_role')$$,
  'Policy % does not exist',
  'test_role_delete_dem_user policy is not created'
);

rollback;
