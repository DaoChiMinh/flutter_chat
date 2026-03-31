"""
GIPHY Sticker Tool
==================
Tải animated sticker từ GIPHY API + đặt tên theo quy tắc viết tắt.

Quy tắc tên:
  "milk and mocha"  → MM1, MM2, MM3, ...
  "peach cat"       → PC1, PC2, PC3, ...
  "bugcat capoo"    → BC1, BC2, BC3, ...
  "kawaii bear"     → KB1, KB2, KB3, ...
  Hoặc tự đặt:     --prefix BG → BG1, BG2, BG3, ...

Setup:
  pip install requests
  1. Vào https://developers.giphy.com → Login → Create App → API → Copy Key
  2. export GIPHY_API_KEY=your_key_here

Ví dụ:
  python giphy_sticker_tool.py "milk and mocha"
  python giphy_sticker_tool.py "milk and mocha" --download
  python giphy_sticker_tool.py "peach cat mochi" --download --limit 40
  python giphy_sticker_tool.py "bugcat capoo" --download --prefix BC --dart
  python giphy_sticker_tool.py "kawaii bear" --download --dart --dart-file bear.dart
"""

import argparse
import json
import os
import re
import sys
import time

import requests

# ── Từ bỏ qua khi tạo prefix ────────────────────────────────
SKIP_WORDS = {"and", "the", "of", "in", "on", "at", "for", "to", "a", "an", "is", "with"}

GIPHY_STICKER_SEARCH = "https://api.giphy.com/v1/stickers/search"
GIPHY_STICKER_TRENDING = "https://api.giphy.com/v1/stickers/trending"


# ============================================================
# NAMING: Tạo prefix từ query
# ============================================================

def make_prefix(query: str) -> str:
    """
    Tạo prefix 2 ký tự viết hoa từ query.

    "milk and mocha"  → MM
    "peach cat"       → PC
    "bugcat capoo"    → BC
    "kawaii"          → KA
    "cute bunny cat"  → CBC (3 từ → 3 ký tự, nhưng giới hạn 2)
    """
    words = [w for w in query.lower().split() if w not in SKIP_WORDS and len(w) > 0]

    if not words:
        return "ST"

    if len(words) == 1:
        # Từ đơn: lấy 2 ký tự đầu
        return words[0][:2].upper()

    # Nhiều từ: lấy chữ cái đầu mỗi từ (tối đa 2-3)
    prefix = "".join(w[0] for w in words[:3]).upper()
    return prefix[:2] if len(prefix) > 3 else prefix


def make_filename(prefix: str, index: int, ext: str = "gif") -> str:
    """MM1.gif, MM2.gif, ..., MM10.gif, ..."""
    return f"{prefix}{index}.{ext}"


# ============================================================
# GIPHY API
# ============================================================

def fetch_stickers(query: str, api_key: str, limit: int = 50) -> list[dict]:
    """Tìm sticker qua GIPHY API."""
    print(f"🔍 Đang tìm: \"{query}\" (limit={limit})")

    stickers = []
    offset = 0
    total_available = 0

    while len(stickers) < limit:
        batch = min(50, limit - len(stickers))
        params = {
            "api_key": api_key,
            "q": query,
            "limit": batch,
            "offset": offset,
            "rating": "g",
            "lang": "en",
        }

        try:
            resp = requests.get(GIPHY_STICKER_SEARCH, params=params, timeout=15)
            resp.raise_for_status()
            data = resp.json()
        except requests.RequestException as e:
            print(f"❌ Lỗi API: {e}")
            break
        except json.JSONDecodeError:
            print("❌ Response không phải JSON")
            break

        results = data.get("data", [])
        total_available = data.get("pagination", {}).get("total_count", 0)

        if not results:
            break

        for item in results:
            images = item.get("images", {})
            original = images.get("original", {})
            fixed = images.get("fixed_height", {})
            size_bytes = int(original.get("size", 0) or 0)

            stickers.append({
                "id": item.get("id", ""),
                "title": _clean_title(item.get("title", "")),
                "gif_url": original.get("url", ""),
                "gif_200": fixed.get("url", ""),
                "webp_url": fixed.get("webp", ""),
                "size_kb": round(size_bytes / 1024, 1),
            })

        offset += len(results)
        if len(results) < batch:
            break
        time.sleep(0.2)

    print(f"✅ Tìm thấy {len(stickers)} sticker (GIPHY có ~{total_available} kết quả)")
    return stickers[:limit]


