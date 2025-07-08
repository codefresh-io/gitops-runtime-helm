#!/bin/sh

set -ex

VERSION=$(grep -e ^version Chart.yaml | cut -d' ' -f 2)

if [ -z "$(git status --porcelain)" ]; then
    helm package .
    git checkout 0.1.2
    helm package .
    git checkout 0.1.1
    helm package .
    git rev-parse --verify --quiet gh-pages && git branch --quiet -D -f gh-pages
    git checkout --orphan gh-pages
    git reset
    helm repo index . --url https://tendant.github.io/simple-app
    git add index.yaml simple-app-0.1.1.tgz simple-app-0.1.2.tgz simple-app-$VERSION.tgz
    git commit -am "Update release"
    git clean -df
    git push -f origin gh-pages
    git checkout master
else
    echo "There is uncommitted change! Exiting without releasing."
    exit 1
fi