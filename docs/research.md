# 🔬 أبحاث السكريبت — Steal a Brainrot (لـ Delta Executor)

> آخر تحديث للمعلومات: **29 سبتمبر 2026**
> المصادر: Steal a Brainrot Wiki (Fandom)، مواقع إخبارية، وتوثيق المجتمع.

---

## 1️⃣ نظرة عامة على اللعبة

| العنصر | التفصيل |
|---|---|
| المطوّر | Brazilian Spyder (**Sammy / SpyderSammy**) |
| نوع اللعبة | collecting + stealing + economy |
| الحلقة الأساسية | تشتري Brainrots من السجادة الحمرا (Red Carpet) → تنتج فلوس/ثانية داخل قاعدتك → تسرق من اللاعبين → Rebirth لمضاعفات دائمة |
| البداية | 100$ + سلاح أساسي (Tung Bat) + **قاعدتك مقفولة 30 ثانية** أول ما تدخل |
| القواعد | 8 قواعد بالخريطة، بوابات ليزر حمرا |
| الريبيرث | حتى Rebirth 19 (أُضيفت بـ Update 61/62 — 15 أغسطس 2026) |
| الـ Secrets | 270+ Secret حالياً (أغسطس 2026)، أقواهم Griffin (~$400M/s) |
| التحديثات | **كل سبت تقريباً**. التالي: **Update 69 — 3 أكتوبر 2026 (Haunted Fuse + mutation جديدة)** |

### 🛡️ أنظمة الحماية (مهمة لفهم السرقة)
- **Base Lock:** 60 ثانية حماية + **10 ثواني/ريبيرث** + 10 ثواني إضافية (VIP gamepass).
- **بوابات الليزر:** وقت القفل بس صاحب القاعدة (وأصدقاؤه عبر **Friend Controller**) يعدّي.
- **عند السرقة:** سرعتك تنزل بشكل كبير + أدواتك تتعطل + صاحب القاعدى يتبلّغ + أي لاعب يضربك يرجع الـ brainrot لقاعدته.
- **أدوات الدفاع:** Traps, Alarms, Sentries, Turrets, و**Grief Shield** (Rebirth 19 — يمتص ضربة من لاعب ثالث، **بس ما يحميك من صاحب الـ brainrot**).

---

## 2️⃣ 🔥 التحديث الأخير: Update 68 — "Jump for Eggs LTM"

**تاريخ الإصدار:** 26 سبتمبر 2026، 3:00 PM EST
**المصدر:** https://stealabrainrot.fandom.com/wiki/Jump_for_Eggs_LTM

### شنو هو؟
LTM (وضع محدود الوقت) **جوّه** لعبة Steal a Brainrot، مستوحى من لعبة **"Steal an Egg"** المستقلة (نفس المطوّر). اللاعبون **يقفزون بين الجزر** لجمع **البيضات (Eggs)**، والبيضة تفحص (hatch) مثل الـ Lucky Block وتعطيك الـ brainrot مباشرة بقاعدتك.

### الدخول
عبر **بوابة/Portal** تنقلك لمنطقة الـ LTM (حسب وصفك يا صاح — تجد فيه أشياءك). ⚠️ يحتاج تأكيد inside-game (اسم البوابة وشكلها).

### الحلقة الأساسية (Gameplay Loop)
1. **التدريب على الترامبولين (Treadmill/Trampoline)** قرب القاعدة → تكسب **XP**.
2. كل ما يزيد مستواك (Level) → تفتح **جزر أعلى وأبعد**.
3. للوصول للسحاب: **الترامبولين الكبير بنص الخريطة** أو القفز العادي.
4. تهبط على جزيرة → تجمع البيضات (لها **مؤقّت تنازلي** — تختفي إذا ما أسرعت).
5. تحمل البيضة وترجّعها **لقاعدتك**.
6. البيضة **تفحص** → الـ brainrot يضاف مباشرة لقاعدتك.
7. **أعلى جزيرة = brainrots أندر**.

### 🌟 الميزة الذهبية للسكريبت: آلة الـ AFK
آلة تجعلك تأخذ **قفزات متتالية تلقائية** لتقفز بين السحاب وتوصل للجزر (حسب وصفك). عملياً: آلية القفز التلقائي/XP هذي هي اللي راح نبني عليها الأوتوفارم.

