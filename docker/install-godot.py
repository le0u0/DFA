"""Install the official Godot executable and only its single-threaded Web template."""
import hashlib
import io
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
import urllib.request
import zipfile


class RemoteZip(io.RawIOBase):
    """Seek an HTTPS ZIP with validated byte ranges; never download the full kit."""

    def __init__(self, url):
        super().__init__()
        request = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(request, timeout=120) as response:
            self.url = response.geturl()
            self.size = int(response.headers["Content-Length"])
        self.position = 0

    def readable(self):
        return True

    def seekable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=io.SEEK_SET):
        target = offset if whence == io.SEEK_SET else self.position + offset if whence == io.SEEK_CUR else self.size + offset
        if target < 0:
            raise ValueError("Negative archive position")
        self.position = target
        return target

    def read(self, size=-1):
        end = self.size if size < 0 else min(self.size, self.position + size)
        if end <= self.position:
            return b""
        start = self.position
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={start}-{end - 1}"})
        with urllib.request.urlopen(request, timeout=120) as response:
            expected = f"bytes {start}-{end - 1}/{self.size}"
            if response.status != 206 or response.headers.get("Content-Range") != expected:
                raise RuntimeError("Export-template server did not honor byte ranges; refusing a full-kit download")
            data = response.read(end - start + 1)
        if len(data) != end - start:
            raise RuntimeError("Incomplete archive range")
        self.position = end
        return data


def install(version, architecture):
    if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", version):
        raise ValueError("Expected a stable Godot version")
    platform = {"amd64": "linux.x86_64", "arm64": "linux.arm64"}[architecture]
    base = f"https://github.com/godotengine/godot-builds/releases/download/{version}-stable"
    filename = f"Godot_v{version}-stable_{platform}.zip"
    with urllib.request.urlopen(f"{base}/SHA512-SUMS.txt", timeout=120) as response:
        checksums = dict((name.lstrip("*"), digest) for digest, name in (line.split(maxsplit=1) for line in response.read().decode().splitlines() if line.strip()))
    with tempfile.TemporaryDirectory() as temporary:
        archive = Path(temporary) / filename
        with urllib.request.urlopen(f"{base}/{filename}", timeout=120) as response, archive.open("wb") as dest:
            shutil.copyfileobj(response, dest)
        if hashlib.sha512(archive.read_bytes()).hexdigest() != checksums[filename]:
            raise RuntimeError("Godot executable checksum mismatch")
        with zipfile.ZipFile(archive) as packed:
            executable = next(n for n in packed.namelist() if Path(n).name == filename[:-4])
            with packed.open(executable) as src, open("/usr/local/bin/godot", "wb") as dest:
                shutil.copyfileobj(src, dest)
        Path("/usr/local/bin/godot").chmod(0o755)
    data_home = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    target = data_home / "godot/export_templates" / f"{version}.stable"
    target.mkdir(parents=True, exist_ok=True)
    # ZipFile verifies each selected member's CRC. TLS remains enabled for all requests.
    with RemoteZip(f"{base}/Godot_v{version}-stable_export_templates.tpz") as remote, zipfile.ZipFile(remote) as packed:
        template = next(n for n in packed.namelist() if Path(n).name == "web_nothreads_release.zip")
        with packed.open(template) as src, (target / "web_nothreads_release.zip").open("wb") as dest:
            shutil.copyfileobj(src, dest)
    print(f"Installed Godot {version} ({architecture}) and Web release template", flush=True)


if __name__ == "__main__":
    install(sys.argv[1], sys.argv[2])
