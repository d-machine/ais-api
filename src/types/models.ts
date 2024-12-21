export interface User {
  id: number;
  username: string;
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  reporting_manager_id?: number | null;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface Role {
  id: number;
  name: string;
  description?: string;
  team?: string;
  department?: string;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface UserRole {
  id: number;
  user_id: number;
  role_id: number;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface AccessType {
  id: number;
  name: string;
  description?: string;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface AccessGrant {
  id: number;
  user_id: number;
  target_id: number;
  access_type_id: number;
  valid_from?: Date;
  valid_until?: Date;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface Resource {
  id: number;
  name: string;
  description?: string;
  parent_id?: number;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface ResourceAccessRole {
  id: number;
  resource_id: number;
  role_id: number;
  access_type_id: number;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface HierarchyClosure {
  id: number;
  ancestor_id: number;
  descendant_id: number;
  depth: number;
  last_updated_at: Date;
  last_updated_by: number;
}

export interface RefreshToken {
  id: number;
  user_id: number;
  token: string;
  expires_at: Date;
  last_updated_at: Date;
  last_updated_by: number;
} 