enum ConnectionStatus {
  connected('connected', '已连接'),
  connecting('connecting', '连接中'),
  disconnected('disconnected', '未连接');

  final String code;
  final String label;
  const ConnectionStatus(this.code, this.label);

  static ConnectionStatus fromCode(String code) {
    return values.firstWhere((element) => element.code == code);
  }

}
