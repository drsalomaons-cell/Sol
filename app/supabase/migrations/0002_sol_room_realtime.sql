-- Enable realtime events for the live room seat grid and room chat.
-- Safe additive publication change; tables already exist.
ALTER PUBLICATION supabase_realtime ADD TABLE public.room_participants, public.room_chat_messages;
