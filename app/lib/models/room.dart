import '../core/room_layout.dart';

enum SeatState { empty, occupied, locked }

class RoomSeat {
  final int index;
  final SeatState state;
  final String? userId;
  const RoomSeat(this.index, {this.state = SeatState.empty, this.userId});
}

class SolRoom {
  final String id;
  final String name;
  final String hostId;
  final RoomSeatLayout seatLayout;
  final int online;
  const SolRoom({required this.id, required this.name, required this.hostId, required this.seatLayout, this.online = 0});
}

