import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../services/livekit_service.dart';

class RoomPage extends StatefulWidget {
  final String? roomId;
  final String roomTitle;

  const RoomPage({super.key, this.roomId, this.roomTitle = 'Sala'});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final voice = SolLiveKitService();
  final messageController = TextEditingController();
  RealtimeChannel? roomChannel;

  List<Map<String, dynamic>> participants = [];
  List<Map<String, dynamic>> messages = [];
  String? currentUserId;
  String? roomError;
  String? voiceError;
  int seatCapacity = 30;
  bool loading = true;
  bool connecting = false;
  bool voiceConnected = false;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser?.id;
    refresh();
    subscribeToRoom();
  }

  void subscribeToRoom() {
    final id = widget.roomId;
    if (id == null || id.isEmpty) return;
    roomChannel = supabase
        .channel('sol-room:$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: id,
          ),
          callback: (_) => unawaited(refresh()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: id,
          ),
          callback: (_) => unawaited(refresh()),
        )
        .subscribe();
  }

  Future<void> refresh() async {
    final id = widget.roomId;
    if (id == null || id.isEmpty) {
      if (mounted) {
        setState(() {
          loading = false;
          roomError = 'Esta sala não tem um identificador válido.';
        });
      }
      return;
    }

    if (mounted) setState(() => loading = true);
    try {
      final roomRow = await supabase
          .from('room_sessions')
          .select('seats,status,chat_enabled')
          .eq('id', id)
          .maybeSingle();
      if (roomRow == null || roomRow['status'] != 'live') {
        throw Exception('A sala não existe ou não está ao vivo.');
      }

      final seatRows = await supabase
          .from('room_participants')
          .select('member_id,seat_no,mic_enabled,joined_at,left_at')
          .eq('room_id', id)
          .isFilter('left_at', null)
          .order('seat_no');

      final messageRows = await supabase
          .from('room_chat_messages')
          .select('sender_user_id,body,created_at')
          .eq('room_id', id)
          .order('created_at', ascending: false)
          .limit(50);

      if (!mounted) return;
      setState(() {
        seatCapacity = (roomRow['seats'] as num?)?.toInt() ?? 30;
        participants = List<Map<String, dynamic>>.from(seatRows);
        messages = List<Map<String, dynamic>>.from(messageRows).reversed
            .toList();
        currentUserId = supabase.auth.currentUser?.id;
        roomError = null;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        roomError = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  int? get mySeat {
    for (final participant in participants) {
      if (participant['member_id']?.toString() == currentUserId) {
        return (participant['seat_no'] as num?)?.toInt();
      }
    }
    return null;
  }

  Map<String, dynamic>? participantAt(int seatNo) {
    for (final participant in participants) {
      if ((participant['seat_no'] as num?)?.toInt() == seatNo) {
        return participant;
      }
    }
    return null;
  }

  Future<void> takeSeat(int seatNo) async {
    final roomId = widget.roomId;
    final userId = currentUserId ?? supabase.auth.currentUser?.id;
    if (roomId == null || userId == null) {
      setState(
        () => roomError = 'Entre na sua conta antes de ocupar uma cadeira.',
      );
      return;
    }

    try {
      await supabase.rpc(
        'claim_room_seat',
        params: {
          'p_room_id': roomId,
          'p_member_id': userId,
          'p_seat_no': seatNo,
        },
      );
      await refresh();
    } catch (e) {
      if (mounted) {
        setState(() => roomError = 'Não foi possível ocupar a cadeira: $e');
      }
    }
  }

  Future<void> leaveSeat() async {
    final roomId = widget.roomId;
    final userId = currentUserId ?? supabase.auth.currentUser?.id;
    if (roomId == null || userId == null) return;

    try {
      if (voiceConnected) {
        await voice.disconnect();
        voiceConnected = false;
      }
      await supabase.rpc(
        'leave_room_seat',
        params: {'p_room_id': roomId, 'p_member_id': userId},
      );
      if (mounted) setState(() => voiceError = null);
      await refresh();
    } catch (e) {
      if (mounted) {
        setState(() => roomError = 'Não foi possível liberar a cadeira: $e');
      }
    }
  }

  Future<void> toggleVoice() async {
    final roomId = widget.roomId;
    final userId = currentUserId ?? supabase.auth.currentUser?.id;
    if (roomId == null || userId == null) {
      setState(() => voiceError = 'Entre na sua conta para usar o áudio.');
      return;
    }

    if (voiceConnected) {
      setState(() {
        connecting = true;
        voiceError = null;
      });
      try {
        await voice.disconnect();
        await supabase.rpc(
          'set_room_mic',
          params: {
            'p_room_id': roomId,
            'p_member_id': userId,
            'p_enabled': false,
          },
        );
        if (mounted) setState(() => voiceConnected = false);
        await refresh();
      } catch (e) {
        if (mounted) setState(() => voiceError = e.toString());
      } finally {
        if (mounted) setState(() => connecting = false);
      }
      return;
    }

    if (mySeat == null) {
      setState(
        () => voiceError =
            'Primeiro ocupe uma cadeira; depois ligue o microfone.',
      );
      return;
    }

    setState(() {
      connecting = true;
      voiceError = null;
    });
    try {
      final response = await supabase.functions.invoke(
        'sol-livekit-token',
        body: {'roomId': roomId},
      );
      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          'Servidor de voz respondeu HTTP ${response.status}: ${response.data}',
        );
      }
      if (response.data is! Map) {
        throw Exception('Resposta inválida do servidor de voz.');
      }
      final data = Map<String, dynamic>.from(response.data as Map);
      final url = data['url']?.toString() ?? '';
      final token = data['token']?.toString() ?? '';
      if (url.isEmpty || token.isEmpty) {
        throw Exception('O servidor não devolveu URL e token LiveKit.');
      }

      final connectedRoom = await voice.connect(url: url, token: token);
      final localParticipant = connectedRoom.localParticipant;
      if (localParticipant == null) {
        throw Exception('LiveKit conectou sem participante local.');
      }
      await localParticipant.setMicrophoneEnabled(true);
      await supabase.rpc(
        'set_room_mic',
        params: {'p_room_id': roomId, 'p_member_id': userId, 'p_enabled': true},
      );
      if (mounted) setState(() => voiceConnected = true);
      await refresh();
    } catch (e) {
      await voice.disconnect();
      if (mounted) {
        setState(() {
          voiceConnected = false;
          voiceError = 'Falha ao conectar o áudio: $e';
        });
      }
    } finally {
      if (mounted) setState(() => connecting = false);
    }
  }

  Future<void> sendMessage() async {
    final roomId = widget.roomId;
    final userId = currentUserId ?? supabase.auth.currentUser?.id;
    final body = messageController.text.trim();
    if (roomId == null || userId == null || body.isEmpty || sending) return;

    setState(() => sending = true);
    try {
      await supabase.from('room_chat_messages').insert({
        'room_id': roomId,
        'sender_user_id': userId,
        'body': body,
      });
      messageController.clear();
      await refresh();
    } catch (e) {
      if (mounted) {
        setState(() => roomError = 'Não foi possível enviar a mensagem: $e');
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    if (roomChannel != null) {
      unawaited(supabase.removeChannel(roomChannel!));
    }
    voice.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownSeat = mySeat;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomTitle),
        actions: [
          IconButton(
            tooltip: 'Atualizar sala',
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (roomError != null)
              Card(
                color: const Color(0xff44232a),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(roomError!),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Áudio ao vivo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ownSeat == null
                          ? 'Ocupe uma cadeira para falar na sala.'
                          : 'Você está na cadeira $ownSeat.',
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: connecting || loading ? null : toggleVoice,
                      icon: Icon(voiceConnected ? Icons.call_end : Icons.mic),
                      label: Text(
                        connecting
                            ? 'Conectando…'
                            : voiceConnected
                            ? 'Desligar microfone'
                            : 'Conectar e ligar microfone',
                      ),
                    ),
                    if (voiceError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          voiceError!,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cadeiras (${participants.length}/$seatCapacity)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (ownSeat != null)
                  TextButton.icon(
                    onPressed: loading ? null : leaveSeat,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair da cadeira'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: seatCapacity,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width >= 600
                      ? 6
                      : 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final seatNo = index + 1;
                  final occupant = participantAt(seatNo);
                  final occupied = occupant != null;
                  final mine =
                      occupant?['member_id']?.toString() == currentUserId;
                  final canTap = !occupied || mine;
                  return Material(
                    color: mine
                        ? const Color(0xff493a13)
                        : occupied
                        ? const Color(0xff172238)
                        : const Color(0xff101a2d),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: !canTap || loading
                          ? null
                          : mine
                          ? leaveSeat
                          : () => takeSeat(seatNo),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: mine
                                ? const Color(0xffffd35a)
                                : occupied
                                ? const Color(0xff4b5c78)
                                : const Color(0xff293b58),
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              occupied
                                  ? Icons.person
                                  : Icons.event_seat_outlined,
                              color: mine
                                  ? const Color(0xffffd35a)
                                  : Colors.white70,
                              size: 24,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Cadeira $seatNo',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              mine
                                  ? 'Você'
                                  : occupied
                                  ? 'Ocupada'
                                  : 'Livre',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            if (occupant?['mic_enabled'] == true)
                              const Icon(
                                Icons.mic,
                                size: 14,
                                color: Color(0xff9fe3b1),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 18),
            const Text(
              'Chat da sala',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (messages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Nenhuma mensagem nesta sala ainda.'),
              )
            else
              ...messages.map((message) {
                final isMine =
                    message['sender_user_id']?.toString() == currentUserId;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isMine ? Icons.person : Icons.chat_bubble_outline,
                  ),
                  title: Text(isMine ? 'Você' : 'Participante'),
                  subtitle: Text((message['body'] ?? '').toString()),
                );
              }),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Escreva uma mensagem',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar mensagem',
                  onPressed: sending ? null : sendMessage,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
