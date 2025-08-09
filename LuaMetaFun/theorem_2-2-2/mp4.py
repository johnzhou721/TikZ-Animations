import os
import time
import shutil
import cv2
from PyPDF2 import PdfReader
from pdf2image import convert_from_path
import numpy as np

# --- Settings ---
pdf_path = 'main.pdf'
output_video = 'output.mp4'
fps = 30
batch_size = 30
dpi = 100
font = cv2.FONT_HERSHEY_SIMPLEX
font_scale = 1
font_color = (255, 255, 255)
font_thickness = 2
position_offset = (50, 50)  # x, y offset for page number text

start_time = time.time()
print("🚀 Starting PDF to video conversion...")

# Step 1: Load PDF and count pages
reader = PdfReader(pdf_path)
total_pages = len(reader.pages)
print(f"📄 Total pages found: {total_pages}")

# Step 2: Get frame dimensions from first page
sample = convert_from_path(pdf_path, dpi=dpi, first_page=1, last_page=1)[0]
width, height = sample.size
print(f"🖼️ Frame size: {width}x{height}")

# Step 3: Setup VideoWriter with reliable codec
fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # Try 'XVID' or 'avc1' if issues persist
video = cv2.VideoWriter(output_video, fourcc, fps, (width, height))

if not video.isOpened():
    raise RuntimeError("❌ VideoWriter failed to initialize!")

# Step 4: Process pages in batches
for start in range(1, total_pages + 1, batch_size):
    end = min(start + batch_size - 1, total_pages)
    print(f"\n📦 Processing pages {start}-{end}...")

    try:
        images = convert_from_path(pdf_path, dpi=dpi, first_page=start, last_page=end, fmt='jpeg')
    except Exception as e:
        print(f"⚠️ Error rendering pages {start}-{end}: {e}")
        continue

    temp_folder = f"batch_{start}_{end}"
    os.makedirs(temp_folder, exist_ok=True)

    for i, img in enumerate(images):
        page_num = start + i
        img_path = os.path.join(temp_folder, f"page_{page_num}.jpg")
        img.save(img_path, 'JPEG')

        frame = cv2.imread(os.path.abspath(img_path))
        if frame is None:
            print(f"⚠️ Skipping page {page_num}: frame is unreadable")
            continue

        # Resize for consistency
        frame = cv2.resize(frame, (width, height))

        # Add page number overlay
        text = f"Page {page_num}/{total_pages}"
        cv2.putText(frame, text, position_offset, font, font_scale, font_color, font_thickness)

        video.write(frame)

    shutil.rmtree(temp_folder)
    print(f"🧹 Removed temp folder '{temp_folder}'")

# Step 5: Finalize video
video.release()
duration = time.time() - start_time
print(f"\n✅ Completed! Saved '{output_video}' in {duration:.2f} seconds.")
