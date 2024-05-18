# Deploy a Worker

An AVS operator is expected to serve proving requests from Lagrange network by running a `Worker` binary. The Lagrange sequence sends through the `Gateway` tasks to workers containing all the necessary inputs to generate zkproofs. The worker continuously listens for such tasks and generate proofs accordingly.


![Worker](Lagrange.png)

This is a step by step guide to deploy your own worker.

### Pre-Requirements

There are **3** different types of workers. Every type can generate a specific type of proof.
You can choose your infrastrcture depending on the type of proof you would like to be able to generate.

| Worker Type | CPU | Memory | Disk | Internet |
| --- | --- | --- | --- | --- |
| `worker-sc` | 10 | 20 GB | 60GB | ✅ |
| `worker-sp` | 40 | 80 GB | 60GB | ✅ |
| `worker-sg` | 90 | 180 GB | 60GB | ✅ |

### Deployment Steps

1. Install `Docker` by following this [guide](https://docs.docker.com/engine/install/)
2. 
3. Run the worker
```sh
ETHEREUM__URL=https://eth*************
docker compose up -e ETHEREUM__URL -d
```