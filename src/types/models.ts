export interface IUser {
  id: number;
  username: string;
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  reportsTo?: number;
  is_active: boolean;
  lua: Date;
  lub: number;
}

export interface IRole {
  id: number;
  name: string;
  description?: string;
  team?: string;
  department?: string;
  is_active: boolean;
  lua: Date;
  lub: number;
}

export interface IUserRole {
  id: number;
  user_id: number;
  is_active: boolean;
  lua: Date;
  lub: number;
}

export interface IAccessGrant {
  id: number;
  user_id: number;
  target_id: number;
  access_type: string;
  valid_from?: Date;
  valid_until?: Date;
  is_active: boolean;
  lua: Date;
  lub: number;
}

export interface IResource {
  id: number;
  name: string;
  description?: string;
  parent_id?: number;
  is_active: boolean;
  lua: Date;
  lub: number;
}

export interface IResourceAccessRole {
  id: number;
  resource_id: number;
  role_id: number;
  access_type: number;
  access_level: number;
  is_active: boolean;
  lua: Date;
  lub: number;
}

export interface IRefreshToken {
  id: number;
  user_id: number;
  token: string;
  expires_at: Date;
}

export interface IAccessibleResource {
    resource_id: number;
    role_id: number;
    role_name: string;
    access_type: string;
    access_level: string;
    parent_id: number;
}

export interface IResourceTreeNode extends IAccessibleResource {
    resource_id: number;

    children?: IResourceTreeNode[];
}

export interface IClaimConfig {
  resource_id: number;
  access_type: string;
  access_level: string;
}

export interface IUserClaimConfig extends IClaimConfig {
    user_id: number;
    role_id: number;
}

// outline
// 1. Whenever there is a change in resource table, update the resource tree in redis
// 2. Resource tree will only contain the information resource_id
// 3. Separately store the accessible resources for each user,
// when they access the resource_tree and it is not present in cache
// based on the accessible resources return the accessble tree branches from the resource tree

// store data is redis as follows-
// user-{userId}-role-{roleId}-res-{resourceId}-at-{accessType}-al-{accessLevel}
// whenever user to role mapping changes, clear the cache for that user and role


