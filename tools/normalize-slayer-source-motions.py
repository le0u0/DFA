"""Package generated source-guided Slayer poses. Requires Pillow, numpy, scipy.

These are authoring dependencies only; Docker/game startup uses the committed atlas.
"""
from pathlib import Path
import hashlib,json,math
from PIL import Image,ImageDraw
import numpy as np
from scipy.ndimage import label,find_objects,binary_dilation

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'docs/art/slayer/source-motions/source'
OUT=ROOT/'assets/characters/slayer/animation-proof'
REFERENCE=json.loads((ROOT/'docs/art/roster/dfo-actions/slayer.json').read_text())
REFERENCE['clips']['dashattack']=json.loads((ROOT/'docs/art/slayer/motion-review/dashattack-source.json').read_text())
# Start from the preserved original proof, not the last generated output.
import runpy
runpy.run_path(str(ROOT/'tools/normalize-slayer-animation-proof.py'))
old=Image.open(OUT/'body-atlas.png').convert('RGBA')
data=json.loads((OUT/'animations.json').read_text())
atlas=Image.new('RGBA',(1024,2048));atlas.alpha_composite(old)
registration=[]

def figures(name):
 im=Image.open(SOURCE/name).convert('RGBA');a=np.array(im)
 labels,_=label(a[:,:,3]>128,np.ones((3,3)))
 counts=np.bincount(labels.ravel());result=[]
 for i,box in enumerate(find_objects(labels),1):
  if box is None or counts[i]<1000:continue
  ys,xs=box
  # Isolate each figure before cropping, including antialiased borders. Some
  # generated bounding boxes overlap; rectangular cuts would retain fragments.
  mask=binary_dilation(labels==i,iterations=1)
  arr=a.copy();arr[:,:,3]=np.where(mask,arr[:,:,3],0)
  bounds=(xs.start,ys.start,xs.stop,ys.stop)
  result.append((bounds,Image.fromarray(arr).crop(bounds)))
 return result

def install(action,facing,row,items,scale,hands,angles):
 assert len(items)==len(hands)==len(angles)
 baseline=max(b[3] for b,_ in items)
 normalized=[]
 for column,((box,image),hand) in enumerate(zip(items,hands)):
  w,h=round(image.width*scale),round(image.height*scale)
  foot_center=image.width/2
  if action!='run':
   band=image.getchannel('A').crop((0,round(image.height*.85),image.width,image.height)).getbbox()
   if band:foot_center=(band[0]+band[2])/2
  x=64-round(foot_center*scale);y=112+round((box[1]-baseline)*scale)
  assert 0<=x and 0<=y and x+w<=128 and y+h<=128,(action,box,x,y,w,h)
  atlas.alpha_composite(image.resize((w,h),Image.Resampling.NEAREST),(column*128+x,row*128+y))
  point=[round(x+(hand[0]-box[0])*scale),round(y+(hand[1]-box[1])*scale)]
  nearby=[]
  for dy in range(-7,8):
   for dx in range(-7,8):
    px,py=point[0]+dx,point[1]+dy
    if not (0<=px<128 and 0<=py<128):continue
    r,g,b,a=atlas.getpixel((column*128+px,row*128+py))
    if a>200 and r>130 and 50<g<210 and b<160 and r>g*1.12 and g>b*1.12:
     nearby.append((dx*dx+dy*dy,[px,py]))
  if nearby:point=min(nearby,key=lambda v:v[0])[1]
  if atlas.getpixel((column*128+point[0],row*128+point[1]))[3]<128:
   opaque=[]
   for dy in range(-6,7):
    for dx in range(-6,7):
     px,py=point[0]+dx,point[1]+dy
     if 0<=px<128 and 0<=py<128 and atlas.getpixel((column*128+px,row*128+py))[3]>200:
      opaque.append((dx*dx+dy*dy,[px,py]))
   assert opaque,(action,facing,column,'grip outside body')
   point=min(opaque,key=lambda v:v[0])[1]
  normalized.append(point)
  registration.append(dict(action=action,facing=facing,column=column,box=box,scale=scale,position=[x,y],size=[w,h]))
 source=REFERENCE['clips'][action];indices=[f['image_index'] for f in source['frames']]
 unique=list(dict.fromkeys(indices));assert len(unique)==len(items)
 cells=[unique.index(i) for i in indices]
 impact=source['attack_box_frames'][0] if source['attack_box_frames'] else -1
 data['clips'][f'{action}_{facing}']=dict(row=row,cells=cells,durations=[f['delay_ms']/1000 for f in source['frames']],loop=action=='run',impact_frame=impact,hands=[normalized[c] for c in cells],sword_angles=[angles[c] for c in cells],source=source['source'],source_image_indices=indices)

run=figures('run.png')
for facing,row,lo,hi in [('left',6,0,375),('right',7,375,724)]:
 items=sorted([v for v in run if lo<=v[0][1]<hi],key=lambda v:v[0][0]);assert len(items)==8
 # Fists stay forward in this run design. Source hand positions are authored.
 hands=([(70,225),(335,225),(605,222),(889,225),(1182,225),(1435,225),(1740,225),(1985,225)] if facing=='left' else [(205,545),(470,545),(750,545),(1045,545),(1295,545),(1560,545),(1840,545),(2120,545)])
 install('run',facing,row,items,.26,hands,[-2.35 if facing=='left' else 2.35]*8)
