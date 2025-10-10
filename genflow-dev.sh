#!/usr/bin/env sh

# POSIX-compliant development environment setup script.
# Works on macOS, Linux and WSL2. When run non-interactively (e.g. piped to sh),
# it will use sensible defaults and will not prompt for input.

set -eu

DEFAULT_WORKSPACE_DIR="$HOME/genboard"

# If stdin is a terminal, prompt the user; otherwise use defaults (safe for curl | sh)
if [ -t 0 ]; then
    printf 'Enter workspace directory location [%s]: ' "$DEFAULT_WORKSPACE_DIR"
    if ! read WORKSPACE_DIR; then
        WORKSPACE_DIR=
    fi
else
    WORKSPACE_DIR=
fi

WORKSPACE_DIR="${WORKSPACE_DIR:-$DEFAULT_WORKSPACE_DIR}"

printf 'Workspace will be set up at: %s\n' "$WORKSPACE_DIR"

# Ask user if they want to set up an alias for devstack (interactive only)
SET_ALIAS="n"
if [ -t 0 ]; then
    printf '\nDo you want to set up an alias \''devstack\'' for easier startup of development containers? [y/N]: '
    if read ANS; then
        case "$ANS" in
            [Yy]* ) SET_ALIAS="y" ;;
            * ) SET_ALIAS="n" ;;
        esac
    fi
fi

if [ "$SET_ALIAS" = "y" ]; then
    # Decide which rc file to edit. Prefer user's shell if available, fall back to common files.
    SHELL_RC=""
    if [ -n "${SHELL:-}" ]; then
        case "$(basename "$SHELL")" in
            zsh) SHELL_RC="$HOME/.zshrc" ;;
            bash) SHELL_RC="$HOME/.bashrc" ;;
            *) SHELL_RC="$HOME/.profile" ;;
        esac
    else
        # Fallback order
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_RC="$HOME/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            SHELL_RC="$HOME/.bashrc"
        else
            SHELL_RC="$HOME/.profile"
        fi
    fi

    ALIAS_CMD="alias devstack='docker compose -f $WORKSPACE_DIR/devstack/compose.yml'"

    # Ensure rc file exists
    if [ ! -f "$SHELL_RC" ]; then
        # create an empty rc file so grep won't fail
        : > "$SHELL_RC"
    fi

    # Append alias if not already present
    if ! grep -F -x -q "$ALIAS_CMD" "$SHELL_RC" 2>/dev/null; then
        printf '%s\n' "$ALIAS_CMD" >> "$SHELL_RC"
        printf "Alias 'devstack' added to %s\n" "$SHELL_RC"
    else
        printf "Alias 'devstack' already present in %s\n" "$SHELL_RC"
    fi
fi

printf 'Setting up workspace directory at %s\n' "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR"

# Navigate to the workspace directory
if ! cd "$WORKSPACE_DIR" 2>/dev/null; then
    printf 'Failed to change directory to %s\n' "$WORKSPACE_DIR" >&2
    exit 1
fi

# Clone the repositories if they don't exist (SSH URLs; ensure keys/access set up)
if [ ! -d "devstack" ]; then
    git clone git@github.com:GenBoard-FIIT/devstack.git
fi

if [ ! -d "frontend" ]; then
    git clone git@github.com:GenBoard-FIIT/frontend.git
fi

if [ ! -d "backend" ]; then
    git clone git@github.com:GenBoard-FIIT/backend.git
fi

# Navigate to the devstack directory for compose operations
if ! cd devstack 2>/dev/null; then
    printf 'Failed to change directory to %s/devstack\n' "$WORKSPACE_DIR" >&2
    exit 1
fi

printf '\n\nDevelopment environment setup complete. Navigate to %s and start coding!\n' "$WORKSPACE_DIR"
printf 'To start the devstack in the future, simply run "devstack up -d" from your terminal.\n\n'

printf 'Running initial setup for backend and frontend...\n\n'

# Backend setup (best-effort; these commands assume docker & composer are available)
docker compose -f compose.yml run --rm backend composer install || printf 'Warning: composer install failed or composer not available\n'

docker compose -f compose.yml up -d database || printf 'Warning: starting database container failed\n'

docker compose -f compose.yml run --rm backend bin/console doctrine:database:create --if-not-exists || true
docker compose -f compose.yml run --rm backend bin/console doctrine:migrations:migrate --no-interaction || true
docker compose -f compose.yml run --rm backend bin/console doctrine:fixtures:load --no-interaction || true

printf 'Initial setup for backend and frontend completed.\n'

# Start the Docker containers
docker compose -f compose.yml up -d --build || printf 'Warning: docker compose up failed\n'

printf '\nYou can now access the following services:\n'
printf 'Backend: http://localhost:80\n'
printf 'Frontend: http://localhost:3000\n'
printf 'Database available at: localhost:5432 (user: user, password: password, db: app)\n\n'
printf 'Happy coding!\n'
