@tool
@icon("res://addons/useful-scripts/Images/Icons/GUICreator.svg")
class_name GUICreator extends Object
## Creates [Control] Nodes (GUI) from [Dictionary].
## 
## You can see the parameters in the description of the [b]make_*[/b] functions, but there are several global [param Parameters]:[br]
## ● [param is_root]: [bool] - Makes this element the root for all others (all elements without the [param parent] parameter will automatically be added to the [param root_control]). [b]Default: [code]false[/code][/b][br][br]
## ● [param parent]: [StringName] - Defines the parent of this element and adds it to it. If you set the value to [code]"root"[/code], then the element will be added as a child node of the root element ([param root_control]). You can also set the [code]name[/code] of the [param root_control] as the value, this will be equivalent. [b]Default: [code]"root"[/code][/b][br][br]
## ● [param h_*/v_size_flags] (or [param horizontal_*]/[param vertical_size_flags]: [enum Control.SizeFlags] - Param for sets element's [member Control.size_flags_horizontal] and [member Control.size_flags_vertical].
## [b]Default: [constant Control.SIZE_FILL][/b][br][br]
## ● [param size]: [Vector2] - sets [member Control.size] [i](if element not added to [Container])[/i]. [b]Default: [Vector2](100, 100)[/b][br][br]
## ● [param min_size]: [Vector2] - [member Control.custom_minimum_size]. [b]Default: [constant Vector2.ZERO][/b][br][br]
## ● [param properties]: [Dictionary][[StringName], [Variant]] - A parameter for setting other properties that are not processed by the [method  make_*] methods. I recommend using [StringName] ([code]&""[/code]) to increase performance. [b]Default: [code]{}[/code][/b][br][br]
## ● [param signals]: [Dictionary][[StringName], [Callable]] - A parameter for setting other signals that are not processed by the [method  make_*] methods. I recommend using [StringName] ([code]&""[/code]) to increase performance. [b]Default: [code]{}[/code][/b][br][br]
## ● [param meta]: [Dictionary][[StringName], [Variant]] - A parameter for setting [code]Meta Data[/code] of this control. I recommend using [StringName] ([code]&""[/code]) to increase performance. [b]Default: [code]{}[/code][/b][br][br]
## ● [param script]: [String] - You can attach custom script. It's can be a code in like String or path to script file. [b]Default: [code]""[/code][/b][br][br]
##● [param ready_callable]: [Callable] - Calls when [signal Node.ready] is emited.[br][br]
## 
##[b]Example of usage:[/b] 
## [codeblock]
## func _ready() -> void:
##    add_child(GUICreator.create_gui({
##        &"RootBox": {
##            "type": &"HBoxContainer",
##            "is_root": true,
##        },
##        &"PrintButton": {
##            "type": &"Button",
##            "parent": "root",
##            "text": "Print \"Hi!\"'",
##            "pressed_callable": func(): print("Hieeeee!"), ## Lambda function.
##        },
##        &"QuitButton": {
##            "type": &"Button",
##            "parent": "root",
##            "text": "Quit",
##            "pressed_callable": get_tree().quit, ## Callable from 'SceneTree'.
##        },
##    })) ## Its adds `HBoxContainer` with 2 buttons: 1. Prints message and 2. Quit the game.
## [/codeblock]
##
##@tutorial(GUICreator wiki): https://github.com/NickSteinGames/useful-scripts/wiki/GUICreator#how-it-works
##

##Global [ButtonGroup]s for [BaseButton] from [method make_button][br]
static var global_button_groups: Dictionary[StringName, ButtonGroup] = {}

##Defined GUIs.[br]
##Its [Control]s whats storages in memory for improve optimization.[br]
##See [method define_gui_add], [method define_gui_remove] and [method define_gui_clear].
static var defined_guis: Dictionary[StringName, Control] = {}

