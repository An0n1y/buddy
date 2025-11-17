import tensorflow as tf
import tf2onnx
import onnx

tflite_path = "../assets/models/age_gender_ethnicity.tflite"
onnx_path = "../assets/models/age_gender_ethnicity.onnx"

interpreter = tf.lite.Interpreter(model_path=tflite_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input shape:", input_details[0]['shape'])
print("Output details:", [(o['name'], o['shape']) for o in output_details])

concrete_func = tf2onnx.convert.from_tflite(
    tflite_path,
    output_path=onnx_path,
    opset=13
)

print(f"✓ Converted {tflite_path} -> {onnx_path}")
