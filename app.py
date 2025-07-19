from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import StreamingResponse
import numpy as np
import cv2
from io import BytesIO
from basicsr.archs.rrdbnet_arch import RRDBNet
from realesrgan import RealESRGANer
import os
import requests

app = FastAPI(title="Image Upscaler API")

# Initialize model and upsampler once
model = RRDBNet(
    num_in_ch=3,     # input RGB channels
    num_out_ch=3,    # output RGB channels
    num_feat=64,     # number of feature maps
    num_block=6,    # number of RRDB blocks
    num_grow_ch=32,  # growth channels per RDB
    scale=2        # 4× upscaling
)
model.eval()

modelpath = './models/RealESRGAN_x4plus_anime_6B.pth'
if not os.path.exists(modelpath):
    print("Downloading model please wait")
#     url = 'https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus_anime_6B.pth'
#     response = requests.get(url)
#     with open(model, 'wb') as f:
#         f.write(response.content)
#     print("Model downloaded successfully!")





upsampler = RealESRGANer(
    scale=2,
    model_path=modelpath,
    model=model,
    tile=0,
    tile_pad=10,
    pre_pad=0,
    half=False,
    gpu_id=None
)

@app.post("/upscale")
async def upscale_image(file: UploadFile = File(...),outscale: int = Form(1)):
    """
    Upscale an uploaded image by the given outscale factor.

    - **file**: image file to upscale (JPEG, PNG, etc.)
    - **outscale**: scaling factor for upscaling (integer)
    """
    # Read bytes and convert to OpenCV image
    try:
        contents = await file.read()
        np_arr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("Invalid image file")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error reading image: {e}")

    # Perform upscaling
    try:
        output, _ = upsampler.enhance(img, outscale=outscale)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upscaling failed: {e}")

    # Encode output image to JPEG
    success, encoded_img = cv2.imencode('.jpg', output)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to encode output image")

    # Return image
    img_bytes = encoded_img.tobytes()
    return StreamingResponse(BytesIO(img_bytes), media_type="image/jpeg")

# Optionally include a simple root endpoint
@app.get("/")
async def root():
    return {"message": "Welcome to the Image Upscaler API. POST an image to /upscale."}
