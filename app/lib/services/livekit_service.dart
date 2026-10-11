import 'package:livekit_client/livekit_client.dart';

class SolLiveKitService {
  Room? room;
  Future<Room> connect({required String url, required String token}) async {
    room = Room();
    await room!.connect(url, token);
    return room!;
  }
  Future<void> disconnect() async { await room?.disconnect(); room = null; }
}