for name,action,facing,row,scale,hands,angles in [
 ('uppercut-left.png','attack3','left',10,.16,[(140,625),(422,450),(674,355),(1024,185),(1290,105),(1680,168),(1955,119)],[-2.4,-1.6,-.6,0,0,0,0]),
 ('uppercut-right.png','attack3','right',13,.16,[(245,648),(640,440),(950,296),(1235,188),(1505,110),(1795,150),(2110,170)],[2.4,1.6,.6,0,0,0,0]),
]:
 items=sorted(figures(name),key=lambda v:v[0][0]);assert len(items)==7
 install(action,facing,row,items,scale,hands,angles)

for name,action,right_row,left_row,scale in [('slash-reviewed.png','attack1',11,8,.24),('reverse-reviewed.png','attack2',12,9,.26)]:
 poses=figures(name)
 for facing,row,lo,hi in [('right',right_row,0,360),('left',left_row,360,724)]:
  items=sorted([v for v in poses if lo<=v[0][1]<hi],key=lambda v:v[0][0]);assert len(items)==7
  # Reject image-edge fragments rather than ship clipped final recovery hands.
  if (action=='attack1' and facing=='right') or (action=='attack2' and facing=='left'):items[6]=items[5]
  hands=[]
  for col,(b,im) in enumerate(items):
   width,height=im.size
   if action=='attack1':
    hx=(60 if facing=='right' else width-55) if col<3 else ((width-20 if facing=='right' else 20) if col==3 else (25 if facing=='right' else width-20))
    hy=55 if col<3 else height-55 if col==3 else height*.62
   else:
    hx=(width*.52 if facing=='right' else width*.45) if col==0 else (width-18 if facing=='right' else 18) if col==1 else (25 if facing=='right' else width-25)
    hy=height*.60 if col==0 else height*.37
   hands.append((b[0]+hx,b[1]+hy))
  angles=([math.pi,-2.4,-2.2,math.pi/2,-math.pi/2,-math.pi/2,-math.pi/2] if action=='attack1' else [-math.pi/2,math.pi/2,-math.pi/2,-math.pi/2,-math.pi/2,-math.pi/2,-math.pi/2])
  if facing=='left':angles=[-a for a in angles]
  install(action,facing,row,items,scale,hands,angles)

thrust=figures('dashattack.png')
for facing,row,lo,hi in [('right',14,0,375),('left',15,375,727)]:
 items=sorted([v for v in thrust if lo<=v[0][1]<hi],key=lambda v:v[0][0]);assert len(items)==7
 # The final right-facing fist touches the source image edge: reject that
 # cell and hold the preceding extended thrust instead of shipping clipping.
 if facing=='right':items[6]=items[5]
 hands=([(90,150),(400,158),(700,183),(1200,190),(1540,192),(1860,194),(1860,194)] if facing=='right' else [(195,480),(510,485),(780,520),(920,530),(1250,535),(1585,535),(1920,535)])
 sign=1 if facing=='right' else -1
 install('dashattack',facing,row,items,.26,hands,[sign*a for a in [2.1,2.0,1.8,1.5,1.5,1.5,1.5]])

data.update(version=3,columns=8,rows=16,source_motion_registration=registration)
data['limitations']=['Source-guided chibi poses are an authored approximation, not pixel-for-pixel original choreography.','Slayer basic and running attacks use raw ANI duration and first attack-box timing; this slows the prototype attack cadence.','Idle/walk and air/heavy attacks retain the previous draft art; the final right thrust, right first-slash and left reverse-slash poses hold the preceding pose because their generated source cells touched an image edge.','Generated grip locations and per-pose arm occlusion require further art review.']
(OUT/'animations.json').write_text(json.dumps(data,indent=2)+'\n');atlas.save(OUT/'body-atlas.png')
manifest=dict(sources={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.glob('*.png')},reference='docs/art/roster/dfo-actions/slayer.json',registration=registration,limitations=data['limitations'])
(ROOT/'docs/art/slayer/source-motions/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
preview=Image.new('RGB',(8*128,10*148),'#293e35');draw=ImageDraw.Draw(preview)
for row,(action,facing) in enumerate((a,f) for f in ['left','right'] for a in ['run','attack1','attack2','attack3','dashattack']):
 clip=data['clips'][action+'_'+facing]
 for col in range(8 if action=='run' else 7):
  cell=atlas.crop((col*128,clip['row']*128,(col+1)*128,(clip['row']+1)*128))
  preview.paste(cell,(col*128,row*148),cell)
  timeline=clip['cells'].index(col);h=clip['hands'][timeline]
  draw.ellipse((col*128+h[0]-2,row*148+h[1]-2,col*128+h[0]+2,row*148+h[1]+2),fill='yellow')
  draw.text((col*128+3,row*148+128),f'{action} {facing} {col}',fill='white')
preview.save(ROOT/'docs/art/slayer/source-motions/grip-review.png')
print('Packaged 72 added facing cells, 10 source-guided clips, including running thrust.')
