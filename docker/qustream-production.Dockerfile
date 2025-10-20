# Production Node for QuStream
#
# Requires to run from repository root and to copy the binary in the build folder (part of the release workflow)

FROM docker.io/library/ubuntu:22.04 AS builder

# Branch or tag to build qustream from
ARG COMMIT="qustream"
ARG RUSTFLAGS=""
ENV RUSTFLAGS=$RUSTFLAGS
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /

RUN echo "*** Installing Basic dependencies ***"
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates
RUN apt install --assume-yes git clang curl libssl-dev llvm libudev-dev make protobuf-compiler pkg-config

RUN set -e

RUN echo "*** Installing Rust environment ***"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"
RUN rustup default stable
# rustup version are pinned in the rust-toolchain file

# Clone the QuStreamNetwork repository
RUN echo "*** Cloning QuStreamNetwork ***" && \
	if git ls-remote --heads https://github.com/Asphere-xyz/QuStreamNetwork.git $COMMIT | grep -q $COMMIT; then \
	echo "Cloning branch $COMMIT"; \
	git clone --depth=1 --branch $COMMIT https://github.com/Asphere-xyz/QuStreamNetwork.git; \
	elif git ls-remote --tags https://github.com/Asphere-xyz/QuStreamNetwork.git $COMMIT | grep -q $COMMIT; then \
	echo "Cloning tag $COMMIT"; \
	git clone --depth=1 --branch $COMMIT https://github.com/Asphere-xyz/QuStreamNetwork.git; \
	else \
	echo "Cloning specific commit $COMMIT"; \
	git clone --depth=1 https://github.com/Asphere-xyz/QuStreamNetwork.git && \
	cd QuStreamNetwork && \
	git fetch origin $COMMIT && \
	git checkout $COMMIT; \
	fi

WORKDIR /qustream/qustream

# Print target cpu
RUN rustc --print target-cpus

RUN echo "*** Building QuStreamNetwork ***"
RUN cargo build --profile=production --all

FROM debian:stable-slim
LABEL maintainer="t.emin@asphere.xyz"
LABEL description="Production Binary for QuStreamNetwork Nodes"

RUN useradd -m -u 1000 -U -s /bin/sh -d /qustream qustream && \
	mkdir -p /qustream/.local/share && \
	mkdir /data && \
	chown -R qustream:qustream /data && \
	ln -s /data /qustream/.local/share/qustream && \
	rm -rf /usr/sbin

USER qustream

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder --chown=qustream /qustream/target/production/qustream /qustream/qustream

RUN chmod uog+x /qustream/qustream

# 30333 for parachain p2p
# 30334 for relaychain p2p
# 9944 for Websocket & RPC call
# 9615 for Prometheus (metrics)
EXPOSE 30333 30334 9944 9615

VOLUME ["/data"]

ENTRYPOINT ["/qustream/qustream"]