> ✅ **تحديث 29 سبتمبر 2026:** هاد الجدول تحقّقنا منو من الويكي صفحة صفحة،
> وصار **محطوط حرفياً** داخل السكريبت في `src/modules/02_EggDB.lua`
> (35 بيضة: الاسم + الندرة + الجزيرة + الدخل/ثانية). يعني السكريبت يعرف البيضة
> حتى لو الأوبجكت ما عندو حتى خاصية — من اسمو برك.

### 🏝️ الجزر ومحتوى البيض (7 جزر × 5 بيضات)

#### 🟩 Grass/Starter
| البيضة | الاسم | الندرة | الدخل |
|---|---|---|---|
| 1 | Cavallo Virtuoso | Mythic | $7.5K/s (T1) |
| 2 | Tartaruga Cisterna | Brainrot God | $250K/s (T1) |
| 3 | Eggdin Egg Egg Dun | Brainrot God | $310K/s (T1) |
| 4 | **Graipuss Medussi** | Secret | $1M/s (T1) ← أكثر Secret شيوعاً |
| 5 | Zebrino Pianino | Secret | $7.2M/s (T2) |

#### 🟨 Desert
| البيضة | الاسم | الندرة | الدخل |
|---|---|---|---|
| 1 | Extinct Ballerina | Brainrot God | $125K/s (T1) |
| 2 | Craburger | Secret | $1.3M/s (T1) |
| 3 | Rexino Ramino | Secret | $2.6M/s (T2) |
| 4 | Qamar Camelamp | Secret | $3.3M/s (T2) |
| 5 | La Grande Combinasion | Secret | $10M/s (T2) |

#### 🟦 Arctic
| البيضة | الاسم | الندرة | الدخل |
|---|---|---|---|
| 1 | Frio Ninja | Brainrot God | $265K/s (T1) |
| 2 | Ski Ski Skunki | Secret | $1.6M/s (T2) |
| 3 | Rockarino Rockara | Secret | $3M/s (T2) |
| 4 | Chill Puppy | Secret | $4M/s (T2) |
| 5 | Yetimatic | Secret | $87.5M/s (T3) |

#### 🟫 Cave
| البيضة | الاسم | الندرة | الدخل |
|---|---|---|---|
| 1 | Sammyni Spyderini | Secret | $330K/s (T1) |
| 2 | Pin Pin Pengu | Secret | $2.3M/s (T2) |
| 3 | Chicleteira Bicicleteira | Secret | $3.5M/s (T2) |
| 4 | Sir Mangus | Secret | $7.5M/s (T3) |
| 5 | Draculino | Secret | $120M/s (T4) |

#### 🟥 Lava
| البيضة | الاسم | الندرة | الدخل |
|---|---|---|---|
| 1 | Ranito Pepito | Secret | $950K/s (T1) |
| 2 | To to to Sahur | Secret | $2.25M/s (T2) |
| 3 | Burrito Bat | Secret | $7M/s (T2) |
| 4 | Lavamanta | Secret | $28.5M/s (T3) |
| 5 | Cerberus | Secret | $175M/s (T4) |

#### 🌊 Aquatic
| البيضة | الاسم | الندرة | الدخل |
|---|---|---|---|
| 1 | Fishboard | Secret | $825K/s (T1) |
| 2 | Marino Submarino | Secret | $3.6M/s (T2) |
| 3 | Arcadopus | Secret | $5M/s (T2) |
| 4 | Swag Soda | Secret | $13M/s (T3) |
| 5 | Capitano Moby | Secret | $160M/s (T4) |

#### ☁️ Heavenly (الأعلى)
| البيضة | الاسم | الندرة | الدخل |
|---|---|---|---|
| 1 | Capibaro Celestino | Secret | $1.7M/s (T1) |
| 2 | Cupid Cupid Sahur | Secret | $3.1M/s (T2) |
| 3 | DJ Panda | Secret | $17.5M/s (T3) |
| 4 | Lionello Casarello | Secret | $58.5M/s (T3) |
| 5 | **Dragon Cannelloni** | Secret | $250M/s (T4) |

