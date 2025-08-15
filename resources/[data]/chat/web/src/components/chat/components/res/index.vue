<script setup>
import { computed, ref, onMounted, nextTick, watch, shallowRef, useTemplateRef } from 'vue';
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'
import { motion, AnimatePresence } from 'motion-v';
import { onClickOutside } from '@vueuse/core'

const StoreData = DefaultData();
const {
    ShowMoreOptions,
    ShowChat,
    ShowChatInput,
    Commands,
    ChatCategories,
    ChatMessages,
    ChatInput,
    ChatMessageColors,
    SelectedPosition,
    SelectedCategory,
    SelectedColor,
    SongData,
    VolumeRange,
    ShowEmojiMenu,
    Emojis,
    Locales,
} = storeToRefs(StoreData);

const modal = shallowRef(false)
const modalRef = useTemplateRef('modalRef')
const buttonRef = useTemplateRef('buttonRef')

onClickOutside(
  modalRef,
  () => {
    modal.value = false
  },
  {
    ignore: [buttonRef],
  }
)

const GetCategoryLabel = (name) => {
    const category = ChatCategories.value.find(cat => cat.name === name);
    return category ? category.label : '';
};

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

const ShowCommandSuggestions = computed(() => {
    return ChatInput.value.startsWith('/') && CommandSuggestions.value.length > 0;
});

const IsWhite = (hex) => {
    if (!hex) return false;

    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);

    const brightness = (r * 299 + g * 587 + b * 114) / 1000;

    return brightness > 200;
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

const GetAnimationPosition = (position) => {
    switch (position) {
      case 'top-left': return { x: -100, opacity: 0 };
      case 'top-right': return { x: 100, opacity: 0 };
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

onMounted(() => {
    window.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            modal.value = false;
        }
    });
});
</script>

