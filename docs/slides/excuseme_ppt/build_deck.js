const path = require("path");
const PptxGenJS = require("pptxgenjs");
const {
  imageSizingContain,
  imageSizingCrop,
  warnIfSlideHasOverlaps,
  warnIfSlideElementsOutOfBounds,
} = require("./pptxgenjs_helpers");

const pptx = new PptxGenJS();
pptx.layout = "LAYOUT_WIDE";
pptx.author = "OpenAI Codex";
pptx.company = "Excuse Me";
pptx.subject = "Excuse Me projektbemutató";
pptx.title = "Excuse Me projektbemutató";
pptx.lang = "hu-HU";
pptx.theme = {
  headFontFace: "Aptos Display",
  bodyFontFace: "Aptos",
  lang: "hu-HU",
};

const OUT = path.join(__dirname, "excuseme_projekt_bemutato.pptx");
const asset = (name) => path.join(__dirname, "..", "..", "latex", "assets", name);

const C = {
  bg: "F6F1E8",
  panel: "FFFCF8",
  ink: "14324A",
  text: "2F4B62",
  mute: "6E8698",
  line: "D8CFC4",
  accent: "E85D04",
  accent2: "1B998B",
  dark: "0D2234",
  white: "FFFFFF",
  pale: "FFF3EA",
};

function addNotes(slide, lines) {
  slide.addNotes(lines.join("\n"));
}

function finalize(slide, footer) {
  if (slide._finalized) {
    return;
  }
  if (footer) {
    slide.addText(footer, {
      x: 0.6,
      y: 7.06,
      w: 12.0,
      h: 0.16,
      margin: 0,
      fontFace: "Aptos",
      fontSize: 9,
      color: C.mute,
      align: "right",
    });
  }
  warnIfSlideHasOverlaps(slide, pptx);
  warnIfSlideElementsOutOfBounds(slide, pptx);
  slide._finalized = true;
}

function baseSlide(title, kicker, notes, footer = "Excuse Me | Projektbemutató") {
  const slide = pptx.addSlide();
  slide.background = { color: C.bg };
  slide.addShape(pptx.ShapeType.rect, {
    x: 0,
    y: 0,
    w: 13.333,
    h: 0.34,
    line: { color: C.accent, transparency: 100 },
    fill: { color: C.accent },
  });
  slide.addText(kicker, {
    x: 0.6,
    y: 0.42,
    w: 3.2,
    h: 0.18,
    margin: 0,
    fontFace: "Aptos",
    fontSize: 11,
    bold: true,
    color: C.accent,
  });
  slide.addText(title, {
    x: 0.6,
    y: 0.66,
    w: 8.6,
    h: 0.42,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 24,
    bold: true,
    color: C.ink,
  });
  slide.addShape(pptx.ShapeType.line, {
    x: 0.6,
    y: 1.22,
    w: 12.1,
    h: 0,
    line: { color: C.line, pt: 1.2 },
  });
  addNotes(slide, notes);
  slide._footerText = footer;
  return slide;
}

function addPanel(slide, x, y, w, h, fill = C.panel, line = C.line) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x,
    y,
    w,
    h,
    rectRadius: 0.08,
    line: { color: line, pt: 1 },
    fill: { color: fill },
  });
}

function addBullets(slide, items, x, y, w, h, fontSize = 15) {
  const runs = [];
  items.forEach((item) => {
    runs.push({
      text: item,
      options: {
        bullet: { indent: 18 },
        breakLine: true,
      },
    });
  });
  slide.addText(runs, {
    x,
    y,
    w,
    h,
    margin: 0,
    fontFace: "Aptos",
    fontSize,
    color: C.ink,
    breakLine: false,
    valign: "top",
    paraSpaceAfterPt: 9,
  });
}

function addImageCard(slide, imagePath, x, y, w, h, caption) {
  addPanel(slide, x, y, w, h);
  slide.addImage({
    path: imagePath,
    ...imageSizingContain(imagePath, x + 0.12, y + 0.12, w - 0.24, h - 0.52),
  });
  if (caption) {
    slide.addText(caption, {
      x: x + 0.18,
      y: y + h - 0.28,
      w: w - 0.36,
      h: 0.16,
      margin: 0,
      fontFace: "Aptos",
      fontSize: 10,
      color: C.mute,
      italic: true,
      align: "center",
    });
  }
}

