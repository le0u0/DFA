"""Compare captured Start-renderer frames against decoded original ANI replay.

The original panel is a data replay, not a recording of the original client.
Both panels share elapsed time; the source final pose is held after ANI end.
"""
import argparse,json
from pathlib import Path
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]

def build(captures,original,output,version):
 output.mkdir(parents=True,exist_ok=True)
 source=json.loads((ROOT/'docs/art/roster/dfo-actions/slayer.json').read_text())['clips']
 source['dashattack']=json.loads((ROOT/'docs/art/slayer/motion-review/dashattack-source.json').read_text())
 traces=json.loads((captures/'trace.json').read_text())
 trace={(v['action'],v['facing'],round(v['time']*1000)):v for v in traces}
 records={}
 for facing in ['right','left']:
  for action in ['run','attack1','attack2','attack3','dashattack']:
   clip=source[action];frames=[]
   for index in range(0,45,2):
    time=index*25
    local=time%clip['total_raw_delay_ms'] if action=='run' else min(time,clip['total_raw_delay_ms']-1)
    frame=clip['frames'][-1];edge=0
    for candidate in clip['frames']:
     edge+=candidate['delay_ms']
     if local<edge:frame=candidate;break
    current=Image.open(captures/f'{action}-{facing}/{index:03}.png').convert('RGB')
    panel=Image.new('RGBA',(310,225),'#293e35')
    image=Image.open(original/f"{frame['image_index']:03}.png").convert('RGBA')
    # One scale for all source poses; no per-frame centering or resizing.
    image=image.resize((350,350),Image.Resampling.NEAREST)
    panel.alpha_composite(image,(155+round(frame['image_pos'][0]*.7),195+round(frame['image_pos'][1]*.7)))
    # The source remains in its supplied right-facing orientation in both
    # comparisons; labels explicitly identify it. Never invent source anatomy.
    canvas=Image.new('RGB',(620,288),'#15201d');draw=ImageDraw.Draw(canvas)
    draw.text((8,8),f'DFA {version} - {action} {facing}',fill='white')
    draw.text((318,8),'Original ANI replay (right-facing)',fill='white')
    canvas.paste(current,(0,30));canvas.paste(panel.convert('RGB'),(310,30))
    state=trace[(action,facing,time)]
    draw.text((8,260),f"{time}ms  {state['clip']} record {state['frame']}",fill='white')
    suffix=' (end held)' if time>=clip['total_raw_delay_ms'] and action!='run' else ''
    draw.text((318,260),f"{time}ms  IMG {frame['image_index']}{suffix}",fill='white')
    frames.append(canvas)
   name=f'{action}-{facing}-{version}.gif'
   palette=frames[0].quantize(colors=256)
   quantized=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
   quantized[0].save(output/name,save_all=True,append_images=quantized[1:],duration=50,loop=0,optimize=False,disposal=2)
   records[name]=dict(sample_ms=50,source=clip['source'],source_duration_ms=clip['total_raw_delay_ms'],game_duration_ms=clip['total_raw_delay_ms'] if action=='run' else round(trace[(action,facing,0)]['duration']*1000),source_scale=.7,source_facing='right',note='DFA uses actual Start renderer with world translation fixed; original uses decoded images and raw ANI timing, final pose held. Original client not recorded.')
 (output/f'{version}-comparison.json').write_text(json.dumps(records,indent=2)+'\n')
 print(f'Wrote {len(records)} animated comparisons for {version}')

if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--captures',type=Path,required=True);p.add_argument('--original',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);p.add_argument('--version',required=True)
 a=p.parse_args();build(a.captures,a.original,a.output,a.version)
