# Deploy a Worker

An AVS operator is expected to serve proving requests from Lagrange network by running a “worker” binary. The Lagrange sequence sends tasks to workers  containing all the necessary inputs to generate a zkproofs.  The worker continuously listen for such tasks and generate proofs accordingly.

This is a step by step guide to deploy your own worker

### Pre-Requirement

There are **3** different types of workers. Every type can generate a specific type of proof.

| Worker Type | CPU | Memory | Disk | Internet |
| --- | --- | --- | --- | --- |
| worker-sc | 10 | 20 GB | 60GB | ✅ |
| worker-sp | 40 | 80 GB | 60GB | ✅ |
| worker-sg | 90 | 180 GB | 60GB | ✅ |

### Deployment Steps

1. Install Docker by following this [guide](https://docs.docker.com/engine/install/)
2. 
3. Run the worker
```sh
ETHEREUM__URL=https://eth*************
docker compose up -e ETHEREUM__URL -d
```