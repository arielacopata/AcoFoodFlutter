# 🥗 AcoFoodFlutter

AcoFoodFlutter es la versión en Flutter de **AcoFood**, una app pensada para registrar alimentos, calcular macros y conectarse vía **Bluetooth** a la balanza inteligente **Macroscale**.

## 🚀 Funcionalidades

- 📱 **Interfaz Flutter** multiplataforma (Android, iOS, Web, Desktop).
- 🔍 **Buscador de alimentos** con macros.
- ⚖️ **Integración con balanza Macroscale** vía `flutter_blue_plus`.
- 📊 **Historial de consumos** con fecha, gramos y kcal.
- 🎨 **Soporte de temas (claro/oscuro)**.
- 🔐 **Persistencia** con `shared_preferences` y `sqflite`.

## 📂 Estructura del proyecto

```plaintext
lib/
 ├── home_page.dart         # Pantalla principal
 ├── models/                # Modelos (Food, UserProfile, FoodEntry, etc.)
 ├── widgets/               # Widgets reutilizables (FoodAmountSheet, BluetoothManager)
 ├── services/              # Lógica de simulador de balanza
