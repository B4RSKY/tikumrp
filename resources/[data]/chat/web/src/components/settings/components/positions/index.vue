<script setup>
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'

const StoreData = DefaultData();
const { Positions, SelectedPosition, Locales } = storeToRefs(StoreData);
</script>

<template>
    <div class="w-full flex flex-col items-center gap-y-[.9375vw]">
        <div class="flex items-center self-start gap-x-[.5208vw]">
            <div class="w-[1.9792vw] h-[1.9792vw] flex items-center justify-center bg-[#202125] rounded-[.3125vw]">
                <img src="/svgs/position.svg" alt="position" class="w-[.8333vw] h-[.8333vw]">
            </div>
            <div class="flex flex-col items-start">
                <p class="text-[.8333vw] text-[#FFFFFF] leading-tight line-clamp-1 font-['Poppins-Bold'] max-w-[13.8542vw]">{{ Locales.position }}</p>
                <p class="text-[.7292vw] text-[#FFFFFF59] leading-tight line-clamp-1 font-['Poppins-Regular'] max-w-[13.8542vw]">{{ Locales.position_description }}</p>
            </div>
        </div>
        <div class="grid items-center w-max gap-[.3646vw]" style="grid-template-columns: repeat(3, max-content);">
            <div class="w-[5.2083vw] h-[3.0208vw] rounded-[.2083vw] border-[.0521vw] border-solid relative cursor-pointer" :style="SelectedPosition.name == 'top-left' ? 'background-color: #FFFFFF14;border-color:#FFFFFF1F;' : 'background-color: #FFFFFF0F;border-color:#FFFFFF0F;'" @click="SelectedPosition = Positions[0]">
                <div class="w-[1.3542vw] h-[.8333vw] bg-[#FFFFFF1F] rounded-[.1042vw] border-[.0521vw] border-solid border-[#FFFFFF24] absolute top-[.3125vw] left-[.3125vw]"></div>
            </div>
            <div class="w-[5.2083vw] h-[3.0208vw] rounded-[.2083vw] border-[.0521vw] border-solid relative cursor-pointer" :style="SelectedPosition.name == 'top-center' ? 'background-color: #FFFFFF14;border-color:#FFFFFF1F;' : 'background-color: #FFFFFF0F;border-color:#FFFFFF0F;'" @click="SelectedPosition = Positions[1]">
                <div class="w-[1.3542vw] h-[.8333vw] bg-[#FFFFFF1F] rounded-[.1042vw] border-[.0521vw] border-solid border-[#FFFFFF24] absolute top-[.3125vw] -translate-x-1/2 left-1/2"></div>
            </div>
            <div class="w-[5.2083vw] h-[3.0208vw] rounded-[.2083vw] border-[.0521vw] border-solid relative cursor-pointer" :style="SelectedPosition.name == 'top-right' ? 'background-color: #FFFFFF14;border-color:#FFFFFF1F;' : 'background-color: #FFFFFF0F;border-color:#FFFFFF0F;'" @click="SelectedPosition = Positions[2]">
                <div class="w-[1.3542vw] h-[.8333vw] bg-[#FFFFFF1F] rounded-[.1042vw] border-[.0521vw] border-solid border-[#FFFFFF24] absolute top-[.3125vw] right-[.3125vw]"></div>
            </div>
            <div class="w-[5.2083vw] h-[3.0208vw] rounded-[.2083vw] border-[.0521vw] border-solid relative cursor-pointer" :style="SelectedPosition.name == 'center-left' ? 'background-color: #FFFFFF14;border-color:#FFFFFF1F;' : 'background-color: #FFFFFF0F;border-color:#FFFFFF0F;'" @click="SelectedPosition = Positions[3]">
                <div class="w-[1.3542vw] h-[.8333vw] bg-[#FFFFFF1F] rounded-[.1042vw] border-[.0521vw] border-solid border-[#FFFFFF24] absolute -translate-y-1/2 top-1/2 left-[.3125vw]"></div>
            </div>
            <div class="w-[5.2083vw] h-[3.0208vw] relative">
            </div>
            <div class="w-[5.2083vw] h-[3.0208vw] rounded-[.2083vw] border-[.0521vw] border-solid relative cursor-pointer" :style="SelectedPosition.name == 'center-right' ? 'background-color: #FFFFFF14;border-color:#FFFFFF1F;' : 'background-color: #FFFFFF0F;border-color:#FFFFFF0F;'" @click="SelectedPosition = Positions[4]">
                <div class="w-[1.3542vw] h-[.8333vw] bg-[#FFFFFF1F] rounded-[.1042vw] border-[.0521vw] border-solid border-[#FFFFFF24] absolute -translate-y-1/2 top-1/2 right-[.3125vw]"></div>
            </div>
            <div class="w-[5.2083vw] h-[3.0208vw] rounded-[.2083vw] border-[.0521vw] border-solid relative cursor-pointer" :style="SelectedPosition.name == 'bottom-left' ? 'background-color: #FFFFFF14;border-color:#FFFFFF1F;' : 'background-color: #FFFFFF0F;border-color:#FFFFFF0F;'" @click="SelectedPosition = Positions[5]">
                <div class="w-[1.3542vw] h-[.8333vw] bg-[#FFFFFF1F] rounded-[.1042vw] border-[.0521vw] border-solid border-[#FFFFFF24] absolute bottom-[.3125vw] left-[.3125vw]"></div>
            </div>
            <div class="w-[5.2083vw] h-[3.0208vw] rounded-[.2083vw] border-[.0521vw] border-solid relative cursor-pointer" :style="SelectedPosition.name == 'bottom-center' ? 'background-color: #FFFFFF14;border-color:#FFFFFF1F;' : 'background-color: #FFFFFF0F;border-color:#FFFFFF0F;'" @click="SelectedPosition = Positions[6]">
                <div class="w-[1.3542vw] h-[.8333vw] bg-[#FFFFFF1F] rounded-[.1042vw] border-[.0521vw] border-solid border-[#FFFFFF24] absolute bottom-[.3125vw] -translate-x-1/2 left-1/2"></div>
            </div>
            <div class="w-[5.2083vw] h-[3.0208vw] rounded-[.2083vw] border-[.0521vw] border-solid relative cursor-pointer" :style="SelectedPosition.name == 'bottom-right' ? 'background-color: #FFFFFF14;border-color:#FFFFFF1F;' : 'background-color: #FFFFFF0F;border-color:#FFFFFF0F;'" @click="SelectedPosition = Positions[7]">
                <div class="w-[1.3542vw] h-[.8333vw] bg-[#FFFFFF1F] rounded-[.1042vw] border-[.0521vw] border-solid border-[#FFFFFF24] absolute bottom-[.3125vw] right-[.3125vw]"></div>
            </div>
        </div>
    </div>
</template>