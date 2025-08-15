<script setup>
import { onMounted } from 'vue';
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'
import { motion, AnimatePresence } from 'motion-v';

const StoreData = DefaultData();
const { RPTexts, ChatCategories, ChatMessageColors } = storeToRefs(StoreData);

const GetCategoryLabel = (name) => {
    const category = ChatCategories.value.find(cat => cat.name === name);
    return category ? category.label : '';
};
</script>

<template>
    <template v-for="(text, index) in RPTexts" :key="index">
        <div class="flex flex-col items-center justify-end absolute px-[.625vw] bg-[#202125B2] min-w-[7.8125vw] w-max max-w-[15.625vw] h-max py-[.625vw] rounded-[.4167vw]" :style="`left: ${text.screenX}%;top: ${text.screenY}%;`">
            <div class="flex items-center gap-x-[.2083vw] absolute top-[-.7292vw] left-[.7292vw]">
                <div class="p-[.2083vw] bg-[#FFFFFF] rounded-[.2083vw] flex items-center justify-center">
                    <p class="font-['Poppins-SemiBold'] text-[#525252] text-[.5729vw] leading-none">{{ text.player }}</p>
                </div>
                <div class="p-[.2083vw] rounded-[.2083vw] flex items-center justify-center" :style="`background-color: ${ChatMessageColors[text.category].bg}`">
                    <p class="font-['Poppins-SemiBold'] text-[.5729vw] leading-none" :style="`color: ${ChatMessageColors[text.category].text}`">{{ GetCategoryLabel(text.category) }}</p>
                </div>
            </div>
            <p v-if="!text.isDice && !text.isRPS" class="text-[.625vw] font-['Poppins-Regular'] leading-tight text-[#FFF] max-w-[15.625vw] line-clamp-2">{{ text.message }}</p>
            <div v-else class="flex flex-col items-center gap-y-[.2604vw]">
                <template v-if="text.isDice">
                    <i class="fa-solid fa-dice text-[1.25vw] text-[#FFF]"></i>
                    <p class="text-[.625vw] font-['Poppins-Regular'] leading-tight text-[#FFF] max-w-[15.625vw] line-clamp-2">{{ text.message }}</p>
                </template>
                <template v-else-if="text.isRPS">
                    <i v-if="text.isRPS && text.hand == 'rock'" class="fa-solid fa-hand-back-fist text-[1.25vw] text-[#FFF]"></i>
                    <i v-if="text.isRPS && text.hand == 'paper'" class="fa-solid fa-hand text-[1.25vw] text-[#FFF]"></i>
                    <i v-if="text.isRPS && text.hand == 'scissors'" class="fa-solid fa-hand-scissors text-[1.25vw] text-[#FFF]"></i>
                    <p class="text-[.625vw] font-['Poppins-Regular'] leading-tight text-[#FFF] max-w-[15.625vw] line-clamp-2">{{ text.message }}</p>
                </template>
            </div>
            <svg width="1.1979vw" height=".625vw" viewBox="0 0 23 12" fill="none" class="absolute bottom-[-0.599vw] left-[.5208vw]" xmlns="http://www.w3.org/2000/svg">
                <path d="M22.5 0.5L11.5 11.5L0.5 0.5H22.5Z" fill="#202125B2"/>
            </svg>
        </div>
    </template>
</template>