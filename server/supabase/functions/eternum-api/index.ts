const HEADERS = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,POST,OPTIONS",
  "access-control-allow-headers": "authorization,content-type"
};

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

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: HEADERS });
}

Deno.serve(async (request: Request) => {
  const url = new URL(request.url);
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: HEADERS });

  if ((url.pathname.endsWith("/health") || url.pathname.endsWith("/api/health")) && request.method === "GET") {
    return json({ ok: true, game: "ETERNUM", service: "game-api", version: "0.1.0", time: new Date().toISOString() });
  }

  if (url.pathname.endsWith("/api/world") && request.method === "GET") {
    return json({ ok: true, world: {
      name: "ETERNUM",
      title: "جهانِ سرنوشت‌های نانوشته",
      chapter: "first_gate",
      locations: [
        { id: "city", name: "شهرِ فانوس‌های خاموش" },
        { id: "forest", name: "جنگلِ ممنوعه" },
        { id: "ruins", name: "ویرانه‌های فراموش‌شده" }
      ],
      progression: { characterLevelMax: 500, powerMasteryMax: 100 }
    }});
  }

  if (url.pathname.endsWith("/api/power/generate") && request.method === "POST") {
    let body: Record<string, unknown>;
    try { body = await request.json(); } catch { return json({ ok: false, error: "invalid_json" }, 400); }
    const characterName = typeof body.characterName === "string" ? body.characterName.trim().slice(0, 32) : "مسافر بی‌نام";
    const shuffled = [...ELEMENTS].sort(() => Math.random() - 0.5);
    return json({
      ok: true,
      characterName: characterName || "مسافر بی‌نام",
      power: {
        id: crypto.randomUUID(),
        name: "موهبتِ آستانه",
        rarity: "نامتعارف",
        description: "قدرتی ناشناخته که در لحظهٔ عبور از آستانه بیدار شده است.",
        subpowers: shuffled.map((element, i) => ({ slot: i + 1, name: element[0], ability: element[1] })),
        mastery: 1,
        locked: false,
        warning: "این پیش‌نمایش است؛ تا زمان تأیید در حساب ذخیره نمی‌شود."
      }
    });
  }

  if (url.pathname.endsWith("/api/rooms") && request.method === "GET") {
    return json({ ok: true, rooms: [], status: "multiplayer_pending", note: "اتاق‌های پایدار چندنفره هنوز به سرور چندنفره متصل نشده‌اند." });
  }

  return json({ ok: false, error: "not_found" }, 404);
});
