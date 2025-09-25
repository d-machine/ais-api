# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Initial Setup
```bash
npm install
docker-compose --env-file .env.development build api
docker-compose --env-file .env.development up -d
```

### Database Initialization (one-time setup)
```bash
curl --location --request POST 'localhost:3000/api/storage/initializeDatabase'
curl --location --request POST 'localhost:3000/api/storage/loadConfigs'
```

### Development Workflow
```bash
# Start development server with hot reload
npm run dev

# Build TypeScript to JavaScript
npm run build

# Start production server
npm start

# Run individual containers
docker-compose --env-file .env.development up postgres -d
docker-compose --env-file .env.development up redis -d
docker-compose --env-file .env.development up api -d

# Check application health
curl localhost:3000/health

# Environment setup
cp .env.example .env.development
# Edit .env.development with your configuration
```

### Docker Management
```bash
# Rebuild and restart all services
docker-compose --env-file .env.development down
docker-compose --env-file .env.development build
docker-compose --env-file .env.development up -d

# View logs
docker-compose logs api
docker-compose logs postgres
docker-compose logs redis

# Connect to PostgreSQL container for debugging
docker exec -it ais_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

# Complete environment reset (removes all data)
docker-compose --env-file .env.development down -v
```

## Architecture Overview

### Technology Stack
- **Runtime**: Node.js 20 with TypeScript (ES Modules)
- **Web Framework**: Hono.js with middleware for CORS, logging, timing, and pretty JSON
- **Database**: PostgreSQL 15 with connection pooling
- **Cache**: Redis 7 with memory optimization
- **Authentication**: JWT with refresh tokens
- **Container**: Docker with multi-stage builds

### Core Application Structure

The application follows a layered architecture pattern:

**Entry Point** (`src/index.ts`)
- Configures Hono app with middleware stack
- Sets up error handling and CORS
- Initializes database and cache connections before server start
- Implements graceful shutdown handling

**Service Layer Architecture**
- `BaseService`: Abstract base class providing database query execution patterns
- All services inherit from BaseService for consistent data access
- Query execution abstracted through different return type methods (scalar, single row, multiple rows)

**Authentication & Authorization System**
- Role-based access control with hierarchical resources
- JWT authentication with refresh token support
- Resource tree caching in Redis for performance
- Complex permission model supporting access types and levels

**Database Layer**
- Singleton pattern for database connection management
- Connection pooling with health checks
- Sequential SQL file execution for database schema setup
- Support for multiple query return types (scalar, single row, multiple rows)

**Route Organization**
- `/api/storage`: Database management and configuration loading
- `/api/auth`: Authentication, user management, and role assignment
- `/api/generic`: General-purpose API endpoints
- `/health`: Application health monitoring

### Key Components

**Database Setup Flow**
1. Execute schema.sql for base structure
2. Create authentication tables (user, role, resource, etc.)
3. Set up geographical data tables (country, state, city, district)
4. Initialize business domain tables (transport, material, warehouse, broker, party)
5. Create order management tables (purchase_order, sales_order, picking_list)
6. Load initial data and query functions

**Caching Strategy**
- User permissions cached with pattern: `user-{userId}-role-{roleId}-res-{resourceId}-at-{accessType}-al-{accessLevel}`
- Resource tree stored in Redis for hierarchical access control
- Cache invalidation on user-role mapping changes

**Environment Configuration**
- Uses `.env.development` for Docker Compose configuration
- Supports PostgreSQL, Redis, and JWT configuration
- Admin user setup through environment variables

## Config-Driven Architecture

This API is **heavily config-driven**, with YAML/JSON configuration files defining UI forms, data tables, queries, and business logic.

### Configuration Structure

**Config Location**: All configuration files are stored in `data/fs/configs/`

**Config Types**:
- **List Configs**: Define data tables with columns, actions, queries, and filters (e.g., `list-users.yaml`, `list-categories.yaml`)
- **Form Configs**: Define input forms with fields, validation, and save actions (e.g., `add-user.yaml`, `add-role.yaml`)
- **Mixed Configs**: Support both sections and multiple interaction patterns

### Config File Anatomy

**List Configuration Pattern**:
```yaml
actionType: EXECUTE_QUERY
queryInfo:
  returnType: MULTIPLE_ROWS
  query: |
    SELECT id, name, email FROM users WHERE active = true
  options:
    applyFiltering: true
    applySorting: true
    applyPagination: true
applicableActions:
  - add
  - edit
  - delete
actionConfig:
  add:
    label: Add User
    actionType: DISPLAY_FORM
    formConfig: add-user
    accessTypeRequired: 6-ADD
columns:
  - name: username
    label: Username
    sortable: true
    filterType: string
```

