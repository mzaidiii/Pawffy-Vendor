<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=E85D04&height=220&section=header&text=Pawffy%20Vendor&fontSize=60&fontColor=ffffff&animation=fadeIn&fontAlignY=35&desc=The%20provider-side%20app%20powering%20every%20groomer%2C%20vet%2C%20walker%20%26%20trainer%20on%20Pawffy&descAlignY=55&descSize=18" width="100%"/>

<a href="https://github.com/mzaidiii/Pawffy-Vendor">
  <img src="https://readme-typing-svg.demolab.com/?lines=Flutter+app+for+pet-care+professionals;Real-time+jobs+%C2%B7+Live+GPS+%C2%B7+In-app+chat;Built+solo+by+Zaidi+%F0%9F%90%BE&font=Fira%20Code&center=true&width=650&height=45&color=E85D04&vCenter=true&size=22"/>
</a>

<br/>

<img src="https://img.shields.io/badge/Flutter-3.8.1-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-3.8-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Riverpod-State%20Mgmt-4051B5?style=for-the-badge&logo=riverpod&logoColor=white"/>
<img src="https://img.shields.io/badge/Supabase-Auth-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
<img src="https://img.shields.io/badge/Node.js-API%20Gateway-339933?style=for-the-badge&logo=node.js&logoColor=white"/>

<br/><br/>

<img src="https://img.shields.io/github/stars/mzaidiii/Pawffy-Vendor?style=social"/>
<img src="https://img.shields.io/github/forks/mzaidiii/Pawffy-Vendor?style=social"/>
<img src="https://img.shields.io/github/last-commit/mzaidiii/Pawffy-Vendor?color=E85D04&style=flat-square"/>
<img src="https://img.shields.io/badge/status-in%20development-yellow?style=flat-square"/>

</div>

<br/>

## 🐾 What is this

Pawffy has two sides to it — the app pet owners use to book a walk, a grooming session, or a vet visit, and the app the **service providers** use to actually run their business on top of it. This repo is the second one.

Pawffy Vendor is where groomers, vets, walkers, and trainers set up their profile, list what they offer, get discovered, accept jobs, and take a client's booking all the way from *"request received"* to *"paid out"* — with live location sharing while a job is active, milestone checklists, photo proof of work, and a chat thread with the client the whole way through.

It talks to a Node.js API gateway, with Supabase handling phone-based auth and a PostgreSQL database sitting underneath it all.

<br/>

## ✨ Core capabilities

<table>
<tr>
<td width="50%" valign="top">

**🔐 Phone-first onboarding**
OTP login via Supabase, then a guided multi-step setup — business info, service menu with pricing, weekly availability, license upload, and a review-and-submit step before an admin verifies the account.

**📥 Live request feed**
Incoming bookings land in a feed the vendor can accept or reject in real time, with search and status filters (pending / upcoming / completed / canceled).

</td>
<td width="50%" valign="top">

**📍 Active job tracking**
Once a job starts, GPS coordinates stream to the server on an interval, milestones get checked off as work progresses, and photos are attached along the way — right up to a final completion form.

**💬 Built-in messaging & wallet**
A dedicated chat thread per client, plus a wallet view for balance, payout history, and withdrawal requests.

</td>
</tr>
</table>

<br/>

## 🧭 How a booking actually moves through the app

```mermaid
sequenceDiagram
    participant Owner as Pet Owner
    participant API as Backend
    participant App as Vendor App

    Owner->>API: Sends a booking request
    API->>App: Shows up in the request feed
    App->>API: Vendor accepts
    Note over App: Status → Upcoming
    App->>API: Vendor starts the job on-site
    Note over App: Status → Active
    loop while job is active
        App->>API: Location ping
        App->>API: Milestone checked off
        App->>API: Photo uploaded
    end
    App->>API: Final notes + completion form submitted
    Note over App: Status → Completed, payout hits wallet
```

<br/>

## 🏗️ Under the hood

```
lib/
├── core/
│   ├── storage/        → secure token & session storage
│   ├── config/         → Supabase keys, env config
│   ├── networks/       → Dio client, interceptors, API constants
│   └── utils/          → GPS, image picking, device helpers
└── features/
    ├── auth/            → OTP login, signup, session gate
    ├── onboarding/       → business setup wizard
    ├── home/             → dashboard, presence toggle, stats
    ├── requests/         → job feed → active job → completion
    ├── calendar/         → working hours, blocked dates
    ├── message/          → chat threads
    ├── notification/     → alerts feed
    └── profile/          → portfolio, wallet, settings
```

State is handled with **Riverpod**, networking runs through **Dio** with JWT interceptors, and tokens live in **flutter_secure_storage** so a session survives an app restart without ever touching plaintext storage.

<br/>

## 🎨 Design notes

- Full light/dark theme support — cards, borders, and text all key off `Theme.of(context).brightness` rather than hardcoded colors.
- One consistent accent color across the whole app: **Pawffy Orange** `#E85D04`, used for every CTA, checkmark, and active state.
- Every form screen is scroll-safe and keyboard-aware (`resizeToAvoidBottomInset`), wrapped in `SafeArea`, with text that shrinks gracefully on smaller screens instead of wrapping badly.

<br/>

## 🚀 Running it locally

```bash
# clone it
git clone https://github.com/mzaidiii/Pawffy-Vendor.git
cd Pawffy-Vendor

# grab dependencies
flutter pub get

# run on your device/emulator of choice
flutter run
```

You'll need a `.env` (or equivalent config in `core/config`) with your Supabase project URL/anon key and the base URL of the backend API before auth will work end to end.

<br/>

## 🗺️ Where this is headed

- [ ] Push notifications for new job requests
- [ ] In-app earnings analytics / weekly summaries
- [ ] Offline-first request queue for spotty connectivity mid-job
- [ ] Multi-language support

<br/>

## 🤝 About this project

Built solo, end to end — Flutter frontend, UX flows, and API integration. Part of the larger **Pawffy** ecosystem alongside the customer-facing app.

<div align="center">
<br/>

<a href="https://www.linkedin.com/in/mohd-murtaza-zaidi-b18a5b294">
  <img src="https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white"/>
</a>
<a href="https://x.com/">
  <img src="https://img.shields.io/badge/X-Follow-000000?style=for-the-badge&logo=x&logoColor=white"/>
</a>

<br/><br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=E85D04&height=100&section=footer"/>

</div>