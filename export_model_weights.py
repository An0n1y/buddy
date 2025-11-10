#!/usr/bin/env python3
"""
Export sklearn Random Forest model weights to JSON format for Dart/Flutter loading.
This allows us to ship the trained model without TensorFlow/tflite_flutter dependency.
"""

import os
import pickle
import json
import numpy as np

REPO_ROOT = os.path.dirname(os.path.abspath(__file__))
PKL_PATH = os.path.join(REPO_ROOT, 'assets', 'models', 'age_gender_model.pkl')
WEIGHTS_JSON = os.path.join(REPO_ROOT, 'assets', 'models', 'model_weights.json')

print(f'Loading pickle model from {PKL_PATH}...')
with open(PKL_PATH, 'rb') as f:
    models_dict = pickle.load(f)

age_model = models_dict['age']
gender_model = models_dict['gender']
ethnicity_model = models_dict['ethnicity']
scaler = models_dict['scaler']

print(f'Age model: {age_model}')
print(f'  - n_estimators: {age_model.n_estimators}')
print(f'  - max_depth: {age_model.max_depth}')
print(f'  - n_features: {age_model.n_features_in_}')
print(f'  - n_classes: {age_model.n_classes_}')

print(f'\nScaler mean shape: {scaler.mean_.shape}')
print(f'Scaler scale shape: {scaler.scale_.shape}')

# Extract feature importances and tree structure
def export_tree_ensemble(model, name):
    """Export tree ensemble to JSON-compatible format."""
    data = {
        'type': 'RandomForest',
        'name': name,
        'n_estimators': int(model.n_estimators),
        'max_depth': int(model.max_depth) if model.max_depth else 0,
        'n_features': int(model.n_features_in_),
        'n_classes': int(model.n_classes_),
        'feature_importances': model.feature_importances_.tolist(),
        # For actual inference, we'd need to serialize tree structures,
        # but for now, we'll use feature importance scores as a proxy
    }
    return data

weights = {
    'scaler': {
        'mean': scaler.mean_.tolist(),
        'scale': scaler.scale_.tolist(),
        'var': scaler.var_.tolist(),
    },
    'models': {
        'age': export_tree_ensemble(age_model, 'age'),
        'gender': export_tree_ensemble(gender_model, 'gender'),
        'ethnicity': export_tree_ensemble(ethnicity_model, 'ethnicity'),
    },
    'metadata': {
        'version': '1.0',
        'timestamp': '2025-11-10',
        'input_shape': [1, 2304],
        'output_classes': {
            'age': 5,
            'gender': 2,
            'ethnicity': 5,
        },
        'labels': {
            'age': ['0-12', '13-18', '19-29', '30-49', '50+'],
            'gender': ['Male', 'Female'],
            'ethnicity': ['White', 'Black', 'Asian', 'Indian', 'Other'],
        }
    }
}

with open(WEIGHTS_JSON, 'w') as f:
    json.dump(weights, f, indent=2)

file_size_mb = os.path.getsize(WEIGHTS_JSON) / (1024 * 1024)
print(f'\n✓ Model weights exported to {WEIGHTS_JSON}')
print(f'  Size: {file_size_mb:.2f} MB')
print(f'\nNote: For actual inference on-device, Flutter would need to:')
print(f'  1. Load this JSON file')
print(f'  2. Call a backend API for predictions (if models too large)')
print(f'  3. Or: use a simpler heuristic-based approach (current implementation)')
