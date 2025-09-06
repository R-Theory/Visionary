#!/usr/bin/env python3
"""
Visionary Application Entry Point

This is a temporary entry point for the containerized development environment.
Replace this with your actual OpenWebUI-based backend when ready.
"""

import os
import logging
from contextlib import asynccontextmanager
from typing import Dict, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    logger.info("🚀 Starting Visionary application...")
    logger.info("Environment: %s", os.getenv("ENVIRONMENT", "development"))
    yield
    logger.info("📉 Shutting down Visionary application...")


# Create FastAPI app
app = FastAPI(
    title="Visionary API",
    description="Knowledge Management and Media Processing Platform - Development Container",
    version="0.1.0-dev",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5173",  # Vite dev server
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "🚀 Welcome to Visionary API",
        "version": "0.1.0-dev",
        "status": "running",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "docs": "/docs"
    }


@app.get("/health")
async def health_check() -> Dict[str, Any]:
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "visionary-api",
        "version": "0.1.0-dev",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "timestamp": os.popen("date -Iseconds").read().strip()
    }


@app.get("/api/v1/info")
async def get_info():
    """Get application information."""
    return {
        "app": "Visionary",
        "description": "Knowledge Management and Media Processing Platform",
        "features": {
            "media_library": {
                "status": "planned",
                "description": "PDF/video/audio processing with TTS"
            },
            "knowledge_manager": {
                "status": "planned",
                "description": "Content ingestion and retrieval with embeddings"
            },
            "study_page": {
                "status": "planned",
                "description": "Flashcards, AI podcasts, analytics"
            },
            "email_manager": {
                "status": "planned",
                "description": "AI classification and smart folders"
            }
        },
        "architecture": {
            "database": "MongoDB",
            "cache": "Redis",
            "storage": "MinIO",
            "framework": "FastAPI",
            "containerized": True
        }
    }


@app.get("/api/v1/services")
async def get_services():
    """Check service connectivity."""
    services = {}

    # Check MongoDB (will add actual connectivity later)
    try:
        # TODO: Add actual MongoDB connection check
        services["mongodb"] = {
            "status": "available",
            "url": os.getenv("DATABASE_URL", "mongodb://mongo:27017/visionary")
        }
    except Exception as e:
        services["mongodb"] = {"status": "unavailable", "error": str(e)}

    # Check Redis (will add actual connectivity later)
    try:
        # TODO: Add actual Redis connection check
        services["redis"] = {
            "status": "available",
            "url": os.getenv("REDIS_URL", "redis://redis:6379")
        }
    except Exception as e:
        services["redis"] = {"status": "unavailable", "error": str(e)}

    # Check MinIO (will add actual connectivity later)
    try:
        # TODO: Add actual MinIO connection check
        services["minio"] = {
            "status": "available",
            "endpoint": os.getenv("MINIO_ENDPOINT", "minio:9000")
        }
    except Exception as e:
        services["minio"] = {"status": "unavailable", "error": str(e)}

    return {"services": services}


@app.exception_handler(404)
async def not_found_handler(request, exc):
    """Custom 404 handler."""
    return JSONResponse(
        status_code=404,
        content={
            "error": "Not Found",
            "message": "The requested endpoint was not found",
            "docs": "/docs"
        }
    )


if __name__ == "__main__":
    import uvicorn

    # Get configuration from environment
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8080"))
    debug = os.getenv("DEBUG", "false").lower() == "true"
    reload = os.getenv("HOT_RELOAD", "false").lower() == "true"

    logger.info("Starting Visionary server on %s:%d", host, port)

    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=reload,
        log_level="debug" if debug else "info"
    )
