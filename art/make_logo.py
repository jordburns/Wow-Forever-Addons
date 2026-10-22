import argparse
import math
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
SLOT_COUNT = 5
TITLE_MAX_WIDTH = 860
FONT_IMPACT = "/System/Library/Fonts/Supplemental/Impact.ttf"
FONT_TITLE = "/System/Library/Fonts/Supplemental/Trebuchet MS Bold.ttf"
OUTPUT_SIZES = (1024, 400, 64)

GOLD = (222, 178, 82)
GOLD_LIGHT = (255, 224, 140)
OUTLINE_DARK = (10, 12, 24)

THEMES = {
    "navy": {"top": (20, 26, 48), "bottom": (38, 52, 96), "emblem": (88, 120, 170), "emblem_dark": (44, 64, 104)},
    "crimson": {"top": (40, 12, 16), "bottom": (92, 24, 30), "emblem": (170, 60, 60), "emblem_dark": (100, 30, 34)},
    "forest": {"top": (14, 32, 20), "bottom": (30, 74, 44), "emblem": (70, 140, 90), "emblem_dark": (34, 80, 48)},
    "purple": {"top": (28, 16, 44), "bottom": (62, 36, 98), "emblem": (128, 90, 180), "emblem_dark": (70, 46, 110)},
}


def point(x, y, size, fx, fy):
    return (x + size * fx, y + size * fy)


def polygon(draw, x, y, size, points, **style):
    draw.polygon([point(x, y, size, fx, fy) for fx, fy in points], **style)


def icon_sword(draw, x, y, size):
    polygon(draw, x, y, size, [(0.78, 0.16), (0.86, 0.24), (0.38, 0.72), (0.30, 0.64)], fill=(225, 230, 240))
    draw.line((*point(x, y, size, 0.22, 0.56), *point(x, y, size, 0.46, 0.80)), fill=GOLD, width=int(size * 0.08))
    draw.line((*point(x, y, size, 0.32, 0.70), *point(x, y, size, 0.18, 0.84)), fill=(120, 80, 40), width=int(size * 0.09))


def icon_shield(draw, x, y, size):
    polygon(draw, x, y, size, [(0.5, 0.16), (0.8, 0.28), (0.76, 0.6), (0.5, 0.86), (0.24, 0.6), (0.2, 0.28)],
            fill=(88, 120, 170), outline=GOLD_LIGHT, width=int(size * 0.05))


def icon_flame(draw, x, y, size):
    polygon(draw, x, y, size, [(0.5, 0.12), (0.74, 0.48), (0.72, 0.72), (0.5, 0.88), (0.28, 0.72), (0.3, 0.46), (0.42, 0.56)],
            fill=(240, 120, 30))
    polygon(draw, x, y, size, [(0.5, 0.42), (0.62, 0.64), (0.5, 0.8), (0.38, 0.66)], fill=(255, 220, 90))


def icon_heal(draw, x, y, size):
    arm = size * 0.14
    centre = size / 2
    draw.rectangle((x + centre - arm, y + size * 0.2, x + centre + arm, y + size * 0.8), fill=(90, 210, 110))
    draw.rectangle((x + size * 0.2, y + centre - arm, x + size * 0.8, y + centre + arm), fill=(90, 210, 110))


def icon_bolt(draw, x, y, size):
    polygon(draw, x, y, size, [(0.58, 0.12), (0.28, 0.54), (0.48, 0.54), (0.38, 0.88), (0.74, 0.42), (0.54, 0.42)],
            fill=(120, 200, 255))


def icon_bag(draw, x, y, size):
    draw.rounded_rectangle((*point(x, y, size, 0.2, 0.36), *point(x, y, size, 0.8, 0.84)), radius=int(size * 0.1),
                           fill=(160, 110, 60), outline=GOLD_LIGHT, width=int(size * 0.04))
    draw.arc((*point(x, y, size, 0.32, 0.14), *point(x, y, size, 0.68, 0.54)), 180, 360, fill=GOLD_LIGHT,
             width=int(size * 0.06))


def icon_map(draw, x, y, size):
    polygon(draw, x, y, size, [(0.16, 0.24), (0.38, 0.16), (0.62, 0.26), (0.84, 0.18), (0.84, 0.76), (0.62, 0.84),
                               (0.38, 0.74), (0.16, 0.82)], fill=(220, 200, 150))
    draw.line((*point(x, y, size, 0.3, 0.6), *point(x, y, size, 0.5, 0.42), *point(x, y, size, 0.7, 0.56)),
              fill=(180, 40, 40), width=int(size * 0.05))


def icon_star(draw, x, y, size):
    polygon(draw, x, y, size, [(0.5, 0.12), (0.6, 0.4), (0.88, 0.4), (0.66, 0.58), (0.74, 0.86), (0.5, 0.7),
                               (0.26, 0.86), (0.34, 0.58), (0.12, 0.4), (0.4, 0.4)], fill=GOLD_LIGHT)


