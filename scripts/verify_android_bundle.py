#!/usr/bin/env python3
"""Verify a French Vanilla release AAB without accessing private signing keys.

Requires Java, jarsigner, keytool, and a separately supplied bundletool JAR.
Prints a JSON evidence record on success; exits nonzero on any failed check.
This validates the local artifact, not its acceptance or publication by Play.
"""

import argparse
import hashlib
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path


PACKAGE = "com.loosetie.frenchvanilla"
ANDROID = "{http://schemas.android.com/apk/res/android}"
DEPENDENCIES_PATH = "BUNDLE-METADATA/com.android.tools.build.libraries/dependencies.pb"


class VerificationError(ValueError):
    """A required release property could not be verified."""


def require(condition, message):
    if not condition:
        raise VerificationError(message)


def protobuf_fields(data):
    """Read protobuf wire fields, rejecting truncated or unsupported encodings."""
    offset = 0

    def varint():
        nonlocal offset
        value = 0
        for shift in range(0, 70, 7):
            require(offset < len(data), "Truncated dependency protobuf varint")
            byte = data[offset]
            offset += 1
            require(shift < 63 or byte < 2, "Oversized dependency protobuf varint")
            value |= (byte & 127) << shift
            if byte < 128:
                return value
        raise VerificationError("Oversized dependency protobuf varint")

    while offset < len(data):
        key = varint()
        number, wire_type = key >> 3, key & 7
        require(number > 0, "Invalid dependency protobuf field number")
        if wire_type == 0:
            value = varint()
        else:
            require(wire_type in (1, 2, 5), "Unsupported dependency protobuf wire type")
            size = varint() if wire_type == 2 else (8 if wire_type == 1 else 4)
            require(size <= len(data) - offset, "Truncated dependency protobuf field")
            value = data[offset:offset + size]
            offset += size
        yield number, wire_type, value


def one_bytes_field(data, number):
    matches = [value for field, wire, value in protobuf_fields(data)
               if field == number and wire == 2]
    require(len(matches) == 1, f"Expected one dependency protobuf field {number}")
    return matches[0]


def billing_dependencies(data, expected_version):
    """Read Library.maven_library coordinates, not arbitrary string matches.

    AGP dependencies.proto: AppDependencies.library = 1;
    Library.maven_library = 1; MavenLibrary group = 1, artifact = 2, version = 5.
    """
    coordinates = []
    for number, wire, library in protobuf_fields(data):
        if number != 1 or wire != 2:
            continue
        maven_fields = [value for field, kind, value in protobuf_fields(library)
                        if field == 1 and kind == 2]
        # Non-Maven library variants may have other fields.
        if not maven_fields:
            continue
        require(len(maven_fields) == 1, "Ambiguous Maven dependency record")
        maven = maven_fields[0]
        try:
            group = one_bytes_field(maven, 1).decode("utf-8")
            artifact = one_bytes_field(maven, 2).decode("utf-8")
            version = one_bytes_field(maven, 5).decode("utf-8")
        except UnicodeDecodeError as error:
            raise VerificationError("Invalid Maven dependency text") from error
        if group == "com.android.billingclient":
            require(version == expected_version,
                    f"Packaged {group}:{artifact} is {version}, expected {expected_version}")
            coordinates.append(f"{group}:{artifact}:{version}")
    require(f"com.android.billingclient:billing:{expected_version}" in coordinates,
            "Packaged Billing Library coordinate is missing")
    return sorted(set(coordinates))


def manifest_properties(xml, expected_version_name, expected_version_code, expected_billing):
    try:
        manifest = ET.fromstring(xml)
    except ET.ParseError as error:
        raise VerificationError("Bundletool did not return a valid manifest XML") from error
    require(manifest.tag == "manifest", "Missing manifest root")
    require(manifest.get("package") == PACKAGE, "Unexpected application package")
    require(manifest.get(ANDROID + "versionName") == expected_version_name,
            "Unexpected versionName")
    require(manifest.get(ANDROID + "versionCode") == str(expected_version_code),
            "Unexpected versionCode")
    applications = manifest.findall("application")
    require(len(applications) == 1, "Expected one application in the base manifest")
    application = applications[0]
    require(application.get(ANDROID + "debuggable", "false") in ("false", "0"),
            "Release bundle is debuggable or has unresolved debuggable metadata")
    permissions = {node.get(ANDROID + "name") for node in manifest.findall("uses-permission")}
    require("com.android.vending.BILLING" in permissions, "Missing Billing permission")
    billing_versions = [node.get(ANDROID + "value") for node in application.findall("meta-data")
                        if node.get(ANDROID + "name") == "com.google.android.play.billingclient.version"]
    require(billing_versions == [expected_billing], "Missing or incorrect Billing manifest metadata")
    sdk = manifest.find("uses-sdk")
    require(sdk is not None, "Missing SDK manifest metadata")
    target = sdk.get(ANDROID + "targetSdkVersion", "")
    require(target.isdecimal() and int(target) > 0, "Missing numeric target SDK")
    return {
        "package": PACKAGE,
        "version_name": expected_version_name,
        "version_code": expected_version_code,
        "target_sdk": int(target),
        "min_sdk": sdk.get(ANDROID + "minSdkVersion"),
        "debuggable": False,
        "billing_permission": True,
        "billing_manifest_version": expected_billing,
    }


