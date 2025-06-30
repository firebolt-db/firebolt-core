#!/bin/bash
# <h2 style="color:red">Get Firebolt Core with:</h2><code>bash <(curl -s https://get-core.firebolt.io/)</code><br/><br/><br/><pre>
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

# Docker image to pull
DOCKER_IMAGE="ghcr.io/firebolt-db/firebolt-core:preview-rc"
EXTERNAL_PORT=3473
DOCKER_RUN_ARGS=(
  -i
  --name firebolt-core
  --rm
  --ulimit memlock=8589934592:8589934592
  --security-opt seccomp=unconfined
  -v "$(pwd)/firebolt-core-data:/firebolt-core/volume"
  -p "$EXTERNAL_PORT:3473"
  "$DOCKER_IMAGE"
)

ensure_docker_is_installed() {
    if docker info >/dev/null 2>&1; then
        echo "[🐳] Docker is present and works ✅"
        return 0
    fi
    
    if [ "$(uname)" = "Darwin" ]; then
        echo "[🐳] Docker needs to be installed: https://docs.docker.com/desktop/setup/install/mac-install/ ❌"
    else
        echo "[🐳] Docker needs to be installed: https://docs.docker.com/desktop/setup/install/linux/ ❌"
    fi
    return 1
}

check_docker_version() {
    # Explicitly inform the user about the known io_uring issue in Docker Desktop 4.42.1 on Mac
    if [ "$(uname)" = "Darwin" ]; then
        version=$(docker version | sed -n 's/.*Docker Desktop \([0-9.]*\).*/\1/p')
        if [ "$version" = "4.42.1" ]; then
            echo "[❌] Firebolt Core cannot run with Docker Desktop verion ${version} on Mac, as it contains a known bug: https://github.com/firebolt-db/firebolt-core/issues/9"
            return 1
        fi
    fi
}

pull_docker_image() {
    echo "[🐳] Pulling Firebolt Core Docker image '$DOCKER_IMAGE'"
    docker pull --quiet "$DOCKER_IMAGE"
    if [ $? -eq 0 ]; then
        echo "[🐳] Docker image '$DOCKER_IMAGE' pulled successfully ✅"
    else
        echo "[🐳] Failed to pull Docker image '$DOCKER_IMAGE' ❌"
        return 1
    fi
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
    echo "[❌] Firebolt Core failed to start. This is unexpected, please submit a bug report on Github https://github.com/firebolt-db/firebolt-core/issues"
    echo "[❌] Error: $RESPONSE"
    return 1
}

run_docker_image() {
    echo "[⚠️] Note: a local 'firebolt-core-data directory' will be created."
    
    if [ "$AUTO_RUN" = true ]; then
        answer="y"
    else
        read -p "[🔥] Everything is set up and you are ready to go! Do you want to run the Firebolt Core image? (use --auto-run to skip this prompt) [y/N]: " answer
    fi
    
    case "$answer" in
        [yY])
            echo -n "[🔥] Starting the Firebolt Core Docker container"
            CID="$(docker run --detach "${DOCKER_RUN_ARGS[@]}")"
            trap "docker kill $CID" EXIT
            echo " ✅"

            wait_for_core_to_be_ready
            
            echo "[🔥] Running Firebolt CLI"
            docker exec -ti $CID fbcli
            ;;
        *)
            echo "[🔥] Firebolt Core is ready to be executed, you can do this by running the following command:"
            echo
            echo "docker run "${DOCKER_RUN_ARGS[@]}""
            echo
            echo "And then in another terminal:"
            echo
            echo "docker exec -ti firebolt-core fbcli"
            echo
            ;;

    esac
}

# Main script execution
banner
ensure_docker_is_installed
check_docker_version
pull_docker_image
run_docker_image
