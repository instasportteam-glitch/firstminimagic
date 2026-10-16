import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const CatGameApp());

class CatGameApp extends StatelessWidget {
  const CatGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Найди котика',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const CatGamePage(),
    );
  }
}

/// Стадии игры.
enum Phase { searching, feeding, full, escaped, gameOver }

class Food {
  const Food(this.emoji, this.name, this.value, this.reaction);

  final String emoji;
  final String name;

  /// > 0 — насыщает, 0 — котик отказывается, < 0 — вредно (минус жизнь).
  final int value;
  final String reaction;
}

const List<Food> kFoods = [
  Food('🐟', 'Рыбка', 40, 'Мур-р! Обожаю рыбку!'),
  Food('🍗', 'Курочка', 30, 'Ням-ням, вкусно!'),
  Food('🥫', 'Корм', 25, 'Хрум-хрум, мой любимый корм!'),
  Food('🦐', 'Креветка', 20, 'Какая вкусная креветка!'),
  Food('🥦', 'Брокколи', 0, 'Фу! Котики не едят брокколи.'),
  Food('🍫', 'Шоколад', -1, 'Нельзя! Шоколад вреден котикам. −1 ❤️'),
  Food('🧅', 'Лук', -1, 'Лук ядовит для котиков! −1 ❤️'),
];

class CatGamePage extends StatefulWidget {
  const CatGamePage({super.key});

  @override
  State<CatGamePage> createState() => _CatGamePageState();
}

class _CatGamePageState extends State<CatGamePage> {
  static const int maxHearts = 3;
  final Random _random = Random();

  int level = 1;
  int hearts = maxHearts;
  int score = 0;

  late int gridSize;
  late int catIndex;
  late int triesLeft;
  final Set<int> opened = {};
  Phase phase = Phase.searching;
  int satiety = 0;
  String catFace = '😿';
  String message = '';
  List<Food> foods = List.of(kFoods);

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  /// Прячем котика в новом месте. Поле растёт каждые 2 уровня (3x3 … 6x6).
  void _startRound() {
    gridSize = min(3 + (level - 1) ~/ 2, 6);
    catIndex = _random.nextInt(gridSize * gridSize);
    triesLeft = gridSize + 1;
    opened.clear();
    phase = Phase.searching;
    satiety = 0;
    catFace = '😿';
    foods = List.of(kFoods)..shuffle(_random);
    message = 'Котик спрятался в одном из квадратиков. Найди его!\n'
        'Цифра в открытом квадрате — сколько шагов до котика.';
  }

  void _restartGame() {
    setState(() {
      level = 1;
      hearts = maxHearts;
      score = 0;
      _startRound();
    });
  }

  int _distance(int a, int b) {
    final ra = a ~/ gridSize, ca = a % gridSize;
    final rb = b ~/ gridSize, cb = b % gridSize;
    return (ra - rb).abs() + (ca - cb).abs();
  }

  String _steps(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'шаг';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'шага';
    return 'шагов';
  }

  void _openCell(int index) {
    if (phase != Phase.searching || opened.contains(index)) return;
    setState(() {
      opened.add(index);

      if (index == catIndex) {
        phase = Phase.feeding;
        catFace = '😿';
        message = 'Ура, нашёл котика! Он очень голодный — покорми его 🍽️';
        return;
      }

      triesLeft--;
      final d = _distance(index, catIndex);
      final hint = d == 1
          ? 'Горячо! 🔥'
          : d == 2
              ? 'Тепло 🙂'
              : 'Холодно ❄️';

      if (triesLeft > 0) {
        message = '$hint До котика $d ${_steps(d)}.';
        return;
      }

      hearts--;
      if (hearts <= 0) {
        phase = Phase.gameOver;
        message = 'Попытки и жизни закончились 😢\nКотик ждёт тебя в новой игре!';
      } else {
        phase = Phase.escaped;
        catFace = '🐈';
        message = 'Попытки кончились — котик был вот тут! −1 ❤️\n'
            'Он перепрятался, попробуй ещё раз.';
      }
    });
  }

