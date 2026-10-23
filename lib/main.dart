import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/solution_result.dart';
import 'services/gemini_solver.dart';
import 'widgets/math_text_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiffSolverApp());
}

class DiffSolverApp extends StatelessWidget {
  const DiffSolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiffSolver - Pemecah PDB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Indigo / Modern Blue
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const DiffSolverHomePage(),
    );
  }
}

class DiffSolverHomePage extends StatefulWidget {
  const DiffSolverHomePage({super.key});

  @override
  State<DiffSolverHomePage> createState() => _DiffSolverHomePageState();
}

class _DiffSolverHomePageState extends State<DiffSolverHomePage> {
  final TextEditingController _eqController = TextEditingController();
  final TextEditingController _ivpController = TextEditingController();
  final FocusNode _eqFocusNode = FocusNode();

  bool _hasIvp = false;
  bool _isLoading = false;
  String? _errorMessage;
  SolutionResult? _solution;
  String? _apiKey;

  final List<String> _quickSymbols = [
    r"y'",
    r"y''",
    r"dy/dx",
    r"dx",
    r"dy",
    r"e^x",
    r"^",
    r"=",
    r"+",
    r"-",
    r"*",
    r"/",
    r"(",
    r")",
    r"sin(x)",
    r"cos(x)",
  ];