## Returns [Control] ([param root_control]) from given [param data].[br]
## [b]Example:[/b] 
## [codeblock]
## func _ready() -> void:
##    add_child(GUICreator.create_gui({
##        &"RootBox": {
##            "type": &"HBoxContainer",
##            "is_root": true,
##        },
##        &"PrintButton": {
##            "type": &"Button",
##            "parent": "root",
##            "text": "Print \"Hi!\"'",
##            "pressed_callable": func(): print("Hieeeee!"), ## Lambda function.
##        },
##        &"QuitButton": {
##            "type": &"Button",
##            "parent": "root",
##            "text": "Quit",
##            "pressed_callable": get_tree().quit, ## Callable from 'SceneTree'.
##        },
##    }))
## [/codeblock]
##The [param owner] argument can be one of the following 3 options:[br]
##● [String]/[StringName] - The [member Node.owner] for each element will be set to the node whose name was passed;[br]
##● [Node] - The passed node (can be any class that inherits from [Node]) will be set as [member Node.owner] for all elements;[br]
##● [NodePath] - Path to the node (starting from [member SceneTree.root]).[br]
static func create_gui(data: Dictionary[StringName, Dictionary], owner = null) -> Control:
	assert(!data.is_empty(), "'data' is empty!")
	var root_control: Control
	var result_data: Dictionary[StringName, Control]
	var print_debuging = data.erase("print_debug")
	
	for control: StringName in data.keys():
		var control_data: Dictionary = data[control]
		var control_type: StringName = control_data.get("type", &"Control")
		var new_control: Control
		new_control = ClassDB.instantiate(control_type)
		match control_type:
			&"Label": new_control = make_label(control, control_data)
			&"RichTextLabel": new_control = make_rich_label(control_data)
			&"Button": new_control = make_button(control_data)
			&"BoxContainer", &"HBoxContainer", &"VBoxContainer": new_control = make_box_container(control_data)
			&"OptionButton": new_control = make_option_button(control_data)
			&"LineEdit": new_control = make_line_edit(control_data)
			_: new_control = make_custom(control_type, control_data)
		
		new_control.size_flags_horizontal = control_data.get("h_size_flags", control_data.get("horizontal_size_flags", Control.SIZE_FILL))
		new_control.size_flags_vertical = control_data.get("v_size_flags", control_data.get("vertical_size_flags", Control.SIZE_FILL))
		
		if control_data.has("ready_callable"):
			new_control.ready.connect(control_data.get("ready_callable"))
		
		for control_property: StringName in control_data.get("properties", {}).keys():
			new_control.set(control_property, control_data.get("properties", {})[control_property])
		
		for control_signal: StringName in control_data.get("signals", {}).keys():
			var err: Error = new_control.connect(control_signal, control_data.get("signals", {})[control_signal])
			if err != OK: printerr("Singal '%s' not connected - %s" % [control_signal, error_string(err)])
		
		if control_data.has("script"):
			var script: Variant = control_data.get("script", "")
			if script is String:
				if script.is_absolute_path():
					new_control.set_script(load(script))
				else:
					var new_script = GDScript.new()
					new_script.source_code = script
					var err = new_script.reload()
					if err == OK:
						new_control.set_script(new_script)
					else:
						printerr("GUICreator: Can't create script - error: ", error_string(err))
			elif script is Resource:
				new_control.set_script(script)
			else:
				assert(false, "parametr 'script' mut be a 'path' to file, 'source_code' of script or a script object it self.")
		
		new_control.name = control
		
		if control_data.get("is_root", data.keys()[0] == control):
			root_control = new_control
			result_data[&"root"] = new_control
			result_data[control] = new_control
			if print_debuging: print_debug("Root '%s' added!" % control)
		else:
			result_data[StringName(control_data.get("parent", &"root"))].add_child(new_control, true)
			result_data[control] = new_control
			if print_debuging: print_debug("Element '%s' added!" % control)
		if owner:
			match typeof(owner):
				TYPE_STRING, TYPE_STRING_NAME:
					if result_data.has(StringName(owner)):
						if !control_data.get("is_root", false):
							new_control.owner = result_data[StringName(owner)]
				TYPE_OBJECT:
					if owner is Node:
						new_control.owner = owner
					else:
						assert(false, "'owner' mut be a 'String'/'StringName' of 'data'`s already existens GUI Control, owner it self (and 'Node') or 'NodePath' to the owner Node (from 'root').")
				TYPE_NODE_PATH:
					new_control.owner = new_control.get_tree().root.get_node(owner)
				_:
					assert(false, "'owner' mut be a 'String'/'StringName' of 'data'`s already existens GUI Control, owner it self (and 'Node') or 'NodePath' to the owner Node (from 'root').")
		
		var metadata: Dictionary = control_data.get("meta", {})
		for meta in metadata.keys():
			new_control.set_meta(meta, metadata[meta])
		
		assert(root_control, "No root! Add in 'data' on fisrt place Control with parametr 'is_root' = 'true'")
		
	return root_control

