import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/solution_result.dart';

class GeminiSolverService {
  static const String _prefApiKey = 'gemini_api_key';
  static const String defaultApiKey = '';

  static Future<String?> getSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefApiKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved;
    }
    return defaultApiKey;
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, key.trim());
  }

  static Future<SolutionResult> solveEquation({
    required String equation,
    String? initialCondition,
    required String apiKey,
  }) async {
    final effectiveKey = apiKey.trim().isNotEmpty ? apiKey.trim() : defaultApiKey;

    final model = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: effectiveKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, // Suhu rendah untuk akurasi matematika yang presisi
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system('''
Anda adalah Dosen Ahli Matematika Universitas yang ahli dalam Kalkulus Lanjut dan Persamaan Diferensial Biasa (Ordinary Differential Equations / ODE).
Tugas Anda adalah memecahkan persamaan diferensial yang diberikan mahasiswa dan menjelaskannya secara sistematis, runut, dan sangat jelas.

Formatkan jawaban Anda HANYA dalam JSON valid dengan skema berikut:
{
  "equation": "Teks soal asli",
  "equationType": "Jenis persamaan (contoh: PDB Linear Orde 1, Variabel Terpisah, PDB Eksak, PDB Orde 2 Homogen)",
  "method": "Metode penyelesaian (contoh: Metode Faktor Integrasi, Pemisahan Variabel, Persamaan Karakteristik)",
  "steps": [
    {
      "title": "Judul langkah (contoh: Langkah 1: Identifikasi dan Bentuk Standar)",
      "explanation": "Penjelasan konsep langkah ini dalam bahasa Indonesia yang ramah mahasiswa. Jika menyebut variabel/rumus kecil di dalam teks, gunakan tanda \$...\$ (contoh: \$P(x) = 2\$).",
      "formula": "Rumus atau persamaan utama pada langkah ini dalam notasi LaTeX murni tanpa tanda dollar (contoh: \\mu(x) = e^{\\int 2 dx} = e^{2x})"
    }
  ],
  "finalSolution": "Rumus solusi akhir (umum atau khusus jika ada syarat awal) dalam notasi LaTeX murni tanpa tanda dollar (contoh: y(x) = C e^{-2x} + 2x - 1)",
  "notes": "Catatan tambahan atau tips ujian jika relevan (opsional)"
}

PENTING:
- Pastikan semua simbol matematika (seperti integral \\int, turunan, pangkat, pecahan \\frac{}{}, e^{...}) ditulis dalam sintaks LaTeX yang benar.
- Di field 'formula' dan 'finalSolution', jangan sertakan tanda dolar \$ atau \$\$. Cukup sintaks LaTeX murninya.
- Jangan ada teks markdown di luar blok JSON.
'''),
    );

    String prompt = 'Pecahkan persamaan diferensial berikut secara bertahap:\n$equation';
    if (initialCondition != null && initialCondition.trim().isNotEmpty) {
      prompt += '\nSyarat Nilai Awal (Initial Value Condition): $initialCondition';
    }

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text;

      if (rawText == null || rawText.trim().isEmpty) {
        throw Exception('Tidak mendapatkan respon dari Gemini API.');
      }

      // Bersihkan kemungkinan pembungkus markdown ```json ... ```
      String cleanedJson = rawText.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7);
      }
      if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3);
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      cleanedJson = cleanedJson.trim();

      final decoded = json.decode(cleanedJson) as Map<String, dynamic>;
      return SolutionResult.fromMap(decoded);
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Format respon AI tidak dapat dibaca sebagai JSON: ${e.message}');
      }
      throw Exception('Gagal memecahkan soal: $e');
    }
  }
}
