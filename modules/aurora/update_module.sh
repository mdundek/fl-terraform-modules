#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <git_release_tag>"
    exit 1
fi

GIT_RELEASE=$1

cd ../..

git add .
git commit -m "refactor"
git push

git tag -a "$GIT_RELEASE" -m "Release $GIT_RELEASE"
git push origin $GIT_RELEASE

cd ../fl-crossplane
sed -i '' -E 's/(module:.*ref=)[^&"]+/\1'$GIT_RELEASE'/' aurora.yaml
kubectl apply -f ./aurora.yaml