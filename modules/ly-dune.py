#!/usr/bin/env python3
"""Draws the Dune login animation for ly: an Arrakis dusk with the DUNE logo,
twinkling stars, a shooting star and sand blowing off the dune crests.

Writes `dune.dur` (durdraw format 7, the only one ly reads) and `palette`, the
16 colors of the Linux console that the animation is drawn with. The console
turns any true color into one of its 16 palette slots (drivers/tty/vt/vt.c:
foreground by the hue of the channels above half the brightest one, bright
when that one is above 0xaa; background by the top bit of each channel, never
bright), so ly's start_cmd loads this palette and every cell names its slots
through 256-color indexes that land exactly on them.

Cells are 1:2, so the scene is drawn in square pixels, two per cell, and each
cell gets the glyph, foreground and background that look most like its pair:
half blocks, shades and spaces, with the coverage of each glyph's halves taken
from the console font itself.
"""
import argparse
import gzip
import json
import math
import struct

import numpy as np

# Console slots in ANSI order; ly draws its own text in 15 (white), its errors
# in 9 (red) and its background in 0, so those stay readable on the scene
PALETTE = [
    "08070f",  # 0 night sky, ly's background
    "181029",  # 1 upper sky
    "2f1838",  # 2 middle sky
    "5e2436",  # 3 low sky
    "9a4430",  # 4 horizon glow
    "21131a",  # 5 far dunes
    "4a2620",  # 6 dune shadow
    "8a4e2e",  # 7 dune body
    "615775",  # 8 dim stars (foreground only)
    "d0663a",  # 9 afterglow, ly's errors
    "b97a48",  # 10 lit sand
    "e2aa6c",  # 11 crest highlight
    "3a1d27",  # 12 dark dune tone
    "d8ccb8",  # 13 shooting star's tail
    "f0c98c",  # 14 blowing sand
    "f2e8d4",  # 15 the logo, ly's text
]

FRAMES = 48
FRAMERATE = 8.0

# ly's login box: 7 lines plus margin_box_v on both sides, centered
BOX_HEIGHT = 9
# ly's big clock: CHAR_HEIGHT lines, 2 more above the box
BIGCLOCK_HEIGHT = 5
BIGCLOCK_GAP = 2

GLYPHS = [" ", "█", "▀", "▄", "░", "▒", "▓"]
OVERLAY_GLYPHS = ["·", "•", "."]
FOREGROUND_SLOTS = list(range(1, 16))
BACKGROUND_SLOTS = list(range(0, 8))
# Palette slots from dark to light within one family of colors: shades blend
# only neighbours of one ramp, mixing ramps gives muddy purples and blues
RAMPS = [[0, 1, 2, 3, 4, 9], [5, 12, 6, 7, 10, 11, 14], [8, 13, 15]]
# What a pixel of the scene shows, and the slots its cell may draw it with:
# the dark sky purples are close enough to the dune shadows to be picked
# for them, and dither the dunes lavender
SKY, DUNES, LIGHTS = 0, 1, 2
REGION_SLOTS = {
    SKY: set(RAMPS[0]),
    # The crest rims glow with the sky's reds
    DUNES: set(RAMPS[1]) | {3, 4},
    LIGHTS: set(RAMPS[2]),
}


def hex_rgb(hex_color):
    return np.array([int(hex_color[i:i + 2], 16) for i in (0, 2, 4)], float) / 255


def srgb_to_linear(srgb):
    return np.where(srgb <= 0.04045, srgb / 12.92, ((srgb + 0.055) / 1.055) ** 2.4)


def linear_to_oklab(linear):
    lms = linear @ np.array([
        [0.4122214708, 0.2119034982, 0.0883024619],
        [0.5363325363, 0.6806995451, 0.2817188376],
        [0.0514459929, 0.1073969566, 0.6299787005],
    ])
    lms = np.cbrt(lms)
    return lms @ np.array([
        [0.2104542553, 1.9779984951, 0.0259040371],
        [0.7936177850, -2.4285922050, 0.7827717662],
        [-0.0040720468, 0.4505937099, -0.8086757660],
    ])


PALETTE_LINEAR = np.array([srgb_to_linear(hex_rgb(color)) for color in PALETTE])


