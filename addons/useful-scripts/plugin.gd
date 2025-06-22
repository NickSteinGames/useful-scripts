@tool
extends EditorPlugin

var us_menu: PopupMenu

const IDS: Dictionary[String, int] = {
	"guide_creator": 0,
	"gui_creator": 1,
}
var IDS_CALSS: Dictionary[int, Callable] = {
	0: _open_guide_creator,
	1: _open_guicreator
}

const GUIDE_CREATOR = preload("Scenes/guide_creator.tscn")
var guide_creator: Window
var gui_creator: Window

const CLASSES: PackedStringArray = [
	"AABB",
	"Array",
	"Basis",
	"bool",
	"Callable",
	"Color",
	"Dictionary",
	"float",
	"int",
	"NodePath",
	"PackedByteArray",
	"PackedColorArray",
	"PackedFloat32Array",
	"PackedFloat64Array",
	"PackedInt32Array",
	"PackedInt64Array",
	"PackedStringArray",
	"PackedVector2Array",
	"PackedVector3Array",
	"PackedVector4Array",
	"Plane",
	"Projection",
	"Quaternion",
	"Rect2",
	"Rect2i",
	"RID",
	"Signal",
	"String",
	"StringName",
	"Transform2D",
	"Transform3D",
	"Vector2",
	"Vector2i",
	"Vector3",
	"Vector3i",
	"Vector4",
	"Vector4i",
]
#const controls_list: PackedStringArray = [
	#"AspectRatioContainer",
	#"BaseButton",
	#"BoxContainer",
	#"Button",
	#"CenterContainer",
	#"CheckBox",
	#"CheckButton",
	#"CodeEdit",
	#"ColorPicker",
	#"ColorPickerButton",
	#"ColorRect",
	#"Container",
	#"Control",
	#"FlowContainer",
	#"GraphEdit",
	#"GraphElement",
	#"GraphFrame",
	#"GraphNode",
	#"GridContainer",
	#"HBoxContainer",
	#"HFlowContainer",
	#"HScrollBar",
	#"HSeparator",
	#"HSlider",
	#"HSplitContainer",
	#"ItemList",
	#"Label",
	#"LineEdit",
	#"LinkButton",
	#"MarginContainer",
	#"MenuBar",
	#"MenuButton",
	#"NinePatchRect",
	#"OptionButton",
	#"Panel",
	#"PanelContainer",
	#"ProgressBar",
	#"Range",
	#"ReferenceRect",
	#"RichTextLabel",
	#"ScrollBar",
	#"ScrollContainer",
	#"Separator",
	#"Slider",
	#"SpinBox",
	#"SplitContainer",
	#"SubViewportContainer",
	#"TabBar",
	#"TabContainer",
	#"TextEdit",
	#"TextureButton",
	#"TextureProgressBar",
	#"Tree",
	#"VBoxContainer",
	#"VFlowContainer",
	#"VScrollBar",
	#"VSeparator",
	#"VSlider",
	#"VSplitContainer",
	#"VideoStreamPlayer"
#]

func _enter_tree() -> void:
	us_menu = PopupMenu.new()
	add_tool_submenu_item("Useful Scripts", us_menu)
	
	guide_creator = GUIDE_CREATOR.instantiate()
	EditorInterface.get_editor_main_screen().add_child(guide_creator)
	guide_creator.position = EditorInterface.get_editor_main_screen().size / 2 - Vector2(0, guide_creator.size.y / 2)
	guide_creator.hide()
	
	#gui_creator = GUI_CRETOR_WINDOW.instantiate()
	#EditorInterface.get_editor_main_screen().add_child(gui_creator)
	#gui_creator.position = EditorInterface.get_editor_main_screen().size / 2 - Vector2(0, gui_creator.size.y / 2)
	#gui_creator.hide()
	
	us_menu.id_pressed.connect(_on_id_pressed)
	
	us_menu.add_item("Guide Creator")
	#us_menu.add_item("GUI Creator")
	
	

func _exit_tree() -> void:
	guide_creator.queue_free()
	#gui_creator.queue_free()
	us_menu.queue_free()
	remove_tool_menu_item("Useful Scripts")

func _open_guide_creator():
	guide_creator.show()
func _open_guicreator():
	gui_creator.show()

func _on_id_pressed(id: int):
	IDS_CALSS[id].call()
