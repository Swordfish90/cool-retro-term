import sys

__, inpath, outpath = sys.argv

def interpolate(color, minim):
    return minim + (color / 255) * (255 - minim)

def rgb2grey(r, g, b):
    return round(0.21 * r + 0.72 * g + 0.07 * b)

infile = open(inpath, "r")
outfile = open(outpath, "w")

lines = infile.readlines()

def process_line(line):
    if not line.startswith("color"): return line
    chunks = [l for l in line.split(" ") if l]
    color = rgb2grey(int(chunks[2]), int(chunks[3]), int(chunks[4]))
    if color != 0:
        color = int(interpolate(color, 5))
    chunks[2] = str(color)
    chunks[3] = str(color)
    chunks[4] = str(color)
    return ' '.join(chunks)

for l in (process_line(l) for l in lines):
    outfile.write(l + '\n')

infile.close()
outfile.close()
