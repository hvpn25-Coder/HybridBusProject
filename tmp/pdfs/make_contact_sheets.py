import sys
from pathlib import Path
from PIL import Image, ImageDraw

source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
pages = sorted(source.glob("page-*.png"))
for sheet_index in range(0, len(pages), 6):
    selected = pages[sheet_index:sheet_index + 6]
    canvas = Image.new("RGB", (1560, 1480), "#d7dce0")
    draw = ImageDraw.Draw(canvas)
    for slot, page_path in enumerate(selected):
        page = Image.open(page_path).convert("RGB")
        page.thumbnail((500, 707))
        x = 10 + (slot % 3) * 520
        y = 35 + (slot // 3) * 730
        canvas.paste(page, (x, y))
        draw.text((x, 10 + (slot // 3) * 730), f"Page {sheet_index + slot + 1}", fill="#111111")
    canvas.save(source / f"contact-{sheet_index // 6 + 1:02d}.png")