function addFullDiagramSlide(title, imageName, noteText) {
  const slide = pptx.addSlide();
  slide.background = { color: C.bg };
  slide.addText(title, {
    x: 0.55,
    y: 0.28,
    w: 8.6,
    h: 0.3,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 20,
    bold: true,
    color: C.ink,
  });
  slide.addImage({
    path: asset(imageName),
    ...imageSizingContain(asset(imageName), 0.45, 0.72, 12.45, 6.3),
  });
  addNotes(slide, noteText);
  finalize(slide, "Excuse Me | Diagram");
}

function slideTitle() {
  const slide = pptx.addSlide();
  slide.background = { color: C.bg };
  slide.addShape(pptx.ShapeType.rect, {
    x: 0,
    y: 0,
    w: 5.1,
    h: 7.5,
    line: { color: C.dark, transparency: 100 },
    fill: { color: C.dark },
  });
  slide.addImage({
    path: asset("gyontatoFulke.png"),
    ...imageSizingCrop(asset("gyontatoFulke.png"), 5.1, 0, 8.23, 7.5),
  });
  slide.addText("Excuse Me", {
    x: 0.72,
    y: 1.1,
    w: 3.2,
    h: 0.48,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 27,
    bold: true,
    color: C.white,
  });
  slide.addText("AI-alapú mobilalkalmazás kifogások újrafogalmazására", {
    x: 0.72,
    y: 1.78,
    w: 3.9,
    h: 0.52,
    margin: 0,
    fontFace: "Aptos",
    fontSize: 18,
    color: "D6E5EF",
  });
  slide.addText(
    "A projekt Flutter kliensből, FastAPI backendből, OpenRouter integrációból és Firestore-alapú adatkezelésből épül fel.",
    {
      x: 0.72,
      y: 2.55,
      w: 3.8,
      h: 1.15,
      margin: 0,
      fontFace: "Aptos",
      fontSize: 14,
      color: "D6E5EF",
      valign: "top",
    }
  );
  slide.addShape(pptx.ShapeType.roundRect, {
    x: 0.72,
    y: 5.75,
    w: 3.8,
    h: 0.7,
    rectRadius: 0.05,
    line: { color: "35546C", pt: 1 },
    fill: { color: "16344C" },
  });
  slide.addText("Fókusz: screenek, architektúra, NoSQL modell és előadói jegyzetek", {
    x: 0.95,
    y: 6.02,
    w: 3.35,
    h: 0.18,
    margin: 0,
    fontFace: "Aptos",
    fontSize: 11,
    color: C.white,
    align: "center",
  });
  addNotes(slide, [
    "Ezen a nyitó dián röviden bemutatnám, hogy az Excuse Me egy kreatív, de technikailag teljes értékű mobilprojekt.",
    "A fő ötlet az, hogy a felhasználó egy valós helyzetet ír be, és az alkalmazás ebből humoros vagy komoly kifogást generál.",
    "A prezentációban külön végigmegyek a képernyőkön, az architektúrán és a Firestore adattároláson is.",
  ]);
  finalize(slide);
}

function slideOverview() {
  const slide = baseSlide(
    "Projektcél és értékajánlat",
    "01 | Áttekintés",
    [
      "Itt azt emelném ki, hogy a projekt nem csak vicces ötlet, hanem mérnöki szempontból is jól rétegzett alkalmazás.",
      "A probléma az, hogy a felhasználó gyorsan akar jobb megfogalmazást, de a hangnem és a nyelv is számít.",
      "A megoldás ezért egyszerre tartalomgeneráló, archiváló és közösségi rendszer.",
    ]
  );
  addPanel(slide, 0.6, 1.52, 5.8, 5.1);
  slide.addText("Miért készült el az alkalmazás?", {
    x: 0.88,
    y: 1.82,
    w: 3.0,
    h: 0.22,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 18,
    bold: true,
    color: C.ink,
  });
  addBullets(slide, [
    "A felhasználó egy kellemetlen helyzetet gyakran rosszul, túl nyersen vagy túl hosszúan fogalmaz meg.",
    "Ugyanarra a helyzetre más hangnem szükséges munkahelyi, privát vagy humoros kontextusban.",
    "A generált szövegek akkor válnak értékessé, ha menthetők, elemezhetők és akár publikálhatók is.",
  ], 0.94, 2.18, 4.95, 2.45);
  slide.addText("Mit ad a rendszer?", {
    x: 0.88,
    y: 5.05,
    w: 2.2,
    h: 0.22,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 18,
    bold: true,
    color: C.accent2,
  });
  addBullets(slide, [
    "Hitelesített mobil klienst.",
    "AI-alapú, nyelvhelyes válaszgenerálást.",
    "History, statisztika, kategóriák és közösségi fal funkciókat.",
  ], 0.94, 5.37, 4.95, 1.05, 14);
  addImageCard(slide, asset("fancyExcuse.png"), 6.72, 1.52, 5.98, 5.1, "Példa a generált eredményre");
  finalize(slide, slide._footerText);
}

