# 🥚 كيف يشتغل رصد البيض (Egg Detection) — v2.1

الهدف: **ما تبقى القايمة فارغة أبداً** — حتى لو كانت أسماء الأوبجكتات غريبة،
وحتى لو البيضة تولّات (spawned) بعد ما شغّلت السكريبت.

---

## 1. المشكلة القديمة

النسخة الأولى كانت تعمل غير هادا:

```lua
if d.Name:lower():find("egg") then ... end
```

يعني: إذا الأوبجكت ما كان اسمو فيه «egg» → **ما يتلاقى**. والنتيجة: `eggs found: 0`
على أغلب السيرفرات (البيضات غالباً سمّاوها على اسم البرينروت اللي جوّه،
مثلاً `DragonCannelloni`، أو عندهم `ProximityPrompt` بلا اسم واضح).

---

## 2. الحل: نظام نقاط (0–100) بـ 7 مصادر

كل أوبجكت من نوع `Model` أو `BasePart` يمرّ على هاد الفلتر:

```text
  1)  هل هو داخل شخصية لاعب/NPC؟            ->  لا، نتجاهلوه
  2)  هل واحد من أسلافو مسجّل كبيضة؟         ->  نعم، نتجاهلوه (مانكرروش)
  3)  هل هو «مكان» (island / biome / ltm)؟  ->  نعم، نتجاهلوه إلا إذا موسوم بيضة
  4)  نحسب النقاط (الجدول تحت)
  5)  النقاط >= عتبة الحساسية؟               ->  نسجّلو بيضة
```

### جدول النقاط

| المصدر (source) | النقاط | كيف نتعرفو |
|---|---|---|
| `db` | **100** | الاسم يطابق واحد من الـ 35 بيضة المعروفة (مطابقة تامة أو جزئية) |
| `value` | **95** | خاصية/قيمة جوّه فيها اسم برينروت معروف (`EggName`, `Brainrot`, `Reward`…) |
| `attr` | **85** | خاصية `IsEgg` / `IsCollectible` / `IsPickup` = true |
| `name` | **70** | كلمة «egg» (أو `capsule`, `nest`, `pod`…) باسمو هو |
| `user` | **65** | كلمة من الكلمات اللي كتبتها بخانة «extra keywords» |
| `prompt` | **58** | عندو `ProximityPrompt` مكتوب فيه Collect / Grab / Pick / Steal / Hatch |
| `click` | **50** | عندو `ClickDetector` |
| داخل مجلد `Eggs` / `Islands` / `LTM` / `Event` | **+12** | يرفّع أي إشارة حقيقية فوقو |
| الندرة/الجزيرة جاية من خاصية | **72–75** | `Rarity="Secret"`، `Island="Lava"`… |
| مجرد «موجود داخل مجلد Eggs» | 45 | أقل من العتبة → **ما يتّعتابرش** بيضة (صخرة مثلاً) |

### عتبة الحساسية (من الواجهة)

| الاختيار | العتبة | متى تستعملو |
|---|---|---|
| **loose (يلقى أكثر)** | 35 | إذا القايمة باقي فارغة — يقبل حتى الحاجات اللي داخل مجلد البيضات |
| **normal** (الافتراضي) | 60 | التوازن الطبيعي |
| **strict (أخطاء أقل)** | 75 | إذا القايمة فيها حاجات مو بيض |

---

## 3. منين جاية الندرة (يعني علاه ما يطلعش `Unknown`)

بالترتيب — أول واحد يلقاه هو المستعمل:

1. خاصية على الأوبجكت: `Rarity`, `EggRarity`, `Tier`, `Rank`, `Quality`
   (ويتطبعع: `brainrotgod` → `Brainrot God`, `bg` → `Brainrot God`, `sec` → `Secret`…)
2. قيمة `StringValue` اسمها فيه كلمة rarity جوّه الأوبجكت.
3. **قاعدة البيانات**: الاسم يطابق واحد من الـ 35 بيضة → ندرة + جزيرة + الدخل.
4. النص الحر: `"Secret Egg"`, `"Mythic_Capsule"` → يقرا الندرة من الكلمة.
5. كآخر حل: `Unknown` (رمادي) — وإمكانك تخفيهم بـ *Hide eggs with unknown rarity*.

