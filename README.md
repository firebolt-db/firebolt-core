<p align="center">
    <img alt="Firebolt Core logo" src="static/core.png?raw=true" width="400" />
</p>
<p align="center">
    <b>Firebolt Core</b> is a free, self-hosted edition of <a href="https://www.firebolt.io/">Firebolt's high-performance distributed query engine</a>, designed to power the data infrastructure behind today's most demanding applications.
</p>
<p align="center">
  <a href="https://discord.gg/UpMPDHActM">
    <img src="https://img.shields.io/badge/Discord-%235865F2.svg?logo=discord&logoColor=white" alt="Discord chat"
  /></a>
  <a href="https://docs.firebolt.io/firebolt-core" style="text-decoration: none"><img
    src="https://img.shields.io/badge/Core-docs-brightgreen"
    alt="Firebolt Core documentation"
  /></a>
  <a href="https://docs.firebolt.io/FireboltCore/firebolt-core-operation.html" style="text-decoration: none"><img
    src="https://img.shields.io/badge/deployment-guide-brightgreen"
    alt="Deployment and Operational Guide"
  /></a>
  <a href="https://github.com/firebolt-db/firebolt-core?tab=readme-ov-file#get-started" style="text-decoration: none"><img
    src="https://img.shields.io/badge/release-preview%E2%80%93rc-brightgreen"
    alt="Release"
  /></a>
  <a href="https://github.com/firebolt-db/firebolt-core/issues" style="text-decoration: none"><img
    src="https://img.shields.io/github/issues/firebolt-db/firebolt-core.svg"
    alt="GitHub Issues"
  /></a>
  <a href="https://github.com/firebolt-db/firebolt-core/stargazers" style="text-decoration: none"><img
    src="https://img.shields.io/github/stars/firebolt-db/firebolt-core.svg"
    alt="GitHub Stars"
  /></a>
</p>

> *Deploy anywhere, from a single laptop to your own datacenter*

## Key Features

