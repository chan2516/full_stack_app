from __future__ import annotations

import json
import os
from pathlib import Path

import certifi
from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover
    load_dotenv = None


BASE_DIR = Path(__file__).resolve().parent
DATA_FILE = BASE_DIR / "data.json"
ENV_FILE = BASE_DIR / ".env"

if load_dotenv is not None:
    load_dotenv(ENV_FILE)


def get_mongo_collection():
    """Create a MongoDB collection using environment settings."""
    mongo_uri = os.getenv("MONGODB_URI")
    database_name = os.getenv("MONGODB_DATABASE", "first_project")
    collection_name = os.getenv("MONGODB_COLLECTION", "submissions")

    if not mongo_uri:
        raise RuntimeError(
            "MONGODB_URI is not set. Add your MongoDB connection string to the environment."
        )

    client = MongoClient(
        mongo_uri,
        tlsCAFile=certifi.where(),
        serverSelectionTimeoutMS=10_000,
        connectTimeoutMS=10_000,
    )
    database = client[database_name]
    return database[collection_name]


def load_data() -> list[dict]:
    """Load a JSON list from the backend file."""
    try:
        with DATA_FILE.open("r", encoding="utf-8") as file:
            data = json.load(file)
    except FileNotFoundError:
        return []

    if not isinstance(data, list):
        raise ValueError("data.json must contain a JSON list.")

    return data


def filter_data(records: list[dict], query: str) -> list[dict]:
    """Return records whose text fields match the search query."""
    normalized_query = query.strip().lower()
    if not normalized_query:
        return records

    filtered_records: list[dict] = []
    for record in records:
        values = (str(value).lower() for value in record.values())
        if any(normalized_query in value for value in values):
            filtered_records.append(record)

    return filtered_records


def build_submission_document(form_data: dict[str, str]) -> dict[str, str]:
    """Build a clean MongoDB document from submitted form values."""
    return {
        "name": form_data.get("name", "").strip(),
        "email": form_data.get("email", "").strip(),
        "message": form_data.get("message", "").strip(),
    }


def create_app() -> Flask:
    """Create and configure the Flask API application."""
    app = Flask(__name__)
    app.secret_key = os.getenv("FLASK_SECRET_KEY", "dev-secret-key")

    cors_origins = os.getenv("CORS_ORIGINS", "*")
    CORS(
        app,
        resources={
            r"/api/*": {"origins": cors_origins},
            r"/health": {"origins": cors_origins},
        },
    )

    @app.get("/health")
    def health() -> tuple:
        return jsonify({"status": "ok", "service": "backend"}), 200

    @app.get("/api/records")
    def records() -> tuple:
        search_query = request.args.get("q", "")
        try:
            filtered = filter_data(load_data(), search_query)
            return jsonify({"records": filtered, "search_query": search_query}), 200
        except Exception as error:  # noqa: BLE001
            return jsonify({"error": str(error)}), 500

    @app.post("/api/submit")
    def submit() -> tuple:
        payload = request.get_json(silent=True) or {}
        form_data = {
            "name": str(payload.get("name", "")).strip(),
            "email": str(payload.get("email", "")).strip(),
            "message": str(payload.get("message", "")).strip(),
        }

        try:
            if not form_data["name"] or not form_data["email"] or not form_data["message"]:
                raise ValueError("All fields are required.")

            collection = get_mongo_collection()
            result = collection.insert_one(build_submission_document(form_data))
            return (
                jsonify(
                    {
                        "success": True,
                        "message": "Data submitted successfully.",
                        "id": str(result.inserted_id),
                    }
                ),
                201,
            )
        except Exception as error:  # noqa: BLE001
            app.logger.exception("Submit failed")
            return jsonify({"success": False, "error": str(error)}), 400

    @app.get("/api/submissions")
    def submissions() -> tuple:
        try:
            collection = get_mongo_collection()
            docs = list(collection.find().sort("_id", -1).limit(50))
            for doc in docs:
                doc["_id"] = str(doc["_id"])
            return jsonify({"submissions": docs, "database": os.getenv("MONGODB_DATABASE", "first_project")}), 200
        except Exception as error:  # noqa: BLE001
            app.logger.exception("Failed to load submissions")
            return jsonify({"error": str(error)}), 500

    @app.get("/api")
    def api() -> tuple:
        return jsonify(load_data()), 200

    return app


app = create_app()


if __name__ == "__main__":
    port = int(os.getenv("FLASK_PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=os.getenv("FLASK_DEBUG", "false").lower() == "true")
