# Test DFA in a browser with Docker

On a Mac, install and open [Docker Desktop](https://www.docker.com/products/docker-desktop/). Godot runs in the build container; no native Godot installation is needed. Use Chrome (or another browser with WebGL 2 support).

In your DFA checkout:

```sh
git fetch origin
git switch dfo-character-animations
git pull --ff-only
npm start
```

After this initial update, launch with just **`npm start`** (equivalently `npm run start`). No `npm install` is required: the package contains no dependencies, only Docker shortcuts. Node/npm must be installed to use the shortcut; the direct command `docker compose up --build` remains available with Docker Desktop alone. Startup does not pull Git changes automatically. Run `git pull --ff-only` when you want updates; it stops if your local and remote histories have diverged instead of creating a merge commit.

Wait for the build and server startup, then open **http://localhost:8080** and choose **Start**, select your character, then enter a dungeon. Click inside the game before using the keyboard. The first build downloads the engine and web template; subsequent builds reuse the cached tools. After pulling new art/code, run `npm start` again.

- **Arrows:** move; double-tap left/right to run
- **X:** basic attack / combo
- **Z:** class skill
- **C:** jump
- **Space:** dodge
- **V:** change equipment appearance
- **Esc:** pause / resume

For repeatable tests, select **Training · Immortal goblin** in the dungeon dropdown. Test all five classes through the same Start flow. Slayer uses the latest chibi source sheet; source-faithful run/attack remapping is still pending. See [animation status](../docs/art/slayer/animation-proof/README.md).

Stop with **Ctrl+C**, then remove the stopped service with:

```sh
npm run stop
```

If port 8080 is already in use, change the host side in `compose.yaml` (for example `127.0.0.1:8081:8080`) and open the matching URL. If the browser's Quit button stops the game, reload the page. This setup serves only on your own computer's loopback interface; no public hosting is configured.

## Extract original action references

With the original `~/Documents/DFO.zip` present, run:

```sh
npm run extract:actions
```

This optional Docker helper reads the archive and matching `sk.dat` / `DFO.exe` client metadata without running or exporting the executable. It writes a small reference package to **Documents/DFO-action-reference/** on your Mac. Upload its reference ZIP (or all numbered parts) in our chat. On a validation failure, upload its diagnostic ZIP instead. Existing game data is mounted read-only, with only the dedicated output folder writable. No whole-game unpacking or additional Mac Python packages are needed.

The helper is an opt-in Compose profile; normal `npm start` still launches only the game preview. The original PVF variant is checked by its header/layout, string-pool decompression, group boundaries and decompressed sizes. This protects the reference work from silently using invalid frame data; it is not a claim that original motion has already been recreated.

## Docker Hub proxy or DNS errors

If a build reports `auth.docker.io`, `Proxy Error`, or `DNS Failed`, Docker Desktop cannot reach the image registry. In Docker Desktop, open **Settings → Resources → Proxies** and check the configured proxy. If your network does not require a proxy, disable a stale manual proxy; otherwise use the proxy settings supplied for your network. Apply the change and restart Docker Desktop, then rerun `docker compose up --build`.

The Dockerfile uses Docker Desktop’s bundled BuildKit frontend, avoiding a separate `docker/dockerfile` image download. The Python base image still requires registry access on the first build. Signing in to Docker does not repair a proxy DNS failure.

## Build and validation details

The multi-stage Dockerfile downloads Godot **4.6.3**, checks the executable's SHA-512 against the official release checksum list, imports the project, and exports the single-threaded Web target. The downloader reads only the needed member of the large export-template archive using validated HTTP byte ranges. It refuses servers that ignore ranges rather than downloading the entire export kit. Both `amd64` and `arm64` select the corresponding official Linux executable; no forced Intel emulation is configured for Apple Silicon.

The serving image contains Python and the exported files, runs as an unprivileged user, and is about **153 MiB** uncompressed. Docker Desktop itself and build caches need additional disk space. The server sets WebAssembly MIME type, no-cache behavior, and cross-origin isolation headers. Game state is not persisted by this preview container.

Validated here on Linux/amd64: complete Docker build/export, container startup as the unprivileged user, HTTP HTML/JS/WASM/PCK responses and headers, and Chromium/WebGL 2 loading. The initial browser validation exercised the previous inspection controls. That screen has since been removed; current testing uses Start and the normal gameplay controls. Physical Mac/arm64 and Safari have not been tested in this environment.

In managed cloud environments with an injected HTTPS proxy CA, the optional BuildKit secret is supported:

```sh
docker build --secret id=proxy_ca,src=/etc/ssl/certs/ca-certificates.crt -t dfa-animation-web .
docker run --rm -p 127.0.0.1:8080:8080 dfa-animation-web
```

Normal Docker Desktop builds do not need this secret. Certificate verification remains enabled.
