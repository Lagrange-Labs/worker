# Build from source
### Setup Steps

1. On another directory on this machine clone the lgn-coprocessor repo
```sh
cd $HOME
git clone https://github.com/Lagrange-Labs/lgn-coprocessor.git
cd lgn-coprocessor
```
2. Checkout to the right version
```sh
#For  testnet
git checkout v1.0.2
#For  mainnet
git checkout v1.0.2
```
3. Build the docker
```sh
docker build -t lgn-coprocessor:local -f docker/worker/Dockerfile .
```
4. Once the build is done, cd back to the worker directory from this [repo](https://github.com/Lagrange-Labs/worker). and 
- Edit the docker-compose.yaml file. Change the `image:` line with `image: lgn-coprocessor:local`
- Replace `pull_policy: always` to `pull_policy: never`
5. Go back to the main step by step and continue from where you left, to generate the Lagrange key
