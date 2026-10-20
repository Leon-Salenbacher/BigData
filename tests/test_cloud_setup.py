"""Offline checks: python -m unittest discover -s tests -v."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLOUD = ROOT / "setup/cloud"
BASH = shutil.which("bash")
if os.name == "nt" and Path("C:/Program Files/Git/bin/bash.exe").exists():
    BASH = "C:/Program Files/Git/bin/bash.exe"
PWSH = shutil.which("pwsh")


class ConfigTests(unittest.TestCase):
    def test_json_inputs(self):
        cases = [
            ({"project_id": "test-project", "instance_name": "bigdata", "zone": "europe-west3-a"}, True),
            ({"project_id": "test-project"}, False),
            ({"project_id": "$(echo injected)", "instance_name": "vm", "zone": "zone"}, False),
            ([], False),
            ("{broken", False),
        ]
        with tempfile.TemporaryDirectory(dir=ROOT) as directory:
            path = Path(directory) / "config.json"
            for value, valid in cases:
                with self.subTest(value=value):
                    path.write_text(value if isinstance(value, str) else json.dumps(value))
                    result = subprocess.run([sys.executable, str(CLOUD / "read-config.py"), str(path)], capture_output=True, text=True)
                    self.assertEqual(result.returncode == 0, valid, result.stderr)
            path.unlink()
            result = subprocess.run([sys.executable, str(CLOUD / "read-config.py"), str(path)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)

    @unittest.skipUnless(PWSH, "PowerShell unavailable")
    def test_ip_helper(self):
        with tempfile.TemporaryDirectory(dir=ROOT) as directory:
            output = Path(directory) / "ip.json"
            for ip, valid in [("203.0.113.42", True), ("999.1.1.1", False), ("::1", False), ("", False), ("127.1", False)]:
                with self.subTest(ip=ip):
                    result = subprocess.run([PWSH, "-NoProfile", "-File", str(ROOT / "infra/update-ip.ps1"), "-PublicIp", ip, "-OutputPath", str(output)], capture_output=True, text=True)
                    self.assertEqual(result.returncode == 0, valid, result.stderr)
                    self.assertEqual(json.loads(output.read_text())["ssh_source_cidr"], "203.0.113.42/32")
            # Exercise automatic lookup offline, including a failed response.
            for response, valid in [("198.51.100.1", True), ("invalid", False)]:
                command = "function Invoke-RestMethod { '" + response + "' }; & '" + str(ROOT / "infra/update-ip.ps1") + "' -OutputPath '" + str(output) + "'"
                result = subprocess.run([PWSH, "-NoProfile", "-Command", command], capture_output=True, text=True)
                self.assertEqual(result.returncode == 0, valid, result.stderr)
            self.assertEqual(json.loads(output.read_text())["ssh_source_cidr"], "198.51.100.1/32")


@unittest.skipUnless(BASH, "Bash unavailable")
class LifecycleTests(unittest.TestCase):
    def test_syntax(self):
        for path in (ROOT / "setup").rglob("*.sh"):
            result = subprocess.run([BASH, "-n", path.as_posix()], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_lifecycle(self):
        for status, deployment, expected in [("TERMINATED", "failure", 9), ("RUNNING", "term", 0), ("", "term", 1), ("API_ERROR", "term", 8)]:
            with self.subTest(status=status), tempfile.TemporaryDirectory(dir=ROOT) as directory:
                folder = Path(directory)
                for name in ("entrypoint.sh", "instance.sh"):
                    shutil.copy(CLOUD / name, folder / name)
                (folder / "config.sh").write_text('''load_config() { GCE_INSTANCE_NAME=test; GCE_ZONE=test-zone; }
authenticate() { :; }
gc() {
    echo "$*" >> "$TEST_CALL_LOG"
    if [ "$1 $2 $3" = "compute instances list" ]; then
        if [ "$TEST_STATUS" = API_ERROR ]; then return 8; fi
        echo "$TEST_STATUS"
    fi
}
sleep() { kill -TERM $$; }
''', newline="\n")
                (folder / "ssh.sh").write_text("wait_for_ssh() { :; }\n", newline="\n")
                (folder / "deploy.sh").write_text("deploy_task() { " + ("return 9;" if deployment == "failure" else ":;") + " }\n", newline="\n")
                log = folder / "calls.log"
                env = dict(os.environ, TEST_STATUS=status, TEST_CALL_LOG=log.as_posix())
                result = subprocess.run([BASH, (folder / "entrypoint.sh").as_posix()], cwd=ROOT, env=env, capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, expected, result.stderr)
                calls = log.read_text()
                self.assertEqual("instances start" in calls, status == "TERMINATED")
                self.assertEqual("instances stop" in calls, status in ("RUNNING", "TERMINATED"))
                self.assertNotIn("instances create", calls)
                self.assertNotIn("firewall", calls)


if __name__ == "__main__":
    unittest.main()
