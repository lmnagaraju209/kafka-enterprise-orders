from fastapi import FastAPI
import os
import psycopg2
import json
from couchbase.cluster import Cluster, ClusterOptions
from couchbase.auth import PasswordAuthenticator
from couchbase.options import ClusterTimeoutOptions

app = FastAPI()

COUCHBASE_HOST = os.getenv("COUCHBASE_HOST")
COUCHBASE_BUCKET = os.getenv("COUCHBASE_BUCKET")
COUCHBASE_USER = os.getenv("COUCHBASE_USERNAME")
COUCHBASE_PASS = os.getenv("COUCHBASE_PASSWORD")

@app.get("/api/analytics")
def get_analytics():
    try:
        cluster = Cluster(
            f"couchbase://{COUCHBASE_HOST}",
            ClusterOptions(
                PasswordAuthenticator(COUCHBASE_USER, COUCHBASE_PASS),
                timeout_options=ClusterTimeoutOptions(kv_timeout=5)
            )
        )
        bucket = cluster.bucket(COUCHBASE_BUCKET)
        collection = bucket.default_collection()

        # Query: get last 10 orders
        result = cluster.query(
            f"SELECT * FROM `{COUCHBASE_BUCKET}` LIMIT 10;"
        )

        orders = [row for row in result]
        return {"status":"ok", "orders":orders}

    except Exception as e:
        return {"error": str(e)}
