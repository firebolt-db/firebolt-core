#!/bin/bash
# <h2 style="color:red">Get Firebolt with:</h2><code>curl -fsSL https://get.firebolt.io/ | bash</code><br /><br /><br /><pre>
set -e

# Parse command line arguments
AUTO_RUN=false
if [ "$1" = "--auto-run" ]; then
    AUTO_RUN=true
elif [ -n "$1" ]; then
    echo "Unknown option: $1"
    echo "Usage: $0 [--auto-run]" 1>&2
    exit 1
fi

# When the script is piped in (e.g. 'curl | bash'), stdin is not a terminal
# and the user cannot answer prompts through it, so run without prompting.
if [ ! -t 0 ]; then
    AUTO_RUN=true
fi

banner() {
    echo -e "\e[31m"
    echo "███████╗██╗██████╗ ███████╗██████╗  ██████╗ ██╗  ████████╗"
    echo "██╔════╝██║██╔══██╗██╔════╝██╔══██╗██╔═══██╗██║  ╚══██╔══╝"
    echo "█████╗  ██║██████╔╝█████╗  ██████╔╝██║   ██║██║     ██║   "
    echo "██╔══╝  ██║██╔══██╗██╔══╝  ██╔══██╗██║   ██║██║     ██║   "
    echo "██║     ██║██║  ██║███████╗██████╔╝╚██████╔╝███████╗██║   "
    echo "╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚═╝   "
    echo -e "\e[0m"
    echo "       The Analytical Database for Engineers"
    echo "       © 2026 Firebolt Analytics Inc (https://firebolt.io)"
    echo ""
    echo "       🔥🔥🔥 Setup script for Firebolt 🔥🔥🔥"
    echo ""
}

IS_MACOS=0
if [ "$(uname)" = "Darwin" ]; then
    IS_MACOS=1
fi

# Docker image to pull - allow specifying overrides via env variables
ENGINE_REPO="${ENGINE_REPO:-ghcr.io/firebolt-db/engine}"
ENGINE_TAG="${ENGINE_TAG:-dev}"
DOCKER_IMAGE="${ENGINE_REPO}:${ENGINE_TAG}"
EXTERNAL_PORT=3473
# Generated engine config, dropped into the data directory (used on macOS only,
# see below). It is auto-loaded by the engine as /var/lib/firebolt/config.yaml.
CONFIG_FILE="firebolt-data/config.yaml"
DOCKER_CONTAINER_NAME="firebolt"
DOCKER_RUN_ARGS=(
  -i
  --name $DOCKER_CONTAINER_NAME
  --rm
  --ulimit memlock=8589934592:8589934592
  --security-opt seccomp=unconfined
  -v "$(pwd)/firebolt-data:/var/lib/firebolt"
  -p "$EXTERNAL_PORT:3473"
)
# On macOS the Docker Desktop file-sharing backend cannot stat the engine's Unix
# domain socket when it lives on the bind-mounted data directory, so Firebolt
# fails to start. Keep the socket off the shared filesystem: put it on an
# in-memory tmpfs at /run/firebolt and relocate it there via the generated
# config file. Mirror the ownership/permissions the image ships /run/firebolt
# with (firebolt:root, mode 2770) so both root and the non-root firebolt user
# (uid 3473, group 0) can create the socket.
if [ $IS_MACOS -eq 1 ]; then
    DOCKER_RUN_ARGS+=( --tmpfs /run/firebolt:rw,mode=2770,uid=3473,gid=0 )
fi
DOCKER_RUN_ARGS+=( "$DOCKER_IMAGE" )

# Engine config that moves the query Unix socket onto the tmpfs while keeping the
# HTTP endpoint on TCP 3473. Used on macOS only.
read -r -d '' CONFIG_YAML <<'EOF' || true
schema_version: "1.0"
endpoints:
  http:
    listeners:
      - type: tcp
        port: 3473
      - type: unix
        path: /run/firebolt/query_endpoint
EOF

write_firebolt_config() {
    printf '%s\n' "$CONFIG_YAML" > "$CONFIG_FILE"
}

ensure_docker_is_installed() {
    if docker info >/dev/null 2>&1; then
        echo "[🐳] Docker is present and works ✅"
        return 0
    fi

    if [ $IS_MACOS -eq 1 ]; then
        echo "[🐳] Docker needs to be installed: https://docs.docker.com/desktop/setup/install/mac-install/ ❌"
    else
        echo "[🐳] Docker needs to be installed: https://docs.docker.com/desktop/setup/install/linux/ ❌"
    fi
    return 1
}

check_docker_version() {
    # Explicitly inform the user about the known io_uring issue in Docker Desktop for Mac
    # See also:
    # * https://github.com/docker/for-mac/issues/7707
    if [ $IS_MACOS -eq 1 ]; then
        version=$(docker version | sed -n 's/.*Docker Desktop \([0-9.]*\).*/\1/p')
        if [ "$version" = "4.42.1" ] || [ "$version" = "4.43.0" ] || [ "$version" = "4.43.1" ]; then
            echo "[❌] Firebolt cannot run with Docker Desktop version ${version} on Mac, as it contains a known io_uring issue; please use version 4.43.2+"
            return 1
        fi
    fi
}

