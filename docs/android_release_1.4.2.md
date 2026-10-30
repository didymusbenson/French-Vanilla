# Android release 1.4.2 (versionCode 10)

Prepared October 30, 2026 on Kista’s MacBook Pro for the November 1 Google Play Billing deadline.

## Release purpose

The Billing Library 8 migration was already published in source commit `bcb0697a0796798b7a6f39d7788e082843e49806`. The previously saved signed 1.4.1 (code 9) bundle also contains Billing 8.0.0; its Play upload or rollout was never verified. This release provides a newly built, signed, independently inspected AAB with an incremented version, plus a reusable artifact verification gate. It keeps the established locked dependencies and purchase implementation.

Google’s [Billing deprecation schedule](https://developer.android.com/google/play/billing/deprecation-faq?hl=en), checked October 30, 2026, lists November 1, 2026 as Billing 7’s extension deadline. Billing 8 is supported for new releases until August 31, 2027. Google also requires the `com.google.android.play.billingclient.version` manifest metadata to remain present for correct version detection.

## Artifact

| Property | Verified value |
| --- | --- |
| Filename | `French-Vanilla-1.4.2-build10.aab` |
| Application ID | `com.loosetie.frenchvanilla` |
| Version name / code | `1.4.2` / `10` |
| Billing Library | `8.0.0` |
| Target / minimum Android SDK | `36` / `24` |
| Size | `52,370,854` bytes |
| SHA-256 | `646f6cde7b54cd7bccf55fb4f2ce6a75d65bb45bb4b9e92d8bfa44e1560b498b` |
| Signer certificate SHA-256 | `E6:CF:BD:83:A3:64:57:09:A8:DA:73:DA:EB:13:CA:C4:E3:8E:63:5A:7F:3E:7F:04:44:A4:26:B2:6C:25:AF:0E` |

The signer matches the existing signed 1.4.1 bundle. Existing signing was used without creating or changing keys. Version code 10 is greater than the highest verified local release, code 9. The highest version code already uploaded to Play Console is **not verified**; Play must confirm that 10 is unused.

## Validation performed

- Flutter 3.41.2 / Dart 3.11.0; `flutter pub get --enforce-lockfile` passed without lockfile changes.
- Locked `in_app_purchase` 3.3.1 and `in_app_purchase_android` 0.5.0; Gradle `releaseRuntimeClasspath` resolved `com.android.billingclient:billing:8.0.0` through the Android plugin.
- `flutter analyze --no-pub --no-fatal-infos` passed: 29 existing informational notices, zero warnings or errors.
- `flutter test --no-pub` passed all 3 tests.
- `flutter build appbundle --release --no-pub` and the repository-required `flutter build ios --simulator --debug --no-codesign --no-pub` passed.
- Bundletool 1.18.1 validated the actual AAB. Its base manifest reports the expected package/version, Billing permission, Billing 8.0.0 metadata, and a non-debuggable release.
- The structured, signed AAB dependency metadata contains the Billing 8.0.0 Maven coordinate. The release DEX also contains the 8.0.0 version marker.
- Strict JAR signature verification passed apart from the expected Java trust-store warnings for the existing self-signed upload certificate. No unsigned-entry or expired-certificate errors were accepted.
- All six bundled arm64/x86_64 native libraries have ELF LOAD alignment of at least 16 KiB. This is a static compatibility check, not a device-runtime test.
- An independent reviewer ran the verifier against this AAB and the prior bundle; an intentionally wrong expected version code was rejected. All 8 focused verifier tests passed.

## Repeatable artifact gate

Supply an existing bundletool JAR and the final AAB path:

```sh
python3 -m unittest discover -s scripts -p 'test_verify_android_bundle.py'
python3 scripts/verify_android_bundle.py /path/to/French-Vanilla-1.4.2-build10.aab \
  --bundletool /path/to/bundletool-all-1.18.1.jar \
  --expected-version-name 1.4.2 \
  --expected-version-code 10 \
  --expected-signer-sha256 E6:CF:BD:83:A3:64:57:09:A8:DA:73:DA:EB:13:CA:C4:E3:8E:63:5A:7F:3E:7F:04:44:A4:26:B2:6C:25:AF:0E
```

The verifier reads the bundle and public certificate only. It does not access private signing keys or submit anything to Play.

## Remaining Play steps

No Play Console upload, submission, track change, or rollout was performed. The live policy warning is not cleared merely by building this file or publishing its source. Upload the verified bundle, confirm version code availability and the detected Billing version, complete the intended release, and then recheck policy status and active tracks. Do not assume an uploaded draft has replaced the affected release.

Actual Play purchase, cancellation, pending-purchase, restore, and acknowledgment flows were not exercised with a licensed tester account. The existing Flutter tests are not transaction tests; follow Google’s [billing testing guidance](https://developer.android.com/google/play/billing/test) when validating the release in Play.
