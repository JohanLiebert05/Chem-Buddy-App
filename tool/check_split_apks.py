"""Check ABI packaging and retained native features without executing an APK.

Usage: python tool/check_split_apks.py UNIVERSAL_APK SPLIT_OUTPUT_DIRECTORY
The baseline need not have identical Dart code. Native OCR/PDF libraries must be
retained with matching bytes. Educational/web assets must match this checkout.
"""
import hashlib
import json
from pathlib import Path
import sys
from zipfile import ZipFile


def digest(archive, name):
    return hashlib.sha256(archive.read(name)).hexdigest()


def inspect(baseline, directory):
    result = {"baseline_bytes": baseline.stat().st_size, "splits": []}
    with ZipFile(baseline) as old:
        # Compiled shaders, fonts and asset manifests can legitimately change.
        assets = [n for n in old.namelist() if n.startswith(
            ("assets/flutter_assets/assets/", "assets/flutter_assets/web/"))
            and not n.endswith("/")]
        for abi in ("arm64-v8a", "armeabi-v7a", "x86_64"):
            path = directory / f"app-{abi}-release.apk"
            with ZipFile(path) as new:
                names = set(new.namelist())
                abis = {n.split("/")[1] for n in names if n.startswith("lib/")}
                assert abis == {abi}, (path, abis)
                retained = [n for n in old.namelist()
                            if n.startswith(f"lib/{abi}/")
                            and not n.endswith(("libapp.so", "libflutter.so", "/"))]
                assert any("ocr" in n for n in retained), "OCR check is missing"
                assert any("pdfium" in n for n in retained), "PDF check is missing"
                for name in assets + retained:
                    assert name in names, f"Missing feature asset/library: {name}"
                    if name in retained:
                        expected = digest(old, name)
                    else:
                        source = Path(__file__).resolve().parents[1] / name.removeprefix("assets/flutter_assets/")
                        expected = hashlib.sha256(source.read_bytes()).hexdigest()
                    assert expected == digest(new, name), f"Changed: {name}"
                size = path.stat().st_size
                result["splits"].append({
                    "abi": abi, "bytes": size,
                    "reduction_percent": round(100 * (1 - size / baseline.stat().st_size), 2),
                    "feature_assets_matching_checkout": len(assets),
                    "unchanged_native_libraries": len(retained),
                    "ocr_and_pdf_present": True,
                })
    return result


if __name__ == "__main__":
    print(json.dumps(inspect(Path(sys.argv[1]), Path(sys.argv[2])), indent=2))
