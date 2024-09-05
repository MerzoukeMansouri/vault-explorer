#!/bin/bash
export VAULT_ADDR='https://vault.factory.adeo.cloud'
export VAULT_TOKEN=$(cat ~/.vault-token)
search_secret="$1"
vault_namespace="$2"

if [ -z "$vault_namespace" ]; then
    echo "Usage: $0 <search_secret> <vault_namespace>"
    exit 1
fi

secrets=$(vault kv list -format=json "$vault_namespace" | jq -r '.[]')

for secret in $secrets; do
   if [[ "$secret" != */ ]]; then
        secret_data=$(vault kv get -format=json "${vault_namespace}${secret}")
        if echo "$secret_data" | jq -e ".data.data | to_entries[] | select(.value | tostring | contains(\"$search_secret\"))" > /dev/null; then
            echo "Secret containing '$search_secret' found at: ${vault_namespace}${secret}"
        # else
        #  echo "No secret containing '$search_secret' found at: ${vault_namespace}${secret}"
        fi
    else
        if [[ "$secret" == */ ]]; then
            # Recursively search in the sub-path
            bash vault.sh "$search_secret" "${vault_namespace}${secret}"
        fi
    fi
done