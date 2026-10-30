"""Encode full-resolution renderer captures at faithful normal/quarter speed."""
from pathlib import Path
import argparse,json
from PIL import Image,ImageDraw
import numpy as np
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--captures',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
report={}
for directory in sorted(a.captures.iterdir()):
 if not directory.is_dir():continue
 paths=sorted(directory.glob('*.png'))
 if not paths:continue
 montage=Image.new('RGB',(64*len(paths),66))
 for i,path in enumerate(paths):
  with Image.open(path) as im:montage.paste(im.convert('RGB').resize((64,66)),(i*64,0))
 # Reserve actual green accent colors: a thumbnail-only adaptive palette can
 # otherwise turn small green boot/cuff details brown during GIF quantization.
 atlas=np.asarray(Image.open(Path(__file__).resolve().parents[1]/'assets/characters/slayer/model/parts.png').convert('RGBA'))
 rgb=atlas[:,:,:3].astype(np.float32)
 green=(atlas[:,:,3]>128)&(rgb[:,:,1]>rgb[:,:,0]*1.3)&(rgb[:,:,1]>rgb[:,:,2]*1.3)&(rgb[:,:,1]>80)
 samples=np.asarray(atlas[:,:,:3][green])
 accent=Image.fromarray(samples.reshape((1,len(samples),3))).quantize(colors=16)
 palette=Image.new('P',(1,1))
 palette.putpalette(montage.quantize(colors=240).getpalette()[:720]+accent.getpalette()[:48])
 frames=[]
 for path in paths:
  with Image.open(path) as im:
   rgb=im.convert('RGB');bg=rgb.getpixel((0,0))
   for edge_x in (0,im.width-1):
    assert all(rgb.getpixel((edge_x,y))==bg for y in list(range(0,1107))+list(range(1113,im.height))), ('Clipped proof',path)
   assert im.size==(1236,1273), (path,im.size)
   frames.append(im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE))
 durations=[30 if i%3<2 else 40 for i in range(len(frames))]
 name=directory.name+'.gif'
 frames[0].save(a.output/name,save_all=True,append_images=frames[1:],duration=durations,loop=0,disposal=1,optimize=False)
 # Quarter-speed copies are only needed for the right side; left is still
 # rendered/reviewed in full to catch asymmetric attachment mistakes.
 if directory.name.endswith('right'):
  frames[0].save(a.output/(directory.name+'-slow.gif'),save_all=True,append_images=frames[1:],duration=[v*4 for v in durations],loop=0,disposal=1,optimize=False)
 # Every frame, numbered in timeline order, for frame-by-frame visual review.
 for page in range((len(paths)+19)//20):
  board=Image.new('RGB',(1236,5*310),'#17231f');d=ImageDraw.Draw(board)
  for n,path in enumerate(paths[page*20:(page+1)*20]):
   with Image.open(path) as im:thumb=im.convert('RGB').resize((309,285),Image.Resampling.LANCZOS)
   x=(n%4)*309;y=(n//4)*310
   board.paste(thumb,(x,y+25));d.text((x+8,y+7),f'{page*20+n:03d}  {(page*20+n)/30:.3f}s',fill='white')
  board.save(a.captures/(directory.name+f'-frames-{page+1}.png'))
 report[name]={'resolution':[1236,1273],'samples':len(paths),'duration_ms':sum(durations),'renderer':'game/slayer_model.gd','clock':'30 Hz capture of continuous seconds-based motion','fixed_model_scale':9.5,'source':'Native-detail texture atlas; not enlarged gameplay screenshots'}
(a.output/'proof.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
