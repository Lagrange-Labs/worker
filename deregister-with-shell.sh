#!/bin/zsh
set -euo pipefail

HOLESKY_CHAINID=17000
MAINNET_CHAINID=1
SIG_EXPIRY_SECONDS=300

# AVS__ETH_PWD=keystore_password.txt
# AVS__ETH_KEYSTORE=keystore/UTC--2025-06-24T10-20-15.307253000Z--95800d8ad04f6685f9bea678b22d91578ce0aad7

# AVS__LAGR_PWD=keystore_password.txt
# AVS__LAGR_KEYSTORE=lagrange_key.txt

if [[ -z "${AVS__ETH_PWD:-}" || -z "${AVS__ETH_KEYSTORE:-}" || -z "${AVS__LAGR_KEYSTORE:-}" || -z "${AVS__LAGR_PWD:-}" ]]; then
  echo "Error: Please set AVS__ETH_PWD and AVS__ETH_KEYSTORE environment variables"
  exit 1
fi

echo "Using AVS__ETH_KEYSTORE: $AVS__ETH_KEYSTORE"

chain_id=1  # Default to Holesky chain ID

echo "Chain ID: $chain_id"

if [ "$chain_id" -eq "$HOLESKY_CHAINID" ]; then
  ETH_RPC_URL="https://rpc.holesky.ethpandaops.io"
  ZKMR_SERVICE_MANAGER_ADDR=0xf98D5De1014110C65c51b85Ea55f73863215CC10
  ZKMR_STAKE_REGISTRY_ADDR=0xf724cDC7C40fd6B59590C624E8F0E5E3843b4BE4
  EIGEN_AVS_DIRECTORY_ADDR=0x055733000064333CaDDbC92763c58BF0192fFeBf
elif [ "$chain_id" -eq "$MAINNET_CHAINID" ]; then
  ETH_RPC_URL="https://eth.llamarpc.com"
  ZKMR_SERVICE_MANAGER_ADDR=0x22CAc0e6A1465F043428e8AeF737b3cb09D0eEDa
  ZKMR_STAKE_REGISTRY_ADDR=0x8dcdCc50Cc00Fe898b037bF61cCf3bf9ba46f15C
  EIGEN_AVS_DIRECTORY_ADDR=0x135dda560e946695d6f155dacafc6f1f25c1f5af
else
  echo "Unsupported chain ID: $chain_id"
  exit 1
fi

export ETH_RPC_URL
echo "Using RPC: $ETH_RPC_URL"

OPERATOR_ADDR=$(jq -r '.address' "$AVS__ETH_KEYSTORE")
echo "Operator Address: $OPERATOR_ADDR"

SALT=0x$(openssl rand -hex 32)
EXPIRY_TIMESTAMP=$(($(cast block -f timestamp) + SIG_EXPIRY_SECONDS))
echo "Salt: $SALT"
echo "Expires at: $EXPIRY_TIMESTAMP"

HASH=$(cast call $EIGEN_AVS_DIRECTORY_ADDR \
  "calculateOperatorAVSRegistrationDigestHash(address,address,bytes32,uint256)" \
  "$OPERATOR_ADDR" \
  "$ZKMR_SERVICE_MANAGER_ADDR" \
  "$SALT" \
  "$EXPIRY_TIMESTAMP")

if [[ -z "$HASH" ]]; then
  echo "Error: Failed to compute deregistration hash"
  exit 1
fi

echo "Deregistration Hash: $HASH"

SIGNATURE=$(cast wallet sign \
  --keystore "$AVS__ETH_KEYSTORE" \
  --password "$(cat $AVS__ETH_PWD)" \
  "$HASH")

echo "Signature: $SIGNATURE"

cast send $ZKMR_STAKE_REGISTRY_ADDR \
  "deregisterOperator((bytes,bytes32,uint256))" \
  "(${SIGNATURE},${SALT},${EXPIRY_TIMESTAMP})" \
  --keystore "$AVS__ETH_KEYSTORE" \
  --password "$(cat $AVS__ETH_PWD)"
