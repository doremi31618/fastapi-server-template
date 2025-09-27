#!/bin/bash

# Create directory structure
mkdir -p app/core
mkdir -p app/middleware
mkdir -p app/shared
mkdir -p app/api/v1
mkdir -p app/modules/auth/domain
mkdir -p app/modules/auth/infra

# Create main application files
touch app/main.py
touch app/api/v1/router.py
touch app/api/v1/auth.py

# Create core files
touch app/core/config.py
touch app/core/security.py

# Create middleware files
touch app/middleware/timings.py

# Create shared files
touch app/shared/db.py
touch app/shared/utils.py

# Create auth module files
touch app/modules/auth/schemas.py
touch app/modules/auth/services.py
touch app/modules/auth/deps.py

# Create auth domain files
touch app/modules/auth/domain/models.py
touch app/modules/auth/domain/ports.py

# Create auth infrastructure files
touch app/modules/auth/infra/orm.py
touch app/modules/auth/infra/repositories.py
touch app/modules/auth/infra/token_jwt.py

echo "FastAPI project structure created successfully!"