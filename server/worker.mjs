const JSON_HEADERS = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer"
};

function json(data, status = 200, origin = "*") {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...JSON_HEADERS,
      "access-control-allow-origin": origin,
      "access-control-allow-methods": "GET,POST,OPTIONS",
      "access-control-allow-headers": "authorization,content-type",
      "vary": "Origin"
    }
  });
}

const ELEMENTS = [
  ["سایه‌خوری", "جذب و بلعیدن انرژی تاریک"],
  ["شکاف فضایی", "گشودن شکاف‌های کوتاه در فضا"],
  ["طنین روح", "شنیدن ردّ احساسات باقی‌مانده"],
  ["آذرِ خاموش", "آتش بنفش با قابلیت مهار"],
  ["توقف لحظه", "کندکردن کوتاه حرکت پیرامون"],
  ["زرهِ سرنوشت", "تبدیل بخشی از آسیب به نیرو"],
  ["نخ‌های جاذبه", "تغییر جهت حرکت اجسام"],
  ["بازتابِ نفرین", "بازگرداندن بخشی از اثر جادویی"],
  ["چشمِ حقیقت", "دیدن نقاط ضعف پنهان"],
  ["دروازه‌نوردی", "حس‌کردن مسیرهای میان جهان‌ها"]
];

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin") || "*";

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "access-control-allow-origin": origin,
          "access-control-allow-methods": "GET,POST,OPTIONS",
          "access-control-allow-headers": "authorization,content-type",
          "access-control-max-age": "86400",
          "vary": "Origin"
        }
      });
    }

    if ((url.pathname === "/health" || url.pathname === "/api/health") && request.method === "GET") {
      return json({
        ok: true,
        game: "ETERNUM",
        service: "game-api",
        version: "0.1.0",
        time: new Date().toISOString()
      }, 200, origin);
    }

    if (url.pathname === "/api/world" && request.method === "GET") {
      return json({
        ok: true,
        world: {
          name: "ETERNUM",
          title: "جهانِ سرنوشت‌های نانوشته",
          chapter: "first_gate",
          locations: [
            { id: "city", name: "شهرِ فانوس‌های خاموش" },
            { id: "forest", name: "جنگلِ ممنوعه" },
            { id: "ruins", name: "ویرانه‌های فراموش‌شده" }
          ],
          progression: { characterLevelMax: 500, powerMasteryMax: 100 }
        }
      }, 200, origin);
    }

    if (url.pathname === "/api/power/generate" && request.method === "POST") {
      let body;
      try {
        body = await request.json();
      } catch {
        return json({ ok: false, error: "invalid_json" }, 400, origin);
      }

      const characterName = typeof body.characterName === "string"
        ? body.characterName.trim().slice(0, 32)
        : "مسافر بی‌نام";
      const random = crypto.getRandomValues(new Uint32Array(ELEMENTS.length));
      const shuffled = ELEMENTS.map((element, i) => ({ element, key: random[i] }))
        .sort((a, b) => a.key - b.key);

      return json({
        ok: true,
        characterName: characterName || "مسافر بی‌نام",
        power: {
          id: crypto.randomUUID(),
          name: "موهبتِ آستانه",
          rarity: "نامتعارف",
          description: "قدرتی ناشناخته که در لحظهٔ عبور از آستانه بیدار شده است.",
          subpowers: shuffled.map(({ element }, i) => ({
            slot: i + 1,
            name: element[0],
            ability: element[1]
          })),
          mastery: 1,
          locked: false,
          warning: "این پیش‌نمایش است؛ تا زمان تأیید در حساب ذخیره نمی‌شود."
        }
      }, 200, origin);
    }

    if (url.pathname === "/api/rooms" && request.method === "GET") {
      return json({
        ok: true,
        rooms: [],
        status: "multiplayer_pending",
        note: "اتاق‌های پایدار چندنفره هنوز به Durable Objects متصل نشده‌اند."
      }, 200, origin);
    }

    return json({ ok: false, error: "not_found" }, 404, origin);
  }
};
