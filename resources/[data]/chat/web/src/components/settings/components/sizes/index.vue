<script setup>
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'

const StoreData = DefaultData();
const { Sizes, SelectedSize, Locales } = storeToRefs(StoreData);

const GetSizeLabel = (size) => {
    switch (size) {
        case 'small':
            return Locales.value.small;
        case 'medium':
            return Locales.value.medium;
        case 'large':
            return Locales.value.large;
        default:
            return '';
    }
}
</script>

<template>
    <div v-if="Locales && Locales.size && Locales.size_description" class="w-full flex flex-col items-center gap-y-[.9375vw]">
        <div class="flex items-center self-start gap-x-[.5208vw]">
            <div class="w-[1.9792vw] h-[1.9792vw] flex items-center justify-center bg-[#202125] rounded-[.3125vw]">
                <img src="/svgs/size.svg" alt="color" class="w-[.8333vw] h-[.8333vw]">
            </div>
            <div class="flex flex-col items-start">
                <p class="text-[.8333vw] text-[#FFFFFF] leading-tight line-clamp-1 font-['Poppins-Bold'] max-w-[13.8542vw]">{{ Locales.size }}</p>
                <p class="text-[.7292vw] text-[#FFFFFF59] leading-tight line-clamp-1 font-['Poppins-Regular'] max-w-[13.8542vw]">{{ Locales.size_description }}</p>
            </div>
        </div>
        <div class="flex items-center gap-x-[.3646vw] w-full">
            <div
                v-for="(size, index) in Sizes"
                :key="index"
                class="w-[5.2083vw] h-[1.9792vw] flex items-center justify-center rounded-[.2083vw] border-[.0521vw] border-solid border-[#FFFFFF0F] cursor-pointer"
                :class="size.name == SelectedSize.name ? 'bg-[#FFFFFF]' : 'bg-[#FFFFFF0A]'"
                @click="SelectedSize = size"
            >
                <p
                    class="text-[.7292vw] leading-tight line-clamp-1 font-['Poppins-Medium']"
                    :class="size.name == SelectedSize.name ? 'text-[#17181C]' : 'text-[#FFFFFF]'"
                >
                    {{ GetSizeLabel(size.name) }}
                </p>
            </div>
        </div>
    </div>
</template>