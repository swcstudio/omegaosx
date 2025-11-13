# OSXDK Development Docker Images

The OSXDK development Docker images provide the development environment for using and developing OSXDK.

## Building Docker Images

To build an OSXDK development Docker image and test it on your local machine, navigate to the root directory of the OmegaOS W3.x source code tree and execute the following command:

```bash
cd <omegaosx dir>
# Build Docker image
docker buildx build \
    -f osdk/tools/docker/Dockerfile \
    --build-arg ASTER_RUST_VERSION=$(grep "channel" rust-toolchain.toml | awk -F '"' '{print $2}') \
    -t omegaosx/osxdk:$(cat DOCKER_IMAGE_VERSION) \
    .
```

## Tagging and Uploading Docker Images

The Docker images are tagged according to the version specified
in the `DOCKER_IMAGE_VERSION` file at the project root.
Check out the [version bump](https://omegaosx.github.io/book/to-contribute/version-bump.html) documentation
on how new versions of the Docker images are released.
