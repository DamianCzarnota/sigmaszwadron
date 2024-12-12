import httpx
from typing import Any, Dict, Optional, List
from datetime import datetime, timedelta
import random

import firebase_admin
from firebase_admin import credentials
from firebase_admin import storage

from firebase_admin import credentials

class FirebaseUploader:

    def __init__(self, bucket_name):
        cred = credentials.Certificate("sigmaszwadron-firebase-adminsdk-zswuv-68daf9ec00.json")
        firebase_admin.initialize_app(cred, {
            'storageBucket': bucket_name
        })
        self.bucket = storage.bucket()

    def upload_image(self, image_content, image_name):

        blob = self.bucket.blob(image_name)
        blob.upload_from_string(image_content, content_type="image/jpeg")
        public_url = blob.public_url
        print(f"Image uploaded successfully! Public URL: {public_url}")

class RestClient:

    def __init__(self, base_url: str):
        self.base_url = base_url

    async def get(self, endpoint: str, params: Optional[Dict[str, Any]] = None) -> Dict:


        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}{endpoint}", params=params)
            response.raise_for_status()
            return response.json()

class ApiService:

    def __init__(self, client: RestClient):
        self.client = client

    async def fetch_data(self, endpoint: str, query_params: Dict[str, Any]) -> List[Dict]:

        json_response = await self.client.get(endpoint, params=query_params)
        return self.parse_json(json_response)

    def parse_json(self, json_data: Dict) -> List[Dict]:

        # Custom parsing logic can be added here
        if isinstance(json_data, list):
            return json_data
        elif isinstance(json_data, dict):
            return [json_data]
        else:
            raise ValueError("Unexpected JSON structure")
        
  
class ImageDownloader:

    def __init__(self, uploader):
        self.uploader = uploader

    def download_image(self, image_url, image_title):

        try:
            print(f"Downloading: {image_title} from {image_url}")

            with httpx.stream("GET", image_url) as response:
                response.raise_for_status()
                image_content = b"".join(response.iter_bytes())

            self.uploader.upload_image(image_content, f"{image_title}.jpg")

            
        except httpx.RequestError as e:
            print(f"Failed to download {image_title} from {image_url}: {e}")

def get_random_date(start_year=2016, end_year=2024):
    
    start_date = datetime(start_year, 1, 1)
    end_date = datetime(end_year, 12, 31)
    random_days = random.randint(0, (end_date - start_date).days)
    random_date = start_date + timedelta(days=random_days)
    return random_date.strftime("%Y-%m-%d")
    
    

# Example Usage
async def main():
    base_url = "https://api.nasa.gov"
    rest_client = RestClient(base_url)
    api_service = ApiService(rest_client)
    uploader = FirebaseUploader('gs://sigmaszwadron.firebasestorage.app')
    downloader_service = ImageDownloader(uploader)

    # Define the API endpoint and query parameters
    endpoint = "/planetary/apod"
    random_date = get_random_date()
    query_params = {"api_key": "", "start_date": random_date, "end_date": random_date}

    # Fetch and process data
    try:
        data = await api_service.fetch_data(endpoint, query_params)
        for i, item in enumerate(data):
            print(item["url"])
            print()
            downloader_service.download_image(item["url"],item["title"])
    except httpx.HTTPStatusError as e:
        print(f"HTTP error occurred: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

# To run the async main function
if __name__ == "__main__":
    import asyncio
    asyncio.run(main())