function slideUiWalkthrough() {
  const slide = baseSlide(
    "Fő képernyők és felhasználói útvonal",
    "02 | UI áttekintés",
    [
      "Ezen a dián azt mutatnám be, hogyan néz ki a fő user journey a belépéstől a generálásig és a közösségi funkciókig.",
      "A hangsúly azon van, hogy a képernyők nem önálló elemek, hanem egy folyamat részei.",
    ]
  );
  addImageCard(slide, asset("excuseme_ui_diagram.png"), 0.72, 1.58, 5.4, 4.95, "A navigációs struktúra");
  addImageCard(slide, asset("navbar.png"), 6.45, 1.58, 2.25, 4.95, "Oldalsó menü");
  addPanel(slide, 8.98, 1.58, 3.72, 4.95, "F8F5EE");
  slide.addText("Mit látunk?", {
    x: 9.24,
    y: 1.88,
    w: 2.2,
    h: 0.2,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 18,
    bold: true,
    color: C.ink,
  });
  addBullets(slide, [
    "A kezdőfelület két fő tabot ad: Generator és Wall of Shame.",
    "A drawer kezeli a profilhoz kötött nézeteket: statisztika, history, kategóriák és Hall of Fame.",
    "A theme-váltás és az accountkezelés ugyanebben az oldalsó panelben történik.",
    "A képernyők külön screen osztályokba vannak szervezve, ezért a navigáció a kódban is tiszta.",
  ], 9.24, 2.18, 3.0, 3.5, 14);
  finalize(slide, slide._footerText);
}

function slideGenerator() {
  const slide = baseSlide(
    "Generator képernyő és eredménykártya",
    "03 | Screen walkthrough",
    [
      "Itt érdemes hangsúlyozni, hogy ez a projekt fő interakciós pontja.",
      "A felhasználó beírja az igazságot, stílust választ, majd a rendszer egy rövid, célzott választ ad vissza.",
      "A kártya innen továbbvezeti a felhasználót újragenerálásra vagy publikálásra.",
    ]
  );
  addImageCard(slide, asset("gyontatoFulke.png"), 0.72, 1.58, 3.75, 4.95, "Bemeneti felület");
  addImageCard(slide, asset("fancyExcuse.png"), 4.8, 1.58, 3.75, 4.95, "Eredménykártya");
  addPanel(slide, 8.88, 1.58, 3.8, 4.95, C.pale, "F0D7C2");
  slide.addText("Működés", {
    x: 9.14,
    y: 1.88,
    w: 2.0,
    h: 0.2,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 18,
    bold: true,
    color: C.accent,
  });
  addBullets(slide, [
    "A truth mező 240 karakterre korlátozott, így a backend bemenete kontrollálható marad.",
    "A stílusválasztás ugyanazt az endpointot használja, de más promptfeltétellel.",
    "A válaszban megjelenik az eredeti truth, a detektált nyelv, a kategória és a kész kifogás.",
    "A Post to wall művelet már egy korábban létrehozott generation rekordra épül.",
  ], 9.14, 2.2, 3.0, 3.3, 14);
  finalize(slide, slide._footerText);
}