### قاعدة البيانات (35 بيضة = 7 جزر × 5)

| الجزيرة | البيضات (من الأرخص للأغلى) |
|---|---|
| **Grass** | Cavallo Virtuoso · Tartaruga Cisterna · Eggdin Egg Egg Dun · Graipuss Medussi · Zebrino Pianino |
| **Desert** | Extinct Ballerina · Craburger · Rexino Ramino · Qamar Camelamp · La Grande Combinasion |
| **Arctic** | Frio Ninja · Ski Ski Skunki · Rockarino Rockara · Chill Puppy · **Yetimatic $87.5M/s** |
| **Cave** | Sammyni Spyderini · Pin Pin Pengu · Chicleteira Bicicleteira · Sir Mangus · **Draculino $120M/s** |
| **Aquatic** | Fishboard · Marino Submarino · Arcadopus · Swag Soda · **Capitano Moby $160M/s** |
| **Lava** | Ranito Pepito · To to to Sahur · Burrito Bat · Lavamanta · **Cerberus $175M/s** |
| **Heavenly** | Capibaro Celestino · Cupid Cupid Sahur · DJ Panda · Lionello Casarello · **Dragon Cannelloni $250M/s** |

المصدر: Steal a Brainrot Wiki — *Jump for Eggs LTM* (Update 68، 26/09/2026).

---

## 4. الرصد الحيّ (البيضات اللي تولّي من بعد)

```text
Workspace.DescendantAdded     -> كل أوبجكت جديد يتقيّم فوراً
Workspace.DescendantRemoving  -> البيضة المقطوفة/المختفية تتحيّد من القايمة
ProximityPromptService.PromptShown -> نسجّل كل برومبت نشوفو (يعرفنا شنو اسم
                                     «الالتقاط» الحقيقي فهاد الماب)
مسح سريع كل 1.0s              -> غير المجلدات اللي فيها بيضات
مسح شامل كل 25s              -> كامل الخريطة (أو اضغط DEEP SCAN NOW)
```

كل هادا مشروط بـ **Watch for new eggs (live scan)** و **Deep scan** من الواجهة،
وما يكلّفش بزاف: الفحص الشامل محدود بـ 60 ألف أوبجكت و700 تحليل لكل مرة.

---

## 5. شنو نعرضو فوق كل بيضة (ESP)

```text
   +-----------------------------+
   |      Dragon Cannelloni      |   الاسم — بلون الندرة، وسط
   |   [ SEC ]  Heavenly $250M/s |   شريحة التصنيف + الجزيرة + الدخل
   |        507m     1:45        |   المسافة + العدّاد التنازلي
   +-----------------------------+
```

- النص **وسط** فوق البيضة (`StudsOffset` حسب علو الأوبجكت).
- `MaxDistance = 6000` → تشوف البيضات اللي في الجزر العالية (بعيدة).
- `See eggs through walls` يخلي اللصاقة فوق كل شيء.
- خانة «ESP max distance» و«Label size» من تاب Settings.

---

## 6. الفرم: كيف يمشي للبيضة ويجيبها

```text
1) TRAVEL   طيران سلس (v2.3) بسرعة محدودة (~80 stud/s) باش السيرفر يقبل الحركة:
            يطلع للعلو (sky arc) → يقطع → يهبط فوق البيضة.
            noclip + PlatformStand باش ما تطيحش / ما تتضربش في جزيرة.
            anti-rubberband: إذا السيرفر رجّعك لنقطة الانطلاق، المسار هو المصدر
            وما نتبعوش الرجعة — نرجّعوك للمسار.
            hold على الوصول حتى السيرفر يشوفك عند البيضة.
            ما يقولش «وصلت» إلا إذا المسافة فعلاً صغيرة.
2) PICK UP  يجرّب بالترتيب: fireproximityprompt -> hold -> click detector
            -> يوقف فوقها (touch) -> (اختياري) remotes الاسم فيها collect
            ويكتب بالـ log أي طريقة نجحات
3) RETURN   يثبّتك بالهواء (Anchor) ما تطيحش، ثم يرجّعك للقاعدة
            (يلقاها من Workspace/<اسمك> أو Bases/Plots أو خاصية Owner
            أو RespawnLocation أو **SET BASE HERE**)
4) HATCH    يستنى الفقس ثم يزيد العدّاد ويرجع يدوّر على غيرها
```

