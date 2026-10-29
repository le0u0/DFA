# Test DFA in a browser with Docker

On a Mac, install and open [Docker Desktop](https://www.docker.com/products/docker-desktop/). Godot runs in the build container; no native Godot installation is needed. Use Chrome (or another browser with WebGL 2 support).

In your DFA checkout:

```sh
git fetch origin
git switch dfo-character-animations
git pull --ff-only
docker compose up --build
```

Wait for the build and server startup, then open **http://localhost:8080** and choose **Slayer animation lab**. Click inside the game before using the keyboard. The first build downloads the engine and web template; subsequent builds reuse the cached tools. After pulling new art/code, run `docker compose up --build` again.

- **1 / 2 / 3:** idle / walk / attack
- **F:** switch facing
- **P:** pause / resume
- **, / .:** step backward / forward
- **V:** steel sword / cyan sword / body only
- **Esc:** main menu

Choose **0.25×** and **Show grip / feet** to inspect attachment and foot registration. The right windup still holds guard as documented in the [animation-proof notes](../docs/art/slayer/animation-proof/README.md). This does not turn the draft art into final animations.

Stop with **Ctrl+C**, then remove the stopped service with:

```sh
docker compose down
```

If port 8080 is already in use, change the host side in `compose.yaml` (for example `127.0.0.1:8081:8080`) and open the matching URL. If the browser's Quit button stops the game, reload the page. This setup serves only on your own computer's loopback interface; no public hosting is configured.

## Build and validation details

The multi-stage Dockerfile downloads Godot **4.6.3**, checks the executable's SHA-512 against the official release checksum list, imports the project, and exports the single-threaded Web target. The downloader reads only the needed member of the large export-template archive using validated HTTP byte ranges. It refuses servers that ignore ranges rather than downloading the entire export kit. Both `amd64` and `arm64` select the corresponding official Linux executable; no forced Intel emulation is configured for Apple Silicon.

The serving image contains Python and the exported files, runs as an unprivileged user, and is about **153 MiB** uncompressed. Docker Desktop itself and build caches need additional disk space. The server sets WebAssembly MIME type, no-cache behavior, and cross-origin isolation headers. Game state is not persisted by this preview container.

Validated here on Linux/amd64: complete Docker build/export, container startup as the unprivileged user, HTTP HTML/JS/WASM/PCK responses and headers, and Chromium/WebGL 2 loading. Browser checks exercised lab entry, attack selection, facing, paused frame stepping, cyan/body-only swapping, and Esc back to the main menu; no browser or script errors were reported. Physical Mac/arm64 and Safari have not been tested in this environment.

In managed cloud environments with an injected HTTPS proxy CA, the optional BuildKit secret is supported:

```sh
docker build --secret id=proxy_ca,src=/etc/ssl/certs/ca-certificates.crt -t dfa-animation-web .
docker run --rm -p 127.0.0.1:8080:8080 dfa-animation-web
```

Normal Docker Desktop builds do not need this secret. Certificate verification remains enabled.