##Creates a GUI from the given [Dictionary] of [[StringName], [Dictionary]] [param data] and saves it into a scene according to the given [String] [param save_path].
##[br]An extension within the [param save_path] is optional.
##[br]Returns an [enum Error] if issues occur.[br]
##[b]Warning:[/b] in [param *_callable]s parameters (or in parameter [param signals]) not saved lambda methods or etc.[br]
##Use this method only for creates layouts. [br]
static func save_gui_scene(data: Dictionary[StringName, Dictionary], save_path: String) -> Error:
	var scene: PackedScene = PackedScene.new()
	var node = create_gui(data, &"root")
	node.set_meta("test", print.bind("Hellow World!"))
	node.set_meta("test2", "HIIIIII!")
	var pack_err = scene.pack(node)
	if !save_path.get_extension():
		if save_path.ends_with("."): save_path += "res"
		else: save_path += ".res"
	if pack_err != OK:
		printerr("GUICretor: Can`t pack scene: ", error_string(pack_err))
		return pack_err
	var save_err = ResourceSaver.save(scene, save_path, ResourceSaver.FLAG_BUNDLE_RESOURCES)
	return save_err

#region DEFINED GUI
##Adds GUI from [param data] into [member defined_guis] with gived [param name].[br]
static func define_gui_add(data: Dictionary[StringName, Dictionary], name: StringName):
	if !defined_guis.has(name):
		defined_guis[name] = create_gui(data, &"root")
	else:
		push_error("GUICreator: GUI Node with name \"%s\" already exist!" % name)
## Replace GUI with [param name] to [param new_data]
static func define_gui_replace(new_data: Dictionary[StringName, Dictionary], name: StringName):
	if defined_guis.has(name):
		defined_guis[name] = create_gui(new_data, &"root")
	else:
		push_warning("GUICreator: GUI Node with name \"%s\" not exist for replacing." % name)
## Returns Defined GUI from [member defined_guis] by [param name]
static func define_gui_get(name: StringName) -> Control:
	if defined_guis.has(name):
		return defined_guis[name].duplicate()
	else:
		push_error("GUICreator: GUI Node with name \"%s\" not exist!" % name)
		return null
## Deletes GUI from [member defined_guis] by [param name].
static func define_gui_remove(name: StringName):
	if !defined_guis.erase(name): push_warning("GUICreator: GUI Node with name \"%s\" not even exist." % name)
## Clear [member defined_guis]. (see [method Dictionary.clear])
static func define_gui_clear():
	defined_guis.clear()
#endregion

## Creates a [Button] (and [CheckBox], [CheckButton]).[br]
## Button's Parameters:[br]
## ● [param text]: [String] - Text on [Button]. [b]Default: [param name][/b] (see [member Button.text])[br][br]
## ● [param toggle_mode]: [bool] - Makes Button toggable. [b]Default: [code]false[/code][/b] (see [member BaseButton.toggle_mode])[br][br]
## ● [param start_pressed]: [bool] - Makes Button pressed by default. [b]Default: [code]false[/code][/b] (if [param toggle_mode] is [code]true[/code]) (see [member BaseButton.button_pressed])[br][br]
## ● [param toggled_callable]: [Callable] - [Callable] for connect to [signal BaseButton.toggled]. It can be a Lambda function. Must be given for button functionality. (if [param toggle_mode] is [code]true[/code]) (see [signal BaseButton.toggled])[br][br]
## ● [param pressed_callable]: [Callable] - [Callable] for connect to [signal BaseButton.pressed]. It can be a Lambda function. Must be given for button functionality. (if [param toggle_mode] is [code]false[/code]) (see [signal BaseButton.pressed])[br][br]
## ● [param button_group]: [StringName/ButtonGroup] - If it [String]/[StringName], [ButtonGroup] takes from [member global_button_groups] (see [member BaseButton.button_group])[br][br]
## [br][b]Warning:[/b] [param start_pressed] not call [param toggled_callable].
static func make_button(control_data: Dictionary) -> Button:
	var new_button: Button
	
	new_button = ClassDB.instantiate(control_data.type)
	
	new_button.text = control_data.get("text", "Button")
	new_button.toggle_mode = control_data.get("toggle_mode", false)
	if new_button.toggle_mode:
		new_button.button_pressed = control_data.get("start_pressed", false)
		if control_data.has("toggled_callable"):
			new_button.toggled.connect(control_data.get("toggled_callable"))
	else:
		if control_data.has("pressed_callable"):
			new_button.pressed.connect(control_data.get("pressed_callable"))
	
	return new_button

