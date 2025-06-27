import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void initSocket(String userId) {
    socket = IO.io('ws://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('Connected to server');
      _isConnected = true;
      socket.emit('join', userId);
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
      _isConnected = false;
    });

    socket.connect();
  }

  void joinTodoRoom(String todoId) {
    if (_isConnected) {
      socket.emit('join_todo', todoId);
    }
  }

  void leaveTodoRoom(String todoId) {
    if (_isConnected) {
      socket.emit('leave_todo', todoId);
    }
  }

  void emitTodoUpdate(Map<String, dynamic> todoData) {
    if (_isConnected) {
      socket.emit('todo_update', todoData);
    }
  }

  void onTodoUpdate(Function(Map<String, dynamic>) callback) {
    socket.on('todo_updated', (data) => callback(data));
  }

  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
      _isConnected = false;
    }
  }
}