import { system, world, EquipmentSlot, GameMode, Player, EntityDamageCause } from "@minecraft/server";

/** Vanilla-like ore mining XP (iron/gold/copper/deepslate variants). */
const ORE_MINING_XP = { min: 0, max: 2 };

/** Vanilla-like smelt XP per output (raw iron -> iron ingot). */
const SMELT_XP_PER_ITEM = 0.7;

const RIFLE_ID = "toolsplusplus:eagle_eye_rifle";
const AMMO_ITEM_ID = "toolsplusplus:rifle_ammo";
const RIFLE_SOUND_ID = "toolsplusplus.eagle_eye_sfx";
const SCOPE_SOUND_ID = "toolsplusplus.camera_zoom";
const RIFLE_BULLET_TAG = "toolsplusplus:rifle_bullet";
const RIFLE_COOLDOWN_TICKS = 12;
const SPYGLASS_FOV = 3;
const SCOPE_SLOWNESS_AMPLIFIER = 3;
const SCOPE_SLOWNESS_DURATION = 20;
const BULLET_SPEED = 5;
const BULLET_DAMAGE = 8;

/** @type {Map<string, number>} */
const lastShotTick = new Map();

/** @type {Map<string, boolean>} */
const isScoped = new Map();

const SMELT_OUTPUTS = new Set([
  "toolsplusplus:ruby_chunk",
]);

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
    itemStack.hasTag("toolsplusplus:ruby_tier") ||
    itemStack.hasTag("toolsplusplus:sapphire_tier")
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
  if (!afterItemStack || !SMELT_OUTPUTS.has(afterItemStack.typeId)) {
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

function getMainhandItem(player) {
  const equippable = player.getComponent("minecraft:equippable");
  return equippable?.getEquipment(EquipmentSlot.Mainhand);
}

function isHoldingRifle(player) {
  return getMainhandItem(player)?.typeId === RIFLE_ID;
}

function consumeAmmo(player) {
  const inventory = player.getComponent("minecraft:inventory");
  const container = inventory?.container;
  if (!container) {
    return false;
  }

  for (let slot = 0; slot < container.size; slot++) {
    const stackItem = container.getItem(slot);
    if (stackItem?.typeId === AMMO_ITEM_ID) {
      if (stackItem.amount > 1) {
        stackItem.amount -= 1;
        container.setItem(slot, stackItem);
      } else {
        container.setItem(slot, undefined);
      }
      return true;
    }
  }

  return false;
}

function spawnRifleBullet(player) {
  const viewDirection = player.getViewDirection();
  const head = player.getHeadLocation();
  const spawnAt = {
    x: head.x + viewDirection.x * 0.6,
    y: head.y + viewDirection.y * 0.2,
    z: head.z + viewDirection.z * 0.6,
  };

  const bullet = player.dimension.spawnEntity("minecraft:arrow", spawnAt);
  bullet.addTag(RIFLE_BULLET_TAG);

  const projectile = bullet.getComponent("minecraft:projectile");
  if (projectile) {
    projectile.owner = player;
  }

  bullet.applyImpulse({
    x: viewDirection.x * BULLET_SPEED,
    y: viewDirection.y * BULLET_SPEED,
    z: viewDirection.z * BULLET_SPEED,
  });
}

function fireRifle(player) {
  const currentTick = system.currentTick;
  const lastTick = lastShotTick.get(player.id) ?? -Infinity;
  if (currentTick - lastTick < RIFLE_COOLDOWN_TICKS) {
    return;
  }

  if (!consumeAmmo(player)) {
    player.dimension.playSound(RIFLE_SOUND_ID, player.location, { volume: 0.3, pitch: 1.8 });
    player.onScreenDisplay.setActionBar("Eagle Eye Rifle: Out of ammo!");
    return;
  }

  lastShotTick.set(player.id, currentTick);
  player.dimension.playSound(RIFLE_SOUND_ID, player.location, { volume: 1, pitch: 1 });
  spawnRifleBullet(player);
}

function applySpyglassScope(player) {
  try {
    player.camera.setFov({ fov: SPYGLASS_FOV });
  } catch (_error) {
    // Camera may be unavailable in restricted contexts.
  }

  player.addEffect("slowness", SCOPE_SLOWNESS_DURATION, {
    amplifier: SCOPE_SLOWNESS_AMPLIFIER,
    showParticles: false,
  });
}

function beginScope(player) {
  isScoped.set(player.id, true);
  player.dimension.playSound(SCOPE_SOUND_ID, player.location, { volume: 0.22, pitch: 1.0 });
  applySpyglassScope(player);
}

function resetScope(player) {
  try {
    player.camera.clear();
  } catch (_error) {
    // Ignore camera clear failures.
  }

  try {
    player.removeEffect("slowness");
  } catch (_error) {
    // Ignore effect removal failures.
  }

  isScoped.set(player.id, false);
}

function handleRifleScopeRelease(event) {
  if (event.itemStack?.typeId !== RIFLE_ID || !(event.source instanceof Player)) {
    return;
  }

  resetScope(event.source);
}

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

world.beforeEvents.itemUse.subscribe((event) => {
  if (event.itemStack?.typeId !== RIFLE_ID) {
    return;
  }

  // Cancel vanilla item-use state so left-click attacks still work while aiming.
  event.cancel = true;

  const player = event.source;
  system.run(() => {
    if (!isScoped.get(player.id)) {
      beginScope(player);
    }
  });
});

world.afterEvents.playerSwingStart.subscribe((event) => {
  if (!isHoldingRifle(event.player)) {
    return;
  }

  fireRifle(event.player);
});

world.afterEvents.itemReleaseUse.subscribe(handleRifleScopeRelease);
world.afterEvents.itemStopUse.subscribe(handleRifleScopeRelease);

world.afterEvents.projectileHitEntity.subscribe((event) => {
  const bullet = event.projectile;
  if (!bullet?.hasTag(RIFLE_BULLET_TAG)) {
    return;
  }

  const hit = event.getEntityHit();
  const victim = hit?.entity;
  const shooter = event.source;
  if (!victim || victim.id === shooter?.id) {
    bullet.remove();
    return;
  }

  victim.applyDamage(BULLET_DAMAGE, {
    cause: EntityDamageCause.projectile,
    damagingEntity: shooter,
  });

  if (victim.isValid) {
    const viewDirection = shooter?.getViewDirection();
    if (viewDirection) {
      victim.applyKnockback({ x: viewDirection.x, z: viewDirection.z }, 0.2);
    }
  }

  bullet.remove();
});

world.afterEvents.projectileHitBlock.subscribe((event) => {
  if (event.projectile?.hasTag(RIFLE_BULLET_TAG)) {
    event.projectile.remove();
  }
});

system.runInterval(() => {
  for (const player of world.getAllPlayers()) {
    if (isHoldingRifle(player)) {
      if (isScoped.get(player.id)) {
        applySpyglassScope(player);
      }
    } else if (isScoped.get(player.id)) {
      resetScope(player);
    }
  }
}, 4);