**Form Configuration Pattern**:
```yaml
sections:
  - sectionType: FIELDS
    sectionName: User Details
    queryInfo:
      returnType: SINGLE_ROW
      query: SELECT * FROM users WHERE id = $1
      payload: [user_id]
    applicableActions: [SAVE, CANCEL]
    actionConfig:
      SAVE:
        actionType: EXECUTE_QUERY
        queryInfo:
          query: SELECT insert_user($1, $2, $3) as id
          payload: [username, email, password]
    fields:
      - name: username
        label: Username
        type: TEXT
        required: true
      - name: password
        label: Password
        type: PASSWORD
        required: true
```

### Key Configuration Concepts

**Query Return Types**:
- `SCALAR`: Single value
- `SINGLE_ROW`: One database row
- `MULTIPLE_ROWS`: Array of rows
- `SCALAR_ARRAY`: Array of scalar values

**Action Types**:
- `EXECUTE_QUERY`: Run database query
- `DISPLAY_FORM`: Show form interface
- `FUNCTION_CALL`: Execute JavaScript function

**Field Types**:
- `TEXT`, `TEXTAREA`, `PASSWORD`
- `SELECT` (with `multi: true/false`)
- Complex select configurations with `selectConfig`

**Access Control**:
- `accessTypeRequired`: Format like `{resourceId}-{ACTION}` (e.g., `6-ADD`, `7-EDIT`)
- Automatically filtered based on user permissions

### Configuration Loading Process

1. **Startup**: All YAML/JSON configs loaded into Redis cache via `/api/storage/loadConfigs`
2. **Runtime**: Configs retrieved from cache, parsed, and permission-filtered per user
3. **Query Building**: Dynamic query construction with pagination, sorting, filtering
4. **Action Execution**: Config-driven query execution with parameter binding

### Adding New Features

To add new functionality:
1. Create SQL tables in `data/fs/setup-queries/`
2. Add list config YAML for data display
3. Add form config YAML for data entry/editing
4. Define access permissions in role claims
5. Reload configs via API endpoint

**No code changes required** - everything is configuration-driven!

## Development Notes

### Configuration-Driven Architecture
- YAML files in `/data/fs/configs/` define API endpoints and form configurations
- Dynamic query execution based on configuration files
- Use `loadConfigs` endpoint after modifying YAML configurations

### Query Execution Patterns
The `BaseService` class provides typed query execution methods:
```typescript
// For single values
this.executeScalarQuery(query, params)

// For single rows
this.executeSingleRowQuery(query, params)

// For multiple rows
this.executeMultipleRowsQuery(query, params)
```

### Hot Reload Development
- Use `npm run dev` for TypeScript hot reloading via `tsx`
- Docker volume mounts `/src` for live code updates in containers
- Database schema changes require calling `initializeDatabase` endpoint

### Important File Locations
- `/src/storage/db.ts` - Database connection and query execution
- `/src/storage/cache.ts` - Redis connection management  
- `/data/fs/setup-queries/` - SQL schema files (executed in specific order)
- `/data/fs/configs/` - YAML configuration files for dynamic endpoints
- `/src/types/models.ts` - TypeScript interfaces for database entities

## Business Domain

This API manages a comprehensive business system including:
- **User Management**: Authentication, authorization, and role-based access
- **Geographical Data**: Country, state, city, district, and address management
- **Inventory**: Material management with categories, brands, and units of measure
- **Warehouse Operations**: Palette and warehouse management
- **Trading**: Broker and party management
- **Order Processing**: Purchase orders, sales orders, and picking lists
- **Transport Management**: Logistics and shipping coordination

The system implements a sophisticated permission model where resources are organized hierarchically, and users can have different access types and levels based on their assigned roles.

## Development Notes

### Configuration-Driven Architecture
- YAML files in `/data/fs/configs/` define API endpoints and form configurations
- Dynamic query execution based on configuration files
- Use `loadConfigs` endpoint after modifying YAML configurations

### Query Execution Patterns
The `BaseService` class provides typed query execution methods:
```typescript
// For single values
this.executeScalarQuery(query, params)

// For single rows
this.executeSingleRowQuery(query, params)

// For multiple rows
this.executeMultipleRowsQuery(query, params)
```

### Hot Reload Development
- Use `npm run dev` for TypeScript hot reloading via `tsx`
- Docker volume mounts `/src` for live code updates in containers
- Database schema changes require calling `initializeDatabase` endpoint

### Important File Locations
- `/src/storage/db.ts` - Database connection and query execution
- `/src/storage/cache.ts` - Redis connection management  
- `/data/fs/setup-queries/` - SQL schema files (executed in specific order)
- `/data/fs/configs/` - YAML configuration files for dynamic endpoints
- `/src/types/models.ts` - TypeScript interfaces for database entities
