export {};
// outline
// 1. Whenever there is a change in resource table, update the resource tree in redis
// 2. Resource tree will only contain the information resource_id
// 3. Separately store the accessible resources for each user,
// when they access the resource_tree and it is not present in cache
// based on the accessible resources return the accessble tree branches from the resource tree
// store data is redis as follows-
// user-{userId}-role-{roleId}-res-{resourceId}-at-{accessType}-al-{accessLevel}
// whenever user to role mapping changes, clear the cache for that user and role
