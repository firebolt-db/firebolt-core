#!/bin/bash
# <h2 style="color:red">Get Firebolt Core with:</h2><code>curl -fsSL https://get.firebolt.io/ | bash</code><br/><br/><br/><pre>
set -e

# Parse command line arguments
AUTO_RUN=false
if [[ "$1" = "--auto-run" ]]; then
    AUTO_RUN=true
elif [[ -n "$1" ]]; then
    echo "Unknown option: $1"
    echo "Usage: $0 [--auto-run]" 1>&2
    exit 1
fi

# When the script is piped in (e.g. 'curl | bash'), stdin carries the script
# rather than user input. Open the controlling terminal on a separate file
# descriptor for prompts and the interactive CLI. Do not replace stdin with
# exec, or bash will read the rest of the script from the terminal.
TTY_FD=
open_controlling_tty() {
    if [[ -t 0 ]]; then
        return 0
    fi
    if [[ -r /dev/tty ]] && exec {TTY_FD}< /dev/tty; then
        return 0
    fi
    return 1
}

if ! open_controlling_tty && [[ "$AUTO_RUN" = false ]]; then
    AUTO_RUN=true
fi

banner() {
    echo "
🔥🔥🔥 Firebolt Core setup script 🔥🔥🔥
---------:    .---     ---------:         ---------:     ---------:              :-====-:            ---          .---------..  
++++++++++    :+++     ++++++++++++:      +++++++++-     ++++++++++++-        ++++++++++++++     ...:=++        -+++++++++++++  
++++          :+++     +++-     ++++.     +++-           +++-     ++++-    :=++++.      -++++=      :+++             -+++       
++++          :+++     +++:      +++:     +++-           +++-     .:++=    ++++.          =++:      :++=             :+-:       
++++:....     :+++     +++-     ++++      ++++:....      ++++:...-++++    .+=-             =+++     :+++             .=++       
+++++++++     :+++     ++++++++++++       +++++++++      ++++++++++++     -+++-               -    :++++             :+++       
++++          :+++     +++=.:+++=         +++=           +++=    .++++:    +++=           .=+++     :+++             :++=       
++++          :+++     +++:   =++=        +++-           +++-      -++=    =+++=          ++++:     :+++            :=+++       
++++          :+++     +++:    ++++       +++=           +++=    :++++:     -+++++:    -+++++:      -+++.            :+++       
++++          :+++     +++:     =+++      ++++++++++       =+++++++--         -++++++++++++.        -++++++++-       .-++       
                                                                                  .:--:.                                        
"
}

IS_MACOS=0
if [[ "$(uname)" = "Darwin" ]]; then
    IS_MACOS=1
fi

# Docker image to pull - allow specifying overrides via env variables
CORE_REPO="${CORE_REPO:-ghcr.io/firebolt-db/engine}"
CORE_TAG="${CORE_TAG:-dev}"
DOCKER_IMAGE="${CORE_REPO}:${CORE_TAG}"
EXTERNAL_PORT=3473
# Generated engine config, dropped into the data directory (used on macOS only,
# see below). It is auto-loaded by the engine as /var/lib/firebolt/config.yaml.
CORE_CONFIG_FILE="firebolt-core-data/config.yaml"
DOCKER_RUN_ARGS=(
  -i
  --name firebolt-core
  --rm
  --ulimit memlock=8589934592:8589934592
  --security-opt seccomp=unconfined
  -v "$(pwd)/firebolt-core-data:/var/lib/firebolt"
  -p "$EXTERNAL_PORT:3473"
)
# On macOS the Docker Desktop file-sharing backend cannot stat the engine's Unix
# domain socket when it lives on the bind-mounted data directory, so Core fails
# to start. Keep the socket off the shared filesystem: put it on an in-memory
# tmpfs at /run/firebolt and relocate it there via the generated config file.
# Mirror the ownership/permissions the image ships /run/firebolt with
# (firebolt:root, mode 2770) so both root and the non-root firebolt user (uid
# 3473, group 0) can create the socket.
if [[ $IS_MACOS -eq 1 ]]; then
    DOCKER_RUN_ARGS+=( --tmpfs /run/firebolt:rw,mode=2770,uid=3473,gid=0 )
fi
DOCKER_RUN_ARGS+=( "$DOCKER_IMAGE" )

# Engine config that moves the query Unix socket onto the tmpfs while keeping the
# HTTP endpoint on TCP 3473. Used on macOS only.
read -r -d '' CORE_CONFIG_YAML <<'EOF' || true
schema_version: "1.0"
endpoints:
  http:
    listeners:
      - type: tcp
        port: 3473
      - type: unix
        path: /run/firebolt/query_endpoint
EOF

write_core_config() {
    printf '%s\n' "$CORE_CONFIG_YAML" > "$CORE_CONFIG_FILE"
}

ensure_docker_is_installed() {
    if docker info >/dev/null 2>&1; then
        echo "[🐳] Docker is present and works ✅"
        return 0
    fi
    
    if [[ $IS_MACOS -eq 1 ]]; then
        echo "[🐳] Docker needs to be installed: https://docs.docker.com/desktop/setup/install/mac-install/ ❌"
    else
        echo "[🐳] Docker needs to be installed: https://docs.docker.com/desktop/setup/install/linux/ ❌"
    fi
    return 1
}

