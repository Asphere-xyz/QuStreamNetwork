# QuStreamNetwork Binary
#
# Requires to run from repository root and to copy the binary in the build folder (part of the release workflow)

FROM debian:stable AS builder

RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates

FROM debian:stable-slim
LABEL maintainer="t.emin@asphere.xyz"
LABEL description="QuStreamNetwork Binary"

RUN useradd -m -u 1000 -U -s /bin/sh -d /qustream qustream && \
	mkdir -p /qustream/.local/share && \
	mkdir /data && \
	chown -R qustream:qustream /data && \
	ln -s /data /qustream/.local/share/qustream && \
	rm -rf /usr/sbin

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

USER qustream

COPY --chown=qustream build/* /qustream
RUN chmod uog+x /qustream/qustream*

# 30333 for parachain p2p
# 30334 for relaychain p2p
# 9944 for Websocket & RPC call
# 9615 for Prometheus (metrics)
EXPOSE 30333 30334 9944 9615

VOLUME ["/data"]

ENTRYPOINT ["/qustream/qustream"]
