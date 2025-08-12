import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/saju_calculator.dart';
import '../models/saju_chars.dart';
import 'yulhyun_chatbot_screen.dart';
import '../services/storage_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 시진 데이터 클래스
class Sijin {
  final String name;
  final String timeRange;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  
  const Sijin({
    required this.name,
    required this.timeRange,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  static const List<Sijin> sijinList = [
    Sijin(name: '자시(子時)', timeRange: '23:30 ~ 01:30', startHour: 23, startMinute: 30, endHour: 1, endMinute: 30),
    Sijin(name: '축시(丑時)', timeRange: '01:30 ~ 03:30', startHour: 1, startMinute: 30, endHour: 3, endMinute: 30),
    Sijin(name: '인시(寅時)', timeRange: '03:30 ~ 05:30', startHour: 3, startMinute: 30, endHour: 5, endMinute: 30),
    Sijin(name: '묘시(卯時)', timeRange: '05:30 ~ 07:30', startHour: 5, startMinute: 30, endHour: 7, endMinute: 30),
    Sijin(name: '진시(辰時)', timeRange: '07:30 ~ 09:30', startHour: 7, startMinute: 30, endHour: 9, endMinute: 30),
    Sijin(name: '사시(巳時)', timeRange: '09:30 ~ 11:30', startHour: 9, startMinute: 30, endHour: 11, endMinute: 30),
    Sijin(name: '오시(午時)', timeRange: '11:30 ~ 13:30', startHour: 11, startMinute: 30, endHour: 13, endMinute: 30),
    Sijin(name: '미시(未時)', timeRange: '13:30 ~ 15:30', startHour: 13, startMinute: 30, endHour: 15, endMinute: 30),
    Sijin(name: '신시(申時)', timeRange: '15:30 ~ 17:30', startHour: 15, startMinute: 30, endHour: 17, endMinute: 30),
    Sijin(name: '유시(酉時)', timeRange: '17:30 ~ 19:30', startHour: 17, startMinute: 30, endHour: 19, endMinute: 30),
    Sijin(name: '술시(戌時)', timeRange: '19:30 ~ 21:30', startHour: 19, startMinute: 30, endHour: 21, endMinute: 30),
    Sijin(name: '해시(亥時)', timeRange: '21:30 ~ 23:30', startHour: 21, startMinute: 30, endHour: 23, endMinute: 30),
  ];
}

class SajuInputScreen extends StatefulWidget {
  const SajuInputScreen({super.key});

  @override
  State<SajuInputScreen> createState() => _SajuInputScreenState();
}

class _SajuInputScreenState extends State<SajuInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  
  DateTime? _selectedDate;
  Sijin? _selectedSijin;
  bool _isLunar = false;
  String? _selectedGender;
  bool _isLoading = false;
  bool _hasSavedProfile = false;
  
  // 선택 항목들
  String? _selectedMaritalStatus;
  String? _selectedBloodType;
  
  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkSavedProfile();
  }