def icon_skull(draw, x, y, size):
    draw.ellipse((*point(x, y, size, 0.22, 0.14), *point(x, y, size, 0.78, 0.66)), fill=(230, 230, 220))
    draw.rectangle((*point(x, y, size, 0.34, 0.56), *point(x, y, size, 0.66, 0.82)), fill=(230, 230, 220))
    draw.ellipse((*point(x, y, size, 0.32, 0.34), *point(x, y, size, 0.46, 0.5)), fill=(20, 20, 30))
    draw.ellipse((*point(x, y, size, 0.54, 0.34), *point(x, y, size, 0.68, 0.5)), fill=(20, 20, 30))


def icon_book(draw, x, y, size):
    draw.rectangle((*point(x, y, size, 0.18, 0.2), *point(x, y, size, 0.5, 0.82)), fill=(120, 60, 160))
    draw.rectangle((*point(x, y, size, 0.5, 0.2), *point(x, y, size, 0.82, 0.82)), fill=(140, 76, 184))
    draw.line((*point(x, y, size, 0.5, 0.2), *point(x, y, size, 0.5, 0.82)), fill=GOLD_LIGHT, width=int(size * 0.04))


def icon_gear(draw, x, y, size):
    centre = point(x, y, size, 0.5, 0.5)
    for angle in range(0, 360, 45):
        draw.line((*centre, *point(x, y, size, 0.5 + 0.36 * math.cos(math.radians(angle)), 0.5 + 0.36 * math.sin(math.radians(angle)))),
                  fill=(170, 180, 190), width=int(size * 0.14))
    draw.ellipse((*point(x, y, size, 0.24, 0.24), *point(x, y, size, 0.76, 0.76)), fill=(170, 180, 190))
    draw.ellipse((*point(x, y, size, 0.4, 0.4), *point(x, y, size, 0.6, 0.6)), fill=(30, 34, 50))


ICONS = {
    "sword": (icon_sword, (60, 34, 34), ["sword", "warrior", "melee", "attack", "combat", "damage", "dps"]),
    "shield": (icon_shield, (30, 40, 70), ["shield", "tank", "defense", "protect", "armor", "paladin"]),
    "flame": (icon_flame, (70, 34, 20), ["fire", "flame", "mage", "spell", "magic", "warlock"]),
    "heal": (icon_heal, (24, 60, 36), ["heal", "healer", "priest", "health", "restore", "support"]),
    "bolt": (icon_bolt, (22, 40, 72), ["lightning", "shaman", "energy", "fast", "speed", "macro", "action"]),
    "bag": (icon_bag, (54, 40, 24), ["bag", "bags", "inventory", "item", "items", "loot", "gold", "vendor"]),
    "map": (icon_map, (40, 46, 40), ["map", "quest", "guide", "route", "travel", "explore", "zone"]),
    "star": (icon_star, (50, 44, 20), ["star", "favorite", "reputation", "achievement", "reward"]),
    "skull": (icon_skull, (36, 30, 40), ["skull", "boss", "dungeon", "raid", "death", "pvp", "rogue"]),
    "book": (icon_book, (40, 26, 54), ["book", "journal", "spellbook", "talent", "lore", "learn"]),
    "gear": (icon_gear, (34, 38, 46), ["gear", "settings", "config", "tool", "profession", "option"]),
}
DEFAULT_ICONS = ["sword", "shield", "flame", "heal", "bolt"]


def choose_icons(icon_names, description):
    if icon_names:
        chosen = [name.strip() for name in icon_names.split(",") if name.strip()]
        unknown = [name for name in chosen if name not in ICONS]
        if unknown:
            raise SystemExit(f"Unknown icons: {', '.join(unknown)}. Choose from: {', '.join(ICONS)}")
        return chosen[:SLOT_COUNT]
    words = set(re.findall(r"[a-z]+", (description or "").lower()))
    chosen = [name for name, (_, _, keywords) in ICONS.items() if words & set(keywords)]
    for name in DEFAULT_ICONS:
        if len(chosen) >= SLOT_COUNT:
            break
        if name not in chosen:
            chosen.append(name)
    return chosen[:SLOT_COUNT]


def default_initials(name):
    return "".join(word[0] for word in name.split() if word[:1].isalnum()).upper()[:3]


def vertical_gradient(top, bottom):
    gradient = Image.new("RGB", (1, SIZE))
    for y in range(SIZE):
        t = y / (SIZE - 1)
        gradient.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return gradient.resize((SIZE, SIZE))


def draw_background(logo, theme):
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rounded_rectangle((16, 16, SIZE - 16, SIZE - 16), radius=150, fill=255)
    logo.paste(vertical_gradient(theme["top"], theme["bottom"]), (0, 0), mask)
    ImageDraw.Draw(logo).rounded_rectangle((16, 16, SIZE - 16, SIZE - 16), radius=150, outline=GOLD, width=18)


