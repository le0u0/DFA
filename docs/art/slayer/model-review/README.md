# Model review before game integration

Gameplay animation integration is paused. The current fixed-part rig is rejected.
The model must look natural as a complete character before another implementation
or animation claim is made.

## Review artifacts

- [Weapon-free model candidate, 1236 × 1273 PNG](model-candidate-1236x1273.png)
- [Original approved appearance reference](../chibi-pixel-reference-v6.png)
- [Rejected combo: sampled GIF frames](rejected-combo-frames.png)
- [Rejected run/thrust: sampled GIF frames](rejected-run-thrust-frames.png)

The sampled review boards enlarge old pixels only to expose the faults; they are
not native-resolution artwork. The old GIF is 620 × 288 with an actor about 80 pixels
tall. It does not represent the detail or appearance of the approved 1236 × 1273 image.

The candidate is a high-resolution edit of the approved appearance: remove the
sword, retain the same character, compact anatomy, costume and asymmetric arms.
Its generated source is 1254 × 1254. Only transparent margins are cropped; the
character pixels are centered at their original scale on a transparent 1236 × 1273
canvas. No rejected 80px game image is upscaled to make it.
The source and exact normalization are recorded in `manifest.json`.

This is a **static review candidate**, not an accepted model or completed animation.
It is not connected to Start. The earlier 80px rig measurements are not the authoring
standard and do not override the approved image. Full-body anatomy, limb thickness,
face, costume and silhouette must be checked together at the reference's resolution.

## Findings from the existing GIF

The torso changes between front/back views without a convincing turn. Arms look
attached rather than driven by shoulders and torso. Leg motion does not establish
believable foot contact or weight transfer. Those are visual failures even when
bone-length tests pass. The low-resolution cutout rig also loses the reference's
detail and reads as a different rendition of the character.

## Resolution and acceptance rule

Use **1236 ×1273** as the standalone model-review and action-frame canvas, matching
the approved appearance image. Keep the body's scale and anatomy consistent on that
canvas; do not resize individual poses to fill their bounds. Game/display scaling
is deferred until the model and complete motion proofs are accepted.

Review the complete static model first. Action proofs must then show full connected
movement at normal speed and slow motion, with coherent shoulders, elbows, hips,
knees, foot contact and weight transfer. They must retain the approved model's
proportions and native detail. A static candidate does not establish motion quality.
No new runtime code or runtime assets were changed in this review.

## Smoothness and continuity gate

No replacement animation has passed this gate yet. Review the complete three-hit
combo and running thrust, including anticipation, contact, follow-through and
recovery to idle. Watch at authored speed, quarter speed and frame by frame in
both directions. The head and body must retain their proportions; shoulders,
elbows, wrists, hips and knees must follow continuous paths. Check planted feet,
push-off, weight transfer, weapon grip and depth order. Reject visible pops,
unintended sliding, detached joints, sudden view swaps or missing recovery poses.

Keep every action frame on the same 1236 × 1273 canvas. Establish one body scale
and floor anchor for the complete action set, leaving space for the sword and
full limb arcs. Never fit each pose independently to its bounds. Motion proofs
must show timing faithfully; a slow preview supplements normal-speed playback.

After visual acceptance, verify tap/hold/buffered input, repeated combos, running
thrusts, direction changes and interruptions in moving gameplay. A smooth isolated
loop does not establish that transitions work. Technical checks supplement visual
review; they cannot certify that the character looks natural.

All 87 frames of the rejected combo were also inspected on contact sheets:
[1–24](combo-all-frames-1.png), [25–48](combo-all-frames-2.png),
[49–72](combo-all-frames-3.png), [73–87](combo-all-frames-4.png).
These sheets document the rejected motion; they are not replacement action art.
