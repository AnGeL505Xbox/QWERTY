"""Migración explícita JSON -> Resources. No se ejecuta al arrancar ni sobrescribe archivos."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
data = json.loads((ROOT / 'data/content.json').read_text())

def quoted(value):
    return json.dumps(value, ensure_ascii=False)

def save(path, text):
    destination = ROOT / path
    if destination.exists():
        raise SystemExit(f'No se sobrescribe {destination}; usa Git para revisar la migración.')
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(text, encoding='utf-8')

def header(script, ext='', subs='', steps=2):
    return f'[gd_resource type="Resource" load_steps={steps} format=3]\n[ext_resource type="Script" path="res://core/data/resources/{script}.gd" id="script"]\n{ext}\n{subs}\n[resource]\nscript = ExtResource("script")\n'

for id, status in data['statuses'].items():
    text = header('status_definition') + f'id = {quoted(id)}\ndisplay_name = {quoted(status["name"])}\n'
    text += ''.join(f'{key} = {status.get(key,0)}\n' for key in ['attack', 'defense'])
    save(f'data/statuses/{id}.tres', text)

for card in data['cards']:
    ext = '[ext_resource type="Script" path="res://core/data/resources/effect_definition.gd" id="effect"]\n'
    subs = ''
    refs = []
    for index, effect in enumerate(card['effects']):
        ref = f'e{index}'
        refs.append(f'SubResource("{ref}")')
        subs += f'[sub_resource type="Resource" id="{ref}"]\nscript = ExtResource("effect")\ntype = {quoted(effect["type"])}\namount = {effect["amount"]}\n'
        if effect['type'] == 'status':
            ext += f'[ext_resource type="Resource" path="res://data/statuses/{effect["status"]}.tres" id="status{index}"]\n'
            subs += f'status = ExtResource("status{index}")\n'
    text = header('card_definition', ext, subs, 3 + len(refs) + sum(e['type']=='status' for e in card['effects']))
    for source, field in [('id','id'),('name','display_name'),('owner','owner'),('description','description'),('target','target')]:
        text += f'{field} = {quoted(card[source])}\n'
    text += f'cost = {card["cost"]}\nexhaust = {str(card["exhaust"]).lower()}\neffects = Array[ExtResource("effect")]([{", ".join(refs)}])\n'
    save(f'data/cards/{card["id"]}.tres', text)

for char in data['characters']:
    ids = list(dict.fromkeys(char['deck'] + [char['special']]))
    ext = '[ext_resource type="Script" path="res://core/data/resources/card_definition.gd" id="card"]\n'
    ext += f'[ext_resource type="Resource" path="res://visuals/profiles/{char["id"]}.tres" id="visual"]\n'
    ext += ''.join(f'[ext_resource type="Resource" path="res://data/cards/{id}.tres" id="{id}"]\n' for id in ids)
    text = header('character_definition', ext, steps=4 + len(ids))
    for source, field in [('id','id'),('name','display_name'),('affinity','affinity')]:
        text += f'{field} = {quoted(char[source])}\n'
    rgb = [int(char['color'][i:i+2],16)/255 for i in (0,2,4)]
    text += 'color = Color(' + ', '.join(map(str,rgb)) + ', 1)\nvisual_profile = ExtResource("visual")\n'
    for field in ['health','attack','defense','energy','stress_limit']:
        text += f'{field} = {char[field]}\n'
    for group in ['crisis','passive']:
        for field, value in char[group].items():
            text += f'{group}_{field} = {value}\n'
    text += 'deck = Array[ExtResource("card")]([' + ', '.join(f'ExtResource("{id}")' for id in char['deck']) + '])\n'
    text += f'special = ExtResource("{char["special"]}")\n'
    save(f'data/characters/{char["id"]}.tres', text)

for enemy in data['enemies']:
    ext = '[ext_resource type="Script" path="res://core/data/resources/intent_definition.gd" id="intent"]\n[ext_resource type="Resource" path="res://visuals/profiles/enemy.tres" id="visual"]\n'
    subs, refs = '', []
    for index, intent in enumerate(enemy['pattern']):
        ref = f'i{index}'
        refs.append(f'SubResource("{ref}")')
        subs += f'[sub_resource type="Resource" id="{ref}"]\nscript = ExtResource("intent")\ntype = {quoted(intent["type"])}\namount = {intent["amount"]}\n'
    text = header('enemy_definition', ext, subs, 4 + len(refs))
    text += f'id = {quoted(enemy["id"])}\ndisplay_name = {quoted(enemy["name"])}\nhealth = {enemy["health"]}\nvisual_profile = ExtResource("visual")\n'
    text += 'pattern = Array[ExtResource("intent")]([' + ', '.join(refs) + '])\n'
    save(f'data/enemies/{enemy["id"]}.tres', text)

ext = ''
for group, script in [('cards','card'),('characters','character'),('enemies','enemy'),('statuses','status')]:
    ext += f'[ext_resource type="Script" path="res://core/data/resources/{script}_definition.gd" id="{group}_type"]\n'
    ids = list(data[group]) if group == 'statuses' else [item['id'] for item in data[group]]
    for id in ids:
        ext += f'[ext_resource type="Resource" path="res://data/{group}/{id}.tres" id="{group}_{id}"]\n'
text = header('content_catalog', ext, steps=2 + ext.count('[ext_resource'))
for group in ['cards','characters','enemies','statuses']:
    ids = list(data[group]) if group == 'statuses' else [item['id'] for item in data[group]]
    text += f'{group} = Array[ExtResource("{group}_type")]([' + ', '.join(f'ExtResource("{group}_{id}")' for id in ids) + '])\n'
text += 'team = Array[ExtResource("characters_type")]([' + ', '.join(f'ExtResource("characters_{id}")' for id in data['team']) + '])\n'
text += f'hand_size = {data["balance"]["hand_size"]}\n'
save('data/catalog.tres', text)
print('Resources creados. El JSON se conserva como referencia de migración.')
