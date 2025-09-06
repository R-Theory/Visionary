"""
Visionary Celery Application Configuration
Main entry point for background task processing with Sentry integration
"""

import os
from celery import Celery
import sentry_sdk
from sentry_sdk.integrations.celery import CeleryIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

# Initialize Sentry for error tracking
def init_sentry():
    """Initialize Sentry SDK for error monitoring"""
    sentry_dsn = os.getenv('SENTRY_DSN')
    environment = os.getenv('ENVIRONMENT', 'development')

    if sentry_dsn:
        sentry_sdk.init(
            dsn=sentry_dsn,
            environment=environment,
            integrations=[
                CeleryIntegration(monitor_beat_tasks=True),
                SqlalchemyIntegration(),
            ],
            traces_sample_rate=0.1,
            profiles_sample_rate=0.1,
            # Set tag for service identification
            before_send=lambda event, hint: {
                **event,
                'tags': {**event.get('tags', {}), 'service': 'visionary-workers'}
            }
        )

# Initialize Sentry before creating Celery app
init_sentry()

# Create Celery application
app = Celery('visionary_workers')

# Configuration
app.conf.update(
    broker_url=os.getenv('CELERY_BROKER_URL', 'redis://redis:6379/0'),
    result_backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://redis:6379/0'),

    # Task routing
    task_routes={
        'workers.tts.tasks.*': {'queue': 'tts'},
        'workers.knowledge.tasks.*': {'queue': 'knowledge'},
        'workers.media.tasks.*': {'queue': 'media'},
        'workers.study.tasks.*': {'queue': 'study'},
    },

    # Task execution settings
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,

    # Task retry and timeout settings
    task_acks_late=True,
    worker_prefetch_multiplier=1,
    task_default_retry_delay=60,  # seconds
    task_max_retries=3,
    task_soft_time_limit=300,     # 5 minutes
    task_time_limit=600,          # 10 minutes

    # Task result settings
    result_expires=3600,          # 1 hour

    # Monitoring and logging
    worker_send_task_events=True,
    task_send_sent_event=True,

    # Security
    worker_hijack_root_logger=False,
    worker_log_color=False,
)

# Auto-discover tasks from worker modules
app.autodiscover_tasks([
    'workers.tts',
    'workers.knowledge',
    'workers.media',
    'workers.study',
    'workers.email',
])

# Health check task
@app.task(name='workers.health_check')
def health_check():
    """Simple health check task for monitoring"""
    return {'status': 'healthy', 'worker': 'visionary'}

# Celery beat schedule (for periodic tasks)
app.conf.beat_schedule = {
    # Clean up expired TTS cache entries every hour
    'cleanup-tts-cache': {
        'task': 'workers.tts.tasks.cleanup_expired_cache',
        'schedule': 3600.0,  # Every hour
    },

    # System health monitoring every 5 minutes
    'system-health-check': {
        'task': 'workers.health_check',
        'schedule': 300.0,   # Every 5 minutes
    },

    # Update knowledge base statistics daily
    'update-knowledge-stats': {
        'task': 'workers.knowledge.tasks.update_statistics',
        'schedule': 86400.0,  # Daily
    },
}

# Error handling
@app.task(bind=True)
def error_handler(self, uuid):
    """Handle task errors and send to Sentry"""
    result = self.retry_policy_error_handler(uuid)
    if result:
        # Log additional context to Sentry
        sentry_sdk.capture_message(
            f"Task {uuid} failed after all retries",
            level="error",
            extra={
                "task_id": uuid,
                "retries": self.request.retries,
            }
        )
    return result

if __name__ == '__main__':
    app.start()