function slideAuthHistoryStats() {
  const slide = baseSlide(
    "Bejelentkezés, előzmények és statisztika",
    "04 | Screen walkthrough",
    [
      "Ez a dia azt mutatja, hogy a projekt nem névtelen egyszeri generátor, hanem állapotot és felhasználói adatot kezel.",
      "A session fontos, mert minden generálás userhez kötött, és innen lesz history meg statisztika.",
    ]
  );
  addImageCard(slide, asset("signupScreen.png"), 0.72, 1.58, 3.55, 4.95, "Belépés és regisztráció");
  addImageCard(slide, asset("historyScreen.png"), 4.57, 1.58, 4.25, 4.95, "Saját előzmények");
  addImageCard(slide, asset("statsScreen.png"), 9.12, 1.58, 3.55, 4.95, "Statisztikai nézet");
  finalize(slide, slide._footerText);
}

function slideAuthHistoryStatsExplain() {
  const slide = baseSlide(
    "Mit mondanék ezekről a képernyőkről?",
    "05 | Funkcionális magyarázat",
    [
      "Itt külön bontanám a három képernyő szerepét, mert ezek mutatják meg igazán a perzisztenciát és az analitikát.",
    ]
  );
  addPanel(slide, 0.72, 1.56, 12.0, 5.0);
  addBullets(slide, [
    "A belépési képernyő tokenalapú hitelesítést ad, így a generálások és a közösségi műveletek felhasználóhoz rendelhetők.",
    "A History képernyőben a korábbi generálások újrahasznosíthatók, szűrhetők és utólag publikálhatók.",
    "A Stats képernyő a backend aggregációjára épül, ezért nem a kliens számol mindent külön-külön.",
    "Ezek együtt azt bizonyítják, hogy az alkalmazás tud tartalom-életciklust kezelni, nem csak egyszeri válaszokat adni.",
  ], 1.0, 1.98, 11.4, 2.4, 16);
  slide.addText("Kulcsgondolat: minden generálás tartós rekord, amelyből később feed, leaderboard és felhasználói analitika is építhető.", {
    x: 1.0,
    y: 5.0,
    w: 11.0,
    h: 0.45,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 17,
    color: C.accent2,
    bold: true,
  });
  finalize(slide, slide._footerText);
}

function slideCommunity() {
  const slide = baseSlide(
    "Közösségi képernyők",
    "06 | Screen walkthrough",
    [
      "Ezek a képernyők mutatják meg, hogy a projekt közösségi dimenziót is kapott.",
      "Itt át lehet vezetni a hallgatóságot a publikus feedtől a rangsorolásig és a kategóriákig.",
    ]
  );
  addImageCard(slide, asset("publicCategories.png"), 0.72, 1.58, 3.9, 4.95, "Kategória alapú publikus feed");
  addImageCard(slide, asset("hallofFame.png"), 4.92, 1.58, 3.9, 4.95, "Hall of Fame");
  addImageCard(slide, asset("wallofshame.png"), 9.12, 1.58, 3.5, 4.95, "Wall of Shame");
  finalize(slide, slide._footerText);
}

function slideCommunityExplain() {
  const slide = baseSlide(
    "Közösségi funkciók értelmezése",
    "07 | Funkcionális magyarázat",
    [
      "A közösségi nézetekkel azt lehet hangsúlyozni, hogy a generált tartalomnak másodlagos élete is van.",
    ]
  );
  addBullets(slide, [
    "A Wall of Shame a fő publikus folyam, ahol reakciók érkeznek a posztokra.",
    "A Hall of Fame összesíti ezeket a reakciókat, ezért a közösségi érték mérhetővé válik.",
    "A Categories nézet tematikusan bontja fel a tartalmat, így a feed nem csak időrendi listává válik.",
    "Admin szerepkörben a publikus fal moderálható, tehát a rendszer tartalomkezelési felelősséget is vállal.",
  ], 0.92, 1.7, 6.2, 3.25, 16);
  addImageCard(slide, asset("hallofFame.png"), 7.42, 1.58, 2.35, 4.95, "Toplista");
  addImageCard(slide, asset("publicCategories.png"), 9.96, 1.58, 2.35, 4.95, "Témaszűrés");
  addPanel(slide, 0.92, 5.18, 6.15, 1.18, C.pale, "F0D7C2");
  slide.addText("Üzleti és mérnöki értelemben ez növeli a retentiont, a visszatérést és a funkcionális mélységet.", {
    x: 1.16,
    y: 5.56,
    w: 5.55,
    h: 0.28,
    margin: 0,
    fontFace: "Aptos",
    fontSize: 13,
    color: C.ink,
    align: "center",
  });
  finalize(slide, slide._footerText);
}