def signer_fingerprint(output, expected):
    expected = expected.replace(":", "").upper()
    require(re.fullmatch(r"[0-9A-F]{64}", expected), "Expected signer SHA256 must contain 64 hex digits")
    signers = re.findall(r"^Signer #(\d+):", output, re.MULTILINE)
    require(signers == ["1"], "Expected exactly one signing identity")
    fingerprints = re.findall(r"SHA256:\s*([0-9A-Fa-f:]+)", output)
    # This app's established upload certificate is self-signed: one signer, one certificate.
    require(len(fingerprints) == 1, "Expected one self-signed upload certificate")
    actual = fingerprints[0].replace(":", "").upper()
    require(actual == expected, "Signing certificate SHA256 does not match the existing upload certificate")
    return ":".join(actual[index:index + 2] for index in range(0, 64, 2))


def verify_jarsigner_result(returncode, output):
    require("jar verified" in output.lower(), "AAB signature was not verified")
    if returncode == 0:
        return []
    # Android upload keys are normally self-signed. Strict jarsigner reports code 4
    # because the certificate is not in Java's public CA store. Permit only those
    # two exact error categories; expiry, unsigned entries, and other failures fail.
    require(returncode == 4, f"Strict jarsigner validation failed (exit {returncode})")
    error_block = re.search(r"(?:^|\n)Error:\s*\n(.*?)(?=\nWarning:|\Z)", output, re.DOTALL)
    require(error_block is not None, "Unrecognized strict jarsigner error")
    errors = [line.strip() for line in error_block[1].splitlines() if line.strip()]
    allowed = (
        "This jar contains entries whose certificate chain is invalid. Reason: PKIX path building failed:",
        "This jar contains entries whose signer certificate is self-signed.",
    )
    require(errors and all(any(line.startswith(prefix) for prefix in allowed) for line in errors),
            "Jarsigner reported errors beyond the expected self-signed certificate")
    return ["Existing self-signed upload certificate is not trusted by Java's public CA store."]


def run(command, allowed_codes=(0,)):
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    output = result.stdout + result.stderr
    require(result.returncode in allowed_codes,
            f"{Path(command[0]).name} failed (exit {result.returncode}): {output[-2000:].strip()}")
    return result.returncode, output


def verify(args):
    bundle = args.bundle.resolve(strict=True)
    bundletool = args.bundletool.resolve(strict=True)
    java = [args.java, "-Duser.language=en", "-Duser.country=US", "-jar", str(bundletool)]
    run(java + ["validate", f"--bundle={bundle}"])
    _, manifest = run(java + ["dump", "manifest", f"--bundle={bundle}", "--module=base"])
    evidence = manifest_properties(manifest, args.expected_version_name,
                                   args.expected_version_code, args.expected_billing)
    with zipfile.ZipFile(bundle) as archive:
        names = archive.namelist()
        require(len(names) == len(set(names)), "Bundle contains duplicate ZIP entries")
        require(DEPENDENCIES_PATH in names, "Bundle dependency metadata is missing")
        evidence["billing_dependencies"] = billing_dependencies(
            archive.read(DEPENDENCIES_PATH), args.expected_billing)
    java_locale = ["-J-Duser.language=en", "-J-Duser.country=US"]
    code, signature = run([args.jarsigner, *java_locale, "-verify", "-strict", "-verbose", "-certs",
                           str(bundle)], allowed_codes=(0, 4))
    evidence["signature_notes"] = verify_jarsigner_result(code, signature)
    _, certificate = run([args.keytool, *java_locale, "-printcert", "-jarfile", str(bundle)])
    evidence["signer_sha256"] = signer_fingerprint(certificate, args.expected_signer_sha256)
    digest = hashlib.sha256()
    with bundle.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    evidence.update({
        "bundle": str(bundle), "bytes": bundle.stat().st_size, "sha256": digest.hexdigest(),
        "bundletool_validation": "passed", "signature_verified": True,
        "play_console_acceptance": "not_checked",
    })
    return evidence


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path)
    parser.add_argument("--bundletool", type=Path, required=True)
    parser.add_argument("--expected-version-name", required=True)
    parser.add_argument("--expected-version-code", type=int, required=True)
    parser.add_argument("--expected-signer-sha256", required=True)
    parser.add_argument("--expected-billing", default="8.0.0")
    parser.add_argument("--java", default="java")
    parser.add_argument("--jarsigner", default="jarsigner")
    parser.add_argument("--keytool", default="keytool")
    args = parser.parse_args()
    try:
        print(json.dumps(verify(args), indent=2))
    except (VerificationError, OSError, zipfile.BadZipFile) as error:
        print(f"AAB verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