* 🚀 **Powerful.** Firebolt Core ships with all key performance and usability features of Firebolt's [managed Cloud data warehouse](https://www.firebolt.io/), including a state-of-the-art query optimizer, distributed query execution engine, Iceberg support, and many more.
* 🆓 **Free to use.** Firebolt Core is free to use, forever (see the [LICENSE](LICENSE.md) for details).
* 📈 **No usage limits.** Firebolt Core has no usage limits. Process unlimited data, scale to as many nodes as you need, and run as many queries as you like.
* 🛢️ **Postgres compliant.** Firebolt's SQL dialect is Postgres compliant. We offer powerful extensions for analytical workloads, such as lambda functions for array processing. For a complete reference, see the [SQL reference documentation](https://docs.firebolt.io/sql_reference/).
* 🛠️ **Self-contained.** Firebolt Core comes packaged as a single Docker image (`ghcr.io/firebolt-db/firebolt-core:preview-rc`) that contains everything needed to run it.
* 🏠 **Self-hosted.** You can deploy Firebolt Core anywhere you want, from your personal workstation to large on-premise clusters or VPCs.
* 📊 **First-class support** with [documentation](https://docs.firebolt.io/firebolt-core), updates, and active [community support via GitHub Discussions](https://github.com/firebolt-db/firebolt-core/discussions). We encourage you to join the conversation!
* 🤖 **AI-ready architecture** optimized for modern data and ML applications.
* 🎯 **Designed for demanding applications.** Powering real-time analytics, embedded analytics, and large-scale data processing workloads.
* 🔄 **Workload compatibility.** Many workloads run interchangeably with [managed Firebolt](https://www.firebolt.io/).

## Get Started

Start Core on your machine with:
```bash
bash <(curl -s https://get-core.firebolt.io/)
```

If you want to work with Docker directly, you can also run:

```bash
docker run -i --rm \
        --ulimit memlock=8589934592:8589934592 \
        --security-opt seccomp=unconfined \
        -p 127.0.0.1:3473:3473 \
        -v ./firebolt-core-data:/firebolt-core/volume \
        ghcr.io/firebolt-db/firebolt-core:preview-rc
```

> [!CAUTION]
> This will create a local `firebolt-core-data` directory, owned by root, where data, metadata, logs and diagnostic information are persisted.

You can also start a single node cluster by cloning this repository and then run the following command within the repository root directory:
```bash
docker compose up
```

See also:
* [Get Started](https://docs.firebolt.io/FireboltCore/firebolt-core-get-started.html)

### Multi-Node via Docker Compose

Use this setup if you want to leverage the computing power of multiple hosts.

1. Add in `config.json` one entry (either hostname or IP address) for each of the nodes; node 0 is the first node in the array:

    ```json
    {
        "nodes": [
            {
                "host": "ip-or-host-of-node-0"
            },
            {
                "host": "ip-or-host-of-node-1"
            },
            {
                "host": "ip-or-host-of-node-2"
            }
        ]
    }
    ```

1. Make sure that this repository and your `config.json` are present on each of the nodes.

1. Activate node 0:

   ```bash
   docker compose up
   ```

1. Activate all further nodes by running on each host:

   ```bash
   NODE=1 docker compose -f compose.yaml -f compose.nodeN.yaml up
   ```

   Increase `NODE` for each further node.

See also:
* [Deployment using Docker Compose](https://docs.firebolt.io/FireboltCore/firebolt-core-deployment-compose.html)
* [Docker Compose](https://docs.docker.com/compose/)

### Multi-Node via Kubernetes

You can deploy Firebolt Core on Kubernetes (v1.19+) by following these steps:

1. Create a dedicated namespace:
```bash
kubectl create namespace firebolt-core
```
2. Customize the values for the chart (see [helm/README.md](helm/README.md)), for example by setting `nodesCount` to 3.
3. Install the Helm chart in such namespace:
```bash
helm install helm/ --generate-name --namespace firebolt-core
```
4. Verify that pods are running:
```bash
kubectl get pods
```
Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
helm-1748880880-firebolt-core-0   0/1     Running   0          5m32s
helm-1748880880-firebolt-core-1   0/1     Running   0          5m32s
helm-1748880880-firebolt-core-2   0/1     Running   0          5m32s
```

See also:
* [helm/README.md](helm/README.md) for information on the values you can customize, including number of nodes.
* [Deployment on Kubernetes](https://docs.firebolt.io/FireboltCore/firebolt-core-deployment-k8s.html)

## Requirements

Software for your host OS:

* **[Docker Engine](https://docs.docker.com/engine/install/)**, with the **[Docker Compose plugin](https://docs.docker.com/compose/install/linux/)** if you want to use `docker compose`; if you use the [get-core.sh](get-core.sh) script Docker engine will be installed automatically.
* **[cURL](https://curl.se/) or any other HTTP client** in order to send SQL queries to Firebolt Core.

Software for your Docker host:
* **Linux kernel version >= 6.1**. Firebolt Core internally uses the `io_uring` kernel API for fast network and disk I/O, and some required features of this API have only been released in Linux 6.1.

Resources for each node (either a local machine or a VM instance):

* **An amd64 CPU supporting at least SSE 4.2, or an arm64 CPU** All published Firebolt Core Docker images are multi-arch images suitable for both `amd64` and `arm64`.
* **At least 16 GB of RAM** are recommended in order to run basic queries.
* **At least 25 GB of SSD space** are recommended in order to run basic queries.
* **At least 10 GBit/s of inter-node network bandwidth** is recommended for multi-node deployments.
* TCP port `3473` open when using a single node.
* TCP ports `3473`, `1717`, `3434`, `5678`, `6500`, `8122`, `16000` open when using multiple nodes.

> [!NOTE]
> There is no universally correct amount of RAM and disk space for running Firebolt Core, and the above are simply rough guidelines for running some simple queries as a way to get started. The ideal amount of RAM and disk space depends heavily on the specific workload that you are running against a Firebolt Core deployment (see [Deployment and Operational Guide](https://docs.firebolt.io/FireboltCore/firebolt-core-operation.html) for details).

## Run Queries on Firebolt Core via CLI

You can submit queries to a Firebolt Core cluster using any HTTP client (like cURL), the official [Firebolt CLI](https://github.com/firebolt-db/fb-cli) as a standalone binary, or by invoking the CLI from within the Core Docker container.

```bash
Suggested change
# Use the fbcli script available within the container
docker exec -ti firebolt-core fbcli "SELECT 42;"
```

```bash
# Run the standalone fb CLI
fb --core "SELECT 42;"
```

```bash
# Use cURL 
curl -s "http://localhost:3473/?output_format=psql" --data-binary "SELECT 42";
```

See also:
* [Example Queries](examples/README.md)
* [Connect to Firebolt Core](https://docs.firebolt.io/FireboltCore/firebolt-core-connect.html)

## Run Queries on Firebolt Core via the web UI

1. Download the Firebolt Core UI Docker image:
```bash
docker pull 231290928314.dkr.ecr.us-east-1.amazonaws.com/firebolt-core-ui:latest
```

2. Run the UI container, linking it to your Firebolt Core instance:

#### MacOS and Windows
```bash
docker run --name firebolt-core-ui -p 9100:9100 -e FIREBOLT_CORE_URL=http://host.docker.internal:3473 ghcr.io/firebolt-db/firebolt-core-ui
```

#### Linux
```bash
docker run --network=host --name firebolt-core-ui -p 9100:9100 -e FIREBOLT_CORE_URL=http://localhost:3473 ghcr.io/firebolt-db/firebolt-core-ui
```

3. Open your browser and navigate to `http://localhost:9100` to access the UI.

## Troubleshooting & Support

Detailed information about Firebolt Core is available in the [documentation](https://docs.firebolt.io/FireboltCore/).

* Encountering issues? Check the [Troubleshooting Guide](https://docs.firebolt.io/FireboltCore/firebolt-core-troubleshooting.html) for common problems and solutions and the [FAQs](https://docs.firebolt.io/FireboltCore/firebolt-core-faq.html)
* For further assistance, join the [GitHub Discussions](https://github.com/firebolt-db/firebolt-core/discussions).
* For best practices on securing your deployment and information on backing up, consult the [Operational Guide](https://docs.firebolt.io/FireboltCore/firebolt-core-operation.html).
* Curious about what's next for Firebolt Core? Check out the [Roadmap](https://docs.firebolt.io/FireboltCore/firebolt-core-roadmap.html) to see planned features and improvements.

## Verifying Firebolt Core Docker Images

All Firebolt Core published images are signed using [cosign](https://github.com/sigstore/cosign).

To verify:

1. Download the public key: [cosign.pub](cosign.pub)
1. Run:
```console
cosign verify --key cosign.pub ghcr.io/firebolt-db/firebolt-core:preview-rc
```

You should see output confirming the signature is valid:
```
Verification for ghcr.io/firebolt-db/firebolt-core:preview-rc --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
[...]
```

## License

See [LICENSE](LICENSE.md) and [NOTICE](NOTICE.md).
