FROM python:3-slim

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# Install pip requirements
COPY requirements.txt .
RUN  pip install -r requirements.txt


WORKDIR /app
COPY application.py /app

RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser


ENTRYPOINT ["python3", "application.py"]