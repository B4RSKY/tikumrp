<script setup>
    import { DefaultData } from '@/store/index';
    import { storeToRefs } from 'pinia';
    import { motion, AnimatePresence } from 'motion-v';

    const StoreData = DefaultData();
    const { ShowCommandList, DefaultCommands, Locales } = storeToRefs(StoreData);
</script>

<template>
    <AnimatePresence mode="sync">
        <motion.div v-if="ShowCommandList" :initial="{ y: '100%', opacity: 0 }" :animate="{ y: 0, opacity: 1 }" :exit="{ y: '100%', opacity: 0 }" :transition="{ duration: 0.5 }" class="w-[18.75vw] h-max max-h-[80vh] bg-[#1B1C20] rounded-[.625vw] flex flex-col items-start absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-[100] overflow-hidden">
            <div class="flex items-center justify-between w-full px-[1.0938vw] py-[1.0417vw]">
                <div class="w-[2.3958vw] h-[2.3958vw] bg-[#17181C] rounded-[.3125vw] flex items-center justify-center cursor-pointer hover:bg-[#FFFFFF0A] transition-all duration-200" @click="StoreData.ToggleSettings()">
                    <i class="fa-solid fa-angle-left text-[#FFF] text-[.8333vw]"></i>
                </div>
                <p class="text-[.7292vw] font-['Poppins-Medium'] text-[#FFF] leading-tight line-clamp-1">{{ Locales.command_list }}</p>
            </div>
            <div class="w-full h-max bg-[#17181C] px-[1.0938vw] py-[1.0417vw] flex flex-col rounded-[.625vw]">
                <div id="command-list" class="flex flex-col items-start w-full h-max gap-y-[.5208vw] overflow-y-auto max-h-[60vh]">
                    <template v-for="(command, index) in DefaultCommands" :key="index">
                        <div class="p-[.5208vw] flex flex-col items-start gap-y-[.3125vw] bg-[#FFFFFF05] border-[.0521vw] border-solid border-[#FFFFFF0F] rounded-[.2083vw]">
                            <div class="flex items-center gap-x-[.2083vw]">
                                <p class="text-[.7292vw] font-['Poppins-Medium'] text-[#FFF] leading-tight line-clamp-1">/{{ command.name }}</p>
                                <template v-for="(args, index) in command.aliases" :key="index">
                                    <p class="text-[.7292vw] font-['Poppins-Medium'] text-[#FFF]/55 leading-tight line-clamp-1">[{{ args.name }}]</p>
                                </template>
                            </div>
                            <p class="text-[.625vw] font-['Poppins-Regular'] text-[#FFF]/55 leading-tight">{{ command.description }}</p>
                        </div>
                    </template>
                </div>
            </div>
        </motion.div>
    </AnimatePresence>
</template>

<style scoped>
    #command-list::-webkit-scrollbar {
        width: 0.2083vw;
    }
    #command-list::-webkit-scrollbar-thumb {
        background-color: rgba(255, 255, 255, 0.1);
        border-radius: 0.1042vw;
    }
    #command-list::-webkit-scrollbar-track {
        background-color: transparent;
    }
    #command-list::-webkit-scrollbar-corner {
        background-color: transparent;
    }
    #command-list::-webkit-scrollbar-button {
        display: none;
    }
    #command-list::-webkit-scrollbar-track-piece {
        background-color: transparent;
    }
    #command-list::-webkit-scrollbar-thumb:hover {
        background-color: rgba(255, 255, 255, 0.2);
    }
    #command-list::-webkit-scrollbar-thumb:active {
        background-color: rgba(255, 255, 255, 0.3);
    }
    #command-list::-webkit-scrollbar-thumb:vertical {
        background-color: rgba(255, 255, 255, 0.1);
    }
    #command-list::-webkit-scrollbar-thumb:horizontal {
        background-color: rgba(255, 255, 255, 0.1);
    }
</style>