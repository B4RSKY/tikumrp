<script setup>
import nuiEvents from './utils/event'
import { FetchNUI } from "@/utils";
import { onMounted } from 'vue';
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'

import Settings from './components/settings/index.vue';
import Chat from './components/chat/index.vue';
import D3Text from './components/3dtext/index.vue';
import Commands from './components/commands/index.vue';

const StoreData = DefaultData();
const { ShowChat, ShowChatInput, ShowSettings, ShowMoreOptions, ShowEmojiMenu, ChatCategories, ChatInput, SelectedCategory, CurrentRecentUsedCommand, RecentUsedCommands } = storeToRefs(StoreData);

onMounted(() => {
    window.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            if (ShowSettings.value) {
                return;
            }

            FetchNUI('CLOSE_UI', {});
            ShowChatInput.value = false;
            ShowChat.value = false;
            ShowEmojiMenu.value = false;
            ShowMoreOptions.value = false;
            ShowEmojiMenu.value = false;
            CurrentRecentUsedCommand.value = -1;

            if (ShowSettings.value) {
                StoreData.ShowSettings = false;
            }
            return;
        } else if (event.key === 'Tab') {
            const currentIndex = ChatCategories.value.findIndex(cat => cat.name === SelectedCategory.value.name);
            const filteredCategories = ChatCategories.value.filter(cat => cat.show !== false);
            const nextIndex = (currentIndex + 1) % filteredCategories.length;
            StoreData.SelectedCategory = filteredCategories[nextIndex];
            return;
        } else if (event.key === 'ArrowUp') {
            const totalCommands = RecentUsedCommands.value.length;
            if (CurrentRecentUsedCommand.value < totalCommands - 1) {
                CurrentRecentUsedCommand.value++;
            } else {
                CurrentRecentUsedCommand.value = totalCommands - 1;
            }
            ChatInput.value = RecentUsedCommands.value[CurrentRecentUsedCommand.value] || '';
        } else if (event.key === 'ArrowDown') {
            if (CurrentRecentUsedCommand.value > 0) {
                CurrentRecentUsedCommand.value--;
            } else {
                CurrentRecentUsedCommand.value = -1;
            }

            if (CurrentRecentUsedCommand.value >= 0) {
                ChatInput.value = RecentUsedCommands.value[CurrentRecentUsedCommand.value] || '';
            } else {
                ChatInput.value = '';
            }
        } else if (event.key === 'Enter') {
            StoreData.SendChatMessage();
        }
    });

    nuiEvents();
});
</script>

<template>
    <div id="main" class="w-screen h-screen items-center justify-center overflow-hidden" style="display: flex;">
        <Chat />
        <Settings />
        <Commands />
        <D3Text />
    </div>
</template>