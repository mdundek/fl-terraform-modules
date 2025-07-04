#!/bin/bash

GIT_RELEASE=$1

cd ../../bin/vpc_cleanup
go build -ldflags="-s -w" -o ../../modules/aurora/bin/delete_sgs main.go
cd ../..




git add .
git commit -m "refactor"
git push



git tag -a "$1" -m "Release $1"                                                                                                                            ✔ 
# git push origin $1