function slideArchitecture() {
  const slide = baseSlide(
    "Rendszerarchitektúra",
    "08 | Technikai áttekintés",
    [
      "Itt röviden végigmennék azon, hogy melyik réteg miért felelős.",
      "A legfontosabb üzenet az, hogy a kliens, a backend, az AI és a tárolás jól el van választva egymástól.",
    ]
  );
  addImageCard(slide, asset("excuseme_block_diagram.png"), 0.72, 1.58, 6.1, 4.95, "Magas szintű komponenskapcsolatok");
  addPanel(slide, 7.1, 1.58, 5.55, 4.95);
  addBullets(slide, [
    "A Flutter kliens felel a kezelőfelületért és a felhasználói állapotért.",
    "A FastAPI backend validál, hitelesít, AI-t hív és repository-rétegen keresztül perzisztál.",
    "Az OpenRouter hívás a szerveren marad, így az API-kulcs nem kerül ki a mobilkliensbe.",
    "A Firestore repository ugyanazt a domainmodellt követi, mint az in-memory repository, ezért tesztelhető és cserélhető.",
  ], 7.36, 1.96, 4.95, 3.65, 15);
  finalize(slide, slide._footerText);
}

function slideApi() {
  const slide = baseSlide(
    "API-kommunikáció és hibakezelés",
    "09 | Backend",
    [
      "Ezen a dián azt mondanám el, hogy a kliens-szerver kommunikáció pontos JSON-szerződésre épül.",
      "A másik fontos pont a hibák normalizálása: timeout, upstream hiba és auth hiba külön kezelve jelenik meg.",
    ]
  );
  addPanel(slide, 0.72, 1.58, 4.2, 4.95);
  slide.addText("Fő endpointok", {
    x: 0.98,
    y: 1.88,
    w: 2.0,
    h: 0.2,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 18,
    bold: true,
    color: C.ink,
  });
  addBullets(slide, [
    "POST /api/auth/signup és /api/auth/login",
    "POST /api/excuses/generate",
    "GET /api/history és /api/stats/overview",
    "GET /api/categories/{category} és /api/leaderboard",
    "POST /api/wall/publish/{id}, POST /api/wall/react/{id}, DELETE /api/admin/wall/{id}",
  ], 1.02, 2.16, 3.45, 3.4, 14);
  addPanel(slide, 5.2, 1.58, 3.15, 2.18, "F8F5EE");
  slide.addText('{ "truth": "Lekéstem a meetingről", "style": "serious" }', {
    x: 5.45,
    y: 2.16,
    w: 2.62,
    h: 0.58,
    margin: 0,
    fontFace: "Consolas",
    fontSize: 11,
    color: C.dark,
  });
  slide.addText("Példakérés", {
    x: 5.45,
    y: 1.84,
    w: 1.5,
    h: 0.18,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 15,
    bold: true,
    color: C.accent2,
  });
  addPanel(slide, 5.2, 4.0, 3.15, 2.53, C.pale, "F0D7C2");
  slide.addText('{ "generationId": "...", "excuse": "Váratlan műszaki akadály miatt csúsztam.", "detectedLanguage": "hu", "style": "serious", "category": "work" }', {
    x: 5.45,
    y: 4.35,
    w: 2.62,
    h: 1.45,
    margin: 0,
    fontFace: "Consolas",
    fontSize: 10,
    color: C.dark,
  });
  slide.addText("Példaválasz", {
    x: 5.45,
    y: 4.12,
    w: 1.6,
    h: 0.18,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 15,
    bold: true,
    color: C.accent,
  });
  addPanel(slide, 8.65, 1.58, 4.0, 4.95);
  slide.addText("Hibatűrés", {
    x: 8.92,
    y: 1.88,
    w: 1.8,
    h: 0.2,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 18,
    bold: true,
    color: C.ink,
  });
  addBullets(slide, [
    "A kliens timeouttal hívja az API-t, és emberileg érthető üzenetet jelenít meg.",
    "A backend 502-re fordítja az upstream AI-hibát, 504-re a timeoutot.",
    "A nyelvdetektálás és az egyszeri retry garantálja, hogy a válasz a bemenet nyelvén érkezzen.",
    "A 401-es hibák külön kezelik a hitelesítés hiányát vagy érvénytelenségét.",
  ], 8.95, 2.18, 3.3, 3.45, 14);
  finalize(slide, slide._footerText);
}

