enum RoomSeatLayout { eight, nine, ten, twelve, fifteen, twenty }

class RoomLayoutSpec {
  final RoomSeatLayout layout;
  final int seats;
  final int columns;
  const RoomLayoutSpec(this.layout, this.seats, this.columns);
}

const roomLayouts = <RoomLayoutSpec>[
  RoomLayoutSpec(RoomSeatLayout.eight, 8, 4),
  RoomLayoutSpec(RoomSeatLayout.nine, 9, 3),
  RoomLayoutSpec(RoomSeatLayout.ten, 10, 5),
  RoomLayoutSpec(RoomSeatLayout.twelve, 12, 4),
  RoomLayoutSpec(RoomSeatLayout.fifteen, 15, 5),
  RoomLayoutSpec(RoomSeatLayout.twenty, 20, 5),
];

RoomLayoutSpec layoutFor(RoomSeatLayout layout) => roomLayouts.firstWhere((x) => x.layout == layout);

