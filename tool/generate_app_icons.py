from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ICON = ROOT / "assets" / "branding" / "app_icon_source.png"
SOURCE_ROUND_ICON = ROOT / "assets" / "branding" / "app_icon_round.png"
WINDOWS_ICON = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"

ANDROID_ICON_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

ICO_SIZES = (16, 24, 32, 48, 64, 128, 256)


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    raw = hex_color.lstrip("#")
    return int(raw[0:2], 16), int(raw[2:4], 16), int(raw[4:6], 16), alpha


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def lerp_color(
    start: tuple[int, int, int, int],
    end: tuple[int, int, int, int],
    t: float,
) -> tuple[int, int, int, int]:
    return tuple(lerp(a, b, t) for a, b in zip(start, end))


def cubic(
    p0: tuple[float, float],
    p1: tuple[float, float],
    p2: tuple[float, float],
    p3: tuple[float, float],
    steps: int = 40,
) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    for index in range(steps + 1):
        t = index / steps
        mt = 1 - t
        x = (
            mt * mt * mt * p0[0]
            + 3 * mt * mt * t * p1[0]
            + 3 * mt * t * t * p2[0]
            + t * t * t * p3[0]
        )
        y = (
            mt * mt * mt * p0[1]
            + 3 * mt * mt * t * p1[1]
            + 3 * mt * t * t * p2[1]
            + t * t * t * p3[1]
        )
        points.append((x, y))
    return points


def add_rounded_shadow(
    image: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    blur: int,
    offset: tuple[int, int],
    alpha: int,
) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    shifted = (
        box[0] + offset[0],
        box[1] + offset[1],
        box[2] + offset[0],
        box[3] + offset[1],
    )
    draw.rounded_rectangle(shifted, radius=radius, fill=alpha)
    shadow.putalpha(mask.filter(ImageFilter.GaussianBlur(blur)))
    image.alpha_composite(shadow)


def add_ellipse_shadow(
    image: Image.Image,
    box: tuple[int, int, int, int],
    blur: int,
    offset: tuple[int, int],
    alpha: int,
) -> None:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    shifted = (
        box[0] + offset[0],
        box[1] + offset[1],
        box[2] + offset[0],
        box[3] + offset[1],
    )
    draw.ellipse(shifted, fill=alpha)
    shadow.putalpha(mask.filter(ImageFilter.GaussianBlur(blur)))
    image.alpha_composite(shadow)


def add_rounded_gradient(
    image: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    top: tuple[int, int, int, int],
    bottom: tuple[int, int, int, int],
) -> None:
    width = box[2] - box[0]
    height = box[3] - box[1]
    gradient = Image.new("RGBA", (width, height))
    pixels = gradient.load()
    for y in range(height):
        color = lerp_color(top, bottom, y / max(height - 1, 1))
        for x in range(width):
            pixels[x, y] = color

    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, width - 1, height - 1),
        radius=radius,
        fill=255,
    )
    gradient.putalpha(mask)
    image.alpha_composite(gradient, dest=(box[0], box[1]))


def add_ellipse_gradient(
    image: Image.Image,
    box: tuple[int, int, int, int],
    top: tuple[int, int, int, int],
    bottom: tuple[int, int, int, int],
) -> None:
    width = box[2] - box[0]
    height = box[3] - box[1]
    gradient = Image.new("RGBA", (width, height))
    pixels = gradient.load()
    for y in range(height):
        color = lerp_color(top, bottom, y / max(height - 1, 1))
        for x in range(width):
            pixels[x, y] = color

    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, width - 1, height - 1), fill=255)
    gradient.putalpha(mask)
    image.alpha_composite(gradient, dest=(box[0], box[1]))


