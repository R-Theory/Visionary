"""
Simplified Celery Application Configuration for Testing
"""

import os
from celery import Celery

# Create Celery application
app = Celery('visionary_workers')

# Basic configuration
app.conf.update(
    broker_url=os.getenv('CELERY_BROKER_URL', 'redis://redis:6379/0'),
    result_backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://redis:6379/0'),
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
)

# Simple test task
@app.task(name='workers.health_check')
def health_check():
    """Simple health check task for monitoring"""
    return {'status': 'healthy', 'worker': 'visionary'}

if __name__ == '__main__':
    app.start()
