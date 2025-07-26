# 🏗️ نقشه معماری و نمودار جریان QJuryRegistry

در این مستند، یک نقشه معماری ساده و یک نمودار جریان (Flowchart) برای قرارداد `QJuryRegistry` ارائه می‌دهیم تا درک کامل‌تری از ساختار و رفتار آن داشته باشید.

---

## 🔧 نقشه معماری ساده QJuryRegistry

```
┌──────────────────────────┐
│      QJuryRegistry       │
├──────────────────────────┤
│ 🔹 STAKE_AMOUNT (0.1 ETH)│
│ 🔹 isJuror[address]      │◄── چک می‌کند آیا فرد داور است
│ 🔹 stakes[address]       │◄── ذخیره استیک داور
│ 🔹 jurors[]              │◄── لیست کل داوران
├──────────────────────────┤
│ 📤 registerAsJuror()     │──┐
│ 📤 getAllJurors()        │  │
│ 📤 slashJuror(address)   │  │  ◄── توابع عمومی
│ 📤 rewardJuror(address)  │  │
│ 📥 receive()             │◄─┘  ◄── دریافت اتر مستقیم
├──────────────────────────┤
│ 📢 JurorRegistered       │◄─ رویداد
│ 📢 JurorSlashed          │◄─ رویداد
│ 📢 JurorRewarded         │◄─ رویداد
└──────────────────────────┘
```

---

## 🔁 نمودار جریان (Flowchart)

### 1️⃣ ثبت‌نام داور (`registerAsJuror()`)

```
[کاربر ارسال تراکنش با 0.1 ETH]
              │
              ▼
 [registerAsJuror() فراخوانی]
              │
  ┌────────────┴─────────────┐
  │ آیا کاربر قبلاً داور است؟ │
  └────────────┬─────────────┘
         │ بله                     ▼ خیر
         ▼                     ┌───────────────┐
[خطا: Already registered]      │ آیا مقدار = 0.1 ETH؟ │
                              └───────┬───────┘
                              │ خیر   ▼ بله
                              ▼   ✔ ثبت اطلاعات داور:
                     [خطا: Incorrect stake]   - isJuror[msg.sender] = true  
                                               - stakes[msg.sender] = 0.1  
                                               - jurors[] ← msg.sender  
                                               🔊 emit JurorRegistered
```

---

### 2️⃣ حذف داور (`slashJuror()`)

```
[Admin فراخوانی slashJuror(juror)]
              │
              ▼
       ┌────────────┐
       │ juror ثبت شده است؟ │
       └──────┬─────┘
              │ خیر   ▼ بله
              ▼    stakes[juror] = 0  
     [خطا: Not a juror]     isJuror[juror] = false  
                             🔊 emit JurorSlashed
```

---

### 3️⃣ پاداش‌دهی به داور (`rewardJuror()`)

```
[Admin فراخوانی rewardJuror(juror, amount)]
              │
              ▼
       ┌────────────┐
       │ juror ثبت شده است؟ │
       └──────┬─────┘
              │ خیر   ▼ بله
              ▼    ارسال amount ETH به juror  
     [خطا: Not a juror]     🔊 emit JurorRewarded
```

---

### 4️⃣ دریافت اتر مستقیم (بدون فراخوانی تابع)

```
[کاربر ارسال ETH بدون فراخوانی تابع]
              │
              ▼
         receive() فعال می‌شود
```

---

📝 **توضیح تکمیلی:**
- توابع `slashJuror` و `rewardJuror` معمولاً باید تنها توسط قراردادهای دیگر (مثل `QJuryDispute` یا `QJuryReward`) یا اپراتور مجاز فراخوانی شوند (در نسخه پیشرفته‌تر می‌توان `onlyOwner` یا کنترل دسترسی اضافه کرد).
- تابع `receive()` برای دریافت مستقیم ETH تعریف شده و ممکن است در آینده جهت تامین بودجه برای پاداش‌دهی مفید باشد.

