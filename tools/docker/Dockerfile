FROM rust:1.75-slim as builder

WORKDIR /usr/src/omegaosx
COPY . .

RUN apt-get update && apt-get install -y build-essential pkg-config libssl-dev
RUN cargo build --release --bin omegaosx-kernel

FROM gcr.io/distroless/cc-debian12

COPY --from=builder /usr/src/omegaosx/target/release/omegaosx-kernel /usr/local/bin/
COPY LICENSE /app/LICENSE

USER 1000

HEALTHCHECK --interval=30s --timeout=3s CMD /usr/local/bin/omegaosx-kernel --health || exit 1

CMD ["omegaosx-kernel"]