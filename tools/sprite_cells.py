"""Isolate generated grid cells without retaining neighboring-frame fragments."""
from collections import deque
from PIL import Image


def isolate_cell(cell):
    """Drop disconnected edge fragments; preserve the main figure and inner islands.

    Generated sheets can put the previous frame's feet at the next cell's top,
    or a neighboring ponytail at its side. Do not trim a fixed band: legitimate
    raised hands/hair can touch those same edges. The largest opaque-connected
    component is the character and is always retained, including edge pixels.
    """
    cell = cell.convert("RGBA")
    width, height = cell.size
    alpha = cell.getchannel("A")
    pixels = alpha.tobytes()
    visited = bytearray(len(pixels))
    components = []
    for start, value in enumerate(pixels):
        if value <= 128 or visited[start]:
            continue
        visited[start] = 1
        queue = deque([start])
        members = []
        touches_edge = False
        while queue:
            index = queue.popleft()
            members.append(index)
            x, y = index % width, index // width
            touches_edge |= x == 0 or y == 0 or x == width - 1 or y == height - 1
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = ny * width + nx
                    if pixels[neighbor] > 128 and not visited[neighbor]:
                        visited[neighbor] = 1
                        queue.append(neighbor)
        components.append((members, touches_edge))
    if not components:
        return cell, 0
    primary = max(range(len(components)), key=lambda i: len(components[i][0]))
    # Assign antialiased pixels to their nearest opaque region. This avoids
    # a faint bridge attaching a shoe fragment to the next frame's hair.
    owners = [-1] * len(pixels)
    queue = deque()
    for component_id, (members, _) in enumerate(components):
        for index in members:
            owners[index] = component_id
            queue.append(index)
    while queue:
        index = queue.popleft()
        x, y = index % width, index // width
        for ny in range(max(0, y - 1), min(height, y + 2)):
            for nx in range(max(0, x - 1), min(width, x + 2)):
                neighbor = ny * width + nx
                if pixels[neighbor] and owners[neighbor] < 0:
                    owners[neighbor] = owners[index]
                    queue.append(neighbor)
    rejected = {i for i, (_, edge) in enumerate(components) if edge and i != primary}
    kept_alpha = bytearray(0 if owner in rejected else value for owner, value in zip(owners, pixels))
    removed = sum(old > 0 and new == 0 for old, new in zip(pixels, kept_alpha))
    cleaned = cell.copy()
    cleaned.putalpha(Image.frombytes("L", cell.size, bytes(kept_alpha)))
    return cleaned, removed