  void _feed(Food food) {
    if (phase != Phase.feeding) return;
    setState(() {
      message = food.reaction;

      if (food.value < 0) {
        hearts--;
        catFace = '🙀';
        if (hearts <= 0) {
          phase = Phase.gameOver;
          message = '${food.reaction}\nЖизни закончились — игра окончена.';
        }
        return;
      }

      if (food.value == 0) {
        catFace = '😾';
        return;
      }

      satiety = min(100, satiety + food.value);
      if (satiety >= 100) {
        phase = Phase.full;
        catFace = '😻';
        final bonus = 10 + triesLeft * 5;
        score += bonus;
        message = 'Котик сыт и мурлычет! +$bonus ⭐';
      } else {
        catFace = satiety >= 50 ? '😺' : '😸';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EC),
      appBar: AppBar(
        title: const Text('Найди котика 🐱'),
        centerTitle: true,
        backgroundColor: scheme.primaryContainer,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatus(),
              const SizedBox(height: 12),
              _buildMessage(scheme),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AspectRatio(aspectRatio: 1, child: _buildGrid()),
                ),
              ),
              const SizedBox(height: 12),
              _buildBottomPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    const style = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    final heartsText =
        List.generate(maxHearts, (i) => i < hearts ? '❤️' : '🤍').join(' ');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Уровень $level', style: style),
        Text(heartsText, style: style),
        Text('⭐ $score', style: style),
      ],
    );
  }

  Widget _buildMessage(ColorScheme scheme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(message),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: gridSize * gridSize,
      itemBuilder: (context, i) => _buildCell(i),
    );
  }

  Widget _buildCell(int i) {
    final isOpen = opened.contains(i);
    final showCat = i == catIndex &&
        (isOpen || phase == Phase.escaped || phase == Phase.gameOver);

    Color color;
    Widget child;
    if (showCat) {
      color = Colors.white;
      child = _CatView(face: catFace);
    } else if (isOpen) {
      final d = _distance(i, catIndex);
      final maxD = 2 * (gridSize - 1);
      final t = maxD <= 1 ? 0.0 : ((d - 1) / (maxD - 1)).clamp(0.0, 1.0);
      color = Color.lerp(Colors.red.shade300, Colors.lightBlue.shade200, t)!;
      child = Text(
        '$d',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    } else {
      color = Colors.orange.shade300;
      child = const Text(
        '?',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openCell(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    switch (phase) {
      case Phase.searching:
        return Text(
          'Осталось попыток: $triesLeft',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        );
      case Phase.feeding:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Сытость  ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: satiety / 100,
                      minHeight: 14,
                    ),
                  ),
                ),
                Text('  $satiety%', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final f in foods)
                  ActionChip(
                    avatar: Text(f.emoji),
                    label: Text(f.name),
                    onPressed: () => _feed(f),
                  ),
              ],
            ),
          ],
        );
      case Phase.full:
        return FilledButton.icon(
          onPressed: () => setState(() {
            level++;
            _startRound();
          }),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Следующий уровень'),
        );
      case Phase.escaped:
        return FilledButton.icon(
          onPressed: () => setState(_startRound),
          icon: const Icon(Icons.refresh),
          label: const Text('Искать снова'),
        );
      case Phase.gameOver:
        return FilledButton.icon(
          onPressed: _restartGame,
          icon: const Icon(Icons.replay),
          label: const Text('Играть заново'),
        );
    }
  }
}

/// Котик, который «подпрыгивает» каждый раз, когда меняется его настроение.
class _CatView extends StatelessWidget {
  const _CatView({required this.face});

  final String face;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(face),
      tween: Tween(begin: 0.5, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Text(face, style: const TextStyle(fontSize: 56)),
    );
  }
}