إذا فشل السفر (السيرفر رجّعك): الفرم يوقف الالتقاط وما يحاولش يقبط من نقطة الانطلاق.
إذا فشل الالتقاط: يتخطّى البيضة 30 ثانية ويريّح (مانعاودش نفس البيضة للّانهاية).

### ليش كنت ترجع لنقطة الانطلاق؟

القفزات القديمة (60 stud كل 0.1s ≈ 600 stud/s، أو قفزة وحدة تحت 80m) السيرفر يرفضها
ويرجّعك لآخر مكان صحيح = نقطة انطلاقك. العميل يوريك تطير، بعدين «بوب» ترجع.
والالتقاط يفشل لأن السيرفر باقي يشوفك في القاعدة.

الحل: قسم **Teleport (anti snap-back)** — Mode = `smooth`، Fight snap-back = ON،
Hold still on arrival = ON، Noclip = ON. إذا باقي يرجع، خفّض السرعة لـ `slow 50`.

---

## 7. إذا باقي ما تلقى والو — خطة الإصلاح

1. تأكد أنك **داخل منطقة الـ LTM** (ادخل من البوابة).
2. اضغط **DEEP SCAN NOW** (يمسح الخريطة كاملة).
3. حسّن الحساسية على **loose**.
4. اكتب كلمة من اسم البيضة بخانة «extra keywords» (مثلاً `capsule`, `nest`, `pod`).
5. تاب **Diag** ← **BUILD FULL REPORT** ← **COPY** ← صيفطولي التقرير.
   التقرير فيه: شجرة الـ workspace، كل الأسماء اللي فيها «egg»، المجلدات،
   البرومبتات، الـ remotes، مكان القاعدة، وتحليل الرصد — نحطّو الأسماء الحقيقية ونولّي 100%.

---

## 8. 🆕 v2.2 — التنبيهات والجزر والـ AFK

### 🔔 تنبيه البيضات النادرة
أول ما بيضة ندرة فوق العتبة اللي ختارتها (الافتراضي: `Secret`) تتلاقى:
- إشعار Roblox (`SetCore`) — بمعدّل إشعار واحد كل 4 ثوانٍ باش ما يفيضوش،
- **toast** أسفل الشاشة بلون الندرة،
- سطر `<== RARE EGG` بالـ Activity log،
- وسطر دايم بالواجهة: `3 rare egg(s) seen • last: Dragon Cannelloni [Secret]`.

البيضة تتعلّم `alerted = true` → ما يتكرّرش التنبيه لنفس البيضة.

### 🗺️ الجزر
`Extras.findIslands()` يقلّب مستويين من الـ workspace ويطابق الأسماء مع
كلمات الجزيرة (`grass/desert/snow/cave/water/lava/heaven/candy...`)،
يرتبهم من الأسفل للأعلى، ويعطي لكل جزيرة لون + عدد البيضات اللي فيها.

### 🐇 AFK على الترامبولين
يدوّر على أي أوبجكت اسمو فيه `trampoline / treadmill / jump / train / gym / xp`،
يمشي ليها (`GO TRAIN`) ثم يشغّل قفز تلقائي كل `AfkJumpInterval` ثانية
(`Humanoid.Jump = true`) — يعني XP وأنت بعيد.

### 💾 الإعدادات المحفوظة
- الترميز: سطور `key=type=value` (number/boolean/string/table) — بلا مكتبات خارجية.
- الملف: `SaBSuite/settings.txt` (يستعمل `writefile/readfile/isfile` حق الـ executor).
- عند التحميل نقبل غير المفاتيح الموجودة أصلاً وبنفس النوع (أمان).
