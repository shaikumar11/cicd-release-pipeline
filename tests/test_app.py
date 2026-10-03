import os
import unittest

from fastapi.testclient import TestClient


class AppTests(unittest.TestCase):
    def setUp(self):
        os.environ.pop("APP_FAIL_HEALTH", None)
        from app.main import app
        self.client = TestClient(app)

    def tearDown(self):
        os.environ.pop("APP_FAIL_HEALTH", None)

    def test_health_ok(self):
        r = self.client.get("/health")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.json()["status"], "ok")

    def test_health_fails_when_flag_set(self):
        os.environ["APP_FAIL_HEALTH"] = "1"
        r = self.client.get("/health")
        self.assertEqual(r.status_code, 503)

    def test_version_endpoint(self):
        r = self.client.get("/version")
        self.assertEqual(r.status_code, 200)
        self.assertIn("version", r.json())


if __name__ == "__main__":
    unittest.main()