function slideFirestore() {
  const slide = baseSlide(
    "Firestore adatmodell",
    "10 | NoSQL perzisztencia",
    [
      "Itt azt hangsúlyoznám, hogy NoSQL-ban nem klasszikus táblák vannak, hanem kollekciók és dokumentumok, de az üzleti modell ugyanúgy jól felismerhető.",
      "A három fő kollekció a users, az excuse_generations és a wall_posts.",
    ]
  );
  addImageCard(slide, asset("firestore.png"), 0.72, 1.58, 5.15, 4.95, "Firestore nézet a projekt dokumentációjából");
  addPanel(slide, 6.14, 1.58, 6.52, 4.95);
  slide.addText("Kollekciók és szerepük", {
    x: 6.42,
    y: 1.86,
    w: 3.0,
    h: 0.2,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 18,
    bold: true,
    color: C.ink,
  });
  addBullets(slide, [
    "users: felhasználói azonosító, username, passwordHash, isAdmin, createdAt",
    "excuse_generations: userId, username, truth, excuse, style, language, category, publishedToWall, createdAt",
    "wall_posts: username, truth, excuse, style, language, category, generationId, reactions, lolCount, createdAt",
    "A wall_posts dokumentum a generation rekord publikus, reakciózható kivetítése.",
  ], 6.45, 2.16, 5.75, 2.9, 14);
  addPanel(slide, 6.45, 5.2, 5.75, 0.95, C.pale, "F0D7C2");
  slide.addText("NoSQL előny: a lekérdezések a képernyők igényeihez igazodnak, például history lista, leaderboard és kategória feed.", {
    x: 6.72,
    y: 5.48,
    w: 5.2,
    h: 0.28,
    margin: 0,
    fontFace: "Aptos",
    fontSize: 12,
    color: C.ink,
    align: "center",
  });
  finalize(slide, slide._footerText);
}

function slideTesting() {
  const slide = baseSlide(
    "Tesztelhetőség és állapotkezelés",
    "11 | Minőség",
    [
      "Itt azt mondanám el, hogy a projekt felépítése támogatja az automatizált ellenőrzést.",
      "A backendben endpoint és üzleti logika tesztek vannak, a Flutter oldalon pedig widget tesztek és dependency injection.",
    ]
  );
  addImageCard(slide, asset("excuseme_state_diagram.png"), 0.72, 1.58, 3.65, 2.25, "Állapotdiagram");
  addImageCard(slide, asset("excuseme_activity_diagram.png"), 0.72, 4.06, 3.65, 2.25, "Aktivitásdiagram");
  addImageCard(slide, asset("excuseme_class_diagram.png"), 4.65, 1.58, 4.6, 4.73, "Osztálydiagram");
  addPanel(slide, 9.54, 1.58, 3.12, 4.73, "F8F5EE");
  addBullets(slide, [
    "FastAPI tesztek ellenőrzik a sikeres generálást, a validation hibákat, a timeoutot és az upstream hibát.",
    "A widget tesztek lefedik a gombállapotot, az eredménykirajzolást és a wall feed megjelenítést.",
    "A szolgáltatásrétegek leválasztása miatt a UI könnyen tesztelhető hamis service-ekkel is.",
  ], 9.78, 1.92, 2.55, 3.55, 13);
  finalize(slide, slide._footerText);
}

