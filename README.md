# MetaQR App 🧬📱
[![Flutter](https://img.shields.io/badge/Flutter-3.19.6-blue.svg?logo=flutter)](https://flutter.dev)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build Passing](https://img.shields.io/badge/build-passing-brightgreen.svg)]()

> _A mobile-first companion for functional microbiome profiling and disease risk prediction using QR-based access._

---

## 📖 Table of Contents
- [📱 Overview](#-overview)
- [✨ Features](#-features)
- [🛠️ Tech Stack](#️-tech-stack)
- [🧪 Screenshots](#-screenshots)
- [🚀 Installation](#-installation)
  - [Frontend (Flutter)](#frontend-flutter)
  - [Backend (FastAPI)](#backend-fastapi)
- [📡 API Endpoints](#-api-endpoints)
- [🛣️ Project Structure](#️-project-structure)
- [💡 Future Enhancements](#-future-enhancements)
- [👨‍💻 Contributors](#-contributors)
- [📄 License](#-license)

---

## 📱 Overview

**MetaQR** is a cross-platform Flutter mobile app built for microbiome researchers, clinicians, and students. By scanning microbiome-derived QR codes, users can access functional profiles, annotations, and risk scores—backed by a powerful FastAPI backend with machine learning capabilities.

This project bridges biological datasets with user-friendly mobile visualizations.

---

## ✨ Features

✅ Real-time **QR Code Scanning** using device camera  
✅ Downloadable `.tsv` **Functional Annotation Files**  
✅ Species-based **Functional Feature Profiles** (COG, CAZy, KEGG, etc.)  
✅ Intelligent **Search by Description / ID**  
✅ REST API-powered architecture  
✅ Lightweight, responsive, and modular Flutter UI  
✅ Clean backend integration with disease **ML Risk Scoring**

---

## 🛠️ Tech Stack

### 🔹 Frontend (Flutter)
| Package | Description |
|--------|-------------|
| `mobile_scanner` | QR scanning |
| `dio`, `pretty_dio_logger` | API requests & debugging |
| `csv` | Parses `.csv` and `.tsv` files |
| `dropdown_button2` | Custom dropdowns |
| `animations`, `url_launcher` | UI interactivity & navigation |

### 🔸 Backend (FastAPI)
- FastAPI (`0.115.2`)
- ML risk scoring pipeline (species-based)
- QR decoding + genome mapping
- TSV generation using microbiome annotations
- Uvicorn + Conda-based deployment

---

## 🚀 Installation

### ✅ Frontend (Flutter)

**Requirements:**
- Flutter SDK 3.x
- Android Studio or Visual Studio Code
- Emulator or connected device

**Steps:**
```bash
git clone https://github.com/nacool11/metaqr_app.git
cd metaqr_app
flutter pub get
flutter run
