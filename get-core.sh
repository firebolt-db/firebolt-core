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
DOCKER_RUN_ARGS="-i --rm --ulimit memlock=8589934592:8589934592 --security-opt seccomp=unconfined -v ./firebolt-core-data:/firebolt-core/volume -p $EXTERNAL_PORT:3473 $DOCKER_IMAGE"

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
    
    if [ "$AUTO_RUN" = true ]; then
        answer="y"
    else
        read -p "[🔥] Everything is set up and you are ready to go! Do you want to run the Firebolt Core image? (use --auto-run to skip this prompt) [y/N]: " answer
    fi
    
    case "$answer" in
        [yY])
            echo "[🔥] Running a Firebolt Core Docker container"
            echo
            CID="$(docker run --detach $DOCKER_RUN_ARGS)"
            trap "docker kill $CID" EXIT
            docker exec -ti $CID fbcli
            ;;
        *)
            echo "[🔥] Firebolt Core is ready to be executed, you can do this by running the following command:"
            echo
            echo "docker run --name firebolt-core $DOCKER_RUN_ARGS"
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
install_docker
pull_docker_image
run_docker_image
