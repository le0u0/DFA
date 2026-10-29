FROM python:3.13-slim-bookworm AS export
ARG GODOT_VERSION=4.6.3
ARG TARGETARCH
ENV GODOT_SILENCE_ROOT_WARNING=1
WORKDIR /project
RUN --mount=type=secret,id=proxy_ca \
    set -eu; dfa_ca_option=""; \
    if [ -f /run/secrets/proxy_ca ]; then dfa_ca_option="-o Acquire::https::CaInfo=/run/secrets/proxy_ca"; fi; \
    apt-get $dfa_ca_option update && \
    apt-get $dfa_ca_option install -y --no-install-recommends libfontconfig1 && \
    rm -rf /var/lib/apt/lists/*
COPY docker/install-godot.py /tmp/install-godot.py
# Optional secret is for managed environments with a session-specific proxy CA.
# On a normal Mac build Docker/Python use their standard CA stores.
RUN --mount=type=secret,id=proxy_ca \
    if [ -f /run/secrets/proxy_ca ]; then \
      SSL_CERT_FILE=/run/secrets/proxy_ca python /tmp/install-godot.py "$GODOT_VERSION" "$TARGETARCH"; \
    else \
      python /tmp/install-godot.py "$GODOT_VERSION" "$TARGETARCH"; \
    fi
COPY project.godot export_presets.cfg ./
COPY assets ./assets
COPY game ./game
COPY scenes ./scenes
RUN godot --headless --editor --import --quit && \
    mkdir -p /web && \
    godot --headless --export-release Web /web/index.html

FROM python:3.13-slim-bookworm AS serve
WORKDIR /site
COPY --chmod=644 docker/serve-web.py /usr/local/bin/serve-web.py
COPY --from=export /web/ ./
RUN chmod -R a+rX /site
USER 65534:65534
EXPOSE 8080
CMD ["python", "/usr/local/bin/serve-web.py"]
