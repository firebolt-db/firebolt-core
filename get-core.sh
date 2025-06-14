#!/bin/bash
# <h2 style="color:red">Get Firebolt Core with:</h2><code>bash <(curl -s https://get-core.firebolt.io/)</code><br/><br/><br/><pre>
set -e

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
DOCKER_RUN_COMMAND="docker run -i --rm --ulimit memlock=8589934592:8589934592 --security-opt seccomp=unconfined -v ./firebolt-core-data:/firebolt-core/volume -p $EXTERNAL_PORT:3473 $DOCKER_IMAGE"

install_docker() {
    if docker info >/dev/null 2>&1; then
        echo "[🐳] Docker is present and works ✅"
        return 0
    fi

    if [ "$(uname)" = "Darwin" ]; then
        echo "[🐳] Docker needs to be installed: https://docs.docker.com/desktop/setup/install/mac-install/ ❌"
        return 1
    fi

    # fallback for other Linux and other OSes
    echo "[🐳] Checking if rootless Docker is installed"
    curl -fsSL https://get.docker.com/rootless | sh
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

run_docker_image() {
    echo "[⚠️] Note: a local 'firebolt-core-data directory' will be created."
    read -p "[🔥] Everything is set up and you are ready to go! Do you want to run the Firebolt Core image? [y/N]: " answer
    case "$answer" in
        [yY])
            echo "[🔥] Running Firebolt Core Docker image with command: $DOCKER_RUN_COMMAND"
            echo "[🔥] Run SQL queries in another terminal with:"
            echo
            echo "curl -s http://localhost:$EXTERNAL_PORT --data-binary 'select 42';"
            echo
            eval "$DOCKER_RUN_COMMAND"
            ;;
        *)
            echo "[🔥] Firebolt Core is ready to be executed, you can do this by running the following command:"
            echo
            echo "$DOCKER_RUN_COMMAND"
            echo
            ;;

    esac
}

# Main script execution
banner
install_docker
pull_docker_image
run_docker_image
