#!/bin/bash
set -x
set -e
BUILDER=gcr.io/mlab-sandbox/github-m-lab-builder:travis

docker pull $BUILDER

# On pull requests, the origin repo and branch are provided in
# TRAVIS_PULL_REQUEST_{BRANCH, REPO_SLUG}  On pushes, these are
# empty, and we want to use the TRAVIS_ versions.
REPO=${TRAVIS_PULL_REQUEST_SLUG:-$TRAVIS_REPO_SLUG}
BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}

# TODO update to use github-m-lab-builder:master as soon as there is one.
docker run \
  -v `pwd`/slicebase-i386:/root/builder/build/slicebase-i386 \
  -v `pwd`/bin:/root/bin \
  $BUILDER /root/bin/build_npad.sh $REPO $BRANCH
