# functions/generate_preview.py

import io
from google.cloud import storage
from PIL import Image
import functions_framework
from enum import Enum

DEFAULT_IMAGE_SCALING_VALUE = 400

class image_size(Enum):
    USE_X_Y = 1
    USE_SIZE = 2

def string_to_int(value):
    try:
        num = float(value)
        return int(num)
    except ValueError:
        return DEFAULT_IMAGE_SCALING_VALUE

@functions_framework.http
def generate_preview(request):
    try:
        file_name = request.args.get("fileName")
        if not file_name:
            return ("Brak parametru 'fileName' w zapytaniu.", 400)
        
        size = request.args.get("size")
        size_x = request.args.get("sizex")
        size_y = request.args.get("sizey")

        thumbnail_choice = image_size.USE_SIZE
        if size_x is not None and size_y is None:
            size = string_to_int(size_x)
            if size < 0:
                size = DEFAULT_IMAGE_SCALING_VALUE
            thumbnail_choice = image_size.USE_SIZE
        elif size_y is not None and size_x is None:
            size = string_to_int(size_y)
            if size < 0:
                size = DEFAULT_IMAGE_SCALING_VALUE
            thumbnail_choice = image_size.USE_SIZE
        elif size_y is not None and size_y is not None:
            size_x = string_to_int(size_x)
            size_y = string_to_int(size_y)
            if size_y < 0 or size_x < 0:
                size = DEFAULT_IMAGE_SCALING_VALUE
                thumbnail_choice =image_size.USE_SIZE
            else:
                thumbnail_choice =image_size.USE_X_Y
        else:
            if size is None:
                size = DEFAULT_IMAGE_SCALING_VALUE
            else:
                size = string_to_int(size)
                if size < 0:
                    size = DEFAULT_IMAGE_SCALING_VALUE
            thumbnail_choice = image_size.USE_SIZE

        bucket_name = "sigmaszwadron.firebasestorage.app"  

        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)

        if not blob.exists():
            return (f"Nie znaleziono pliku: {file_name}", 404)

        image_data = blob.download_as_bytes()

        img = Image.open(io.BytesIO(image_data))
        
        if thumbnail_choice == image_size.USE_SIZE:
            img.thumbnail((size, size),     Image.Resampling.LANCZOS)
        else:
            img.thumbnail((size_x, size_y), Image.Resampling.LANCZOS)            
    
        output_buffer = io.BytesIO()
        img.save(output_buffer, format="JPEG")
        output_buffer.seek(0)

        headers = {
            "Content-Type": "image/jpeg",
            "Cache-Control": "public, max-age=31536000",  # Cache for 1 year
        }

        return (output_buffer.getvalue(), 200, headers)

    except Exception as e:
        print(f"Błąd serwera: {e}")
        return (f"Błąd serwera: {e}", 500)