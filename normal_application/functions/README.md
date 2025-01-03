## Test Locally

Create virtual environemnt
```bash
python -m venv venv

Linux:  source venv/bin/activate
Windows PS: ./venv/Scripts/Activate.ps1
```

Install requirements.
```bash
pip install -r requirements.txt
```

Setup google authorization with service user key json
Linux
```bash
Linux: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"

Windows PS: $env:GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

Run functions locally
```bash
functions-framework --target=generate_preview --debug
```
Where target is a function from "main.py"
## Upload function to firebase

```bash
gcloud functions deploy generate_preview --runtime python310 --trigger-http [--allow-unauthenticated]
```

## Delete function from firebase
```bash
firebase functions:delete generate_preview
```