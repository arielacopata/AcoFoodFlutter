import '../models/food.dart';

// Suplementos como "alimentos especiales" sin valores nutricionales
final List<Food> supplementsList = [
  Food(
    id: 9001, // IDs altos para no chocar con alimentos
    emoji: '💊',
    name: 'Vitamina B12',
    fullName: 'Vitamina B12 (Cianocobalamina)',
  ),
  Food(
    id: 9002,
    emoji: '☀️',
    name: 'Vitamina D',
    fullName: 'Vitamina D3 (Colecalciferol)',
  ),
  Food(
    id: 9003,
    emoji: '🌿',
    name: 'Omega-3 (Algas)',
    fullName: 'Omega-3 de algas marinas',
  ),
  Food(
    id: 9004, // ← NUEVO
    emoji: '🧂',
    name: 'Yodo',
    fullName: 'Yodo (suplemento)',
  ),
];
