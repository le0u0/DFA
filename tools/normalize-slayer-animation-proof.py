"""Slice the generated proof into registered cells; never rescale frames independently."""
from pathlib import Path
import hashlib,json
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'docs/art/slayer/animation-proof/source/body-sheet-corrected.png'
OUT=ROOT/'assets/characters/slayer/animation-proof'
OUT.mkdir(parents=True,exist_ok=True)
sheet=Image.open(SOURCE).convert('RGBA')
assert sheet.size==(1254,1254),sheet.size
# Imagegen's visible rows/columns are not exact multiples of its requested grid.
# These cuts lie in inspected transparent gutters, avoiding clipped feet/hands.
XS=[0,223,428,633,838,1043,1254]
YS=[0,223,427,630,826,1028,1254]
SCALE=0.4
atlas=Image.new('RGBA',(768,768))
registration=[]
for row in range(6):
 for col in range(6):
  # The generated right overhead anticipation swaps cursed anatomy. Reuse its
  # right guard as a held windup, instead of shipping the incorrect arm frame.
  source_col=0 if (row,col)==(5,1) else col
  box=(XS[source_col],YS[row],XS[source_col+1],YS[row+1])
  cell=sheet.crop(box)
  alpha=cell.getchannel('A').point(lambda v:255 if v>128 else 0)
  bounds=alpha.getbbox();assert bounds
  crop=cell.crop(bounds)
  # One scale across all frames; translation registers feet and horizontal center.
  width=round(crop.width*SCALE);height=round(crop.height*SCALE)
  crop=crop.resize((width,height),Image.Resampling.NEAREST)
  x=64-width//2;y=112-height
  assert x>=0 and y>=0 and x+width<128 and y+height<128
  atlas.alpha_composite(crop,(col*128+x,row*128+y))
  registration.append(dict(row=row,column=col,source_column=source_col,source_box=box,visible_bounds=bounds,position=[x,y],size=[width,height]))
atlas.save(OUT/'body-atlas.png')
# Hand positions are authored against the normalized cells and inspected in the lab.
# x/y are texture-cell coordinates. Right and left facings are authored separately.
hands=[
 [[48,91],[48,91],[48,91],[48,91],[48,91],[48,91]],
 [[44,87],[48,91],[48,91],[45,91],[46,90],[46,90]],
 [[43,91],[48,48],[33,77],[34,94],[43,90],[44,91]],
 [[84,91],[84,91],[84,91],[84,91],[84,91],[84,91]],
 [[84,91],[83,91],[85,91],[83,92],[84,82],[84,91]],
 [[84,91],[84,91],[95,79],[93,94],[84,91],[84,91]],
]
angles=[
 [-2.35]*6,[-2.35]*6,[-2.35,-0.25,-1.35,-2.2,-2.35,-2.35],
 [2.35]*6,[2.35]*6,[2.35,2.35,1.35,2.2,2.35,2.35],
]
clips={}
for facing,row_offset in [('left',0),('right',3)]:
 for action,row_index,durations in [('idle',0,[.18]*6),('walk',1,[.11]*6),('attack',2,[.10,.10,.13,.10,.10,.07])]:
  row=row_offset+row_index
  clips[f'{action}_{facing}']=dict(row=row,durations=durations,loop=action!='attack',impact_frame=2 if action=='attack' else -1,hands=hands[row],sword_angles=angles[row])
manifest=dict(version=1,cell_size=[128,128],origin=[64,112],columns=6,rows=6,clips=clips,source_scale=SCALE,registration=registration,limitations=['Right windup holds guard instead of using the generated anatomy-swapped overhead pose.','Draft pose timing and grip/occlusion need user review; not a complete gameplay animation set.'],source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest())
(OUT/'animations.json').write_text(json.dumps(manifest,indent=2)+'\n')
# Validate packaging and distinct walk motion; this does not replace visual QA.
for row in range(6):
 frames=[atlas.crop((c*128,row*128,(c+1)*128,(row+1)*128)) for c in range(6)]
 assert all(im.getchannel('A').getbbox() for im in frames)
 if row in (1,4):assert len({im.tobytes() for im in frames})>=5
print('Registered 36 cells, 6 clips; independent facings; one rejected source pose replaced by a guard hold.')
