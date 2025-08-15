<script setup>
import { onMounted } from 'vue';
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'
import { motion, AnimatePresence } from 'motion-v';

import Themes from './components/themes/index.vue';
import Colors from './components/colors/index.vue';
import Positions from './components/positions/index.vue';
import Sizes from './components/sizes/index.vue';

const StoreData = DefaultData();
const { ShowSettings, ShowNotification, ThreadType, Locales } = storeToRefs(StoreData);
</script>

<template>
    <AnimatePresence mode="sync">
        <motion.div v-if="ShowSettings" :initial="{ y: '100%', opacity: 0 }" :animate="{ y: 0, opacity: 1 }" :exit="{ y: '100%', opacity: 0 }" :transition="{ duration: 0.5 }" class="absolute -translate-x-1/2 -translate-y-1/2 top-1/2 left-1/2 z-10 flex items-center justify-center w-screen h-screen">
            <div class="min-w-[18.75vw] w-max h-max bg-[#1B1C20] flex flex-col items-center rounded-[.625vw]">
                <div class="flex items-center justify-between px-[1.25vw] pt-[1.25vw] pb-[.9375vw] w-full">
                    <div class="flex items-center gap-x-[.6771vw]">
                        <img src="/svgs/logo.svg" alt="logo" class="w-[2.7083vw] h-[2.7083vw]">
                        <div class="flex flex-col items-start">
                            <p class="text-[.8854vw] text-[#FFFFFF] leading-tight font-['Poppins-Bold'] max-w-[13.8542vw]">{{ Locales.chat_settings }}</p>
                            <p class="text-[.7292vw] text-[#FFFFFF59] leading-tight font-['Poppins-Regular'] max-w-[13.8542vw]">{{ Locales.chat_settings_description }}</p>
                        </div>
                    </div>
                    <div class="w-[1.9792vw] h-[1.9792vw] flex items-center justify-center bg-[#202125] hover:bg-[#FFFFFF0A] transition-all duration-200 rounded-[.3125vw] cursor-pointer" @click="StoreData.ToggleCommandList()">
                        <img src="/svgs/mac-commands.svg" alt="commands" class="w-[.7292vw] h-[.7292vw]">
                    </div>
                </div>
                <div class="flex flex-col items-center w-full bg-[#17181C] p-[1.25vw] rounded-[.625vw] gap-y-[1.25vw]">
                    <Themes />
                    <Colors />
                    <Positions />
                    <Sizes />
                    <div class="flex items-center gap-x-[.3125vw] w-full">
                        <div class="w-full h-[1.9792vw] flex items-center justify-center rounded-[.2083vw] border-[.0521vw] border-solid border-[#FFFFFF0F] bg-[#FFFFFF0A] hover:bg-[#FFFFFF] transition-all duration-200 group cursor-pointer" @click="StoreData.ToggleThread()">
                            <p class="text-[.7292vw] leading-tight line-clamp-1 font-['Poppins-Medium'] text-[#FFFFFF] group-hover:text-[#17181C] transition-all duration-200">
                                {{ ThreadType == 'dui' ? 'DUI' : 'Native' }}
                            </p>
                        </div>
                        <div class="w-[1.9792vw] h-[1.9792vw] flex items-center justify-center rounded-[.2083vw] border-[.0521vw] border-solid border-[#FFFFFF0F] bg-[#FFFFFF0A] hover:bg-[#FFFFFF] transition-all duration-200 group cursor-pointer" @click="ShowNotification = !ShowNotification">
                            <i v-if="ShowNotification" class="fa-solid fa-bell text-[#FFFFFF] group-hover:text-[#17181C] transition-all duration-200 text-[.7292vw]"></i>
                            <i v-if="!ShowNotification" class="fa-solid fa-bell-slash text-[#FFFFFF] group-hover:text-[#17181C] transition-all duration-200 text-[.7292vw]"></i>
                        </div>
                    </div>
                </div>
                <div class="flex items-center justify-between w-full px-[1.25vw] py-[.8594vw] gap-x-[.5208vw]">
                    <div class="w-full h-[2.1875vw] flex items-center justify-center rounded-[.2083vw] border-[.0521vw] border-solid border-[#FFFFFF0F] cursor-pointer group bg-[#FFFFFF0A] transition-all duration-200 hover:bg-[#FFFFFF]" @click="StoreData.SaveSettings();ShowSettings = false">
                        <p class="text-[.7292vw] leading-tight line-clamp-1 text-[#FFFFFF] group-hover:text-[#17181C] font-['Poppins-SemiBold'] max-w-[8.0208vw]">{{ Locales.save_changes }}</p>
                    </div>
                    <div class="w-full h-[2.1875vw] flex items-center justify-center rounded-[.2083vw] border-[.0521vw] border-solid border-[#FFFFFF0F] cursor-pointer group bg-[#FFFFFF0A] transition-all duration-200 hover:bg-[#FFFFFF]" @click="StoreData.CancelSettings();ShowSettings = false">
                        <p class="text-[.7292vw] leading-tight line-clamp-1 text-[#FFFFFF] group-hover:text-[#17181C] font-['Poppins-SemiBold'] max-w-[8.0208vw]">{{ Locales.close }}</p>
                    </div>
                </div>
            </div>
        </motion.div>
    </AnimatePresence>
</template>