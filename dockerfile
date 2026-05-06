# ============================
# 1. Base Image (Stable)
# ============================
FROM python:3.12-slim

# ----------------------------
# 2. System-level dependencies
# ----------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    libglib2.0-0 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------
# 3. Working directory
# ----------------------------
WORKDIR /app

# ----------------------------
# 4. Python env settings
# ----------------------------
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# ----------------------------
# 5. Install dependencies FIRST
# (cached layer — improves build speed)
# ----------------------------
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ----------------------------
# 6. Copy project files
# ----------------------------
COPY . .

# ----------------------------
# 7. Build Knowledge Base (FAISS)
# If this file is missing, the build won't fail.
# ----------------------------
RUN python base.py || echo "FAISS build skipped during container build"

# ----------------------------
# 8. Expose the Render port (will be overridden by $PORT)
# ----------------------------
EXPOSE 10000

# ----------------------------
# 9. Start FastAPI using Gunicorn + UvicornWorker
# Render automatically injects $PORT
# ----------------------------
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "GENTAX-AI.gentaxai.main:app", "--bind", "0.0.0.0:${PORT}"]