### 🆕 Brainrots جديدة بالتحديث
Ranito Pepito ($950K/s) · Capibaro Celestino ($1.7M/s) · Pin Pin Pengu ($2.3M/s) · Rexino Ramino ($2.6M/s) · Rockarino Rockara ($3M/s) · Qamar Camelamp ($3.3M/s) · Marino Submarino ($3.6M/s) · Lavamanta ($28.5M/s) · Lionello Casarello ($58.5M/s) · Draculino ($120M/s)

### 📌 حقائق مثيرة للاهتمام
- **Graipuss Medussi** هو أكثر Secret يظهر (جزيرة Grass أو من SpyderSammy).
- اللعبة "أعادت شراء" بيرهروتات كانت نادرة (Extinct Ballerina, Eggdin Egg Egg Dun, Craburger, Chill Puppy, Frio Ninja, Cupid Cupid Sahur, Yetimatic, Swag Soda) — صار غضب بالمجتمع.
- بحجم قاعدتك بالـ LTM: الـ brainrots تكبر/تصغر حسب الندرة.
- **بداية الحدث:** 26 سبتمبر 2026 — **النهاية: TBA (ساري حالياً)**.

### 🎮 اللعبة الأصلية: Steal an Egg (مصدر الإلهام) — معلومات تقنية مهمة
الـ LTM ماخوذ من لعبة ثانية لنفس المطوّر، وفهم ميكانيكتها يعطينا أفكار للفرم:

| الميكانيكية | التفاصيل | كيف يستفاد منها السكريبت |
|---|---|---|
| **الأعشاش (nests)** | البيض يولّي في أعشاش موزّعة على مناطق (biomes) | نراقب المجلدات اللي أسماؤها `Nest/Eggs/Spawns` |
| **إعادة التعيين** | البيض يتجدّد كل **5 دقائق** (و«ليلة» كل 4.5 دقيقة بالنسخة الأولى) | نقرا العدّاد التنازلي من الخصائص (`TimeLeft/Despawn`) ونعرضو فوق البيضة |
| **البيضة عالمية** | أول ما واحد يقبطها، **تختفي من كل السيرفرات** | نعتبر «البيضة اختفات = تقبطت» (هادي إشارة نجاح إضافية غير فحص الحمل) |
| **الحمل الفيزيائي** | لازم ترجّعها لقاعدتك بيدك، وتموت = تضيع | التيليبورت التدريجي + التثبيت بالهواء (Anchor) باش ما تطيحش |
| **حرّاس (guardian beasts)** | وحوش تحرس الأعشاش | خيارات: تخطّي البيضة بعد فشل (cooldown 30s) |
| ** teleport tricks** | اللاعبون يتهربو من التليبورت الإجباري بـ jump/طفي الواي فاي | ما يهمنا — التيليبورت مالنا يخدم بـ CFrame |

