// scripts/main.ts
import { system, world, EntityDamageCause, EquipmentSlot, Player } from "@minecraft/server";
var RIFLE_ID = "com_eagle_eye_rifle_3jdckckc:my_sword";
var AMMO_ITEM_ID = "com_eagle_eye_rifle_3jdckckc:rifle_ammo";
var RIFLE_SOUND_ID = "com.eagle_eye_rifle_3jdckckc.eagle_eye_sfx";
var CAMERA_ZOOM_SOUND_ID = "com.eagle_eye_rifle_3jdckckc.camera_zoom";
var COOLDOWN_TICKS = 12;
var MAX_ZOOM_LEVEL = 5;
var SCOPE_CAMERA_PRESETS = [
  "com_eagle_eye_rifle_3jdckckc:scope_zoom_1",
  "com_eagle_eye_rifle_3jdckckc:scope_zoom_2",
  "com_eagle_eye_rifle_3jdckckc:scope_zoom_3",
  "com_eagle_eye_rifle_3jdckckc:scope_zoom_4",
  "com_eagle_eye_rifle_3jdckckc:scope_zoom_5"
];
var SLOWNESS_EFFECT = "slowness";
var lastShotTick = /* @__PURE__ */ new Map();
var zoomLevel = /* @__PURE__ */ new Map();
var isScoped = /* @__PURE__ */ new Map();
var lastLeftClickBlockTick = /* @__PURE__ */ new Map();
function consumeAmmo(player) {
  const inventory = player.getComponent("minecraft:inventory");
  const container = inventory?.container;
  if (!container) {
    return false;
  }
  for (let slot = 0; slot < container.size; slot++) {
    const stackItem = container.getItem(slot);
    if (stackItem && stackItem.typeId === AMMO_ITEM_ID) {
      if (stackItem.amount > 1) {
        stackItem.amount -= 1;
        container.setItem(slot, stackItem);
      } else {
        container.setItem(slot, void 0);
      }
      return true;
    }
  }
  return false;
}
function fireRifle(player) {
  const currentTick = system.currentTick;
  const lastTick = lastShotTick.get(player.id) ?? -Infinity;
  if (currentTick - lastTick < COOLDOWN_TICKS) {
    return;
  }
  const hadAmmo = consumeAmmo(player);
  if (!hadAmmo) {
    player.dimension.playSound(RIFLE_SOUND_ID, player.location, { volume: 0.3, pitch: 1.8 });
    player.onScreenDisplay.setActionBar("Eagle Eye Rifle: Out of ammo!");
    return;
  }
  lastShotTick.set(player.id, currentTick);
  const viewDirection = player.getViewDirection();
  const muzzleLocation = {
    x: player.location.x + viewDirection.x * 0.5,
    y: player.location.y + 1.5,
    z: player.location.z + viewDirection.z * 0.5
  };
  player.dimension.playSound(RIFLE_SOUND_ID, player.location, { volume: 1, pitch: 1 });
  const rayHits = player.dimension.getEntitiesFromRay(muzzleLocation, viewDirection, {
    maxDistance: 100
  });
  for (const rayHit of rayHits) {
    const hitEntity = rayHit.entity;
    if (hitEntity.id === player.id) {
      continue;
    }
    hitEntity.applyDamage(8, {
      cause: EntityDamageCause.entityAttack,
      damagingEntity: player
    });
    if (hitEntity.isValid) {
      hitEntity.applyKnockback({ x: viewDirection.x, z: viewDirection.z }, 0.2);
    }
    break;
  }
}
function getReticle(level) {
  const bars = "-".repeat(level + 1);
  return `${bars}  +  ${bars}
Eagle Eye Scope: Zoom ${level}/${MAX_ZOOM_LEVEL}`;
}
function applyZoom(player, level) {
  try {
    player.camera.setCamera(SCOPE_CAMERA_PRESETS[level - 1] ?? SCOPE_CAMERA_PRESETS[0]);
  } catch (_error) {
    try {
      player.camera.setCamera("minecraft:first_person");
    } catch (_fallbackError) {
    }
  }
  player.addEffect(SLOWNESS_EFFECT, 12, { amplifier: Math.min(level + 1, 5), showParticles: false });
  player.onScreenDisplay.setActionBar(getReticle(level));
}
function cycleZoom(player) {
  const currentLevel = zoomLevel.get(player.id) ?? 0;
  const nextLevel = currentLevel >= MAX_ZOOM_LEVEL ? 1 : currentLevel + 1;
  zoomLevel.set(player.id, nextLevel);
  player.dimension.playSound(CAMERA_ZOOM_SOUND_ID, player.location, {
    volume: 0.22,
    pitch: 0.85 + nextLevel * 0.12
  });
  applyZoom(player, nextLevel);
}
function resetScope(player) {
  try {
    player.camera.clear();
  } catch (_error) {
  }
  try {
    player.removeEffect(SLOWNESS_EFFECT);
  } catch (_error) {
  }
  player.onScreenDisplay.setActionBar("");
  isScoped.set(player.id, false);
}
function isPlayer(entity) {
  return entity instanceof Player;
}
var RifleFireComponent = {
  onUse(event) {
    const player = event.source;
    cycleZoom(player);
    isScoped.set(player.id, true);
  },
  // Bedrock exposes left-clicks against entities through item hit callbacks.
  // Use the same hitscan rifle logic so a left-click attack fires the gun while
  // preserving the current zoom level and allowing the player to stay crouched.
  onHitEntity(event) {
    const attackingEntity = event.attackingEntity;
    if (isPlayer(attackingEntity)) {
      fireRifle(attackingEntity);
    }
  }
};
function handleLeftClickBlock(event) {
  const player = event.player ?? event.source;
  if (!player || !player.isValid) {
    return;
  }
  const equipment = player.getComponent("minecraft:equippable");
  const mainhandItem = equipment?.getEquipment(EquipmentSlot.Mainhand);
  if (mainhandItem?.typeId !== RIFLE_ID) {
    return;
  }
  const lastTick = lastLeftClickBlockTick.get(player.id) ?? -Infinity;
  if (system.currentTick - lastTick <= 1) {
    return;
  }
  lastLeftClickBlockTick.set(player.id, system.currentTick);
  fireRifle(player);
}
system.beforeEvents.startup.subscribe(({ itemComponentRegistry }) => {
  itemComponentRegistry.registerCustomComponent(
    "com_eagle_eye_rifle_3jdckckc:rifle_fire_component",
    RifleFireComponent
  );
});
var afterEvents = world.afterEvents;
afterEvents.playerBreakBlock?.subscribe(handleLeftClickBlock);
system.runInterval(() => {
  for (const player of world.getAllPlayers()) {
    const equipment = player.getComponent("minecraft:equippable");
    const mainhandItem = equipment?.getEquipment(EquipmentSlot.Mainhand);
    const holdingRifle = mainhandItem?.typeId === RIFLE_ID;
    if (holdingRifle) {
      if (!zoomLevel.has(player.id)) {
        zoomLevel.set(player.id, 0);
      }
      if (isScoped.get(player.id)) {
        applyZoom(player, zoomLevel.get(player.id) || 1);
      }
    } else if (isScoped.get(player.id)) {
      resetScope(player);
      zoomLevel.delete(player.id);
    }
  }
}, 4);
