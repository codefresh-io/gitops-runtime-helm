#!/bin/sh

set -ex

if [ $# -eq 3 ]; then
   SECRETS_FILE=$1
   SECRETS_NAMESPACE=$2
   SECRETS_NAME=$3
else
    echo "Usage: $0 <secrets_properties_file> <namespace> <secrets_name>"
    exit 1
fi

kubectl create secret generic $SECRETS_NAME -n $SECRETS_NAMESPACE --from-env-file=$SECRETS_FILE --dry-run -o json > $SECRETS_FILE.json

kubeseal <$SECRETS_FILE.json >$SECRETS_FILE-secret.json

rm $SECRETS_FILE.json