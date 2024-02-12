#!/bin/bash
SRCROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHARTDIR="charts/gitops-runtime"
VALUESFILE="$CHARTDIR/ci/values-all-images.yaml"
OUTPUTFILE=$1

helm dep update $CHARTDIR

helm template RELEASE_NAME $CHARTDIR -f $VALUESFILE \
  | grep -E 'image:|Image:'  | grep -v "{}" \
  | awk -F ': ' '{print $2}' | awk NF \
  | tr -d '"' | tr -d ',' | cut -f1 -d"@" \
  | sort -u