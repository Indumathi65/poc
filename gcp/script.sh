#!/usr/bin/env bash
set -euo pipefail

PROJECT="YOUR_GCP_PROJECT"          # replace
CLOUDSQL_INSTANCE="cloudsql-postgres-1"
REPL_USER="replicator"
REPL_PASS="CHANGE_ME_SourcePass!"

# 1) Patch Cloud SQL flags for logical replication
gcloud config set project "$PROJECT"

echo "Patching Cloud SQL instance to enable logical replication (will restart instance)..."

gcloud sql instances patch "$CLOUDSQL_INSTANCE" \
  --database-flags=wal_level=logical,max_replication_slots=10,max_wal_senders=10 \
  --quiet

# Wait until RUNNABLE
while true; do
  state=$(gcloud sql instances describe "$CLOUDSQL_INSTANCE" --format='value(state)')
  echo "Cloud SQL state: $state"
  if [[ "$state" == "RUNNABLE" ]]; then break; fi
  sleep 15
done

# 2) Create replication user
set +e
gcloud sql users create "$REPL_USER" --instance="$CLOUDSQL_INSTANCE" --password="$REPL_PASS"
set -e

echo "User created. Remember to grant privileges if needed via psql."

echo "Cloud SQL patching & user creation done."