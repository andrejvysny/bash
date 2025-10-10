#!/usr/bin/sh

# This script is used to set up the development environment for the project.

# Ask user for workspace directory location
DEFAULT_WORKSPACE_DIR="$HOME/genboard"
read -p "Enter workspace directory location [$DEFAULT_WORKSPACE_DIR]: " WORKSPACE_DIR
WORKSPACE_DIR="${WORKSPACE_DIR:-$DEFAULT_WORKSPACE_DIR}"

echo "Workspace will be set up at: ${WORKSPACE_DIR}"

# Ask user if they want to set up an alias for devstack
read -p $'\nDo you want to set up an alias \'devstack\' to run this script? [y/N]: ' SET_ALIAS
if [[ "$SET_ALIAS" =~ ^[Yy]$ ]]; then
    ALIAS_CMD="alias devstack=\"docker compose -f $WORKSPACE_DIR/devstack/compose.yml\""
    # Detect OS and choose shell rc file
    if [[ "$(uname)" == "Darwin" ]]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
    if ! grep -Fxq "$ALIAS_CMD" "$SHELL_RC"; then
        echo "$ALIAS_CMD" >> "$SHELL_RC"
        echo "Alias 'devstack' added to $SHELL_RC"
    else
        echo "Alias 'devstack' already exists in $SHELL_RC"
    fi
fi

echo "Setting up workspace directory at $WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR"

# Navigate to the workspace directory
cd "$WORKSPACE_DIR" || { echo "Failed to change directory to $WORKSPACE_DIR
"; exit 1; }

# Clone the repository if it doesn't exist
if [ ! -d "devstack" ]; then
    git clone git@github.com:GenBoard-FIIT/devstack.git
fi

if [ ! -d "frontend" ]; then
    git clone git@github.com:GenBoard-FIIT/frontend.git
fi

if [ ! -d "backend" ]; then
    git clone git@github.com:GenBoard-FIIT/backend.git
fi


# Navigate to the devstack directory
cd devstack || { echo "Failed to change directory to $WORKSPACE_DIR/devstack
"; exit 1; }

echo "\n\nDevelopment environment setup complete. Navigate to $WORKSPACE_DIR and start coding!"
echo "\nTo start the devstack in the future, simply run 'devstack up -d' from your terminal.\n"


echo "Running initial setup for backend and frontend...\n\n\n"


# Backend setup
docker compose -f compose.yml run --rm backend composer install

docker compose -f compose.yml up -d database

docker compose -f compose.yml run --rm backend bin/console doctrine:database:create --if-not-exists
docker compose -f compose.yml run --rm backend bin/console doctrine:migrations:migrate --no-interaction
docker compose -f compose.yml run --rm backend bin/console doctrine:fixtures:load --no-interaction


echo "\nInitial setup for backend and frontend completed."

# Start the Docker containers
docker compose -f compose.yml up -d --build

echo "\n\n\nYou can now access the following services:"
echo "Backend: http://localhost:80"
echo "Frontend: http://localhost:3000"
echo "Database available at: localhost:5432 (user: user, password: password, db: app)"
echo "\n\nHappy coding!"