المصادر: [IGN — All Pets](https://www.ign.com/wikis/steal-an-egg-roblox/All_Pets) ·
[allthings.how](https://allthings.how/steal-an-egg-every-hidden-secret-worth-knowing-roblox/) ·
[Steal an Egg wiki](https://stealanegg.fandom.com/wiki/Eggs_%26_pet)

### 📖 سابقة مشابهة ( Egg Hunt — أبريل 2026 )
نفس الميكانيكية بالضبط: جزر + شراء double jumps + بيض بمؤقّت + ترجّعها لقاعدتك + تفحص. المصدر: TechWiser guide.

---

## 3️⃣ ⚡ ملاحظات تقنية عن Delta

- النمط: `loadstring(game:HttpGet("URL"))()`
- لغة **Luau** قياسية + سینتابس Synapse (`getobjects`, `fireproximityprompt`, `hookmetamethod`, إلخ).
- ⚠️ **صور الـ ESP:** Roblox ما يحمّل روابط خارجية بـ `ImageLabel.Image` — لازم `rbxassetid`. الحلول الممكنة:
  1. استخدام **أيقونات اللعبة نفسها** (نتأكد منها لما نفكّ مجلدات اللعبة — غالباً icons لكل brainrot موجودة بـ ReplicatedStorage).
  2. إذا مو موجودة → نعرض **أسماء + ألوان حسب الندرة** بدل الصور (fallback).
  3. رفع أيقونات خاصة فينا (270+ صورة — كثير، يُستخدم فقط للأهم).

## 4️⃣ ❓ ألغاز تقنية — الحل الجاهز: تاب **Diag**
بدل ما نسوّل الأسئلة برك، السكريبت ولاّ **يجاوب عليها وحدو**:

| السؤال | كيف السكريبت يلقى الجواب وحدو |
|---|---|
| أسماء objects البيض؟ | 7 استراتيجيات رصد (شوف `docs/egg-detection.md`) + تقرير يعرض كل أسماء الأوبجكتات |
| طريقة الالتقاط؟ | يجرّب `fireproximityprompt` → `InputHold` → `ClickDetector` → `Touch` → `Remote`، ويكتب أي وحدة خدمات |
| إشارة النجاح؟ | يفحص الحمل (character/player) **و** اختفاء البيضة من الخريطة |
| وين القاعدة؟ | `Workspace/<اسمك>` · `Bases/Plots` · خاصية `Owner/OwnerId` · `RespawnLocation` · أو **SET BASE HERE** |
| شنو الـ remotes؟ | تاب Diag يعرض كل remote اسمو فيه collect/pick/egg/hatch |
| شنو البرومبتات؟ | `ProximityPromptService.PromptShown` يسجّل كل برومبت تشوفو بمسارو الكامل |

**باقي علينا غير حاجة وحدة:** الأسماء التقنية الحقيقية — تجينا بتقرير الـ Diag
(نسخ/حفظ) ونحطّها في قاعدة البيانات → الرصد يولّي 100%.

---

## 5️⃣ 🗺️ خطة المشروع

| المرحلة | الوصف | الحالة |
|---|---|---|
| **0 — البحث** | جمع معلومات عن الماب، الحماية، وآخر تحديث | ✅ شبه مكتملة |
| **1 — الاستكشاف** | استكشاف شجرة الـ objects — صار **آلي** (تاب Diag + 7 استراتيجيات رصد) | ✅ v2.1 |
| **2 — الهيكل** | سكربت مقسّم 9 وحدات + واجهة مخصّصة (موبايل/كمبيوتر) + أداة بناء + اختبارات | ✅ v2.1 |
| **3 — الميزة الأولى** | **Egg ESP ملوّن + رصد عميق + تصفيات + تيليبورت تدريجي + إرجاع للقاعدة** | ✅ v2.1 |
| **4 — الميزة الثانية** | **🎯 Code Sniper** (تفصيلها بالقسم 6) | ✅ v1 → محسّنة v2.1 |
| **5 — الصقل** | اختبارات آلية (84 فحص) + حماية من الأخطاء + تحديث أسبوعي (Update 69 — 3 أكتوبر) | 🔄 مستمر |

### 🧪 الاختبارات الآلية (جديدة في v2.1)
```bash
pip install lupa
python3 tests/run_tests.py         # 36 فحص: قاعدة البيانات، التصنيف، الأدوات
python3 tests/run_world_tests.py   # 48 فحص: عالم Roblox وهمي (رصد/تصفية/ESP/فرم/واجهة)
```
الاختبار الثاني يبني خريطة وهمية فيها 4 بيضات و3 فخاخ، يشغّل **الملف الحقيقي**،
ويتأكد أنو: لقى البيضات وتجاهل الفخاخ والجزر، صنّف الندرة والجزيرة، ركّب اللصاقات
بألوانها، لقى بيضة تولّات من بعد، تليبورتا وقبطها ورجّعها، والتصغير يخدم.

---

## 6️⃣ 🎯 الميزة الثانية: Code Sniper (أكواد الـ Admin Abuse)

### ⏰ مواعيد الـ Admin Abuse (مهمة للاختبار!)
| الحدث | الوقت | المدة |
|---|---|---|
| **Taco Tuesday** | كل **ثلاثاء 6:00 PM ET** | 30–45 دقيقة |
| **Saturday Update** | كل **سبت 3:00 PM ET** | 30–45 دقيقة |

- يصير على **كل السيرفرات بنفس الوقت** (حتى الخاصة).
- Sammy (**SpyderSammy**) يتكلم بالشات ويعمل challenges + giveaways + **يقول الأكواد**: "code is: XXXXX".

### 🖥️ نظام الأكواد باللعبة (الواجهة)
| العنصر | التفصيل |
|---|---|
| زر الأكواد | **"Codes" button على يسار الشاشة** (أُضيف 13 يونيو 2026) |
| صندوق النص | placeholder: **"Code Here..."** |
| زر الاستلام | **"Submit"** (أو ضغط Enter) |
| حساسية الأحرف | **غير حساسة** (codes are NOT case-sensitive) |
| مسار قديم (قبل يونيو 2026) | Shop → آخر القائمة → Redeem Codes |

### 📜 أمثلة على أكواد حقيقية
- `BESTBRAINROTEVER` → La Vacca Saturno Saturnita (يظهر بالسجادة الحمرا، يكلف $80M شراء، يظهر مرة وحدة!)
- `saturn`, `FREEOCTOBLOCK777`, `FREE500DRAGS`, `JOHNPORKDAPIGGY`, `CODESAREREAL321`, `L2EXPLOITERS` (انتهت)
- أكواد الـ Admin Abuse: `BRAINSUPER`, `ADMINSTEAL`, `TACOBOOST`

### 🔧 التقنية المطلوبة للقناص
1. **الكشف (أهم جزء):**
   - `TextChatService.MessageReceived` (الشات الحديث — يعمل client-side بالـ executors).
   - كل رسالة تجيك كـ `TextChatMessage` فيها: `.Text` (النص)، `.TextSource` (فيه `UserId` و`Name`)، `.PrefixText`.
   - fallback قديم: `Player.Chatted` إذا اللعبة تستخدم الشات القديم.
2. **التحليل:** Regex على النمط: `code%s+is%s*:?%s*([%w_%-%d]+)` — والأنماط البديلة ("the code is", "use code", "code:").
3. **الاستلام السريع — ترتيب السرعة:**
   - ⚡ **الأسرع:** fire الـ Remote مباشرة (بدون UI) — راح نلاقي اسمه بالاستكشاف (غالباً داخل `ReplicatedStorage.Remotes`).
   - 🐢 أبطأ: نكتب نص بالـ TextBox ونضغط زر Submit.
   - 💡 **القناص يتغلب على الإنسان بسهولة:** MessageReceived يشتغل لحظة وصول الرسالة، والـ remote round-trip وحدة.
4. **الحماية المطلوبة:**
   - **فلترة باسم Sammy** (مهم جداً!) — الناس يكدرون يكتبون أكواد مزيفة بالشات ليخربون محاولاتك.
   - منع تكرار نفس الكود (codes one-time-use).
   - معالجة ردود اللعبة: "invalid" / "already redeemed" بدون ما يطيح السكريبت.
   - ⚠️ **تنبيه:** إذا فلتر الشات (####) خبّى الكود، ما نكدر نرجّعه — بس أكواد UPPERCASE العادية تمرّ عادة.

### 💡 فكرة ذكية: التكامل
القناص يشتغل **بالخلفية دايماً** بينما الميزة الأولى (AFK بيضات) تشتغل — يعني وأنت تفلّه بالبيضات، أي كود ينزل بالأدمن أبوس يُصاد فوراً.

### 📣 كيف يعلن Sammy الأكواد فعلياً (الأنماط اللي لازم نغطيها)
| النمط | مثال | الملاحظة |
|---|---|---|
| كود كامل برسالة | `code is: BESTBRAINROTEVER` | الأسهل — نفصّه من نفس الرسالة |
| **تهجئة حرف حرف** | "code is" → "B" → "E" → "S" → "T" | **الأخطر** — يحتاج تجميع تدريجي |
| كلمتين (ملصوقة/بمسافة) | `TACOBOOST` أو `TACO BOOST` | نجرب الاتنين |
| ثلاث كلمات | `SUPER TACO BOOST` | — |
| كلمتين + 3 أرقام | `TACO123` / `TACO 123` | — |
| أرقام بالكلمات | "TACO ONE TWO THREE" | نحوّل one→1, two→2... |
| حروف مكرّرة | "double S" | → SS |

### 🛡️⚠️ مضادات Sammy (مهم تعرفها!)
من صفحة الأكواد بالويكي:
- **27–30 يونيو 2026:** Sammy **أوقف الأكواد** خلال الـ Admin Abuse **بسبب الـ exploiters**.
- **حظر مجموعة** كانت تستخدم **AI لسرقة الأكواد**، وعمل كود `L2EXPLOITERS` سخرة منهم.
- **التهجئة حرف حرف على الأغلب هي countermeasure ضد القناصة** (تصعب الالتقاط الآلي).
- الطلب على الأكواد بالأدمن أبوس عالي جداً (اللاعبون يسبامون Sammy بالديسكورد).

> 🔴 **صراحة:** Sammy حظر قناصة أكواد سابقاً — فيه risk بان حقيقي. القناص راح يكون سريع، بس القرار قرارك وأنا وضّحتلك.

### 🎯 مواصفات الميزة الثانية (النهائية — حسب طلبك)
- Sammy يعلن الكود **كلمة كلمة** (مش حرف حرف).
- **أنت تفتح خانة الأكواد بنفسك** — السكريبت **يكتب الكود فيها** (يملأ الـ TextBox).
- القناص يشتغل **بالخلفية 24/7** (حتى وقت الميزة الأولى).
- ✅ **الكتابة التدريجية (Progressive Write):** كل ما توصل كلمة جديدة من Sammy → السكريبت يحدّث نص الـ TextBox فوراً بأفضل مرشح. يعني لو تأخرت بفتح الخانة، النص يكون جاهز ومتكامل.
- 💡 إذا الخانة مو مفتوحة بعد → السكريبت يخزّن المرشح، ولما تظهر (ChildAdded) يكتبها فوراً.
- 🔜 اختياري لاحقاً: ضغط "Submit" تلقائي (toggle) — حالياً أنت تضغطه.

### 🪪 هوية Sammy (لفلترة القناص — مصدر موثوق)
| العنصر | القيمة |
|---|---|
| Username | **SpyderSammy** |
| Display name | Sammy |
| **Roblox UserId** | **2678001507** |
| Community | BRAZILIAN SPYDER (مع do_small) |

> 💡 القناص يفلتر بـ `TextSource.UserId == 2678001507` — مستحيل أحد ينتحل الكود (الفلترة بالـ UserId أقوى من الاسم).

### 🧠 تصميم منطق تجميع الكود (Word-by-Word Accumulator)
```
1. فلترة المرسل: بس رسائل Sammy (بالاسم/UserId)
2. كاشف البداية: أي رسالة فيها "code" → ندخل وضع التجميع
3. وضع التجميع: كل رسالة جديدة من Sammy تُحلَّل (كل رسالة = عادة كلمة وحدة):
   • كلمة alphanumeric قصيرة (TACO, BOOST, 123) → تُضاف للمرشح
   • كلمة رقم (one..nine, zero) → تُحوَّل لرقم وتُضاف
   • "double X" → تُضاف XX
   • حرف وحيد (A-Z) أو رقم وحيد → يُضاف (fallback لو تهجّى أحياناً)
   • كلام طويل/عادي (جملة فيها مسافات وكلمات كثيرة) → يُتجاهل
   • رسالة جديدة فيها "code" → نبدأ تجميع جديد (كود ثاني)
4. بناء المرشحين: نسخة ملصوقة (TACOBOOST) + نسخة بمسافات (TACO BOOST)
5. إشارة النهاية: صمت 8–10 ثواني من Sammy، أو كلمة مثل "go"/"done"، أو تغيّر الموضوع
6. التحقق: المرشح يطابق ^[A-Z0-9]+$ وطوله 3–30
7. الكتابة: نكتب المرشح بالـ TextBox فوراً (تدريجياً) — بدل fire الـ Remote
8. الحماية: جدول الأكواد المكتوبة (منع التكرار) + تجاهل الأكواد المزيفة من غير Sammy
```

---

## 7️⃣ 🏆 تحليل سكريبتات الناس المشهورة (سبتمبر 2026)

### أشهر الهَبّات على الماب
| الهَب | أشهر ميزاته |
|---|---|
| **Chilli Hub** | Instant Steals, Speed Boosts, Infinite Money, Anti-steal |
| **Echo Hub** | Noclip, Auto Buy, Auto Lock Base |
| **ReyHub** | Auto Steal, Auto Floor, Auto Hit, ESP |
| **Ajjan Hub** | Instant Steal, Inf Jump, NoClip, Auto Base Lock |
| **QuantumPulsar X** | Auto Sell, Auto Steal, Base Protection, ESP |
| **Gumanba (MODDED)** | Instant Steal, Easy Cash, Teleport, Speed, Godmode, Remove Walls |
| **Ronix Hub** | Auto Farm, NoClip, INSTANT STEAL SPEED, Anti Kick |
| **Feronik Hub** | Auto Lock, Instant Steal, Auto Buy, Auto Rebirth |
| **Hulk Hub** | Invisible, Trade Freeze, AutoFarm |
| **Express Hub** | Brainrot Spawner, Instant Steal, Anti Hit, Desync |
| **Lemon Hub** | Instant Steal, Brainrot Spawner, Invisible, Anti-Hit |
| **Rift Hub** | Win Every Duel, Instant Steal, Desync |
| **ZZZZ Hub** | Auto Steal, Quick Toggle, Hub UI |
| **Moondiety / Moon Hub** | Speed Boost, God Mode, Auto Farm, ESP |
| **Ghost Hub** | Auto Lock, Wall Hacks, Teleport |
| **AV-On-Top** | Auto Farm |
| **CryoNova** | Auto Lock Base, Auto Steal |

### 🔘 الأزرار/الميزات القياسية (موجودة بكل سكريبت تقريباً)
| الفئة | الأزرار |
|---|---|
| **سرقة** | Auto Steal · **Instant Steal** · Auto Steal Target |
| **فارم** | Auto Farm · Auto Collect Cash · Auto Buy · Auto Rebirth |
| **حماية** | Auto Lock Base · Anti-Hit · Anti-Ragdoll · Invisible · Desync |
| **ESP** | Brainrot ESP · Player ESP · **Rarity ESP** · **Lock ESP (مؤقّت القفل)** · Base ESP |
| **حركة** | Speed · Jump/Inf Jump · Fly · NoClip |
| **تيليبورت** | Teleport to Base · to Brainrot · to Player |
| **متنوعة** | Server Hop · Anti-AFK · Anti-Kick · Low Graphics · UI Toggle · Win Duels · Brainrot Spawner |

### 📊 مقارنة سكريبتنا (`src/StealABrainrot.lua`) بالمنافسين
| الميزة | المنافسون | سكريبتنا |
|---|---|---|
| 🎯 **Code Sniper (أكواد الأدمن أبوس)** | ❌ **ما عندهم** | ✅ **عندنا (فريد!)** |
| 🥚 **Egg System (Jump for Eggs LTM)** | ❌ **ما عندهم** (LTM جديد) | ✅ **عندنا (فريد!)** |
| ESP بالصور + تصفية + فرم | ⚠️ ESP عادي | ✅ ✅ ✅ |
| واجهة موبايل (تنزّل/تتصغر/تتغلق) | ✅ | ✅ |
| وضع اختبار للقناص | ❌ | ✅ |
| Auto Steal / Instant Steal | ✅ | ❌ |
| Auto Collect Cash / Auto Buy | ✅ | ❌ |
| Auto Lock Base | ✅ | ❌ |
| Auto Rebirth | ✅ | ❌ |
| Player ESP / Lock ESP | ✅ | ❌ |
| Speed / Fly / NoClip / Inf Jump | ✅ | ❌ |
| Teleports (Base/Brainrot/Player) | ✅ | ❌ |
| Server Hop / Anti-AFK | ✅ | ❌ |
| Explorer (استكشاف المسارات) | ❌ | ✅ |

### 💡 الخلاصة
**نقاط قوتنا الفريدة:** القناص + نظام البيضات (أحدث LTM) — ما ي coveredها المنافسون.
**اللي ناقصنا:** الميزات "القياسية" اللي يتوقعها أي مستخدم (Auto Steal, Auto Collect, Auto Lock, ESP اللاعبين, Speed/Fly/Noclip, Teleports).

---

## 8️⃣ 🎯 مواصفات القناص النهائية (حسب طلبك)

### متطلباتك
1. **أكواد كثيرة عبر الوقت** — Sammy يقدر يحط كود كل ربع ساعة بمدة محددة → القناص يبقى شغال 24/7 ويصيد كل كود جديد (مع منع تكرار نفس الكود).
2. **أشكال عديدة للأكواد** — بدون أرقام، كلمتين، كلمتين+رقم، ثلاث كلمات... إلخ.
3. **Sammy يقول النوع قبل الكود** → السكريبت يفهم النوع من كلام Sammy تلقائياً.
4. **تختار النوت بالسكريبت** → قائمة أنواع جاهزة.
5. **زر "بدا" (START)** → تضغطه لما يبدأ Sammy يقول الكود → يكتب فوراً وبسرعة.

### الأنواع المدعومة (7)
`Any (auto)` · `Letters only` · `Two words` · `Two words + number` · `Three words` · `Three words + number` · `With numbers (any)`

### كيف يفهم النوع من كلام Sammy
| يقول Sammy | يفهم السكريبت |
|---|---|
| "the code is **two words**" | words=2 |
| "**three words**" | words=3 |
| "**letters only**" | digits=false |
| "**letters and numbers**" | digits=true |
| "**two words** and a **number**" | words=2 + digits |
| "code is two words: TACO BOOST" | يضبط النوع + يجمع الكود من نفس الرسالة |

### السرعة (مهم!)
- **الكتابة التدريجية:** كل كلمة توصل → الخانة تتحدّث فوراً.
- **الإنهاء الفوري:** إذا النوع معروف (مثلاً "كلمتين") → لما توصل الكلمة الثانية ينهي ويكتب **حالاً** بدون ما يستنى Silence Timeout. ⚡
- **صياغة الكود:** JOINED (`TACOBOOST`) أو SPACED (`TACO BOOST`) — خيار بالسكريبت.

### الأزرار بصفحة Code Sniper
| الزر | الوظيفة |
|---|---|
| Type: … | يدور على الـ 7 أنواع |
| Format: … | JOINED / SPACED |
| ▶ START capturing (بدا) | يبدأ الالتقاط فوراً (يدوياً) |
| ■ STOP capturing | ينهي ويحفظ |
| 1) Feed this word | اختبار: تغذي كلمة |
| 2) Start session (marker) | اختبار: يبدأ بوضع التجميع |
| 3) DEMO: two words | اختبار تلقائي: "two words" → TACO → BOOST |
| 3b) DEMO: words + numbers | اختبار تلقائي: "letters and numbers" → TACO → BOOST → 123 |
| 4) Force finish now | إنهاء فوري |

