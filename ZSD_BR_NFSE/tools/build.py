import spec,re
def q(s): return "'"+s.replace("'","''")+"'"
md=open(__import__('os').path.join(__import__('os').path.dirname(__file__),'..','ZSD_BR_NFSE_DDIC.md'),encoding='utf-8').read()
sec=md[md.index('## 6. Classe de mensagem'):md.index('## 7.')]
msgs=re.findall(r'^\| (0\d\d) \| (.+?) \|$',sec,re.M)
assert len(msgs)==46
L=[]
L.append("  gt_domain = VALUE #(")
for n,t,l,d,lc,txt,fv in spec.DOMAINS:
    L.append(f"    ( name = {q(n)} datatype = {q(t)} leng = {l} decimals = {d} lowercase = {q('X' if lc else ' ')} text = {q(txt)} )")
L.append("  ).")
L.append("  gt_fixval = VALUE #(")
for n,t,l,d,lc,txt,fv in spec.DOMAINS:
    for i,(v,tx) in enumerate(fv,1):
        L.append(f"    ( domname = {q(n)} valpos = '{i:04d}' value = {q(v)} text = {q(tx)} )")
L.append("  ).")
dom="\n".join(L)
L=["  gt_dtel = VALUE #("]
for n,ty,s,m,lo in spec.DTELS:
    if ty[0]=='D':
        L.append(f"    ( name = {q(n)} domname = {q(ty[1])} short = {q(s)} medium = {q(m)} long = {q(lo)} )")
    else:
        L.append(f"    ( name = {q(n)} datatype = {q(ty[1])} leng = {ty[2]} decimals = {ty[3]} short = {q(s)} medium = {q(m)} long = {q(lo)} )")
L.append("  ).")
dtel="\n".join(L)
L=["  gt_table = VALUE #("]
for n,txt,cf,ta,tk,log,f in spec.TABLES:
    L.append(f"    ( name = {q(n)} text = {q(txt)} contflag = {q(cf)} tabart = {q(ta)} tabkat = {q(tk)} logging = {q('X' if log else ' ')} )")
L.append("  ).")
L.append("  gt_field = VALUE #(")
for n,txt,cf,ta,tk,log,f in spec.TABLES:
    for fn,k,r in f:
        cur = r in spec.CURR_DTELS
        extra = f" reftable = {q('ZSD_BR_NFSE_DATA')} reffield = 'WAERS'" if cur else ""
        L.append(f"    ( tabname = {q(n)} fieldname = {q(fn)} key = {q('X' if k else ' ')} rollname = {q(r)}{extra} )")
L.append("  ).")
tab="\n".join(L)
L=["  gt_message = VALUE #("]
for no,tx in msgs:
    L.append(f"    ( msgnr = '{no}' text = {q(tx)} )")
L.append("  ).")
msg="\n".join(L)
tpl=open(__import__('os').path.join(__import__('os').path.dirname(__file__),'template.abap'),encoding='utf-8').read()
out=tpl.replace('@@DOMAINS@@',dom).replace('@@DTELS@@',dtel).replace('@@TABLES@@',tab).replace('@@MESSAGES@@',msg)
open(__import__('os').path.join(__import__('os').path.dirname(__file__),'..','ZSD_BR_NFSE_DDIC_GEN.txt'),'w',encoding='utf-8').write(out)
print('written', out.count('\n'),'lines;', len(msgs),'messages')
