# Openshift Knative Common Packages

This repository holds Openshift's fork of [`knative/pkg`](https://github.com/knative/pkg) 
with additions and fixes needed only for the OpenShift side of things.

![sink](https://live.staticflickr.com/2524/3727870484_d57ce2b914.jpg)

["The kitchen sink"](https://www.flickr.com/photos/11121568@N06/3727870484) by
Alan Cleaver is licensed under CC BY 2.0

## How this repository works ?

The `main` branch holds up-to-date specific [openshift files](./openshift)
that are necessary for CI setups and maintaining it. This includes:

- Scripts to create a new release branch from `upstream`
- CI setup files & tests scripts

Each release branch holds the upstream code for that release and our
openshift's specific files.

## CI Setup

For the CI setup, two repositories are of importance:

- This repository
- [openshift/release](https://github.com/openshift/release) which
  contains the configuration of CI jobs that are run on this
  repository