pull_docker_image() {
    echo "[🐳] Pulling Firebolt Docker image '$DOCKER_IMAGE'"
    # Check the pull inline rather than through '$?': 'set -e' would abort the script on a
    # failed pull before any separate check could report it, leaving the user with docker's
    # raw error and none of the context below.
    if docker pull --quiet "$DOCKER_IMAGE"; then
        echo "[🐳] Docker image '$DOCKER_IMAGE' pulled successfully ✅"
    else
        echo "[🐳] Failed to pull Docker image '$DOCKER_IMAGE' ❌"
        return 1
    fi
}

DEFAULT_RUN_USER=""
detect_firebolt_user() {
    if [ $IS_MACOS -eq 1 ]; then
        DEFAULT_RUN_USER=root
    else
        DEFAULT_RUN_USER="firebolt"
    fi

    # set FIREBOLT_USER, unless already set by user
    FIREBOLT_USER="${FIREBOLT_USER:-$DEFAULT_RUN_USER}"
}

wait_for_firebolt_to_be_ready() {
    # If curl is not installed, we can't check if Firebolt is ready
    if ! command -v curl >/dev/null 2>&1; then
        return 0
    fi

    echo -n "[🔥] Wait for Firebolt to be ready"

    # Try for ~10 seconds to get a valid response from Firebolt
    timeout=10
    RESPONSE="Unknown error"
    while [ $timeout -gt 0 ]; do
        set +e
        RESPONSE=$(curl -s 'http://localhost:3473/?output_format=TabSeparatedWithNamesAndTypes' --data-binary "SELECT 42;")
        set -e

        if [ "$RESPONSE" = $'?column?\nint\n42' ]; then
            echo " ✅"
            return 0
        fi
        sleep 1
        timeout=$((timeout - 1))
        echo -n "."
    done

    echo " ❌"
    echo "[❌] Firebolt failed to start. This is unexpected, please submit a bug report on Github https://github.com/firebolt-db/firebolt-core/issues"
    echo "[❌] Error: $RESPONSE"
    return 1
}

run_docker_image() {
    echo "[⚠️] Note: a local 'firebolt-data directory' with permissions 0777 will be created."
    if [ $IS_MACOS -eq 1 ]; then
        echo "[⚠️] Note: on macOS a '$CONFIG_FILE' file will be created and the socket will run on an in-memory tmpfs."
    fi

    if [ "$AUTO_RUN" = true ]; then
        answer="y"
    else
        prompt="[🔥] Everything is set up and you are ready to go! Do you want to run the Firebolt image? (use --auto-run to skip this prompt) [y/N]: "
        if ! { printf "%s" "$prompt" > /dev/tty && read -r answer < /dev/tty; } 2>/dev/null; then
            answer=""
        fi
    fi

    case "$answer" in
        [yY])
            if [ ! -d firebolt-data ]; then
                mkdir -p -m 777 firebolt-data
            fi
            if [ $IS_MACOS -eq 1 ]; then
                write_firebolt_config
            fi
            echo -n "[🔥] Starting the Firebolt Docker container"
            CID="$(docker run --detach --user $FIREBOLT_USER "${DOCKER_RUN_ARGS[@]}")"
            trap "docker kill $CID" EXIT
            echo " ✅"

            wait_for_firebolt_to_be_ready

            # stdin may be the script itself (e.g. 'curl | bash'), so attach the
            # CLI to the controlling terminal instead; without one, leave the
            # container running in the background.
            #
            # The image ships no separate CLI binary: `firebolt` is both the server and the
            # client. The `client` subcommand is what connects to the server already running
            # in the container (localhost:3473, database "firebolt") — a bare `firebolt`
            # would start a second, embedded one instead.
            if { : < /dev/tty; } 2>/dev/null; then
                echo "[🔥] Running Firebolt CLI"
                docker exec -ti $CID firebolt client < /dev/tty
            else
                trap - EXIT
                echo "[🔥] No terminal available, leaving Firebolt running in the background."
                echo "[🔥] Connect to it with: docker exec -ti $DOCKER_CONTAINER_NAME firebolt client"
                echo "[🔥] Stop it with: docker kill $DOCKER_CONTAINER_NAME"
            fi
            ;;
        *)
            echo "[🔥] Firebolt is ready to be executed, you can do this by running the following commands:"
            echo
            echo "mkdir -m 777 firebolt-data"
            if [ $IS_MACOS -eq 1 ]; then
                echo "cat > $CONFIG_FILE <<'EOF'"
                printf '%s\n' "$CONFIG_YAML"
                echo "EOF"
            fi
            # Print the arguments one by one with '%q' so the line stays copy-pasteable: it
            # quotes whatever needs quoting, e.g. the bind-mount path when the current
            # directory contains spaces.
            printf 'docker run --user %q' "$FIREBOLT_USER"
            printf ' %q' "${DOCKER_RUN_ARGS[@]}"
            printf '\n'
            echo
            echo "And then in another terminal:"
            echo
            echo "docker exec -ti $DOCKER_CONTAINER_NAME firebolt client"
            echo
            ;;

    esac
}

# Main script execution
banner
ensure_docker_is_installed
check_docker_version
pull_docker_image
detect_firebolt_user
run_docker_image