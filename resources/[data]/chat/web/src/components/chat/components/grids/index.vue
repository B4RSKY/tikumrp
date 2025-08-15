<script setup>
import { computed, ref, onMounted, nextTick, watch } from 'vue';
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'
import { motion, AnimatePresence } from 'motion-v';

const StoreData = DefaultData();
const {
    ShowMoreOptions,
    ShowChat,
    ShowChatInput,
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
        class="flex flex-col items-start absolute"
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
            <motion.div v-if="ShowChatInput" class="w-max h-[1.875vw] flex items-center gap-x-[.2083vw]" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3, ease: 'easeInOut' }">
                <template v-for="(categorie, index) in ChatCategories" :key="index">
                    <div v-if="categorie.show" class="px-[.5688vw] py-[.5688vw] rounded-[.2083vw] flex items-center justify-center cursor-pointer" :style="SelectedCategory.name == categorie.name ? `background: ${SelectedColor.hex}` : `background: ${SelectedColor.box}`" @click="SelectedCategory = categorie">
                        <p class="font-['Poppins-Medium'] text-[.5729vw] leading-none line-clamp-1" :style="SelectedCategory.name == categorie.name ? `color: ${SelectedColor.hex === '#FFFFFF' ? '#000' : '#FFF'}` : `color: #FFF`">{{ categorie.label }}</p>
                    </div>
                </template>
            </motion.div>
            <motion.div v-if="ShowChat" class="flex flex-col items-start justify-end h-[15.4063vw] w-[22.7604vw]" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3, ease: 'easeInOut' }">
                <div id="chat-message" class="w-full h-max max-h-[16.4063vw] flex flex-col items-start justify-end mt-[.4688vw] overflow-y-auto gap-y-[.3125vw] hide-scrollbar">
                    <div v-for="(chat, index) in filteredMessages" :key="index" class="flex items-stretch w-max max-w-full">
                        <div class="min-w-[1.3021vw] w-[1.3021vw] rounded-tl-[.2083vw] rounded-bl-[.2083vw] flex items-center justify-center border-[.0781vw] border-solid border-[#ffffff29]" :style="`background-color: ${ChatMessageColors[chat.category].bg}`">
                            <p class="text-[.5729vw] leading-tight font-['Poppins-Medium'] -rotate-90" :style="`color: ${ChatMessageColors[chat.category].text}`">{{ GetCategoryLabel(chat.category) }}</p>
                        </div>
                        <div class="w-full h-full flex flex-col items-start rounded-tr-[.2083vw] rounded-br-[.2083vw] px-[.4167vw] py-[.4167vw] gap-y-[.3125vw] border-[.0781vw] border-solid border-[#ffffff29]" :style="`background-color: ${SelectedColor.box}`">
                            <div class="flex items-center justify-between w-full gap-x-[.2604vw]">
                                <div class="flex items-center justify-center gap-x-[.2604vw]">
                                    <p v-if="chat.category !== 'server' && chat.category !== 'custom'" class="text-[.5729vw] leading-tight font-['Poppins-Medium'] line-clamp-1 text-[#FFF]">{{ chat.fullname }}:</p>
                                    <p v-if="chat.category == 'server'" class="text-[.5729vw] leading-tight font-['Poppins-Medium'] line-clamp-1 text-[#FFF]">{{ GetCategoryLabel(chat.category) }}:</p>
                                </div>
                                <p class="text-[.5729vw] leading-tight font-['Poppins-Medium'] line-clamp-1 text-[#FFFFFF80]">{{ chat.time }}</p>
                            </div>
                            <p v-if="!chat.isImage" class="text-[.5729vw] leading-tight font-['Poppins-Regular'] text-[#FFF] max-w-full">{{ chat.message }}</p>
                            <img v-if="chat.isImage" :src="chat.message" alt="image" class="w-full h-auto rounded-[.2083vw] object-cover" />
                        </div>
                    </div>
                </div>
                <div v-if="SongData.title" class="w-full h-max flex items-stretch mt-[.3125vw]">
                    <div class="min-w-[1.3021vw] w-[1.3021vw] min-h-full rounded-tl-[.2083vw] rounded-bl-[.2083vw] flex items-center justify-center border-[.0781vw] border-solid border-[#ffffff29]" :style="`background-color: #1ED760`">
                        <p class="text-[.5729vw] leading-tight font-['Poppins-Medium'] -rotate-90" :style="`color: #FFFFFF`">MUSIC</p>
                    </div>
                    <div class="w-full h-full flex items-center justify-between bg-[#00531EB2] border-[.0781vw] border-solid border-[#ffffff29] rounded-tr-[.2083vw] rounded-br-[.2083vw] px-[.4167vw] py-[.4167vw] gap-y-[.5208vw]">
                        <div class="flex flex-col items-start justify-center">
                            <p class="text-[#1ED760] text-[.5729vw] leading-tight font-['Poppins-Regular']">Now playing</p>
                            <p class="text-[#FFFFFF] text-[.5729vw] leading-tight font-['Poppins-Regular'] max-w-[13vw] line-clamp-1">{{ SongData.title }}</p>
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
            <motion.div v-if="ShowChatInput" class="w-[22.7604vw] h-max flex flex-col items-start mt-[.3125vw] relative" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3, ease: 'easeInOut' }">
                <div class="flex items-center gap-x-[.1563vw] w-full h-[2.1875vw] relative">
                    <div class="w-full h-[2.1875vw] rounded-[.3125vw] px-[.4167vw] py-[.5208vw] flex items-center" :style="`background-color: ${SelectedColor.box}`">
                        <input id="chat-input" type="text" v-model="ChatInput" :placeholder="Locales.type_a_message" class="w-full h-full bg-transparent text-white placeholder:text-white/50 text-[.5208vw] leading-tight font-['Poppins-Medium'] outline-none" />
                    </div>
                    <div class="w-[2.1875vw] h-[2.1875vw] rounded-[.3125vw] px-[.4167vw] py-[.5208vw] flex items-center justify-center cursor-pointer group" :style="`background-color: ${SelectedColor.box}`" @click="StoreData.ToggleMoreOptions()">
                        <i class="fa-solid fa-ellipsis text-[.8333vw] text-[#FFF]/50 group-hover:text-[#FFF] transition-colors duration-150"></i>
                    </div>
                    <div class="w-[2.1875vw] h-[2.1875vw] rounded-[.3125vw] px-[.4167vw] py-[.5208vw] flex items-center" :style="`background-color: ${SelectedColor.box}`" @click="StoreData.ToggleMoreOptions()">
                        <i class="fa-solid fa-paper-plane-top text-[#FFF] text-[.8333vw]"></i>
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
                    </AnimatePresence>
                </div>
                <AnimatePresence mode="sync">
                    <motion.div v-if="ShowEmojiMenu" :initial="{ opacity: 0 }" :animate="{ opacity: 1 }" :exit="{ opacity: 0 }" :transition="{ duration: 0.3 }" class="p-[.1042vw] w-max h-max max-h-[8.8542vw] overflow-y-auto grid gap-[.1042vw] absolute bottom-[-9.0625vw] right-0 bg-[#202125B2] rounded-[.2083vw] hide-scrollbar" style="grid-template-columns: repeat(12, max-content);">
                        <p v-for="(emoji, index) in Emojis" :key="index" class="text-[.9375vw] cursor-pointer" @click="ChatInput = ChatInput + emoji">{{ emoji }}</p>
                    </motion.div>
                </AnimatePresence>
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