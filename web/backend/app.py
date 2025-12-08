from fastapi import FastAPI
from datetime import timedelta
import os

from couchbase.cluster import Cluster, ClusterOptions
from couchbase.auth import PasswordAuthenticator
from couchbase.options import ClusterTimeoutOptions

app = FastAPI()

COUCHBASE_HOST = os.getenv("COUCHBASE_HOST")
COUCHBASE_BUCKET = os.getenv("COUCHBASE_BUCKET")
COUCHBASE_USER = os.getenv("COUCHBASE_USERNAME")
COUCHBASE_PASS = os.getenv("COUCHBASE_PASSWORD")


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/api/analytics")
def get_analytics():
    try:
        conn_str = f"couchbases://{COUCHBASE_HOST}" if "cloud.couchbase.com" in COUCHBASE_HOST else f"couchbase://{COUCHBASE_HOST}"
        
        cluster = Cluster(
            conn_str,
            ClusterOptions(
                PasswordAuthenticator(COUCHBASE_USER, COUCHBASE_PASS),
                timeout_options=ClusterTimeoutOptions(kv_timeout=timedelta(seconds=5))
            )
        )

        bucket = cluster.bucket(COUCHBASE_BUCKET)
        result = cluster.query(f"SELECT * FROM `{COUCHBASE_BUCKET}` LIMIT 10;")

        return {"status": "ok", "orders": [row for row in result]}

    except Exception as e:
        return {"error": str(e)}
