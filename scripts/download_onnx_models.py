import urllib.request
import os

models_dir = "../assets/models"
os.makedirs(models_dir, exist_ok=True)

urls = {
    "face_detection.onnx": "https://github.com/onnx/models/raw/main/validated/vision/body_analysis/ultraface/models/version-RFB-640.onnx",
    "emotion.onnx": "https://github.com/onnx/models/raw/main/validated/vision/body_analysis/emotion_ferplus/model/emotion-ferplus-8.onnx",
}

for filename, url in urls.items():
    filepath = os.path.join(models_dir, filename)
    print(f"Downloading {filename}...")
    urllib.request.urlretrieve(url, filepath)
    print(f"✓ Saved to {filepath}")

print("\n✓ All models downloaded successfully!")
print("\nNote: You still need to convert age_gender_ethnicity.tflite manually")
print("Run: python -m tf2onnx.convert --tflite age_gender_ethnicity.tflite --output age_gender_ethnicity.onnx")
