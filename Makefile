CGO_ENABLED=0
GOOS=linux
KO_DOCKER_REPO=${DOCKER_REPO_OVERRIDE}
BRANCH=
TEST=
IMAGE=

# Guess location of openshift/release repo. NOTE: override this if it is not correct.
OPENSHIFT=${CURDIR}/../../github.com/openshift/release

# Update CI configuration in the $(OPENSHIFT) directory.
# NOTE: Makes changes outside this repository.
update-ci:
	sh ./openshift/ci-operator/update-ci.sh $(OPENSHIFT)
.PHONY: update-ci