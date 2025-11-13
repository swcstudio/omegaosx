# OmegaOS W3.x Development Docker Images

OmegaOS W3.x development Docker images are provided to facilitate developing and testing OmegaOS W3.x project. These images can be found in the [omegaosx/omegaosx](https://hub.docker.com/r/omegaosx/omegaosx/) repository on DockerHub.

## Building Docker Images

OmegaOS W3.x development Docker image is based on an OSXDK development Docker image. To build an OmegaOS W3.x development Docker image and test it on your local machine, navigate to the root directory of the OmegaOS W3.x source code tree and execute the following command:

```bash
cd <omegaosx dir>
# Build Docker image
docker buildx build \
    -f tools/docker/Dockerfile \
    --build-arg ASTER_RUST_VERSION=$(grep "channel" rust-toolchain.toml | awk -F '"' '{print $2}') \
    --build-arg BASE_VERSION=$(cat DOCKER_IMAGE_VERSION) \
    -t omegaosx/omegaosx:$(cat DOCKER_IMAGE_VERSION) \
    .
```

## Tagging and Uploading Docker Images

The Docker images are tagged according to the version specified
in the `DOCKER_IMAGE_VERSION` file at the project root.
Check out the [version bump](https://omegaosx.github.io/book/to-contribute/version-bump.html) documentation
on how new versions of the Docker images are released.
