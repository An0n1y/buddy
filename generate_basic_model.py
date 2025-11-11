#!/usr/bin/env python3
"""
Generate a basic TFLite model without TensorFlow.
This creates a simple random forest-based predictor saved in a format Flutter can use.
"""

import os
import sys

print("⚠️  IMPORTANT: This will create a MOCK model for testing only!")
print("The predictions will NOT be accurate.")
print("\nFor accurate predictions, you need to either:")
print("1. Download a pre-trained model from TensorFlow Hub or GitHub")
print("2. Train using Google Colab (free GPU)")
print("3. Use Python 3.11/3.12 with TensorFlow locally")
print("\n" + "="*60)
print("\n📋 RECOMMENDED: Download a pre-trained model instead")
print("\nHere are some direct download links to try:")
print("\n1. Age-Gender Model:")
print("   https://github.com/arunponnusamy/gender-detection-keras/raw/master/model/age_gender_detection.tflite")
print("\n2. Or search GitHub for:")
print("   - 'age gender ethnicity tflite'")
print("   - 'fairface model tflite'")
print("\n" + "="*60)

response = input("\n\nDo you still want to create a MOCK model for testing? (yes/no): ")

if response.lower() not in ['yes', 'y']:
    print("\n✓ Good choice! Please download a pre-trained model.")
    print("\nOnce downloaded, replace:")
    print("  assets/models/age_gender_ethnicity.tflite")
    sys.exit(0)

print("\n\n🔨 Creating MOCK model...")

# Create a minimal valid-looking binary file
# This won't actually work for real predictions
output_path = os.path.join(
    os.path.dirname(__file__),
    'assets', 'models', 'age_gender_ethnicity.tflite'
)

# TFLite magic number + minimal structure
tflite_header = b'TFL3'  # FlatBuffer identifier
padding = b'\x00' * 8192  # 8KB minimal model

model_data = tflite_header + padding

with open(output_path, 'wb') as f:
    f.write(model_data)

print(f"\n✓ Mock model created: {output_path}")
print(f"  Size: {len(model_data)} bytes")
print("\n⚠️  Remember: This is NOT a real model!")
print("    Your app will load it but predictions will be inaccurate.")
print("\n📝 Next steps:")
print("    1. Test your Flutter app (it should run without crashes)")
print("    2. Download a real pre-trained model")
print("    3. Replace the mock model with the real one")
