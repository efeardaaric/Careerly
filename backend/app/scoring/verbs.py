"""English and Turkish action-verb signals. A quality hint, not a hard rule."""

EN = {
    "built",
    "developed",
    "implemented",
    "designed",
    "created",
    "led",
    "managed",
    "optimized",
    "increased",
    "reduced",
    "launched",
    "automated",
    "analyzed",
    "analysed",
    "delivered",
    "improved",
    "owned",
    "shipped",
    "migrated",
    "refactored",
    "mentored",
    "coordinated",
    "established",
    "introduced",
    "streamlined",
}

TR = {
    "gelistirdim",
    "geliştirdim",
    "olusturdum",
    "oluşturdum",
    "tasarladim",
    "tasarladım",
    "yonettim",
    "yönettim",
    "uyguladim",
    "uyguladım",
    "artirdim",
    "artırdım",
    "azalttim",
    "azalttım",
    "iyilestirdim",
    "iyileştirdim",
    "otomatiklestirdim",
    "otomatikleştirdim",
    "analiz",
    "teslim",
    "kurdum",
    "yayina",
    "yayına",
}

ALL = EN | TR


def starts_with_action(bullet: str) -> bool:
    words = bullet.strip().lstrip("-•* ").split()
    if not words:
        return False
    return words[0].lower().strip(".,:;") in ALL