function slideClosing() {
  const slide = pptx.addSlide();
  slide.background = { color: C.dark };
  slide.addImage({
    path: asset("hallofFame.png"),
    ...imageSizingCrop(asset("hallofFame.png"), 7.58, 0, 5.75, 7.5),
  });
  slide.addText("Összegzés", {
    x: 0.8,
    y: 1.06,
    w: 2.2,
    h: 0.22,
    margin: 0,
    fontFace: "Aptos",
    fontSize: 13,
    bold: true,
    color: "8ED1C9",
  });
  slide.addText("Az Excuse Me egyszerre kreatív és mérnökileg felépített mobilprojekt", {
    x: 0.8,
    y: 1.46,
    w: 5.7,
    h: 0.82,
    margin: 0,
    fontFace: "Aptos Display",
    fontSize: 26,
    bold: true,
    color: C.white,
  });
  addBullets(slide, [
    "Van jól követhető felhasználói folyamata.",
    "Van szerveroldali üzleti logikája és hibatűrése.",
    "Van Firestore-alapú perzisztenciája és közösségi modulja.",
  ], 0.95, 2.55, 5.7, 1.9, 16);
  slide.addShape(pptx.ShapeType.roundRect, {
    x: 0.92,
    y: 5.52,
    w: 4.95,
    h: 0.72,
    rectRadius: 0.05,
    line: { color: "2F495D", pt: 1 },
    fill: { color: "16344C" },
  });
  slide.addText("Kulcsszó: AI-támogatott kreatív újrafogalmazás közösségi visszacsatolással", {
    x: 1.18,
    y: 5.79,
    w: 4.4,
    h: 0.18,
    margin: 0,
    fontFace: "Aptos",
    fontSize: 11,
    color: C.white,
    align: "center",
  });
  addNotes(slide, [
    "Zárásként azt emelném ki, hogy a projekt nem csak látványos, hanem technikailag is összerakott.",
    "A kliens, a backend, az AI és az adattárolás együtt egy teljes mini terméket adnak.",
    "Innen tovább lehetne menni például jobb moderáció, részletesebb analitika vagy több nyelvi modell irányába.",
  ]);
  finalize(slide);
}

slideTitle();
slideOverview();
slideUiWalkthrough();
slideGenerator();
slideAuthHistoryStats();
slideAuthHistoryStatsExplain();
slideCommunity();
slideCommunityExplain();
slideArchitecture();
slideApi();
slideFirestore();
slideTesting();

addFullDiagramSlide("Use case diagram", "excuseme_usecase_diagram.png", [
  "Ezt a diagramot külön diára tettem, hogy jól olvasható legyen.",
  "Itt röviden bemutatnám a felhasználó és az admin fő use case-eit.",
]);
addFullDiagramSlide("UI diagram", "excuseme_ui_diagram.png", [
  "Ez a diagram a fő képernyőstruktúrát foglalja össze.",
  "A lényeg az, hogy a navigáció funkcionális szempontból is konzisztens.",
]);
addFullDiagramSlide("Block diagram", "excuseme_block_diagram.png", [
  "Ez a blokkdiagram a rendszer nagy komponenseit és kapcsolatait mutatja.",
  "A kliens, a backend és a perzisztencia jól külön rétegekben marad.",
]);
addFullDiagramSlide("Sequence diagram", "excuseme_sequence_diagram.png", [
  "Itt a generálási folyamat lépései látszanak a felhasználói kéréstől az AI-válaszig.",
  "Ez jó hely a szerveroldali validáció és retry logika említésére.",
]);
addFullDiagramSlide("State diagram", "excuseme_state_diagram.png", [
  "Ez az állapotdiagram azt mutatja, hogyan mozog a felhasználó a fő interakciók között.",
  "Kiemelném, hogy a képernyőállapotok és az API-hívások szépen elválaszthatók.",
]);
addFullDiagramSlide("Activity diagram", "excuseme_activity_diagram.png", [
  "Az aktivitásdiagram a fő üzleti folyamatot mutatja egyben.",
  "Ez összeköti a felhasználói műveleteket a rendszer reakcióival.",
]);
addFullDiagramSlide("Class diagram", "excuseme_class_diagram.png", [
  "Az osztálydiagram jól mutatja a modellek, service-ek és screenek közötti kapcsolatot.",
  "Ebből látszik, hogy a kód szerkezete több külön rétegre van bontva.",
]);

slideClosing();

(async () => {
  for (const slide of pptx._slides) {
    finalize(slide, slide._footerText);
  }
  await pptx.writeFile({ fileName: OUT });
  console.log(`Deck written to ${OUT}`);
})();
