<script setup>
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'

const StoreData = DefaultData();
const { Colors, SelectedColor, Locales } = storeToRefs(StoreData);
</script>

<template>
    <div class="w-full flex flex-col items-center gap-y-[.9375vw]">
        <div class="flex items-center self-start gap-x-[.5208vw]">
            <div class="w-[1.9792vw] h-[1.9792vw] flex items-center justify-center bg-[#202125] rounded-[.3125vw]">
                <img src="/svgs/color.svg" alt="color" class="w-[.8333vw] h-[.8333vw]">
            </div>
            <div class="flex flex-col items-start">
                <p class="text-[.8333vw] text-[#FFFFFF] leading-tight line-clamp-1 font-['Poppins-Bold'] max-w-[13.8542vw]">{{ Locales.main_color }}</p>
                <p class="text-[.7292vw] text-[#FFFFFF59] leading-tight line-clamp-1 font-['Poppins-Regular'] max-w-[13.8542vw]">{{ Locales.main_color_description }}</p>
            </div>
        </div>
        <div class="grid items-center gap-x-[.3646vw] gap-y-[.3646vw]" style="grid-template-columns: repeat(8, max-content);">
            <div
                v-for="(color, index) in Colors"
                :key="index"
                class="w-[1.7708vw] h-[1.7708vw] flex items-center justify-center rounded-[.2604vw] cursor-pointer"
                :class="SelectedColor.hex == color.hex ? 'border-[.1042vw] border-solid border-[#FFFFFF]' : ''"
                :style="`background-color: ${color.hex};`"
                @click="StoreData.SetColor(color)"
            >
                <img src="/svgs/color-check.svg" alt="color-check" class="w-[.625vw] h-auto" draggable="false" v-if="SelectedColor.hex == color.hex" />
            </div>
        </div>
    </div>
</template>