  final List<Map<String, String>> _examples = [
    {
      'label': 'PDB Linear Orde 1',
      'eq': "y' + 2y = 4x",
      'ivp': '',
    },
    {
      'label': 'Variabel Terpisah',
      'eq': "dy/dx = x * y",
      'ivp': '',
    },
    {
      'label': 'PDB Eksak',
      'eq': "(2*x*y)dx + (x^2 - 1)dy = 0",
      'ivp': '',
    },
    {
      'label': 'Orde 2 Homogen',
      'eq': "y'' - 5y' + 6y = 0",
      'ivp': '',
    },
    {
      'label': 'Nilai Awal (IVP)',
      'eq': "y' + y = 2*e^x",
      'ivp': "y(0) = 1",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    // Default contoh soal
    _eqController.text = "y' + 2y = 4x";
  }

  @override
  void dispose() {
    _eqController.dispose();
    _ivpController.dispose();
    _eqFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final key = await GeminiSolverService.getSavedApiKey();
    setState(() {
      _apiKey = key;
    });
  }

  void _insertSymbol(String symbol) {
    final text = _eqController.text;
    final selection = _eqController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, symbol);
    _eqController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + symbol.length),
    );
    _eqFocusNode.requestFocus();
  }

  void _selectExample(Map<String, String> example) {
    setState(() {
      _eqController.text = example['eq'] ?? '';
      final ivp = example['ivp'] ?? '';
      if (ivp.isNotEmpty) {
        _hasIvp = true;
        _ivpController.text = ivp;
      } else {
        _hasIvp = false;
        _ivpController.clear();
      }
      _errorMessage = null;
    });
  }

  Future<void> _solve() async {
    final eq = _eqController.text.trim();
    if (eq.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan persamaan diferensial terlebih dahulu')),
      );
      return;
    }

    if (_apiKey == null || _apiKey!.trim().isEmpty) {
      _showApiKeyDialog(isCompulsory: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _solution = null;
    });

    try {
      final res = await GeminiSolverService.solveEquation(
        equation: eq,
        initialCondition: _hasIvp ? _ivpController.text.trim() : null,
        apiKey: _apiKey!,
      );

      setState(() {
        _solution = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showApiKeyDialog({bool isCompulsory = false}) {
    final controller = TextEditingController(text: _apiKey ?? '');
    showDialog(
      context: context,
      barrierDismissible: !isCompulsory,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Pengaturan API Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aplikasi membutuhkan Gemini API Key untuk memecahkan dan menguraikan langkah soal.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'Tempel (paste) kunci di sini...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tips: Kunci Anda tersimpan aman hanya di HP ini dan tidak dikirim ke server luar selain Google AI Studio.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          actions: [
            if (!isCompulsory)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final key = controller.text.trim();
                if (key.isNotEmpty) {
                  await GeminiSolverService.saveApiKey(key);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  setState(() {
                    _apiKey = key;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key berhasil disimpan!')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DiffSolver',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Pemecah Persamaan Diferensial Biasa',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan API Key',
            icon: Stack(
              children: [
                const Icon(Icons.vpn_key_outlined),
                if (_apiKey == null || _apiKey!.isEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showApiKeyDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Peringatan jika API Key belum diisi
            if (_apiKey == null || _apiKey!.isEmpty)
              GestureDetector(
                onTap: () => _showApiKeyDialog(),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Klik di sini untuk memasukkan Gemini API Key Anda.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Color(0xFFD97706)),
                    ],
                  ),
                ),
              ),

            // Card Input Soal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan Persamaan Diferensial:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _eqController,
                      focusNode: _eqFocusNode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "Contoh: y' + 2y = 4x",
                        hintStyle: const TextStyle(fontFamily: 'sans-serif', color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                        suffixIcon: _eqController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _eqController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 12),

                    // Baris Tombol Simbol Cepat
                    const Text(
                      'Simbol Cepat:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _quickSymbols.map((sym) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                sym,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              backgroundColor: const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              onPressed: () => _insertSymbol(sym),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFF1F5F9)),

                    // Opsi Syarat Nilai Awal (IVP)
                    Row(
                      children: [
                        Checkbox(
                          value: _hasIvp,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) {
                            setState(() {
                              _hasIvp = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Ada Syarat Nilai Awal (IVP)? Contoh: y(0) = 1',
                            style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),

                    if (_hasIvp)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 6),
                        child: TextField(
                          controller: _ivpController,
                          style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            hintText: "Contoh: y(0) = 1 atau y(0) = 2, y'(0) = 0",
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Tombol Hitung
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _solve,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          _isLoading ? 'Menganalisis & Menyelesaikan...' : 'Pecahkan Soal Sekarang',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contoh Soal Praktis
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contoh Soal Kuliah Cepat:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _examples.map((ex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            avatar: const Icon(Icons.play_circle_outline, size: 16, color: Color(0xFF2563EB)),
                            label: Text(ex['label']!, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            onPressed: () => _selectExample(ex),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Tampilan Error jika ada
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // TAMPILAN SOLUSI HASIL HITUNGAN
            if (_solution != null) ...[
              // Ringkasan Tipe & Metode
              Card(
                color: const Color(0xFFEFF6FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _solution!.equationType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Metode: ${_solution!.method}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A8A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // KOTAK SOLUSI AKHIR
              Card(
                color: const Color(0xFF0F172A), // Dark elegant background untuk jawaban akhir
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF38BDF8), size: 18),
                              SizedBox(width: 6),
                              Text(
                                'SOLUSI AKHIR',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                            tooltip: 'Salin Rumus LaTeX',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _solution!.finalSolution));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rumus solusi disalin ke clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: MathBlock(
                          tex: _solution!.finalSolution,
                          alignment: Alignment.center,
                          textStyle: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // LANGKAH DEMI LANGKAH
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered, size: 18, color: Color(0xFF1E293B)),
                    SizedBox(width: 6),
                    Text(
                      'Langkah Penyelesaian Bertahap:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              ..._solution!.steps.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final step = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFFE0E7FF),
                              child: Text(
                                '$idx',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Penjelasan kata-kata
                        MixedMathText(text: step.explanation),

                        // Rumus langkah jika ada
                        if (step.formula.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: MathBlock(
                              tex: step.formula,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              // Catatan tambahan jika ada
              if (_solution!.notes != null && _solution!.notes!.trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFF475569)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Catatan: ${_solution!.notes!}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
