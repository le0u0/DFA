"""Slice and register the high-resolution part sheet; no per-pose body resizing."""
from pathlib import Path
import json, hashlib, shutil
from PIL import Image, ImageDraw, ImageChops
from sprite_cells import isolate_cell
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'docs/art/slayer/model/source/detail-parts.png'
OUT=ROOT/'assets/characters/slayer/model'
sheet=Image.open(SOURCE).convert('RGBA')
joint_source=ROOT/'docs/art/slayer/model/source/joint-parts.png'
joint_sheet=Image.open(joint_source).convert('RGBA')
def cell(col,row,source=sheet,rows=4):
 w,h=source.size
 im=source.crop((round(col*w/4),round(row*h/rows),round((col+1)*w/4),round((row+1)*h/rows)))
 im,_=isolate_cell(im)
 box=im.getchannel('A').point(lambda a:255 if a>128 else 0).getbbox()
 return im.crop(box)
# Preserve native texture samples in the atlas. Logical dimensions are calibrated
# once per anatomical part, shared by all poses and all review/game resolutions.
spec=[('head_right',0,0,32,30),('head_left',1,0,32,30),('torso_front',2,0,40,22),('hips',3,0,32,12),('thigh',1,1,16,20),('shin',1,1,13,8),('boot_right',2,1,18,12),('boot_left',3,1,18,12),('upper_arm',0,2,10,17),('forearm',1,2,8.5,13.5),('fist',2,2,7,7),('cursed_upper',3,2,10,16),('cursed_forearm',0,3,9,14),('claw',1,3,9,10),('sword_steel',2,3,8,64),('sword_cyan',3,3,8,64)]
atlas=Image.new('RGBA',(2560,2560));entries={}
for i,(name,c,r,w,h) in enumerate(spec):
 joint_cells={'upper_arm':(0,0),'forearm':(1,0),'cursed_upper':(2,0),'cursed_forearm':(3,0),'thigh':(0,1),'shin':(1,1),'boot_right':(2,1),'boot_left':(3,1)}
 if name in joint_cells:
  jc,jr=joint_cells[name];im=cell(jc,jr,joint_sheet,2)
 else:
  im=cell(c,r)
 # The normal-hand source has a short wrist extension. Keep the fist/grip only.
 if name=='fist': im=im.crop((0,round(im.height*.36),im.width,im.height))
 x=(i%4)*640+(640-im.width)//2;y=(i//4)*640+(640-im.height)//2
 assert im.width <= 640 and im.height <= 640, (name, im.size)
 atlas.alpha_composite(im,(x,y))
 entries[name]={'rect':[x,y,im.width,im.height],'size':[w,h]}
# Register the original approved arm pixels against anatomical joint anchors.
# This is asset extraction, with no repainting or texture resampling: the same
# muscle/wrist-band shapes survive instead of generated stacked muscle pieces.
reference=Image.open(ROOT/'docs/art/slayer/model-review/model-candidate-1236x1273.png').convert('RGBA')
segments={
 'upper_arm':([(377,575),(410,586),(421,630),(412,683),(384,724),(343,714),(316,688),(326,652),(350,629),(361,599)],(394,608),(350,696),11),
 'forearm':([(315,684),(376,705),(385,730),(344,787),(323,814),(273,802),(244,775),(268,726),(286,696)],(350,696),(295,791),9),
 'cursed_upper':([(701,558),(751,558),(780,583),(805,634),(804,672),(768,675),(731,647),(703,603),(689,560)],(723,573),(785,664),12),
 'cursed_forearm':([(775,648),(824,661),(866,704),(884,747),(914,793),(907,825),(861,851),(819,821),(803,780),(778,743),(754,705)],(785,664),(870,827),10)}
for name,(polygon,root,tip,length) in segments.items():
 mask=Image.new('L',reference.size);ImageDraw.Draw(mask).polygon(polygon,fill=255)
 region=reference.copy();region.putalpha(ImageChops.multiply(reference.getchannel('A'),mask))
 box=mask.getbbox();region=region.crop(box)
 calibration=length/((tip[0]-root[0])**2+(tip[1]-root[1])**2)**.5
 i=next(i for i,v in enumerate(spec) if v[0]==name)
 x=(i%4)*640+(640-region.width)//2;y=(i//4)*640+(640-region.height)//2
 atlas.paste((0,0,0,0),((i%4)*640,(i//4)*640,(i%4+1)*640,(i//4+1)*640))
 atlas.alpha_composite(region,(x,y))
 entries[name]={'rect':[x,y,region.width,region.height],'size':[region.width*calibration,region.height*calibration],
 'root':[(root[0]-box[0])*calibration,(root[1]-box[1])*calibration],
 'tip':[(tip[0]-box[0])*calibration,(tip[1]-box[1])*calibration]}
anchors={
 'thigh':[[.5,.08],[.5,.88]], 'shin':[[.5,.1],[.5,.9]],
 'upper_arm':[[.5,.10],[.5,.90]], 'forearm':[[.5,.08],[.5,.91]],
 'cursed_upper':[[.5,.12],[.5,.88]], 'cursed_forearm':[[.5,.10],[.5,.86]]}
for name,(a,b) in anchors.items():
 if name in segments: continue
 w,h=entries[name]['size']
 entries[name]['root']=[a[0]*w,a[1]*h]
 entries[name]['tip']=[b[0]*w,b[1]*h]
atlas.save(OUT/'parts.png')
m=json.loads((OUT/'model.json').read_text());m.update(version=2,thigh_length=16,shin_length=6,thigh_width=16,shin_width=13,boot=[18,12],parts=entries,source_sha256=hashlib.sha256(SOURCE.read_bytes()+joint_source.read_bytes()+(ROOT/'docs/art/slayer/model-review/model-candidate-1236x1273.png').read_bytes()).hexdigest(),texture_policy='Native part pixels retained; logical anatomy calibrated once, never per pose.',motion='motion.json')
(OUT/'model.json').write_text(json.dumps(m,indent=2)+'\n')
print(f'Packaged {len(entries)} native-detail parts into {atlas.size} atlas')
