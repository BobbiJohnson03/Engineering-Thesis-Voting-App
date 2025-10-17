// lib/network/ws_client.dart
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectWs(String baseWsUrl, String meetingId) {
  // baseWsUrl example: ws://192.168.1.10:8080
  final url = Uri.parse('$baseWsUrl/ws?mid=$meetingId');
  return WebSocketChannel.connect(url);
}

/// Optional: a tiny wrapper with lifecycle & callbacks
class WsService {
  final String baseWsUrl;
  final String meetingId;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  WsService({required this.baseWsUrl, required this.meetingId});

  void connect({
    void Function(dynamic msg)? onMessage,
    void Function()? onDone,
    void Function(Object err)? onError,
  }) {
    _channel = connectWs(baseWsUrl, meetingId);
    _sub = _channel!.stream.listen(
      (msg) => onMessage?.call(msg),
      onDone: onDone,
      onError: onError,
      cancelOnError: true,
    );
  }

  void send(String data) => _channel?.sink.add(data);

  Future<void> close() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _sub = null;
  }
}
