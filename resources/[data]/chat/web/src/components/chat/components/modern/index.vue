<script setup>
import { computed, ref, watchEffect, nextTick, watch } from 'vue';
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'
import { motion, AnimatePresence } from 'motion-v';

const StoreData = DefaultData();
const {
    ShowMoreOptions,
    ShowChatInput,
    ShowChat,
    ChatCategories,
    ChatMessages,
    ChatInput,
    ChatMessageColors,
    Commands,
    SelectedPosition,
    SelectedCategory,
    SelectedColor,
    SongData,
    VolumeRange,
    ShowEmojiMenu,
    Emojis,
    Locales,
} = storeToRefs(StoreData);

const filteredMessages = computed(() => {
    if (SelectedCategory.value.name === 'all') {
        return ChatMessages.value;
    };

    return ChatMessages.value.filter(chat => chat.category === SelectedCategory.value.name);
});

const CommandSuggestions = computed(() => {
    if (!ChatInput.value) return [];

    if (!ChatInput.value.startsWith('/')) {
        return [];
    }

    const filteredInput = ChatInput.value.toLowerCase().replace(/^\//, '');

    if (!filteredInput || filteredInput == '') return [];

    const suggestions = Commands.value.filter(chat =>
        chat?.name?.toLowerCase().includes(filteredInput)
    ).slice(0, 5);

    return suggestions
});

const GetCategoryLabel = (name) => {
    const category = ChatCategories.value.find(cat => cat.name === name);
    return category ? category.label : '';
};

const UpdateFill = () => {
    if (!document.querySelector('.custom-range')) return;

    const input = document.querySelector('.custom-range')

    input.addEventListener('input', function() {
        this.style.setProperty('--fill-percent', (this.value - this.min) / (this.max - this.min) * 100 + '%');
    });

    input.style.setProperty('--fill-percent', (input.value - input.min) / (input.max - input.min) * 100 + '%');

    StoreData.UpdateVolume();
};

const ScrollToBottom = () => {
    const chatContainer = document.querySelector('#chat-message');

    if (chatContainer) {
        chatContainer.scrollTop = chatContainer.scrollHeight
    };
};

const GetAnimationPosition = (position) => {
    switch (position) {
      case 'top-left': return { x: -100, opacity: 0 };
      case 'top-center': return { y: -100, opacity: 0 };
      case 'top-right': return { x: 100, opacity: 0 };
      case 'bottom-left': return { x: -100, opacity: 0 };
      case 'bottom-center': return { y: 100, opacity: 0 };
      case 'bottom-right': return { x: 100, opacity: 0 };
      case 'center-left': return { x: -100, opacity: 0 };
      case 'center-right': return { x: 100, opacity: 0 };
      default: return { x: 0, y: 0, opacity: 0 };
    }
};

const GetMoreOptionsPosition = (position) => {
    if (position.includes('left')) {
        return "-right-[1.5vw] top-1/2 -translate-y-1/2";
    } else if (position.includes('right')) {
        return "-left-[9vw] top-1/2 -translate-y-1/2";
    } else {
        return "-right-[1.5vw] top-1/2 -translate-y-1/2";
    }
};

watch(() => ShowChatInput.value, () => {
    setTimeout(() => {
        const chatInput = document.querySelector('#chat-input');
        if (chatInput) {
            chatInput.focus();
        }

        nextTick(ScrollToBottom)
    }, 100);
});

watch(() => ChatMessages.value.length, () => {
    nextTick(ScrollToBottom)
});
</script>

<template>
    <div
        class="flex flex-col items-start absolute w-[22.7604vw]"
        :class="
            SelectedPosition.name == 'top-left' ? 'top-[.8333vw] left-[1.3542vw]' :
            SelectedPosition.name == 'top-right' ? 'top-[.8333vw] right-[1.3542vw]' :
            SelectedPosition.name == 'top-center' ? 'top-[.8333vw] -translate-x-1/2 left-1/2' :
            SelectedPosition.name == 'bottom-left' ? 'bottom-[.8333vw] left-[1.3542vw]' :
            SelectedPosition.name == 'bottom-right' ? 'bottom-[.8333vw] right-[1.3542vw]' :
            SelectedPosition.name == 'bottom-center' ? 'bottom-[.8333vw] -translate-x-1/2 left-1/2' :
            SelectedPosition.name == 'center-left' ? '-translate-y-1/2 top-1/2 left-[1.3542vw]' :
            SelectedPosition.name == 'center-right' ? '-translate-y-1/2 top-1/2 right-[1.3542vw]' : ''
        "
    >
        <AnimatePresence mode="sync">
            <motion.div v-if="ShowChatInput" class="w-full h-[2vw] flex items-center justify-between rounded-[.3125vw] gap-x-[.3125vw] px-[.5208vw] group" :style="`background-color: ${SelectedColor.box}`" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3, ease: 'easeInOut' }">
                <template v-for="(categorie, index) in ChatCategories" :key="index">
                    <div v-if="categorie.show" class="py-[.2167vw] px-[.5729vw] rounded-[.2083vw] flex items-center justify-center cursor-pointer" :class="SelectedCategory.name == categorie.name ? 'bg-[#84848433]' : ''" @click="SelectedCategory = categorie">
                        <p class="font-['Poppins-Medium'] text-[.625vw] leading-none line-clamp-1" :class="SelectedCategory.name == categorie.name ? 'text-[#FFFFFF]' : 'text-[#FFFFFF66]'">{{ categorie.label }}</p>
                    </div>
                </template>
            </motion.div>
            <motion.div v-if="ShowChat" class="h-[15.7813vw] flex flex-col outline-none mt-[.5208vw] w-full" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3, ease: 'easeInOut' }">
                <div id="chat-message" class="flex flex-col gap-y-[.625vw] w-full overflow-y-auto outline-none py-[.3125vw] hide-scrollbar">
                    <div v-for="(chat, index) in filteredMessages" :key="index" class="w-full h-max rounded-[.2083vw] flex flex-col items-start justify-end relative px-[.7292vw] pb-[.9vw] pt-[1.304vw] group " :style="`background-color: ${SelectedColor.box}`">
                        <div class="flex items-center w-full justify-between absolute top-[-.3125vw] left-0 px-[.7292vw]">
                            <div class="flex items-center gap-x-[.2083vw]">
                                <div v-if="chat.category !== 'server' && chat.category !== 'custom'" class="flex items-center justify-center px-[.3646vw] py-[.3125vw] rounded-[.2083vw]" :style="`background-color: ${SelectedColor.hex}`">
                                    <p class="text-[.5729vw] font-['Poppins-Medium'] leading-none line-clamp-1 uppercase" :style="`color: ${SelectedColor.text}`">{{ chat.fullname }}</p>
                                </div>
                                <div class="flex items-center justify-center px-[.3646vw] py-[.3125vw] rounded-[.2083vw]" :style="`background-color: ${ChatMessageColors[chat.category].bg}`">
                                    <p class="text-[.5729vw] font-['Poppins-Medium'] leading-none line-clamp-1 uppercase" :style="`color: ${ChatMessageColors[chat.category].text}`">{{ GetCategoryLabel(chat.category) }}</p>
                                </div>
                            </div>
                        </div>
                        <div class="flex items-center justify-end w-full absolute top-[.5208vw] right-[.5208vw]">
                            <p class="text-[.5729vw] font-['Poppins-Medium'] leading-none line-clamp-1 uppercase text-[#FFF]">{{ chat.time }}</p>
                        </div>
                        <p v-if="!chat.isImage" class="font-['Poppins-Regular'] text-[#FFF] text-[.5729vw] leading-tight">{{ chat.message }}</p>
                        <img v-if="chat.isImage":src="chat.message" alt="image" class="w-full h-auto rounded-[.2083vw] object-cover" />
                    </div>
                </div>
                <div v-if="SongData.title" class="w-full h-max bg-[#013815B2] rounded-[.2083vw] flex flex-col items-start justify-end relative px-[.7292vw] pb-[.9vw] pt-[1.304vw] mt-[.5208vw]">
                    <div class="flex items-center w-full justify-between absolute top-[-.3125vw] left-0 px-[.7292vw]">
                        <div class="flex items-center justify-center px-[.3646vw] py-[.3125vw] bg-[#46FF88] rounded-[.2083vw]">
                            <p class="text-[#434343] text-[.5729vw] font-['Poppins-Medium'] leading-none line-clamp-1 uppercase">MUSIC</p>
                        </div>
                    </div>
                    <div class="flex items-center justify-between w-full">
                        <div class="flex flex-col items-start">
                            <p class="font-['Poppins-Regular'] text-[.5729vw] text-[#46FF88] leading-none uppercase">Now Playing</p>
                            <p class="font-['Poppins-Regular'] text-[.5729vw] text-[#FFFFFF] leading-none uppercase max-w-[13vw] line-clamp-1">{{ SongData.title }}</p>
                        </div>
                        <div class="flex items-center gap-x-[.5208vw]">
                            <i class="fa-solid fa-trash text-[.625vw] text-[#FFF] cursor-pointer" @click="StoreData.StopMusic()"></i>
                            <i v-if="SongData.isPlaying" class="fa-solid fa-pause text-[.7292vw] text-[#FFF] cursor-pointer" @click="StoreData.TogglePlaying()"></i>
                            <i v-if="!SongData.isPlaying" class="fa-solid fa-play text-[.7292vw] text-[#FFF] cursor-pointer" @click="StoreData.TogglePlaying()"></i>
                            <div class="flex items-center gap-x-[.5208vw]">
                                <img src="/svgs/sound.svg" alt="sound" class="w-[.7488vw] h-[.7292vw]" draggable="false" />
                                <input type="range" id="volume" name="volume" min="0" max="100" class="custom-range" @input="updateFill" v-model="VolumeRange" />
                            </div>
                        </div>
                    </div>
                </div>
            </motion.div>
            <motion.div v-if="ShowChatInput" class="flex flex-col items-start outline-none relative mt-[.3125vw] w-full" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3, ease: 'easeInOut' }">
                <div class="flex items-center gap-x-[.1563vw] w-full h-[2.3438vw]">
                    <div class="w-full h-[2.3438vw] rounded-[.3125vw] px-[.4167vw] py-[.5208vw] flex items-center" :style="`background-color: ${SelectedColor.box}`">
                        <input id="chat-input" type="text" v-model="ChatInput" :placeholder="Locales.type_a_message" class="w-full h-full bg-transparent text-white placeholder:text-white/50 text-[.5208vw] leading-tight font-['Poppins-Medium'] outline-none" />
                    </div>
                    <div class="w-[2.3438vw] h-[2.3438vw] rounded-[.3125vw] px-[.4167vw] py-[.5208vw] flex items-center justify-center cursor-pointer group" :style="`background-color: ${SelectedColor.box}`" @click="StoreData.ToggleMoreOptions()">
                        <i class="fa-solid fa-ellipsis text-[.8333vw] text-[#FFF]/50 group-hover:text-[#FFF] transition-colors duration-150"></i>
                    </div>
                    <div class="w-[2.3438vw] h-[2.3438vw] rounded-[.3125vw] px-[.4167vw] py-[.5208vw] flex items-center justify-center cursor-pointer" :style="`background-color: ${SelectedColor.box}`" @click="StoreData.SendChatMessage()">
                        <i class="fa-solid fa-paper-plane-top text-[#FFF] text-[.8333vw]"></i>
                    </div>
                </div>
                <AnimatePresence mode="sync">
                    <motion.div v-if="ShowMoreOptions" :initial="{ opacity: 0 }" :animate="{ opacity: 1 }" :exit="{ opacity: 0 }" :transition="{ duration: 0.3 }" class="flex items-center absolute" :class="GetMoreOptionsPosition(SelectedPosition.name)">
                        <svg xmlns="http://www.w3.org/2000/svg" width=".4688vw" height=".8333vw" viewBox="0 0 9 16" fill="none" class="absolute" :class="SelectedPosition.name.includes('right') ? 'rotate-180 right-[-8.2292vw]' : '-left-[.4329vw]'">
                            <path d="M0 8L8.5 0V16L0 8Z" :fill="SelectedColor.box"/>
                        </svg>
                        <div class="w-max h-[1.9792vw] gap-x-[.9375vw] flex items-center px-[.5729vw] rounded-[.2083vw] absolute " :style="`background-color: ${SelectedColor.box}`">
                            <div class="flex items-center justify-center cursor-pointer w-[.9896vw] h-[1.1134vw]" @click="StoreData.ToggleDice();ShowMoreOptions = false">
                                <i class="fa-solid fa-dice text-[.8333vw] text-[#FFF]/50 hover:text-[#FFF] transition-colors duration-150"></i>
                            </div>
                            <div class="flex items-center justify-center cursor-pointer w-[.9896vw] h-[1.1134vw]" @click="StoreData.ToggleRPS();ShowMoreOptions = false">
                                <i class="fa-solid fa-hand-scissors text-[.8333vw] text-[#FFF]/50 hover:text-[#FFF] transition-colors duration-150"></i>
                            </div>
                            <div class="flex items-center justify-center cursor-pointer w-[.9375vw] h-[.9375vw]" @click="StoreData.ToggleEmojiMenu();ShowMoreOptions = false">
                                <i class="fa-solid fa-face-smile text-[.8333vw] text-[#FFF]/50 hover:text-[#FFF] transition-colors duration-150"></i>
                            </div>
                            <div class="flex items-center justify-center cursor-pointer w-[.9375vw] h-[.9375vw]" @click="StoreData.ToggleSettings();ShowMoreOptions = false">
                                <i class="fa-solid fa-gear text-[.8333vw] text-[#FFF]/50 hover:text-[#FFF] transition-colors duration-150"></i>
                            </div>
                        </div>
                    </motion.div>
                    <motion.div v-if="ShowEmojiMenu" :initial="{ opacity: 0 }" :animate="{ opacity: 1 }" :exit="{ opacity: 0 }" :transition="{ duration: 0.3 }" class="p-[.1042vw] w-max h-max max-h-[8.8542vw] overflow-y-auto grid gap-[.1042vw] absolute bottom-[-9.0625vw] right-0 bg-[#27272799] rounded-[.2083vw] hide-scrollbar" style="grid-template-columns: repeat(12, max-content);">
                        <p v-for="(emoji, index) in Emojis" :key="index" class="text-[.9375vw] cursor-pointer" @click="ChatInput = ChatInput + emoji">{{ emoji }}</p>
                    </motion.div>
                </AnimatePresence>
            </motion.div>
            <motion.div v-if="ShowChatInput" class="flex flex-col item-start gap-y-[.1563vw] w-full mt-[.4167vw]" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3, ease: 'easeInOut' }">
                <div class="flex flex-col item-start gap-y-[.1563vw] w-full mt-[.4167vw]">
                    <div v-for="(suggestion, index) in CommandSuggestions" :key="index" class="w-full h-max rounded-[.2083vw] px-[.6083vw] py-[.4083vw] gap-x-[.5208vw] flex items-center" style="background: linear-gradient(90deg, rgba(28, 28, 28, 0.50) 0%, rgba(28, 28, 28, 0.00) 100%);">
                        <i class="fa-solid fa-terminal text-[.7292vw] text-[#FFF]"></i>
                        <div class="flex items-center gap-x-[.2083vw]">
                            <p class="font-['Poppins-Regular'] text-[#FFF]/45 text-[.5729vw] leading-tight line-clamp-1">{{ Locales.suggestion }}:</p>
                            <p class="font-['Poppins-Regular'] text-[#FFF] text-[.5729vw] leading-tight line-clamp-1">/{{ suggestion.name }}</p>
                        </div>
                    </div>
                </div>
            </motion.div>
        </AnimatePresence>
    </div>