def linear_color(hex_color):
    return srgb_to_linear(hex_rgb(hex_color))


# ---------------------------------------------------------------- colors

def ly_rgb_of_256(color_index):
    """convert_256_to_rgb from ly's DurFile.zig."""
    if color_index < 16:
        raise ValueError(f"the 16 basic colors are not used: {color_index}")
    if color_index < 232:
        step, scaler = 0xF0 // 6, 0xFF - (0xF0 // 6) * 5
        cube = color_index - 16

        def channel(level):
            return level * step + scaler if level > 0 else 0
        return channel(cube // 36 % 6), channel(cube // 6 % 6), channel(cube % 6)
    gray = 0x08 + (0xEE - 0x08) // 23 * (color_index - 232)
    return gray, gray, gray


def console_foreground_slot(rgb):
    """rgb_foreground() of the Linux console, in ANSI slot order."""
    if rgb == (0, 0, 0):
        raise ValueError("black is ly's default color, not a foreground slot")
    brightest = max(rgb)
    hue = sum(bit for channel, bit in zip(rgb, (1, 2, 4)) if channel > brightest // 2)
    if hue == 7 and brightest <= 0x55:
        return 8
    return hue + (8 if brightest > 0xAA else 0)


def console_background_slot(rgb):
    """rgb_background() of the Linux console; black is the default background."""
    return sum(bit for channel, bit in zip(rgb, (1, 2, 4)) if channel & 0x80)


def cube_index(red, green, blue):
    return 16 + 36 * red + 6 * green + blue


def foreground_index(slot):
    if slot == 8:
        return 232
    level = 5 if slot > 8 else 2
    hue = slot & 7
    index = cube_index(level * (hue & 1), level * (hue >> 1 & 1), level * (hue >> 2 & 1))
    if console_foreground_slot(ly_rgb_of_256(index)) != slot:
        raise AssertionError(f"256-color {index} doesn't land on foreground slot {slot}")
    return index


def background_index(slot):
    index = cube_index(2 * (slot & 1), 2 * (slot >> 1 & 1), 2 * (slot >> 2 & 1))
    if console_background_slot(ly_rgb_of_256(index)) != slot:
        raise AssertionError(f"256-color {index} doesn't land on background slot {slot}")
    return index


# ---------------------------------------------------------------- font

def glyph_coverage(font_path, glyphs):
    """Share of lit pixels in the top and bottom halves of each glyph of a PSF2 font."""
    data = gzip.open(font_path).read()
    magic, _, header_size, flags, count, glyph_size, height, width = struct.unpack("<8I", data[:32])
    if magic != 0x864AB572 or not flags & 1:
        raise ValueError(f"{font_path} is not a PSF2 font with a unicode table")
    row_bytes = (width + 7) // 8
    glyph_of = {}
    for number, entry in enumerate(data[header_size + count * glyph_size:].split(b"\xff")[:count]):
        for codepoint in entry.split(b"\xfe")[0].decode("utf-8"):
            glyph_of.setdefault(codepoint, number)

    coverage = []
    for glyph in glyphs:
        if glyph not in glyph_of:
            raise ValueError(f"{font_path} has no glyph for {glyph!r}")
        start = header_size + glyph_of[glyph] * glyph_size
        bits = np.unpackbits(np.frombuffer(data[start:start + glyph_size], np.uint8))
        pixels = bits.reshape(height, row_bytes * 8)[:, :width]
        coverage.append((pixels[:height // 2].mean(), pixels[height // 2:].mean()))
    return coverage


# ---------------------------------------------------------------- scene

def smoothstep(edge0, edge1, value):
    t = np.clip((value - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)


def polyline_distance(px, py, points):
    """Distance from every pixel to the nearest segment of a polyline."""
    distance = np.full(px.shape, np.inf)
    for (ax, ay), (bx, by) in zip(points[:-1], points[1:]):
        dx, dy = bx - ax, by - ay
        length2 = dx * dx + dy * dy
        t = np.clip(((px - ax) * dx + (py - ay) * dy) / length2, 0, 1) if length2 else 0
        distance = np.minimum(distance, np.hypot(px - ax - t * dx, py - ay - t * dy))
    return distance


def arc(cx, cy, rx, ry, start, end, steps=24):
    return [(cx + rx * math.cos(angle), cy + ry * math.sin(angle))
            for angle in np.linspace(start, end, steps)]


def logo_strokes(left, top, height):
    """The DUNE of the Villeneuve films: one horseshoe, a half ring with straight
    arms, turned four ways, open to the left for the D, up for the U, down for
    the N and to the right for the E, which also has a dot in its middle.
    Returns the strokes as polylines, the dots, the stroke width and the
    logo's width."""
    side, gap, stroke = height, 0.42 * height, 0.1 * height
    half = side / 2 - stroke / 2
    # Open upwards, around the origin
    horseshoe = [(-half, -half), (-half, 0.0)] + arc(0, 0, half, half, math.pi, 0) + [(half, -half)]
    # Turn that takes the opening from up to the letter's side
    turns = {"D": -math.pi / 2, "U": 0.0, "N": math.pi, "E": math.pi / 2}
    letters, dots = [], []
    for number, letter in enumerate("DUNE"):
        cx, cy = left + side / 2 + number * (side + gap), top + side / 2
        cos, sin = math.cos(turns[letter]), math.sin(turns[letter])
        letters.append([(cx + x * cos - y * sin, cy + x * sin + y * cos) for x, y in horseshoe])
        if letter == "E":
            dots.append((cx, cy, 0.8 * stroke))
    return letters, dots, stroke, 4 * side + 3 * gap


class Scene:
    def __init__(self, columns, lines, seed=1965):
        self.width, self.height = columns, lines * 2
        self.random = np.random.default_rng(seed)
        width, height = self.width, self.height
        self.center = width / 2

        box_top = (lines - BOX_HEIGHT) // 2
        clock_top = box_top - BIGCLOCK_HEIGHT - BIGCLOCK_GAP
        # The logo fills the sky between the key hints on the first line and
        # the clock, in pixels
        band_top, band_bottom = 2 * 2, (clock_top - 1) * 2
        self.logo_height = round((band_bottom - band_top) * 0.7)
        self.logo_top = (band_top + band_bottom - self.logo_height) / 2

        self.horizon = 0.68 * height

        self.dune_layers = [self._dune_layer(base, amplitude, frequency)
                            for base, amplitude, frequency in
                            ((0.69, 0.020, 2.5), (0.78, 0.035, 1.8), (0.89, 0.045, 1.3))]
        self.static = self._render_static(supersample=3)
        self.stars = self._place_stars()
        self.grains = self._place_grains()

    def _dune_layer(self, base, amplitude, frequency):
        """Crest height over x: rolling dunes with sharp ridges, in pixels."""
        phases = self.random.uniform(0, 2 * math.pi, 3)
        scale = frequency * 2 * math.pi / self.height

        def crest(x):
            ridge = 1 - np.abs(np.sin(x * scale / 2 + phases[0])) ** 0.7
            roll = 0.5 * np.sin(x * scale * 0.37 + phases[1]) + 0.3 * np.sin(x * scale * 1.7 + phases[2])
            return self.height * (base - amplitude * (ridge + roll))
        return crest

    def _render_static(self, supersample):
        width, height = self.width * supersample, self.height * supersample
        px, py = np.meshgrid((np.arange(width) + 0.5) / supersample,
                             (np.arange(height) + 0.5) / supersample)

        def downsample(image):
            return image.reshape(self.height, supersample, self.width, supersample, -1).mean(axis=(1, 3))

        image, ground = self._dunes(self._sky(px, py), px, py)
        image = downsample(image)
        dunes = downsample(ground[..., None])[..., 0] > 0.5
        # The logo is whole pixels: smoothed edges come out as stray orange
        # between its cream and the night sky
        logo = downsample(self._logo_cover(px, py)[..., None])[..., 0] > 0.45
        image[logo] = PALETTE_LINEAR[15]
        self.regions = np.where(logo, LIGHTS, np.where(dunes, DUNES, SKY))
        return image

    def _sky(self, px, py):
        stops = [(0.0, "08070f"), (0.35, "181029"), (0.6, "2f1838"),
                 (0.8, "5e2436"), (0.92, "9a4430"), (1.0, "d0663a")]
        # The sun has just set behind the dunes in the middle of the screen
        glow = np.exp(-((px - self.center) / (0.9 * self.height)) ** 2)
        position = np.clip(py / self.horizon, 0, 1.05) ** (1.15 - 0.25 * glow)
        offsets = [offset for offset, _ in stops]
        colors = np.array([linear_color(color) for _, color in stops])
        return np.stack([np.interp(position, offsets, colors[:, channel]) for channel in range(3)], axis=-1)

    def _logo_cover(self, px, py):
        left = self.center - logo_strokes(0, 0, self.logo_height)[3] / 2
        letters, dots, stroke, _ = logo_strokes(left, self.logo_top, self.logo_height)
        distance = np.full(px.shape, np.inf)
        for points in letters:
            distance = np.minimum(distance, polyline_distance(px, py, points) - stroke / 2)
        for x, y, radius in dots:
            distance = np.minimum(distance, np.hypot(px - x, py - y) - radius)
        return (distance <= 0).astype(float)

    def _dunes(self, image, px, py):
        """The dunes over the sky, and how much of each pixel they cover."""
        ground = np.zeros(px.shape)
        layers = [  # shadow, lit side, crest rim: palette slots
            (5, 12, 3),
            (12, 7, 4),
            (6, 10, 11),
        ]
        for nearness, (crest, (shadow, lit, rim)) in enumerate(zip(self.dune_layers, layers)):
            top = crest(px)
            depth = py - top
            # The lit face of each ridge runs down to the left of its crest:
            # sample the slope further along the ridge the deeper the pixel
            slope = np.gradient(crest(px + 0.6 * np.maximum(depth, 0)), axis=1)
            lit_share = smoothstep(-0.04, 0.1, -slope * (1 + nearness))
            shadow, lit, rim = PALETTE_LINEAR[shadow], PALETTE_LINEAR[lit], PALETTE_LINEAR[rim]
            color = shadow + (lit - shadow) * lit_share[..., None]
            if nearness == 2:
                # Wind ripples on the nearest dune
                ripples = np.sin(px * 0.8 + depth * 2.4 + 2 * np.sin(px * 0.07))
                color = color * (1 + 0.12 * ripples[..., None])
            rim_share = np.exp(-np.maximum(depth, 0) / 0.9)[..., None] * 0.8
            color = color + (rim - color) * rim_share
            cover = np.clip(depth + 0.5, 0, 1)
            ground = np.maximum(ground, cover)
            image = image + (color - image) * cover[..., None]
        return image, ground

    def _place_stars(self):
        stars = []
        sky_bottom = 0.6 * self.height
        count = int(self.width * sky_bottom * 0.014)
        logo_half_width = logo_strokes(0, 0, self.logo_height)[3] / 2 + 3
        for _ in range(count):
            x, y = self.random.uniform(0, self.width), self.random.uniform(0, sky_bottom)
            near_logo = (abs(x - self.center) < logo_half_width
                         and self.logo_top - 3 < y < self.logo_top + self.logo_height + 3)
            if near_logo:
                continue
            stars.append({
                "cell": (int(x), int(y) // 2),
                # Fewer bright stars low in the glow
                "brightness": self.random.uniform(0.25, 1) * (1 - 0.6 * y / sky_bottom),
                "twinkle": int(self.random.integers(1, 4)),
                "phase": self.random.uniform(0, 1),
            })
        return stars

    def _place_grains(self):
        """Grains of sand blown to the right off the highest crests, drawn as
        dots: a cell is too coarse for a grain painted in blocks."""
        grains = []
        xs = np.arange(self.width, dtype=float)
        for crest, count, length in ((self.dune_layers[1], 7, 0.13), (self.dune_layers[2], 8, 0.2)):
            tops = crest(xs)
            peaks = sorted((x for x in range(2, self.width - 2) if tops[x] <= tops[x - 2:x + 3].min()),
                           key=lambda x: tops[x])
            chosen = []
            for x in peaks:
                if all(abs(x - other) > self.width / (count + 1) for other in chosen):
                    chosen.append(x)
                if len(chosen) == count:
                    break
            for x in chosen:
                for _ in range(36):
                    grains.append({
                        "origin": (x + 0.5, tops[x] - 0.5),
                        "length": length * self.height * self.random.uniform(0.5, 1.1),
                        "rise": self.random.uniform(0.5, 3),
                        # Whole passes per loop, so the loop has no seam
                        "speed": int(self.random.integers(1, 4)),
                        "phase": self.random.uniform(0, 1),
                        "strength": self.random.uniform(0.3, 1),
                    })
        return grains

    def grain_glyphs(self, number):
        glyphs = {}
        for grain in self.grains:
            t = (grain["speed"] * number / FRAMES + grain["phase"]) % 1
            ox, oy = grain["origin"]
            x = ox + t * grain["length"]
            y = oy - grain["rise"] * math.sin(math.pi * t) + 3 * t * t
            brightness = grain["strength"] * math.sin(math.pi * t)
            if brightness < 0.25 or not (0 <= x < self.width and 0 <= y < self.height):
                continue
            # A dot low in the cell for the lower pixel, in the middle for the upper
            glyph = "." if y % 2 >= 1 else "·"
            glyphs[(int(x), int(y) // 2)] = (glyph, 14 if brightness > 0.6 else 11)
        return glyphs

    def star_glyphs(self, number):
        glyphs = {}
        for star in self.stars:
            wave = math.sin(2 * math.pi * (star["twinkle"] * number / FRAMES + star["phase"]))
            # Down to nothing at the bottom of each twinkle
            brightness = star["brightness"] * (0.5 + 0.5 * wave)
            if brightness > 0.6:
                glyphs[star["cell"]] = ("•", 15)
            elif brightness > 0.35:
                glyphs[star["cell"]] = ("·", 15)
            elif brightness > 0.15:
                glyphs[star["cell"]] = ("·", 8)
        return glyphs

    def meteor_pixels(self, number):
        """A shooting star once a loop, down the sky left of the login box:
        pixels of its head and tail, the tail dimming from cream to lavender."""
        first, life = 8, 8
        step = number - first
        if not 0 <= step < life:
            return []
        start = np.array([self.center - 0.42 * self.height, 0.30 * self.height])
        end = np.array([self.center - 0.80 * self.height, 0.50 * self.height])
        direction = (end - start) / np.linalg.norm(end - start)
        head = start + (end - start) * step / (life - 1)
        tail = min(14.0, np.linalg.norm(head - start) + 1)
        # The last steps burn out: the whole streak one shade dimmer each
        dimming = max(0, step - (life - 3))
        shades = [15, 13, 8]
        pixels = {}
        for distance in np.linspace(0, tail, int(tail * 3) + 1):
            x, y = head - direction * distance
            shade = min(int(3 * distance / tail), 2) + dimming
            cell = (int(y), int(x))
            if shade < len(shades) and 0 <= cell[0] < self.height and 0 <= cell[1] < self.width:
                pixels.setdefault(cell, shades[shade])
        return [(y, x, slot) for (y, x), slot in pixels.items() if self.regions[y, x] == SKY]


# ---------------------------------------------------------------- cells

class CellPainter:
    """Picks the glyph and colors of every cell that look most like its two pixels."""

    def __init__(self, coverage):
        blendable = {(first, second) for ramp in RAMPS
                     for index, first in enumerate(ramp) for second in ramp[index + 1:index + 2]}
        blendable |= {(second, first) for first, second in blendable}
        options, looks, penalties = [], [], []
        for glyph, (top_cover, bottom_cover) in zip(GLYPHS, coverage):
            foregrounds = FOREGROUND_SLOTS if glyph != " " else [1]
            backgrounds = BACKGROUND_SLOTS if glyph != "█" else [0]
            for foreground in foregrounds:
                for background in backgrounds:
                    if glyph in "░▒▓" and (foreground, background) not in blendable:
                        continue
                    fg, bg = PALETTE_LINEAR[foreground], PALETTE_LINEAR[background]
                    looks.append([bg + (fg - bg) * top_cover, bg + (fg - bg) * bottom_cover])
                    options.append((glyph, foreground, background))
                    # Shades are a visible texture: only where they pay off
                    penalties.append(0.0004 if glyph in "░▒▓" else 0)
        self.options = options
        self.looks = linear_to_oklab(np.array(looks)).reshape(len(options), 6)
        self.penalties = np.array(penalties)

    def _used_slots(self, option):
        glyph, foreground, background = option
        return {background} if glyph == " " else {foreground} if glyph == "█" else {foreground, background}

    def paint(self, image, regions):
        lines, columns = image.shape[0] // 2, image.shape[1]
        halves = linear_to_oklab(np.clip(image, 0, 1)).reshape(lines, 2, columns, 3)
        targets = halves.transpose(0, 2, 1, 3).reshape(lines * columns, 6)
        cell_regions = regions.reshape(lines, 2, columns).transpose(0, 2, 1).reshape(lines * columns, 2)
        best = np.empty(len(targets), int)
        for pair in {tuple(sorted(pair)) for pair in cell_regions.tolist()}:
            allowed = set().union(*(REGION_SLOTS[region] for region in pair))
            excluded = np.array([not self._used_slots(option) <= allowed for option in self.options])
            cells = np.flatnonzero((np.sort(cell_regions, axis=1) == pair).all(axis=1))
            for start in range(0, len(cells), 2048):
                chunk = cells[start:start + 2048]
                errors = ((targets[chunk][:, None, :] - self.looks[None]) ** 2).sum(-1) + self.penalties
                errors[:, excluded] = np.inf
                best[chunk] = errors.argmin(axis=1)
        return [[self.options[best[line * columns + column]] for column in range(columns)]
                for line in range(lines)]


def plain_background(cell):
    """The background slot a dot can be drawn on in place of this cell, if the
    cell is one flat color: over a blend the dot would leave a flat square."""
    glyph, foreground, background = cell
    if glyph == " ":
        return background
    if glyph == "█" and foreground in BACKGROUND_SLOTS:
        return foreground
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--columns", type=int, required=True)
    parser.add_argument("--lines", type=int, required=True)
    parser.add_argument("--font", required=True, help="the console's PSF2 font, for glyph coverage")
    parser.add_argument("--out", required=True, help="directory for dune.dur and palette")
    args = parser.parse_args()
    if args.columns < 80 or args.lines < 30:
        raise ValueError(f"a {args.columns}x{args.lines} console is too small for the scene")

    painter = CellPainter(glyph_coverage(args.font, GLYPHS + OVERLAY_GLYPHS)[:len(GLYPHS)])
    scene = Scene(args.columns, args.lines)
    # Only the stars and the sand move, as dots over the still scene
    still = painter.paint(scene.static, scene.regions)
    frames = []
    for number in range(FRAMES):
        meteor = scene.meteor_pixels(number)
        if meteor:
            image, regions = scene.static.copy(), scene.regions.copy()
            for y, x, slot in meteor:
                image[y, x] = PALETTE_LINEAR[slot]
                regions[y, x] = LIGHTS
            base = painter.paint(image, regions)
        else:
            base = still
        cells = [list(row) for row in base]
        moving = {**scene.star_glyphs(number), **scene.grain_glyphs(number)}
        for (column, line), (glyph, foreground) in moving.items():
            background = plain_background(base[line][column])
            if background is not None:
                cells[line][column] = (glyph, foreground, background)
        frames.append({
            "frameNumber": number + 1,
            "delay": 0.0,
            "contents": ["".join(glyph for glyph, _, _ in row) for row in cells],
            # durdraw keeps colors column by column: colorMap[x][y] = [fg, bg]
            "colorMap": [[[foreground_index(cells[line][column][1]), background_index(cells[line][column][2])]
                          for line in range(args.lines)] for column in range(args.columns)],
        })

    movie = {"DurMovie": {
        "formatVersion": 7,
        "colorFormat": "256",
        "preferredFont": "fixed",
        "encoding": "utf-8",
        "name": "Arrakis",
        "artist": "",
        "framerate": FRAMERATE,
        "columns": args.columns,
        "lines": args.lines,
        "extra": None,
        "frames": frames,
    }}
    with open(f"{args.out}/dune.dur", "wb") as raw, \
            gzip.GzipFile(fileobj=raw, mode="wb", mtime=0, filename="") as compressed:
        compressed.write(json.dumps(movie, ensure_ascii=False, separators=(",", ":")).encode())
    with open(f"{args.out}/palette", "w") as palette:
        palette.write("\n".join(PALETTE) + "\n")


if __name__ == "__main__":
    main()
