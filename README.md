# PrivMsg — Flutter Android App

Telegram ga o'xshash grafik interfeys bilan **Privacy Messenger** mobil ilovasi.

---

## APK olish — 3 qadam (5 daqiqa)

### 1. GitHub account oching
https://github.com → Sign up (bepul)

### 2. Repozitoriy yarating
- GitHub da "New repository" bosing
- Nom: `privmsg-app`
- Public yoki Private — farqi yo'q
- "Create repository" bosing

### 3. Fayllarni yuklang
```bash
# Kompyuterda:
cd privmsg-app
git init
git add .
git commit -m "initial"
git remote add origin https://github.com/SIZNING_USERNAME/privmsg-app.git
git push -u origin main
```

**Yoki GitHub Desktop** ishlatib, papkani sudrab tashlang.

### APK yuklab olish
1. GitHub da repositoryingizga kiring
2. **Actions** tab → eng oxirgi build
3. **Artifacts** → `privmsg-apk` → yuklab oling
4. **Releases** → `app-arm64-v8a-release.apk` → telefonga o'rnating

---

## Ilova ekranlari

```
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│ PrivMsg          🔍✏ │  │ ← Ali              ⋮ │  │ ← Sozlamalar        │
│ ● 3 peers  [TOR]    │  │ 🔒 E2EE shifrlangan  │  │                     │
│─────────────────────│  │─────────────────────│  │ MENING ADRESIM      │
│ Suhbatlar Kontaktlar│  │  [Salom!        12:30│  │ ┌─────────────────┐ │
│─────────────────────│  │   Yaxshi, siz?]      │  │ │ 🔑 ABCDef12…   │ │
│ 👤 Ali       14:22  │  │ [Yahshi!      12:31 ✓│  │ │ [Nusxa] [Ulash]│ │
│  Yaxshi, siz?       │  │   Yangi narsa        │  │ └─────────────────┘ │
│─────────────────────│  │   aytaman] ✓✓       │  │                     │
│ 👥 Guruh 1   12:45  │  │─────────────────────│  │ TARMOQ              │
│  Xabar yuborildi    │  │ [Xabar yozing…]  📤 │  │ Tor routing   ●●○  │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
```

---

## Xususiyatlar

| Ekran | Nima qiladi |
|-------|-------------|
| **Suhbatlar** | Barcha chatlar ro'yxati, oxirgi xabar, o'qilmagan count |
| **Kontaktlar** | Saqlangan kontaktlar, onlayn holati |
| **Chat** | Telegram uslubida bubble, shifrlangan status, vaqt |
| **Yangi suhbat** | Public key + IP:port kiritish formi |
| **Sozlamalar** | Identity key, Tor on/off, xavfsizlik ma'lumotlari |

---

## Texnologiyalar

- **Flutter 3.22** — cross-platform UI
- **Dart** — ilovaning tili
- **Go crypto library** — backend (kriptografiya)
  - X3DH key exchange
  - Double Ratchet (Signal protokoli)
  - AES-256-GCM
  - Curve25519 / Ed25519

---

## Lokal build (kompyuterda)

```bash
# Flutter o'rnatish
# https://flutter.dev/docs/get-started/install

flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

---

## Xavfsizlik

- Telefon raqam kerak emas
- Email kerak emas
- Identity = Ed25519 key pair
- Barcha xabarlar E2E shifrlangan
- Server yo'q — P2P TCP
- Ixtiyoriy Tor routing
