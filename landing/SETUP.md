# ربط فورم الإيميل بـ Google Sheets

الهدف: كل واحد بيحط إيميله بالموقع، بينزل تلقائياً بجدول Google Sheets عندك.
الوقت المطلوب: ~١٠ دقايق، مرة وحدة بس.

---

## الخطوة ١ — اعمل الجدول

1. افتح **https://sheets.google.com** وسجّل دخول بحساب Gmail تبعك.
2. اضغط **Blank spreadsheet** (جدول فاضي).
3. سمّي الملف من فوق: `SHOTO Waitlist`.
4. تحت بالأسفل، في تاب اسمه `Sheet1` — اضغط عليه دبل كليك وغيّر الاسم لـ **`Waitlist`** بالضبط (حرف W كبير).
5. بالصف الأول اكتب العناوين:

   | A1 | B1 | C1 |
   |----|----|----|
   | Date | Email | Source |

---

## الخطوة ٢ — ضيف السكربت

1. من القائمة فوق: **Extensions** ← **Apps Script**.
2. رح تفتح صفحة جديدة فيها كود `function myFunction() {}` — **امسح كل شي** فيها.
3. الصق هالكود كامل مكانه:

```javascript
const SHEET_NAME = 'Waitlist';

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(20000);

  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_NAME) || ss.getSheets()[0];

    const email = String(e.parameter.email || '').trim().toLowerCase();

    // فخ السبام: البوتات بتعبي هالحقل، البشر ما بيشوفوه أصلاً
    if (e.parameter.company) return json({ ok: true });

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) {
      return json({ ok: false, error: 'invalid email' });
    }

    // ما نكرر نفس الإيميل مرتين
    const last = sheet.getLastRow();
    if (last > 1) {
      const existing = sheet.getRange(2, 2, last - 1, 1).getValues().flat();
      if (existing.indexOf(email) !== -1) return json({ ok: true, dup: true });
    }

    sheet.appendRow([new Date(), email]);
    return json({ ok: true });

  } catch (err) {
    return json({ ok: false, error: String(err) });
  } finally {
    lock.releaseLock();
  }
}

function json(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
```

4. اضغط أيقونة **الحفظ** (💾) فوق.

---

## الخطوة ٣ — انشر السكربت

1. فوق على اليمين اضغط **Deploy** ← **New deployment**.
2. جنب كلمة "Select type" في أيقونة ترس ⚙️ — اضغطها واختار **Web app**.
3. عبّي هيك:
   - **Description:** `shoto waitlist`
   - **Execute as:** `Me (your@gmail.com)`
   - **Who has access:** **`Anyone`** ← ⚠️ مهم جداً، لازم تكون `Anyone` مش `Anyone with Google account`
4. اضغط **Deploy**.
5. رح يطلب صلاحيات أول مرة:
   - **Authorize access** ← اختار حسابك
   - رح تطلع شاشة تحذير "Google hasn't verified this app" — هاد طبيعي لأنه سكربتك انت
   - اضغط **Advanced** ← **Go to SHOTO Waitlist (unsafe)** ← **Allow**
6. رح يعطيك رابط شكله هيك:

   ```
   https://script.google.com/macros/s/AKfycbxXXXXXXXXXXXXXXXXXXXXX/exec
   ```

   **انسخه.**

---

## الخطوة ٤ — حطّه بالموقع

افتح `index.html`، دوّر على هالسطر (قريب من آخر الملف):

```javascript
const ACTION = "";
```

وحط الرابط بين علامتين التنصيص:

```javascript
const ACTION = "https://script.google.com/macros/s/AKfycbxXXXX.../exec";
```

احفظ. **خلص.**

---

## الخطوة ٥ — جرّب

1. افتح الموقع، حط إيميل تجريبي واضغط الزر.
2. ارجع للجدول — لازم يظهر سطر جديد بالتاريخ والإيميل.

إذا ما ظهر، شوف قسم "لو ما اشتغل" تحت.

---

## معلومات مفيدة

**وين بتشوف الإيميلات؟**
بتفتح الجدول من `sheets.google.com` أو من تطبيق Google Sheets على موبايلك، أي وقت.

**عمود Source شو فايدته؟**
بيحكيلك الشخص سجّل من فورم الهيرو (`hero`) ولا من الفورم يلي تحت (`footer`) — هيك بتعرف أي مكان بيشتغل أحسن.

**كيف بنزّل الإيميلات كلها؟**
من الجدول: **File** ← **Download** ← **CSV** — وبتقدر ترفعه لأي خدمة إيميل جماعي وقت الإطلاق.

**التكرار:** لو نفس الشخص سجّل مرتين، السكربت بيتجاهل الثانية تلقائياً.

**السبام:** في حقل مخفي بالفورم اسمه `company`. البوتات بتعبيه أوتوماتيك، والبشر ما بيشوفوه. لو انعبى، السكربت بيتجاهل الطلب.

---

## ⚠️ مهم — لما تعدّل السكربت لاحقاً

إذا غيّرت أي إشي بكود الـApps Script، **لازم تعمل Deploy جديد** وإلا التعديل ما بينطبق:

**Deploy** ← **Manage deployments** ← أيقونة القلم ✏️ ← **Version: New version** ← **Deploy**

(الرابط بيضل نفسه، ما بتحتاج تغيّره بالموقع.)

---

## لو ما اشتغل

| المشكلة | الحل |
|---|---|
| الجدول ضل فاضي | تأكد إن **Who has access = Anyone** (مش "Anyone with Google account"). ارجع Manage deployments وصلّحها. |
| خطأ CORS بالكونسول | تأكد إن الرابط بينتهي بـ `/exec` مش `/dev` |
| السطر بينزل بجدول غلط | تأكد إن اسم التاب **`Waitlist`** بالضبط |
| صار تعديل وما اشتغل | لازم **New version** بالـdeployment، مش حفظ بس |

عشان تشوف أخطاء السكربت نفسه: من صفحة Apps Script، اضغط **Executions** من القائمة اليسار — بتشوف كل طلب وصل وشو صار فيه.
