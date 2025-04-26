package com.example.sachecraft;

import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.block.AbstractBlock;
import net.minecraftforge.common.ToolType;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.event.lifecycle.FMLClientSetupEvent;
import net.minecraftforge.fml.event.lifecycle.FMLCommonSetupEvent;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod.EventBusSubscriber;

@Mod("sachecraft")
public class SachecraftMod {
    public SachecraftMod() {
        // Initialization logic
    }

    @EventBusSubscriber(bus = EventBusSubscriber.Bus.MOD)
    public static class BlockRegistry {
        public static final Block SACHE_BLOCK = new Block(AbstractBlock.Properties.copy(Blocks.END_STONE)
                .harvestLevel(1)
                .harvestTool(ToolType.PICKAXE)
                .strength(3.0f));

        @SubscribeEvent
        public static void onRegisterBlocks(RegistryEvent.Register<Block> event) {
            event.getRegistry().register(SACHE_BLOCK.setRegistryName("sache_block"));
        }
    }
  }
