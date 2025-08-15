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
    Commands,
    SelectedPosition,
    ShowEmojiMenu,
    Emojis,
    SelectedColor,
    Locales,
} = storeToRefs(StoreData);

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

const ShowCommandSuggestions = computed(() => {
    return ChatInput.value.startsWith('/') && CommandSuggestions.value.length > 0;
});

const GetCategoryLabel = (name) => {
    const category = ChatCategories.value.find(cat => cat.name === name);
    return category ? category.label : '';
};

const GetCategoryColor = (name) => {
    const category = ChatCategories.value.find(cat => cat.name === name);
    return category?.color ? category.color : '#FFFFFF';
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

const ScrollToBottom = () => {
    const chatContainer = document.querySelector('#chat-message');

    if (chatContainer) {
        chatContainer.scrollTop = chatContainer.scrollHeight
    };
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
            <motion.div v-if="ShowChat" :key="ShowChat" class="flex flex-col items-start gap-y-[.3125vw] max-w-[29.1667vw] h-[15.625vw] overflow-y-auto hide-scrollbar" id="chat-message" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3, ease: 'easeInOut' }">
                <div v-for="(message, index) in ChatMessages" :key="index" class="flex gap-[.3125vw]" :style="`${message.isImage ? 'flex-direction: column;align-items: start;' : 'flex-direction: row;align-items: center;'}`">
                    <div class="flex items-center gap-x-[.2083vw]">
                        <p v-if="!message.isImage" class="text-[.7292vw] font-['Poppins-SemiBold'] leading-tight text-border" :style="`color: ${GetCategoryColor(message.category)};`">[{{ GetCategoryLabel(message.category) }}] {{ message.category == 'server' ? 'ANNOUNCE' : message.fullname }}: {{ message.message }}</p>
                        <img v-if="message.isImage" :src="message.message" class="w-[10.4167vw] h-auto" />
                    </div>
                </div>
            </motion.div>
            <motion.div v-if="ShowChatInput" :key="ShowChatInput" class="flex flex-col items-start mt-[.4167vw] relative" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3, ease: 'easeInOut' }">
                <div class="w-[25vw] h-[2.1875vw] flex items-center gap-x-[.625vw] px-[.4167vw]" :class="ShowCommandSuggestions ? 'rounded-tl-[.2083vw] rounded-tr-[.2083vw]' : 'rounded-[.2083vw]'" :style="`background-color: ${SelectedColor.box}`">
                    <input type="text" id="chat-input" v-model="ChatInput" class="w-full h-full bg-transparent border-none outline-none text-[.625vw] font-['Poppins-SemiBold'] leading-tight text-white placeholder:text-white/50" :placeholder="Locales.type_a_message" />
                    <div class="h-full w-[1.9792vw] flex items-center justify-center cursor-pointer group" @click="StoreData.ToggleMoreOptions()">
                        <i class="fa-solid fa-ellipsis text-[.8333vw] text-[#FFF]/50 group-hover:text-[#FFF] transition-colors duration-150"></i>
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
                    <motion.div v-if="ShowEmojiMenu" :initial="{ opacity: 0 }" :animate="{ opacity: 1 }" :exit="{ opacity: 0 }" :transition="{ duration: 0.3 }" class="p-[.1042vw] w-max h-max max-h-[8.8542vw] overflow-y-auto grid gap-[.1042vw] absolute bottom-[-9.0625vw] right-0 border-[.0521vw] border-solid border-[#FFFFFF1F] rounded-[.2083vw] hide-scrollbar" :style="`background-color: ${SelectedColor.box}`" style="grid-template-columns: repeat(12, max-content);">
                        <p v-for="(emoji, index) in Emojis" :key="index" class="text-[.9375vw] cursor-pointer" @click="ChatInput = ChatInput + emoji">{{ emoji }}</p>
                    </motion.div>
                </AnimatePresence>
            </motion.div>
            <div v-if="ShowCommandSuggestions" class="flex flex-col item-start gap-y-[.1563vw] w-full p-[.2083vw] rounded-bl-[.2083vw] rounded-br-[.2083vw]" :style="`background-color: ${SelectedColor.box}`">
                <div v-for="(suggestion, index) in CommandSuggestions" :key="index" class="w-full h-max gap-x-[.5208vw] flex items-center px-[.2083vw] py-[.3125vw]">
                    <i class="fa-solid fa-terminal text-[.7292vw] text-[#FFF]"></i>
                    <div class="flex items-center gap-x-[.2083vw]">
                        <p class="font-['Poppins-Regular'] text-[#FFF]/45 text-[.5729vw] leading-tight line-clamp-1">{{ Locales.suggestion }}:</p>
                        <p class="font-['Poppins-Regular'] text-[#FFF] text-[.5729vw] leading-tight line-clamp-1">/{{ suggestion.name }}</p>
                    </div>
                </div>
            </div>
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

    .text-border {
        -webkit-text-stroke: 1px #00000094;
    }
</style>