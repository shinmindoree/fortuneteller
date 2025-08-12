import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/openai_service.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../models/saju_chars.dart';
import 'saju_input_screen.dart'; // Added import for SajuInputScreen
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class YulhyunChatbotScreen extends StatefulWidget {
  final String name;
  final DateTime birthDate;
  final TimeOfDay birthTime;
  final String gender;
  final bool isLunar;
  final SajuChars sajuChars;
  
  const YulhyunChatbotScreen({
    super.key,
    required this.name,
    required this.birthDate,
    required this.birthTime,
    required this.gender,
    required this.isLunar,
    required this.sajuChars,
  });

  @override
  State<YulhyunChatbotScreen> createState() => _YulhyunChatbotScreenState();
}

class _YulhyunChatbotScreenState extends State<YulhyunChatbotScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  bool _isLoading = false;
  int _remainingQuestions = 10; // 무료 질문 10개 제한
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  late AnimationController _cursorAnimationController;
  Widget? _bannerAdWidget;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cursorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // 저장된 사용 횟수 로드
    _loadUsageCount();
    _loadBannerAd();
    
    // 율현 법사 인사말
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _cursorAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 저장된 사용 횟수 로드
  Future<void> _loadUsageCount() async {
    try {
      final prefs = await StorageService.instance.preferences;
      final usedCount = prefs.getInt('chatbot_questions_used') ?? 0;
      setState(() {
        _remainingQuestions = math.max(0, 10 - usedCount);
      });
    } catch (e) {
      print('사용 횟수 로드 실패: $e');
    }
  }

  /// 사용 횟수 저장
  Future<void> _saveUsageCount() async {
    try {
      final prefs = await StorageService.instance.preferences;
      final usedCount = 10 - _remainingQuestions;
      await prefs.setInt('chatbot_questions_used', usedCount);
    } catch (e) {
      print('사용 횟수 저장 실패: $e');
    }
  }

  void _addWelcomeMessage() {
    final name = widget.name.isEmpty ? '고객님' : widget.name;
    final birthInfo = '${widget.birthDate.year}년 ${widget.birthDate.month}월 ${widget.birthDate.day}일 ${widget.birthTime.hour.toString().padLeft(2, '0')}:${widget.birthTime.minute.toString().padLeft(2, '0')} (${widget.isLunar ? '음력' : '양력'})';
    
    final welcomeMessage = '''안녕하세요! 저는 율현 법사입니다. 🔮

$name님의 사주를 확인해보니 ${widget.sajuChars.display}이네요.
$birthInfo에 태어나신 $name님의 운세를 상담해드리겠습니다.

무료로 10가지 질문에 답변해드릴 수 있어요. 
사주, 운세, 길일 등 무엇이든 편하게 물어보세요!''';
    
    _messages.add(ChatMessage(
      text: welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (_remainingQuestions <= 0) {
      _showAdDialog();
      return;
    }

    // 사용자 메시지 추가
        _messages.add(ChatMessage(
      text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ));

        _messageController.clear();
    _scrollToBottom();

      setState(() {
        _isLoading = true;
        _remainingQuestions--;
      });

    // 사용 횟수 저장
    await _saveUsageCount();

    try {
      // AI 응답 생성
      final response = await _generateAIResponse(message);
      
      if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
            isTyping: true,
        ));
          _isLoading = false;
      });
      _scrollToBottom();
      
        // 타이핑 효과 시작
      _startTypingEffect(_messages.length - 1);
      }
    } catch (e) {
      if (mounted) {
      setState(() {
        _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 광고 시청 후 무료 질문 리셋 다이얼로그
  void _showAdDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.play_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              '광고 시청',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '무료 질문을 모두 사용하셨습니다!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '짧은 광고를 시청하시면:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('10번의 무료 질문을 다시 받을 수 있습니다'),
              _buildFeatureItem('즉시 사용 가능'),
              _buildFeatureItem('무료 서비스'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '약 30초 소요',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              print('🖱️ 광고 시청 버튼 클릭됨 - print');
              debugPrint('🖱️ 광고 시청 버튼 클릭됨 - debugPrint');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('버튼이 클릭되었습니다!'),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.of(context).pop();
              _watchAd();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('광고 시청하기'),
          ),
        ],
      ),
    );
  }

  /// 광고 시청 처리
  Future<void> _watchAd() async {
    debugPrint('🎬 _watchAd 함수 시작');
    
    // 광고 로드 중 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('광고 로드 중...'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              const Text('광고를 준비하고 있습니다...'),
              const SizedBox(height: 8),
              const Text(
                '잠시만 기다려주세요',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      debugPrint('🔄 광고 로드 시작...');
      // 광고 로드
      await AdService.instance.loadRewardedAd();
      debugPrint('✅ 광고 로드 완료');
      
      if (mounted) {
        debugPrint('🔄 로딩 다이얼로그 닫기');
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        debugPrint('🎬 광고 표시 시작...');
        // 광고 표시
        final adWatched = await AdService.instance.showRewardedAd();
        debugPrint('✅ 광고 표시 완료, 시청 여부: $adWatched');
        
        if (adWatched) {
          debugPrint('🎁 광고 시청 완료, 사용 횟수 리셋 시작');
          // 광고 시청 완료 시 사용 횟수 리셋
          await _resetUsageCount();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('광고 시청 완료! 10번의 무료 질문을 다시 받으셨습니다.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          debugPrint('❌ 광고 시청 실패');
          // 광고 로드 실패 시
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('광고 로드에 실패했습니다. 잠시 후 다시 시도해주세요.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 광고 시청 중 오류 발생: $e');
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('광고 시청 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 사용 횟수 리셋
  Future<void> _resetUsageCount() async {
    try {
      final prefs = await StorageService.instance.preferences;
      await prefs.setInt('chatbot_questions_used', 0);
      setState(() {
        _remainingQuestions = 10;
      });
    } catch (e) {
      print('사용 횟수 리셋 실패: $e');
    }
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF1A237E),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBannerAd() async {
    try {
      debugPrint('🔄 배너 광고 로드 시작...');
      final bannerAd = await AdService.instance.loadBannerAd();
      if (bannerAd != null && mounted) {
        setState(() {
          _bannerAdWidget = AdService.instance.getBannerAdWidget();
        });
        debugPrint('✅ 배너 광고 로드 완료');
      } else {
        debugPrint('❌ 배너 광고 로드 실패');
      }
    } catch (e) {
      debugPrint('❌ 배너 광고 로드 중 오류: $e');
    }
  }


  void _startTypingEffect(int messageIndex) {
    if (messageIndex < 0 || messageIndex >= _messages.length) return;
    
    final message = _messages[messageIndex];
    if (message.isUser) return; // 사용자 메시지는 타이핑 효과 없음
    
    setState(() {
      _messages[messageIndex] = message.copyWith(isTyping: true, typingIndex: 0);
    });
    
    // 커서 애니메이션 시작
    _cursorAnimationController.repeat();
    
    _animateTyping(messageIndex);
  }

  void _animateTyping(int messageIndex) {
    if (messageIndex < 0 || messageIndex >= _messages.length) return;
    
    final message = _messages[messageIndex];
    if (!message.isTyping) return;
    
    if (message.typingIndex < message.text.length) {
      // ChatGPT와 유사한 타이핑 속도 (4배 빠르게)
      final char = message.text[message.typingIndex];
      int delay;
      
      // 문자별 타이핑 속도 조절
      if (char == ' ' || char == '\n') {
        delay = 1; // 공백과 줄바꿈은 매우 빠르게
      } else if (char == '.' || char == '!' || char == '?' || char == ',') {
        delay = 2; // 문장 부호는 잠시 멈춤 (4배 빠르게)
      } else {
        delay = 1; // 일반 문자는 빠른 속도 (4배 빠르게)
      }
      
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          setState(() {
            _messages[messageIndex] = message.copyWith(
              typingIndex: message.typingIndex + 1,
            );
          });
          _scrollToBottom();
          _animateTyping(messageIndex);
        }
      });
    } else {
      // 타이핑 완료
      setState(() {
        _messages[messageIndex] = message.copyWith(isTyping: false);
      });
      _cursorAnimationController.stop();
    }
  }

  Future<String> _generateAIResponse(String userMessage) async {
    final prompt = '''
당신은 율현 법사입니다. 사주명리학 전문가로서 친근하고 따뜻한 톤으로 답변해주세요.

사용자 정보:
- 이름: ${widget.name}
- 생년월일: ${widget.birthDate.year}년 ${widget.birthDate.month}월 ${widget.birthDate.day}일
- 태어난 시간: ${widget.birthTime.hour}시 ${widget.birthTime.minute}분
- 성별: ${widget.gender}
- 음력/양력: ${widget.isLunar ? '음력' : '양력'}
- 사주 8자: ${widget.sajuChars.display}

사용자 질문: $userMessage

율현 법사로서 친근하고 전문적인 답변을 해주세요. 사주명리학 지식을 바탕으로 하되, 너무 복잡하지 않게 설명해주세요.

답변은 200~400자 내외로 간결하게 해주세요.
''';

    try {
      final response = await OpenAIService.instance.generateResponse(prompt);
      return response;
    } catch (e) {
      return '죄송합니다. 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1021),
        elevation: 0,
        title: const Text(
          '율현 법사',
                style: TextStyle(
            fontWeight: FontWeight.bold,
                  color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _confirmChangeProfile,
            icon: const Icon(Icons.edit, color: Colors.white, size: 18),
            label: const Text(
              '사주 정보 변경',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          if (_remainingQuestions <= 0)
            TextButton(
              onPressed: _showAdDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8C6A00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '광고 시청',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_remainingQuestions > 0)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                color: const Color(0x3322FF88),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '남은 질문: $_remainingQuestions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0E1A), Color(0xFF101426), Color(0xFF12162A)],
          ),
        ),
        child: SafeArea(
        child: Column(
          children: [
              // 사주 정보 표시
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x11FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Color(0x55D4AF37), blurRadius: 12, spreadRadius: 1)],
                      ),
                      child: Text(
                        '${(widget.name.isEmpty ? '고객님' : widget.name)}님의 사주',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.sajuChars.display,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 채팅 메시지 목록
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                    return _buildTypingIndicator();
                  }
                    return _buildMessage(_messages[index]);
                },
              ),
            ),
              // 메시지 입력 영역
            Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1021),
                  boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                        enabled: _remainingQuestions > 0,
                      decoration: InputDecoration(
                          hintText: _remainingQuestions > 0 ? '무엇이 궁금하신가요…' : '광고 시청 후 질문 가능',
                          hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                          fillColor: const Color(0x22FFFFFF),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                        ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: Icon(
                        Icons.send,
                        color: _remainingQuestions > 0 ? const Color(0xFFD4AF37) : const Color(0xFF8C6A00),
                    ),
                  ),
                ],
              ),
              ),
              // 배너 광고 영역 (입력창 아래 실제 위치)
              if (_bannerAdWidget != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 6, bottom: 6),
                  child: _bannerAdWidget!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFFD4AF37),
              child: const FaIcon(FontAwesomeIcons.yinYang, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0x3322FF88) : const Color(0x11FFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: message.isUser ? const Color(0x5522FF88) : const Color(0x22FFFFFF)),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.isTyping 
                        ? message.text.substring(0, message.typingIndex)
                        : message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (message.isTyping) ...[
                    const SizedBox(height: 2),
                    AnimatedBuilder(
                      animation: _cursorAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _cursorAnimationController.value,
                          child: Container(
                            width: 8,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF22263D),
              child: const FaIcon(FontAwesomeIcons.yinYang, color: Color(0xFFD4AF37), size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFD4AF37),
            child: const FaIcon(FontAwesomeIcons.yinYang, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x11FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x22FFFFFF)),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                    final delay = index * 0.2;
        final animationValue = math.max(0.0, _typingAnimationController.value - delay);
        
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.3 + (0.6 * animationValue)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Future<void> _confirmChangeProfile() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사주 정보 변경'),
        content: const Text('사주 정보를 변경하시겠습니까?\n저장된 프로필을 초기화하고 다시 입력합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('초기화 후 변경'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      // 저장된 프로필 삭제 후 입력 화면으로 이동
      await StorageService.instance.deleteSajuProfile();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SajuInputScreen()),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;
  final int typingIndex;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
    this.typingIndex = 0,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isTyping,
    int? typingIndex,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
      typingIndex: typingIndex ?? this.typingIndex,
    );
  }
}