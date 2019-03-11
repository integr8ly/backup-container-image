# Integreatly Linux Container

This folder container the linux container source code that runs a integreatly backup script.

## Building

Build the image:

```
docker build -t quay.io/integreatly/backup-container:dev .
``` 

Push it:

```
docker push quay.io/integreatly/backup-container:dev
```

## Usage

The image contains a [entrypoint script](tools/entrypoint.sh) which runs a backup script base on some parameters:

* `-c`: specifies the "component" to run a backup against, such as mysql, redis, postgres, etc.
* `-b`: specifies a backend engine to upload the component arquive such as "s3"
* `-e'`: specifies a encryption mechanism to encrypt the component archive before
* `-d`: debug flag that will sleep the container for eternity if set to any value (usefull for debugging when running in a pod)


## Local development
You can run the backup script locally.

Prerequisites:
- Login into your cluster via `oc login`
- Create a symlink for oc config: `mkdir -p /tmp/intly/ && ln -s ~/.kube/ /tmp/intly/.kube`
- Set environment variables that will be required by the component and encryption/upload step. E.g. ENCRYPTION_SECRET_NAME, BACKEND_SECRET_NAME, COMPONENT_SECRET_NAME (for mysql component), etc.

Run it like:

```./image/tools/entrypoint.sh -c 3scale-redis```

Other params:
- `-e ""` parameter will skip encryption
- `-d "true"` will enable debugging mode