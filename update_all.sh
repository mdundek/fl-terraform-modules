#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <git_release_tag>"
    exit 1
fi

GIT_RELEASE=$1

cd bin/vpc_cleanup

GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ../../modules/aurora/bin/delete_sgs main.go
cd ../..

git add .
git commit -m "refactor"
git push

git tag -a "$GIT_RELEASE" -m "Release $GIT_RELEASE"
git push origin $GIT_RELEASE

cd ../fl-crossplane
sed -i '' -E 's/(module:.*ref=)[^&"]+/\1'$GIT_RELEASE'/' aurora.yaml
kubectl apply -f ./aurora.yaml