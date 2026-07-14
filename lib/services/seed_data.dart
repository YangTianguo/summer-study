import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/plan.dart';
import '../models/task.dart';

/// 根据「杨田安_暑期提升计划.md」生成初始学习计划数据
class SeedDataService {
  static const _keyPlans = 'storage_plans';
  static const _keyTasks = 'storage_tasks';
  static const _keyLogs = 'storage_completion_logs';
  static const _seedFlag = 'seed_data_imported';

  static Future<bool> hasSeedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seedFlag) ?? false;
  }

  static Future<void> importSeedData() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = const Uuid();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final plans = <Plan>[];
    final taskMaps = <Map<String, dynamic>>[];
    final logMaps = <Map<String, dynamic>>[];

    // ================================================================
    // 计划1: 📐 数学强化（每日约3小时）
    // ================================================================
    final mathPlanId = uuid.v4();
    plans.add(Plan(
      id: mathPlanId,
      title: '📐 数学强化',
      description: '第一阶段：有理数运算 → 整式加减 → 一元一次方程 → 几何初步。每天先做20道计算题（限时20分钟），错题必须整理到错题本。',
      type: 'daily',
      subject: '数学',
      startDate: today,
      endDate: today.add(const Duration(days: 56)), // 8周
      createdAt: now,
    ));
    taskMaps.addAll([
      _makeTask(uuid, mathPlanId, '上午：数学基础学习（看课本例题→盖住答案自己写→对照批改）', '数学', 90, 0, now),
      _makeTask(uuid, mathPlanId, '上午：20道计算题（限时20分钟）', '数学', 20, 1, now),
      _makeTask(uuid, mathPlanId, '晚上：数学强化训练 + 错题重做', '数学', 90, 2, now),
      _makeTask(uuid, mathPlanId, '整理错题本（每道错题写：错因+正确解法+同类题1道）', '数学', 15, 3, now),
    ]);

    // ================================================================
    // 计划2: 🔤 英语突破（每日约2.5小时）
    // ================================================================
    final engPlanId = uuid.v4();
    plans.add(Plan(
      id: engPlanId,
      title: '🔤 英语突破',
      description: '每天背15个新词 + 复习旧词。第1-3周攻克音标，第1-4周七上课文，第5-6周七下+语法，第7-8周初二预习。大声朗读！',
      type: 'daily',
      subject: '英语',
      startDate: today,
      endDate: today.add(const Duration(days: 56)),
      createdAt: now,
    ));
    taskMaps.addAll([
      _makeTask(uuid, engPlanId, '早晨：英语晨读（大声朗读课文/单词20分钟）', '英语', 30, 0, now),
      _makeTask(uuid, engPlanId, '上午：背15个新单词 + 音标学习', '英语', 45, 1, now),
      _makeTask(uuid, engPlanId, '上午：语法学习（每学一个语法造5个句子）', '英语', 30, 2, now),
      _makeTask(uuid, engPlanId, '晚上：单词滚动复习（用艾宾浩斯记忆法）', '英语', 30, 3, now),
      _makeTask(uuid, engPlanId, '碎片时间：英语听力磨耳朵（午餐/晚餐时播放课文录音）', '英语', 15, 4, now),
    ]);

    // ================================================================
    // 计划3: 📚 语文提升（每日1.5小时）
    // ================================================================
    final chnPlanId = uuid.v4();
    plans.add(Plan(
      id: chnPlanId,
      title: '📚 语文提升',
      description: '古诗文逐篇背诵默写，每天1篇现代文阅读，每周1篇作文。阅读《朝花夕拾》《西游记》。',
      type: 'daily',
      subject: '语文',
      startDate: today,
      endDate: today.add(const Duration(days: 56)),
      createdAt: now,
    ));
    taskMaps.addAll([
      _makeTask(uuid, chnPlanId, '下午：古诗文背诵默写（七上+七下逐篇过关）', '语文', 20, 0, now),
      _makeTask(uuid, chnPlanId, '下午：现代文阅读1篇（做完对答案，总结答题模板）', '语文', 30, 1, now),
      _makeTask(uuid, chnPlanId, '下午：文言文字词解释+翻译练习', '语文', 20, 2, now),
      _makeTask(uuid, chnPlanId, '阅读《朝花夕拾》或《西游记》30分钟', '语文', 30, 3, now),
    ]);

    // ================================================================
    // 计划4: 🧬 生物复习（每日1小时）
    // ================================================================
    final bioPlanId = uuid.v4();
    plans.add(Plan(
      id: bioPlanId,
      title: '🧬 生物复习',
      description: '七上：细胞结构、生态系统。七下：人体各系统。画图理解，用"结构→功能"逻辑串联知识点。',
      type: 'daily',
      subject: '生物',
      startDate: today,
      endDate: today.add(const Duration(days: 56)),
      createdAt: now,
    ));
    taskMaps.addAll([
      _makeTask(uuid, bioPlanId, '下午：生物课本复习（画图理解：细胞结构/人体系统示意图）', '生物', 40, 0, now),
      _makeTask(uuid, bioPlanId, '整理生物知识点笔记（结构→功能串联）', '生物', 20, 1, now),
    ]);

    // ================================================================
    // 计划5: 📖 小科轮换（历史/地理/政治，每日轮换一门，45分钟）
    // ================================================================
    final smallPlanId = uuid.v4();
    plans.add(Plan(
      id: smallPlanId,
      title: '📖 小科轮换背诵',
      description: '周一/四：历史（画时间轴，背朝代事件）。周二/五：地理（看地图，记区域特征）。周三/六：政治（背知识点+答题套路）。',
      type: 'daily',
      subject: '综合',
      startDate: today,
      endDate: today.add(const Duration(days: 56)),
      createdAt: now,
    ));
    taskMaps.addAll([
      _makeTask(uuid, smallPlanId, '上午：小科轮换学习（历史/地理/政治每日一科）', '综合', 45, 0, now),
      _makeTask(uuid, smallPlanId, '周六：本周小科知识点回顾 + 抽背检查', '综合', 30, 1, now),
    ]);

    // ================================================================
    // 计划6: 📝 每日必修习惯
    // ================================================================
    final habitPlanId = uuid.v4();
    plans.add(Plan(
      id: habitPlanId,
      title: '📝 每日必修习惯',
      description: '错题整理、当日复习、早睡早起。周日休息日可灵活安排。',
      type: 'daily',
      subject: '综合',
      startDate: today,
      endDate: today.add(const Duration(days: 56)),
      createdAt: now,
    ));
    taskMaps.addAll([
      _makeTask(uuid, habitPlanId, '下午：当日复习（回顾当天所有科目所学内容30分钟）', '综合', 30, 0, now),
      _makeTask(uuid, habitPlanId, '晚上：背诵类知识回顾（闭眼复述才算过）', '综合', 15, 1, now),
      _makeTask(uuid, habitPlanId, '晚9:30前洗漱准备就寝', '综合', 5, 2, now),
      _makeTask(uuid, habitPlanId, '晚10:00熄灯睡觉（保证8小时+睡眠）', '综合', 5, 3, now),
    ]);

    // ================================================================
    // 写入存储
    // ================================================================
    await prefs.setString(_keyPlans, jsonEncode(plans.map((p) => p.toMap()).toList()));
    await prefs.setString(_keyTasks, jsonEncode(taskMaps));
    await prefs.setString(_keyLogs, jsonEncode(logMaps));
    await prefs.setBool(_seedFlag, true);
  }

  static Map<String, dynamic> _makeTask(
    Uuid uuid, String planId, String title, String subject,
    int minutes, int sortOrder, DateTime now,
  ) {
    return Task(
      id: uuid.v4(),
      planId: planId,
      title: title,
      subject: subject,
      estimatedMinutes: minutes,
      sortOrder: sortOrder,
      createdAt: now,
    ).toMap();
  }
}
