import { DefaultData } from "@/store/index";
import { FetchNUI } from "@/utils";
import { storeToRefs } from "pinia";

export default function () {
  const StoreData = DefaultData();
  const {
    ShowChat,
    ShowChatInput,
    ChatMessages,
    RPTexts,
    SongData,
    VolumeRange,
    ShowNotification,
    Themes,
    Colors,
    ChatCategories,
    ChatMessageColors,
    Commands,
    QuickCommands,
    Emojis,
    AllowedURLs,
    Locales,
    DefaultCommands
  } = storeToRefs(StoreData);

  window.addEventListener("message", async ({ data }) => {
    switch (data.action) {
      case 'SHOW_CHAT':
        ShowChat.value = true;
        ShowChatInput.value = true;
        break;
      case 'OPEN_NUI':
        document.getElementById('#main').style.display = 'flex';
        break;
      case 'CHECK_NUI':
        FetchNUI('NUI_READY', {})
        break;
      case 'SET_CONFIG':
        const Config = data.payload;

        Themes.value = Config.Themes || [];
        Colors.value = Config.ThemeColors || [];
        ChatCategories.value = Config.Categories || [];
        ChatMessageColors.value = Config.MessageColors || {};
        QuickCommands.value = Config.QuickCommands || [];
        AllowedURLs.value = Config.AllowedURLs || [];
        Locales.value = Config.Locales || [];
        Emojis.value = Config.Emojis || [];

        StoreData.GetTheme();
        StoreData.GetColor();
        StoreData.GetPosition();
        StoreData.GetSize();
        StoreData.GetThreadType();
        StoreData.GetNotification();

        FetchNUI('CONFIG_READY', {});
        break;
      case 'SEND_MESSAGE':
        const request = data.payload;

        if (request.isImage) {
          const imageURL = request.message;

          if (AllowedURLs.value.some(url => imageURL.startsWith(url))) {

            ChatMessages.value.push({
              ...request,
              id: ChatMessages.value.length + 1,
              time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            });

            if (ShowNotification.value) {
              ShowChat.value = true;
              setTimeout(() => {
                if (ShowChatInput.value === false) {
                  ShowChat.value = false;
                }
              }, 5000);
            };
          };
        } else {
          ChatMessages.value.push({
            ...request,
            id: ChatMessages.value.length + 1,
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          });

          if (ShowNotification.value) {
            ShowChat.value = true;
            setTimeout(() => {
              if (ShowChatInput.value === false) {
                ShowChat.value = false;
              }
            }, 5000);
          };
        };
        break;
      case 'SHOW_3D_TEXT':
        if (!data.payload.message || !data.payload.message.trim()) return;
        const index = RPTexts.value.findIndex(text => text.source === data.payload.source);

        if (index !== -1) {
          RPTexts.value[index] = {
            ...RPTexts.value[index],
            screenX: data.payload.screenX,
            screenY: data.payload.screenY,
            message: data.payload.message,
            category: data.payload.category,
          };
        } else {
          RPTexts.value.push(data.payload);
        };
        break;
      case 'REMOVE_3D_TEXT':
        const textIndex = RPTexts.value.findIndex(text => text.source === data.payload.source);
        if (textIndex !== -1) {
          RPTexts.value.splice(textIndex, 1);
        }
        break;
      case 'ADD_SUGGESTION':
        const command = data.payload;
        if (Commands.value.find(c => c.name === command.name)) return;

        Commands.value.push(command);
        break;
      case 'PLAY_SONG':
        const song = data.payload;
        if (song && song.url) {
          const response = await fetch(`https://noembed.com/embed?url=${song.url}`);
          const data = await response.json();

          SongData.value = {
            title: data.title,
            url: song.url,
          };

          FetchNUI('SONG_PLAYING', SongData.value);
        }
        break;
      case 'SONG_DATA':
        const songData = data.payload;
        if (songData && songData.title && songData.url) {
          SongData.value = {
            title: songData.title,
            url: songData.url,
            volume: songData.volume || 1.0,
            isPlaying: songData.isPlaying || false,
          };

          VolumeRange.value = Math.round(songData.volume * 100);
        } else {
          SongData.value = {};
        }
        break;
      case 'ADD_CHAT_COMMAND_SUGGESTION':
        const chatCommand = data.payload;

        DefaultCommands.value.push({
          name: chatCommand.command,
          description: chatCommand.description || '',
          aliases: chatCommand.params || [],
        });
        break;
      case 'CLEAR_CHAT':
        ChatMessages.value = [];
        break;
      default:
        break;
    }
  });
}