import random, json, sys
random.seed(int(sys.argv[2])); N=int(sys.argv[1])
keys=["name","description","argument-hint","disable-model-invocation","allowed-tools","model","x"]
atoms=['true','false','yes','no','on','off','1','0','1.0','1e0','~','null','archive-lines','Bash(${CLAUDE_PLUGIN_ROOT}/s.sh save)','a b','a: b','a:b','a #c','a#c','"q"',"'q'",'"open',"'open",'"a\\"b"',"'it''s'",'[x]','{x}','&a x','*a','!t x','|','>','- x','?x','x:','%x','@x','`x`','自動儲存「⋮」→','a\u0085b','a b','x,y',']x','}x','#x','"[a|b]"','"a # b"',"'a: b'",'-x','--- x','x ---','"','\'','...','x ...','... x','a...b','-- x']
def val(): return random.choice(atoms)
def line():
    r=random.random()
    if r<0.45: return f"{random.choice(keys)}: {val()}"
    if r<0.6: return f"{random.choice(keys)}:"
    if r<0.85: return " "*random.choice([1,2,2,2,4])+"- "+val()
    if r<0.9: return "# "+val()
    if r<0.95: return ""
    return val()
for _ in range(N):
    lines=[line() for _ in range(random.randint(1,7))]
    sep="\r\n" if random.random()<0.3 else "\n"
    print(json.dumps(sep.join(lines)+sep))
