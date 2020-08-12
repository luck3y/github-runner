# Github self-hosted runner Dockerfile and Kubernetes configuration

This repository contains a Dockerfile that builds a container image suitable for running a [self-hosted GitHub runner](https://sanderknape.com/2020/03/self-hosted-github-actions-runner-kubernetes/). A Kubernetes Deployment file is also included that you can use as an example on how to deploy this container to a Kubernetes cluster.

This fork of the original repository adds support for OpenShift and a [UBI](https://developers.redhat.com/products/rhel/ubi) based container image.

You can build this image yourself, or use the [prebuilt container image](https://quay.io/repository/bbrowning/openshift-github-runner).

## Building and pushing the container

Replace the image repository below with your own if you're not bbrowning.

```sh
podman build . -t quay.io/bbrowning/openshift-github-runner
podman push quay.io/bbrowning/openshift-github-runner
```

## Features

* Repository runners
* Organizational runners
* Labels
* Graceful shutdown

## OpenShift Example

Create a new project for the runner.

```sh
oc new-project github-runner
```

Create a new secret with your GitHub personal access token.

```sh
oc create secret generic my-secret -n github-runner --from-literal=pat=<your personal access token>
```

Create a Kubernets Deployment that registers a runner to a repository.

```sh
curl https://raw.githubusercontent.com/bbrowning/github-runner/openshift/deployment.yml | \
  sed -e 's/your-organization/<your github org>/' -e 's/your-repository/<your github repo>/' | \
  oc apply -n github-runner -f -
```

Wait for the Deployment to be ready.

```sh
oc wait --for=condition=Available -n github-runner deployment/github-runner --timeout=120s
```

Check logs of the Deployment.

```sh
oc logs -n github-runner deployment/github-runner
```

You should see something like:
```
--------------------------------------------------------------------------------
|        ____ _ _   _   _       _          _        _   _                      |
|       / ___(_) |_| | | |_   _| |__      / \   ___| |_(_) ___  _ __  ___      |
|      | |  _| | __| |_| | | | | '_ \    / _ \ / __| __| |/ _ \| '_ \/ __|     |
|      | |_| | | |_|  _  | |_| | |_) |  / ___ \ (__| |_| | (_) | | | \__ \     |
|       \____|_|\__|_| |_|\__,_|_.__/  /_/   \_\___|\__|_|\___/|_| |_|___/     |
|                                                                              |
|                       Self-hosted runner registration                        |
|                                                                              |
--------------------------------------------------------------------------------

# Authentication


√ Connected to GitHub

# Runner Registration



√ Runner successfully added
√ Runner connection is good

# Runner settings


√ Settings Saved.

.path=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Starting Runner listener with startup type: service
Started listener process
Started running service

√ Connected to GitHub

2020-08-11 21:52:02Z: Listening for Jobs
```

All runners created in this way will have an `openshift` label that
can be used as the `runs-on` value of a workflow to run actions on
your OpenShift worker.
