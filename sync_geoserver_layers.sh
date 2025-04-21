#!/bin/bash

# --- CONFIG ---
GEOSERVER_URL="http://localhost:8080/geoserver/rest"
GEOSERVER_USER="admin"
GEOSERVER_PASS="geoserver"
WORKSPACE="MapDaNang"

MYSQL_USER="root"
MYSQL_PASS="Localhost12345!"
MYSQL_DB="webgis"

# --- GET LAYERS ---
echo "Fetching layers from GeoServer..."
layers=$(curl -s -u $GEOSERVER_USER:$GEOSERVER_PASS \
  -H "Accept: application/json" \
  "$GEOSERVER_URL/workspaces/$WORKSPACE/layers.json" | ./jq.exe -r '.layers.layer[].name')

# --- PROCESS LAYERS ---
for layer in $layers; do
  echo "Syncing layer: $layer"

  # Set default values
  name="$layer"
  description="Layer from $WORKSPACE"
  url="${WORKSPACE}:${layer}"
  locationId=1
  type="VECTOR_IMAGE_LAYER"
  now=$(date +"%Y-%m-%d %H:%M:%S")
  userId=1

  # --- INSERT INTO MYSQL ---
  mysql -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_DB <<EOF
INSERT INTO maplayer (name, description, url, locationId, type, createdAt, updatedAt, createdById, updatedById)
VALUES ('$name', '$description', '$url', $locationId, '$type', '$now', '$now', $userId, $userId)
ON DUPLICATE KEY UPDATE
  updatedAt = '$now',
  updatedById = $userId;
EOF

done

echo "✅ Sync complete."
