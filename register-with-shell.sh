#!/bin/zsh
# --- Description ---
# An example script using `cast` to register for the Lagrange ZK Coprocessor AVS
# This is an alternative to our Rust CLI. You can modify it to suit your operational setup.
# This script does 3 things:
#   1. Generate a new LAGR_KEY to be used to authenticate with the Gateway + sign the proofs you generate. It is needed at runtime while running the worker
#   2. Sign a message with your Eigenlayer ETH_KEY. This is your very sensitive `withdrawal key` https://docs.eigenlayer.xyz/eigenlayer/operator-guides/key-management/intro#withdrawal-keys
#   3. Send a transaction to the ZKMRStakeRegistry to register for the ZK Coprocessor AVS
# The transaction requires as input:
#   1. The public key component of your new LAGR_KEY
#   2. A signed message from your ETH_KEY
#   3. It must be signed with your ETH_KEY i.e. `cast send --private-key $ETH_KEY`
#
# You need to change the "MODIFY ME!" section to load your ETH_KEY safely.
# You don't need to load the ETH_KEY into the environment at all if you use a remote signer.
# You should just modify the `cast send` command at the end of the script to sign the tx in a way that meets your security needs.
# You also need to update the OPERATOR_ADDR variable to match your address.

# --- Dependencies ---
# 1. zsh
# 2. `cast` - a binary from the foundry toolkit https://github.com/foundry-rs/foundry?tab=readme-ov-file
# 3. `openssl` - to generate your new ECDSA secp256k1 LAGR_KEY to be used only for the ZK Coprocessor AVS
# 4. `jq` - only needed for the demo; see === MODIFY ME! === section below

# ==== MODIFY ME! ====
# --- Secrets ---
# This is just an example. You can generate/acquire/inject your operator key however you'd like
OPERATOR_KEY_ADDR_TUPLE=$(cast wallet new --json)
ETH_KEY=$(echo $OPERATOR_KEY_ADDR_TUPLE | jq -r ".[0].private_key")
OPERATOR_ADDR=$(echo $OPERATOR_KEY_ADDR_TUPLE | jq -r ".[0].address")

# --- Constants ---
HOLESKY_CHAINID=17000
MAINNET_CHAINID=1

# --- Configuration ---
SIG_EXPIRY_SECONDS=300
export ETH_RPC_URL=https://rpc.holesky.ethpandaops.io

chain_id=$(cast chain-id)
printf "Chain id: ${chain_id}\n"

# The signature you create + send is valid for SIG_EXPIRY_SECONDS
(( expiry_timestamp = $SIG_EXPIRY_SECONDS + $(cast block -f timestamp) ))

# Determine contract addresses based on the chain ID
if [ $chain_id -eq $HOLESKY_CHAINID ]; then
    echo "Registering with Lagrange ZK Coprocessor on Holesky Testnet"
    ZKMR_SERVICE_MANAGER_ADDR=0xf98D5De1014110C65c51b85Ea55f73863215CC10
    ZKMR_STAKE_REGISTRY_ADDR=0xf724cDC7C40fd6B59590C624E8F0E5E3843b4BE4
    EIGEN_AVS_DIRECTORY_ADDR=0x055733000064333CaDDbC92763c58BF0192fFeBf
elif [ $chain_id -eq $MAINNET_CHAINID ]; then
    echo "Mainnet is not live yet"
    exit 1
else
    echo "Unknown chain ID: $chainId"
    exit 1
fi

# --- Script Logic ---
# The lagrange key should only be used for this AVS.
# It is an ECDSA secp256k1 keypair; the same as ethereum
LAGR_KEY=$(openssl ecparam -name secp256k1 -genkey -noout | openssl ec -text -noout)
LAGR_PUB_KEY=$(echo $LAGR_KEY | grep pub -A 5 | tail -n +2 | tr -d '\n[:space:]:' | sed 's/^04//')

# 32 bytes of X coordinate of ECDSA secp256k1 public key
pubkeyX=0x${LAGR_PUB_KEY:0:64}
# 32 bytes of Y coordinate of ECDSA secp256k1 public key
pubkeyY=0x${LAGR_PUB_KEY:64:64}

printf "Public Key: $LAGR_PUB_KEY\n"
printf "pubkeyX: $pubkeyX\n"
printf "pubkeyY: $pubkeyY\n"

# A salt for your signature
salt=0x$(openssl rand -hex 32)

printf "\nOperator Address: $OPERATOR_ADDR\n"
printf "ZKMRServiceManager contract: $ZKMR_SERVICE_MANAGER_ADDR\n"
printf "ZKMRStakeRegistry contract: $ZKMR_STAKE_REGISTRY_ADDR\n"
printf "Salt for signature: $salt\n"
printf "Signature expires at: $expiry_timestamp"

# Call read-only method on eigenlayer contract to get hash to sign for registration tx
hash=$(cast call $EIGEN_AVS_DIRECTORY_ADDR \
    "calculateOperatorAVSRegistrationDigestHash(address,address,bytes32,uint256)" \
    "$OPERATOR_ADDR" \
    "$ZKMR_SERVICE_MANAGER_ADDR" \
    "${salt}" \
    "${expiry_timestamp}")

printf "\nRegistration hash:\n${hash}"

# Sign the output
signature=$(cast wallet sign --private-key $ETH_KEY $hash)
printf "\nRegistration signature:\n${signature}"

# Register with ZKMR contract using your signature and public key component of your new $LAGR_KEY
cast send $ZKMR_STAKE_REGISTRY_ADDR \
    "registerOperator((uint256,uint256),(bytes,bytes32,uint256))" \
    "(${pubkeyX},${pubkeyY})" \
    "(${signature},${salt},${expiry_timestamp})" \
    # === MODIFY ME ! ===
    --private-key $ETH_KEY # Specify a signer here as you see fit

printf "\nSuccessfully Registered!"

# === MODIFY ME ! ===
# Modify the script to store the $LAGR_KEY somewhere safe
# export LAGR_KEY
