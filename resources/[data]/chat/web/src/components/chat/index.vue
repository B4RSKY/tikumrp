<script setup>
import { DefaultData } from '@/store/index'
import { storeToRefs } from 'pinia'

import Velmor from './components/velmor/index.vue';
import VelmorV2 from './components/velmorv2/index.vue';
import Grids from './components/grids/index.vue';
import Modern from './components/modern/index.vue';
import Res from './components/res/index.vue';
import Samp from './components/samp/index.vue';

const StoreData = DefaultData();
const { SelectedTheme, SelectedSize, ShowChat } = storeToRefs(StoreData);
</script>

<template>
    <div class="w-full h-full" style="display: flex;transition: transform 0.3s ease !important;" :style="`transform: scale(${SelectedSize.size}) !important;transform-origin: ${StoreData.GetPositionText()} !important;`">
        <template v-if="SelectedTheme.name === 'velmor'">
            <Velmor />
        </template>
        <template v-else-if="SelectedTheme.name === 'velmor-v2'">
            <VelmorV2 />
        </template>
        <template v-else-if="SelectedTheme.name === 'grids'">
            <Grids />
        </template>
        <template v-else-if="SelectedTheme.name === 'modern'">
            <Modern />
        </template>
        <template v-else-if="SelectedTheme.name === 'res'">
            <Res />
        </template>
        <template v-else-if="SelectedTheme.name === 'samp'">
            <Samp />
        </template>
    </div>
</template>