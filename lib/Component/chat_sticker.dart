// ============================================================
// STICKER DATA MODEL + PACKS (GIPHY CDN - truy cập được ở VN)
// ============================================================

class StickerPack {
  final String id;
  final String name;
  final String thumbnail;
  final List<Sticker> stickers;

  const StickerPack({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.stickers,
  });
}

class Sticker {
  final String id;
  final String packId;
  final String url;
  final StickerType type;

  const Sticker({
    required this.id,
    required this.packId,
    required this.url,
    this.type = StickerType.gif,
  });
}

enum StickerType { gif, lottie }

// ── 1. Capoo (Bugcat) — mèo xanh siêu cute ─────────────────
// Artist: @capoo trên GIPHY

final _capooPack = StickerPack(
  id: 'capoo',
  name: 'Capoo',
  thumbnail: 'https://media4.giphy.com/media/WxKdPPaxNLCdxgLoBN/200.gif',
  stickers: const [
    Sticker(
      id: 'capoo_01',
      packId: 'capoo',
      url:
          'https://media4.giphy.com/media/WxKdPPaxNLCdxgLoBN/200.gif', // nervous sweat
    ),
    Sticker(
      id: 'capoo_02',
      packId: 'capoo',
      url:
          'https://media4.giphy.com/media/5QMKspne3I3yOk40fl/200.gif', // cute cat
    ),
    Sticker(
      id: 'capoo_03',
      packId: 'capoo',
      url:
          'https://media1.giphy.com/media/455cA4lrbxf2awroM9/200.gif', // cat cute
    ),
    Sticker(
      id: 'capoo_04',
      packId: 'capoo',
      url: 'https://media1.giphy.com/media/L2ec9HGkVlmO78cGBJ/200.gif', // clap
    ),
    Sticker(
      id: 'capoo_05',
      packId: 'capoo',
      url:
          'https://media2.giphy.com/media/QlQdLBS70XJcZY1fLF/giphy.gif', // sad cry
    ),
    Sticker(
      id: 'capoo_06',
      packId: 'capoo',
      url: 'https://media1.giphy.com/media/MX5tWoGn9B3iU1riZJ/200.gif', // happy
    ),
    Sticker(
      id: 'capoo_07',
      packId: 'capoo',
      url:
          'https://media4.giphy.com/media/1hoKkBNSBxVyHIsPer/200.gif', // heart love
    ),
    Sticker(
      id: 'capoo_08',
      packId: 'capoo',
      url:
          'https://media0.giphy.com/media/4Ztytt2s2Cr7XyTI1z/200.gif', // bugcat
    ),
    Sticker(
      id: 'capoo_09',
      packId: 'capoo',
      url:
          'https://media0.giphy.com/media/4N99JtCB4RKJsqt6rJ/200.gif', // cat go
    ),
    Sticker(
      id: 'capoo_10',
      packId: 'capoo',
      url:
          'https://media4.giphy.com/media/Z9uERnzkW098ezsfMu/200.gif', // clapping seal
    ),
  ],
);

// ── 2. Milk & Mocha Bear — cặp gấu trắng + nâu ─────────────
// Artist: @milkmochabear trên GIPHY

final _milkMochaPack = StickerPack(
  id: 'milk_mocha',
  name: 'Milk & Mocha',
  thumbnail: 'https://media2.giphy.com/media/JRsQiAN79bPWUv43Ko/giphy.gif',
  stickers: const [
    Sticker(
      id: 'mm_01',
      packId: 'milk_mocha',
      url:
          'https://media4.giphy.com/media/kfRKF0iqA8jyDqq1nH/200.gif', // white bear heart
    ),
    Sticker(
      id: 'mm_02',
      packId: 'milk_mocha',
      url:
          'https://media2.giphy.com/media/JRsQiAN79bPWUv43Ko/giphy.gif', // white bear dance
    ),
    Sticker(
      id: 'mm_03',
      packId: 'milk_mocha',
      url:
          'https://media4.giphy.com/media/fvN5KrNcKKUyX7hNIA/200.gif', // brown bear kiss
    ),
    Sticker(
      id: 'mm_04',
      packId: 'milk_mocha',
      url:
          'https://media0.giphy.com/media/kf3EjrAsKp3P9bhYHG/giphy.gif', // mocha disco
    ),
    Sticker(
      id: 'mm_05',
      packId: 'milk_mocha',
      url:
          'https://media3.giphy.com/media/1yXzByUnOcb8OVcVyi/giphy.gif', // cat cosplay
    ),
    Sticker(
      id: 'mm_06',
      packId: 'milk_mocha',
      url:
          'https://media2.giphy.com/media/F6CnfR89rHPGpE7mrk/giphy.gif', // cat omg
    ),
    Sticker(
      id: 'mm_07',
      packId: 'milk_mocha',
      url:
          'https://media2.giphy.com/media/KdB5DnYdadrJMWP6Rz/giphy.gif', // peep
    ),
    Sticker(
      id: 'mm_08',
      packId: 'milk_mocha',
      url:
          'https://media2.giphy.com/media/7SDfDM318Pqt4eGdha/giphy.gif', // sad cry
    ),
  ],
);

// ── 3. Tonton Friends — thỏ + chó chibi ─────────────────────
// Artist: @tontonfriends trên GIPHY

final _tontonPack = StickerPack(
  id: 'tonton',
  name: 'Tonton',
  thumbnail: 'https://media0.giphy.com/media/ExpF7gk9NY2JYBLzNJ/giphy.gif',
  stickers: const [
    Sticker(
      id: 'tt_01',
      packId: 'tonton',
      url:
          'https://media0.giphy.com/media/ExpF7gk9NY2JYBLzNJ/giphy.gif', // bunny love
    ),
    Sticker(
      id: 'tt_02',
      packId: 'tonton',
      url:
          'https://media1.giphy.com/media/q4YtFJ9Inq3UQDlPEF/giphy.gif', // bunny no
    ),
    Sticker(
      id: 'tt_03',
      packId: 'tonton',
      url:
          'https://media0.giphy.com/media/rL0yRrsd5a5PSeUMe7/giphy.gif', // nodding yes
    ),
    Sticker(
      id: 'tt_04',
      packId: 'tonton',
      url:
          'https://media2.giphy.com/media/ZBPzPhOF9N6tVh82yr/giphy.gif', // dog love
    ),
    Sticker(
      id: 'tt_05',
      packId: 'tonton',
      url:
          'https://media2.giphy.com/media/rQF9BJzLsTwo29Sumr/giphy.gif', // heart bunny
    ),
  ],
);

// ── ALL PACKS ────────────────────────────────────────────────

final kStickerPacks = <StickerPack>[_capooPack, _milkMochaPack, _tontonPack];

// ── Recent stickers manager ──────────────────────────────────

class RecentStickerManager {
  static final _recent = <Sticker>[];
  static const _maxRecent = 20;

  static List<Sticker> get recents => List.unmodifiable(_recent);

  static void add(Sticker sticker) {
    _recent.removeWhere((s) => s.id == sticker.id);
    _recent.insert(0, sticker);
    if (_recent.length > _maxRecent) _recent.removeLast();
  }
}
