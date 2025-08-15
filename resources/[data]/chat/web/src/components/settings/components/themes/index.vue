<script setup>
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'

const StoreData = DefaultData();
const { Themes, SelectedTheme, Locales } = storeToRefs(StoreData);
</script>

<template>
    <div class="w-full flex flex-col items-center gap-y-[.9375vw]">
        <div class="flex items-center self-start gap-x-[.5208vw]">
            <div class="w-[1.9792vw] h-[1.9792vw] flex items-center justify-center bg-[#202125] rounded-[.3125vw]">
                <img src="/svgs/theme.svg" alt="theme" class="w-[1.25vw] h-[.8333vw]">
            </div>
            <div class="flex flex-col items-start">
                <p class="text-[.8333vw] text-[#FFFFFF] leading-tight line-clamp-1 font-['Poppins-Bold'] max-w-[13.8542vw]">{{ Locales.chat_theme }}</p>
                <p class="text-[.7292vw] text-[#FFFFFF59] leading-tight line-clamp-1 font-['Poppins-Regular'] max-w-[13.8542vw]">{{ Locales.chat_theme_description }}</p>
            </div>
        </div>
        <div class="flex flex-wrap items-center justify-between gap-[.3646vw] max-w-[calc(3*5.2083vw+2*0.3646vw)]">
            <div
                v-for="(theme, index) in Themes"
                :key="index"
                class="w-[5.2083vw] h-[1.9792vw] flex items-center justify-center rounded-[.2083vw] border-[.0521vw] border-solid border-[#FFFFFF0F] cursor-pointer"
                :class="theme.name == SelectedTheme.name ? 'bg-[#FFFFFF]' : 'bg-[#FFFFFF0A]'"
                @click="StoreData.SetTheme(theme)"
            >
                <p
                    class="text-[.7292vw] leading-tight line-clamp-1 font-['Poppins-Medium']"
                    :class="theme.name == SelectedTheme.name ? 'text-[#17181C]' : 'text-[#FFFFFF]'"
                >
                    {{ theme.label }}
                </p>
            </div>
        </div>
    </div>
</template>