<template>
    <div
        class="flex flex-col items-start absolute h-full"
        :class="
            SelectedPosition.name == 'top-right' ? 'top-[0] right-[0]' : 'top-[0] left-[0]'
        "
    >
        <AnimatePresence :mode="'sync'">
            <motion.div v-if="ShowChatInput || ShowChat" :initial="GetAnimationPosition(SelectedPosition.name)" :animate="{ x: 0, y: 0, opacity: 1 }" :exit="GetAnimationPosition(SelectedPosition.name)" :transition="{ duration: 0.3 }" class="w-[23.4375vw] h-full p-[.5208vw] flex flex-col items-start" :style="`${ShowChatInput ? `background-color: ${SelectedColor.box}` : ``}`">
                <div v-if="ShowChatInput" class="w-full h-max flex items-center justify-between border-b-[.0521vw] border-[#ffffff29] pb-[.3125vw]">
                    <div class="flex items-center w-full h-max gap-x-[.3125vw]">
                        <i class="fa-solid fa-messages text-[.8333vw] text-[#FFF]"></i>
                        <p class="text-[#FFF] text-[.9375vw] font-['Poppins-SemiBold'] uppercase">{{ Locales.command_list }}</p>
                    </div>
                    <div class="flex items-center justify-center relative">
                        <div div class="w-[2.1875vw] h-[2.1875vw] rounded-[.3083vw] flex items-center justify-center cursor-pointer border-[.0781vw] border-solid border-[#ffffff29]" :style="`background-color: ${SelectedColor.box}`" ref="buttonRef" @click="modal = true">
                            <i class="fa-solid fa-filter text-[#FFF] text-[.8333vw]"></i>
                        </div>
                        <AnimatePresence :mode="'sync'">
                            <motion.div v-if="modal" ref="modalRef" :initial="{ opacity: 0 }" :animate="{ opacity: 1 }" :exit="{ opacity: 0 }" :transition="{ duration: 0.3 }" class="w-max h-max p-[.2083vw] rounded-[.3125vw] border-[.0781vw] border-solid border-[#ffffff29] absolute top-[2.3958vw] right-[0]" :style="{ backgroundColor: SelectedColor.box }">
                                <template v-for="(categorie, index) in ChatCategories" :key="index">
                                    <div v-if="categorie.show" class="px-[.4167vw] py-[.3125vw] rounded-[.2083vw] flex cursor-pointer group transition-all duration-150" :class="SelectedCategory.name == categorie.name ? 'bg-[#ffffff29]' : 'hover:bg-[#ffffff29]'" @click="SelectedCategory = categorie;modal = false;ScrollToBottom()">
                                        <p class="text-[.625vw] font-['Poppins-Medium'] transition-all duration-150 leading-tight line-clamp-1" :class="SelectedCategory.name == categorie.name ? 'text-[#FFF]' : 'text-[#FFF]/50 group-hover:text-[#FFF]'">{{ categorie.label }}</p>
                                    </div>
                                </template>
                            </motion.div>
                        </AnimatePresence>
                    </div>
                </div>
                <div v-if="ShowChat" class="w-full flex flex-col items-start justify-start mt-[.3125vw] overflow-hidden" :class="ShowChatInput ? ' h-full' : 'h-1/3'">
                    <div class="w-full h-max max-h-full gap-[.5208vw] flex flex-col overflow-y-auto hide-scrollbar" id="chat-message">
                        <div v-for="(message, index) in filteredMessages" :key="index" class="w-full flex flex-col items-start p-[.3125vw] rounded-[.3125vw] gap-y-[.3125vw]" :style="`background-color: ${SelectedColor.box}`">
                            <div class="w-full h-max flex items-center justify-between gap-x-[.3125vw]">
                                <div class="flex items-center gap-x-[.3125vw]">
                                    <div v-if="message.category !== 'server' || message.category !== 'custom'" class="bg-[#ffffff29] px-[.3125vw] py-[.2083vw] flex items-center justify-center rounded-[.2083vw]">
                                        <p class="text-[#FFF] text-[.625vw] font-['Poppins-Medium'] leading-tight line-clamp-1">{{ message.fullname }}</p>
                                    </div>
                                    <div class="px-[.3125vw] py-[.2083vw] flex items-center justify-center rounded-[.2083vw]" :style="`background-color: ${ChatMessageColors[message.category].bg}`">
                                        <p class="text-[.625vw] font-['Poppins-Medium'] leading-tight line-clamp-1" :style="`color: ${IsWhite(ChatMessageColors[message.category].bg) ? '#000' : '#FFF'}`">{{ GetCategoryLabel(message.category) }}</p>
                                    </div>
                                </div>
                                <div class="px-[.3125vw] py-[.2083vw] bg-[#FFFFFF29] rounded-[.2083vw] flex items-center justify-center">
                                    <p class="text-[.625vw] text-[#FFF] leading-none font-['Poppins-Medium']">{{ message.time }}</p>
                                </div>
                            </div>
                            <p v-if="!message.isImage" class="text-[#FFF] text-[.625vw] leading-tight font-['Poppins-Regular'] break-words whitespace-normal w-full">{{ message.message }}</p>
                            <img v-if="message.isImage" :src="message.message" alt="image" class="w-full h-auto rounded-[.2083vw] object-cover" />
                        </div>
                    </div>
                </div>
                <div v-if="SongData.title && ShowChatInput" class="w-full flex flex-col items-start justify-start mt-[.3125vw]">
                    <div class="w-full h-max max-h-full gap-[.5208vw] flex flex-col bg-[#013815B2] rounded-[.3125vw] p-[.3125vw]">
                        <div class="w-full h-max flex items-center justify-start gap-x-[.3125vw]">
                            <div class="px-[.3125vw] py-[.2083vw] flex items-center justify-center rounded-[.2083vw] bg-[#46FF88]">
                                <p class="text-[.625vw] font-['Poppins-Medium'] leading-tight line-clamp-1 text-[#000]">MUSIC</p>
                            </div>
                        </div>
                        <div class="w-full h-max flex items-center justify-between gap-x-[.5208vw]">
                            <p class="font-['Poppins-Regular'] text-[.625vw] text-[#FFFFFF] leading-none uppercase">{{ SongData.title }}</p>
                            <div class="flex items-center gap-x-[.5208vw]">
                                <i class="fa-solid fa-trash text-[.625vw] text-[#FFF] cursor-pointer" @click="StoreData.StopMusic()"></i>
                                <i v-if="SongData.isPlaying" class="fa-solid fa-pause text-[.7292vw] text-[#FFF] cursor-pointer" @click="StoreData.TogglePlaying()"></i>
                                <i v-if="!SongData.isPlaying" class="fa-solid fa-play text-[.7292vw] text-[#FFF] cursor-pointer" @click="StoreData.TogglePlaying()"></i>
                                <div class="flex items-center gap-x-[.5208vw]">
                                    <img src="/svgs/sound.svg" alt="sound" class="w-[.7488vw] h-[.7292vw]" draggable="false" />
                                    <input type="range" id="volume" name="volume" min="0" max="100" class="custom-range" @input="UpdateFill" v-model="VolumeRange" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div v-if="ShowChatInput" class="w-full h-max min-h-max flex flex-col items-center mt-[.3125vw] relative">
                    <div class="flex items-center justify-between w-full h-max gap-x-[.4167vw]">
                        <div class="w-full h-[2.3958vw] border-[.0781vw] border-solid border-[#ffffff29] overflow-hidden pl-[.7292vw] gap-x-[.7292vw] flex items-center justify-between"  :class="ShowCommandSuggestions ? 'rounded-tl-[.2083vw] rounded-tr-[.2083vw]' : 'rounded-[.2083vw]'" :style="`background-color: ${SelectedColor.box}`">
                            <input id="chat-input" type="text" v-model="ChatInput" class="w-full h-full bg-transparent outline-none border-none text-[.625vw] text-white placeholder:text-white/50 font-['Poppins-Medium']" :placeholder="Locales.type_a_message" />
                            <div class="flex items-center justify-center cursor-pointer w-[1.9792vw] h-[1.9792vw] group" @click="StoreData.ToggleMoreOptions()">
                                <i class="fa-solid fa-ellipsis text-[.8333vw] text-[#FFF]/50 group-hover:text-[#FFF] transition-colors duration-150"></i>
                            </div>
                        </div>
                        <div class="w-[2.3958vw] h-[2.3958vw] border-[.0781vw] border-solid border-[#ffffff29] rounded-[.3083vw] flex items-center justify-center cursor-pointer" :style="`background-color: ${SelectedColor.box}`" @click="StoreData.SendChatMessage()">
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
                        <motion.div v-if="ShowEmojiMenu" :initial="{ opacity: 0 }" :animate="{ opacity: 1 }" :exit="{ opacity: 0 }" :transition="{ duration: 0.3 }" class="p-[.1042vw] w-max h-max max-h-[8.8542vw] overflow-y-auto grid gap-[.1042vw] absolute bottom-[-9.0625vw] right-0 border-[.0521vw] border-solid border-[#FFFFFF1F] rounded-[.2083vw] hide-scrollbar" :style="`background-color: ${SelectedColor.box}`" style="grid-template-columns: repeat(12, max-content);">
                            <p v-for="(emoji, index) in Emojis" :key="index" class="text-[.9375vw] cursor-pointer" @click="ChatInput = ChatInput + emoji">{{ emoji }}</p>
                        </motion.div>
                    </AnimatePresence>
                    <div v-if="ShowCommandSuggestions" class="flex flex-col item-start gap-y-[.1563vw] w-full p-[.2083vw] rounded-bl-[.2083vw] rounded-br-[.2083vw]" :style="`background-color: ${SelectedColor.box}`">
                        <div v-for="(suggestion, index) in CommandSuggestions" :key="index" class="w-full h-max gap-x-[.5208vw] flex items-center px-[.2083vw] py-[.3125vw]">
                            <i class="fa-solid fa-terminal text-[.7292vw] text-[#FFF]"></i>
                            <div class="flex items-center gap-x-[.2083vw]">
                                <p class="font-['Poppins-Regular'] text-[#FFF]/45 text-[.5729vw] leading-tight line-clamp-1">{{ Locales.suggestion }}:</p>
                                <p class="font-['Poppins-Regular'] text-[#FFF] text-[.5729vw] leading-tight line-clamp-1">/{{ suggestion.name }}</p>
                            </div>
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