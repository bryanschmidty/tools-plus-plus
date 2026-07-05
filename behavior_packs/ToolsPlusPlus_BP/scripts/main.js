import { system, world, EquipmentSlot, GameMode, Player } from "@minecraft/server";

/** Vanilla-like ore mining XP (iron/gold/copper/deepslate variants). */
const ORE_MINING_XP = { min: 0, max: 2 };

/** Vanilla-like smelt XP per output (raw iron -> iron ingot). */
const SMELT_XP_PER_ITEM = 0.7;

const SMELT_OUTPUT = "toolsplusplus:ruby_chunk";

const SMELTER_BLOCK_TYPES = new Set([
  "minecraft:furnace",
  "minecraft:lit_furnace",
  "minecraft:blast_furnace",
  "minecraft:lit_blast_furnace",
]);

const SMELT_SESSION_TICKS = 40;

/** @type {Map<string, { blockKey: string, untilTick: number }>} */
const activeSmeltSessions = new Map();

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function blockKey(block) {
  return `${block.dimension.id}:${block.x}:${block.y}:${block.z}`;
}

function isSmelterBlock(typeId) {
  return SMELTER_BLOCK_TYPES.has(typeId);
}

function asPlayer(entity) {
  if (!entity || entity.typeId !== "minecraft:player") {
    return undefined;
  }

  return entity;
}

function beginSmeltSession(player, block) {
  activeSmeltSessions.set(player.id, {
    blockKey: blockKey(block),
    untilTick: system.currentTick + SMELT_SESSION_TICKS,
  });
}

function extendSmeltSession(player) {
  const session = activeSmeltSessions.get(player.id);
  if (!session) {
    return;
  }

  session.untilTick = system.currentTick + SMELT_SESSION_TICKS;
}

function getSmeltSession(player) {
  const session = activeSmeltSessions.get(player.id);
  if (!session) {
    return undefined;
  }

  if (system.currentTick > session.untilTick) {
    activeSmeltSessions.delete(player.id);
    return undefined;
  }

  return session;
}

function isValidOrePickaxe(itemStack) {
  if (!itemStack) {
    return false;
  }

  if (!itemStack.hasTag("minecraft:is_tool") || !itemStack.hasTag("minecraft:is_pickaxe")) {
    return false;
  }

  return (
    itemStack.hasTag("minecraft:iron_tier") ||
    itemStack.hasTag("minecraft:diamond_tier") ||
    itemStack.hasTag("minecraft:netherite_tier") ||
    itemStack.hasTag("toolsplusplus:ruby_tier")
  );
}

function hasSilkTouch(itemStack) {
  const enchantable = itemStack.getComponent("minecraft:enchantable");
  return !!enchantable?.getEnchantment("silk_touch");
}

function spawnMiningXpOrbs(dimension, location, min, max) {
  const orbCount = randomInt(min, max);
  if (orbCount <= 0) {
    return;
  }

  const spawnAt = {
    x: location.x + 0.5,
    y: location.y + 0.5,
    z: location.z + 0.5,
  };

  for (let i = 0; i < orbCount; i++) {
    dimension.spawnEntity("minecraft:xp_orb", spawnAt);
  }
}

function awardSmeltXp(player, itemCount) {
  for (let i = 0; i < itemCount; i++) {
    if (Math.random() < SMELT_XP_PER_ITEM) {
      player.addExperience(1);
    }
  }
}

function getInventoryGain(beforeItemStack, afterItemStack) {
  if (!afterItemStack || afterItemStack.typeId !== SMELT_OUTPUT) {
    return 0;
  }

  const beforeAmount =
    beforeItemStack?.typeId === afterItemStack.typeId ? beforeItemStack.amount : 0;

  return Math.max(0, afterItemStack.amount - beforeAmount);
}

const ExperienceRewardComponent = {
  onPlayerBreak({ block, dimension, player }, { params }) {
    const equippable = player?.getComponent("minecraft:equippable");
    if (!equippable) {
      return;
    }

    const itemStack = equippable.getEquipment(EquipmentSlot.Mainhand);
    if (!isValidOrePickaxe(itemStack) || hasSilkTouch(itemStack)) {
      return;
    }

    const min = params?.min ?? ORE_MINING_XP.min;
    const max = params?.max ?? ORE_MINING_XP.max;
    spawnMiningXpOrbs(dimension, block.location, min, max);
  },
};

/** Applies one point of mining wear with unbreaking, matching vanilla digger behavior. */
function applyToolDurabilityDamage(player) {
  const equippable = player.getComponent("minecraft:equippable");
  if (!equippable) {
    return;
  }

  const mainhand = equippable.getEquipmentSlot(EquipmentSlot.Mainhand);
  if (!mainhand.hasItem()) {
    return;
  }

  const itemStack = mainhand.getItem();
  const durability = itemStack.getComponent("minecraft:durability");
  if (!durability || durability.unbreakable) {
    return;
  }

  const enchantable = itemStack.getComponent("minecraft:enchantable");
  const unbreakingLevel = enchantable?.getEnchantment("unbreaking")?.level;
  const damageChance = durability.getDamageChance(unbreakingLevel) / 100;

  if (Math.random() > damageChance) {
    return;
  }

  durability.damage += 1;

  if (durability.damage >= durability.maxDurability) {
    mainhand.setItem(undefined);
    player.playSound("random.break");
    return;
  }

  mainhand.setItem(itemStack);
}

const DiggingDurabilityComponent = {
  onMineBlock({ source }) {
    if (!(source instanceof Player) || source.getGameMode() === GameMode.Creative) {
      return;
    }

    applyToolDurabilityDamage(source);
  },
};

system.beforeEvents.startup.subscribe(({ blockComponentRegistry, itemComponentRegistry }) => {
  blockComponentRegistry.registerCustomComponent(
    "toolsplusplus:experience_reward",
    ExperienceRewardComponent
  );

  itemComponentRegistry.registerCustomComponent(
    "toolsplusplus:digging_durability",
    DiggingDurabilityComponent
  );
});

world.afterEvents.playerInteractWithBlock.subscribe((event) => {
  if (!isSmelterBlock(event.block.typeId)) {
    return;
  }

  beginSmeltSession(event.player, event.block);
});

world.afterEvents.blockContainerOpened.subscribe((event) => {
  const player = asPlayer(event.openSource?.entity);
  if (!player || !isSmelterBlock(event.block.typeId)) {
    return;
  }

  beginSmeltSession(player, event.block);
});

world.afterEvents.blockContainerClosed.subscribe((event) => {
  const player = asPlayer(event.closeSource?.entity);
  if (!player || !isSmelterBlock(event.block.typeId)) {
    return;
  }

  extendSmeltSession(player);
});

world.afterEvents.playerInventoryItemChange.subscribe((event) => {
  const session = getSmeltSession(event.player);
  if (!session) {
    return;
  }

  const gained = getInventoryGain(event.beforeItemStack, event.itemStack);
  if (gained <= 0) {
    return;
  }

  awardSmeltXp(event.player, gained);
  extendSmeltSession(event.player);
});
