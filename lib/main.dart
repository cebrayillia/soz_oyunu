import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SozOyunuApp());
}

// Azərbaycan əlifbasına uyğun böyük hərf çeviricisi ('i' -> 'İ', 'ı' -> 'I')
String toAzUpper(String input) {
  return input
      .replaceAll('i', 'İ')
      .replaceAll('ı', 'I')
      .replaceAll('ə', 'Ə')
      .replaceAll('ö', 'Ö')
      .replaceAll('ü', 'Ü')
      .replaceAll('ğ', 'Ğ')
      .replaceAll('ş', 'Ş')
      .replaceAll('ç', 'Ç')
      .toUpperCase();
}

class SozOyunuApp extends StatelessWidget {
  const SozOyunuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Söz Oyunu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF4A0404), // Tünd bordo
        primaryColor: const Color(0xFF8B0000), // Tünd qırmızı
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: const Color(0xFFB71C1C),
          secondary: Colors.amber,
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: const Color(0xFF4A0404),
            elevation: 8,
            shadowColor: Colors.black87,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ==================== DATA MODELLERİ ====================
class WordItem {
  final String word;
  final String clue;

  WordItem({required this.word, required this.clue});

  factory WordItem.fromJson(Map<String, dynamic> json) {
    return WordItem(
      word: toAzUpper(json['word'].toString().trim()),
      clue: json['clue']?.toString() ?? '',
    );
  }
}

class LevelData {
  final int level;
  final List<WordItem> words;

  LevelData({required this.level, required this.words});

  factory LevelData.fromJson(Map<String, dynamic> json) {
    var list = json['words'] as List;
    List<WordItem> wordsList = list.map((i) => WordItem.fromJson(i)).toList();
    return LevelData(level: json['level'], words: wordsList);
  }
}

// ==================== ANA SƏHİFƏ ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int coins = 0;
  int currentLevel = 1;
  bool hasSecondChance = false;
  List<LevelData> allLevels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initGameData();
  }

  Future<void> _initGameData() async {
    await _loadPrefs();
    await _loadLevelsFromJson();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      coins = prefs.getInt('coins') ?? 50; // Başlanğıc hədiyyə 50 coin
      currentLevel = prefs.getInt('currentLevel') ?? 1;
      hasSecondChance = prefs.getBool('hasSecondChance') ?? false;
    });
  }

  Future<void> _loadLevelsFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/words.json');
      final data = json.decode(response);
      final List levelsJson = data['levels'];
      allLevels = levelsJson.map((e) => LevelData.fromJson(e)).toList();
    } catch (e) {
      debugPrint("JSON oxuma xətası: $e");
    }
  }

  Future<void> _buySecondChance() async {
    if (hasSecondChance) {
      _showSnack("Sizdə artıq 'Təkrar təxmin' hüququ aktivdir!", Colors.orange);
      return;
    }
    if (coins >= 99) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        coins -= 99;
        hasSecondChance = true;
      });
      await prefs.setInt('coins', coins);
      await prefs.setBool('hasSecondChance', true);
      _showSnack("'Təkrar təxmin' hüququ alındı!", Colors.green);
    } else {
      _showSnack("Kifayət qədər coin yoxdur! (99 Coin lazımdır)", Colors.redAccent);
    }
  }

  void _showSnack(String msg, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openShopModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF6B0909),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.amber, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.storefront, color: Colors.amber, size: 30),
              SizedBox(width: 10),
              Text("MAĞAZA", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A0404),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_moon, color: Colors.orangeAccent, size: 36),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Təkrar Təxmin Hüququ",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Sözü səhv təxmin etdikdə səviyyə yanmır, bu hüquq silinir və eyni sözə yenidən cəhd edirsiniz.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.monetization_on),
                        label: Text(hasSecondChance ? "AKTİVDİR" : "99 Coin - Satın Al"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasSecondChance ? Colors.grey : Colors.amber,
                        ),
                        onPressed: hasSecondChance
                            ? null
                            : () {
                                Navigator.pop(context);
                                _buySecondChance();
                              },
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("BAĞLA", style: TextStyle(color: Colors.amber)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B0000), Color(0xFF3B0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Yuxarı Panel (Balans və Qoruyucu Statusu)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A0404),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber, width: 1.5),
                              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                                const SizedBox(width: 6),
                                Text(
                                  "$coins",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasSecondChance)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange[900],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shield, color: Colors.amber, size: 20),
                                  SizedBox(width: 6),
                                  Text("Qorunma Aktiv", style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Oyun Başlığı
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red[900],
                            border: Border.all(color: Colors.amber, width: 4),
                            boxShadow: const [
                              BoxShadow(color: Colors.black87, blurRadius: 15, offset: Offset(0, 6))
                            ],
                          ),
                          child: const Icon(Icons.extension, size: 70, color: Colors.amber),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "SÖZ OYUNU",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: Colors.amber,
                            shadows: [
                              Shadow(color: Colors.black, offset: Offset(2, 4), blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "SƏVİYYƏ: $currentLevel / 200",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    // Düymələr (Oyuna Başla və Mağaza)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50, left: 32, right: 32),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow_rounded, size: 32),
                              label: const Text("OYUNA BAŞLA", style: TextStyle(fontSize: 22)),
                              onPressed: () async {
                                if (allLevels.isEmpty) {
                                  _showSnack("Söz bazası (words.json) tapılmadı!", Colors.red);
                                  return;
                                }
                                LevelData levelToPlay = allLevels.firstWhere(
                                  (lvl) => lvl.level == currentLevel,
                                  orElse: () => allLevels.first,
                                );
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GameScreen(levelData: levelToPlay),
                                  ),
                                );
                                _loadPrefs(); // Qayıdanda balansı və səviyyəni yenilə
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                foregroundColor: Colors.amber,
                                side: const BorderSide(color: Colors.amber, width: 2),
                              ),
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text("MAĞAZA"),
                              onPressed: _openShopModal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ==================== OYUN SƏHİFƏSİ ====================
