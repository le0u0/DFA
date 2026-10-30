"""Package one fixed Slayer mannequin, never resize a body per animation frame."""
from pathlib import Path
import hashlib,json
from PIL import Image,ImageDraw
from sprite_cells import isolate_cell
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'docs/art/slayer/model/source/parts.png'
OUT=ROOT/'assets/characters/slayer/model';OUT.mkdir(parents=True,exist_ok=True)
# Dimensions are canonical runtime pixels, not individual pose bounding boxes.
parts=[('head_right',32,30),('head_left',32,30),('head_back',32,30),('torso_front',40,22),('torso_back',40,22),('hips',32,12),('thigh',14,17),('shin',11,13),('boot_right',16,7),('boot_left',16,7),('upper_arm',8,15),('forearm',7,13),('fist',7,7),('cursed_upper',10,16),('cursed_forearm',9,14),('claw',9,10),('hips_back',32,12),('torso_side',36,22)]
sheet=Image.open(SOURCE).convert('RGBA');atlas=Image.new('RGBA',(768,384));entries={}
ycuts=[0,390,680,1024]
for index,(name,w,h) in enumerate(parts):
 row,col=divmod(index,6)
 cell=sheet.crop((col*256,ycuts[row],(col+1)*256,ycuts[row+1]))
 cell,_=isolate_cell(cell)
 cell.putalpha(cell.getchannel('A').point(lambda a:255 if a>180 else 0))
 box=cell.getbbox();assert box
 cell=cell.crop(box)
 if name=='cursed_forearm':
  # Exclude the hanging chain from the structural arm width. A small chain is
  # drawn separately, so decoration cannot make the forearm look thinner.
  cell=cell.crop((0,0,round(cell.width*.64),cell.height))
 # A part is calibrated once here; pose rendering uses these same dimensions.
 cell=cell.resize((w*3,h*3),Image.Resampling.NEAREST)
 x=col*128+(128-cell.width)//2;y=row*128+(128-cell.height)//2
 atlas.alpha_composite(cell,(x,y));entries[name]=dict(rect=[x,y,cell.width,cell.height],size=[w,h])
atlas.save(OUT/'parts.png')
model=dict(version=1,reference='docs/art/slayer/chibi-pixel-reference-v6.png',standing_height=80,head=[32,30],chin_to_hips=22,hips_to_soles=28,shoulder_span=24,chest_width=24,waist_width=18,hip_span=16,thigh_length=13,shin_length=9,thigh_width=14,shin_width=11,boot=[16,7],normal_arm=[11,9],cursed_arm=[12,10],normal_arm_width=[8,7],cursed_arm_width=[10,9],parts=entries,source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),rule='Bone lengths, body-part dimensions and head size are constant. Pose changes use rotations and joint locations; no per-pose scaling or stretching.')
(OUT/'model.json').write_text(json.dumps(model,indent=2)+'\n')
(ROOT/'docs/art/slayer/model/proportions.json').write_text(json.dumps(model,indent=2)+'\n')
# Technical dimension diagram, not another independently generated body.
im=Image.new('RGB',(760,600),'#20352e');d=ImageDraw.Draw(im);scale=6;cx=210;top=55
point=lambda x,y:(cx+x*scale,top+y*scale)
d.rounded_rectangle((*point(-16,0),*point(16,30)),radius=35,fill='#e8cf91',outline='white',width=2)
d.polygon([point(-12,34),point(12,34),point(9,48),point(-9,48)],fill='#345eaa',outline='white')
d.rectangle((*point(-12,47),*point(12,54)),fill='#254478',outline='white')
for sign in [-1,1]:
 d.line([point(sign*6,52),point(sign*9,65)],fill='#4166b6',width=14*scale)
 d.line([point(sign*9,65),point(sign*10,74)],fill='#7d93b7',width=11*scale)
 d.rounded_rectangle((*point(sign*10-8,74),*point(sign*10+8,80)),radius=8,fill='#4166b6',outline='white')
 d.line([point(sign*12,35),point(sign*16,45),point(sign*17,54)],fill='#c94979' if sign<0 else '#deb18c',width=(9 if sign<0 else 7)*scale)
for y,text in [(0,'Crown 0'),(30,'Chin 30  |  head: 30px / 37.5%'),(52,'Hips 52  |  torso + pelvis: 22px / 27.5%'),(80,'Soles 80  |  legs + boots: 28px / 35%')]:
 d.line((90,top+y*scale,720,top+y*scale),fill='#81a58e',width=1);d.text((335,top+y*scale+3),text,fill='white')
d.text((40,15),'SLAYER: ONE FIXED 80px MODEL',fill='white')
d.text((335,325),'Thigh: 13px long / 14px wide',fill='white');d.text((335,350),'Shin: 9px long / 11px wide',fill='white');d.text((335,375),'Boot: 16px wide / 7px high',fill='white');d.text((335,415),'Same dimensions in every action.',fill='white');d.text((335,440),'Bend joints; do not lengthen legs.',fill='white')
im.save(ROOT/'docs/art/slayer/model/proportion-guide.png')
print('Packaged18 fixed-size parts;80px model; invariant limb lengths/widths.')