---

## 9️⃣ 📜 سجل التغييرات

### v2.1.0 — «الرصد» (29 سبتمبر 2026)
- 🥚 **رصد جديد كلياً**: 7 استراتيجيات + نظام نقاط + عتبة حساسية (عادي/واسع/صارم).
- 📚 **قاعدة بيانات 35 بيضة** (7 جزر × 5) بالاسم + الندرة + الجزيرة + الدخل.
- 👀 **رصد حيّ**: `DescendantAdded/Removing` + `PromptShown` + مسح سريع (1s) وشامل (25s).
- 🏷️ **ESP واضح**: اسم بلون الندرة + شريحة التصنيف + الجزيرة + المسافة + عدّاد تنازلي، والنص وسط.
- 🎛️ **قسم Filters** باين دايماً: الندرة، الجزيرة، البحث، المسافة، إخفاء المجهول، تخطّي الفاشل.
- 🤖 **فرم يخدم فعلاً**: تيليبورت تدريجي + تثبيت بالهواء + 5 طرق التقطاط + تسجيل الطريقة الناجحة.
- 🪟 **إصلاح زر التصغير**: جسم النافذة في إطار واحد + دعم لمس الموبايل (debounce).
- 🔬 **تاب Diag**: تقرير كامل (شجرة، أسماء، برومبتات، remotes، قاعدة) مع نسخ/حفظ.
- 🧪 **84 اختبار آلي** (وحدات + عالم وهمي) و`tools/build.py` يجمع الوحدات في ملف واحد.

### v1.0.0 — أول نسخة
- Egg ESP بالاسم + الندرة + صورة، تصفية بالاسم، فرم بسيط، Code Sniper كامل مع وضع اختبار.
