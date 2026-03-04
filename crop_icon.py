from PIL import Image
import os

source_path = r"C:/Users/Onyx/.gemini/antigravity/brain/996ded9c-f68f-4502-a40b-4100bde88483/app_icon_sw_edge_1768893303410.png"
dest_path = r"d:/FlutterProject/sw_game_helper/assets/icon/icon_sw_final.png"
artifact_dest_path = r"C:/Users/Onyx/.gemini/antigravity/brain/996ded9c-f68f-4502-a40b-4100bde88483/app_icon_sw_final.png"

try:
    print(f"Loading image from {source_path}")
    img = Image.open(source_path)
    
    # Calculate bounding box of non-zero regions
    bbox = img.getbbox()
    
    if bbox:
        print(f"Original Size: {img.size}")
        print(f"Bounding Box: {bbox}")
        
        # Crop the image
        cropped_img = img.crop(bbox)
        print(f"Cropped Size: {cropped_img.size}")
        
        # Save to destination
        cropped_img.save(dest_path)
        cropped_img.save(artifact_dest_path)
        print(f"Saved cropped image to {dest_path}")
        print(f"Saved artifact copy to {artifact_dest_path}")
    else:
        print("Error: content is all transparent?")
        
except Exception as e:
    print(f"Error: {e}")
