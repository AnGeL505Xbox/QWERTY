"""Traslado único del escenario de fase 4 a nodos editables; no sobrescribe escenas."""
from pathlib import Path
from math import radians, sin, cos
root = Path(__file__).resolve().parents[1]
path = root / 'scenes/visuals/arena.tscn'
if path.exists():
    raise SystemExit('La escena ya existe. Edítala en Godot; no se sobrescribe.')
resources = []
nodes = []
def box(name, size, position, color, unshaded=False, angle=None):
    i = len(resources)//2
    channels = [int(color[j:j+2], 16)/255 for j in (0,2,4)]
    resources.append(f'[sub_resource type="StandardMaterial3D" id="Material{i}"]\nalbedo_color = Color({", ".join(map(str,channels))}, 1)\n' + ('shading_mode = 0\n' if unshaded else ''))
    resources.append(f'[sub_resource type="BoxMesh" id="Mesh{i}"]\nsize = Vector3{size}\nmaterial = SubResource("Material{i}")\n')
    text = f'[node name="{name}" type="MeshInstance3D" parent="Stage"]\nposition = Vector3{position}\nmesh = SubResource("Mesh{i}")\n'
    if angle: text += f'rotation = Vector3(0, 0, {radians(angle)})\n'
    nodes.append(text)
box('Floor', (14,0.2,7), (0,-0.8,-1), '242d48')
for i in range(7):
    box(f'Column{i+1}', (0.32,5.8,0.5), (-7.2+i*2.4,1.6,-5), '252c47')
    box(f'LightStrip{i+1}', (0.1,4.8,0.12), (-7.2+i*2.4,1.8,-4.7), '537486', True)
for i in range(5):
    box(f'Crystal{i+1}', (0.45,1.5,0.45), (-5.2+i*2.6,-0.05,-2.6), '5d6486', angle=22)
box('FrontLine', (11,0.025,0.04), (0,-0.68,1.4), '67b3c4', True)
text = f'[gd_scene load_steps={8+len(resources)} format=3]\n'
text += '''[ext_resource type="Script" path="res://visuals/arena.gd" id="arena"]
[ext_resource type="PackedScene" path="res://scenes/visuals/actor.tscn" id="actor"]
[ext_resource type="Script" path="res://visuals/effects/feedback.gd" id="feedback"]
[ext_resource type="Resource" path="res://visuals/profiles/lira.tres" id="lira"]
[ext_resource type="Resource" path="res://visuals/profiles/noa.tres" id="noa"]
[ext_resource type="Resource" path="res://visuals/profiles/enemy.tres" id="enemy"]
[sub_resource type="Environment" id="Environment"]
background_mode = 1
background_color = Color(0.0627, 0.0941, 0.1843, 1)
ambient_light_source = 2
ambient_light_color = Color(0.5686, 0.6471, 0.7843, 1)
ambient_light_energy = 0.65
'''
text += '\n'.join(resources)
text += '''
[node name="Arena" type="Node3D"]
script = ExtResource("arena")
profiles = {"lira": ExtResource("lira"), "noa": ExtResource("noa"), "enemy": ExtResource("enemy")}

[node name="Camera3D" type="Camera3D" parent="."]
position = Vector3(0, 3.4, 10)
rotation = Vector3(-0.273, 0, 0)
fov = 48.0
current = true

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment")

[node name="Sun" type="DirectionalLight3D" parent="."]
rotation_degrees = Vector3(-60, -30, 0)
shadow_enabled = false

[node name="Stage" type="Node3D" parent="."]
'''
text += '\n'.join(nodes)
text += '\n[node name="AllySlots" type="Node3D" parent="."]\n'
for i in range(3):
    text += f'\n[node name="Slot{i+1}" type="Marker3D" parent="AllySlots"]\nposition = Vector3({-3.7+i*1.2}, 0.5, {i*0.25})\n'
    text += f'\n[node name="Actor" parent="AllySlots/Slot{i+1}" instance=ExtResource("actor")]\ndisplay_name = "{["Lira", "Noa", "Tercer integrante"][i]}"\nprofile = ExtResource("{["lira","noa","lira"][i]}")\n'
text += '''
[node name="EnemySlot" type="Marker3D" parent="."]
position = Vector3(2.9, 0.5, -0.3)

[node name="Actor" parent="EnemySlot" instance=ExtResource("actor")]
display_name = "Enemigo"
profile = ExtResource("enemy")

[node name="Feedback" type="Node3D" parent="."]
script = ExtResource("feedback")
'''
path.write_text(text)
print('Escenario trasladado a escena editable.')
