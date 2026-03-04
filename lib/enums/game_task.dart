/// 游戏任务类型
/// 用于区分不同的游戏任务类型
enum GameTaskType {
  daily('daily', '日常', '日常任务: 包含了除魔任务，师门任务，宝图任务，竞技任务，试炼任务'),
  fishing('fishing', '钓鱼', '钓鱼任务: 根据当前钓鱼类型可以自动调成年鱼和鱼宝宝'),
  dungeon('dungeon', '副本', '副本任务: 选择你要进行的副本任务，开始进行自动完成副本');

  final String code;
  final String label;
  final String desc;

  const GameTaskType(this.code, this.label, this.desc);

  /// 根据标签获取游戏任务类型
  static GameTaskType fromCode(String code) =>
      GameTaskType.values.firstWhere((e) => e.code == code);
}
