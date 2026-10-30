"""Render whole held-input combo and run/thrust transitions beside ANI replay."""
import argparse,json,math
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]


def source_frame(clip,seconds):
    local=max(0,seconds*1000)%clip['total_raw_delay_ms']
    for frame in clip['frames']:
        if local<frame['delay_ms']:return frame
        local-=frame['delay_ms']
    return clip['frames'][-1]


def build(captures,original,output,version):
    output.mkdir(parents=True,exist_ok=True)
    source=json.loads((ROOT/'docs/art/roster/dfo-actions/slayer.json').read_text())['clips']
    source['dashattack']=json.loads((ROOT/'docs/art/slayer/motion-review/dashattack-source.json').read_text())
    trace=json.loads((captures/'trace.json').read_text());report={}
    for facing in ['right','left']:
        for sequence in ['combo','run-thrust']:
            rows=[v for v in trace if v['sequence']==sequence and v['facing']==facing]
            first=next(v for v in rows if v['kind']==('basic' if sequence=='combo' else 'dash'))
            start=first['time']-first['attack_elapsed']
            run_start=next((v['time'] for v in rows if v['clip']=='run'),start)
            frames=[];sampled=[]
            for step in range(math.floor(rows[-1]['time']/.05)+1):
                time=step*.05;state=min(rows,key=lambda v:abs(v['time']-time));elapsed=time-start
                action='idle';local=time
                if sequence=='combo' and elapsed>=0:
                    for number in range(1,4):
                        candidate='attack'+str(number);duration=source[candidate]['total_raw_delay_ms']/1000
                        if elapsed<duration:
                            action=candidate;local=elapsed;break
                        elapsed-=duration
                    else:local=elapsed
                elif sequence=='run-thrust':
                    if elapsed>=0 and elapsed<source['dashattack']['total_raw_delay_ms']/1000:
                        action='dashattack';local=elapsed
                    elif elapsed<0 and time>=run_start:
                        action='run';local=time-run_start
                    elif state['clip']=='walk':
                        action='walk';local=time
                frame=source_frame(source[action],local)
                current=Image.open(captures/f'{sequence}-{facing}'/f"{state['index']:03}.png").convert('RGB')
                original_pose=Image.open(original/f"{frame['image_index']:03}.png").convert('RGBA').resize((350,350),Image.Resampling.NEAREST)
                panel=Image.new('RGBA',(310,225),'#293e35');panel.alpha_composite(original_pose,(155+round(frame['image_pos'][0]*.7),195+round(frame['image_pos'][1]*.7)))
                canvas=Image.new('RGB',(620,288),'#15201d');d=ImageDraw.Draw(canvas)
                d.text((8,8),f'DFA {version} - FULL {sequence} {facing}',fill='white')
                d.text((318,8),'Original ANI sequence replay (right)',fill='white')
                canvas.paste(current,(0,30));canvas.paste(panel.convert('RGB'),(310,30))
                d.text((8,260),f"{time:.2f}s  {state['clip']} / {state['frame']}",fill='white')
                d.text((318,260),f"{time:.2f}s  {action} / IMG {frame['image_index']}",fill='white')
                frames.append(canvas);sampled.append(state)
            palette=frames[0].quantize(colors=256)
            frames=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
            name=f'{sequence}-{facing}-{version}.gif'
            frames[0].save(output/name,save_all=True,append_images=frames[1:],duration=50,loop=0,disposal=2,optimize=False)
            seams=[]
            if sequence=='combo':
                for prior,next_clip in [('attack1','attack2'),('attack2','attack3')]:
                    next_i=next(i for i,v in enumerate(rows) if v['clip']==next_clip)
                    prior_i=max(i for i,v in enumerate(rows[:next_i]) if v['clip']==prior)
                    a,b=rows[prior_i],rows[next_i]
                    seams.append(dict(boundary=prior+' -> '+next_clip,hand_distance=math.dist(a['hand'],b['hand']),intervening_clips=[v['clip'] for v in rows[prior_i+1:next_i]],prior_hand=a['hand'],next_hand=b['hand']))
            report[name]=dict(input='Held X across all three stages' if sequence=='combo' else 'Idle, double-tap direction, X while running, idle',sample_ms=50,combo_started=start,seams=seams,source='Concatenated raw ANI clips; source engine transitions are not established. DFA uses actual held input; world translation fixed for pose review.')
    (output/f'{version}-transitions.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v['seams'] for k,v in report.items() if v['seams']},indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--captures',type=Path,required=True);p.add_argument('--original',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--version',required=True)
    a=p.parse_args();build(a.captures,a.original,a.output,a.version)
