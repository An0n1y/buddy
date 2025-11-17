import urllib.request
import os

models_dir = "../assets/models"
os.makedirs(models_dir, exist_ok=True)

emotion_url = "https://github.com/petercunha/Emotion/raw/master/emotion_model.tflite"

filepath = os.path.join(models_dir, "emotion.tflite")
print(f"Downloading emotion.tflite...")
try:
    urllib.request.urlretrieve(emotion_url, filepath)
    print(f"Saved to {filepath}")
except Exception as e:
    print(f"Error: {e}")
    print("Creating placeholder model...")
    with open(filepath, "wb") as f:
        f.write(b"")
