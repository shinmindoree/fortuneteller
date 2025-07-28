import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/saju_calculator.dart';
import '../models/saju_chars.dart';
import 'saju_analysis_screen.dart';

class SajuInputScreen extends StatefulWidget {
  const SajuInputScreen({super.key});

  @override
  State<SajuInputScreen> createState() => _SajuInputScreenState();
}

class _SajuInputScreenState extends State<SajuInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLunar = false;
  String? _selectedGender;
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      helpText: '태어난 시간 선택',
      cancelText: '취소',
      confirmText: '확인',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('생년월일을 선택해주세요')),
        );
        return;
      }
      
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('태어난 시간을 선택해주세요')),
        );
        return;
      }
      
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성별을 선택해주세요')),
        );
        return;
      }

      _calculateAndShowSaju();
    }
  }

  void _calculateAndShowSaju() {
    try {
      // 사주 계산 실행
      final sajuChars = SajuCalculator.instance.calculateSaju(
        birthDate: _selectedDate!,
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        isLunar: _isLunar,
        gender: _selectedGender!,
      );

      // 계산 결과를 다이얼로그로 표시
      _showSajuResult(sajuChars);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사주 계산 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _showSajuResult(SajuChars sajuChars) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사주 8자 계산 결과'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 입력 정보
              Text(
                '📋 입력 정보',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('이름: ${_nameController.text.isEmpty ? '없음' : _nameController.text}'),
              Text('생년월일: ${DateFormat('yyyy년 MM월 dd일').format(_selectedDate!)} (${_isLunar ? '음력' : '양력'})'),
              Text('태어난 시간: ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'),
              Text('성별: $_selectedGender'),
              const SizedBox(height: 16),
              
              // 8자 결과
              Text(
                '🔮 사주 8자',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sajuChars.display,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              
              // 상세 정보
              Text('년주 (年柱): ${sajuChars.year.display}'),
              Text('월주 (月柱): ${sajuChars.month.display}'),
              Text('일주 (日柱): ${sajuChars.day.display}'),
              Text('시주 (時柱): ${sajuChars.hour.display}'),
              const SizedBox(height: 12),
              
              Text(
                '💡 일간(日干): ${sajuChars.day.cheongan.name}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '이 사주의 중심이 되는 천간입니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // AI 분석 화면으로 이동
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SajuAnalysisScreen(
                    sajuChars: sajuChars,
                    name: _nameController.text,
                    birthDate: _selectedDate!,
                    gender: _selectedGender!,
                    isLunar: _isLunar,
                  ),
                ),
              );
            },
            child: const Text('AI 분석하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사주 정보 입력'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 메시지
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '사주 분석을 위한 정보',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '정확한 사주 분석을 위해 생년월일과 태어난 시간을 정확히 입력해주세요.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 이름 입력
              Text(
                '이름 (선택사항)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '이름을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              
              // 생년월일 입력
              Text(
                '생년월일 *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? '생년월일을 선택하세요'
                            : DateFormat('yyyy년 MM월 dd일').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 음력/양력 선택
              Row(
                children: [
                  Text(
                    '달력 종류',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: _isLunar,
                          onChanged: (value) {
                            setState(() {
                              _isLunar = value!;
                            });
                          },
                        ),
                        const Text('양력'),
                        const SizedBox(width: 16),
                        Radio<bool>(
                          value: true,
                          groupValue: _isLunar,
                          onChanged: (value) {
                            setState(() {
                              _isLunar = value!;
                            });
                          },
                        ),
                        const Text('음력'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 태어난 시간 입력
              Text(
                '태어난 시간 *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime == null
                            ? '태어난 시간을 선택하세요'
                            : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _selectedTime == null
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 성별 선택
              Text(
                '성별 *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGender = '남성';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedGender == '남성'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            width: _selectedGender == '남성' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _selectedGender == '남성'
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.male,
                              color: _selectedGender == '남성'
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '남성',
                              style: TextStyle(
                                color: _selectedGender == '남성'
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: _selectedGender == '남성'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGender = '여성';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedGender == '여성'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            width: _selectedGender == '여성' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _selectedGender == '여성'
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.female,
                              color: _selectedGender == '여성'
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '여성',
                              style: TextStyle(
                                color: _selectedGender == '여성'
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: _selectedGender == '여성'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // 제출 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome),
                      const SizedBox(width: 8),
                      Text(
                        '사주 분석하기',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 