def draw_emblem(logo, theme):
    shape = [(512, 150), (722, 222), (706, 452), (512, 612), (318, 452), (302, 222)]
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(glow).polygon(shape, fill=GOLD + (150,))
    logo.alpha_composite(glow.filter(ImageFilter.GaussianBlur(28)))
    draw = ImageDraw.Draw(logo)
    draw.polygon(shape, fill=theme["emblem"])
    draw.line(shape + [shape[0]], fill=GOLD, width=16, joint="curve")
    inner = [(512, 196), (680, 254), (667, 440), (512, 566), (357, 440), (344, 254)]
    draw.polygon(inner, fill=theme["emblem_dark"])
    draw.line([(512, 196), (512, 566)], fill=theme["emblem"], width=6)


def fitted_font(draw, path, text, start_size, max_width):
    size = start_size
    while size > 20:
        font = ImageFont.truetype(path, size)
        box = draw.textbbox((0, 0), text, font=font)
        if box[2] - box[0] <= max_width:
            return font
        size -= 4
    return ImageFont.truetype(path, size)


def draw_centred_text(draw, text, font, top, **style):
    box = draw.textbbox((0, 0), text, font=font)
    x = (SIZE - (box[2] - box[0])) // 2 - box[0]
    draw.text((x, top - box[1]), text, font=font, **style)
    return box


def draw_initials(logo, initials):
    draw = ImageDraw.Draw(logo)
    font = fitted_font(draw, FONT_IMPACT, initials, 250, 340)
    box = draw.textbbox((0, 0), initials, font=font)
    top = 400 - (box[3] - box[1]) // 2
    draw_centred_text(draw, initials, font, top + 10, fill=(0, 0, 0, 160))
    draw_centred_text(draw, initials, font, top, fill=GOLD_LIGHT, stroke_width=6, stroke_fill=(60, 40, 10))


def draw_title(logo, title):
    draw = ImageDraw.Draw(logo)
    font = fitted_font(draw, FONT_TITLE, title, 92, TITLE_MAX_WIDTH)
    draw_centred_text(draw, title, font, 628, fill=(240, 240, 250), stroke_width=4, stroke_fill=OUTLINE_DARK)


def draw_action_bar(logo, icon_names):
    draw = ImageDraw.Draw(logo)
    slot, gap, top = 118, 22, 712
    left = (SIZE - (len(icon_names) * slot + (len(icon_names) - 1) * gap)) // 2
    for index, name in enumerate(icon_names):
        draw_icon, background, _ = ICONS[name]
        x = left + index * (slot + gap)
        draw.rounded_rectangle((x, top, x + slot, top + slot), radius=18, fill=background, outline=GOLD, width=6)
        draw_icon(draw, x + 8, top + 8, slot - 16)


def draw_author(logo, author):
    draw = ImageDraw.Draw(logo)
    font = fitted_font(draw, FONT_TITLE, f"by {author}", 60, TITLE_MAX_WIDTH)
    draw_centred_text(draw, f"by {author}", font, 872, fill=GOLD_LIGHT, stroke_width=3, stroke_fill=OUTLINE_DARK)


def parse_arguments():
    parser = argparse.ArgumentParser(description="Make an addon logo in dist/logos.")
    parser.add_argument("--name", required=True, help='Addon name, for example "Class Macros"')
    parser.add_argument("--description", default="", help="Words that describe the addon. They choose the icons.")
    parser.add_argument("--icons", default="", help=f"Comma list of up to {SLOT_COUNT} icons: {', '.join(ICONS)}")
    parser.add_argument("--initials", default="", help="Letters on the emblem. Default: the first letters of the name.")
    parser.add_argument("--author", default="Crypto", help='Shown as "by <author>"')
    parser.add_argument("--theme", default="navy", choices=sorted(THEMES))
    return parser.parse_args()


def main():
    arguments = parse_arguments()
    theme = THEMES[arguments.theme]
    icon_names = choose_icons(arguments.icons, arguments.description)
    initials = arguments.initials or default_initials(arguments.name)

    logo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_background(logo, theme)
    draw_emblem(logo, theme)
    draw_initials(logo, initials)
    draw_title(logo, arguments.name.upper())
    draw_action_bar(logo, icon_names)
    draw_author(logo, arguments.author)

    output = Path(__file__).resolve().parent.parent / "dist" / "logos"
    output.mkdir(parents=True, exist_ok=True)
    file_prefix = re.sub(r"[^A-Za-z0-9]+", "_", arguments.name).strip("_")
    for size in OUTPUT_SIZES:
        image = logo if size == SIZE else logo.resize((size, size), Image.LANCZOS)
        image.save(output / f"{file_prefix}-logo-{size}.png")
    print(f"Logos: {output}/{file_prefix}-logo-<size>.png (icons: {', '.join(icon_names)})")


if __name__ == "__main__":
    main()