class GameScreen extends StatefulWidget {
  final LevelData levelData;

  const GameScreen({super.key, required this.levelData});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentWordIndex = 0; // 0..9 (10 söz)
  late String targetWord;
  late String currentClue;
  late List<String> slots; // İstifadəçinin yazdığı və ya ipucu ilə açılan hərflər
  late List<bool> lockedHints; // İpucu ilə açılmış sabit hərflər

  int coins = 0;
  bool hasSecondChance = false;
  bool levelCompleted = false;

  // Azərbaycan klaviaturası düzülüşü
  final List<List<String>> azKeyboard = [
    ['Q', 'Ü', 'E', 'R', 'T', 'Y', 'U', 'İ', 'O', 'P', 'Ö', 'Ğ'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'I', 'Ə'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M', 'Ç', 'Ş', 'SİL']
  ];

  @override
  void initState() {
    super.initState();
    _loadPlayerStatus();
    _setupWord();
  }

  Future<void> _loadPlayerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      coins = prefs.getInt('coins') ?? 0;
      hasSecondChance = prefs.getBool('hasSecondChance') ?? false;
    });
  }

  void _setupWord() {
    final item = widget.levelData.words[currentWordIndex];
    targetWord = item.word;
    currentClue = item.clue;
    slots = List.filled(targetWord.length, '');
    lockedHints = List.filled(targetWord.length, false);
  }

  // Klaviaturadan hərf basıldıqda
  void _onKeyTap(String key) {
    if (levelCompleted) return;

    if (key == 'SİL') {
      for (int i = slots.length - 1; i >= 0; i--) {
        if (slots[i].isNotEmpty && !lockedHints[i]) {
          setState(() {
            slots[i] = '';
          });
          break;
        }
      }
    } else {
      for (int i = 0; i < slots.length; i++) {
        if (slots[i].isEmpty) {
          setState(() {
            slots[i] = key;
          });
          break;
        }
      }
    }
  }

  // "Hərf aç" İpucu funksiyası (-10 coin)
  Future<void> _revealRandomLetter() async {
    if (coins < 10) {
      _showMsg("İpucu üçün 10 Coin lazımdır!", Colors.redAccent);
      return;
    }

    // Hələ düzgün açılmamış və ya boş olan indeksləri tap
    List<int> availableIndices = [];
    for (int i = 0; i < targetWord.length; i++) {
      if (!lockedHints[i] && slots[i] != targetWord[i]) {
        availableIndices.add(i);
      }
    }

    if (availableIndices.isEmpty) return;

    final randomIndex = availableIndices[Random().nextInt(availableIndices.length)];
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      coins -= 10;
      slots[randomIndex] = targetWord[randomIndex];
      lockedHints[randomIndex] = true;
    });
    await prefs.setInt('coins', coins);

    // Əgər bütün qutular dolubsa avtomatik yoxla
    if (!slots.contains('')) {
      _checkAnswer();
    }
  }

  // Təxmini Yoxla
  Future<void> _checkAnswer() async {
    if (slots.contains('')) {
      _showMsg("Bütün xanaları doldurun!", Colors.orange);
      return;
    }

    final guessedWord = slots.join('');
    final prefs = await SharedPreferences.getInstance();

    if (guessedWord == targetWord) {
      // Düzgün cavab: Hər hərfə görə +10 coin
      int reward = targetWord.length * 10;
      setState(() {
        coins += reward;
      });
      await prefs.setInt('coins', coins);

      if (currentWordIndex < widget.levelData.words.length - 1) {
        _showMsg("Doğrudur! +$reward Coin qazandınız.", Colors.green);
        setState(() {
          currentWordIndex++;
          _setupWord();
        });
      } else {
        // 10 sözün hamısı tapıldı
        setState(() {
          levelCompleted = true;
        });
      }
    } else {
      // Səhv təxmin!
      if (hasSecondChance) {
        // "Təkrar təxmin" hüququ varsa istifadə olunur
        setState(() {
          hasSecondChance = false;
          for (int i = 0; i < slots.length; i++) {
            if (!lockedHints[i]) slots[i] = '';
          }
        });
        await prefs.setBool('hasSecondChance', false);
        _showSecondChanceUsedDialog();
      } else {
        // Hüquq yoxdursa səviyyə dərhal bitir və Ana Səhifəyə qaytarılır
        _showGameOverDialog();
      }
    }
  }

  void _showSecondChanceUsedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF6B0909),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.amber, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.amber),
            SizedBox(width: 8),
            Text("Qorunma İşə Düşdü!", style: TextStyle(color: Colors.amber)),
          ],
        ),
        content: const Text(
          "Sözü səhv yazdınız, lakin 'Təkrar təxmin' hüququnuz sizi məğlubiyyətdən xilas etdi! Eyni sözü yenidən yoxlayın.",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("DAVAM ET"),
          )
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF4A0404),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        title: const Text(
          "MƏĞLUB OLDUNUZ!",
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Təxmininiz yanlışdır və 'Təkrar təxmin' hüququnuz yoxdur. Səviyyə başa çatdı.",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Dialoqu bağla
              Navigator.pop(context); // Ana səhifəyə qayıt
            },
            child: const Text("ANA SƏHİFƏYƏ QAYIT"),
          )
        ],
      ),
    );
  }

  Future<void> _goToNextLevel() async {
    final prefs = await SharedPreferences.getInstance();
    int savedLevel = prefs.getInt('currentLevel') ?? 1;
    if (savedLevel < 200) {
      await prefs.setInt('currentLevel', savedLevel + 1);
    }
    if (!mounted) return;
    Navigator.pop(context); // Ana səhifəyə qayıt (yeni səviyyə yüklənəcək)
  }

  void _showMsg(String text, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B0909),
        elevation: 6,
        title: Text(
          "Səviyyə ${widget.levelData.level}  •  Söz ${currentWordIndex + 1}/10",
          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (hasSecondChance)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.shield, color: Colors.orangeAccent, size: 22),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B0000),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text("$coins", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5A0606), Color(0xFF2B0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Sözün sualı / izahı və uzunluq göstəricisi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.7), width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${targetWord.length} HƏRFLİ SÖZ",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentClue,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Hərf Qutuları (4-dən 13-ə qədər ekrana sığması üçün dinamik Wrap)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 10,
                  children: List.generate(targetWord.length, (index) {
                    bool isLocked = lockedHints[index];
                    double boxSize = targetWord.length > 9 ? 34 : 42;
                    return Container(
                      width: boxSize,
                      height: boxSize + 6,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.amber[800] : const Color(0xFF3B0000),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: slots[index].isNotEmpty ? Colors.amber : Colors.redAccent,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Text(
                        slots[index],
                        style: TextStyle(
                          fontSize: targetWord.length > 9 ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.black : Colors.amber,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(),

              // İdarəetmə düymələri: İpucu (Hərf aç) & Təxmin Et / Növbəti Səviyyə
              if (levelCompleted)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.double_arrow, size: 28),
                      label: const Text("NÖVBƏTİ SƏVİYYƏ"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[700], foregroundColor: Colors.white),
                      onPressed: _goToNextLevel,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: _revealRandomLetter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.lightbulb),
                          label: const Text("Hərf aç (-10)"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: _checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: const Color(0xFF4A0404),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: const Text("YOXLAYIN"),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Virtual Azərbaycan Klaviaturası
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF330202),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: Column(
                  children: azKeyboard.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row.map((key) {
                          bool isDelete = key == 'SİL';
                          return Expanded(
                            flex: isDelete ? 2 : 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.5),
                              child: Material(
                                color: isDelete ? Colors.red[800] : const Color(0xFF7B1111),
                                elevation: 4,
                                shadowColor: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _onKeyTap(key),
                                  child: Container(
                                    height: 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDelete ? Colors.orangeAccent : Colors.amber.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: isDelete
                                        ? const Icon(Icons.backspace_outlined, color: Colors.amber, size: 20)
                                        : Text(
                                            key,
                                            style: const TextStyle(
                                              color: Colors.amber,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
