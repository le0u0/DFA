"""Package generated source-guided Slayer poses. Requires Pillow, numpy, scipy.

These are authoring dependencies only; Docker/game startup uses the committed atlas.
"""
from pathlib import Path
import hashlib,json
from PIL import Image,ImageDraw
import numpy as np
from scipy.ndimage import label,find_objects,binary_dilation

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'docs/art/slayer/source-motions/source'
OUT=ROOT/'assets/characters/slayer/animation-proof'
REFERENCE=json.loads((ROOT/'docs/art/roster/dfo-actions/slayer.json').read_text())
# Start from the preserved original proof, not the last generated output.
import runpy
runpy.run_path(str(ROOT/'tools/normalize-slayer-animation-proof.py'))
old=Image.open(OUT/'body-atlas.png').convert('RGBA')
data=json.loads((OUT/'animations.json').read_text())
atlas=Image.new('RGBA',(1024,1792));atlas.alpha_composite(old)
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
  x=64-w//2;y=112+round((box[1]-baseline)*scale)
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
attacks=figures('attacks-corrected.png')
configs=[('attack1','left',8,0,230,[(74,95),(270,107),(436,68),(620,111),(837,124),(1020,108),(1220,101)],[-2.35,-2.1,-.5,-1.5,-2.4,-2.4,-2.4]),('attack2','left',9,230,430,[(51,321),(236,324),(451,321),(618,290),(812,310),(1014,330),(1210,335)],[-2.4,-2.1,-.6,-1.5,-1.5,-1.5,-1.5]),('attack1','right',11,635,830,[(141,707),(338,708),(508,670),(737,711),(898,677),(1090,717),(1304,705)],[2.35,2.1,.5,1.5,2.4,2.4,2.4])]
for action,facing,row,lo,hi,hands,angles in configs:
 items=sorted([v for v in attacks if lo<=v[0][1]<hi],key=lambda v:v[0][0]);assert len(items)==7
 install(action,facing,row,items,.36,hands,angles)
for name,action,facing,row,scale,hands,angles in [
 ('uppercut-left.png','attack3','left',10,.16,[(140,625),(422,450),(674,355),(1024,185),(1290,105),(1680,168),(1955,119)],[-2.4,-1.6,-.6,0,0,0,0]),
 ('uppercut-right.png','attack3','right',13,.16,[(245,648),(640,440),(950,296),(1235,188),(1505,110),(1795,150),(2110,170)],[2.4,1.6,.6,0,0,0,0]),
 ('reverse-right.png','attack2','right',12,.17,[(337,555),(590,390),(850,380),(1185,380),(1490,380),(1830,380),(2110,380)],[2.4,2.1,.6,1.5,1.5,1.5,1.5])]:
 items=sorted(figures(name),key=lambda v:v[0][0]);assert len(items)==7
 install(action,facing,row,items,scale,hands,angles)

data.update(version=2,columns=8,rows=14,source_motion_registration=registration)
data['limitations']=['Source-guided chibi poses are an authored approximation, not pixel-for-pixel original choreography.','Raw basic attack delays are mapped around the existing gameplay strike time; combat tuning is unchanged.','Idle/walk and air/dash/heavy attacks retain the previous draft art.','Generated grip locations and per-pose arm occlusion require further art review.']
(OUT/'animations.json').write_text(json.dumps(data,indent=2)+'\n');atlas.save(OUT/'body-atlas.png')
manifest=dict(sources={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.glob('*.png')},reference='docs/art/roster/dfo-actions/slayer.json',registration=registration,limitations=data['limitations'])
(ROOT/'docs/art/slayer/source-motions/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
preview=Image.new('RGB',(8*128,8*148),'#293e35');draw=ImageDraw.Draw(preview)
for row,(action,facing) in enumerate((a,f) for f in ['left','right'] for a in ['run','attack1','attack2','attack3']):
 clip=data['clips'][action+'_'+facing]
 for col in range(8 if action=='run' else 7):
  cell=atlas.crop((col*128,clip['row']*128,(col+1)*128,(clip['row']+1)*128))
  preview.paste(cell,(col*128,row*148),cell)
  timeline=clip['cells'].index(col);h=clip['hands'][timeline]
  draw.ellipse((col*128+h[0]-2,row*148+h[1]-2,col*128+h[0]+2,row*148+h[1]+2),fill='yellow')
  draw.text((col*128+3,row*148+128),f'{action} {facing} {col}',fill='white')
preview.save(ROOT/'docs/art/slayer/source-motions/grip-review.png')
print('Packaged 58 new independently authored facing cells, 8 source-guided clips.')