</template>

<style scoped>
    .hide-scrollbar::-webkit-scrollbar {
        width: 0;
    }

    .custom-range {
        -webkit-appearance: none;
        width: 4.6875vw;
        height: 0.2083vw;
        background: rgba(255, 255, 255, 0.35);
        border-radius: 9999px;
        outline: none;
        position: relative;
    }

    .custom-range::-webkit-slider-runnable-track {
        height: 0.2083vw;
        border-radius: 9999px;
    }

    .custom-range::-moz-range-track {
        height: 0.2083vw;
        border-radius: 9999px;
    }

    .custom-range::-webkit-slider-thumb {
        -webkit-appearance: none;
        height: 0.5208vw;
        width: 0.5208vw;
        background: #ffffff;
        border-radius: 50%;
        margin-top: -0.1563vw;
        position: relative;
        z-index: 2;
    }

    .custom-range::-moz-range-thumb {
        height: 0.5208vw;
        width: 0.5208vw;
        background: #ffffff;
        border: none;
        border-radius: 50%;
        position: relative;
        z-index: 2;
    }

    .custom-range::-webkit-slider-container {
        border-radius: 999px;
        background: linear-gradient(to right, #46FF88 var(--fill-percent), transparent 0);
    }

    .custom-range::-moz-range-progress {
        height: 0.2083vw;
        border-radius: 9999px;
        background: #46FF88;
    }
</style>