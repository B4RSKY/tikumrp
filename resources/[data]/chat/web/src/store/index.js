import { defineStore } from "pinia";
import { FetchNUI } from "@/utils";

export const DefaultData = defineStore("DefaultData", {
  state: () => ({
    PlayerData: {
      name: "No.1 Developer",
    },
    ShowSettings: false,
    ShowChat: false,
    ShowChatInput: false,
    ShowMoreOptions: false,
    ShowEmojiMenu: false,
    ShowNotification: false,
    ShowCommandList: false,
    ThreadType: "dui",
    Themes: [],
    Colors: [],
    Positions: [
      { name: "top-left" },
      { name: "top-center" },
      { name: "top-right" },
      { name: "center-left" },
      { name: "center-right" },
      { name: "bottom-left" },
      { name: "bottom-center" },
      { name: "bottom-right" },
    ],
    Sizes: [
      { name: "small", label: "Small", size: 0.9 },
      { name: "medium", label: "Medium", size: 1.0 },
      { name: "large", label: "Large", size: 1.1 },
    ],
    ChatCategories: [],
    ChatMessages: [],
    ChatInput: "",
    ChatMessageColors: {},
    Commands: [],
    DefaultCommands: [],
    QuickCommands: [],
    RPTexts: [],
    SelectedTheme: { name: "grids", label: "Grids" },
    SelectedColor: { name: "black", hex: "#000", text: '#fff', box: '#0000007d', from: 'rgba(0, 0, 0, .35)', to: 'rgba(0, 0, 0, 0)' },
    SelectedSize: { name: "medium", label: "Medium", size: 1.0 },
    SelectedPosition: { name: "top-left" },
    SelectedCategory: { name: "all", label: "All" },
    AllowedURLs: [],
    SongData: {},
    VolumeRange: 0.0,
    Emojis: [],
    CurrentRecentUsedCommand: -1,
    RecentUsedCommands: [],
    Locales: {},
  }),
  actions: {
    CloseUi() {
      document.getElementById('main-ui').style.display = 'none';

      setTimeout(() => {
        FetchNUI('close');
      }, 500);
    },
    SetTheme(theme) {
      this.SelectedTheme = theme;
      this.SetColor(theme.defaultTheme);
    },
    SetColor(color) {
      this.SelectedColor = color;
    },
    GetTheme() {
      const theme = localStorage.getItem('theme');

      if (theme) {
        this.SelectedTheme = JSON.parse(theme);
      } else {
        this.SelectedTheme = this.Themes[0];
        localStorage.setItem('theme', JSON.stringify(this.SelectedTheme));
      }
    },
    GetColor() {
      const color = localStorage.getItem('color');
      if (color) {
        this.SelectedColor = JSON.parse(color);
      } else {
        this.SelectedColor = this.Colors[0];
        localStorage.setItem('color', JSON.stringify(this.SelectedColor));
      }
    },
    GetPosition() {
      const position = localStorage.getItem('position');
      if (position) {
        this.SelectedPosition = JSON.parse(position);
      } else {
        this.SelectedPosition = this.Positions[0];
        localStorage.setItem('position', JSON.stringify(this.SelectedPosition));
      }
    },
    GetSize() {
      const size = localStorage.getItem('size');
      if (size) {
        this.SelectedSize = JSON.parse(size);
      } else {
        this.SelectedSize = this.Sizes[1];
        localStorage.setItem('size', JSON.stringify(this.SelectedSize));
      }
    },
    GetThreadType() {
      const threadType = localStorage.getItem('thread');
      if (threadType) {
        this.ThreadType = threadType;
      } else {
        this.ThreadType = 'dui';
        localStorage.setItem('thread', this.ThreadType);
      }
    },
    GetNotification() {
      const notification = localStorage.getItem('notification');
      if (notification) {
        this.ShowNotification = notification;
      } else {
        this.ShowNotification = true;
        localStorage.setItem('notification', this.ShowNotification);
      }
    },
    GetPositionText() {
      const position = this.SelectedPosition.name;
      const filteredPosition = position.replace(/-/g, ' ');
      return filteredPosition.charAt(0).toLowerCase() + filteredPosition.slice(1);
    },
    SaveSettings() {
      localStorage.setItem('color', JSON.stringify(this.SelectedColor));
      localStorage.setItem('theme', JSON.stringify(this.SelectedTheme));
      localStorage.setItem('position', JSON.stringify(this.SelectedPosition));
      localStorage.setItem('size', JSON.stringify(this.SelectedSize));
      localStorage.setItem('thread', this.ThreadType);
      localStorage.setItem('notification', this.ShowNotification);

      FetchNUI('TOGGLE_THREAD', { type: this.ThreadType });
    },
    CancelSettings() {
      this.GetTheme();
      this.GetColor();
      this.GetPosition();
      this.GetSize();
      this.GetThreadType();
      this.GetNotification();
      this.ShowSettings = false;
    },
    ToggleSettings() {
      if (this.ShowCommandList) {
        this.ShowCommandList = false;

        setTimeout(() => {
          this.ShowSettings = !this.ShowSettings;
        }, 500);
      } else {
        this.ShowSettings = !this.ShowSettings;
      };
    },
    ToggleCommandList() {
      if (this.ShowSettings) {
        this.ShowSettings = false;
        setTimeout(() => {
          this.ShowCommandList = !this.ShowCommandList;
        }, 500);
      } else {
        this.ShowCommandList = !this.ShowCommandList;
      };
    },
    ToggleMoreOptions() {
      this.ShowMoreOptions = !this.ShowMoreOptions;
    },
    ToggleEmojiMenu() {
      this.ShowEmojiMenu = !this.ShowEmojiMenu;
    },
    ToggleDice() {
      FetchNUI('TOGGLE_DICE', {});
    },
    ToggleRPS() {
      FetchNUI('TOGGLE_RPS', {});
    },
    ToggleThread() {
      if (this.ThreadType === 'dui') {
        this.ThreadType = 'native';
      } else {
        this.ThreadType = 'dui';
      }
    },
    SendChatMessage() {
      if (this.ChatInput.trim() === "") return;

      FetchNUI('EXECUTE_COMMAND', this.ChatInput.replace(/^\//, ''));
      FetchNUI('CLOSE_UI', {});

      const isAlreadyUsed = this.RecentUsedCommands.includes(this.ChatInput);

      if (!isAlreadyUsed && this.ChatInput !== '') {
        this.RecentUsedCommands.unshift(this.ChatInput);
      }

      if (!this.ChatInput.includes('www.youtube.com')) {
        setTimeout(() => {
          if (this.ShowChatInput === false) {
            this.ShowChat = false;
          }
        }, 5000);
      } else {
        this.ShowChat = false;
      }

      this.CurrentRecentUsedCommand = -1;
      this.ChatInput = "";

      this.ShowChatInput = false;
    },
    QuickCommand(command) {
      this.ChatInput = "/" + command + " ";
    },
    TogglePlaying() {
      FetchNUI('TOGGLE_PLAYING', {});
    },
    StopMusic() {
      if (this.SongData && this.SongData.url) {
        FetchNUI('STOP_MUSIC', {});
        this.SongData = {};
      }
    },
    UpdateVolume() {
      if (this.SongData && this.SongData.url) {
        FetchNUI('UPDATE_VOLUME', { volume: this.VolumeRange });
      }
    }
  },
});
