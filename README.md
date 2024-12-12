# sigmaszwadron
Project for cloudpgm and mobiapps

# Run batch job locally

```
export NASA_API_KEY=<nasa-api-key>
export BUCKET_NAME=<bucket-name-without-gs://-prefix>
export GCP_JSON_PATH=<json-file-with-firebase-credentials> 
export REALTIMEDB_NAME=<realtimedatabase-address> 
python3 ./application.py 
```

# Build container image with batch job
```
gcloud auth configure-docker us-central1-docker.pkg.dev
docker build . -t us-central1-docker.pkg.dev/sigmaszwadron/batch/app:1.0.0

```