  Future<void> _checkSavedProfile() async {
    final profile = await StorageService.instance.getSajuProfile();
    if (mounted) {
      setState(() {
        _hasSavedProfile = profile != null;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)), // 25년 전
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: '생년월일 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectSijin() async {
    final Sijin? picked = await showDialog<Sijin>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            '태어난 시진 선택',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: Sijin.sijinList.length,
              itemBuilder: (context, index) {
                final sijin = Sijin.sijinList[index];
                return ListTile(
                  title: Text(
                    sijin.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    sijin.timeRange,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(sijin);
                  },
                  selected: _selectedSijin == sijin,
                  selectedTileColor: const Color(0x33FFD700),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedSijin = picked;
      });
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      appBar: AppBar(
        title: const Text(
          '사주 정보 입력',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D1021),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_hasSavedProfile)
            TextButton(
              onPressed: _startWithSaved,
              child: const Text(
                '이전 저장 불러오기',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '사주 정보를 계산하고 있습니다...',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0E1A), Color(0xFF12162A)],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 헤더 (유리 카드)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0x11FFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 6)),
                            ],
                          ),
                          child: const Column(
                            children: [
                              FaIcon(FontAwesomeIcons.yinYang, size: 44, color: Color(0xFFD4AF37)),
                              SizedBox(height: 16),
                              Text(
                                '율현 법사와 상담하기',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '사주 관련 정보를 입력하시면\n율현법사와 상담할 수 있습니다',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 필수 입력 항목들
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x11FFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          child: Column(
                            children: [
                              // 이름 입력
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: '이름을 입력하세요',
                                  hintStyle: const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: const Color(0x22FFFFFF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이름을 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              
                              // 생년월일 선택
                              InkWell(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0x33FFFFFF)),
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0x22FFFFFF),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.white70),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedDate != null
                                            ? DateFormat('yyyy년 MM월 dd일').format(_selectedDate!)
                                            : '생년월일을 선택하세요',
                                        style: TextStyle(
                                          color: _selectedDate != null ? Colors.white : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // 태어난 시진 선택
                              InkWell(
                                onTap: _selectSijin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0x33FFFFFF)),
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0x22FFFFFF),
                                  ),
                                  child: Row(
                                    children: [
                                      const FaIcon(FontAwesomeIcons.yinYang, color: Colors.white70, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedSijin != null
                                                  ? _selectedSijin!.name
                                                  : '태어난 시진을 선택하세요',
                                              style: TextStyle(
                                                color: _selectedSijin != null ? Colors.white : Colors.white70,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_selectedSijin != null)
                                              Text(
                                                _selectedSijin!.timeRange,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // 성별 선택
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0x33FFFFFF)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0x22FFFFFF),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('남성', style: TextStyle(color: Colors.white, fontSize: 14)),
                                        value: '남성',
                                        groupValue: _selectedGender,
                                        activeColor: const Color(0xFFD4AF37),
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGender = value;
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('여성', style: TextStyle(color: Colors.white, fontSize: 14)),
                                        value: '여성',
                                        groupValue: _selectedGender,
                                        activeColor: const Color(0xFFD4AF37),
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGender = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // 음력/양력 선택
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0x33FFFFFF)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0x22FFFFFF),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<bool>(
                                        title: const Text('양력', style: TextStyle(color: Colors.white, fontSize: 14)),
                                        value: false,
                                        groupValue: _isLunar,
                                        activeColor: const Color(0xFFD4AF37),
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (value) {
                                          setState(() {
                                            _isLunar = value!;
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<bool>(
                                        title: const Text('음력', style: TextStyle(color: Colors.white, fontSize: 14)),
                                        value: true,
                                        groupValue: _isLunar,
                                        activeColor: const Color(0xFFD4AF37),
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (value) {
                                          setState(() {
                                            _isLunar = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 선택 항목들
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x08FFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37), size: 20),
                                  SizedBox(width: 8),
                                  Text('선택 입력 (더 자세한 분석을 원한다면)', 
                                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // 결혼 여부
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0x33FFFFFF)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0x22FFFFFF),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('기혼', style: TextStyle(color: Colors.white, fontSize: 14)),
                                        value: '기혼',
                                        groupValue: _selectedMaritalStatus,
                                        activeColor: const Color(0xFFD4AF37),
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedMaritalStatus = value;
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('미혼', style: TextStyle(color: Colors.white, fontSize: 14)),
                                        value: '미혼',
                                        groupValue: _selectedMaritalStatus,
                                        activeColor: const Color(0xFFD4AF37),
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedMaritalStatus = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // 거주 도시
                              TextFormField(
                                controller: _cityController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: '현재 거주 도시 (예: 서울, 부산)',
                                  hintStyle: const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: const Color(0x22FFFFFF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // 혈액형
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0x33FFFFFF)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0x22FFFFFF),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: const Text('A형', style: TextStyle(color: Colors.white, fontSize: 14)),
                                            value: 'A형',
                                            groupValue: _selectedBloodType,
                                            activeColor: const Color(0xFFD4AF37),
                                            contentPadding: EdgeInsets.zero,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedBloodType = value;
                                              });
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: const Text('B형', style: TextStyle(color: Colors.white, fontSize: 14)),
                                            value: 'B형',
                                            groupValue: _selectedBloodType,
                                            activeColor: const Color(0xFFD4AF37),
                                            contentPadding: EdgeInsets.zero,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedBloodType = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: const Text('O형', style: TextStyle(color: Colors.white, fontSize: 14)),
                                            value: 'O형',
                                            groupValue: _selectedBloodType,
                                            activeColor: const Color(0xFFD4AF37),
                                            contentPadding: EdgeInsets.zero,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedBloodType = value;
                                              });
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: const Text('AB형', style: TextStyle(color: Colors.white, fontSize: 14)),
                                            value: 'AB형',
                                            groupValue: _selectedBloodType,
                                            activeColor: const Color(0xFFD4AF37),
                                            contentPadding: EdgeInsets.zero,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedBloodType = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 상담 시작 버튼
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            '율현 법사와 상담 시작',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _startWithSaved() async {
    final profile = await StorageService.instance.getSajuProfile();
    if (profile == null) return;

    final name = profile['name'] as String? ?? '';
    final birthDate = DateTime.parse(profile['birthDate'] as String);
    final hour = (profile['hour'] as num).toInt();
    final minute = (profile['minute'] as num).toInt();
    final gender = profile['gender'] as String? ?? '남성';
    final isLunar = profile['isLunar'] as bool? ?? false;

    final sajuChars = SajuCalculator.instance.calculateSaju(
      birthDate: birthDate,
      hour: hour,
      minute: minute,
      isLunar: isLunar,
      gender: gender,
    );

    // 선택 항목들도 불러오기
    final maritalStatus = profile['maritalStatus'] as String?;
    final city = profile['city'] as String?;
    final bloodType = profile['bloodType'] as String?;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => YulhyunChatbotScreen(
          name: name,
          birthDate: birthDate,
          birthTime: TimeOfDay(hour: hour, minute: minute),
          gender: gender,
          isLunar: isLunar,
          sajuChars: sajuChars,
          maritalStatus: maritalStatus,
          city: city,
          bloodType: bloodType,
        ),
      ),
    );
  }

  void _submitForm() async {
    // 필수 항목 검증
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('생년월일을 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedSijin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('태어난 시진을 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('성별을 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _calculateAndShowSaju();
  }

  Future<void> _calculateAndShowSaju() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 시진에서 대표 시간 추출 (시작 시간 사용)
      final hour = _selectedSijin!.startHour;
      final minute = _selectedSijin!.startMinute;
      
      final sajuChars = SajuCalculator.instance.calculateSaju(
        birthDate: _selectedDate!,
        hour: hour,
        minute: minute,
        isLunar: _isLunar,
        gender: _selectedGender!,
      );

      // 기본 프로필 정보
      final profileData = {
        'name': _nameController.text.trim(),
        'birthDate': _selectedDate!.toIso8601String(),
        'hour': hour,
        'minute': minute,
        'gender': _selectedGender!,
        'isLunar': _isLunar,
        'sijin': _selectedSijin!.name, // 시진 정보도 저장
      };

      // 선택 항목이 있으면 추가
      if (_selectedMaritalStatus != null) {
        profileData['maritalStatus'] = _selectedMaritalStatus!;
      }
      if (_cityController.text.trim().isNotEmpty) {
        profileData['city'] = _cityController.text.trim();
      }
      if (_selectedBloodType != null) {
        profileData['bloodType'] = _selectedBloodType!;
      }

      // 프로필 저장
      await StorageService.instance.saveSajuProfileMap(profileData);

      if (!mounted) return;
      
      // 챗봇 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => YulhyunChatbotScreen(
            name: _nameController.text.trim(),
            birthDate: _selectedDate!,
            birthTime: TimeOfDay(hour: hour, minute: minute),
            gender: _selectedGender!,
            isLunar: _isLunar,
            sajuChars: sajuChars,
            // 선택 항목들도 전달
            maritalStatus: _selectedMaritalStatus,
            city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
            bloodType: _selectedBloodType,
          ),
        ),
      );
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
} 