## Creates a [Label].[br]
## Label's Parameters:[br]
## ● [param text]: [String] - [member Label.text]. [b]Default: [param name][/b][br][br]
## ● [param h_*/v_alignment]: [String] -  [member Label.horizontal_alignment] and  [member Label.vertical_alignment]. You also can use [code]"horizontal_*"[/code] and [code]"vertical_alignment"[/code] for changing alignments.
## [b]Default: [constant HORIZONTAL_ALIGNMENT_LEFT]; [constant VERTICAL_ALIGNMENT_TOP][/b][br][br]
## ● [param clip_text]: [bool] - [member Label.clip_text]. [b]Default: [code]false[/code][/b][br][br]
## ● [param autowrap_mode] (or [param autowrap]): [enum TextServer.AutowrapMode] - [member Label.autowrap_mode]. [b]Default: [constant TextServer.AutowrapMode.AUTOWRAP_OFF][/b][br][br]
## ● [param overrun_behavior]: [enum TextServer.OverrunBehavior] - [member Label.text_overrun_behavior]. [b]Default: [constant TextServer.OVERRUN_NO_TRIMMING][/b][br][br]
## ● [param label_settings]: [LabelSettings] - [member Label.label_settings]. [b]Default: [code]null[/code][/b][br][br]
static func make_label(name:StringName, control_data: Dictionary) -> Label:
	var new_label = Label.new()
	
	new_label.text = control_data.get("text", "")
	new_label.horizontal_alignment = control_data.get("h_alignment", control_data.get("horizontal_alignment", HORIZONTAL_ALIGNMENT_LEFT))
	new_label.vertical_alignment = control_data.get("v_alignment", control_data.get("vertical_alignment", VERTICAL_ALIGNMENT_TOP))
	
	new_label.clip_text = control_data.get("clip_text", false)
	new_label.text_overrun_behavior = control_data.get("overrun_behavior", control_data.get("autowrap", TextServer.AutowrapMode.AUTOWRAP_OFF))
	
	new_label.autowrap_mode = control_data.get("autowrap_mode", TextServer.OverrunBehavior.OVERRUN_NO_TRIMMING)
	
	new_label.label_settings = control_data.get("label_settings", null)
	
	return new_label

## Creates a [RichTextLabel].[br]
## Label's Parameters:[br]
## ● as with [method make_label][br][br]
## ● [param bbcode/bbcode_enebled]: [bool] - [member RichTextLabel.bbcode_enabled]. [b]Default: [code]false[/code][/b][br][br]
## ● Use [param properties] to sets another [RichTextLabel] properties.
static func make_rich_label(control_data: Dictionary) -> RichTextLabel:
	var new_label = RichTextLabel.new()
	
	new_label.text = control_data.get("text", "")
	new_label.bbcode_enabled = control_data.get("bbcode", control_data.get("bbcode_enabled", false))
	new_label.horizontal_alignment = control_data.get("h_alignment", control_data.get("horizontal_alignment", HORIZONTAL_ALIGNMENT_LEFT))
	new_label.vertical_alignment = control_data.get("v_alignment", control_data.get("vertical_alignment", VERTICAL_ALIGNMENT_TOP))
	
	new_label.clip_text = control_data.get("clip_text", false)
	new_label.text_overrun_behavior = control_data.get("overrun_behavior", TextServer.OverrunBehavior.OVERRUN_NO_TRIMMING)
	
	new_label.label_settings = control_data.get("label_settings", null)
	
	return new_label

