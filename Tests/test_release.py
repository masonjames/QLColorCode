"""Publication boundaries: rehearsals and altered artifacts must never upload."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import subprocess
import sys

SPEC = importlib.util.spec_from_file_location("release", Path(__file__).resolve().parents[1] / "scripts/release.py")
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.dmg = self.root / "QLColorCode-5.0.0-beta.1.dmg"
        self.dmg.write_bytes(b"synthetic DMG fixture, not an installable image")
        self.manifest = {
            "schema": 1, "repository": release.REPOSITORY, "distribution_ready": True,
            "working_tree_dirty": False, "tag": "v5.0.0-beta.1", "version": "5.0.0",
            "source_commit": "a" * 40, "dmg": self.dmg.name, "sha256": release.sha256(self.dmg),
        }

    def test_matching_artifact_is_accepted(self):
        self.assertEqual(release.validate_manifest(self.manifest, self.root), self.dmg)

    def test_rehearsal_cannot_be_uploaded(self):
        self.manifest["distribution_ready"] = False
        with self.assertRaises(ValueError):
            release.validate_manifest(self.manifest, self.root)

    def test_dirty_source_cannot_be_uploaded(self):
        self.manifest["working_tree_dirty"] = True
        with self.assertRaises(ValueError):
            release.validate_manifest(self.manifest, self.root)

    def test_changed_bytes_are_rejected(self):
        self.dmg.write_bytes(b"tampered")
        with self.assertRaises(ValueError):
            release.validate_manifest(self.manifest, self.root)

    def test_path_escape_is_rejected_before_reading(self):
        for name in ("../../secret", "/private/secret", "other.dmg"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                release.validate_manifest({**self.manifest, "dmg": name}, self.root)

    def test_foreign_repository_is_rejected(self):
        with self.assertRaises(ValueError):
            release.validate_manifest({**self.manifest, "repository": "other/project"}, self.root)

    def test_mismatched_version_is_rejected(self):
        with self.assertRaises(ValueError):
            release.validate_manifest({**self.manifest, "version": "4.1.0"}, self.root)

    def test_malformed_revision_is_rejected(self):
        with self.assertRaises(ValueError):
            release.validate_manifest({**self.manifest, "source_commit": "HEAD"}, self.root)

    def test_only_release_tags_can_enter_casks(self):
        for value in ('v5.0.0"\nsystem "oops"', "../v5.0.0", "main", "v5.0.0-beta.0", "v5.0.0\n", "v５.0.0"):
            with self.subTest(tag=value), self.assertRaises(ValueError):
                release.cask(value, "a" * 64)

    def test_cask_uses_same_immutable_universal_download(self):
        text = release.cask("v5.0.0-beta.1", "a" * 64)
        self.assertIn('version "5.0.0-beta.1"', text)
        self.assertIn('sha256 "' + "a" * 64 + '"', text)
        self.assertIn('depends_on macos: ">= :sequoia"', text)
        self.assertIn('/releases/download/v#{version}/QLColorCode-#{version}.dmg', text)
        self.assertNotIn("postflight", text)

    def test_cask_rejects_untrusted_checksum(self):
        with self.assertRaises(ValueError):
            release.cask("v5.0.0", '${shell}')

    def test_every_gate_needs_explicit_evidence(self):
        gates = {name: {"passed": True, "evidence": "Reviewed test receipt"} for name in release.GATES}
        release.require_ready({"stable": gates, "beta": {}}, "v5.0.0")
        for field in ({}, {**gates, "unknown_gate": {}}, {**gates, "parser_deadline": {"passed": True, "evidence": ""}},
                      {**gates, "parser_deadline": {"passed": False, "evidence": "Still open"}}):
            with self.subTest(gates=field), self.assertRaises(ValueError):
                release.require_ready({"stable": field, "beta": {}}, "v5.0.0")

    def test_beta_evidence_cannot_authorize_stable_release(self):
        readiness = {"stable": {}, "beta": {name: {"passed": True, "evidence": "Observed local beta trial"}
                                            for name in release.BETA_GATES}}
        release.require_ready(readiness, "v5.0.0-beta.1")
        with self.assertRaises(ValueError):
            release.require_ready(readiness, "v5.0.0")
        readiness["beta"]["local_runtime_and_install"]["passed"] = False
        with self.assertRaises(ValueError):
            release.require_ready(readiness, "v5.0.0-beta.1")

    def test_diagnostic_stderr_does_not_corrupt_parsed_stdout(self):
        result = release.run(sys.executable, "-c", 'import sys; print("{} "); print("diagnostic", file=sys.stderr)')
        self.assertEqual(result, "{}")

    def test_disabled_gatekeeper_cannot_pass(self):
        with patch.object(release, "run", return_value="assessments disabled"), self.assertRaises(ValueError):
            release.assess(self.dmg, "open")

    def test_local_signing_exception_cannot_count_as_notarization(self):
        with patch.object(release, "run", side_effect=["assessments enabled", "accepted\nsource=Developer ID"]), self.assertRaises(ValueError):
            release.assess(self.dmg, "open")

    def test_optimized_python_cannot_bypass_bundle_checks(self):
        result = subprocess.run([sys.executable, "-O", str(release.ROOT / "scripts/verify-bundle.py"), "/missing.app"], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("do not use -O", result.stderr)

    def test_source_receipt_detects_changed_input(self):
        before = release.source_digest(self.root)
        self.dmg.write_bytes(b"changed source fixture")
        self.assertNotEqual(release.source_digest(self.root), before)


if __name__ == "__main__":
    unittest.main()
