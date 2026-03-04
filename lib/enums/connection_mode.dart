enum ConnectionMode {
  
  usb('usb', 'USB'),
  
  wifi('wifi', 'Wi-Fi');

  final String code;
  final String label;

  const ConnectionMode(this.code, this.label);

  static ConnectionMode fromCode(String code) {
    return values.firstWhere((element) => element.code == code);
  }
}
