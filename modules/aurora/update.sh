#!/bin/bash

GIT_RELEASE=$1
GIT_RELEASE=$(echo "$GIT_RELEASE" | tr -d ' \n\r')

cd ../../bin/vpc_cleanup
go build -ldflags="-s -w" -o ../../modules/aurora/bin/delete_sgs main.go
cd ../..




git add .
git commit -m "refactor"
git push

echo $GIT_RELEASE

git tag -a "$GIT_RELEASE" -m "Release $GIT_RELEASE"                                                                                                                            ✔ 
# git push origin $GIT_RELEASE