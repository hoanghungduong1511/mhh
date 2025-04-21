import json
import mysql.connector
from datetime import datetime

# --- Kết nối MySQL ---
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Localhost12345!",  # 👉 thay bằng mật khẩu MySQL thật
    database="webgis"
)
cursor = conn.cursor()

# --- Thông tin file ---
geojson_file = "bank.geojson"
layer_id = 2  # 👉 ID của layer 'bank' trong bảng maplayer

# --- Load dữ liệu GeoJSON ---
with open(geojson_file, "r", encoding="utf-8") as f:
    geojson = json.load(f)

features = geojson.get("features", [])
layer_name = geojson.get("name", "unknown_layer")
now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# --- Duyệt và chèn từng feature ---
for i, feature in enumerate(features):
    properties = feature.get("properties", {})
    geometry = feature.get("geometry", {})
    name = f"{layer_name}_{i+1}"

    cursor.execute("""
        INSERT INTO feature (id, name, properties, geometry, layerId, createdAt, updatedAt)
        VALUES (UUID(), %s, %s, %s, %s, %s, %s)
    """, (
        name,
        json.dumps(properties),
        json.dumps(geometry),
        layer_id,
        now,
        now
    ))

# --- Hoàn tất ---
conn.commit()
cursor.close()
conn.close()

print(f"✅ Đã chèn {len(features)} feature vào layer ID = {layer_id}")
