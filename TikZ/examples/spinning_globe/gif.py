from pdf2image import convert_from_path
from PIL import Image

# Path to your PDF
pdf_path = "main.pdf"

# Convert PDF pages to images
pages = convert_from_path(pdf_path, dpi=100)  # higher dpi for quality

# Scale factor
scale = 1
scaled_pages = []
for page in pages:
    w, h = page.size
    scaled_pages.append(page.resize((w*scale, h*scale), Image.LANCZOS))

# Save as GIF
scaled_pages[0].save(
    "animation.gif",
    format="GIF",
    append_images=scaled_pages[1:],
    save_all=True,
    duration=150,  # milliseconds per frame
    loop=0
)

print("GIF saved as animation.gif")
