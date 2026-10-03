"""Small FastAPI service used as the deployable unit for the release pipeline."""
import os

from fastapi import FastAPI, Response

APP_VERSION = os.getenv("APP_VERSION", "0.0.0-dev")
APP_ENV = os.getenv("APP_ENV", "local")

app = FastAPI(title="release-pipeline-demo", version=APP_VERSION)


@app.get("/health")
def health(response: Response):
    # APP_FAIL_HEALTH lets the pipeline simulate a bad release to prove auto-rollback.
    if os.getenv("APP_FAIL_HEALTH") == "1":
        response.status_code = 503
        return {"status": "unhealthy", "version": APP_VERSION}
    return {"status": "ok", "version": APP_VERSION, "env": APP_ENV}


@app.get("/version")
def version():
    return {"version": APP_VERSION, "env": APP_ENV}
