#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <git_release_tag>"
    exit 1
fi

set -x

GIT_RELEASE=$1

cd ../../bin/vpc_cleanup
go build -ldflags="-s -w" -o ../../modules/aurora/bin/delete_sgs main.go
cd ../..

git add .
git commit -m "refactor"
git push

echo "GIT_RELEASE=[$GIT_RELEASE]"

git tag -a "$GIT_RELEASE" -m "Release bin"                                                                                                                           ✔ 
# git push origin $GIT_RELEASE