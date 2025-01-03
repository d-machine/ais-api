export interface IUser {
  id: number;
  username: string;
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  reportsTo?: number;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface IRole {
  id: number;
  name: string;
  description?: string;
  team?: string;
  department?: string;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface IUserRole {
  id: number;
  user_id: number;
  role_id: number;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface IAccessGrant {
  id: number;
  user_id: number;
  target_id: number;
  access_type: string;
  valid_from?: Date;
  valid_until?: Date;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface IResource {
  id: number;
  name: string;
  description?: string;
  parent_id?: number;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface IResourceAccessRole {
  id: number;
  resource_id: number;
  role_id: number;
  access_type: number;
  access_level: number;
  last_updated_at: Date;
  last_updated_by: number;
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
    children?: IResourceTreeNode[];
}
