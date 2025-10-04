import 'package:flutter/material.dart';

class HabitInfoScreen extends StatelessWidget {
  const HabitInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de Hábitos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHabitSection(
            '🫁 Respirar',
            [
              _buildTechnique('4-7-8', 
                'Inhala por 4 segundos, mantén 7 segundos, exhala en 8 segundos. Calma el sistema nervioso y ayuda con el sueño.'),
              _buildTechnique('Cuadrada (Box Breathing)', 
                'Inhala 4 seg, mantén 4 seg, exhala 4 seg, mantén 4 seg. Usada por Navy SEALs para reducir estrés.'),
              _buildTechnique('Profunda (Diafragmática)', 
                'Respiración lenta y profunda desde el diafragma. Reduce ansiedad y mejora oxigenación.'),
              _buildTechnique('Wim Hof', 
                '30-40 respiraciones rápidas seguidas de retención. Aumenta energía y fortalece sistema inmune. Advertencia: no hacerlo en agua o conduciendo.'),
            ],
          ),
          const Divider(height: 32),
          _buildHabitSection(
            '🧘 Meditar',
            [
              _buildTechnique('5-10 minutos', 
                'Ideal para principiantes. Enfócate en tu respiración o usa una app guiada.'),
              _buildTechnique('15-20 minutos', 
                'Duración óptima para obtener beneficios completos: reduce estrés, mejora concentración y bienestar emocional.'),
            ],
          ),
          const Divider(height: 32),
          _buildHabitSection(
            '🚿 Ducha fría',
            [
              _buildTechnique('30 segundos - 1 minuto', 
                'Para principiantes. Empieza con agua tibia y termina con 30 seg de fría.'),
              _buildTechnique('2-5 minutos', 
                'Para experimentados. Beneficios: mejora circulación, acelera recuperación muscular, fortalece sistema inmune y aumenta estado de alerta.'),
              _buildTechnique('⚠️ Advertencias', 
                'No recomendado si tenés problemas cardíacos. Salí gradualmente si sentís mareos.'),
            ],
          ),
          const Divider(height: 32),
          _buildHabitSection(
            '🙏 Agradecer',
            [
              _buildTechnique('Lista de 3', 
                'Escribí 3 cosas por las que estás agradecido. Aumenta felicidad y reduce depresión.'),
              _buildTechnique('Journaling', 
                'Escritura más profunda sobre lo que agradecés y por qué.'),
              _buildTechnique('Meditación', 
                'Contempla momentos positivos de tu día en silencio.'),
              _buildTechnique('A alguien', 
                'Expresá gratitud directamente a una persona.'),
            ],
          ),
          const Divider(height: 32),
          _buildHabitSection(
            '🏃 Ejercicio',
            [
              _buildTechnique('HIIT', 
                'Intervalos de alta intensidad (20-30 min). Quema calorías eficientemente.'),
              _buildTechnique('Correr/Caminar', 
                'Cardio sostenido. Mejora salud cardiovascular y resistencia.'),
              _buildTechnique('Gimnasio', 
                'Entrenamiento de fuerza. Aumenta masa muscular y metabolismo.'),
              _buildTechnique('Bicicleta', 
                'Bajo impacto en articulaciones, excelente para cardio.'),
              _buildTechnique('General', 
                'Cualquier actividad física cuenta. Lo importante es moverte diariamente.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitSection(String title, List<Widget> techniques) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...techniques,
      ],
    );
  }

  Widget _buildTechnique(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}