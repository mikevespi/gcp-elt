begin;
select plan(8);


select has_role( 'dem_internal', 'role dem_internal exists' );
select isnt_superuser(
    'dem_internal',
    'dem_internal should not be a super user'
);

select has_role( 'dem_external', 'role dem_external exists' );
select isnt_superuser(
    'dem_external',
    'dem_external should not be a super user'
);

select has_role( 'dem_admin', 'role dem_admin exists' );
select isnt_superuser(
    'dem_admin',
    'dem_admin should not be a super user'
);

select has_role( 'dem_guest', 'role dem_guest exists' );
select isnt_superuser(
    'dem_guest',
    'dem_guest should not be a super user'
);


select finish();
rollback;