def make_feather(scale: int) -> Image.Image:
    layer_size = 820 * scale
    center = layer_size // 2
    layer = Image.new("RGBA", (layer_size, layer_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    def p(x: float, y: float) -> tuple[float, float]:
        return center + x * scale, center + y * scale

    left_edge = cubic(p(0, -280), p(-165, -180), p(-138, 88), p(-28, 252))
    right_edge = cubic(p(0, -280), p(180, -172), p(120, 112), p(26, 252))
    body = left_edge + list(reversed(right_edge))

    body_points = [(round(x), round(y)) for x, y in body]
    draw.polygon(body_points, fill=rgba("#f6fff8"), outline=rgba("#18364b"))
    draw.line(body_points + [body_points[0]], fill=rgba("#18364b"), width=16 * scale, joint="curve")

    spine_top = p(0, -258)
    spine_bottom = p(0, 338)
    draw.line(
        [spine_top, spine_bottom],
        fill=rgba("#14354c"),
        width=24 * scale,
    )
    draw.line(
        [spine_top, spine_bottom],
        fill=rgba("#78e5d8"),
        width=10 * scale,
    )
    draw.line(
        [p(0, 245), p(-78, 360)],
        fill=rgba("#f2d092"),
        width=22 * scale,
    )
    draw.line(
        [p(0, 245), p(-78, 360)],
        fill=rgba("#18364b", 170),
        width=6 * scale,
    )

    for y, left_x, right_x in [
        (-182, -92, 90),
        (-122, -122, 118),
        (-56, -130, 120),
        (16, -118, 104),
        (88, -91, 82),
        (156, -56, 50),
    ]:
        draw.line([p(0, y), p(left_x, y + 64)], fill=rgba("#5fc8c6", 160), width=7 * scale)
        draw.line([p(0, y), p(right_x, y + 62)], fill=rgba("#5fc8c6", 140), width=7 * scale)

    # Small cuts keep the feather readable as a feather instead of a leaf.
    draw.polygon(
        [(round(x), round(y)) for x, y in [p(-154, -34), p(-86, -2), p(-138, 38)]],
        fill=rgba("#f6f0dd"),
    )
    draw.polygon(
        [(round(x), round(y)) for x, y in [p(126, 44), p(72, 78), p(118, 116)]],
        fill=rgba("#f6f0dd"),
    )

    return layer.rotate(-28, resample=Image.Resampling.BICUBIC, expand=True)


def make_source_icon(size: int = 1024, scale: int = 3, round_shape: bool = False) -> Image.Image:
    work_size = size * scale
    image = Image.new("RGBA", (work_size, work_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    def v(value: int) -> int:
        return value * scale

    outer = (v(48), v(48), v(976), v(976))
    if round_shape:
        add_ellipse_shadow(image, outer, v(38), (0, v(26)), 120)
        add_ellipse_gradient(image, outer, rgba("#102440"), rgba("#1d3140"))
        draw.ellipse(outer, outline=rgba("#7ce7db", 115), width=v(10))
    else:
        add_rounded_shadow(image, outer, v(230), v(38), (0, v(26)), 120)
        add_rounded_gradient(
            image,
            outer,
            v(230),
            rgba("#102440"),
            rgba("#1d3140"),
        )
        draw.rounded_rectangle(outer, radius=v(230), outline=rgba("#7ce7db", 115), width=v(10))

    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((v(-150), v(-135), v(520), v(520)), fill=rgba("#27d6c8", 58))
    glow_draw.ellipse((v(600), v(560), v(1160), v(1140)), fill=rgba("#f26d55", 45))
    image.alpha_composite(glow.filter(ImageFilter.GaussianBlur(v(42))))

    canvas_box = (v(210), v(250), v(814), v(740))
    add_rounded_shadow(image, canvas_box, v(108), v(26), (0, v(20)), 90)
    draw.rounded_rectangle(canvas_box, radius=v(108), fill=rgba("#f6f0dd"))
    draw.rounded_rectangle(canvas_box, radius=v(108), outline=rgba("#73e4d8"), width=v(18))
    draw.rounded_rectangle((v(262), v(304), v(760), v(686)), radius=v(78), fill=rgba("#fff9ec", 235))

    grid_color = rgba("#1a3b55", 48)
    for x in range(330, 740, 96):
        draw.line((v(x), v(330), v(x), v(664)), fill=grid_color, width=v(4))
    for y in range(354, 660, 86):
        draw.line((v(290), v(y), v(742), v(y)), fill=grid_color, width=v(4))

    pixel_size = v(44)
    pixels = [
        (636, 302, "#65e4d7"),
        (692, 302, "#7aa7ff"),
        (748, 302, "#ff7d63"),
        (692, 358, "#ffe08a"),
        (748, 358, "#65e4d7"),
        (636, 414, "#9e89ff"),
    ]
    for x, y, color in pixels:
        box = (v(x), v(y), v(x) + pixel_size, v(y) + pixel_size)
        draw.rounded_rectangle(box, radius=v(10), fill=rgba("#14354c", 42))
        inner = (box[0] - v(4), box[1] - v(5), box[2] - v(4), box[3] - v(5))
        draw.rounded_rectangle(inner, radius=v(9), fill=rgba(color))

    feather = make_feather(scale)
    feather_shadow = Image.new("RGBA", feather.size, (0, 0, 0, 0))
    feather_shadow.putalpha(feather.getchannel("A").filter(ImageFilter.GaussianBlur(v(8))))
    image.alpha_composite(feather_shadow, dest=(v(244), v(128)))
    image.alpha_composite(feather, dest=(v(238), v(110)))

    for x, y, color, radius in [
        (300, 236, "#ffe08a", 18),
        (790, 610, "#7ce7db", 16),
        (280, 684, "#ff7d63", 13),
    ]:
        draw.ellipse((v(x - radius), v(y - radius), v(x + radius), v(y + radius)), fill=rgba(color, 210))

    final_mask = Image.new("L", image.size, 0)
    final_draw = ImageDraw.Draw(final_mask)
    if round_shape:
        final_draw.ellipse(outer, fill=255)
    else:
        final_draw.rounded_rectangle(outer, radius=v(230), fill=255)
    image.putalpha(Image.composite(image.getchannel("A"), Image.new("L", image.size, 0), final_mask))

    return image.resize((size, size), Image.Resampling.LANCZOS)


def write_png(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG", optimize=True)


def main() -> None:
    source = make_source_icon()
    round_source = make_source_icon(round_shape=True)
    write_png(SOURCE_ICON, source)
    write_png(SOURCE_ROUND_ICON, round_source)

    for density, size in ANDROID_ICON_SIZES.items():
        target_dir = ROOT / "android" / "app" / "src" / "main" / "res" / density
        write_png(target_dir / "ic_launcher.png", source.resize((size, size), Image.Resampling.LANCZOS))
        write_png(target_dir / "ic_launcher_round.png", round_source.resize((size, size), Image.Resampling.LANCZOS))

    WINDOWS_ICON.parent.mkdir(parents=True, exist_ok=True)
    source.save(WINDOWS_ICON, format="ICO", sizes=[(size, size) for size in ICO_SIZES])

    print(f"Wrote {SOURCE_ICON.relative_to(ROOT)}")
    print(f"Wrote {SOURCE_ROUND_ICON.relative_to(ROOT)}")
    print("Wrote Android launcher icons")
    print(f"Wrote {WINDOWS_ICON.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
