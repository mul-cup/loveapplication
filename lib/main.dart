import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '연애대백과',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const IntroPage(),
    );
  }
}

// IntroPage: 하트 떨어지는 애니메이션 + 시작하기 버튼
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  final Random random = Random();
  final List<_FallingHeart> hearts = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (hearts.length < 30) {
        setState(() {
          hearts.add(
            _FallingHeart(
              key: UniqueKey(),
              x: random.nextDouble(),
              size: 20 + random.nextDouble() * 20,
              speed: 1 + random.nextDouble() * 2,
              startY: -0.1 - random.nextDouble(),
            ),
          );
        });
      }
      setState(() {
        hearts.removeWhere((heart) => heart.startY > 1.2);
        for (var heart in hearts) {
          heart.startY += heart.speed * 0.01;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: Stack(
        children: [
          // 떨어지는 하트들
          ...hearts.map((heart) {
            return Positioned(
              left: heart.x * size.width,
              top: heart.startY * size.height,
              child: Opacity(
                opacity: 0.7,
                child: Text(
                  '❤️',
                  style: TextStyle(
                    fontSize: heart.size,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.pinkAccent,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // 중앙 텍스트 + 시작하기 버튼
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '💖 연애대백과 💖',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                      shadows: [
                        Shadow(color: Colors.pinkAccent, blurRadius: 8),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '사랑하는 사람과의 한때를\n더욱 빛나도록',
                    style: TextStyle(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: () {
                      _timer.cancel();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthPage(),
                        ),
                      );
                    },
                    child: const Text('시작하기'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallingHeart {
  final Key key;
  final double x; // 0~1, 가로 위치 비율
  final double size;
  double startY; // 0~1, 세로 위치 비율
  final double speed;

  _FallingHeart({
    required this.key,
    required this.x,
    required this.size,
    required this.startY,
    required this.speed,
  });
}

// 회원가입/로그인 화면 + 약관 동의 포함 + 이름/D-day 저장 유지
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLoginMode = true; // true: 로그인, false: 회원가입

  final TextEditingController idController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController pwConfirmController = TextEditingController();

  String? errorMessage;

  bool agreedTerms = false;
  bool agreedPrivacy = false;

  // 간단히 메모리 저장하는 회원 DB (실제 앱에선 서버 연동 필요)
  final Map<String, String> _userDB = {};

  @override
  void initState() {
    super.initState();
    _loadUserDB();
  }

  // 예시로 SharedPreferences에서 저장한 유저 DB 불러오기
  Future<void> _loadUserDB() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('user_')) {
        final pw = prefs.getString(key);
        if (pw != null) {
          _userDB[key.substring(5)] = pw;
        }
      }
    }
  }

  Future<void> _saveUser(String id, String pw) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_$id', pw);
  }

  void _toggleMode() {
    setState(() {
      errorMessage = null;
      isLoginMode = !isLoginMode;
      idController.clear();
      pwController.clear();
      pwConfirmController.clear();
      agreedTerms = false;
      agreedPrivacy = false;
    });
  }

  void _signUp() async {
    final id = idController.text.trim();
    final pw = pwController.text.trim();
    final pwConfirm = pwConfirmController.text.trim();

    if (id.isEmpty || pw.isEmpty || pwConfirm.isEmpty) {
      setState(() {
        errorMessage = '모든 항목을 입력하세요.';
      });
      return;
    }

    if (!agreedTerms || !agreedPrivacy) {
      setState(() {
        errorMessage = '약관에 모두 동의해야 합니다.';
      });
      return;
    }

    if (pw != pwConfirm) {
      setState(() {
        errorMessage = '비밀번호와 비밀번호 확인이 일치하지 않습니다.';
      });
      return;
    }

    if (_userDB.containsKey(id)) {
      setState(() {
        errorMessage = '이미 존재하는 아이디입니다.';
      });
      return;
    }

    _userDB[id] = pw;
    await _saveUser(id, pw);

    setState(() {
      errorMessage = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다! 로그인 해주세요.')));

    _toggleMode(); // 로그인 모드로 전환
  }

  void _login() {
    final id = idController.text.trim();
    final pw = pwController.text.trim();

    if (id.isEmpty || pw.isEmpty) {
      setState(() {
        errorMessage = '아이디와 비밀번호를 모두 입력하세요.';
      });
      return;
    }

    if (!_userDB.containsKey(id) || _userDB[id] != pw) {
      setState(() {
        errorMessage = '아이디 또는 비밀번호가 올바르지 않습니다.';
      });
      return;
    }

    setState(() {
      errorMessage = null;
    });

    // 로그인 성공 시 ID 저장
    _saveLoggedInUser(id);

    // 로그인 성공, 홈 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(loggedInId: id)),
    );
  }

  Future<void> _saveLoggedInUser(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUser', id);
  }

  @override
  void dispose() {
    idController.dispose();
    pwController.dispose();
    pwConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLoginMode ? '로그인' : '회원가입'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (!isLoginMode) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: pwConfirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (!isLoginMode) ...[
                  CheckboxListTile(
                    value: agreedTerms,
                    onChanged: (v) {
                      setState(() {
                        agreedTerms = v ?? false;
                      });
                    },
                    title: const Text('이용 약관에 동의합니다.'),
                  ),
                  CheckboxListTile(
                    value: agreedPrivacy,
                    onChanged: (v) {
                      setState(() {
                        agreedPrivacy = v ?? false;
                      });
                    },
                    title: const Text('개인정보 처리방침에 동의합니다.'),
                  ),
                ],
                const SizedBox(height: 12),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isLoginMode ? _login : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(isLoginMode ? '로그인' : '회원가입'),
                ),
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(isLoginMode ? '회원가입 하러가기' : '로그인 하러가기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// HomePage: 로그인 후 사용자 이름과 사귄 날짜 불러와 보여주고 수정 가능,
// 추천 데이트룩, 추천 데이트 코스 버튼 추가
class HomePage extends StatefulWidget {
  final String loggedInId;

  const HomePage({super.key, required this.loggedInId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String myName = '';
  String partnerName = '';
  DateTime? dateTogether;

  int get days {
    if (dateTogether == null) return 0;
    final now = DateTime.now();
    return now.difference(dateTogether!).inDays + 1;
  }

  final TextEditingController myNameController = TextEditingController();
  final TextEditingController partnerNameController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadNamesAndDate();
  }

  Future<void> _loadNamesAndDate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myName = prefs.getString('${widget.loggedInId}_myName') ?? '';
      partnerName = prefs.getString('${widget.loggedInId}_partnerName') ?? '';
      final dateString = prefs.getString('${widget.loggedInId}_dateTogether');
      if (dateString != null) {
        dateTogether = DateTime.tryParse(dateString);
      }
    });
  }

  Future<void> _saveNamesAndDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${widget.loggedInId}_myName', myName);
    await prefs.setString('${widget.loggedInId}_partnerName', partnerName);
    if (dateTogether != null) {
      await prefs.setString(
        '${widget.loggedInId}_dateTogether',
        dateTogether!.toIso8601String(),
      );
    }
  }

  void _onChangeName() {
    myNameController.text = myName;
    partnerNameController.text = partnerName;
    selectedDate = dateTogether;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이름 및 사귄 날짜 변경'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: myNameController,
                  decoration: const InputDecoration(labelText: '내 이름'),
                ),
                TextField(
                  controller: partnerNameController,
                  decoration: const InputDecoration(labelText: '파트너 이름'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('사귄 날짜: '),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? now,
                          firstDate: DateTime(now.year - 10),
                          lastDate: now,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        selectedDate == null
                            ? '날짜 선택'
                            : '${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  myName = myNameController.text.trim();
                  partnerName = partnerNameController.text.trim();
                  dateTogether = selectedDate;
                });
                _saveNamesAndDate();
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  // 로그아웃 처리
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUser');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연애대백과'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$myName ❤️ $partnerName',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text('사귄 지 $days일째 💕', style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _onChangeName,
                icon: const Icon(Icons.edit),
                label: const Text('이름 및 날짜 변경'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),

              // 추천 데이트룩 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DateLookPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade300,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('추천 데이트룩'),
              ),
              const SizedBox(height: 12),

              // 추천 데이트 코스 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DateCoursePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade300,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('추천 데이트 코스'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 추천 데이트룩 페이지 (간단 샘플)
class DateLookPage extends StatelessWidget {
  const DateLookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추천 데이트룩')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '여기에 추천 데이트룩 정보를 보여줍니다.',
                style: TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('뒤로가기'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 추천 데이트 코스 페이지 (간단 샘플)
class DateCoursePage extends StatelessWidget {
  const DateCoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추천 데이트 코스')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '여기에 추천 데이트 코스 정보를 보여줍니다.',
                style: TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('뒤로가기'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
