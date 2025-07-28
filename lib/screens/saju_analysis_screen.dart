import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/openai_service.dart';
import '../models/saju_chars.dart';
import '../models/calendar_event.dart';
import 'calendar_screen.dart';

class SajuAnalysisScreen extends StatefulWidget {
  final SajuChars sajuChars;
  final String name;
  final DateTime birthDate;
  final String gender;
  final bool isLunar;

  const SajuAnalysisScreen({
    super.key,
    required this.sajuChars,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.isLunar,
  });

  @override
  State<SajuAnalysisScreen> createState() => _SajuAnalysisScreenState();
}

class _SajuAnalysisScreenState extends State<SajuAnalysisScreen> {
  SajuAnalysisResult? _analysisResult;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  Future<void> _performAnalysis() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await OpenAIService.instance.analyzeSaju(
        sajuChars: widget.sajuChars,
        name: widget.name.isEmpty ? '익명' : widget.name,
        birthDate: widget.birthDate,
        gender: widget.gender,
        isLunar: widget.isLunar,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사주 분석 결과'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _performAnalysis,
              tooltip: '다시 분석하기',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_analysisResult == null) {
      return _buildEmptyWidget();
    }

    return _buildAnalysisResult();
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'AI가 사주를 분석하고 있습니다...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '잠시만 기다려주세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '분석 중 오류가 발생했습니다',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performAnalysis,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Text('분석 결과가 없습니다.'),
    );
  }

  Widget _buildAnalysisResult() {
    final result = _analysisResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기본 정보 카드
          _buildBasicInfoCard(),
          const SizedBox(height: 16),
          
          // 성격 분석
          _buildPersonalityCard(result.personality),
          const SizedBox(height: 16),
          
          // 운세 분석
          _buildFortuneCard(result.fortune),
          const SizedBox(height: 16),
          
          // 주의 시기
          _buildCautionCard(result.cautionPeriod),
          const SizedBox(height: 16),
          
          // 길일 추천
          _buildGoodDaysCard(result.goodDays),
          const SizedBox(height: 16),
          
          // 종합 요약
          _buildSummaryCard(result.summary),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '기본 정보',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('이름', widget.name.isEmpty ? '익명' : widget.name),
            _buildInfoRow('생년월일', 
                '${DateFormat('yyyy년 MM월 dd일').format(widget.birthDate)} (${widget.isLunar ? '음력' : '양력'})'),
            _buildInfoRow('성별', widget.gender),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '사주 8자',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.sajuChars.display,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityCard(String personality) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '성격 및 기질',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              personality,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneCard(Fortune fortune) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '운세 분석',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFortuneItem('💰', '재물운', fortune.wealth),
            const SizedBox(height: 12),
            _buildFortuneItem('💼', '직업운', fortune.career),
            const SizedBox(height: 12),
            _buildFortuneItem('🏥', '건강운', fortune.health),
            const SizedBox(height: 12),
            _buildFortuneItem('❤️', '애정운', fortune.love),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneItem(String emoji, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26.0),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildCautionCard(String cautionPeriod) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '주의사항',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              cautionPeriod,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoodDaysCard(List<GoodDay> goodDays) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '추천 길일',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (goodDays.isEmpty)
              Text(
                '추천 길일이 없습니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              ...goodDays.map((goodDay) => _buildGoodDayItem(goodDay)).toList(),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _addGoodDaysToCalendar(goodDays),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('캘린더에 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoodDayItem(GoodDay goodDay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                goodDay.date,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goodDay.purpose,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            goodDay.reason,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '종합 운세',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  /// AI 추천 길일을 캘린더에 추가
  void _addGoodDaysToCalendar(List<GoodDay> goodDays) {
    try {
      // GoodDay를 CalendarEvent로 변환
      final events = goodDays.map((goodDay) {
        return CalendarEvent.fromGoodDay(
          goodDay.date,
          goodDay.purpose,
          goodDay.reason,
        );
      }).toList();

      // 캘린더 화면으로 이동하면서 이벤트 전달
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CalendarScreen(
            initialEvents: events,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${goodDays.length}개의 길일이 캘린더에 추가되었습니다'),
          action: SnackBarAction(
            label: '확인',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('캘린더 추가 중 오류가 발생했습니다: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
} 