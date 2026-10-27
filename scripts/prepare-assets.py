"""Pack selected, unmodified DFO sprite layers. Requires Pillow.
Usage: python3 scripts/prepare-assets.py /path/to/DFQ-Original-master [--gunner /path/to/gunner-frames]
Lua resources are parsed as data; no source scripts are executed.
"""
import argparse,json,re,shutil
from pathlib import Path
from PIL import Image,ImageDraw
parser=argparse.ArgumentParser();parser.add_argument('source',type=Path);parser.add_argument('--gunner',type=Path);parser.add_argument('--gunner-sheet',type=Path);parser.add_argument('--scenery-file',type=Path,required=True);args=parser.parse_args()
root=args.source;out=Path('public/assets');out.mkdir(parents=True,exist_ok=True)
frames={};animations={};images=[]
def read(path):return path.read_text() if path.exists() else ''
def origin(path,image):
 s=read(path);x=re.search(r'ox\s*=\s*(-?\d+)',s);y=re.search(r'oy\s*=\s*(-?\d+)',s)
 return (int(x.group(1)) if x else image.width//2,int(y.group(1)) if y else image.height)
def add(name,im,ox,oy):
 images.append((name,im,ox,oy))
def composite(character,idx,layers):
 im=Image.new('RGBA',(640,480));anchor=(320,320)
 for layer in layers:
  path=root/f'asset/image/actor/duelist/{character}/{layer}/{idx}.png'
  if not path.exists():continue
  src=Image.open(path).convert('RGBA');ox,oy=origin(root/f'config/asset/sprite/actor/duelist/{character}/{layer}/{idx}.cfg',src)
  im.alpha_composite(src,(anchor[0]-ox,anchor[1]-oy))
 box=im.getbbox()
 if not box:raise ValueError(f'Empty sprite: {character}/{idx}')
 return im.crop(box),anchor[0]-box[0],anchor[1]-box[1]
sets={
 'slayer':('swordman',['skin/default','katana/default','shoes/renewal','pants/renewal','belt/renewal','coat/renewal','hair/renewal','cap/renewal','katana/default_b'],{'idle':'stay','walk':'move','attack':'attack1','attack2':'attack2','attack3':'attack3','upper':'attack3','special':'onigiri','guard':'guard','hurt':'damage1','dead':'down','jump':'sit'}),
 'goblin':('goblin',['skin/base','pants/base','weapon/base'],{'idle':'stay','walk':'move','attack':'attack1','hurt':'damage1','dead':'down','jump':'sit'}),
 'tau':('tau',['skin/army','pants/base','armlet/base','weapon/base','hat/base'],{'idle':'stay','walk':'move','attack':'attack1','charge':'dash','hurt':'damage1','dead':'down','jump':'sit'})}
for name,(character,layers,states) in sets.items():
 for state,ani in states.items():
  ids=re.findall(r'sprite\s*=\s*"(\d+)"',read(root/f'config/asset/frameani/actor/duelist/{character}/{ani}.cfg'))
  animations[name+'-'+state]=[]
  for idx in ids:
   key=f'{name}-{idx}'
   if key not in frames:
    im,ox,oy=composite(character,idx,layers);add(key,im,ox,oy);frames[key]=True
   animations[name+'-'+state].append(key)
if args.gunner:
 # Gunner assets may be supplied as pre-aligned per-action PNG directories.
 for folder in sorted(args.gunner.iterdir()):
  if not folder.is_dir():continue
  animations['gunner-'+folder.name]=[]
  for p in sorted(folder.glob('*.png')):
   im=Image.open(p).convert('RGBA');key='gunner-'+folder.name+'-'+p.stem
   add(key,im,im.width//2,im.height);animations['gunner-'+folder.name].append(key)
if args.gunner_sheet:
 sheet=Image.open(args.gunner_sheet).convert('RGBA')
 gunner_animations={'idle':[0,1,2],'walk':list(range(3,11)),'attack':[12,13,14,15,16,17,18,19],'upper':[128,129,130,131,132,133],'kick':[134,135,136,137,138],'special':[165,166,167,168,169,170,171,172],'hurt':[96,97,98,99],'dead':[100,101,102,103],'jump':[201,202,203,204,205]}
 for action,ids in gunner_animations.items():
  animations['gunner-'+action]=[]
  for idx in ids:
   key='gunner-'+str(idx)
   if key not in frames:
    im=sheet.crop((idx%5*215,idx//5*215,idx%5*215+215,idx//5*215+215));box=im.getbbox()
    if not box:raise ValueError(f'Empty gunner frame {idx}')
    add(key,im.crop(box),84-box[0],195-box[1]);frames[key]=True
   animations['gunner-'+action].append(key)
width=2048;x=y=row=0;atlas=Image.new('RGBA',(width,2048));metadata={}
for name,im,ox,oy in images:
 if x+im.width+2>width:x=0;y+=row+2;row=0
 if y+im.height>2048:raise ValueError('Atlas overflow')
 atlas.alpha_composite(im,(x,y));metadata[name]={'x':x,'y':y,'w':im.width,'h':im.height,'ox':ox,'oy':oy};x+=im.width+2;row=max(row,im.height)
atlas=atlas.crop((0,0,width,y+row));atlas.save(out/'fighters.png',optimize=True)
shutil.copyfile(args.scenery_file,out/'forest-scene.jpg')
scenery=[{'file':'forest-scene.jpg','role':'scene'}]
(out/'manifest.json').write_text(json.dumps({'image':'fighters.png','frames':metadata,'animations':animations,'scenery':scenery},separators=(',',':')))
preview=Image.new('RGB',(900,400),'#28352e');draw=ImageDraw.Draw(preview)
for i,name in enumerate(sets):
 f=metadata[animations[name+'-idle'][0]];im=atlas.crop((f['x'],f['y'],f['x']+f['w'],f['y']+f['h']));im=im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST);preview.paste(im,(i*300+60,60),im);draw.text((i*300+60,20),name,fill='white')
preview.save('/tmp/dfa-assets/characters-preview.png')
print(f'Packed {len(metadata)} original frames; {len(scenery)} original scenery layers. Gunner included: {bool(args.gunner or args.gunner_sheet)}')