## Creates a [BoxContainer] (or [HBoxContainer]/[VBoxContainer].[br]
## BoxContainer's Parameters:[br]
## ● [param vertical]: [bool] - [member BoxContainer.vertical]. [b]Default: [code]false[/code][/b][br][br]
## ● [param alignment]: [enum BoxContainer.AlignmentMode] - [member BoxContainer.alignment]. [b]Default: [constant BoxContainer.ALIGNMENT_BEGIN][/b][br][br]
## ● [param separation]: [int] - [theme_item BoxContainer.separation]. [b]Default: [code]4[/code][/b][br][br]
static func make_box_container(control_data: Dictionary) -> BoxContainer:
	var new_box: BoxContainer = BoxContainer.new()
	
	new_box.alignment = control_data.get("alignment", BoxContainer.ALIGNMENT_BEGIN)
	new_box.vertical = (control_data.type == &"VBoxContainer" || control_data.get("vertical", false)) && control_data.type != &"HBoxContainer"
	new_box.add_theme_constant_override("separation", control_data.get("separation", 4))
	
	return new_box

## Creates a [OptionButton].[br]
## OptionButton's Parameters:[br]
## ● as with [method make_button][br][br]
## ● [param items]: [Array][[Dictionary]] - items for [OptionButton]. (see [method OptionButton.add_item] and [method OptionButton.add_icon_item) [br][br]
## ● [param item_selected_callable]: [Callable] - Callalbe, whats [method Callable.call] when item selected. (see [signal OptionButton.item_selected]) [b]Default: [code]null[/code][/b][br][br]
## ● [param item_focused_callable]: [Callable] - Callalbe, whats [method Callable.call] when item focused. (see [signal OptionButton.item_focused]) [b]Default: [code]null[/code][/b][br][br]
## [b]Default: [code][][/code][/b] (see [method OptionButton.add_item] [br][br]
## [br]
## Items has Parameters:[br]
## ● [param text]: [String] - visible text for item. [b]Default: [code]""[/code][/b][br][br]
## ● [param id]: [int] - item's ID. [b]Default: [code]-1[/code][/b][br][br]
## ● [param icon]: [Texture2D] - icon item. (see [method OptionButton.add_icon_item]) [b]Default: [code]null[/code][/b][br][br]
## ● [param selected_callable]: [Callable] - Callalbe, whats [method Callable.call] when this item selected. (see [signal OptionButton.item_selected]) [b]Default: [code]null[/code][/b][br][br]
## ● [param focused_callable]: [Callable] - Callalbe, whats [method Callable.call] when this item focused. (see [signal OptionButton.item_focused]) [b]Default: [code]null[/code][/b][br][br]
## [b]Note:[/b] [code]Item[/code]'s [param selected_*] and [param focused_callable]s don't overrides a [b]OptionButton's[/b] parameter [param item_selected_*] and [param item_focused_callable]s.[br]
## [b]Note:[/b] if you put [code]separator:[/code] in begin of text and item become separator (see [method OptionButton.add_separator]
## [b]Warning:[/b] You don't need to make a Callable with arguments for [param selected_*] and [param focused_callable]s (for the [param index] of the original signals), theme functions are called DIRECTLY for each element individually.
## 
## [b]Example:[/b] 
## [codeblock]
## GUICreator.create_gui({
##        &"Root": {
##            "is_root": true
##        },
##        &"Button": {
##            "type": &"OptionButton",
##            "text": "Some Text",
##            "items": [
##                {
##                    "text": "Hello",
##                    "selected_callable": print.bind("Hello, I'am option \"Hello\"!"),
##                },
##                {
##                    "text": "separator:Separator #1!",
##                },
##                {
##                    "text": "I dunno",
##                    "selected_callable": print.bind("Idk who iam..."),
##                },
##            ],
##            "item_selected_callable": func(id: int): print("Option selected: ", id)
##        }
##    }))
## [/codeblock]
static func make_option_button(control_data: Dictionary) -> OptionButton:
	var new_button: OptionButton = make_button(control_data)
	
	if control_data.has("item_selected_callable"):
		new_button.item_selected.connect(control_data.get("item_selected_callable"))
	if control_data.has("item_focused_callable"):
		new_button.item_focused.connect(control_data.get("item_focused_callable"))
	
	var items: Array = control_data.get("items", [])
	for item: Dictionary in items:
		if item.get("text").begins_with("separator:"):
			new_button.add_separator(item.get("text", "").replace("separator:", ""))
		else:
			if item.has("icon"):
				new_button.add_icon_item(item.get("icon", null), item.get("text", ""), item.get("id", -1))
			else:
				new_button.add_item(item.get("text", ""), item.get("id", -1))
			
			if item.has("selected_callable"):
				new_button.item_selected.connect(
					(func(index: int):
						if index == items.find(item):
							(item.get("selected_callable") as Callable).call()
							)
					)
			if item.has("focused_callable"):
				new_button.item_focused.connect(
					(func(index: int):
						if index == items.find(item):
							(item.get("focused_callable") as Callable).call()
							)
					)
	
	return new_button

