"""Focused fail-closed tests; run: python3 -m unittest discover -s scripts -p 'test_*.py'."""

import unittest

from verify_android_bundle import (
    VerificationError,
    billing_dependencies,
    manifest_properties,
    signer_fingerprint,
    verify_jarsigner_result,
)


MANIFEST = '''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.loosetie.frenchvanilla" android:versionName="1.4.2" android:versionCode="10">
  <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="36"/>
  <uses-permission android:name="com.android.vending.BILLING"/>
  <application android:debuggable="false">
    <meta-data android:name="com.google.android.play.billingclient.version" android:value="8.0.0"/>
  </application>
</manifest>'''

# Actual AGP wire shape: AppDependencies.library -> Library.maven_library.
DEPENDENCY = b'\x0a\x2d\x0a\x2b\x0a\x19com.android.billingclient\x12\x07billing\x2a\x058.0.0'
FINGERPRINT = "E6:CF:BD:83:A3:64:57:09:A8:DA:73:DA:EB:13:CA:C4:E3:8E:63:5A:7F:3E:7F:04:44:A4:26:B2:6C:25:AF:0E"
SELF_SIGNED = '''jar verified, with signer errors.

Error:
This jar contains entries whose certificate chain is invalid. Reason: PKIX path building failed: no trusted certificate
This jar contains entries whose signer certificate is self-signed.

Warning:
This jar contains signatures that do not include a timestamp.
'''


class BundleChecksTest(unittest.TestCase):
    def check_manifest(self, xml):
        return manifest_properties(xml, "1.4.2", 10, "8.0.0")

    def test_valid_manifest(self):
        self.assertEqual(self.check_manifest(MANIFEST)["target_sdk"], 36)

    def test_rejects_wrong_release_and_billing_properties(self):
        replacements = [
            ('android:versionName="1.4.2"', 'android:versionName="1.4.1"'),
            ('android:versionCode="10"', 'android:versionCode="9"'),
            ('com.loosetie.frenchvanilla', 'com.example.unrelated'),
            ('android:debuggable="false"', 'android:debuggable="true"'),
            ('android:value="8.0.0"', 'android:value="7.1.1"'),
            ('com.android.vending.BILLING', 'android.permission.INTERNET'),
        ]
        for before, after in replacements:
            with self.subTest(after=after), self.assertRaises(VerificationError):
                self.check_manifest(MANIFEST.replace(before, after))

    def test_reads_structured_billing_coordinate(self):
        self.assertEqual(billing_dependencies(DEPENDENCY, "8.0.0"),
                         ["com.android.billingclient:billing:8.0.0"])

    def test_rejects_old_billing_even_with_new_version_elsewhere(self):
        with self.assertRaises(VerificationError):
            billing_dependencies(DEPENDENCY.replace(b'8.0.0', b'7.1.1') + b'\x12\x058.0.0', "8.0.0")

    def test_rejects_missing_or_truncated_dependency_metadata(self):
        for data in (b'', DEPENDENCY[:-1], b'\x0a\xff', b'\x00', b'\x0b'):
            with self.subTest(data=data), self.assertRaises(VerificationError):
                billing_dependencies(data, "8.0.0")

    def test_accepts_expected_self_signed_certificate(self):
        self.assertEqual(len(verify_jarsigner_result(4, SELF_SIGNED)), 1)
        certificate = f"Signer #1:\nCertificate #1:\n SHA256: {FINGERPRINT}\n"
        self.assertEqual(signer_fingerprint(certificate, FINGERPRINT), FINGERPRINT)

    def test_rejects_wrong_or_multiple_signers(self):
        certificate = f"Signer #1:\n SHA256: {FINGERPRINT}\n"
        for output, expected in ((certificate, "00" * 32),
                                 (certificate + "Signer #2:\n", FINGERPRINT)):
            with self.subTest(output=output), self.assertRaises(VerificationError):
                signer_fingerprint(output, expected)

    def test_rejects_unsigned_expired_or_unverified_bundles(self):
        cases = [
            (16, "jar verified, with signer errors.\nUnsigned entries."),
            (4, SELF_SIGNED.replace("Warning:", "This jar contains entries whose signer certificate has expired.\n\nWarning:")),
            (0, "jar is unsigned."),
            (1, "java.lang.SecurityException: invalid signature"),
        ]
        for code, output in cases:
            with self.subTest(code=code, output=output), self.assertRaises(VerificationError):
                verify_jarsigner_result(code, output)


if __name__ == "__main__":
    unittest.main()