def fetch_trending(api_key: str, limit: int = 50) -> list[dict]:
    """Lấy sticker trending"""
    print(f"🔥 Trending stickers (limit={limit})")
    params = {"api_key": api_key, "limit": min(limit, 50), "rating": "g"}

    try:
        resp = requests.get(GIPHY_STICKER_TRENDING, params=params, timeout=15)
        resp.raise_for_status()
        data = resp.json()
    except Exception as e:
        print(f"❌ Lỗi: {e}")
        return []

    stickers = []
    for item in data.get("data", []):
        images = item.get("images", {})
        original = images.get("original", {})
        fixed = images.get("fixed_height", {})

        stickers.append({
            "id": item.get("id", ""),
            "title": _clean_title(item.get("title", "")),
            "gif_url": original.get("url", ""),
            "gif_200": fixed.get("url", ""),
            "webp_url": fixed.get("webp", ""),
            "size_kb": round(int(original.get("size", 0) or 0) / 1024, 1),
        })

    print(f"✅ {len(stickers)} sticker trending")
    return stickers


def _clean_title(title: str) -> str:
    title = re.sub(r'\s*Sticker\s*(by\s+.*)?$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*GIF\s*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'Sticker gif\.\s*', '', title, flags=re.IGNORECASE)
    return title.strip()[:60] or 'sticker'


# ============================================================
# DOWNLOAD
# ============================================================

def download_stickers(stickers: list[dict], out_dir: str, prefix: str, use_webp: bool = False):
    """
    Tải sticker và đặt tên: MM1.gif, MM2.gif, ...
    Tạo file mapping.json để tra cứu.
    """
    os.makedirs(out_dir, exist_ok=True)
    ext = "webp" if use_webp else "gif"

    print(f"\n📥 Tải {len(stickers)} sticker → {out_dir}/")
    print(f"   Tên file: {prefix}1.{ext}, {prefix}2.{ext}, ...\n")

    mapping = []
    success = 0
    total_size = 0

    for i, s in enumerate(stickers, 1):
        name = make_filename(prefix, i, ext)
        filepath = os.path.join(out_dir, name)

        url = s["webp_url"] if use_webp and s["webp_url"] else s["gif_200"]
        if not url:
            url = s["gif_url"]

        # Lưu mapping
        mapping.append({
            "name": f"{prefix}{i}",
            "file": name,
            "giphy_id": s["id"],
            "title": s["title"],
            "original_url": s["gif_200"] or s["gif_url"],
        })

        if os.path.exists(filepath):
            fsize = os.path.getsize(filepath) / 1024
            total_size += fsize
            print(f"  [{i:>3}/{len(stickers)}] ⏭️  {name:<10} (đã có, {fsize:.0f}KB)")
            success += 1
            continue

        try:
            resp = requests.get(url, timeout=20, stream=True)
            resp.raise_for_status()

            with open(filepath, 'wb') as f:
                for chunk in resp.iter_content(chunk_size=8192):
                    f.write(chunk)

            fsize = os.path.getsize(filepath) / 1024
            total_size += fsize
            print(f"  [{i:>3}/{len(stickers)}] ✅ {name:<10} ({fsize:.0f}KB) — {s['title'][:35]}")
            success += 1
            time.sleep(0.15)

        except Exception as e:
            print(f"  [{i:>3}/{len(stickers)}] ❌ {name:<10} {e}")

    # Lưu mapping JSON
    mapping_path = os.path.join(out_dir, "mapping.json")
    with open(mapping_path, 'w', encoding='utf-8') as f:
        json.dump(mapping, f, ensure_ascii=False, indent=2)

    print(f"\n{'═' * 50}")
    print(f"🎉 Hoàn tất: {success}/{len(stickers)} sticker")
    print(f"📦 Tổng dung lượng: {total_size:.0f}KB ({total_size/1024:.1f}MB)")
    print(f"📁 Thư mục: {out_dir}/")
    print(f"📄 Mapping: {mapping_path}")
    print(f"{'═' * 50}")

    return mapping

# ============================================================
# DART CODE GENERATOR
# ============================================================

def generate_dart(stickers: list[dict], prefix: str, pack_name: str, local_path: str | None = None) -> str:
    """Sinh code Dart StickerPack với tên MM1, MM2, ..."""
    pack_id = re.sub(r'[^a-z0-9]+', '_', pack_name.lower()).strip('_')

    lines = [
        f"final _{pack_id}Pack = StickerPack(",
        f"  id: '{pack_id}',",
        f"  name: '{pack_name.title()}',",
    ]

    if stickers:
        url0 = _dart_url(stickers[0], prefix, 1, local_path)
        lines.append(f"  thumbnail: '{url0}',")

    lines.append("  stickers: const [")

    for i, s in enumerate(stickers, 1):
        sid = f"{prefix}{i}"
        url = _dart_url(s, prefix, i, local_path)
        comment = s['title'][:40]
        lines.append(f"    Sticker(id: '{sid}', packId: '{pack_id}', url: '{url}'), // {comment}")

    lines.append("  ],")
    lines.append(");")
    return '\n'.join(lines)


def _dart_url(s: dict, prefix: str, index: int, local_path: str | None) -> str:
    if local_path:
        return f"{local_path}/{prefix}{index}.gif"
    return f"https://media.giphy.com/media/{s['id']}/200.gif"


# ============================================================
# DISPLAY
# ============================================================

def print_table(stickers: list[dict], prefix: str):
    print(f"\n{'─' * 75}")
    print(f"{'#':>3}  {'Tên':<6}  {'ID':<22}  {'Size':>6}  {'Title'}")
    print(f"{'─' * 75}")

    for i, s in enumerate(stickers, 1):
        name = f"{prefix}{i}"
        size = f"{s.get('size_kb', 0):.0f}KB"
        title = s['title'][:40]
        print(f"{i:>3}  {name:<6}  {s['id']:<22}  {size:>6}  {title}")

    print(f"{'─' * 75}")


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description='GIPHY Sticker Tool — Tải sticker + đặt tên MM1, PC1, BC1, ...',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
═══════════════════════════════════════════════════════════
Lấy API Key miễn phí (30 giây):
  1. Vào https://developers.giphy.com → Login
  2. Create an App → API → Copy Key
  3. export GIPHY_API_KEY=your_key_here
═══════════════════════════════════════════════════════════

Quy tắc tên:
  "milk and mocha"  → MM1, MM2, MM3, ...
  "peach cat"       → PC1, PC2, PC3, ...
  "bugcat capoo"    → BC1, BC2, BC3, ...
  Tự đặt:          --prefix BG → BG1, BG2, ...

Ví dụ:
  %(prog)s "milk and mocha" --download
  %(prog)s "peach cat mochi" --download --limit 40
  %(prog)s "bugcat capoo" --download --prefix BC --dart
  %(prog)s "kawaii bear" --download --dart --dart-file bear.dart
  %(prog)s "cute cat" --download --webp
  %(prog)s --trending --download --prefix TR
        """,
    )

    parser.add_argument('query', nargs='?', default=None, help='Từ khóa (vd: "milk and mocha")')
    parser.add_argument('--key', type=str, default=None, help='GIPHY API Key')
    parser.add_argument('--prefix', type=str, default=None, help='Prefix tên file (vd: MM). Tự tạo nếu không đặt')
    parser.add_argument('--limit', type=int, default=25, help='Số sticker tối đa (mặc định: 25)')
    parser.add_argument('--trending', action='store_true', help='Lấy sticker trending')
    parser.add_argument('--download', action='store_true', help='Tải về local')
    parser.add_argument('--webp', action='store_true', help='Tải WebP (nhỏ hơn GIF)')
    parser.add_argument('--out', type=str, default=None, help='Thư mục lưu')
    parser.add_argument('--dart', action='store_true', help='Xuất code Dart')
    parser.add_argument('--dart-file', type=str, default=None, help='Lưu Dart code ra file')
    parser.add_argument('--local-path', type=str, default=None, help='Path local trong Dart code')

    args = parser.parse_args()

    # ── API Key ───────────────────────────────────────────
    api_key = "KVLk62EyA3HFyeWtBZ2oo3nivvQx1ntZ"#//args.key or os.environ.get("GIPHY_API_KEY")
    if not api_key:
        print("❌ Cần GIPHY API Key!")
        print("   Lấy miễn phí: https://developers.giphy.com")
        print("   Dùng: --key YOUR_KEY hoặc export GIPHY_API_KEY=YOUR_KEY")
        sys.exit(1)

    # ── Fetch ─────────────────────────────────────────────
    if args.trending:
        stickers = fetch_trending(api_key, limit=args.limit)
        pack_name = "trending"
    elif args.query:
        stickers = fetch_stickers(args.query, api_key, limit=args.limit)
        pack_name = args.query
    else:
        parser.print_help()
        sys.exit(1)

    if not stickers:
        print("❌ Không tìm thấy sticker nào.")
        sys.exit(1)

    # ── Prefix ────────────────────────────────────────────
    prefix = args.prefix or make_prefix(pack_name)
    print(f"\n📛 Prefix: {prefix} → {prefix}1, {prefix}2, ... {prefix}{len(stickers)}")

    # ── Print ─────────────────────────────────────────────
    print_table(stickers, prefix)

    # ── Download ──────────────────────────────────────────
    slug = re.sub(r'[^a-z0-9]+', '_', pack_name.lower()).strip('_')

    if args.download:
        out_dir = args.out or f"./stickers/{slug}"
        download_stickers(stickers, out_dir, prefix, use_webp=args.webp)

    # ── Dart ──────────────────────────────────────────────
    if args.dart:
        dart_code = generate_dart(stickers, prefix, pack_name, args.local_path)

        print(f"\n{'═' * 70}")
        print("📋 DART CODE:")
        print(f"{'═' * 70}")
        print(dart_code)
        print(f"{'═' * 70}")

        if args.dart_file:
            with open(args.dart_file, 'w', encoding='utf-8') as f:
                f.write(dart_code)
            print(f"💾 Đã lưu: {args.dart_file}")


if __name__ == '__main__':
    main()