##Creates a [LineEdit].[br]
##LineEdit's Parameters:[br]
## ● [param default_text]: [String] - Text by defualt (see [member LineEdit.text]). [b]Default: [code]""[/code][/b][br][br]
## ● [param placeholder_text] (or [param placeholder]): [String] - Text what be displayed if [member LineEdit.text] is empty. (see [member LineEdit.placeholder_text]) [b]Default: [code]""[/code][/b][br][br]
## ● [param text_changed_callable]: [Callable] - Calls when [member LineEdit.text] is changed.[br][br]
## ● [param text_submitted_callable]: [Callable] - Calls when [member LineEdit.text] is submitted (user presse [code]"ui_accept"[/code]).[br][br]
static func make_line_edit(control_data: Dictionary) -> LineEdit:
	var line_edit = LineEdit.new()
	
	line_edit.placeholder_text = control_data.get("placeholder_text", control_data.get("placeholder", ""))
	line_edit.text = control_data.get("default_text", "")
	
	if control_data.has("text_changed_callable"):
		line_edit.text_changed.connect(control_data.get("text_changed_callable"))
	if control_data.has("text_submitted_callable"):
		line_edit.text_submitted.connect(control_data.get("text_submitted_callable"))
	
	return line_edit

##Creates a [TextEdit].[br]
##TextEdit's Parameters:[br]
## ● [param default_text]: [String] - Text by defualt (see [member LineEdit.text]). [b]Default: [code]""[/code][/b][br][br]
## ● [param placeholder_text] (or [param placeholder]): [String] - Text what be displayed if [member LineEdit.text] is empty. (see [member LineEdit.placeholder_text]) [b]Default: [code]""[/code][/b][br][br]
## ● [param text_changed_callable]: [Callable] - Calls when [signal TextEdit.text_changed] is emitted.[br][br]
static func make_text_edit(control_data: Dictionary) -> TextEdit:
	var line_edit = TextEdit.new()
	
	line_edit.placeholder_text = control_data.get("placeholder_text", control_data.get("placeholder", ""))
	line_edit.text = control_data.get("default_text", "")
	
	if control_data.has("text_changed_callable"):
		line_edit.text_changed.connect(control_data.get("text_changed_callable"))
	
	return line_edit

## More easy way to make custom procces of [param control_data].[br]
## Just add in [code]match control_type:[/code] your class, it's must be like this:
##[codeblock]
##match control_type:
##    &"CustomContainer":
##        return CustomContainer.new()
##[/codeblock]
static func make_custom(control_type: StringName, control_data: Dictionary) -> Control:
	match control_type:
		_: return ClassDB.instantiate(control_type) ## DON'T remove it, else all another types not gonna process.

##Adds global [ButtonGroup] with name [param name] to [member global_button_groups].[br]
static func add_global_button_group(name: StringName, group: ButtonGroup):
	if !global_button_groups.has(name):
		global_button_groups[name] = group

##Removes [ButtonGroup] from [meber global_button_groups].[br]
##Returns [code]true[/code] it removing success[br]
static func remove_global_button_group(name: StringName) -> bool:
	return global_button_groups.erase(name)
