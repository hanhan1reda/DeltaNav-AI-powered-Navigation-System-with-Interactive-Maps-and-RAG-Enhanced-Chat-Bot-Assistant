# **DeltaNav – AI‑Powered Navigation System**

> **Smart campus navigation with interactive indoor/outdoor maps and a RAG‑enhanced chatbot assistant**

---

## **Table of Contents**

1. [Overview](#overview)
2. [Core Features](#core-features)
3. [Tech Stack](#tech-stack)
4. [Architecture](#architecture)
5. [Screenshots](#screenshots)
6. [Getting Started](#getting-started)
7. [Folder Structure](#folder-structure)
8. [Contributing](#contributing)
9. [License](#license)

---

## **Overview**

DeltaNav is a **Flutter** application that delivers seamless **indoor & outdoor navigation** across Delta University.
It combines **GeoJSON‑based interactive maps**, **Dijkstra’s routing**, and a **Retrieval‑Augmented Generation (RAG) chatbot** to provide real‑time guidance, FAQs, and contextual assistance to students and visitors.

---

## **Core Features**

* **Interactive Campus Map** — Smooth pan/zoom with custom SVG overlays.
* **Indoor & Outdoor Navigation** — Shortest‑path routing powered by **Dijkstra’s algorithm**.
* **RAG Chatbot Assistant** — Context‑aware answers using *Mistral 7B* + custom knowledge base.
* **Live Weather Card** — Real‑time weather via **OpenWeatherMap API**.
* **Schedule & Reminders** — Offline JSON schedule with local notifications.
* **Accuracy Indicators** — Color‑coded GPS strength & retry logic.

---

## **Tech Stack**

| Layer        | Technology                   |
| ------------ | ---------------------------- |
| Mobile       | **Flutter (Dart)**           |
| Mapping      | **Leaflet.js** + **GeoJSON** |
| Routing      | **Dijkstra’s Algorithm**     |
| AI Chatbot   | **RAG (Mistral 7B)**         |
| APIs         | **OpenWeatherMap**, REST     |
| Data Storage | Local JSON & secure DB       |

---

## **Architecture**

```
User → Flutter UI → Map Module → Routing Engine → GeoJSON Data
     ↘ Chatbot Module (RAG) ↘ Knowledge Base
```

---

## **Screenshots**

| Home                                                                                     | Weather                                                                                     | Outdoor Map                                                                                     | Chatbot                                                                                     |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| ![Home](https://github.com/user-attachments/assets/2030aee2-f247-4d1b-8115-84475f3d0ffb) | ![Weather](https://github.com/user-attachments/assets/5e42a9fa-1fff-431d-9e44-40aad6ea5b68) | ![Indoor Map](https://github.com/user-attachments/assets/8903c2de-444d-41a6-a41b-2933038487fe) | ![Chatbot](https://github.com/user-attachments/assets/ec13cdf5-c622-48f7-9752-c84635b94b58) |

---

## **Getting Started**

```bash
# Clone repo
git clone https://github.com/your‑org/DeltaNav‑AI‑powered‑Navigation‑System‑with‑Interactive‑Maps‑and‑RAG‑Enhanced‑Chat‑Bot‑Assistant.git
cd DeltaNav‑AI‑powered‑Navigation‑System‑with‑Interactive‑Maps‑and‑RAG‑Enhanced‑Chat‑Bot‑Assistant

# Install Flutter dependencies
flutter pub get

# Run on connected device
flutter run
```

### Build APK

```bash
flutter build apk --release
```

---

## **Folder Structure**

```
├── android/
├── ios/
├── lib/
│   ├── screens/
│   ├── widgets/
│   ├── models/
│   └── services/
├── assets/
│   ├── maps/
│   └── images/
└── schedule.json
```

---

## **Contributing**

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## **License**

Distributed under the MIT License. See `LICENSE` for more information.

---

> * DeltaNav ❤️*