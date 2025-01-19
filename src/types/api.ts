export interface IUpsertUserRequest {
    username: string;
    password: string;
    email: string;
    first_name: string;
    last_name: string;
    role_ids: Array<number>;
    reports_to: number;
}

export interface IUpsertUserResponse extends IUpsertUserRequest {
    id: number;
}

export interface IRoleClaim {
    resource_id: number;
    access_type: string;
    access_level: string;
}

export interface IUpsertRoleRequest {
    name: string;
    description: string;
    team: string;
    department: string;
    claims: Array<IRoleClaim>;
}

export interface IUpsertRoleResponse extends IUpsertRoleRequest {
    id: number;
}

export interface IUpsertAccessGrantsRequest {
    user_id: number;
    target_id: number;
    access_type: string;
    valid_from: Date;
    valid_until: Date;
}

export interface IUpsertAccessGrantsResponse extends IUpsertAccessGrantsRequest {
    id: number;
}

export interface IResourceTree {
    resource_id: number;
    name: string;
    children?: Array<IResourceTree>;
}

export interface IResourceTreeResponse extends IResourceTree {}

export interface ILogoutRequest {
    refresh_token: string;
}

export interface IRefreshRequest {
    refresh_token: string;
}

export interface ILoginRequest {
    username: string;
    password: string;
}

export type TAuthRequest = ILoginRequest | IRefreshRequest;

export interface IAuthResponse {
    access_token: string;
    refresh_token: string;
}
