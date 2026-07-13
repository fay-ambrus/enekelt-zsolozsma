from pypdf import PdfReader, PdfWriter
import sys, os

if len(sys.argv) > 1:
    files = sys.argv[1:]
else:
    files = ["out/sanctorale.pdf", "out/temporale.pdf", "out/appendix.pdf", "out/psalterium.pdf"]

for input_file in files:
    base, ext = os.path.splitext(input_file)
    output_file = base + "-scrambled" + ext

    reader = PdfReader(input_file)
    writer = PdfWriter()

    n = len(reader.pages)

    for i in range(0, n, 4):
        block = list(range(i, min(i + 4, n)))

        if len(block) == 4:
            order = [block[3], block[0], block[1], block[2]]
        else:
            order = block

        for page_num in order:
            writer.add_page(reader.pages[page_num])

    with open(output_file, "wb") as f:
        writer.write(f)

    print(f"Created: {output_file}")