check_docker_version() {
    # Explicitly inform the user about the known io_uring issue in Docker Desktop for Mac
    # See also:
    # * https://github.com/firebolt-db/firebolt-core/issues/9
    # * https://github.com/docker/for-mac/issues/7707
    if [[ $IS_MACOS -eq 1 ]]; then
        version=$(docker version | sed -n 's/.*Docker Desktop \([0-9.]*\).*/\1/p')
        if [[ "$version" = "4.42.1" || "$version" = "4.43.0" || "$version" = "4.43.1" ]]; then
            echo "[❌] Firebolt Core cannot run with Docker Desktop version ${version} on Mac, as it contains a known io_uring issue; please use version 4.43.2+"
            return 1
        fi
    fi
}

pull_docker_image() {
    echo "[🐳] Pulling Firebolt Core Docker image '$DOCKER_IMAGE'"
    docker pull --quiet "$DOCKER_IMAGE"
    if [[ $? -eq 0 ]]; then
        echo "[🐳] Docker image '$DOCKER_IMAGE' pulled successfully ✅"
    else
        echo "[🐳] Failed to pull Docker image '$DOCKER_IMAGE' ❌"
        return 1
    fi
}

DEFAULT_CORE_USER=""
detect_firebolt_user() {
    if [[ $IS_MACOS -eq 1 ]]; then
        DEFAULT_CORE_USER=root
    else
        DEFAULT_CORE_USER="firebolt"
    fi

    # set CORE_USER, unless already set by user
    CORE_USER="${CORE_USER:-$DEFAULT_CORE_USER}"
}

wait_for_core_to_be_ready() {
    # If curl is not installed, we can't check if Core is ready
    if ! command -v curl >/dev/null 2>&1; then
        return 0
    fi

    echo -n "[🔥] Wait for Firebolt Core to be ready"
    
    # Try for ~10 seconds to get a valid response from Core
    timeout=10
    RESPONSE="Unknown error"
    while [[ $timeout -gt 0 ]]; do
        set +e
        RESPONSE=$(curl -s 'http://localhost:3473/?output_format=TabSeparatedWithNamesAndTypes' --data-binary "SELECT 42;")
        set -e

        if [[ "$RESPONSE" = $'?column?\nint\n42' ]]; then
            echo " ✅"
            return 0
        fi
        sleep 1
        timeout=$((timeout - 1))
        echo -n "."
    done

    echo " ❌"
    echo "[❌] Firebolt Core failed to start. This is unexpected, please submit a bug report on Github https://github.com/firebolt-db/firebolt-core/issues"
    echo "[❌] Error: $RESPONSE"
    return 1
}

run_docker_image() {
    echo "[⚠️] Note: a local 'firebolt-core-data directory' with permissions 0777 will be created."
    if [[ $IS_MACOS -eq 1 ]]; then
        echo "[⚠️] Note: on macOS a '$CORE_CONFIG_FILE' file will be created and the socket will run on an in-memory tmpfs."
    fi
    
    if [[ "$AUTO_RUN" = true ]]; then
        answer="y"
    elif [[ -n "$TTY_FD" ]]; then
        read -r -p "[🔥] Everything is set up and you are ready to go! Do you want to run the Firebolt Core image? (use --auto-run to skip this prompt) [y/N]: " answer <&${TTY_FD}
    else
        read -r -p "[🔥] Everything is set up and you are ready to go! Do you want to run the Firebolt Core image? (use --auto-run to skip this prompt) [y/N]: " answer
    fi
    
    case "$answer" in
        [yY])
            if [[ ! -d firebolt-core-data ]]; then
                mkdir -p -m 777 firebolt-core-data
            fi
            if [[ $IS_MACOS -eq 1 ]]; then
                write_core_config
            fi
            echo -n "[🔥] Starting the Firebolt Core Docker container"
            CID="$(docker run --detach --user $CORE_USER "${DOCKER_RUN_ARGS[@]}")"
            trap "docker kill $CID" EXIT
            echo " ✅"

            wait_for_core_to_be_ready
            
            if [[ -t 0 ]] || [[ -n "$TTY_FD" ]]; then
                echo "[🔥] Running Firebolt CLI"
                if [[ -n "$TTY_FD" ]]; then
                    docker exec -ti $CID fb --core <&${TTY_FD}
                else
                    docker exec -ti $CID fb --core
                fi
            else
                trap - EXIT
                echo "[🔥] No terminal available, leaving Firebolt Core running in the background."
                echo "[🔥] Connect to it with: docker exec -ti firebolt-core fb --core"
                echo "[🔥] Stop it with: docker kill firebolt-core"
            fi
            ;;
        *)
            echo "[🔥] Firebolt Core is ready to be executed, you can do this by running the following commands:"
            echo
            echo "mkdir -m 777 firebolt-core-data"
            if [[ $IS_MACOS -eq 1 ]]; then
                echo "cat > $CORE_CONFIG_FILE <<'EOF'"
                printf '%s\n' "$CORE_CONFIG_YAML"
                echo "EOF"
            fi
            echo "docker run --user $CORE_USER "${DOCKER_RUN_ARGS[@]}""
            echo
            echo "And then in another terminal:"
            echo
            echo "docker exec -ti firebolt-core fb --core"
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
